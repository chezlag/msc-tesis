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

source("src/lib/cli_parsing_o.R")

# Input -----------------------------------------------------------------------

sample <- read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <- read_fst("out/data/firms_static.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]
dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]

dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[, sampleA := nomissing & taxTypeRegularAllT15 & balanced15 & year < 2016 & maxTurnoverMUI < 1 & in217 & !is.na(turnover)] # nolint
dty[, sampleB := nomissing & taxTypeRegularAllT15 & balanced15 & maxTurnoverMUI < 1 & in217 & !is.na(turnover)] # nolint

dty <- dty[(sampleA)]
dts <- dts[fid %in% unique(dty[, fid])]

# Compute pre-treatment means of main variables
varlist <- c(
  "turnoverK",
  "vatSalesK",
  "vatPurchasesK",
  "netVatLiabilityK",
  "fid"
)
pretreat <- dty[year == 2010, ..varlist]

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
tab[, N := 1]

# Label variables
labelledlist <- list(
  turnoverK = "Ingreso reportado ($ UYU)",
  vatSalesK = "IVA Ventas ($ UYU)",
  vatPurchasesK = "IVA Compras ($ UYU)",
  netVatLiabilityK = "IVA adeudado ($ UYU)",
  receivedAnyT = "Recibió alguna e-factura",
  emittedAnyT = "Emitió alguna e-factura",
  neverTreated = "Nunca recibió e-factura",
  N = "Número de empresas"
)
var_label(tab) <- labelledlist

# Build table -----------------------------------------------------------------

theme_gtsummary_compact()
theme_gtsummary_language(language = "es", decimal.mark = ",", big.mark = ".")
tab %>%
  tbl_summary(
    statistic = list(
      N ~ "{n}"
    ),
    missing = "no"
  ) %>%
  modify_header(
    label ~ "**Variable**",
    stat_0 ~ ""
  ) %>%
  modify_footnote(stat_0 = NA) %>%
  as_gt(locale = "es") %>%
  tab_row_group(
    gt::md("**Variables de tratamiento.** n (%)"),
    1:3
  ) %>%
  tab_row_group(
    gt::md("**Resultados pre-tratamiento.** Mediana (p25 – p75)"),
    4:8
  ) %>%
  gtsave("out/tables/sample_summary.png")
