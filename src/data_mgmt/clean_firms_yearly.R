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

idvars <- c("fid", "year")
balvarlist <- c("turnover", "Revenue", "Cost", "Profit", "CorpTaxDue")
balformula <- arsenal::formulize(balvarlist, idvars)

cbal <- collap(bal, balformula, fsum) |>
    merge(bal[, .(djFict =fmax(djFict) |> as.logical()), by = idvars])
rm(bal)

# DJ de ventas por IVA ---------------------------------------------------------

message("Processing VAT affidavits and taxable sales/purchases.")

slsvarlist <- c("vatSales", "vatPurchases", "vatDue", "vatLiability", "turnoverNetOfTax", "taxableTurnover")
slsformula <- arsenal::formulize(slsvarlist, idvars)

csls <-  read_fst("src/data/dgi_firmas/out/data/sales_allF_allY.fst", as.data.table = TRUE) |>
    collap(slsformula, fsum)


# Pagos y retenciones de impuestos ---------------------------------------------

message("Processing tax paid and tax retained by third parties.")

tax <- read_fst("src/data/dgi_firmas/out/data/tax_paid_retained.fst", as.data.table = TRUE)
tax[, year := lubridate::year(date)]

taxvarlist <- grep("Paid$|Retained$", names(tax), value = TRUE)
taxformula <- arsenal::formulize(taxvarlist, idvars)

for (v in taxvarlist) tax[, (v) := get(v) / 1e03] # to avoid int overflow in collap()
ctax <- collap(tax, taxformula, fsum)
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

static <- read_fst("out/data/firms_static.fst", as.data.table = TRUE)

dtlist <- list(cbal, csls, ctax)
lapply(dtlist, setkeyv, idvars) |> invisible()
dt <- dtlist |>
    purrr::reduce(merge, all = TRUE) %>%
    merge(cfetab, all.x = TRUE) %>%
    merge(static, all.x = TRUE) %>%
    .[inrange(year, 2010, 2016)] %>%
    merge(fread("src/data/ui.csv"), all.x = TRUE, by = "year") |>
    merge(ipcy[, .(year, defl)], by = "year") 

# Define new variables --------------------------------------------------------

dt[, firm_age := year - birth_year]

# Base sample: DJ ficta
dt[, inSample1 := (djFict)]

# Deflacto y paso a Millones de UI
cfevarlist <- names(cfetab)[-(1:2)]
varlist <- c(balvarlist, slsvarlist, taxvarlist, taxvarlist, cfevarlist)
for (v in varlist) dt[, (paste0(v, "K")) := get(v) / defl]
for (v in varlist) dt[, (paste0(v, "M")) := get(v) / 1e06]
for (v in varlist) dt[, (paste0(v, "MUI")) := get(v) / ui]

# tratamiento A: recepción de primer eticket
dt[, yearFirstReception := lubridate::year(dateFirstReception)]
dt[, eventtimeA := year - yearFirstReception]

# Export ----------------------------------------------------------------------

message("Writing output: ", opt$output)

write_fst(dt, opt$output)
