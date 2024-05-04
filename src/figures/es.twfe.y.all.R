library(groundhog)
pkgs <- c(
  "broom",
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

source("src/lib/theme_set.R")

# Yearly plots  ---------------------------------------------------------------

yvarlist <- c(
  "CR10vatPurchasesK",
  "CR10vatSalesK",
  "CR10netVatLiabilityK"
)
ylablist <- c(
  "Input VAT",
  "Output VAT",
  "Net VAT Liabilty"
)

est <- readRDS("out/analysis/twfe.y.all.fig1.RDS")
addM1 <- data.table(estimate = 0, event = -1, variable = ylablist)
tab <- map(est, broom::tidy, conf.int = TRUE) |>
  map(setDT) |>
  map(\(x) x[, event := c(-7:-2, 0:3)]) |>
  map2(ylablist, \(x, y) x[, variable := y]) |>
  reduce(rbind) |>
  rbind(addM1, use.names = TRUE, fill = TRUE)
tab[, variable := as_factor(variable)]

dodge <- 0.3
tab[event >= -6] %>%
  ggplot(aes(event, estimate, color = variable, shape = variable)) +
  geom_point(position = position_dodge(width = dodge)) +
  geom_errorbar(
    aes(ymin = conf.low, ymax = conf.high),
    position = position_dodge(width = dodge),
    width = 0.25
  ) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_x_continuous(labels = -6:3, breaks = -6:3) +
  scale_shape_manual(values = c(0, 2, 4)) +
  ggsci::scale_color_lancet() +
  labs(x = "Event", y = "Log-points", color = NULL, shape = NULL) +
  cowplot::theme_half_open() +
  theme(legend.position = c(0.05, 0.15), plot.caption = element_text(size = 9))
opt$output <- "out/figures/es.twfe.y.all.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")
