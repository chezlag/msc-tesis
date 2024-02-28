library(groundhog)
pkgs <- c("collapse", "data.table", "fst", "lubridate", "purrr")
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/cli_parsing_o.R")

# get fid for firms not in bcs nor cfe
filelist <- c(
  "src/data/dgi_firmas/out/data/balances_allF_allY.fst",
  "src/data/dgi_firmas/out/data/sales_allF_allY.fst",
  "src/data/dgi_firmas/out/data/tax_paid_retained.fst"
)
fid_only <- filelist |>
  map(\(x) {
    read_fst(x, as.data.table = TRUE) %>%
      .[, .N, fid] %>%
      .[, .(fid)]
  }) |>
  reduce(merge, by = "fid", all = TRUE)

# read datasets with actual information
bcs <- fread("src/data/bcs_covariates.csv")
cfe <- read_fst("out/data/eticket_static.fst", as.data.table = TRUE)
giro <-
  read_fst("src/data/dgi_firmas/out/data/balances_allF_allY.fst", as.data.table = TRUE) %>%
  .[, .(giro = fmax(giro), natjur = fmax(nat_juridica)), fid]

# merge all
dt <- list(bcs, cfe, giro, fid_only) |>
  reduce(merge, by = "fid", all = TRUE)

# create new variables

dt[, receivedAnyT := !is.na(dateFirstReception)]
dt[, emittedAnyT := !is.na(dateFirstEmission)]

dt[, yearFirstReception := fifelse(!is.na(dateFirstReception), year(dateFirstReception), Inf)]
dt[, yearFirstEmission := fifelse(!is.na(dateFirstEmission), year(dateFirstEmission), Inf)]

dt[, quarterFirstReception := floor_date(dateFirstReception, unit = "quarter")]
dt[is.na(quarterFirstReception), quarterFirstReception := Inf]
dt[, quarterFirstEmission := floor_date(dateFirstEmission, unit = "quarter")]
dt[is.na(quarterFirstEmission), quarterFirstEmission := Inf]

dt[, neverTreated := is.na(dateFirstReception)]

# sector bergolo-ceni-sauval
dt[, sector := fcase(
  sector == "Agriculture, forestry, fishing, mining and quarrying", "Primary activities",
  !is.na(ind_code_last), sector,
  default = ""
)]
dt[, ind_code_2d := fifelse(!is.na(ind_code_last), floor(ind_code_last / 1e3), 99)]
dt[, ind_code_3d := fifelse(!is.na(ind_code_last), floor(ind_code_last / 1e2), 99)]
# tiene covariables BCS
dt[, hasCovariates := !is.na(sector) & !is.na(birth_date)]

# sector BPS mega bases
dt[, division := fifelse(!is.na(giro), floor(giro / 1e3), 100)]
dt[, seccion := fcase(
  division %in% 1:3, "A",
  division %in% 5:9, "B",
  division %in% 10:33, "C",
  division == 35, "D",
  division %in% 36:39, "E",
  division %in% 41:43, "F",
  division %in% 45:47, "G",
  division %in% 49:53, "H",
  division %in% 55:56, "I",
  division %in% 58:63, "J",
  division %in% 64:66, "K",
  division == 68, "L",
  division %in% 69:75, "M",
  division %in% 77:82, "N",
  division == 84, "O",
  division == 85, "P",
  division %in% 86:88, "Q",
  division %in% 90:93, "R",
  division %in% 94:96, "S",
  division %in% 97:98, "T",
  division == 99, "U",
  default = "X"
)]
dt[, giro3 := fcase(
  seccion == "A", "Agricultura",
  division %in% 5:43, "Industria",
  division %in% 45:99, "Servicios",
  default = "No clasificados"
)]
dt[, giro6 := fcase(
  seccion == "A", "Agricultura",
  seccion == "C", "Manufactura",
  seccion == "F", "Construcción",
  seccion %in% c("B", "D", "E"), "Minería; EGA",
  seccion %in% c("G", "H", "I", "J", "K", "L", "M", "N"), "Servicios de mercado",
  seccion %in% c("O", "P", "Q", "R", "S", "T", "U"), "Servicios no de mercado",
  default = "No clasificados"
)]
dt[, giro8 := fcase(
  division %in% 1:43, giro6,
  division == 46, "Comercio mayorista",
  division == 47, "Comercio minorista",
  division %in% c(45, 48:82), "Otros servicios de mercado",
  division %in% 84:99, "Servicios no de mercado",
  default = "No clasificados"
)]

write_fst(dt, opt$output)
