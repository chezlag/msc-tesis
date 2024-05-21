library(groundhog)
pkgs <- c("fastverse", "magrittr", "ggplot2", "ggsci", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

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
tab[, sz := N / fsum(N)]

# Plot ------------------------------------------------------------------------

tab |>
  ggplot(aes(quarterFirstReception, sz, fill = as.factor(yearFirstReception))) +
  geom_col() +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-12-31"))) +
  scale_y_continuous(labels = scales::label_percent(), expand = c(0.01, 0), limits = c(0, 0.3)) +
  ggsci::scale_fill_igv() +
  labs(x = "Trimestre de primera recepción de e-factura", y = NULL, fill = NULL) +
  theme(legend.position = "none")

ggsave("out/figures/takeup_reception.png", width = 170, height = 100, units = "mm")
