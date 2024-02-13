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

source("src/lib/tidy_did.R")

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample1), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE) %>%
  .[G1 < 2016]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  .[year %in% 2010:2016]

main_est <- readRDS("out/analysis/did_yearly_S1.bal.ctrl_aggte.simple.RDS")
main_est_tbl <- main_est %>%
  map(possibly(tidy_did_list, NULL)) %>%
  list.filter(str_detect(tidy$y.name[[1]], "^Scaled1"))

vat_est <- readRDS("out/analysis/did_yearly_S1.bal.base_aggte.simple.RDS") %>%
  map(possibly(tidy_did_list, NULL)) %>%
  list.filter(tidy$y.name[[1]] == "Scaled1vatPaidK")
main_est_tbl[[5]] <- vat_est[[1]]

colnames <- list.cases(main_est_tbl, tidy$y.name, sorted = FALSE)
names(main_est_tbl) <- c(
  "Compras reportadas",
  "Ingreso reportado",
  "IVA Compras",
  "IVA Ventas",
  "Pagos de IVA"
)
var_regex <- "deductPurchases|Revenue|vatPurchases|vatSales|vatPaid"
ar <- data.frame(
  "Mean Y pre-2011",
  map(
    grep(var_regex, colnames, value = TRUE),
    \(x) dty[G1 < 2016 & year <= 2011, fmean(get(x), na.rm = TRUE) |> round(3) |> as.character()]
  )
)
ctrl <- data.table("Controles", "Si", "Si", "Si", "Si", "No")
names(ar) <- names(ctrl); setDT(ar)
rows <- rbind(ar, ctrl)

main_est_tbl %>%
  msummary(
    statistic = "conf.int",
    gof_map = c("nobs"),
    add_rows = ar,
    output = "out/tables/did_yearly_S1.bal.ctrl.tex"
  )
