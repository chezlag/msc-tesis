library(groundhog)
pkgs <- c("data.table", "collapse", "magrittr", "ggplot2", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/theme_set.R")

# Input -----------------------------------------------------------------------

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample1), .(fid)]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]

varlist <- c("vatPurchases", "vatSales", "netVatLiability", "vatPaid")
for (v in varlist) dty[, (paste0(v, "0")) := get(v) <= 0]

tab <- melt(dty, id.vars = c("fid", "year"), measure.vars = paste0(varlist, "0")) %>%
  .[, .(value = fmean(value)), .(variable, year)]
tab[, variable := fcase(
  variable == "vatPurchases0", "IVA Compras",
  variable == "vatSales0", "IVA Ventas",
  variable == "netVatLiability0", "IVA adeudado",
  variable == "vatPaid0", "Pagos de IVA"
)]

# Plot ------------------------------------------------------------------------

tab[year < 2016] %>%
  ggplot(aes(year, value, color = variable)) +
  geom_point() +
  geom_line() +
  ylim(0, NA) +
  labs(x = "Años", y = "Proporción de empresas con Y=0", color = NULL)

ggsave("out/figures/share_zeros.png", width = 170, height = 100, units = "mm")
