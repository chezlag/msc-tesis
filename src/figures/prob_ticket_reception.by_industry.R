library(groundhog)
pkgs <- c(
  "arsenal",
  "cowplot",
  "fastverse",
  "forcats",
  "ggplot2",
  "ggsci",
  "janitor",
  "scales",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
theme_set(theme_half_open(font_size = 10))
source("src/lib/tag_industry.R")

pr <- fread("out/data/prob_ticket_reception_by_industry.csv")
pr[, industry := tag_industry(demand) |> forcats::fct_reorder(probTicketReception, last, .desc = TRUE)]

indlist <- c("Manufacturing", "Construction", "Finance")

ggplot(pr, aes(year, probTicketReception, group = industry)) +
  geom_line(color = "grey60") +
  geom_line(
    data = ~ subset(.x, industry %in% indlist),
    mapping = aes(color = industry),
    linewidth = 1
  ) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0.01), labels = label_percent()) +
  ggsci::scale_color_d3() +
  labs(
    x = "Year", y = "P(Reception)", color = NULL,
    title = "Probability of receiving an e-invoice"
  )

ggsave("out/figures/prob_ticket_reception.by_industry.png", width = 100, height = 100, units = "mm")
