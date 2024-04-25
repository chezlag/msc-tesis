library(groundhog)
pkgs <- c("data.table", "magrittr", "ggplot2", "ggsci", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

samples <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <-
  read_fst("out/data/firms_static.fst", as.data.table = TRUE) %>%
  .[samples[(activeBusinessAnyT)], on = "fid"]

dts[is.na(dateFirstReception), dateFirstReception := ymd("2020-12-12")]

dalt <- dts %>%
  .[, .(fid, inSample3, dateFirstReception)]
dfig <- rbind(dalt[, color := "Todas las firmas"], dalt[(inSample3), color := "Firmas en muestra"])
dfig %>%
  ggplot(aes(color = color)) +
  stat_ecdf(aes(dateFirstReception), geom = "step") +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-12-31"))) +
  scale_color_aaas() +
  labs(
    x = "Fecha primera recepción",
    y = "Función de distribución acumulada",
    color = NULL
  )

opt$output <- "out/figures/takeup.in_sample.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")
