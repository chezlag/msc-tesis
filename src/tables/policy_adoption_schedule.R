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

tab <- fread("src/data/policy_adoption_schedule.csv")

# Build table -----------------------------------------------------------------

gtbl <- tab |>
  gt() |>
  cols_align("center") |>
  tab_style(
    style = cell_borders(
      sides = c("top"),
      style = "solid"
    ),
    locations = cells_body(
      rows = c(3, 5, 7)
    )
  ) |>
  opt_table_font(font = "Times New Roman")

opt$output <- "out/tables/policy_adoption_schedule.png"
gtsave(gtbl, opt$output, zoom = 2)
