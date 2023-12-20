library(fastverse)
library(fst)
library(lubridate)
library(purrr)

source("src/lib/cli_parsing_o.R")
source("src/lib/stata_helpers.R")

# Balances --------------------------------------------------------------------

message("Processing corporate income tax affidavits and balance sheets.")

bal <- read_fst("src/data/dgi_firmas/out/data/balances_allF_allY.fst", as.data.table = TRUE)

bal[, turnover := ventas]

bal[(djFict), Revenue := ingresoOperativoFict]
bal[(djFict) & is.na(ingresoOperativoFict), Revenue := ingresoBrutoFict]

negVarlist <- c("costosFict", "deduccFict")
bal |> rowtotal("Cost", negVarlist, .if = "(djFict)")

bal[, Temp1 := -Cost]
bal[, Profit := rowSums(.SD, na.rm = TRUE), .SDcols = c("Revenue", "Temp1")]
bal[, Temp1 := NULL]

bal[, CorpTaxDue := fcase(
    Profit > 0, round(Profit * 0.25),
    Profit <= 0, 0
)]
bal[irae > CorpTaxDue, CorpTaxDue := CorpTaxDue + 1]

cbal <- bal |>
    collap(turnover + Revenue + Cost + Profit + CorpTaxDue ~ fid + year, fsum)
rm(bal)

# DJ de ventas por IVA ---------------------------------------------------------

message("Processing VAT affidavits and taxable sales/purchases.")

csls <- read_fst("src/data/dgi_firmas/out/data/sales_allF_allY.fst", as.data.table = TRUE) |>
    collap(vatSales + vatPurchases + vatDue + vatLiability + turnoverNetOfTax + taxableTurnover ~ fid + year, fsum)

# Pagos y retenciones de impuestos ---------------------------------------------

message("Processing tax paid and tax retained by third parties.")

tax <- read_fst("src/data/dgi_firmas/out/data/tax_paid_retained.fst", as.data.table = TRUE)
tax[, year := lubridate::year(date)]

taxvarlist <- grep("Paid$|Retained$", names(tax), value = TRUE)
for (v in taxvarlist) tax[, (v) := get(v) / 1e03]

ctax <- tax |>
    collap(
        vatPaid + corpTaxPaid + otherTaxPaid + totalTaxPaid +
        vatRetained + corpTaxRetained + otherTaxRetained + totalTaxRetained ~ fid + year, 
        fsum
)
for (v in taxvarlist) ctax[, (v) := get(v) * 1e03]
rm(tax)

# e-ticket ---------------------------------------------------------------------

message("Reading e-ticket transaction data.")

cfetab <- read_fst("out/data/eticket_yearly.fst", as.data.table = TRUE)

# Merge ------------------------------------------------------------------------

message("Merging all data sources.")

ipcy <- fread("src/data/ipc_deflactor_2016m12.csv") %>% 
    .[lubridate::month(date) == 12] %>%
    .[, year := lubridate::year(date)]

dtlist <- list(cbal, csls, ctax)
lapply(dtlist, setkeyv, c("fid", "year")) |> invisible()
dt <- dtlist |>
    purrr::reduce(merge, all = TRUE) %>%
    merge(cfetab, all.x = TRUE) %>%
    .[inrange(year, 2010, 2016)] %>%
    merge(fread("src/data/ui.csv"), all.x = TRUE, by = "year") |>
    merge(ipcy[, .(year, defl)], by = "year") 

# Deflacto y paso a Millones de UI
varlist <- c(
    "turnover", "Revenue", "Cost", "Profit", "CorpTaxDue", 
    "vatSales", "vatPurchases", "vatDue", "vatLiability", "turnoverNetOfTax", "taxableTurnover",
    taxvarlist, names(cfetab)[-(1:2)]
)
for (v in varlist) dt[, (paste0(v, "K")) := get(v) / defl]
for (v in varlist) dt[, (paste0(v, "M")) := get(v) / 1e06]
for (v in varlist) dt[, (paste0(v, "MUI")) := get(v) / ui]

# Export ----------------------------------------------------------------------

message("Writing output: ", opt$output)

write_fst(dt, opt$output)
