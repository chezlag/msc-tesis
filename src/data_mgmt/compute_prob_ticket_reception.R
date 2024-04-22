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

dty <-
  read_fst("out/data/firms_yearly.fst", as.data.table = TRUE)

dty[, supply := fcase(
  seccion %in% c("A", "B"), "a_b",
  seccion %in% c("D", "E"), "d_e",
  seccion %in% c("G", "I"), "g_i",
  seccion %in% c("H", "J"), "h_j",
  seccion %in% c("M", "N"), "m_n",
  seccion %in% c("P", "Q", "R", "S", "T"), "p_q_r_s_t",
  seccion %in% c("C", "F", "K", "L", "O"), str_to_lower(seccion)
)]

tab <- merge(
  collap(dty[(emitted)], turnoverMUI ~ year + supply, fsum),
  collap(dty, turnoverMUI ~ year + supply, fsum) |> setnames("turnoverMUI", "total"),
  by = c("year", "supply"), all = TRUE
)
setnames(tab, "turnoverMUI", "turnoverInTicket")
tab[is.na(turnoverInTicket), turnoverInTicket := 0]
tab[, szTicket := turnoverInTicket / total]

fwrite(tab[!is.na(supply)], "out/data/share_eticket_by_industry.csv")

# Percent of inputs provided by each sector -----------------------------------


clean_cou <- function(file, range) {
  `:=` <- `.N` <- supply <- NULL
  cou <- readxl::read_excel(
    file,
    range = range
  ) |>
    janitor::clean_names()
  data.table::setDT(cou)
  sectorlist <- tab[, .N, supply][!is.na(supply), supply]
  cou <- data.table::melt(
    cou[!is.na(as.integer(codigo))],
    id.vars = "codigo",
    measure.vars = sectorlist,
    variable.name = "demand"
  )
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
  ret <- collapse::collap(cou, value ~ supply + demand, fsum)
  ret
}

cou12 <- clean_cou("src/data/2012_Agregada_COU_C.xlsx", "A36:X57")
cou16 <- clean_cou("src/data/2016_Agregada_Utilizacion intermedia Nacional_pc_C.xlsx", "A8:R29")
fwrite(cou12, "out/data/cou12.csv")
fwrite(cou16, "out/data/cou16.csv")

compute_demand_share <- function(dt) {
  `:=` <- szDemand <- value <- NULL # avoid NSE warnings
  ret <- merge(
    dt,
    collapse::collap(dt, value ~ demand, fsum) |> data.table::setnames("value", "total"),
    by = "demand"
  )
  ret[, szDemand := value / total]
  ret
}
dmd12 <- compute_demand_share(cou12)
dmd16 <- compute_demand_share(cou16)

dmd <- dmd12

# Probability of receiving e-ticket by sector --------------------------------

prob <- merge(
  tab, dmd,
  by = "supply", allow.cartesian = TRUE
)
prob[, probTicketReception := szDemand * szTicket]
ret <- collap(prob, probTicketReception ~ year + demand, fsum)

fwrite(ret, "out/data/prob_ticket_reception_by_industry.csv")
