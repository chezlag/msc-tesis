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

# Input  ----------------------------------------------------------------------

speclist <- c(
  "S1.bal.ctrl_nt",
  "S1.bal.ctrl_nyt15.orig",
  "S1.bal.ctrl_nyt15.univ",
  "S1.bal.ctrl_nyt16",
  "S1.bal.ctrl_nytInf"
)
yvarlist <- c(
  "Scaled1deductPurchasesK",
  "Scaled1RevenueK",
  "Scaled1vatPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1vatPaidK"
)
ylablist <- c(
  "Compras reportadas",
  "Ingreso reportado",
  "IVA Compras",
  "IVA Ventas",
  "Pagos de IVA"
)

# Plot ------------------------------------------------------------------------

source("src/figures/gges.R")

walk(speclist, \(x) walk2(yvarlist, ylablist, \(y, z) gges(x, y, z)))
