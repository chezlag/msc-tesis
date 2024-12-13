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

textdt <- data.frame(
  x = ymd("2015-03-01"),
  y = 0.75,
  label = "Mandatory emission\nfor firms with\nincome > 3M USD\n––>"
)

p1 <- dts %>%
  ggplot() +
  stat_ecdf(aes(dateFirstEmission), geom = "step") +
  geom_vline(
    xintercept = ymd("2016-06-01"), color = "maroon", linetype = "dashed"
  ) +
  scale_x_date(expand = c(0, 0.1)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0.01)) +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-11-30"))) +
  labs(
    x = "First emission date", y = "Cummulative distribution function",
    subtitle = "(a) First emission"
  ) +
  theme(plot.subtitle = element_text(hjust = 0.5))

p2 <- dts %>%
  ggplot() +
  stat_ecdf(aes(dateFirstReception), geom = "step") +
  geom_vline(
    xintercept = ymd("2016-06-01"), color = "maroon", linetype = "dashed"
  ) +
  scale_x_date(expand = c(0, 0.1)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0.01)) +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-11-30"))) +
  labs(
    x = "First reception date", y = NULL,
    subtitle = "(b) First reception"
  ) +
  theme(plot.subtitle = element_text(hjust = 0.5))

p1 | p2

ggsave(opt$output, width = 170, height = 100, units = "mm")
