library(groundhog)
pkgs <- c(
  "fastverse",
  "forcats",
  "gt",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_o.R")

# Input -----------------------------------------------------------------------

tab <- fread("src/data/available_data.tsv")

# Build table -----------------------------------------------------------------

gtbl <- tab |>
  gt() |>
  cols_align("left") |>
  opt_table_font(font = "Times New Roman")

opt$output <- "out/tables/available_data.tex"
gtsave(gtbl, opt$output)

# Manually adjust tex table
tex <- readLines(opt$output)
tex <- map_chr(tex, \(x) str_replace(x, "longtable", "tabular"))
col_widths <- c(0.2, 0.5641, 0.1603, 0.21) %>%
  paste0("p{", ., "\\textwidth}") |>
  paste0(collapse = "") %>%
  paste0("\\begin{tabular}{", ., "}")
tex[grep("begin.tabular", tex)] <- col_widths
for (i in c(5, 7, 9)) {
  tex <- append(tex, "\\midrule", after = i)
}
tex <- head(tex, length(tex) - 1)
writeLines(tex, opt$output)
