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
  "Scaled1vatPurchasesK",
  "Scaled1vatSalesK",
  "Scaled1netVatLiabilityK",
  "Scaled1vatPaidK"
)
ylablist <- c(
  "IVA Compras",
  "IVA Ventas",
  "IVA adeudado",
  "Pagos de IVA"
)

# Plot data -------------------------------------------------------------------

spec <- "S3_bal_ctrl_nyt16"
est <- readRDS(paste0("out/analysis/did.y.by_size.", spec, ".RDS"))

items <- map(yvarlist, \(x) grep(x, names(est$dynamic))) |> unlist()
sizelist <- 1:3
indlist <- str_remove(names(est$simple)[items], paste0(yvarlist[1], ".")) %>%
  grep("\\.", ., invert = TRUE, value = TRUE)

params <- list(
  est$simple[items],
  rep(sizelist, length(yvarlist)),
  rep(ylablist, each = length(sizelist))
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

tidy <-
  pmap(
    params,
    \(x, y, z) tidy_did(x) %>% setDT() %>% .[, size := paste0("Tercil ", y)] %>% .[, variable := z]
  ) |>
  reduce(rbind)

# Plot ------------------------------------------------------------------------

tidy |>
  ggplot(aes(estimate, size, color = variable)) +
  geom_point(position = position_dodge(width = 0.5)) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), position = position_dodge(width = 0.5)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  ggsci::scale_color_d3() +
  labs(x = "Estimación", y = NULL, color = NULL)

ggsave(opt$output, width = 170, height = 100, units = "mm")
