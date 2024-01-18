groundhog.library("optparse", "2024-01-15")
option_list <- list(
    make_option(c("-o", "--output"), type = "character"),
    make_option(c("-i", "--input"), type = "character"),
    make_option(c("-m", "--model"), type = "character")
)
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)