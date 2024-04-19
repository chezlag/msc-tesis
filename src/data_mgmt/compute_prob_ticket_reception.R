library(groundhog)
pkgs <- c(
  "arsenal",
  "collapse",
  "data.table",
  "forcats",
  "fst",
  "ggplot2",
  "ggsci",
  "janitor",
  "lubridate",
  "magrittr",
  "readxl",
  "skimr"
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
tab[is.na(turnoverMUI), turnoverMUI := 0]
tab[, szTicket := turnoverMUI / total]

# Percent of inputs provided by each sector -----------------------------------

cou <- read_excel(
  "src/data/2016_Agregada_Utilizacion intermedia Nacional_pc_C.xlsx",
  skip = 7
) |>
  clean_names()
setDT(cou)
sectorlist <- tab[, .N, supply][!is.na(supply), supply]
cou <- melt(
  cou[!is.na(as.integer(codigo))],
  id.vars = "codigo",
  measure.vars = sectorlist,
  variable.name = "demand"
)
cou[, supply := fcase(
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
cou <- collap(cou, value ~ supply + demand, fsum)

dmd <- merge(
  cou,
  collap(cou, value ~ demand, fsum) |> setnames("value", "total"),
  by = "demand"
)
dmd[, szDemand := value / total]

# Probability of receiving e-ticket by sector --------------------------------

prob <- merge(
  tab, dmd,
  by = "supply", allow.cartesian = TRUE
)
prob[, probTicketReception := szDemand * szTicket]
ret <- collap(prob, probTicketReception ~ year + demand, fsum)

fwrite(ret, "out/data/prob_ticket_reception.csv")

# ret |>
#   ggplot(aes(year, probTicketReception, color = demand)) +
#   geom_line()
# tab |>
#   ggplot(aes(year, szTicket, color = supply)) +
#   geom_line()
