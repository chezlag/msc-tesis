library(fastverse)
library(fst)

source("src/lib/cli_parsing_o.R")

bcs <- fread("src/data/bcs_covariates.csv")
cfe <- read_fst("out/data/eticket_static.fst", as.data.table = TRUE)

dt <- merge(bcs, cfe, by = "fid", all = TRUE)

dt[, receivedAnyT := !is.na(dateFirstReception)]
dt[, emittedAnyT := !is.na(dateFirstEmission)]

dt[, yearFirstReception := lubridate::year(dateFirstReception)]
dt[, yearFirstEmission := lubridate::year(dateFirstEmission)]

dt[, hasCovariates := !is.na(sector) & !is.na(birth_date)]

write_fst(dt, opt$output)
