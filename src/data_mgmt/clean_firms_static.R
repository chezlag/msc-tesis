library(groundhog)
pkgs <- c("data.table", "fst", "lubridate", "purrr")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")

# get fid for firms not in bcs nor cfe
filelist <- c(
  "src/data/dgi_firmas/out/data/balances_allF_allY.fst",
  "src/data/dgi_firmas/out/data/sales_allF_allY.fst",
  "src/data/dgi_firmas/out/data/tax_paid_retained.fst"
)
fid_only <- filelist |>
  map(\(x) {
    read_fst(x, as.data.table = TRUE) %>%
      .[, .N, fid] %>%
      .[, .(fid)]
  }) |>
  reduce(merge, by = "fid", all = TRUE)

# read datasets with actual information
bcs <- fread("src/data/bcs_covariates.csv")
cfe <- read_fst("out/data/eticket_static.fst", as.data.table = TRUE)

# merge all
dt <- list(bcs, cfe, fid_only) |>
  reduce(merge, by = "fid", all = TRUE)

# create new variables

dt[, receivedAnyT := !is.na(dateFirstReception)]
dt[, emittedAnyT := !is.na(dateFirstEmission)]

dt[, yearFirstReception := fifelse(!is.na(dateFirstReception), year(dateFirstReception), Inf)]
dt[, yearFirstEmission := fifelse(!is.na(dateFirstEmission), year(dateFirstEmission), Inf)]

dt[, quarterFirstReception := floor_date(dateFirstReception, unit = "quarter")]
dt[is.na(quarterFirstReception), quarterFirstReception := Inf]
dt[, quarterFirstEmission := floor_date(dateFirstEmission, unit = "quarter")]
dt[is.na(quarterFirstEmission), quarterFirstEmission := Inf]

dt[, neverTreated := is.na(dateFirstReception)]

dt[, sector := fcase(
  sector == "Agriculture, forestry, fishing, mining and quarrying", "Primary activities",
  !is.na(ind_code_last), sector,
  default = "")]

dt[, ind_code_2d := fifelse(!is.na(ind_code_last), floor(ind_code_last /
                                                           1e3), 99)]

dt[, hasCovariates := !is.na(sector) & !is.na(birth_date)]


write_fst(dt, opt$output)
