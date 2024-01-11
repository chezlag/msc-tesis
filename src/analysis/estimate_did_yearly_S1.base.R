library(data.table)
library(magrittr)
library(fst)
library(purrr)
library(did)

# input data
sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE) %>%
  .[(inSample1), .(fid)]
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]

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

# analysis period
yearlist <- list(
  2009:2015,
  2009:2015,
  2009:2016,
  2009:2015,
  2009:2015,
  2009:2015,
  2010:2015
)

# estimate group-time ATT
ddlist <- varlist %>%
  map2(
    .y = yearlist,
    ~ did::att_gt(
      yname = .x,
      gname = "yearFirstReception",
      idname = "fid",
      tname = "year",
      xformla = ~1,
      data = dty[year %in% .y],
      control_group = "notyettreated",
      clustervars = "fid",
      est_method = "dr",
      cores = 8
    )
  )

# estimate aggregate ATT
simple <- ddlist %>%
  map(aggte,
    type = "simple",
    clustervars = "fid",
    bstrap = TRUE
  )

# estimate dynamic ATT
dynamic <- ddlist %>%
  map(aggte,
    type = "dynamic",
    clustervars = "fid",
    bstrap = TRUE
  )

# save results
saveRDS(ddlist, "out/analysis/did_yearly_S1.base.RDS")
saveRDS(simple, "out/analysis/did_yearly_S1.base_aggte.simple.RDS")
saveRDS(dynamic, "out/analysis/did_yearly_S1.base_aggte.dynamic.RDS")
