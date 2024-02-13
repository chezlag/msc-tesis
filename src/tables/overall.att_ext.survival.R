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
dtycj <-
  read_fst("out/data/firms_yearly_filled.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  .[year %in% 2010:2016]

estlist <- readRDS("out/analysis/did_yearly_ext.survival_S3.bal.ctrl_aggte.simple.RDS")
tbl <- estlist %>%
  map(tidy_did_list) %>%
  list.filter(str_detect(tidy$y.name[[1]], "in214|in217|anyVatPaid"))
colnames <- list.cases(tbl, tidy$y.name, sorted = FALSE)
var_regex <- str_flatten(colnames, collapse = "|")
ar <- data.frame(
  "Mean Y pre-2011",
  lapply(
    grep(var_regex, colnames, value = TRUE),
    \(x) dtycj[G1 < 2016 & year <= 2011, fmean(get(x), na.rm = TRUE)]
))
names(tbl) <- fct_recode(
  names(tbl),
  "Presenta DJ IRAE/IPAT" = "in214",
  "Presenta DJ IVA" = "in217",
  "Pago de IVA > 0" = "anyVatPaid")
tbl[str_detect(names(tbl), " ")] %>%
  msummary(
    statistic = "conf.int",
    gof_map = c("nobs"),
    add_rows = ar,
    output = "out/tables/did_yearly_ext.survival_S3.bal.ctrl.tex"
  )
