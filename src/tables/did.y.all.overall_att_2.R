library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "magrittr",
  "forcats",
  "fst",
  "jsonlite",
  "purrr",
  "stringr",
  "rlist"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_oim.R")
source("src/lib/tidy_did.R")

message("Parsing model parameters.")
message("Sample: ", opt$sample)
message("Panel: ", opt$panel)
message("Spec: ", opt$spec)
params <- list(
  opt$sample,
  opt$panel,
  opt$spec,
  opt$group
) %>%
  map(fromJSON) %>%
  unlist(recursive = FALSE)

# Input -----------------------------------------------------------------------

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[eval(parse(text = params$sample_fid)), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE) %>%
  .[eval(parse(text = params$cohorts_yearly))]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  .[eval(parse(text = params$sample_yearly))]

varlist <- c("vatPurchases", "vatSales", "netVatLiability", "vatPaid")
for (v in varlist) dty[, (paste0(v, "0")) := get(v) > 0]

# Table -----------------------------------------------------------------------

yvarlist <- c(
  "vatPurchases0",
  "vatSales0",
  "netVatLiability0",
  "vatPaid0"
)
ylablist <- c(
  "P(IVA Compras > 0)",
  "P(IVA Ventas > 0)",
  "P(IVA adeudado > 0)",
  "P(Pago de IVA > 0)"
)

est <- readRDS(opt$input)
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

# delete table environment lines
tex <- readLines(opt$output)
grep("\\{table\\}", tex, value = TRUE, invert = TRUE) |>
  writeLines(opt$output)
