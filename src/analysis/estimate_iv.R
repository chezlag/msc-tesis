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


# Estimate first stage --------------------------------------------------------------

first_stage <- function(y) {
  ret <- purrr::map(
    c("sampleA", "sampleB", "sampleC"),
    \(x) {
      fixest::setFixest_estimation(data = dty[get(x) == TRUE])
      fixest::feols(.[y] ~ probTicketReception | fid + year)
    }
  )
  ret[[1]]$`Balanced` <- "X"
  ret[[2]]$`Allowing exits` <- "X"
  ret[[3]]$`Balanced` <- "X"
  ret[[3]]$`Incl. 2016` <- "X"
  ret
}

xvarlist <- c("IHSeticketTaxK", "IHSnTicketsReceived")
fs <- map(xvarlist, first_stage) |> unlist(recursive = FALSE)

saveRDS(fs, "out/analysis/first_stage.RDS")

# Estimate IV -----------------------------------------------------------------------

estimate_iv <- function(y) {
  ret <- purrr::map(
    c("sampleA", "sampleB"),
    \(s) {
      purrr::map(
        c("IHSeticketTaxK", "IHSnTicketsReceived"),
        \(x) {
          fixest::setFixest_estimation(data = dty[get(s) == TRUE])
          fixest::feols(.[y] ~ 1 | fid + year | .[x] ~ probTicketReception)
        }
      )
    }
  ) |> unlist(recursive = FALSE)
  ret[[1]]$`Balanced` <- "X"
  ret[[2]]$`Balanced` <- "X"
  ret[[3]]$`Allowing exits` <- "X"
  ret[[4]]$`Allowing exits` <- "X"
  ret
}

yvarlist <- c("IHSvatPurchasesK", "IHSvatSalesK", "IHSnetVatLiabilityK")
iv <- map(yvarlist, estimate_iv) |> unlist(recursive = FALSE)

saveRDS(iv, "out/analysis/iv.RDS")
