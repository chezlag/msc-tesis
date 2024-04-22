library(groundhog)
pkgs <- c("fastverse", "forcats", "magrittr", "ggplot2", "patchwork", "fst", "scales")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
theme_set(theme_half_open(font_size = 10))
source("src/lib/tag_industry.R")

tkt <- fread("out/data/share_eticket_by_industry.csv")
tkt[, industry := tag_industry(supply) |> forcats::fct_reorder(szTicket, last, .desc = TRUE)]

indlist <- c("Manufacturing", "Construction", "Finance")

p2 <- tkt %>%
  ggplot(aes(year, szTicket, group = industry)) +
  geom_line(color = "grey60", linewidth = .5) +
  geom_line(data = ~ subset(.x, industry %in% indlist), mapping = aes(color = industry), linewidth = 1) +
  ggsci::scale_color_d3() +
  scale_x_continuous(expand = c(0, 0.1)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0.01), labels = label_percent()) +
  labs(
    x = "Year", y = "Share of output in e-invoices",
    subtitle = "b) Share of industry output in e-invoices", color = NULL
  ) +
  theme(plot.subtitle = element_text(hjust = 0.5))

opt$output <- "out/figures/share_output_eticket.by_industry.png"
ggsave(opt$output, width = 100, height = 100, units = "mm")

# ggsave("out/figures/takeup.share.png", width = 170, height = 100, units = "mm")
