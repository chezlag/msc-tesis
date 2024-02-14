library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "did",
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

# Input  ----------------------------------------------------------------------

est <- readRDS("out/analysis/did_yearly_S1.bal.ctrl.RDS")

yvar <- "Scaled1vatPurchasesK"

tidy <- est$dynamic[[yvar]] |> tidy_did() |> setDT()

attgt <- est$attgt[[yvar]]
simple <- est$simple[[yvar]]

sig <- ifelse(
  inrange(0, tidy_did(simple)$conf.low, tidy_did(simple)$conf.high),
  "",
  "**"
)

# Figure ----------------------------------------------------------------------

tidy[y.name == yvar & event >= -4] %>%
  .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
  ggplot(aes(x = event, y = estimate, color = treat, fill = treat)) +
  geom_point(size = 2) +
  geom_rect(
    aes(
      ymin = conf.low,
      ymax = conf.high,
      xmin = event - 0.1,
      xmax = event + 0.1,
      fill = treat
    ),
    alpha = 0.4,
    inherit.aes = FALSE
  ) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_x_continuous(breaks = -4:2) +
  scale_y_continuous(labels = scales::dollar_format()) +
  scale_color_startrek() +
  scale_fill_startrek() +
  labs(
    x = "Años desde el tratamiento", y = "Compras reportadas",
    caption = paste0(
      "p-valor de pre-trends: ", round(attgt$Wpval, 3), "\n",
      "Overall ATT: ", round(simple$overall.att, 3), sig
    )
  ) +
  theme(legend.position = "none")

ggsave("out/figures/new.png", width = 170, height = 100, units = "mm")
