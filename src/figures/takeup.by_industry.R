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

dts[is.na(dateFirstReception), dateFirstReception := ymd("2020-12-12")]
dts[, industry := define_industry(seccion) |> tag_industry()]

dts[!is.na(industry)] %>%
  ggplot(aes(color = giro8)) +
  stat_ecdf(aes(dateFirstReception), geom = "line", linewidth = 1) +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-12-31"))) +
  ggsci::scale_color_frontiers() +
  labs(
    x = "Fecha primera recepción",
    y = "Función de distribución acumulada",
    color = NULL
  )

opt$output <- "out/figures/takeup.by_industry.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")
