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

set.seed(20240115)

message("Parsing model parameters.")
message("Sample: ", opt$sample)
message("Panel: ", opt$panel)
message("Spec: ", opt$spec)
params <- list(
  opt$sample,
  opt$panel,
  opt$spec
) %>%
  map(fromJSON) %>%
  unlist(recursive = FALSE)

# Input -----------------------------------------------------------------------

message("Reading data and setting up variables.")

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[eval(parse(text = params$sample_fid)), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE)
dtq <-
  read_fst("out/data/firms_quarterly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  .[eval(parse(text = params$sample_yearly))]

# size and age quartiles – sample specific
quartiles <- dtq[, quantile(Scaler1, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dtq[, sizeQuartile := cut(Scaler1, breaks = quartiles, labels = 1:4)]
quartiles <- dtq[, quantile(as.numeric(birth_date), probs = seq(0, 1, 0.25), na.rm = TRUE)]
dtq[, ageQuartile := cut(as.numeric(birth_date), breaks = quartiles, labels = 1:4)]
dtq[is.na(ageQuartile), ageQuartile := 4] # missing as young
quartiles <- dtq[, quantile(Scaler3, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dtq[, assetsQuartile := cut(Scaler3, breaks = quartiles, labels = 1:4)]
dtq[is.na(assetsQuartile), assetsQuartile := floor(runif(1, 1, 5))]

# outcome variable list
stubnames <- c(
  "vatPaid"
)
varlist <- c(
  paste0("Scaled1", stubnames, "K")
)

# Numerize quarters for estimation
dtq[, quarterV2 := quarter(quarter, with_year = TRUE)]
dtq[, quarterNum := round(quarterV2) + (quarterV2 %% 1) * 2.5 - .25]
dtq[, quarterFirstReceptionV2 := quarter(quarterFirstReception, with_year = TRUE)]
dtq[, quarterFirstReceptionNum := round(quarterFirstReceptionV2) + (quarterFirstReceptionV2 %% 1) * 2.5 - .25]

# remove incomplete quarters from each dataset
patterns <- list(
  "vatPaid|vatRetained"
)
yearlist <- list(
  seq(2010, 2016.75, by = .25)
)
map(patterns, ~ grep(.x, varlist, value = TRUE)) %>%
  walk2(yearlist, ~ dtq[quarterNum %nin% .y, (.x) := NA])

# round quarters up
dtq[, quarterNum := round(4 * quarterNum)]
dtq[, quarterFirstReceptionNum := round(4 * quarterFirstReceptionNum)]
dtq[is.na(quarterFirstReceptionNum), quarterFirstReceptionNum := Inf]

# Estimate --------------------------------------------------------------------

message("Estimating group-time ATT.")
ddlist <- varlist %>%
  map(possibly(\(x) {
    did::att_gt(
      yname = x,
      gname = "quarterFirstReceptionNum",
      idname = "fid",
      tname = "quarterNum",
      xformla = as.formula(params$formula),
      data = dtq,
      control_group = "notyettreated",
      weightsname = params$wt,
      allow_unbalanced_panel = params$unbalanced,
      clustervars = "fid",
      est_method = "dr",
      cores = 16
    )
  }))
names(ddlist) <- varlist

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

message("Saving results: ", opt$output)
saveRDS(ddlist, opt$output)
saveRDS(simple, str_replace(opt$output, ".RDS", "_aggte.simple.RDS"))
saveRDS(dynamic, str_replace(opt$output, ".RDS", "_aggte.dynamic.RDS"))
