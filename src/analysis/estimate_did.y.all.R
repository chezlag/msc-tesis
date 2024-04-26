library(groundhog)
pkgs <- c(
  "arsenal",
  "did",
  "fastverse",
  "fst",
  "jsonlite",
  "modelsummary",
  "purrr",
  "stringr"
)
groundhog.library(pkgs, "2024-01-15")
set.seed(20240115)
source("src/lib/cli_parsing_om.R")
source("src/lib/winsorize.R")
source("src/model/cs21.R")
source("src/lib/create_controls.R")
source("src/lib/tidy_did.R")

# Input -----------------------------------------------------------------------

message("Reading data and setting up variables.")

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
cohorts <-
  read_fst("out/data/cohorts.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"] %>%
  merge(cohorts, by = "fid")

# Create samples
dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[, sampleA := nomissing & taxTypeRegularAllT15 & balanced15 & year < 2016 & maxTurnoverMUI < 1 & in217 & !is.na(turnover)] # nolint
dty[, sampleB := nomissing & taxTypeRegularAllT15 & balanced15 & maxTurnoverMUI < 1 & in217 & !is.na(turnover)] # nolint

# Subset samples & create controls
stublist <- c("vatPurchasesK", "vatSalesK", "netVatLiabilityK")
allylist <- c(
  paste0("CR10", stublist),
  paste0("CR0", stublist),
  paste0("CR20", stublist),
  paste0("CR300", stublist)
)
extylist <- paste0("CR", stublist, "Ext")
xlist <- c("fid", "year", "G1", "birth_date", "Scaler1", "Scaler3", "division")
keeplist <- c(xlist, allylist, extylist)
sA99 <- create_controls(dty[(sampleA), ..keeplist])
sA95 <- create_controls(dty[(sampleA), ..keeplist])
sB99 <- create_controls(dty[(sampleB), ..keeplist])
walk(allylist, \(v) sA99[, (v) := winsorize(get(v), .99), year])
walk(allylist, \(v) sA95[, (v) := winsorize(get(v), .95), year])
walk(allylist, \(v) sB99[, (v) := winsorize(get(v), .99), year])

# Main results --------------------------------------------------------------------

ylist <- paste0("CR10", stublist)
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)

tab1 <- pmap(
  params,
  \(y, dt) {
    cs21_att_gt(y, "~ ageQuartile + division", dt, TRUE) |>
      cs21_simple()
  }
)
# tab1 |>
#   map(tidy_did_list) |>
#   msummary(stars = TRUE)

fig1 <- map(
  ylist,
  \(y) {
    cs21_att_gt(y, "~ ageQuartile + division", sA99, TRUE) |>
      cs21_dynamic()
  }
)
# fig1 |>
#   map(tidy_did_list) |>
#   msummary(stars = TRUE)

# Robustness: Chen & Roth (2023) ------------------------------------------------

ylist <- allylist[c(1, 4, 7, 10, 2, 5, 8, 11, 3, 6, 9, 12)]

tab2 <- map(
  ylist,
  \(y) {
    cs21_att_gt(y, "~ ageQuartile + division", sA99) |>
      cs21_simple()
  }
)

# Extensive margin --------------------------------------------------------------

ylist <- extylist
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)

tab3 <- pmap(
  params,
  \(y, dt) {
    cs21_att_gt(y, "~ ageQuartile + division", dt) |>
      cs21_simple()
  }
)

# Export results ---------------------------------------------------------------

saveRDS(tab1, "out/analysis/did.y.all.tab1.RDS")
saveRDS(fig1, "out/analysis/did.y.all.fig1.RDS")
saveRDS(tab2, "out/analysis/did.y.all.tab2.RDS")
saveRDS(tab3, "out/analysis/did.y.all.tab3.RDS")
