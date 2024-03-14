library(groundhog)
pkgs <- c(
  "arsenal",
  "collapse",
  "data.table",
  "forcats",
  "fst",
  "ggplot2",
  "ggsci",
  "lubridate",
  "magrittr",
  "skimr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")
source("src/lib/stata_helpers.R")

samples <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[samples[(inSample3)], on = "fid"]

dty[, eticketTax := grossAmountReceived - netAmountReceived]
dty[, eticketTaxShare := eticketTax / vatPurchases]

# Plot ------------------------------------------------------------------------

dty[eticketTaxShare < 1] %>%
  ggplot(aes(year, eticketTaxShare, fill = as_factor(year))) +
  geom_boxplot() +
  scale_fill_futurama() +
  scale_x_continuous(breaks = 2012:2016, labels = 2012:2015) +
  labs(x = "Año", y = "Cobertura de IVA compras en e-facturas", fill = NULL) +
  theme(legend.position = "none")

ggsave(opt$output, width = 170, height = 100, units = "mm")
