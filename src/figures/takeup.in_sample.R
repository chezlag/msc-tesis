library(groundhog)
pkgs <- c("data.table", "magrittr", "ggplot2", "ggsci", "patchwork", "fst", "lubridate")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")
source("src/lib/theme_set.R")

samples <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <-
  read_fst("out/data/firms_static.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[samples[(activeBusinessAnyT)], on = "fid"]

dts[is.na(dateFirstReception), dateFirstReception := ymd("2020-12-12")]

dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[, sampleA := nomissing & taxTypeRegularAllT15 & balanced15 & year < 2016 & maxTurnoverMUI < 1 & in217 & !is.na(turnover)] # nolint
sampleA <- dty[(sampleA), .N, fid][, .(fid)]


d1 <- dts[, .(fid, dateFirstReception)]
d1[, color := "All firms"]

d2 <- dts[sampleA, on = "fid"] |>
  _[, .(fid, dateFirstReception)]
d2[, color := "Firms in sample"]

dfig <- rbind(d1, d2)
dfig %>%
  ggplot(aes(color = color)) +
  stat_ecdf(aes(dateFirstReception), geom = "step") +
  coord_cartesian(xlim = c(ymd("2012-01-01"), ymd("2016-12-31"))) +
  scale_color_aaas() +
  labs(
    x = "Date first reception",
    y = "Cummulative distribution function",
    color = NULL
  )

opt$output <- "out/figures/takeup.in_sample.png"
ggsave(opt$output, width = 170, height = 100, units = "mm")
