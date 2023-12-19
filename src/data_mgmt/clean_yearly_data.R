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

# e-ticket ---------------------------------------------------------------------

cfe <- read_fst("src/data/dgi_firmas/out/data/eticket_transactions.fst", as.data.table = TRUE)

ntickets <- merge(
    collap(cfe, nTickets ~ id_receptor + year, fsum) |>
        setnames(c("id_receptor", "nTickets"), c("fid", "nTicketsReceived")),
    collap(cfe, nTickets ~ id_emisor + year, fsum) |>
        setnames(c("id_emisor", "nTickets"), c("fid", "nTicketsEmitted")),
    by = c("fid", "year"), all = TRUE
)

amount <- merge(
    collap(cfe[(positiveAmount)], grossAmount + netAmount ~ id_receptor + year, fsum) |>
        setnames(c("id_receptor", "grossAmount", "netAmount"), c("fid", "grossAmountReceived", "netAmountReceived")),
    collap(cfe[(positiveAmount)], grossAmount + netAmount ~ id_emisor + year, fsum) |>
        setnames(c("id_emisor", "grossAmount", "netAmount"), c("fid", "grossAmountEmitted", "netAmountEmitted")),
    by = c("fid", "year"), all = TRUE
)

# Merge ------------------------------------------------------------------------

ipcy <- fread("src/data/ipc_deflactor_2016m12.csv") %>% 
    .[lubridate::month(date) == 12] %>%
    .[, year := lubridate::year(date)]

lapply(list(cbal, csls, ctax), setkeyv, c("fid", "year")) |> invisible()
dt <- merge(cbal, csls, all = TRUE) %>%
    merge(ctax, all = TRUE) %>%
    merge(ntickets, all.x = TRUE) %>%
    merge(amount, all.x = TRUE) %>%
    .[inrange(year, 2010, 2016)] %>%
    merge(fread("src/data/ui.csv"), all.x = TRUE, by = "year") |>
    merge(ipcy[, .(year, defl)], by = "year") 

# Deflacto y paso a Millones de UI
varlist <- c(
    "turnover", "Revenue", "Cost", "Profit", "CorpTaxDue", 
    "vatSales", "vatPurchases", "vatDue", "vatLiability", "turnoverNetOfTax", "taxableTurnover",
    taxvarlist, names(ntickets)[-(1:2)], names(amount)[-(1:2)]
)
for (v in varlist) dt[, (paste0(v, "K")) := get(v) / defl]
for (v in varlist) dt[, (paste0(v, "M")) := get(v) / 1e06]
for (v in varlist) dt[, (paste0(v, "MUI")) := get(v) / ui]

# Export ----------------------------------------------------------------------

write_fst(dt, opt$output)
