library(data.table)
library(magrittr)
library(fst)
library(purrr)
library(stringr)
library(did)

# input data
sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample1), .(fid)]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]

# size quartiles – mean revenue 2009–2010
quartiles <- dty[, quantile(Scaler1, probs = seq(0, 1, 0.25), na.rm = TRUE)]
dty[, sizeQuartile := cut(Scaler1, breaks = quartiles, labels = 1:4)]

# dependent variables
varlist <- c(
  "deductPurchases",
  "taxableTurnover",
  "Revenue",
  "vatPurchases",
  "vatSales",
  "vatDue",
  "vatPaid"
) %>%
  paste0("Scaled1", ., "K")
varlist %<>% c(., str_replace(., "Scaled1", "Scaled2"))

# analysis period
yearlist <- list(
  2009:2015,
  2009:2015,
  2009:2016,
  2009:2015,
  2009:2015,
  2009:2015,
  2010:2015
) %>%
  rep(2)

# estimate
ddlist <- varlist %>%
  map2(
    .y = yearlist,
    ~ did::att_gt(
      yname = .x,
      gname = "yearFirstReception",
      idname = "fid",
      tname = "year",
      xformla = ~ sector + sizeQuartile,
      data = dty[year %in% .y],
      control_group = "notyettreated",
      clustervars = "fid",
      est_method = "dr",
      cores = 8
    )
  )

simple <- ddlist %>%
  map(possibly(aggte, otherwise = NULL),
    type = "simple",
    clustervars = "fid",
    bstrap = TRUE
  )

dynamic <- ddlist %>%
  map(possibly(aggte, otherwise = NULL),
    type = "dynamic",
    clustervars = "fid",
    bstrap = TRUE
  )

saveRDS(ddlist, "out/analysis/did_yearly_S1.ctrl.RDS")
saveRDS(simple, "out/analysis/did_yearly_S1.ctrl_aggte.simple.RDS")
saveRDS(dynamic, "out/analysis/did_yearly_S1.ctrl_aggte.dynamic.RDS")
