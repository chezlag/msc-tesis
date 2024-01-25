library(groundhog)
pkgs <- c("data.table", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")

bcs <- fread("src/data/bcs_covariates.csv")
cfe <- read_fst("out/data/eticket_static.fst", as.data.table = TRUE)

dt <- merge(bcs, cfe, by = "fid", all = TRUE)

dt[, receivedAnyT := !is.na(dateFirstReception)]
dt[, emittedAnyT := !is.na(dateFirstEmission)]

dt[, yearFirstReception := lubridate::year(dateFirstReception)]
dt[, yearFirstEmission := lubridate::year(dateFirstEmission)]

dt[is.na(yearFirstReception), yearFirstReception := Inf]
dt[is.na(yearFirstEmission), yearFirstEmission := Inf]

dt[, hasCovariates := !is.na(sector) & !is.na(birth_date)]

write_fst(dt, opt$output)
