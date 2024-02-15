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

idvars <- c("fid", "quarter")

# Pagos y retenciones de impuestos ---------------------------------------------

message("Processing tax paid and tax retained by third parties.")

tax <-
  read_fst("src/data/dgi_firmas/out/data/tax_paid_retained.fst",
           as.data.table = TRUE)

taxvarlist <- grep("Paid$|Retained$", names(tax), value = TRUE)
taxformula <- arsenal::formulize(taxvarlist, idvars)

for (v in taxvarlist) tax[, (v) := get(v) / 1e03] # avoid int overflow in collap
ctax <- collap(tax, taxformula, fsum)
for (v in taxvarlist) ctax[, (v) := get(v) * 1e03]
rm(tax)
ctax <- ctax[(totalTaxPaid > 0 | totalTaxRetained > 0)]
ctax[, inPay := TRUE]
ctax[, year := lubridate::year(quarter)]

# e-ticket ---------------------------------------------------------------------

message("Reading e-ticket transaction data.")

cfetab <- read_fst("out/data/eticket_quarterly.fst", as.data.table = TRUE)
cfetab[, inCFE := TRUE]

# Merge ------------------------------------------------------------------------

message("Merging all data sources.")

ipc <- fread("src/data/ipc_deflactor_2016m12.csv")
static <- read_fst("out/data/firms_static.fst", as.data.table = TRUE)
yearlyvarlist <- c(
  "fid",
  "year",
  "Scaler1",
  "Scaler2",
  "Scaler3",
  "Scaler4",
  "Purch1",
  "Purch2"
)
yearly <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[, ..yearlyvarlist]

dt <- ctax |>
  merge(cfetab, all.x = TRUE, by = c("fid", "quarter")) %>%
  merge(static, all.x = TRUE, by = "fid") %>%
  merge(yearly, all.x = TRUE, by = c("fid", "year")) %>%
  .[inrange(year, 2009, 2016)] %>%
  merge(ipc[, .(date, defl)], by.x = "quarter", by.y = "date", all.x = TRUE)

# Define new variables --------------------------------------------------------

message("Defining new variables.")

# Deflacto y paso a Millones de UI
cfevarlist <- c(
  "grossAmountReceived",
  "netAmountReceived",
  "grossAmountEmitted",
  "netAmountEmitted"
)
varlist <- c(taxvarlist, cfevarlist)
for (v in varlist) dt[, (paste0(v, "K")) := get(v) / defl]

# Transformo variables de interés
for (v in paste0(varlist, "K")) dt[, (paste0("Log", v)) := log(get(v) + 1)]
for (v in paste0(varlist, "K")) dt[, (paste0("IHS", v)) := asinh(get(v))]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled1", v)) := get(v) / Scaler1]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled2", v)) := get(v) / Scaler2]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled3", v)) := get(v) / Scaler3]
for (v in paste0(varlist, "K")) dt[, (paste0("Scaled4", v)) := get(v) / Scaler4]

# Recepción/emisión de tickets en t
dt[, received := !is.na(nTicketsReceived)]
dt[, emitted := !is.na(nTicketsEmitted)]

# Negocio activo
dt[, anyTaxPaid := totalTaxPaid > 0]

# Export ----------------------------------------------------------------------

message("Writing output: ", opt$output)

write_fst(dt, opt$output)
