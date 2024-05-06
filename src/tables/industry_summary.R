library(groundhog)
pkgs <- c(
  "fastverse",
  "forcats",
  "gt",
  "labelled",
  "magrittr",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_o.R")
source("src/lib/tag_industry.R")
source("src/lib/tag_section.R")

# Input -----------------------------------------------------------------------

couf <- fread("out/data/cou_final.csv")[
  supply_industry != "INDUSTRY" & supply_industry != "T", .(supply_industry, households, exports)
]
couf[, industry := tag_section(supply_industry) |> as_factor()]
var_label(couf) <- c("", "HH Cons.", "Exports", "Section")

coui <- fread("out/data/cou_intermediate.csv")[
  supply_industry == "IMPORTS", .(demand_industry, szDemand)
]
coui[, industry := tag_section(demand_industry) |> as_factor()]
var_label(coui) <- c("", "Imports", "Section")

prob <- fread("out/data/prob_ticket_reception_by_industry.csv") |>
  _[, industry := tag_section(demand_industry) |> as_factor()] |>
  dcast(industry ~ year, value.var = "probTicketReception")

tab <- merge(
  couf[, .(industry, households, exports)],
  coui[, .(industry, szDemand)],
  by = "industry"
) |>
  merge(prob, by = "industry")

# Table -----------------------------------------------------------------------

gtbl <- tab |>
  gt() |>
  fmt_percent(decimals = 1) |>
  fmt_percent(decimals = 2, columns = 2:4) |>
  cols_align(align = "center") |>
  cols_align(align = "left", columns = 1) |>
  cols_width(2:4 ~ px(90)) |>
  tab_style(
    style = cell_fill(color = "#F6F9D6"),
    locations = cells_body(
      columns = households,
      rows = households > fmedian(households)
    )
  ) |>
  tab_style(
    style = cell_fill(color = "#F6F9D6"),
    locations = cells_body(
      columns = exports,
      rows = exports > fmedian(exports)
    )
  ) |>
  tab_style(
    style = cell_fill(color = "#F6F9D6"),
    locations = cells_body(
      columns = szDemand,
      rows = szDemand > fmedian(szDemand)
    )
  ) |>
  tab_style(
    style = cell_borders(sides = c("right"), style = "solid"),
    locations = cells_body(columns = c(1, 4, 12))
  ) |>
  tab_spanner(label = "Prob. of receiving e-ticket", columns = 5:12) %>%
  tab_spanner(label = "Share of output destined to", columns = 2:4) %>%
  opt_table_font(font = "Times New Roman")

opt$output <- "out/tables/industry_summary.png"
gtsave(gtbl, opt$output)
