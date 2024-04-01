library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
  "did",
  "forcats",
  "ggplot2",
  "ggsci",
  "magrittr",
  "purrr",
  "scales",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_s.R")
source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")
source("src/figures/gges.R")

# Yearly plots  ---------------------------------------------------------------

yvarlist <- c(
  "CR10vatPurchasesK",
  "CR10vatSalesK",
  "CR10netVatLiabilityK"
)
ylablist <- c(
  "IVA Compras",
  "IVA Ventas",
  "IVA adeudado"
)

est <- readRDS(paste0("out/analysis/did.y.all.", opt$spec, ".RDS"))
tidy <- map(
  est[2:3],
  \(x) x %>%
    map(possibly(tidy_did)) %>%
    reduce(rbind) %>%
    setDT() %>%
    .[y.name %in% yvarlist] %>%
    .[, variable := fcase(
      y.name == yvarlist[1], ylablist[1],
      y.name == yvarlist[2], ylablist[2],
      y.name == yvarlist[3], ylablist[3]
    )]
)

tidy[[1]][, stars := fcase(
  p.value < 0.01, "***",
  p.value < 0.05, "**",
  p.value < 0.10, "*",
  default = ""
)]
tidy[[1]][, caption := paste0(variable, ": ", round(estimate, 3), stars)]
caption <- paste(c("Overall ATT", tidy[[1]][, caption]), collapse = "\n")

dodge <- 0.3
tidy[[2]] %>%
  ggplot(aes(event, estimate, color = variable, shape = variable)) +
  geom_point(position = position_dodge(width = dodge)) +
  geom_errorbar(
    aes(ymin = conf.low, ymax = conf.high),
    position = position_dodge(width = dodge),
    width = 0.25
  ) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_x_continuous(labels = -6:2, breaks = -6:2) +
  scale_shape_manual(values = c(0, 2, 4)) +
  ggsci::scale_color_lancet() +
  labs(x = "Evento", y = NULL, color = NULL, shape = NULL) +
  theme_half_open() +
  theme(legend.position = c(0.05, 0.2))

ggsave(opt$output, width = 170, height = 100, units = "mm")
