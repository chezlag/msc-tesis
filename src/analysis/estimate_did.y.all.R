library(groundhog)
pkgs <- c(
  "data.table",
  "magrittr",
  "fst",
  "purrr",
  "stringr",
  "did",
  "jsonlite",
  "arsenal"
)
groundhog.library(pkgs, "2024-01-15")
source("src/lib/cli_parsing_om.R")
source("src/lib/winsorize.R")

set.seed(20240115)

message("Parsing model parameters.")
params <- list(
  opt$sample,
  opt$panel,
  opt$spec,
  opt$group
) %>%
  map(fromJSON) %>%
  unlist(recursive = FALSE)
opt$winsorize <- paste0("0.", opt$winsorize) |> as.numeric()

# Input -----------------------------------------------------------------------

message("Reading data and setting up variables.")

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
  .[eval(parse(text = params$sample_yearly))] %>%
  .[year %in% 2009:2015]

# size and age quartiles – sample specific
quartiles <- dty[, quantile(Scaler1, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, sizeQuartile := cut(Scaler1, breaks = quartiles, labels = 1:4)]
quartiles <- dty[, quantile(as.numeric(birth_date), probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, ageQuartile := cut(as.numeric(birth_date), breaks = quartiles, labels = 1:4)]
dty[is.na(ageQuartile), ageQuartile := 4] # missing as young
quartiles <- dty[, quantile(Scaler3, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, assetsQuartile := cut(Scaler3, breaks = quartiles, labels = 1:4)]
dty[is.na(assetsQuartile), assetsQuartile := floor(runif(1, 1, 5))]

# size and assets deciles – sample specific
deciles <- dty[, quantile(Scaler3, probs = seq(0, 1, 0.1), na.rm = TRUE)] # assets
dty[, assetsDecile := cut(Scaler3, breaks = deciles, labels = 1:10)]
dty[is.na(assetsDecile), assetsDecile := floor(runif(1, 1, 11))]
deciles <- dty[, quantile(Scaler1, probs = seq(0, 1, 0.1), na.rm = TRUE)] # revenue
dty[, sizeDecile := cut(Scaler1, breaks = deciles, labels = 1:10)]
dty[is.na(sizeDecile), sizeDecile := floor(runif(1, 1, 11))]

# outcome variable list
stubnames <- c(
  "vatPurchases",
  "vatSales",
  "netVatLiability"
)
varlist <- c(
  paste0("CR10", stubnames, "K"),
  paste0("CR0", stubnames, "K"),
  paste0("CR20", stubnames, "K"),
  paste0("CR300", stubnames, "K"),
  paste0("CR", stubnames, "KInt")
)
# winsorize continuous variables
for (v in varlist) dty[, (v) := winsorize(get(v), opt$winsorize), year]
# add extensive margin variables
varlist <- c(
  varlist,
  paste0("CR", stubnames, "KExt")
)

# Estimate --------------------------------------------------------------------

message("Estimating group-time ATT.")
ddlist <- varlist %>%
  map(possibly(\(x) {
    did::att_gt(
      yname = x,
      gname = "G1",
      idname = "fid",
      tname = "year",
      xformla = as.formula(params$formula),
      data = dty,
      control_group = params$control_group,
      weightsname = params$wt,
      allow_unbalanced_panel = params$unbalanced,
      clustervars = "fid",
      est_method = "dr",
      cores = opt$threads,
      base_period = "universal"
    )
  }))

message("Estimating overall ATT.")
simple <- ddlist %>%
  map(possibly(\(x) {
    aggte(
      x,
      type = "simple",
      clustervars = "fid",
      bstrap = TRUE,
      na.rm = TRUE
    )
  }))

message("Estimating dynamic ATT.")
dynamic <- ddlist %>%
  map(possibly(\(x) {
    aggte(
      x,
      type = "dynamic",
      clustervars = "fid",
      bstrap = TRUE,
      na.rm = TRUE
    )
  }))

# Output ----------------------------------------------------------------------

# Combine results for export
ret <- list(ddlist, simple, dynamic)
elnames <- c("attgt", "simple", "dynamic")
names(ret) <- elnames
for (el in elnames) names(ret[[el]]) <- varlist

message("Saving results: ", opt$output)
saveRDS(ret, opt$output)
