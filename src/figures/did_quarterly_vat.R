library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "forcats",
  "ggplot2",
  "ggsci",
  "magrittr",
  "purrr",
  "scales",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")

est <- readRDS("out/analysis/did_quarterly_S1.bal.ctrl.RDS")
att <- readRDS("out/analysis/did_quarterly_S1.bal.ctrl_aggte.simple.RDS")

tidy <-
  readRDS("out/analysis/did_quarterly_S1.bal.ctrl_aggte.dynamic.RDS") |>
  map(possibly(tidy_did)) |>
  reduce(rbind) %>%
  setDT() %>%
  .[, variable := str_remove_all(y.name, "^Scaled[12]|K$") %>% as_factor()]

yvar <- "Scaled2vatPaidK"

tidy[y.name == yvar & inrange(event, -20, 12)] %>%
  .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
  ggplot(aes(x = event, y = estimate, color = treat, fill = treat)) +
  geom_point(size = 2) +
  geom_rect(
    aes(
      ymin = conf.low,
      ymax = conf.high,
      xmin = event - .2,
      xmax = event + .2,
      fill = treat
    ),
    alpha = 0.4,
    inherit.aes = FALSE
  ) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_y_continuous(labels = scales::dollar_format()) + 
  scale_color_startrek() +
  scale_fill_startrek() +
  labs(
    x = "Trimestres desde el tratamiento", y = "Pagos de IVA",
    caption = paste0("Overall ATT: ", round(att[[yvar]]$overall.att, 3))
  ) +
  theme(legend.position = "none")

ggsave("out/figures/did_quarterly_vat.png", width = 170, height = 100, units = "mm")
