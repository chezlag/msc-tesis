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
  .[samples[(balanced15 & taxTypeRegularAllT15)], on = "fid"]

dty[, eticketTax := grossAmountReceived - netAmountReceived]
dty[, eticketTaxShare := eticketTax / vatSales]

# # Tengo 15000 NA de IVA compras y 11000 están en las empresas que reciben
# # Es todo por 2016
# dty[, .(eticketTax, vatPurchases)] |> skim()
# dty[(received) & year < 2016, .(eticketTax, vatPurchases, in217, eticketTaxShare)] |> skim()
# skim(dty[eticketTaxShare < 100, .(eticketTaxShare)])
# dty[eticketTaxShare > 2 & eticketTaxShare < Inf, .N]

dty[, industry := define_industry(seccion) |> tag_industry()]

# Plot ------------------------------------------------------------------------

p2 <- dty[!is.na(industry) & year >= 2014 & eticketTaxShare < 1] %>%
  ggplot(aes(giro8, eticketTaxShare, fill = giro8)) +
  geom_boxplot() +
  facet_wrap(~year) +
  scale_x_discrete(labels = NULL) +
  scale_fill_frontiers() +
  labs(
    x = NULL, y = "Coverage of input VAT in e-invoices", fill = NULL
  )
p2

opt$output <- "out/figures/reception_intensity.by_industry.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")

dty[giro8 %nin% excludedSectors & year < 2016 & eticketTaxShare < 1] %>%
  .[, lapply(c(.25, .5, .75), \(x) quantile(eticketTaxShare, x)), .(year, giro8)] %>%
  .[order(giro8, year)]
