library(fastverse)
library(fst)

source("src/lib/cli_parsing_o.R")

bcs <- fread("src/data/bcs_covariates.csv")
cfe <- read_fst("out/data/eticket_static.fst", as.data.table = TRUE)

dt <- merge(bcs, cfe, by = "fid", all = TRUE)

dt[, received := !is.na(dateFirstReception)]
dt[, emitted := !is.na(dateFirstEmission)]

write_fst(dt, opt$output)
