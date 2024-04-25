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
source("src/lib/tidy_did.R")

# Input -----------------------------------------------------------------------

est <- readRDS("out/analysis/did.y.all.tab1.RDS")

# Table -----------------------------------------------------------------------

ylablist <- c("Input VAT", "Output VAT", "Net VAT liability")
rows <- data.table(
  Balanced = rep("Y", 9),
  `Firm & year FE` = rep("Y", 9),
  `Winsorized at p99` = rep(c("Y", "", "Y"), 3),
  `Winsorized at p95` = rep(c("", "Y", ""), 3),
  `Turnover < 3M UI` = rep(c("Y", "Y", ""), 3),
  `Turnover < 4M UI` = rep(c("", "", "Y"), 3)
) |>
  t() %>%
  cbind(rownames(.), .) |>
  data.frame()
rownames(rows) <- NULL

gtbl <- tab1 %>%
  map(tidy_did_list) |>
  msummary(
    gof_map = "nobs",
    stars = c("*" = .05, "**" = .01, "***" = .001),
    output = "gt",
    add_rows = rows
  ) %>%
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
  )

gtsave(gtbl, opt$output)

# delete table environment lines
tex <- readLines(opt$output)
grep("\\{longtable\\}", tex, value = TRUE, invert = TRUE) |>
  writeLines(opt$output)
