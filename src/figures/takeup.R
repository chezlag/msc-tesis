library(groundhog)
pkgs <- c("data.table", "magrittr", "ggplot2", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/theme_set.R")

samples <- read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <-
  read_fst("out/data/firms_static.fst", as.data.table = TRUE) %>%
  .[samples[(activeBusinessAnyT)], on = "fid"]

dts[is.na(dateFirstEmission), dateFirstEmission := ymd("2020-01-01")]
dts[is.na(dateFirstReception), dateFirstReception := ymd("2020-01-01")]

p1 <- dts %>%
  ggplot() +
  stat_ecdf(aes(dateFirstEmission), geom = "step") +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-11-30"))) +
  labs(x = "Fecha de primera emisión", y = "Función de distribución acumulada")

p2 <- dts %>%
  ggplot() +
  stat_ecdf(aes(dateFirstReception), geom = "step") +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-11-30"))) +
  labs(x = "Fecha de primera recepción", y = NULL)

p1 | p2

ggsave("out/figures/takeup.png", width = 170, height = 100, units = "mm")
