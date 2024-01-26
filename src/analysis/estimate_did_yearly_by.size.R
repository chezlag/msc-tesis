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
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  .[eval(parse(text = params$sample_yearly))]

# size and age quartiles – sample specific
quartiles <- dty[, quantile(Scaler1, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, sizeQuartile := cut(Scaler1, breaks = quartiles, labels = 1:4)]

# outcome variable list
stubnames <- c(
  "deductPurchases",
  "taxableTurnover",
  "vatPurchases",
  "vatSales",
  "vatPaid"
)  
varlist <- c(
  paste0("Scaled1", stubnames, "K"),
  paste0("IHS", stubnames, "K")
)

# remove incomplete years from each dataset
patterns <- list(
  "deductPurchases|taxableTurnover|vatPurchases|vatSales|vatDue",
  "vatPaid"
)
yearlist <- list(
  2009:2015,
  2010:2015
)
map(patterns, ~ grep(.x, varlist, value = TRUE)) %>%
  walk2(yearlist, ~ dty[year %nin% .y, (.x) := NA])

# size quantiles
quantlist <- 1:4

# Estimate --------------------------------------------------------------------

message("Estimating group-time ATT.")
ddlist <-
  map2(rep(varlist, each = length(quantlist)),
       rep(quantlist, length(varlist)),
       possibly(\(x, y) {
         att_gt(
           yname = x,
           gname = "yearFirstReception",
           idname = "fid",
           tname = "year",
           xformla = as.formula(params$formula) ,
           data = dty[sizeQuartile == y],
           control_group = "notyettreated",
           weightsname = params$wt,
           allow_unbalanced_panel = params$unbalanced,
           clustervars = "fid",
           est_method = "dr",
           cores = 8
         )
       },
       NULL))

message("Estimating overall ATT.")
simple <- ddlist %>%
  map(possibly(\(x) {
    aggte(x,
          type = "simple",
          clustervars = "fid",
          bstrap = TRUE)
  },
  NULL))

message("Estimating dynamic ATT.")
dynamic <- ddlist %>%
  map(possibly(\(x) {
    aggte(x,
          type = "dynamic",
          clustervars = "fid",
          bstrap = TRUE)
  },
  NULL))

# Output ----------------------------------------------------------------------

message("Saving results: ", opt$output)
saveRDS(ddlist, opt$output)
saveRDS(simple, str_replace(opt$output, ".RDS", "_aggte.simple.RDS"))
saveRDS(dynamic, str_replace(opt$output, ".RDS", "_aggte.dynamic.RDS"))
