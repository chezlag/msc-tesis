library(groundhog)
pkgs <- c(
  "fastverse",
  "fst",
  "lubridate",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/cli_parsing_o.R")
source("src/lib/stata_helpers.R")

message("Reading data and cross-joining.") # ----------------------------------

dts <- read_fst("out/data/firms_static.fst", as.data.table = TRUE)
dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE)

fillCJ <- CJ(fid = unique(dty$fid), year = 2009:2016)
dtyfill <- dty[fillCJ, on = c("fid", "year")]

message("Joining with static firm information.") # ----------------------------

dt <- merge(dtyfill, dts, by = "fid", all.x = TRUE)

cols.x <- str_subset(names(dt), "\\.x$")
dt[, (cols.x) := NULL]
names(dt) <- str_remove(names(dt), "\\.y$")

dt[, firm_age := year - birth_year]

message("Creating extensive margin variables.") # -----------------------------

dt[, anyVatPaid := fifelse(!is.na(vatPaid), vatPaid > 0, FALSE)]
dt[, anyCorpTaxPaid := fifelse(!is.na(corpTaxPaid), corpTaxPaid > 0, FALSE)]
dt[, anyOtherTaxPaid := fifelse(!is.na(otherTaxPaid), otherTaxPaid > 0, FALSE)]
dt[, anyTaxPaid := fifelse(!is.na(totalTaxPaid), totalTaxPaid > 0, FALSE)]
dt[, anyRecordedActivity := !is.na(in214) | !is.na(in217) | !is.na(inPay)]

message("Exporting cross-joined dataset: ", opt$output) # ---------------------

write_fst(dt, opt$output)
