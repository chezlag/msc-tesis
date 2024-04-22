library(groundhog)
pkgs <- c("data.table", "magrittr", "ggplot2", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
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
  scale_x_date(expand = c(0, 0.1)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0.01)) +
  coord_cartesian(xlim = c(ymd("2009-01-01"), ymd("2016-11-30"))) +
  labs(
    x = "First emission date", y = "Cummulative distribution function",
    subtitle = "(a) First emission"
  ) +
  theme(plot.subtitle = element_text(hjust = 0.5))
p1

opt$output <- "out/figures/takeup.emission.png"
ggsave(opt$output, width = 85, height = 100, units = "mm")
