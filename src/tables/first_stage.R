library(groundhog)
pkgs <- c(
  "fastverse",
  "fixest",
  "gt",
  "modelsummary",
  "purrr",
  "stringr"
)
groundhog.library(pkgs, "2024-01-15")

fs <- readRDS("out/analysis/first_stage.RDS")

xlablist <- c("IHS (VAT in e-invoices)", "IHS (N e-invoices)")

rows <- tibble::tribble(
  ~term, ~`1`, ~`2`, ~`3`, ~`4`, ~`5`, ~`6`,
  "Balanced", "X", "", "X", "", "", "",
  "Allowing exits", "", "X", "X", "", "X", "X",
  "Incl. 2016", "", "", "X", "", "", "X"
)
attr(rows, "position") <- 4:6

gtbl <- fs |>
  msummary(
    gof_map = c("nobs", "FE: fid", "FE: year"),
    stars = TRUE,
    output = "gt",
    add_rows = rows
  ) |>
  tab_spanner(label = xlablist[1], columns = 2:4) |>
  tab_spanner(label = xlablist[2], columns = 5:7) |>
  text_replace(pattern = "^probTicketReception$", "Prob (Ticket reception)") |>
  tab_style(
    style = cell_borders(
      sides = c("right"),
      style = "solid"
    ),
    locations = cells_body(
      columns = c(1, 4, 7)
    )
  )

gtsave(gtbl, "out/tables/first_stage.png")
