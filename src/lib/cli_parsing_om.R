library(optparse)
option_list <- list(
    make_option(c("-o", "--output"), type = "character"),
    make_option("--sample", type = "character"),
    make_option("--panel", type = "character"),
    make_option("--spec", type = "character"),
    make_option("--winsorize", type = "integer", default = 99),
    make_option("--group", type = "character"),
    make_option(c("-t", "--threads"), type = "integer", default = 8)
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
