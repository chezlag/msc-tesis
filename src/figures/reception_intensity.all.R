library(groundhog)
pkgs <- c(
  "arsenal",
  "cowplot",
  "collapse",
  "data.table",
  "forcats",
  "fst",
  "ggplot2",
  "ggsci",
  "lubridate",
  "magrittr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")
source("src/lib/stata_helpers.R")
theme_set(theme)

samples <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[samples, on = "fid"]

dty[, eticketTax := grossAmountReceived - netAmountReceived]
dty[, eticketTaxShare := eticketTax / vatSales]

# Plot ------------------------------------------------------------------------

dty[balanced15 & eticketTaxShare < 1] %>%
  ggplot(aes(year, eticketTaxShare, fill = as_factor(year))) +
  geom_boxplot() +
  ggsci::scale_fill_flatui() +
  scale_x_continuous(breaks = 2011:2016, labels = 2011:2016) +
  scale_y_continuous(labels = scales::label_percent()) +
  labs(
    x = "Year", y = "Coverage of input VAT in e-invoices", fill = NULL,
    title = "Share of Input VAT in e-invoices",
    subtitle = "Among e-invoice recepients"
  ) +
  theme_half_open() +
  theme(legend.position = "none")

opt$output <- "out/figures/reception_intensity_all.png"
ggsave(opt$output, width = 120, height = 100, units = "mm")
