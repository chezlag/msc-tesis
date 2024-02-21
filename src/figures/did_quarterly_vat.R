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

yvar <- "Scaled1vatPaidK"
spec <- "S1_bal_ctrl_nyt16"

est <- readRDS(paste0("out/analysis/did.q.all.", spec, ".RDS"))
att <- est$simple[[yvar]]

tidy <-
  est$dynamic[[yvar]] |>
  tidy_did() |>
  setDT()

tidy[inrange(event, -20, 12)] %>%
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
  scale_x_continuous(breaks = seq(-20, 12, 4)) +
  scale_y_continuous(labels = scales::dollar_format()) + 
  scale_color_startrek() +
  scale_fill_startrek() +
  labs(
    x = "Trimestres desde el tratamiento", y = "Pagos de IVA",
    caption = paste0("Overall ATT: ", round(att$overall.att, 3))
  ) +
  theme(legend.position = "none")

ggsave(
  paste0("out/figures/did.q.all.", yvar, ".", spec, ".png"),
  width = 170, height = 100, units = "mm"
)
