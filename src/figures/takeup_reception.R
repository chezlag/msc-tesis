library(data.table)
library(magrittr)
library(ggplot2)
library(patchwork)
library(fst)
library(lubridate)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

# Input + wrangle -------------------------------------------------------------

samples <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <-
  read_fst("out/data/firms_static.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[samples[(activeBusinessAnyT)], on = "fid"]

dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[, sampleA := nomissing & taxTypeRegularAllT15 & balanced15 & year < 2016 & maxTurnoverMUI < 1 & in217 & !is.na(turnover)] # nolint
sampleA <- dty[(sampleA), .N, fid][, .(fid)]

tab <- dts[sampleA, on = "fid"] |>
  _[, .N, .(quarterFirstReception, yearFirstReception)]
tab[quarterFirstReception == Inf, quarterFirstReception := ymd("2020-01-01")]
tab[, sz := N / fsum(N)]

# Plot ------------------------------------------------------------------------

p3 <- tab |>
  ggplot(aes(quarterFirstReception, sz, fill = as.factor(yearFirstReception))) +
  geom_col() +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-12-31"))) +
  scale_y_continuous(labels = scales::label_percent(), expand = c(0.01, 0), limits = c(0, 0.3)) +
  ggsci::scale_fill_igv() +
  labs(
    x = "Quarter of first e-invoice reception", y = "Share of recepient firms in sample", fill = NULL,
    subtitle = "(c) Histogram of first e-invoice reception"
  ) +
  theme(legend.position = "none", plot.subtitle = element_text(hjust = 0.5))

p3
ggsave("out/figures/takeup_reception.png", width = 170, height = 100, units = "mm")

# Plot FIG 1 ------------------------------------------------------------------

p1 / p2 | p3
ggsave("out/figures/fig1.png", width = 240, height = 200, units = "mm")
