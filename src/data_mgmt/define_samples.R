library(groundhog)
pkgs <- c("fastverse", "fst", "purrr")
groundhog.library(pkgs, "2024-01-15")
source("src/lib/cli_parsing_o.R")

dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE)

# Define lookup tables of fid -----------------------------------------------------------

lookup_list <- list()

# En todos los períodos
lookup_list[[1]] <- dty[year %in% 2009:2016, .N, fid][N == 8, .(fid)]
lookup_list[[1]][, inAllT := TRUE]

# Tratamiento absorbente
dty[, receivedInYear := !is.na(nTicketsReceived)] # mas amplio que usando monto
lookup_list[[2]] <- map(
  2012:2016,
  ~ dty[year == .x, .(fid, receivedInYear)] %>%
    setnames("receivedInYear", paste0("received", .x))
) %>%
  reduce(merge, by = "fid") %>%
  .[, periodsTreated := rowSums(.SD), .SDcols = patterns("received\\d{4}")] %>%
  .[, nonAbsorbing := fcase(
    received2012, periodsTreated < 5,
    received2013, periodsTreated < 4,
    received2014, periodsTreated < 3,
    received2015, periodsTreated < 2,
    received2016, periodsTreated < 1
  )] %>%
  .[, .(fid, nonAbsorbing)]

# Tiene covariables en BPS
lookup_list[[3]] <- dty[, .N, .(fid, hasCovariates)][, .(fid, hasCovariates)]

# Max turnoverMUI
lookup_list[[4]] <- dty[, .(maxTurnoverMUI = fmax(turnoverMUI)), fid]
lookup_list[[5]] <- dty[year <= 2011, .(maxPreTurnoverMUI = fmax(turnoverMUI)), fid]

# En todos los años / en algún año / todos los años pre (múltiples variables)
cols <- c("in214", "in217", "djFict", "activeBusiness")
colyrs <- list(2009:2016, 2009:2015, 2009:2016, 2009:2015)
lookup_AllT <- map2(
  cols,
  colyrs,
  \(x, y) {
    dty[year %in% y & get(x) == TRUE, .N, fid][N == length(y), .(fid)] %>%
      .[, paste0(x, "AllT") := TRUE]
  }
)
lookup_AnyT <- map2(
  cols,
  colyrs,
  \(x, y) {
    dty[year %in% y & get(x) == TRUE, .N, fid][, .(fid)] %>%
      .[, paste0(x, "AnyT") := TRUE]
  }
)
lookup_AllTPre <- map(
  cols, \(x) {
    dty[year %in% 2009:2011 & get(x) == TRUE, .N, fid][N == 3, .(fid)] %>%
      .[, paste0(x, "AllTPre") := TRUE]
  }
)

# Define samples  -----------------------------------------------------------------------

lut <- list(lookup_list, lookup_AllT, lookup_AnyT, lookup_AllTPre) %>%
  unlist(recursive = FALSE) %>%
  reduce(merge, by = "fid", all = TRUE)

cols <- grep("^fid$|^maxTurnover", names(lut), value = TRUE, invert = TRUE)
lut[, (cols) := lapply(.SD, \(x) fifelse(is.na(x), FALSE, x)),
  .SDcols = cols
]

lut[, inSample0 := djFictAnyT & (in214AnyT | in217AnyT)]
lut[, inSample1 := djFictAllT & in217AllT & (!nonAbsorbing | is.na(nonAbsorbing))]
lut[, inSample2 := djFictAnyT & in214AllT & in217AllT & (!nonAbsorbing | is.na(nonAbsorbing))] # nolint
lut[, inSample3 := djFictAllTPre]
lut[, inSample4 := inSample1 & maxTurnoverMUI < 3]
# new samples
lut[, inSampleB0 := in214AnyT & in217AnyT]
lut[, inSampleB1 := in214AllT & in217AllT & maxPreTurnoverMUI < 4]
lut[, inSampleB2 := inSampleB0 & maxPreTurnoverMUI < 4]

write_fst(lut, opt$output)
