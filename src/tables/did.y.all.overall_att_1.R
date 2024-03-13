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

# Table -----------------------------------------------------------------------

yvarlist <- c(
  "Scaled1vatPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1netVatLiabilityK",
  "Scaled1vatPaidK"
)
ylablist <- c(
  "IVA Compras",
  "IVA Ventas",
  "IVA adeudado",
  "Pago de IVA"
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
    gof_map = c("nobs"),
    stars = TRUE,
    add_rows = ar,
    output = opt$output
  )

# delete table environment lines
tex <- readLines(opt$output)
grep("\\{table\\}", tex, value = TRUE, invert = TRUE) |>
  writeLines(opt$output)
