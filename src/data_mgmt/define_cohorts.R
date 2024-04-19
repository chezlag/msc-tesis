library(groundhog)
pkgs <- c("fastverse", "fst", "purrr")
groundhog.library(pkgs, "2024-01-15")
source("src/lib/cli_parsing_o.R")

dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE)
mdt <- fread("src/data/dgi_firmas/out/data/mandatory_emission.csv")

# Define lookup tables of fid --------------------------------------------------

lookup_list <- list()

# Year first e-ticket reception
lookup_list[[1]] <-
  dty[(received), .(G1 = fmin(year) |> as.double()), fid]

# Year received e-tickets share is over median
dty[, eticketTax := netAmountReceived]
dty[, eticketTaxShare := eticketTax / Scaler3]
median <- dty[, fmedian(eticketTaxShare)]
dty[, receivedSzOverMedian := fifelse(
  !is.na(eticketTaxShare),
  eticketTaxShare > median,
  FALSE
)]
dty[, receivedSzBelowMedian := fifelse(
  !is.na(eticketTaxShare),
  eticketTaxShare < median,
  FALSE
)]
lookup_list[[2]] <-
  dty[(receivedSzOverMedian), .(G2 = fmin(year) |> as.double()), fid]
lookup_list[[3]] <-
  dty[(receivedSzBelowMedian), .(G3 = fmin(year) |> as.double()), fid]

# Mandated e-ticket adoption
dty[, yearMandatedTurnover := fcase(
  year == 2015 & turnoverMUI > 15, 2016,
  year == 2016 & turnoverMUI > 4, 2017,
  default = Inf
)]
mandated <- merge(
  dty[, fmin(yearMandatedTurnover), fid],
  mdt,
  by = "fid"
)
mandated[, G4 := fifelse(!is.na(mandatedEmissionYear), mandatedEmissionYear, V1)]
lookup_list[[4]] <- mandated[, .(fid, G4, mandated)]


# Define treatment groups  -----------------------------------------------------

lut <- list(
  list(data.table(fid = unique(dty$fid))),
  lookup_list
) |>
  unlist(recursive = FALSE) |>
  reduce(merge, by = "fid", all = TRUE)
varlist <- paste0("G", seq_along(lookup_list))
for (v in varlist) lut[is.na(get(v)), (v) := Inf]

# Export  ----------------------------------------------------------------------
opt$output <- "out/data/cohorts.fst"
write_fst(lut, opt$output)
