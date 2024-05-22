library(groundhog)
pkgs <- c(
  "arsenal",
  "fastverse",
  "fixest",
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

# define event and treatment
dty[, event := year - G1]
for (e in 7:2) dty[, (paste0("treat_M", e)) := event == -e]
for (e in 0:3) dty[, (paste0("treat_", e)) := event == e]
dty[, treat := event >= 0]
dty[, treatedAnyT := event != -Inf]

# Create samples
dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[fid == 14903448 & year == 2009, nomissing := FALSE]
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
intylist <- paste0("CR", stublist, "Int")
xlist <- c("fid", "year", "G1", "birth_date", "Scaler1", "Scaler3", "seccion", "received")
evntlist <- grep("^treat", names(dty), value = TRUE)
keeplist <- c(xlist, allylist, extylist, intylist, evntlist)
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
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treat | fid + year)
    twfe
  }
)

fig1 <- map(
  ylist,
  \(y) {
    setFixest_estimation(data = sA99, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ ..("^treat_") | fid + year)
    twfe
  }
)

# Robustness: Chen & Roth (2023) ------------------------------------------------

ylist <- allylist[c(1, 4, 7, 10, 2, 5, 8, 11, 3, 6, 9, 12)]

tab2 <- map(
  ylist,
  \(y) {
    setFixest_estimation(data = sA99, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treat | fid + year)
    twfe
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
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treat | fid + year)
    twfe
  }
)

# Het. effects: Assets ----------------------------------------------------------

ylist <- paste0("CR10", stublist)
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)

tab4 <- pmap(
  params,
  \(y, dt) {
    dt[, treatAbove := treat & assetsAboveMedian]
    dt[, treatBelow := treat & !assetsAboveMedian]
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treatBelow + treatAbove | fid + year)
    twfe
  }
)

# Het. effects: Final consumption share ----------------------------------------

tab5 <- pmap(
  params,
  \(y, dt) {
    dt[, treatAbove := treat & householdsAboveMedian]
    dt[, treatBelow := treat & !householdsAboveMedian]
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treatBelow + treatAbove | fid + year)
    twfe
  }
)

# Het effects: Exports ---------------------------------------------------------

tab6 <- pmap(
  params,
  \(y, dt) {
    dt[, treatAbove := treat & exportsAboveMedian]
    dt[, treatBelow := treat & !exportsAboveMedian]
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treatBelow + treatAbove | fid + year)
    twfe
  }
)

# Het effects: Imports ---------------------------------------------------------

tab7 <- pmap(
  params,
  \(y, dt) {
    dt[, treatAbove := treat & importsAboveMedian]
    dt[, treatBelow := treat & !importsAboveMedian]
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treatBelow + treatAbove | fid + year)
    twfe
  }
)

# Margen intensivo -------------------------------------------------------------

ylist <- intylist
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)

tab8 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    twfe <- feols(.[y] ~ treat | fid + year)
    twfe
  }
)

# Export results ---------------------------------------------------------------

saveRDS(tab1, "out/analysis/twfe.y.all.tab1.RDS")
saveRDS(fig1, "out/analysis/twfe.y.all.fig1.RDS")
saveRDS(tab2, "out/analysis/twfe.y.all.tab2.RDS")
saveRDS(tab3, "out/analysis/twfe.y.all.tab3.RDS")
saveRDS(tab4, "out/analysis/twfe.y.all.tab4.RDS")
saveRDS(tab5, "out/analysis/twfe.y.all.tab5.RDS")
saveRDS(tab6, "out/analysis/twfe.y.all.tab6.RDS")
saveRDS(tab7, "out/analysis/twfe.y.all.tab7.RDS")
saveRDS(tab8, "out/analysis/twfe.y.all.tab8.RDS")
