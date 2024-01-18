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

# DJ de IRAE/IPAT en todos los períodos / algún período
lookup_list[[2]] <- dty[year %in% 2009:2016 & in214 == TRUE, .N, .(fid)][N == 8, .(fid)]
lookup_list[[2]][, in214AllT := TRUE]
lookup_list[[3]] <- dty[year %in% 2009:2016 & in214 == TRUE, .N, .(fid)][, .(fid)]
lookup_list[[3]][, in214AnyT := TRUE]

# DJ de IVA en todos los períodos / algún período
lookup_list[[4]] <- dty[year %in% 2009:2015 & in217 == TRUE, .N, .(fid)][N == 7, .(fid)]
lookup_list[[4]][, in217AllT := TRUE]
lookup_list[[5]] <- dty[year %in% 2009:2015 & in217 == TRUE, .N, .(fid)][, .(fid)]
lookup_list[[5]][, in217AnyT := TRUE]

# DJ ficta en todos los períodos / algún período
lookup_list[[6]] <- dty[year %in% 2009:2016 & djFict == TRUE, .N, .(fid)][N == 8, .(fid)]
lookup_list[[6]][, djFictAllT := TRUE]
lookup_list[[7]] <- dty[year %in% 2009:2016 & djFict == TRUE, .N, fid][, .(fid)]
lookup_list[[7]][, djFictAnyT := TRUE]
lookup_list[[8]] <- dty[year %in% 2009:2011 & djFict == TRUE, .N, fid][N == 3, .(fid)]
lookup_list[[8]][, djFictAllTPre := TRUE] # balance pre implementación

# Tratamiento absorbente
dty[, receivedInYear := !is.na(nTicketsReceived)] # mas amplio que usando monto
lookup_list[[9]] <- map(
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
lookup_list[[10]] <- dty[, .N, .(fid, hasCovariates)][, .(fid, hasCovariates)]

# Define samples  -----------------------------------------------------------------------

lut <- lookup_list %>%
  reduce(merge, by = "fid", all = TRUE)

lut[, inSample0 := djFictAnyT & (in214AnyT | in217AnyT)]
lut[, inSample1 := djFictAllT & in217AllT & hasCovariates & (!nonAbsorbing | is.na(nonAbsorbing))]
lut[, inSample2 := djFictAnyT & in214AllT & in217AllT & hasCovariates & (!nonAbsorbing | is.na(nonAbsorbing))] # nolint
lut[, inSample3 := djFictAllTPre & hasCovariates]

write_fst(lut, opt$output)
