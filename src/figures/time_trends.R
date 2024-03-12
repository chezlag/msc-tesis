library(groundhog)
pkgs <- c("data.table", "collapse", "magrittr", "forcats", "ggplot2", "fst", "lubridate", "ggsci")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

# Input -----------------------------------------------------------------------

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample1), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  .[cohorts, on = "fid"]

tab <- dty[year < 2016] |>
  collap(vatPurchasesK + vatSalesK + netVatLiabilityK + vatPaidK ~ G1 + year) %>%
  melt(id.vars = c("G1", "year"))

tab[, event := year - G1]

tab[, variable := fcase(
  variable == "vatPurchasesK", "(a) IVA Compras",
  variable == "vatSalesK", "(b) IVA Ventas",
  variable == "netVatLiabilityK", "(c) IVA adeudado",
  variable == "vatPaidK", "(d) Pagos de IVA"
)]

# Plot ------------------------------------------------------------------------

tab %>%
  ggplot(aes(year, value, color = as_factor(G1))) +
  geom_line(data = ~ subset(.x, event >= 0), linetype = "dashed") +
  geom_line(data = ~ subset(.x, event <= 0), linetype = "solid") +
  geom_point(data = ~ subset(.x, event == 0)) +
  facet_grid(~variable) +
  scale_color_locuszoom() +
  scale_y_log10(limits = c(1000, NA), labels = scales::dollar_format()) +
  labs(x = "Años", y = NULL, color = "Período de inicio del tratamiento")

ggsave(opt$output, width = 170, height = 100, units = "mm")
