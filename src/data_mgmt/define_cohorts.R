library(groundhog)
pkgs <- c("fastverse", "fst", "purrr")
groundhog.library(pkgs, "2024-01-15")
source("src/lib/cli_parsing_o.R")

dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE)

# Define lookup tables of fid --------------------------------------------------

lookup_list <- list()

# Year first e-ticket reception
lookup_list[[1]] <-
  dty[(received), .(G1 = fmin(year) |> as.double()), fid]

# Year received e-tickets share is over 5% of 2009–2010 turnover
median <- fmedian(dty$Scaled1netAmountReceivedK)
dty[, receivedSzOverMedian := fifelse(!is.na(Scaled1netAmountReceivedK),
                                      Scaled1netAmountReceivedK > median,
                                      FALSE)]
lookup_list[[2]] <-
  dty[(receivedSzOverMedian), .(G2 = fmin(year) |> as.double()), fid]

# Define treatment groups  -----------------------------------------------------

lut <- list(
  list(data.table(fid = unique(dty$fid))),
  lookup_list
) |>
  unlist(recursive = FALSE) |>
  reduce(merge, by = "fid", all = TRUE)
varlist <- paste0("G", 1:2)
for (v in varlist) lut[is.na(get(v)), (v) := Inf]

# Export  ----------------------------------------------------------------------

write_fst(lut, opt$output)
