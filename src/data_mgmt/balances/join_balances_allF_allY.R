library(fastverse)
library(fst)

# CLI parsing
source("src/lib/cli_parsing_o.r")

# data list
filelist <- list.files(
    path = "out/data/tmp/",
    pattern = "balances_F\\d{4}_allY_clean.fst",
    full.names = TRUE
)
# read and append
dat <- lapply(filelist, read_fst, as.data.table = TRUE) |>
    rbindlist(fill = TRUE, use.names = TRUE)
names(dat)
# order
setorder(dat, fid, year, form)

# save
write_fst(dat, opt$out)