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

terciles <- dty[, quantile(Scaler1, probs = seq(0, 1, 1 / 3), na.rm = TRUE)]
dty[, size := cut(Scaler1, breaks = terciles, labels = 1:3)]

# Plot ------------------------------------------------------------------------

dty[!is.na(size) & year < 2016 & eticketTaxShare <= 1] |>
  ggplot(aes(size, eticketTaxShare, fill = size)) +
  geom_boxplot() +
  facet_wrap(~year) +
  scale_x_discrete(labels = NULL) +
  scale_fill_d3() +
  labs(x = "Año", y = "Cobertura de IVA compras en e-facturas", fill = "Terciles de facturación")

ggsave(opt$output, width = 170, height = 100, units = "mm")
