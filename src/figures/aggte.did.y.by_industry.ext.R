library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "did",
  "forcats",
  "fst",
  "ggplot2",
  "ggsci",
  "magrittr",
  "purrr",
  "scales",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")
source("src/figures/gges.R")

# Define parameters -----------------------------------------------------------

yvarlist <- c(
  "vatPurchases0",
  "vatSales0",
  "netVatLiability0",
  "vatPaid0"
)
ylablist <- c(
  "P(IVA Compras>0)",
  "P(IVA Ventas>0)",
  "P(IVA adeudado>0)",
  "P(Pago de IVA>0)"
)

# Plot data -------------------------------------------------------------------

spec <- "S3_bal_ctrl_nyt16"
est <- readRDS(paste0("out/analysis/did.y.by_industry.", spec, ".RDS"))

items <- map(yvarlist, \(x) grep(x, names(est$simple))) |> unlist()
indlist <- str_remove(names(est$simple)[items], paste0(yvarlist[1], ".")) %>%
  grep("\\.", ., invert = TRUE, value = TRUE)

params <- list(
  est$simple[items],
  rep(indlist, length(yvarlist)),
  rep(ylablist, each = length(indlist))
)

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample3), .(fid)]
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE) %>%
  .[G1 < Inf]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid")
nobs <- dty[, .N, giro8][giro8 %in% indlist][giro8 != "Construcción"]
nobs[, label := paste0("N = ", N)]

tidy <-
  pmap(
    params,
    \(x, y, z) tidy_did(x) %>% setDT() %>% .[, sector := y] %>% .[, variable := z]
  ) |>
  reduce(rbind)

# Plot ------------------------------------------------------------------------

tidy[sector != "Construcción"] |>
  ggplot(aes(estimate, sector, color = variable)) +
  geom_point(position = position_dodge(width = 0.5)) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), position = position_dodge(width = 0.5)) +
  geom_label(data = nobs, aes(x = 0.25, y = giro8, label = label), inherit.aes = FALSE) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  ggsci::scale_color_d3() +
  xlim(NA, .29) +
  labs(x = "Estimación", y = NULL, color = NULL)

ggsave(opt$output, width = 170, height = 100, units = "mm")
