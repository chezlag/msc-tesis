library(arsenal)
library(cowplot)
library(collapse)
library(data.table)
library(forcats)
library(fst)
library(ggplot2)
library(ggsci)
library(lubridate)
library(magrittr)

source("src/lib/theme_set.R")

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
    x = "Year", y = "Coverage of input VAT in e-invoices", fill = NULL
  ) +
  theme_half_open() +
  theme(legend.position = "none")

opt$output <- "out/figures/reception_intensity.all.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")
