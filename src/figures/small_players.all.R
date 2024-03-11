library(groundhog)
pkgs <- c("data.table", "collapse", "magrittr", "ggplot2", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

# Input -----------------------------------------------------------------------

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample3), .(fid)]
cfe <-
  read_fst("src/data/dgi_firmas/out/data/eticket_transactions.fst", as.data.table = TRUE)

tab <- merge(
  collap(cfe, grossAmount ~ id_receptor + id_emisor + year, fsum) %>%
    .[sample, on = .(id_receptor = fid)],
  cfe[grossAmount > 0, fsum(grossAmount), .(id_emisor, year)],
  by = c("id_emisor", "year"),
  all.x = TRUE
) %>%
  .[, buyerShare := grossAmount / V1]

# Plot ------------------------------------------------------------------------

xbreaks <- c(1e-6, 1e-4, 1e-2, 1)
xlabels <- c("0.0001%", "0.01%", "1%", "100%")

tab %>%
  ggplot(aes(buyerShare)) +
  stat_ecdf() +
  scale_x_log10(limits = c(1e-8, 1), breaks = xbreaks, labels = xlabels) +
  labs(
    x = "Peso de comprador en ventas de proveedor emisor de e-facturas",
    y = "Función de distribución acumulada"
  )

ggsave(opt$output, width = 170, height = 100, units = "mm")
