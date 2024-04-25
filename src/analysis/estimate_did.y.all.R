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
dty[, sampleA := nomissing & taxTypeRegularAllTPre & turnoverMUI < 1 & taxType %in% c("Simple", "Regular") & in217AllT15 & year < 2016 & !emittedAnyT] # nolint
dty[, sampleB := nomissing & taxTypeSimpleAllTPre & taxType %in% c("Simple", "Regular") & maxTurnoverMUI < 2 & in217AllT15 & year < 2016 & !emittedAnyT] # nolint

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
  rep(dtlist, 3),
  rep(c(FALSE, FALSE, TRUE), 3)
)

tab1 <- pmap(
  params,
  \(y, dt, u) {
    cs21_att_gt(y, "~ sizeDecile + assetsDecile + ageQuartile + division", dt, u) |>
      cs21_simple()
  }
)

fig1 <- map(
  ylist,
  \(y) {
    cs21_att_gt(y, "~ sizeDecile + assetsDecile + ageQuartile + division", sA99) |>
      cs21_dynamic()
  }
)
fig1 |>
  map(tidy_did_list) |>
  msummary(stars = TRUE)

# Robustness: Chen & Roth (2023) ------------------------------------------------

ylist <- allylist[c(1, 4, 7, 10, 2, 5, 8, 11, 3, 6, 9, 12)]

tab2 <- map(
  ylist,
  \(y) {
    cs21_att_gt(y, "~ sizeDecile + assetsDecile + ageQuartile + division", sA99) |>
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
    cs21_att_gt(y, "~ sizeDecile + assetsDecile + ageQuartile + division", dt) |>
      cs21_simple()
  }
)

# Export results ---------------------------------------------------------------

saveRDS(tab1, "out/analysis/did.y.all.tab1.RDS")
saveRDS(fig1, "out/analysis/did.y.all.fig1.RDS")
saveRDS(tab2, "out/analysis/did.y.all.tab2.RDS")
saveRDS(tab3, "out/analysis/did.y.all.tab3.RDS")
