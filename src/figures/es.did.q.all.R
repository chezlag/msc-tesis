library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "did",
  "forcats",
  "ggplot2",
  "ggsci",
  "magrittr",
  "purrr",
  "scales",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_s.R")
source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")
source("src/figures/gges.R")

# Yearly plots  ---------------------------------------------------------------

yvarlist <- c(
  "Scaled1vatPaidK",
  "Scaled1corpTaxPaidK",
  "Scaled1totalTaxPaidK",
  "vatPaid0",
  "corpTaxPaid0",
  "totalTaxPaid0"
)
ylablist <- c(
  "Pagos de IVA",
  "Pagos de IRAE",
  "Pago total de impuestos",
  "P(Pagos de IVA > 0)",
  "P(Pagos de IRAE > 0)",
  "P(Pago total de impuestos > 0)"
)
y_dollar <- c(rep(TRUE, 3), rep(FALSE, 3))
params <- list(yvarlist, ylablist, y_dollar)

pwalk(params, \(x, y, z) possibly(gges_all(opt$spec, x, y, "q", 134, 80, y_dollar = z)))
