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

iv <- readRDS("out/analysis/iv.tab2.RDS")

ss <- summary(iv[[1]], stage = 1:2)
ss[c(3:4)] <- iv[c(4, 7)]
names(ss) <- c("First stage", "Input VAT", "Output VAT", "Net VAT liability")

rows <- tibble::tribble(
  ~term, ~`First stage`, ~`Input VAT`, ~`Output VAT`, ~`Net VAT liability`,
  "Balanced", "Y", "Y", "Y", "Y",
  "Firm & year FE", "Y", "Y", "Y", "Y"
)

gtbl <- msummary(ss, gof_map = c("nobs"), stars = TRUE, output = "gt", add_rows = rows) |>
  text_replace(pattern = "IHSeticketTaxK$", "IHS (e-invoices VAT)") |>
  text_replace(pattern = "IHSnTicketsReceived$", "IHS (N e-invoices)") |>
  text_replace(pattern = "^probTicketReception$", "Prob (e-invoice reception)") |>
  opt_table_font(font = "Times New Roman")
gtsave(gtbl, "out/tables/iv_short_alt.png", zoom = 2)
# gtbl <- iv |>
#   msummary(
#     gof_map = c("nobs", "FE: fid", "FE: year"),
#     stars = TRUE,
#     output = "gt",
#     add_rows = rows
#   ) |>
#   tab_spanner(label = ylablist[1], columns = 2:5) |>
#   tab_spanner(label = ylablist[2], columns = 6:9) |>
#   tab_spanner(label = ylablist[3], columns = 10:13) |>
#   text_replace(pattern = "^fit_IHSeticketTaxK$", "IHS (VAT in e-invoices)") |>
#   text_replace(pattern = "^fit_IHSnTicketsReceived$", "IHS (N e-invoices)") |>
#   tab_style(
#     style = cell_borders(
#       sides = c("right"),
#       style = "solid"
#     ),
#     locations = cells_body(
#       columns = c(1, 5, 9, 13)
#     )
#   )
# gtbl

gtsave(gtbl, "out/tables/iv_short_ntickets.png")
