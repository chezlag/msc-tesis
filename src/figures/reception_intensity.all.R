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
date <- "2024-03-10"
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

tab <- dty[year < 2016 & eticketTaxShare < 1] %>%
  .[
    , .(
      p10 = quantile(eticketTaxShare, .10),
      p25 = quantile(eticketTaxShare, .25),
      p50 = fmedian(eticketTaxShare),
      p75 = quantile(eticketTaxShare, .75),
      p90 = quantile(eticketTaxShare, .90)
    ),
    .(year)
  ]

tab |>
  ggplot(aes(year)) +
  geom_line(aes(year, p10), inherit.aes = FALSE) +
  geom_line(aes(year, p25), inherit.aes = FALSE) +
  geom_line(aes(year, p50), inherit.aes = FALSE, linewidth = 2) +
  geom_line(aes(year, p75), inherit.aes = FALSE) +
  geom_line(aes(year, p90), inherit.aes = FALSE) +
  geom_ribbon(aes(ymin = p10, ymax = p25), alpha = .3) +
  geom_ribbon(aes(ymin = p25, ymax = p75), alpha = .6) +
  geom_ribbon(aes(ymin = p75, ymax = p90), alpha = .4) +
  scale_fill_futurama() +
  labs(x = "Año", y = "Cobertura de IVA compras en e-facturas", fill = "Percentil de cobertura")

ggsave(opt$output, width = 170, height = 100, units = "mm")
