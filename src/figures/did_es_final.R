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

source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")
source("src/figures/gges.R")

# Yearly plots  ---------------------------------------------------------------

spec <- "S1_bal_ctrl_nyt16"
yvarlist <- c(
  "Scaled1deductPurchasesK",
  "Scaled1RevenueK",
  "Scaled1vatDueK",
  "Scaled1totalTaxPaidK"
)
ylablist <- c(
  "Compras reportadas",
  "Ingreso reportado",
  "IVA adeudado",
  "Pago total de impuestos"
)
walk2(yvarlist, ylablist, \(x, y) gges_all(spec, x, y))

yvarlist <- c(
  "Scaled1vatPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1vatPaidK",
  "Scaled1corpTaxPaidK"
)
ylablist <- c(
  "IVA Compras",
  "IVA Ventas",
  "Pagos de IVA",
  "Pagos de IRAE"
)
walk2(yvarlist, ylablist, \(x, y) gges_all(spec, x, y, "y", 85, 100))

# Quarterly plots -------------------------------------------------------------

yvarlist <- c(
  "Scaled1vatPaidK",
  "Scaled1corpTaxPaidK",
  "Scaled1totalTaxPaidK"
)
ylablist <- c(
  "Pagos de IVA",
  "Pagos de IRAE",
  "Pago total de impuestos"
)
walk2(yvarlist[1:2], ylablist[1:2], \(x, y) gges_all(spec, x, y, "q", 85, 100))
gges_all(spec, yvarlist[3], ylablist[3], "q")
