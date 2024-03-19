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
    as.data.table = TRUE
  )

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
  "Scaler4"
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

# Deflacto
cfevarlist <- c(
  "grossAmountReceived",
  "netAmountReceived",
  "grossAmountEmitted",
  "netAmountEmitted"
)
varlist <- c(taxvarlist, cfevarlist)
for (v in varlist) dt[, (paste0(v, "K")) := get(v) / defl]

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

# Recepción/emisión de tickets en t
dt[, received := !is.na(nTicketsReceived)]
dt[, emitted := !is.na(nTicketsEmitted)]

# Negocio activo
dt[, anyTaxPaid := totalTaxPaid > 0]

# Export ----------------------------------------------------------------------

message("Writing output: ", opt$output)

write_fst(dt, opt$output)
