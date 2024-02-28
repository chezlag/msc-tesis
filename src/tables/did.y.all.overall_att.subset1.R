library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "magrittr",
  "forcats",
  "fst",
  "purrr",
  "stringr",
  "rlist"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_o.R")

source("src/lib/tidy_did.R")

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample1), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE) %>%
  .[G1 < Inf]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  .[year %in% 2010:2016]

yvarlist <- c(
  "Scaled1deductPurchasesK",
  "Scaled1RevenueK",
  "Scaled1vatPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1vatDueK"
)
ylablist <- c(
  "Compras reportadas",
  "Ingreso reportado",
  "IVA Compras",
  "IVA Ventas",
  "IVA adeudado"
)

est <- readRDS("out/analysis/did.y.all.S1_bal_ctrl_nyt16.RDS")
tidy <- est$simple[yvarlist] |> map(tidy_did_list)
names(tidy) <- ylablist

ar <- data.frame(
  "Mean Y pre-2011",
  map(
    yvarlist,
    \(x) dty[G1 < Inf & year <= 2011, fmean(get(x), na.rm = TRUE) |> round(3) |> as.character()]
  )
)

tidy %>%
  msummary(
    statistic = "conf.int",
    gof_map = c("nobs"),
    add_rows = ar,
    output = opt$output
  )
