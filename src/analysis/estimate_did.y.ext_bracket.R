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
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_om.R")

set.seed(20240115)

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

message("Reading data and setting up variables.")

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[eval(parse(text = params$sample_fid)), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE) %>%
  .[eval(parse(text = params$cohorts_yearly))]
.[G1 < 2016]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  .[eval(parse(text = params$sample_yearly))]

# size and age quartiles – sample specific
quartiles <- dty[, quantile(Scaler1, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, sizeQuartile := cut(Scaler1, breaks = quartiles, labels = 1:4)]
quartiles <- dty[, quantile(as.numeric(birth_date), probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, ageQuartile := cut(as.numeric(birth_date), breaks = quartiles, labels = 1:4)]
dty[is.na(ageQuartile), ageQuartile := 4] # missing as young
quartiles <- dty[, quantile(Scaler3, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, assetsQuartile := cut(Scaler3, breaks = quartiles, labels = 1:4)]
dty[is.na(assetsQuartile), assetsQuartile := floor(runif(1, 1, 5))]

# define dependent variables
dty[, bracket1to2 := djFictInBracket2 & shift(djFictInBracket1)]
dty[, bracket2to3 := djFictInBracket3 & shift(djFictInBracket2)]
dty[, bracket1to3 := djFictInBracket3 & shift(djFictInBracket1)]
dty[, bracketShiftUp := bracket1to2 | bracket2to3 | bracket1to3]
dty[, bracket2to1 := djFictInBracket1 & shift(djFictInBracket2)]
dty[, bracket3to2 := djFictInBracket2 & shift(djFictInBracket3)]
dty[, bracket3to1 := djFictInBracket1 & shift(djFictInBracket3)]
dty[, bracketShiftDown := bracket2to1 | bracket3to2 | bracket3to1]
dty[, bracketShiftAny := bracketShiftUp | bracketShiftDown]

# outcome variable list
varlist <- c(
  "bracketShiftAny",
  "bracketShiftUp",
  "bracketShiftDown",
  "bracket1to2",
  "bracket2to3",
  "bracket1to3"
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
    aggte(x,
      type = "simple",
      clustervars = "fid",
      bstrap = TRUE,
      na.rm = TRUE
    )
  }))

message("Estimating dynamic ATT.")
dynamic <- ddlist %>%
  map(possibly(\(x) {
    aggte(x,
      type = "dynamic",
      clustervars = "fid",
      bstrap = TRUE,
      na.rm = TRUE,
      min_e = -4,
      max_e = 3
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
