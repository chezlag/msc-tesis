library(groundhog)
pkgs <- c(
  "broom",
  "fastverse",
  "did",
  "fixest",
  "forcats",
  "ggplot2",
  "ggsci",
  "magrittr",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")

# Input ------------------------------------------------------------------------

overall <- readRDS("out/analysis/iv.tab1.RDS")[c(1, 4, 7)]
size <- readRDS("out/analysis/iv.tab5.RDS")[c(1, 4, 7)]
import <- readRDS("out/analysis/iv.tab6.RDS")[c(1, 4, 7)]
export <- readRDS("out/analysis/iv.tab7.RDS")[c(1, 4, 7)]
households <- readRDS("out/analysis/iv.tab8.RDS")[c(1, 4, 7)]

mlist <- list(overall, size, import, export, households)

vcov_list <- mlist |>
  unlist(recursive = FALSE) |>
  map(vcov)

se_sum <- vcov_list |>
  map(possibly(\(x) sqrt(x[1, 1] + x[2, 2] + 2 * x[1, 2]), 0)) |>
  unlist()

dt <- mlist |>
  unlist(recursive = FALSE) |>
  map(tidy) |>
  map(setDT) |>
  map2(
    rep(c("all", "size", "import", "export", "households"), each = length(overall)),
    \(x, y) x[, group := y]
  ) |>
  map2(
    rep(c("Input VAT", "Output VAT", "Net VAT liability"), length(mlist)),
    \(x, y) x[, y.name := y] |> _[, y.name := as_factor(y.name)]
  ) |>
  map2(
    se_sum,
    \(x, y) x[, se.sum := y]
  ) |>
  rbindlist()

dt[, label := fcase(
  group == "all", "Overall ATE",
  group == "size" & str_detect(term, "TRUE"), "Turnover > median",
  group == "size", "Turnover < median",
  group == "import" & str_detect(term, "TRUE"), "High import ind.",
  group == "import", "Low import ind.",
  group == "export" & str_detect(term, "TRUE"), "High export ind.",
  group == "export", "Low export ind.",
  group == "households" & str_detect(term, "TRUE"), "High HH cons. ind.",
  group == "households", "Low HH cons. ind."
) |> as_factor() |> fct_rev()]

dt[, estimate.sum := fsum(estimate), .(group, y.name)]
dt[, estimate.plot := fifelse(
  str_detect(term, "TRUE"), estimate.sum, estimate
)]
dt[, se.plot := fifelse(
  str_detect(term, "TRUE"), se.sum, std.error
)]
dt[, lo.ci := estimate.plot - qnorm(.025) * se.plot]
dt[, hi.ci := estimate.plot + qnorm(.025) * se.plot]

# Plot ------------------------------------------------------------------------

dt[group != "export"] |>
  ggplot(aes(estimate.plot, as.factor(label), color = group)) +
  geom_point() +
  geom_errorbarh(aes(xmin = lo.ci, xmax = hi.ci), height = 0) +
  facet_grid(~y.name) +
  geom_vline(xintercept = 0) +
  geom_vline(
    data = ~ subset(.x, group == "all"),
    mapping = aes(xintercept = estimate.plot),
    linetype = "dashed"
  ) +
  ggsci::scale_color_cosmic() +
  labs(x = "Estimate", y = NULL) +
  ggplot2::theme(legend.position = "none", panel.grid.major.x = element_blank())

ggsave("out/figures/iv_het.png", width = 170, height = 100, units = "mm")
