library(groundhog)
pkgs <- c(
  "fastverse",
  "forcats",
  "gt",
  "magrittr",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_o.R")

# Input -----------------------------------------------------------------------

est <- readRDS("out/analysis/twfe.y.all.tab1.RDS")

# Table -----------------------------------------------------------------------

ylablist <- c("Input VAT", "Output VAT", "Net VAT liability")
rows <- data.table(
  `Firm & year FE` = rep("Y", 9),
  Balanced = rep(c("Y", "Y", ""), 3),
  `Winsorized at p99` = rep(c("Y", "", "Y"), 3),
  `Winsorized at p95` = rep(c("", "Y", ""), 3),
  `Includes 2016 data` = rep(c("", "", "Y"), 3)
) |>
  t() %>%
  cbind(rownames(.), .) |>
  data.frame()
rownames(rows) <- NULL

gtbl <- est %>%
  msummary(
    gof_map = "nobs",
    stars = c("*" = .05, "**" = .01, "***" = .001),
    output = "gt",
    add_rows = rows
  ) %>%
  text_replace(pattern = "^treatTRUE$", "Post × Received e-invoice") %>%
  tab_spanner(label = ylablist[1], columns = 2:4) %>%
  tab_spanner(label = ylablist[2], columns = 5:7) %>%
  tab_spanner(label = ylablist[3], columns = 8:10) %>%
  tab_style(
    style = cell_borders(
      sides = c("right"),
      style = "solid"
    ),
    locations = cells_body(
      columns = c(1, 4, 7, 10)
    )
  ) |>
  opt_table_font(font = "Times New Roman")

opt$output <- "out/tables/twfe.y.all.overall_att.all.png"
gtsave(gtbl, opt$output)
opt$output <- "out/tables/twfe.y.all.overall_att.all.tex"
gtsave(gtbl, opt$output)

# delete table environment lines
tex <- readLines(opt$output)
grep("\\{longtable\\}", tex, value = TRUE, invert = TRUE) |>
  writeLines(opt$output)
