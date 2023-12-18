library(fastverse)
library(fst)

# CLI parsing
library(optparse)
option_list <- list(
    make_option(c("-o", "--output"), type = "character"),
    make_option(c("-f", "--form"), type = "numeric")
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# data list
filelist <- list.files(
    path = "out/data/tmp/",
    pattern = paste0("balances_wide_F", opt$form, "_Y\\d{4}.fst"),
    full.names = TRUE
)
# read and append
dat <- lapply(filelist, read_fst, as.data.table = TRUE) |>
    rbindlist(fill = TRUE, use.names = TRUE)
names(dat)

# save
write_fst(dat, opt$out)