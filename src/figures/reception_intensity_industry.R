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

# Tengo 15000 NA de IVA compras y 11000 están en las empresas que reciben
# Es todo por 2016
dty[, .(eticketTax, vatPurchases)] |> skim()
dty[(received) & year < 2016, .(eticketTax, vatPurchases, in217, eticketTaxShare)] |> skim()
skim(dty[eticketTaxShare < 100, .(eticketTaxShare)])
dty[eticketTaxShare > 2 & eticketTaxShare < Inf, .N]

# Plot ------------------------------------------------------------------------

excludedSectors <- c("Construcción", "Minería; EGA", "No clasificados")

dty[giro8 %nin% excludedSectors & year < 2016 & eticketTaxShare < 1] %>%
  .[
    , .(
      p25 = quantile(eticketTaxShare, .25),
      p50 = fmedian(eticketTaxShare),
      p75 = quantile(eticketTaxShare, .75)
    ),
    .(giro8, year)
  ] %>%
  melt(id.vars = c("giro8", "year")) |>
  ggplot(aes(year, value, fill = giro8)) +
  geom_col(position = "dodge") +
  facet_grid(~variable) +
  scale_fill_frontiers() +
  labs(x = "Año", y = "Cobertura de IVA compras en e-facturas", fill = NULL, alpha = NULL)

ggsave(opt$output, width = 170, height = 100, units = "mm")
