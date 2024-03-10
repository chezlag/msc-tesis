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

dty[year < 2016 & eticketTaxShare < 1] %>%
  .[
    , .(
      p25 = quantile(eticketTaxShare, .25),
      p50 = fmedian(eticketTaxShare),
      p75 = quantile(eticketTaxShare, .75)
    ),
    .(year)
  ] %>%
  melt(id.vars = "year") |>
  ggplot(aes(year, value, fill = variable)) +
  geom_col(position = "dodge") +
  scale_fill_futurama() +
  labs(x = "Año", y = "Cobertura de IVA compras en e-facturas", fill = "Percentil de cobertura")

ggsave(opt$output, width = 170, height = 100, units = "mm")
