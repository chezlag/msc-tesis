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
  "Scaled1vatPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1netVatLiabilityK",
  "Scaled1vatPaidK",
  "vatPurchases0",
  "vatSales0",
  "netVatLiability0",
  "vatPaid0"
)
ylablist <- c(
  "IVA Compras",
  "IVA Ventas",
  "IVA adeudado",
  "Pago de IVA",
  "P(IVA Compras > 0)",
  "P(IVA Ventas > 0)",
  "P(IVA adeudado > 0)",
  "P(Pago de IVA > 0)"
)
y_dollar <- c(rep(TRUE, 4), rep(FALSE, 4))
params <- list(yvarlist, ylablist, y_dollar)

pwalk(params, \(x, y, z) gges_by_industry(opt$spec, x, y, 136, 80, y_dollar = z))
