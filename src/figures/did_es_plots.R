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

speclist <- c(
  "S1_bal_ctrl_nt",
  "S1_bal_ctrl_nyt15",
  "S1_bal_ctrl_nyt16",
  "S1_bal_ctrl_nytInf"
)
yvarlist <- c(
  "Scaled1deductPurchasesK",
  "Scaled1RevenueK",
  "Scaled1vatPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1vatDueK",
  "Scaled1vatPaidK",
  "Scaled1corpTaxPaidK",
  "Scaled1totalTaxPaidK",
  "vatCredit",
  "noVatDue"
)
ylablist <- c(
  "Compras reportadas",
  "Ingreso reportado",
  "IVA Compras",
  "IVA Ventas",
  "IVA adeudado",
  "Pagos de IVA",
  "Pagos de IRAE",
  "Pago total de impuestos",
  "IVA adeudado < 0",
  "IVA adeudado = 0"
)

walk(speclist, \(x) walk2(yvarlist, ylablist, \(y, z) gges_all(x, y, z)))
walk(speclist, \(x) walk2(yvarlist, ylablist, \(y, z) gges_by_industry(x, y, z)))
walk(speclist, \(x) walk2(yvarlist, ylablist, \(y, z) gges_by_size(x, y, z)))

# Quarterly plots -------------------------------------------------------------

speclist <- c(
  "S1_bal_ctrl_nyt16",
  "S1_bal_base_nyt16"
)
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
walk(speclist, \(x) walk2(yvarlist, ylablist, \(y, z) gges_quarterly(x, y, z)))
