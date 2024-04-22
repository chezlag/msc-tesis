library(groundhog)
pkgs <- c("fastverse", "magrittr", "ggplot2", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

tkt <- fread("out/data/share_eticket_by_industry.csv")

tab <- collap(tkt, turnoverInTicket + total ~ year, fsum)
tab[, szTicket := turnoverInTicket / total]

p2 <- tab %>%
  ggplot(aes(year, szTicket)) +
  geom_line() +
  scale_x_continuous(expand = c(0, 0.1)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0.01)) +
  labs(
    x = "Year", y = "Share of output in e-invoices",
    subtitle = "(b) Share of output in e-invoices"
  ) +
  theme(plot.subtitle = element_text(hjust = 0.5))
p2

opt$output <- "out/figures/share_output_eticket.png"
ggsave(opt$output, width = 85, height = 100, units = "mm")

# ggsave("out/figures/takeup.share.png", width = 170, height = 100, units = "mm")
