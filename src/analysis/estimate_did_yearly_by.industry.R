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

# outcome variable list
stubnames <- c(
  "deductPurchases",
  "Revenue",
  "vatPurchases",
  "vatSales",
  "vatPaid"
)
varlist <- c(
  paste0("Scaled1", stubnames, "K")
)

# remove incomplete years from each dataset
patterns <- list(
  "deductPurchases|taxableTurnover|vatPurchases|vatSales",
  "vatPaid"
)
yearlist <- list(
  2009:2015,
  2010:2015
)
map(patterns, ~ grep(.x, varlist, value = TRUE)) %>%
  walk2(yearlist, ~ dty[year %nin% .y, (.x) := NA])

# sector list
dty[sector == "Agriculture, forestry, fishing, mining and quarrying", sector := "Primary activities"]
industrylist <- c("Construction", "Services", "Retail trade", "Manufacturing", "Wholesale", "Primary activities")

# replace sector with ind_code_2d if spec == ctrl
if (grepl("ctrl", opt$spec)) {
  params$formula <- "~ ageQuartile + assetsQuartile"
}

# Estimate --------------------------------------------------------------------

message("Estimating group-time ATT.")
ddlist <-
  map2(rep(varlist, each = length(industrylist)),
       rep(industrylist, length(varlist)),
       possibly(\(x, y) {
         att_gt(
           yname = x,
           gname = "G1",
           idname = "fid",
           tname = "year",
           xformla = as.formula(params$formula),
           data = dty[sector == y],
           control_group = params$control_group,
           weightsname = params$wt,
           allow_unbalanced_panel = params$unbalanced,
           clustervars = "fid",
           est_method = "dr",
           cores = opt$threads,
           base_period = "universal"
         )
       }))
names(ddlist) <- varlist

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

# Combine results for export
ret <- list(ddlist, simple, dynamic)
elnames <- c("attgt", "simple", "dynamic")
names(ret) <- elnames

# Name estimation output
estnames <- map2(
  rep(varlist, each = length(industrylist)), 
  rep(industrylist, length(varlist),
  \(x, y) paste0(x, ".", y)
) |>
  unlist()
for(el in elnames) names(ret[[el]]) <- estnames

message("Saving results: ", opt$output)
saveRDS(ret, opt$output)
