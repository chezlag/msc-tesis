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

est <- readRDS("out/analysis/did.y.all.tab2.RDS")

# Table -----------------------------------------------------------------------

ylablist <- c("Input VAT", "Output VAT", "Net VAT liability")
rows <- data.table(
  `epsilon` = rep(c(.1, 0, .2, 3), 3)
  # Balanced = rep("Y", 12),
  # `Firm & year FE` = rep("Y", 12),
  # `Winsorized at p99` = rep("Y", 12),
  # `Turnover < 3M UI` = rep("Y", 12)
) |>
  t() %>%
  cbind(rownames(.), .) |>
  data.frame()
rownames(rows) <- NULL

est %>%
  map(tidy_did_list) |>
  msummary(
    gof_map = "nobs",
    stars = c("*" = .05, "**" = .01, "***" = .001),
    output = "gt",
    add_rows = rows
  ) %>%
  tab_spanner(label = ylablist[1], columns = 2:5) %>%
  tab_spanner(label = ylablist[2], columns = 6:9) %>%
  tab_spanner(label = ylablist[3], columns = 10:13) %>%
  tab_style(
    style = cell_borders(
      sides = c("right"),
      style = "solid"
    ),
    locations = cells_body(
      columns = c(1, 5, 9, 13)
    )
  ) %>%
  tab_style(
    style = cell_borders(
      sides = c("bottom"),
      style = "solid"
    ),
    locations = cells_body(
      rows = 3
    )
  )

gtsave(gtbl, opt$output)

# delete table environment lines
tex <- readLines(opt$output)
grep("\\{longtable\\}", tex, value = TRUE, invert = TRUE) |>
  writeLines(opt$output)
