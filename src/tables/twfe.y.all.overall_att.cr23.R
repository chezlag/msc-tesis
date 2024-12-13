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

est <- readRDS("out/analysis/twfe.y.all.tab2.RDS")

# Table -----------------------------------------------------------------------

ylablist <- c("Input VAT", "Output VAT", "Net VAT liability")
rows <- data.table(
  `ε` = rep(c(.1, 0, .2, 3), 3)
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
  ) |>
  opt_table_font(font = "Times New Roman")

opt$output <- "out/tables/twfe.y.all.overall_att.cr23.png"
gtsave(gtbl, opt$output)
opt$output <- "out/tables/twfe.y.all.overall_att.cr23.tex"
gtsave(gtbl, opt$output)

# Manually adjust tex table
tex <- readLines(opt$output)
tex <- append(tex, "\\midrule", after = grep("Num.Obs", tex) - 1)
pval_ref <- c(
  "\\midrule",
  "\\multicolumn{13}{l}{* p $<$ 0.05, ** p $<$ 0.01, *** p $<$ 0.001} \\\\"
)
tex <- append(tex, pval_ref, after = grep("bottomrule", tex) - 1)
tex <- map_chr(tex, \(x) str_replace(x, "longtable", "tabular"))
tex <- head(tex, length(tex) - 4)
tex[length(tex)] <- "\\end{tabular}%"
writeLines(tex, opt$output)
