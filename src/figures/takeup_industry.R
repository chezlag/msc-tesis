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
  .[samples[(inSample3)], on = "fid"]

dts[is.na(dateFirstReception), dateFirstReception := ymd("2020-12-12")]

dts[giro8 %nin% c("Construcción", "Minería; EGA", "No clasificados")] %>%
  ggplot(aes(color = giro8)) +
  stat_ecdf(aes(dateFirstReception), geom = "line", size = 1) +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-12-31"))) +
  ggsci::scale_color_frontiers() +
  labs(
    x = "Fecha primera recepción",
    y = "Función de distribución acumulada",
    color = "Terciles de facturación"
  )

ggsave(opt$output, width = 170, height = 100, units = "mm")
