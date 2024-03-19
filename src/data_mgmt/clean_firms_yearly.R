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
    as.data.table = TRUE
  )

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
  c(
    "turnover",
    "Revenue",
    "Cost",
    "Profit",
    "CorpTaxDue",
    "deduccFict",
    "activoContable",
    "patrimonioContable"
  )
balformula <- arsenal::formulize(balvarlist, idvars)
cbal <- collap(bal, balformula, fsum) |>
  merge(bal[, .(djFict = fmax(djFict) |> as.logical()), idvars], by = idvars)
rm(bal)

# DJ de ventas por IVA ---------------------------------------------------------

message("Processing VAT affidavits and taxable sales/purchases.")

sls <-
  read_fst("src/data/dgi_firmas/out/data/sales_allF_allY.fst",
    as.data.table = TRUE
  )

slsvarlist <- c(
  "taxableTurnover",
  "vatSales",
  "turnoverNetOfTax",
  "vatPurchases",
  "imputedPurchases",
  "carriedOverVatCredit",
  "excessVatCredit",
  "netVatLiability",
  "vatDue"
)
slsformula <- arsenal::formulize(slsvarlist, idvars)

for (v in slsvarlist) sls[, (v) := get(v) / 1e03] # avoid int overflow in collap
csls <- collap(sls, slsformula, fsum) |>
  merge(
    sls[
      , .(
        CEDE = fmax(CEDE) |> as.logical(),
        exported = fmax(exported) |> as.logical()
      ),
      idvars
    ],
    by = idvars
  )
for (v in slsvarlist) csls[, (v) := get(v) * 1e03]
rm(sls)

# Pagos y retenciones de impuestos ---------------------------------------------

message("Processing tax paid and tax retained by third parties.")

tax <-
  read_fst("src/data/dgi_firmas/out/data/tax_paid_retained.fst",
    as.data.table = TRUE
  )
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
walk2(dtlist, c("in214", "in217", "inPay"), \(x, y) x[, (y) := TRUE])
dt <- dtlist |>
  purrr::reduce(merge, all = TRUE) %>%
  merge(cfetab, all.x = TRUE) %>%
  merge(static, all.x = TRUE) %>%
  .[inrange(year, 2009, 2016)] %>%
  merge(fread("src/data/ui.csv"), all.x = TRUE, by = "year") |>
  merge(ipcy[, .(year, defl)], by = "year")

# Define new variables --------------------------------------------------------

message("Defining new variables.")

# Deflacto y paso a Millones de UI (all variables)
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

# Selecciono variables y relevantes para transformar
varlist <- c("vatPurchases", "vatSales", "netVatLiability", "vatPaid")

# Chen & Roth (2023) y-var
for (v in paste0(varlist, "K")) {
  ymin <- dt[get(v) > 0, fmin(get(v))]
  dt[, y := get(v) / ymin]
  for (e in c(10, 0, 20, 300)) { # full effect
    dt[, (paste0("CR", e, v)) := fifelse(
      get(v) > 0, log(y), -e / 100
    )]
  }
  dt[, (paste0("CR", v, "Ext")) := fifelse( # extensive margin
    get(v) > 0, 1, 0
  )]
  dt[, (paste0("CR", v, "Int")) := fifelse( # intensive margin
    get(v) > 0, log(y), NA_integer_
  )]
}

# Variables para reescalar
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

# covariables
dt[, firm_age := year - birth_year]

# Recepción/emisión de tickets en t
dt[, received := !is.na(nTicketsReceived)]
dt[, emitted := !is.na(nTicketsEmitted)]

# Negocio activo
dt[, anyTaxPaid := totalTaxPaid > 0]
dt[, activeBusiness := in214 & in217]
dt[, activeTaxpayer := activeBusiness & anyTaxPaid]

# Tipo de declaración de impuestos
dt[, taxType := fcase(
  (CEDE), "CEDE",
  RevenueMUI < .305, "Exempt",
  RevenueMUI < 4 & djFict, "Simple",
  RevenueMUI > 4 | !djFict, "Regular"
)]

# Export ----------------------------------------------------------------------

message("Writing output: ", opt$output)

write_fst(dt, opt$output)
