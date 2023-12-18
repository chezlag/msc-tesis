library(optparse)
option_list <- list(
    make_option(c("-o", "--output"), type = "character")
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)