library(groundhog)
pkgs <- c("data.table", "did", "ggplot2", "magrittr")
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/tidy_did.R")

gges <- function(spec, yvar, ylab) {
  est <- readRDS(paste0("out/analysis/did.y.by_industry.", spec, ".RDS"))
  tidy <- est$dynamic[[yvar]] |>
    tidy_did() |>
    setDT()
  attgt <- est$attgt[[yvar]]
  simple <- est$simple[[yvar]]

  tidy[y.name == yvar & inrange(event, -4, 4)] %>%
    .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
    ggplot(aes(x = event, y = estimate, color = variable)) +
    geom_point(position = position_dodge(width = .3)) +
    geom_rect(
      aes(
        ymin = conf.low,
        ymax = conf.high,
        xmin = event - .1,
        xmax = event + .1,
        fill = variable,
        alpha = fct_rev(treat)
      ),
      # alpha = 0.4,
      inherit.aes = FALSE,
      position = position_dodge(width = .3)
    ) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_x_continuous(breaks = -3:2) +
    scale_color_d3() +
    scale_fill_d3() +
    scale_alpha_discrete(range = c(0.2, 0.55)) +
    labs(
      x = "Años desde el tratamiento", y = ylab
    ) +
    theme(legend.position = "none")

  ggsave(
    paste0("out/figures/did.y.by_industry.", yvar, ".", spec, ".png"),
    width = 170,
    height = 100,
    units = "mm"
  )
}
