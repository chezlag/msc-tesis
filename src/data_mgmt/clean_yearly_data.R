library(fastverse)
library(fst)
library(lubridate)

source("src/lib/cli_parsing_o.R")
source("src/lib/stata_helpers.R")

# Balances --------------------------------------------------------------------

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

# DJ de ventas por IVA ---------------------------------------------------------

sls <- read_fst("src/data/dgi_firmas/out/data/sales_allF_allY.fst", as.data.table = TRUE)
csls <- sls |>
    collap(vatSales + vatPurchases + vatDue + vatLiability + turnoverNetOfTax + taxableTurnover ~ fid + year, fsum)

# Pagos de IVA -----------------------------------------------------------------

vat <- read_fst("src/data/dgi_firmas/out/data/vat_payments.fst", as.data.table = TRUE)
vat[, year := lubridate::year(date)]
cvat <- vat |>
    collap(vatPaid ~ fid + year)

# Merge ------------------------------------------------------------------------

ipcy <- fread("src/data/ipc_deflactor_2016m12.csv") %>% 
    .[lubridate::month(date) == 12] %>%
    .[, year := lubridate::year(date)]

lapply(list(cbal, csls, cvat), setkeyv, c("fid", "year")) |> invisible()
dt <- merge(cbal, csls, all = TRUE) %>%
    merge(cvat, all = TRUE) %>%
    .[inrange(year, 2010, 2016)] %>%
    merge(fread("src/data/ui.csv"), all.x = TRUE, by = "year") |>
    merge(ipcy[, .(year, defl)], by = "year") 

# Deflacto y paso a Millones de UI
varlist <- c(
    "turnover", "Revenue", "Cost", "Profit", "CorpTaxDue", 
    "vatSales", "vatPurchases", "vatDue", "vatLiability", "turnoverNetOfTax", "taxableTurnover",
    "vatPaid"
)
for (v in varlist) dt[, (paste0(v, "K")) := get(v) / defl]
for (v in varlist) dt[, (paste0(v, "M")) := get(v) / 1e06]
for (v in varlist) dt[, (paste0(v, "MUI")) := get(v) / ui]

# Export ----------------------------------------------------------------------

write_fst(dt, opt$output)
