library(groundhog)
pkgs <- c(
  "collapse",
  "data.table",
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

source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")

spec <- "S3_bal_ctrl_nyt16"
est <- readRDS(paste0("out/analysis/did.y.ext_survival.", spec, ".RDS"))

tidy <-
  est$dynamic |>
  map(possibly(tidy_did)) |>
  reduce(rbind) %>%
  setDT()

yvar <- c("anyVatPaid", "in214", "in217")
newname <- c("Pago IVA > 0", "Presenta DJ IVA", "Presenta DJ IRAE/IPAT")
walk2(yvar, newname, \(x, y) tidy[y.name == x, variable := y])

tidy[y.name %in% yvar] %>%
  .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
  ggplot(aes(x = event, y = estimate, color = variable)) +
  geom_point(position = position_dodge(width = .3)) +
  geom_rect(
    aes(
      ymin = conf.low,
      ymax = conf.high,
      xmin = event - .1,
      xmax = event + .1,
      fill = variable,
      alpha = fct_rev(treat)
    ),
    inherit.aes = FALSE,
    position = position_dodge(width = .3)
  ) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_x_continuous(breaks = -4:2) +
  scale_color_d3() +
  scale_fill_d3() +
  scale_alpha_discrete(range = c(0.2, 0.55)) +
  labs(
    x = "Años desde el tratamiento", y = "Probabilidad de supervivencia",
    color = NULL, fill = NULL, alpha = NULL
  )

ggsave("out/figures/did_ext.survival.png", width = 170, height = 100, units = "mm")
