library(groundhog)
pkgs <- c(
  "BMisc",
  "fastverse",
  "fixest",
  "fst",
  "purrr",
  "stringr"
)
groundhog.library(pkgs, "2024-01-15")
source("src/lib/define_industry.R")
source("src/lib/create_controls.R")
source("src/lib/winsorize.R")

set.seed(20240115)

# data prep --------------------------------------------------------------

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) |>
  _[sample, on = "fid"]

dty[, demand := define_industry(seccion)]

dty <- merge(
  dty,
  fread("out/data/prob_ticket_reception_by_industry.csv"),
  by = c("year", "demand"), all.x = TRUE
)
dty[, avgProbTicketReception := fmean(probTicketReception), year]

dty[, eticketTaxK := grossAmountReceivedK - netAmountReceivedK]

cols <- c("eticketTaxK", "nTicketsReceived", "grossAmountReceivedK")
walk(cols, \(x) dty[is.na(get(x)), (x) := 0])
walk(cols, \(x) dty[, (paste0("IHS", x)) := asinh(get(x))])
walk(paste0("IHS", cols), \(x) dty[, (x) := winsorize(get(x), .99), year])
dty[, avgEticketTaxK := fmean(eticketTaxK), year]

stublist <- c("vatPurchasesK", "vatSalesK", "netVatLiabilityK")
walk(stublist, \(x) dty[, (paste0("IHS", x)) := asinh(get(x))])
walk(paste0("IHS", stublist), \(x) dty[, (x) := winsorize(get(x), .99), year])

# define samples
dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[, sampleA := nomissing & taxTypeRegularAllT15 & balanced15 & !emittedAnyT & year < 2016]
dty[, sampleB := nomissing & taxTypeRegularAllT15 & taxTypeRegularAllTPre & !emittedAnyT & year < 2016]
dty[, sampleC := nomissing & taxTypeRegularAllT15 & !emittedAnyT & year < 2016]

ylist <- stublist %>% c(., paste0("IHS", .), paste0("CR", ., "Ext"))
xexoglist <- c("fid", "year", "birth_date", "Scaler1", "Scaler3", "seccion", "received")
xendoglist <- c("eticketTaxK", "nTicketsReceived") %>% c(., paste0("IHS", .))
z <- c("probTicketReception", "avgProbTicketReception", "avgEticketTaxK")
keeplist <- c(ylist, xexoglist, xendoglist, z)
sA99 <- create_controls(dty[(sampleA), ..keeplist])
sA95 <- create_controls(dty[(sampleA), ..keeplist])
sB99 <- create_controls(dty[(sampleB), ..keeplist], balanced = FALSE)
walk(ylist, \(v) sA99[, (v) := winsorize(get(v), .99), year])
walk(ylist, \(v) sA95[, (v) := winsorize(get(v), .95), year])
walk(ylist, \(v) sB99[, (v) := winsorize(get(v), .99), year])

# Estimate IV -----------------------------------------------------------------------

## Baseline results ------------------------------
ylist <- c("IHSvatPurchasesK", "IHSvatSalesK", "IHSnetVatLiabilityK")
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)
tab1 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + assetsDecile^year |
        IHSeticketTaxK ~ probTicketReception
    )
  }
)

## Alternative endogenous regressor -------------
tab2 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + assetsDecile^year |
        IHSnTicketsReceived ~ probTicketReception
    )
  }
)

## Extensive margin ------------------------------
ylist <- c("vatPurchases", "vatSales", "netVatLiability") %>% paste0("CR", ., "KExt")
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)
tab3 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + assetsDecile^year |
        IHSeticketTaxK ~ probTicketReception
    )
  }
)

## Robustness: Additional controls ----------------
ylist <- c("IHSvatPurchasesK", "IHSvatSalesK", "IHSnetVatLiabilityK")
felist <- c(
  "assetsDecile^year",
  "assetsDecile^year + avgProbTicketReception^year",
  "assetsDecile^year + avgProbTicketReception^year + avgEticketTaxK^year"
)
params <- list(
  rep(ylist, each = 3),
  rep(felist, 3)
)
tab4 <- pmap(
  params,
  \(y, fe) {
    setFixest_estimation(data = sA99, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + .[fe] |
        IHSeticketTaxK ~ probTicketReception
    )
  }
)

## Het.: Size ------------------------------------
ylist <- c("IHSvatPurchasesK", "IHSvatSalesK", "IHSnetVatLiabilityK")
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)
tab5 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + assetsDecile^year |
        IHSeticketTaxK / sizeAboveMedian ~
        probTicketReception / sizeAboveMedian
    )
  }
)

## Het.: Importing -------------------------------
ylist <- c("IHSvatPurchasesK", "IHSvatSalesK", "IHSnetVatLiabilityK")
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)
tab6 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + assetsDecile^year |
        IHSeticketTaxK + IHSeticketTaxK:importsAboveMedian ~
        probTicketReception + probTicketReception:importsAboveMedian
    )
  }
)

## Het.: Exports ---------------------------------
ylist <- c("IHSvatPurchasesK", "IHSvatSalesK", "IHSnetVatLiabilityK")
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)
tab7 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + assetsDecile^year |
        IHSeticketTaxK + IHSeticketTaxK:exportsAboveMedian ~
        probTicketReception + probTicketReception:exportsAboveMedian
    )
  }
)

## Het.: HH cons ---------------------------------
ylist <- c("IHSvatPurchasesK", "IHSvatSalesK", "IHSnetVatLiabilityK")
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = 3),
  rep(dtlist, 3)
)
tab8 <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ 1 |
        fid + year + assetsDecile^year |
        IHSeticketTaxK + IHSeticketTaxK:householdsAboveMedian ~
        probTicketReception + probTicketReception:householdsAboveMedian
    )
  }
)

## First stage ----------------------------------
ylist <- xendoglist[3:4]
dtlist <- list(sA99, sA95, sB99)
params <- list(
  rep(ylist, each = length(dtlist)),
  rep(dtlist, length(ylist))
)
first <- pmap(
  params,
  \(y, dt) {
    setFixest_estimation(data = dt, panel.id = ~ fid + year)
    ret <- feols(
      .[y] ~ probTicketReception | fid + year + assetsDecile^year
    )
  }
)

# Export -----------------------------------------------------------------------------
saveRDS(tab1, "out/analysis/iv.tab1.RDS")
saveRDS(tab2, "out/analysis/iv.tab2.RDS")
saveRDS(tab3, "out/analysis/iv.tab3.RDS")
saveRDS(tab4, "out/analysis/iv.tab4.RDS")
saveRDS(tab5, "out/analysis/iv.tab5.RDS")
saveRDS(tab6, "out/analysis/iv.tab6.RDS")
saveRDS(tab7, "out/analysis/iv.tab7.RDS")
saveRDS(tab8, "out/analysis/iv.tab8.RDS")
saveRDS(first, "out/analysis/iv.first.RDS")
