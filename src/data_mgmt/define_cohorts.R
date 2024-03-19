library(groundhog)
pkgs <- c("fastverse", "fst", "purrr")
groundhog.library(pkgs, "2024-01-15")
source("src/lib/cli_parsing_o.R")

dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE)
dtq <- read_fst("out/data/firms_quarterly.fst", as.data.table = TRUE)

# Define lookup tables of fid --------------------------------------------------

lookup_list <- list()

# Year first e-ticket reception
lookup_list[[1]] <-
  dty[(received), .(G1 = fmin(year) |> as.double()), fid]

# Year received e-tickets share is over median
dty[, eticketTax := grossAmountReceived - netAmountReceived]
dty[, eticketTaxShare := eticketTax / vatPurchases]
median <- dty[, fmedian(eticketTaxShare)]
dty[, receivedSzOverMedian := fifelse(
  !is.na(eticketTaxShare),
  eticketTaxShare > median,
  FALSE
)]
lookup_list[[2]] <-
  dty[(receivedSzOverMedian), .(G2 = fmin(year) |> as.double()), fid]

# Quarter received first e-ticket reception
lookup_list[[3]] <-
  dtq[(received), .(G3 = fmin(quarter) |> as.double()), fid]

# Define treatment groups  -----------------------------------------------------

lut <- list(
  list(data.table(fid = unique(dty$fid))),
  lookup_list
) |>
  unlist(recursive = FALSE) |>
  reduce(merge, by = "fid", all = TRUE)
varlist <- paste0("G", seq_along(lookup_list))
for (v in varlist) lut[is.na(get(v)), (v) := Inf]
lut[, G3 := lubridate::as_date(G3)]

# Export  ----------------------------------------------------------------------

write_fst(lut, opt$output)
