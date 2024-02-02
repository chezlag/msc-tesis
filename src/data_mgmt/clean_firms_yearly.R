library(groundhog)
pkgs <- c(
  "fastverse",
  "fst",
  "lubridate",
  "purrr"
)
groundhog.library(pkgs, "2024-01-15")
source("src/lib/cli_parsing_o.R")
source("src/lib/stata_helpers.R")

# Balances --------------------------------------------------------------------

message("Processing corporate income tax affidavits and balance sheets.")

bal <-
  read_fst("src/data/dgi_firmas/out/data/balances_allF_allY.fst",
           as.data.table = TRUE)

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
balvarlist <-
  c("turnover",
    "Revenue",
    "Cost",
    "Profit",
    "CorpTaxDue",
    "deduccFict",
    "activoContable",
    "patrimonioContable")
balformula <- arsenal::formulize(balvarlist, idvars)
cbal <- collap(bal, balformula, fsum) |>
  merge(bal[, .(djFict = fmax(djFict) |> as.logical()), by = idvars])
rm(bal)

# DJ de ventas por IVA ---------------------------------------------------------

message("Processing VAT affidavits and taxable sales/purchases.")

sls <-
  read_fst("src/data/dgi_firmas/out/data/sales_allF_allY.fst",
           as.data.table = TRUE)

slsvarlist <- c(
  "vatSales",
  "vatPurchases",
  "vatDue",
  "vatDueV2",
  "vatLiability",
  "turnoverNetOfTax",
  "taxableTurnover",
  "deductPurchases",
  "vatDeductions"
)
slsformula <- arsenal::formulize(slsvarlist, idvars)

for (v in slsvarlist) sls[, (v) := get(v) / 1e03] # avoid int overflow in collap
csls <- collap(sls, slsformula, fsum)
for (v in slsvarlist) csls[, (v) := get(v) * 1e03]
rm(sls)

# Pagos y retenciones de impuestos ---------------------------------------------

message("Processing tax paid and tax retained by third parties.")

tax <-
  read_fst("src/data/dgi_firmas/out/data/tax_paid_retained.fst",
           as.data.table = TRUE)
tax[, year := lubridate::year(date)]

taxvarlist <- grep("Paid$|Retained$", names(tax), value = TRUE)
taxformula <- arsenal::formulize(taxvarlist, idvars)

for (v in taxvarlist) tax[, (v) := get(v) / 1e03] # avoid int overflow in collap
ctax <- collap(tax, taxformula, fsum)
for (v in taxvarlist) ctax[, (v) := get(v) * 1e03]
rm(tax)
ctax <- ctax[(totalTaxPaid > 0 | totalTaxRetained > 0)]

# e-ticket ---------------------------------------------------------------------

message("Reading e-ticket transaction data.")

cfetab <- read_fst("out/data/eticket_yearly.fst", as.data.table = TRUE)
cfetab[, inCFE := TRUE]

# Merge ------------------------------------------------------------------------

message("Merging all data sources.")

ipcy <- fread("src/data/ipc_deflactor_2016m12.csv") %>%
  .[lubridate::month(date) == 12] %>%
  .[, year := lubridate::year(date)]

static <- read_fst("out/data/firms_static.fst", as.data.table = TRUE)
static[, inStatic := TRUE]

dtlist <- list(cbal, csls, ctax)
lapply(dtlist, setkeyv, idvars) |> invisible()
map2(dtlist, c("in214", "in217", "inPay"), ~ .x[, (.y) := TRUE])
dt <- dtlist |>
  purrr::reduce(merge, all = TRUE) %>%
  merge(cfetab, all.x = TRUE) %>%
  merge(static, all.x = TRUE) %>%
  .[inrange(year, 2009, 2016)] %>%
  merge(fread("src/data/ui.csv"), all.x = TRUE, by = "year") |>
  merge(ipcy[, .(year, defl)], by = "year")

# Define new variables --------------------------------------------------------

message("Defining new variables.")

# Deflacto y paso a Millones de UI
cfevarlist <- c(
  "grossAmountReceived",
  "netAmountReceived",
  "grossAmountEmitted",
  "netAmountEmitted"
)
varlist <- c(balvarlist, slsvarlist, taxvarlist, cfevarlist)
for (v in varlist) dt[, (paste0(v, "K")) := get(v) / defl]
for (v in varlist) dt[, (paste0(v, "M")) := get(v) / 1e06]
for (v in varlist) dt[, (paste0(v, "MUI")) := get(paste0(v, "M")) / ui]

# Logaritmo e IHS de variables deflactadas
for (v in paste0(varlist, "K")) dt[, (paste0("Log", v)) := log(get(v))]
for (v in paste0(varlist, "K")) dt[, (paste0("IHS", v)) := asinh(get(v))]

# Reescalo usando turnover de 2009-2010 y de los dos años anteriores
create_lag_by_group <- function(dt, condition, oldvarname, newvarname, idvars) {
  dt[eval(parse(text = condition)), (newvarname) := get(oldvarname)]
  dt[, (newvarname) := fmax(get(newvarname)), by = idvars]
}
create_lag_by_group(dt, "year == 2009", "turnoverK", "Turnover2009", "fid")
create_lag_by_group(dt, "year == 2010", "turnoverK", "Turnover2010", "fid")
create_lag_by_group(dt, "year == 2009", "activoContableK", "Assets2009", "fid")
create_lag_by_group(dt, "year == 2010", "activoContableK", "Assets2010", "fid")
create_lag_by_group(dt, "year == 2009", "patrimonioContableK", "Equity2009", "fid")
create_lag_by_group(dt, "year == 2010", "patrimonioContableK", "Equity2010", "fid")
dt[, Scaler1 := (Turnover2009 + Turnover2010) / 2]
dt[, Scaler2 := (shift(turnoverK, 1L) + shift(turnoverK, 2L)) / 2, fid]
dt[, Scaler3 := (Assets2009 + Assets2010) / 2]
dt[, Scaler4 := (Equity2009 + Equity2010) / 2]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled1", v)) := get(v) / Scaler1]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled2", v)) := get(v) / Scaler2]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled3", v)) := get(v) / Scaler3]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled4", v)) := get(v) / Scaler4]

# Compras reportadas al inicio del período y en los dos años anteriores
create_lag_by_group(dt, "year == 2009", "deductPurchasesK", "Purch2009", "fid")
create_lag_by_group(dt, "year == 2010", "deductPurchasesK", "Purch2010", "fid")
dt[, Purch1 := (Purch2009 + Purch2010) / 2]
dt[, Purch2 := (shift(deductPurchasesK, 1L) + shift(deductPurchasesK, 2L)) / 2, fid]

# Franjas de facturación en MUI
dt[(djFict), djFictInBracket1 := RevenueMUI < 2]
dt[(djFict), djFictInBracket2 := inrange(RevenueMUI, 2, 3)]
dt[(djFict), djFictInBracket3 := RevenueMUI > 3]
dt[
  (djFict),
  djFictBracketSwitch :=
    (djFictInBracket1 & !shift(djFictInBracket1)) |
      (djFictInBracket2 & !shift(djFictInBracket2)) |
      (djFictInBracket3 & !shift(djFictInBracket3))
]

# covariables
dt[, firm_age := year - birth_year]

# Recepción/emisión de tickets en t
dt[, received := !is.na(nTicketsReceived)]
dt[, emitted := !is.na(nTicketsEmitted)]

# Negocio activo
dt[, anyTaxPaid := totalTaxPaid > 0]
dt[, activeBusiness := in214 & in217]
dt[, activeTaxpayer := activeBusiness & anyTaxPaid]

# Export ----------------------------------------------------------------------

message("Writing output: ", opt$output)

write_fst(dt, opt$output)
