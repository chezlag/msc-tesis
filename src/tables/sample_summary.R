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
source("src/lib/create_controls.R")

# Input -----------------------------------------------------------------------

sample <- read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <- read_fst("out/data/firms_static.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]
dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]

dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[, sampleDD := nomissing & taxTypeRegularAllT15 & balanced15 & year < 2016 & maxTurnoverMUI < 1 & in217 & !is.na(turnover)] # nolint
dty[, sampleIV := nomissing & taxTypeRegularAllT15 & balanced15 & !emittedAnyT & year < 2016]

sDD <- BMisc::makeBalancedPanel(dty[(sampleDD)], idname = "fid", tname = "year")
sIV <- BMisc::makeBalancedPanel(dty[(sampleIV)], idname = "fid", tname = "year")
sAll <- BMisc::makeBalancedPanel(dty[(sampleAll)], idname = "fid", tname = "year")

# Pre-treatment variables
varlist <- c(
  "turnoverK",
  "vatSalesK",
  "vatPurchasesK",
  "netVatLiabilityK",
  "fid"
)
pretreat <- rbind(
  sDD[year == 2010, ..varlist][, sample := "DD"],
  sIV[year == 2010, ..varlist][, sample := "IV"]
)

# Static variables
varlist <- c(
  "receivedAnyT",
  "emittedAnyT",
  "neverTreated",
  "fid"
)
static <- rbind(
  dts[fid %in% unique(sDD[, fid]), ..varlist][, sample := "DD"],
  dts[fid %in% unique(sIV[, fid]), ..varlist][, sample := "IV"]
)

# Create analysis data
tab <- merge(
  static, pretreat,
  by = c("fid", "sample")
)
tab[, fid := NULL]

# Label variables
labelledlist <- list(
  turnoverK = "Ingreso reportado ($ UYU)",
  vatSalesK = "IVA Ventas ($ UYU)",
  vatPurchasesK = "IVA Compras ($ UYU)",
  netVatLiabilityK = "IVA adeudado ($ UYU)",
  receivedAnyT = "Recibió alguna e-factura",
  emittedAnyT = "Emitió alguna e-factura",
  neverTreated = "Nunca recibió e-factura"
)
var_label(tab) <- labelledlist

# Build table -----------------------------------------------------------------

theme_gtsummary_compact()
theme_gtsummary_language(language = "es", decimal.mark = ",", big.mark = ".")
gtbl <- tab %>%
  tbl_summary(
    missing = "no",
    by = "sample"
  ) %>%
  modify_footnote(update = all_stat_cols() ~ NA) %>%
  as_gt(locale = "es") %>%
  tab_row_group(
    gt::md("**Variables de tratamiento.** n (%)"),
    1:3
  ) %>%
  tab_row_group(
    gt::md("**Resultados pre-tratamiento.** Mediana (p25 – p75)"),
    4:7
  ) %>%
  opt_table_font(font = "Times New Roman")

gtsave(gtbl, "out/tables/sample_summary.png", zoom = 2)
gtsave(gtbl, "out/tables/sample_summary.tex")
