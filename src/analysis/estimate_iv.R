library(groundhog)
pkgs <- c(
  "fastverse",
  "fixest",
  "fst",
  "purrr",
  "stringr"
)
groundhog.library(pkgs, "2024-01-15")
source("src/lib/winsorize.R")

set.seed(20240115)

# data prep --------------------------------------------------------------

sample <-
  read_fst("out/data/samples.fst", as.data.table = TRUE)
dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[sample, on = "fid"]

dty[, demand := fcase(
  seccion %in% c("A", "B"), "a_b",
  seccion %in% c("D", "E"), "d_e",
  seccion %in% c("G", "I"), "g_i",
  seccion %in% c("H", "J"), "h_j",
  seccion %in% c("M", "N"), "m_n",
  seccion %in% c("P", "Q", "R", "S", "T"), "p_q_r_s_t",
  seccion %in% c("C", "F", "K", "L", "O"), str_to_lower(seccion)
)]
dty <- merge(
  dty,
  fread("out/data/prob_ticket_reception_by_industry.csv"),
  by = c("year", "demand")
)

dty[, eticketTaxK := grossAmountReceivedK - netAmountReceivedK]

cols <- c("eticketTaxK", "nTicketsReceived", "grossAmountReceivedK")
walk(cols, \(x) dty[is.na(get(x)), (x) := 0])
walk(cols, \(x) dty[, (paste0("IHS", x)) := asinh(get(x))])
walk(paste0("IHS", yvarlist), \(x) dty[, (x) := winsorize(get(x), .99), year])

yvarlist <- c("vatPurchasesK", "vatSalesK", "netVatLiabilityK")
walk(yvarlist, \(x) dty[, (paste0("IHS", x)) := asinh(get(x))])
walk(paste0("IHS", yvarlist), \(x) dty[, (x) := winsorize(get(x), .99), year])

# define samples
dty[, nomissing := !is.na(vatPurchases) & !is.na(vatSales) & !is.na(netVatLiability)]
dty[, sampleA := nomissing & taxTypeRegularAllT15 & balanced15 & year < 2016 & !emittedAnyT]
dty[, sampleB := nomissing & taxTypeRegularAllT15 & taxTypeRegularAllTPre & year < 2016 & !emittedAnyT]
dty[, sampleC := nomissing & taxTypeRegularAllT15 & balanced15 & !emittedAnyT]


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
