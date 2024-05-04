library(groundhog)
pkgs <- c("arsenal", "data.table", "magrittr", "ggplot2", "ggsci", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

samples <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <-
  read_fst("out/data/firms_static.fst", as.data.table = TRUE) %>%
  .[samples[(balanced15 & taxTypeRegularAllT15)], on = "fid"]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[samples[(balanced15 & taxTypeRegularAllT15)], on = "fid"]

dts[is.na(dateFirstReception), dateFirstReception := ymd("2020-12-12")]

# terciles <- dty[, quantile(Scaler1, probs = seq(0, 1, 1 / 3), na.rm = TRUE)]
quantiles <- dty[, quantile(Scaler1, probs = seq(0, 1, .20), na.rm = TRUE)]
dty[, size := cut(Scaler1, breaks = quantiles, labels = 1:5)]

tab <-
  merge(dts, dty[year == 2011, .(fid, size)], by = "fid", all.x = TRUE)

tab[!is.na(size)] %>%
  ggplot(aes(color = as.factor(size))) +
  stat_ecdf(aes(dateFirstReception), geom = "line", linewidth = 1) +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-12-31"))) +
  scale_color_d3() +
  labs(
    x = "Fecha primera recepción",
    y = "Función de distribución acumulada",
    color = "Quintiles de facturación"
  )

opt$output <- "out/figures/takeup.by_size.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")
