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
  read_fst("out/data/cohorts.fst", as.data.table = TRUE) %>%
  .[G1 < 2016]
size <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[, .(fid, Scaler1)] %>%
  unique()
dtycj <-
  read_fst("out/data/firms_yearly_filled.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid") %>%
  merge(size, by = "fid", all.x = TRUE) %>%
  .[eval(parse(text = params$sample_yearly))] %>% 
  .[year %in% 2010:2016]

# size and age quartiles – sample specific
quartiles <- dtycj[, quantile(Scaler1.y, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dtycj[, sizeQuartile := cut(Scaler1.y, breaks = quartiles, labels = 1:4)]
quartiles <- dtycj[, quantile(as.numeric(birth_date), probs = seq(0, 1, 0.25), na.rm = TRUE)]
dtycj[, ageQuartile := cut(as.numeric(birth_date), breaks = quartiles, labels = 1:4)]
dtycj[is.na(ageQuartile), ageQuartile := 4] # missing as young
quartiles <- dtycj[, quantile(Scaler3, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dtycj[, assetsQuartile := cut(Scaler3, breaks = quartiles, labels = 1:4)]
dtycj[is.na(assetsQuartile), assetsQuartile := floor(runif(1, 1, 5))]


# outcome variable list
varlist <- c(
  "anyVatPaid", 
  "anyCorpTaxPaid",
  "anyOtherTaxPaid",
  "anyTaxPaid",
  "anyRecordedActivity",
  "exit",
  "in214",
  "in217"
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
      data = dtycj,
      control_group = "notyettreated",
      weightsname = params$wt,
      allow_unbalanced_panel = params$unbalanced,
      clustervars = "fid",
      est_method = "dr",
      cores = 8
    )
  }))

message("Estimating overall ATT.")
simple <- ddlist %>%
  map(possibly(\(x) {
    aggte(x,
          type = "simple",
          clustervars = "fid",
          bstrap = TRUE,
          na.rm = TRUE)
  }))

message("Estimating dynamic ATT.")
dynamic <- ddlist %>%
  map(possibly(\(x) {
    aggte(x,
          type = "dynamic",
          clustervars = "fid",
          bstrap = TRUE,
          na.rm = TRUE)
  }))

# Output ----------------------------------------------------------------------

message("Saving results: ", opt$output)
saveRDS(ddlist, opt$output)
saveRDS(simple, str_replace(opt$output, ".RDS", "_aggte.simple.RDS"))
saveRDS(dynamic, str_replace(opt$output, ".RDS", "_aggte.dynamic.RDS"))
