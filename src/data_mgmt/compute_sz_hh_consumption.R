library(groundhog)
pkgs <- c(
  "arsenal",
  "collapse",
  "data.table",
  "forcats",
  "fst",
  "janitor",
  "lubridate",
  "magrittr",
  "readxl",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

# Emission coverage per sector ------------------------------------------------

clean_cou <- function(file, range) {
  `:=` <- supply <- ..varlist <- NULL
  cou <- readxl::read_excel(
    file,
    range = range
  ) |>
    janitor::clean_names()
  data.table::setDT(cou)
  measurelist <- c(
    "utilizacion_total",
    "utilizacion_intermedia_total",
    "gasto_de_consumo_final_hogares",
    "formacion_bruta_de_capital_fijo",
    "variacion_de_existencias1",
    "exportaciones"
  )
  varlist <- c("codigo", measurelist)
  cou <- cou[, ..varlist]
  cou[, supply := data.table::fcase(
    codigo %in% 1:3, "a_b",
    codigo %in% 5:9, "c",
    codigo == 4, "d_e",
    codigo == 10, "f",
    codigo == 11, "g_i",
    codigo %in% c(12, 13, 17), "h_j",
    codigo == 14, "k",
    codigo == 15, "l",
    codigo == 16, "m_n",
    codigo == 18, "o",
    codigo %in% 19:21, "p_q_r_s_t"
  )]
  ret <- collapse::collap(cou, ~supply, fsum)
  ret
}

cou12 <- clean_cou("src/data/2012_Agregada_COU_C.xlsx", "A36:X57")
cou12[, szExport := exportaciones / utilizacion_total]
cou12[, szHHConsumption := gasto_de_consumo_final_hogares / utilizacion_total]

fwrite(cou12, "out/data/cou_hh_consumption.csv")
