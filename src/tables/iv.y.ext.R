library(groundhog)
pkgs <- c(
  "fastverse",
  "forcats",
  "gt",
  "magrittr",
  "modelsummary",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_o.R")

# Input -----------------------------------------------------------------------

est <- readRDS("out/analysis/iv.tab3.RDS")

# Table -----------------------------------------------------------------------

ylablist <- c("Input VAT", "Output VAT", "Net VAT liability")
rows <- data.table(
  `Firm & year FE` = rep("Y", 9),
  Balanced = rep(c("Y", "Y", ""), 3),
  `Winsorized at p99` = rep(c("Y", "", "Y"), 3),
  `Winsorized at p95` = rep(c("", "Y", ""), 3),
  `Allowing exits` = rep(c("", "", "Y"), 3)
) |>
  t() %>%
  cbind(rownames(.), .) |>
  data.frame()
rownames(rows) <- NULL

gtbl <- est %>%
  msummary(
    gof_map = "nobs",
    output = "gt",
    stars = TRUE,
    add_rows = rows
  ) %>%
  text_replace(pattern = "IHSeticketTaxK$", "IHS (e-invoices VAT)") |>
  text_replace(pattern = "IHSnTicketsReceived$", "IHS (N e-invoices)") |>
  text_replace(pattern = "^probTicketReception$", "Prob (e-invoice reception)") |>
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

opt$output <- "out/tables/iv.y.ext.png"
gtsave(gtbl, opt$output)
