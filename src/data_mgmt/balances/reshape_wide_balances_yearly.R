# clean_balances.r

library(fastverse)
library(fst)
library(optparse)
option_list <- list(
    make_option(c("-o", "--output"), type = "character"),
    make_option(c("-y", "--year"), type = "numeric"),
    make_option(c("-f", "--form"), type = "numeric")
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# read data
dataPath <- paste0("src/data/dgi/balances/Balance_1006_2148_2149_", opt$year, ".csv")
dat <- fread(dataPath)
dat[, importe := as.integer(round(importe))]
setorder(dat, cod_formulario, identificador)

# identificador de la firma
setnames(dat, "identificador", "fid")

# Selecciono un único formulario

subset <- dat[cod_formulario == opt$form]

# wide reshape
subset[, variable := paste0("v", nro_de_linea)]
wsubset <- dcast(subset,
    fid ~ variable,
    value.var = "importe"
)

# new variables
wsubset[, form := opt$form]
wsubset[, year := opt$year]

# save dataset
write_fst(wsubset, opt$out)