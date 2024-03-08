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
  .[(inSample3), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE) %>%
  .[G1 < Inf]
dtycj <-
  read_fst("out/data/firms_yearly_filled.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  .[year %in% 2010:2016]

yvarlist <- c("anyVatPaid", "in214", "in217")
ylablist <- c("Pago IVA > 0", "Presenta DJ IVA", "Presenta DJ IRAE/IPAT")

est <- readRDS("out/analysis/did.y.ext_survival.S3_bal_ctrl_nyt16.RDS")
tidy <- est$simple[yvarlist] |> map(tidy_did_list)
names(tidy) <- ylablist

ar <- data.frame(
  "Mean Y pre-2011",
  lapply(
    yvarlist,
    \(x) dtycj[G1 < Inf & year <= 2011, fmean(get(x), na.rm = TRUE)]
  )
)

tidy %>%
  msummary(
    statistic = "conf.int",
    gof_map = c("nobs"),
    add_rows = ar,
    output = opt$output
  )
