library(fastverse)
library(forcats)
library(ggplot2)
library(fst)
library(lubridate)
library(ggsci)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

# Input -----------------------------------------------------------------------

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample3), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  .[cohorts, on = "fid"]

tab <- dty[year < 2016] |>
  collap(vatPurchasesK + vatSalesK + netVatLiabilityK ~ G1 + year) %>%
  melt(id.vars = c("G1", "year"))

tab[, variable := fcase(
  variable == "vatPurchasesK", "(a) Input VAT",
  variable == "vatSalesK", "(b) Output VAT",
  variable == "netVatLiabilityK", "(c) Net VAT liability"
)]

tab[, event := year - G1]

# Plot ------------------------------------------------------------------------

tab %>%
  ggplot(aes(year, value, color = as_factor(G1))) +
  geom_line(data = ~ subset(.x, event >= 0), linetype = "dashed") +
  geom_line(data = ~ subset(.x, event <= 0), linetype = "solid") +
  geom_point(data = ~ subset(.x, event == 0)) +
  facet_grid(~variable) +
  scale_color_locuszoom() +
  scale_y_log10(limits = c(1000, NA), labels = scales::dollar_format()) +
  labs(x = "Year", y = NULL, color = "Year of first e-invoice reception")

opt$output <- "out/figures/time_trends.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")
