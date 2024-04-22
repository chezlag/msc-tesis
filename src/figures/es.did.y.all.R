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

source("src/lib/cli_parsing_os.R")
source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")
source("src/figures/gges.R")

# Yearly plots  ---------------------------------------------------------------

opt$spec <- "S4_bal_ctrl_p99_nytInf"
yvarlist <- c(
  "CR10vatPurchasesK",
  "CR10vatSalesK",
  "CR10netVatLiabilityK"
)
ylablist <- c(
  "Input VAT",
  "Output VAT",
  "Net VAT Liabilty"
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
    ) |> as_factor()]
)

tidy[[1]][, stars := fcase(
  p.value < 0.01, "***",
  p.value < 0.05, "**",
  p.value < 0.10, "*",
  default = ""
)]
tidy[[1]][, caption := paste0(
  variable, ": ", round(estimate, 3), " (", round(std.error, 3), ")", stars
)]
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
  scale_x_continuous(labels = -6:3, breaks = -6:3) +
  scale_shape_manual(values = c(0, 2, 4)) +
  ggsci::scale_color_lancet() +
  labs(x = "Event", y = "Log-points", color = NULL, shape = NULL, caption = caption) +
  theme_half_open() +
  theme(legend.position = c(0.05, 0.2), plot.caption = element_text(size = 9))
opt$output <- paste0("out/figures/es.did.y.all.", opt$spec, ".png")
ggsave(opt$output, width = 170, height = 120, units = "mm")
