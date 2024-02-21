library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "forcats",
  "fst",
  "gt",
  "gtsummary",
  "labelled",
  "magrittr",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

# Input -----------------------------------------------------------------------

sample <- read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample1), .(fid)]
dts <- read_fst("out/data/firms_static.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]
dty <-read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]

# Compute pre-treatment means of main variables
varlist <- c(
  "Scaler1",
  "Scaled1deductPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1vatPurchasesK",
  "Scaled1vatPaidK", 
  "fid"
)
pretreat <- 
  collap(dty[year < 2011, ..varlist], ~ fid)

# Create analysis data
varlist <- c(
  "receivedAnyT",
  "emittedAnyT",
  "neverTreated",
  "fid"
)
tab <- dts[, ..varlist] %>%
  merge(pretreat, by = "fid")
tab[, fid := NULL]
tab[, Scaler1 := Scaler1 / 1e06]
tab[, N := 1]

# Label variables
labelledlist <- list(
  Scaler1 = "Ingreso promedio pre-tratamiento (millones de UYU)",
  Scaled1deductPurchasesK = "Compras pre-tratamiento (% de ingreso)",
  Scaled1vatSalesK = "IVA Ventas pre-tratamiento (% de ingreso)",
  Scaled1vatPurchasesK = "IVA Compras pre-tratamiento (% de ingreso)",
  Scaled1vatPaidK = "Pagos de IVA pre-tratamiento (% de ingreso)",
  receivedAnyT = "Recibió alguna e-factura",
  emittedAnyT = "Emitió alguna e-factura",
  neverTreated = "Nunca recibió e-factura",
  N = "Número de empresas"
)
var_label(tab) <- labelledlist

# Build table -----------------------------------------------------------------

tab %>%
  tbl_summary(
    statistic = list(
      N ~ "{n}"
    ),
    missing = "no"
  ) %>%
  modify_header(
    label ~ "**Variable**",
    stat_0 ~ "n(%); Mediana (p25, p75)"
  ) %>%
  as_gt() %>%
  gtsave("out/tables/sample_summary.tex")
