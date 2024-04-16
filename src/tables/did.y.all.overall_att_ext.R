library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "magrittr",
  "forcats",
  "fst",
  "gt",
  "purrr",
  "stringr",
  "rlist"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_oR")
source("src/lib/tidy_did.R")

# Input -----------------------------------------------------------------------

specs <- c(
  "S4_bal_ctrl_p99_nytInf",
  "S4_bal_ctrl_p95_nytInf",
  "S4_unbal_ctrl_p99_nytInf"
)
est <- specs %>%
  map(\(x) readRDS(paste0("out/analysis/did.y.all.", x, ".RDS"))) %>%
  map(\(x) x$simple) %>%
  map(\(x) map(x, possibly(tidy_did_list)))

est[c(1, 3)] %>%
  walk(\(x) walk(x, \(y) setDT(y$glance) %>% .[, `Winsor at p99` := "Y"]))
est[[2]] %>%
  walk(\(y) setDT(y$glance) %>% .[, `Winsor at p95` := "Y"])
est[1:2] %>%
  walk(\(x) walk(x, \(y) setDT(y$glance) %>% .[, Balanced := "Y"]))
est[[3]] %>%
  walk(\(y) setDT(y$glance) %>% .[, Unbalanced := "Y"])

# Table -----------------------------------------------------------------------

yvarlist <- c(
  "CRvatPurchasesKExt",
  "CRvatSalesKExt",
  "CRnetVatLiabilityKExt"
)
ylablist <- c(
  "P(IVA Compras > 0)",
  "P(IVA Ventas > 0)",
  "P(IVA adeudado > 0)"
)

# Select estimations
selection <- list(
  est[[1]][[yvarlist[1]]],
  est[[2]][[yvarlist[1]]],
  est[[3]][[yvarlist[1]]],
  est[[1]][[yvarlist[2]]],
  est[[2]][[yvarlist[2]]],
  est[[3]][[yvarlist[2]]],
  est[[1]][[yvarlist[3]]],
  est[[2]][[yvarlist[3]]],
  est[[3]][[yvarlist[3]]]
)

gtbl <- selection %>%
  msummary(
    gof_map = c("Balanced", "Unbalanced", "Winsor at p99", "Winsor at p95", "nobs"),
    stars = TRUE,
    output = "gt"
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
