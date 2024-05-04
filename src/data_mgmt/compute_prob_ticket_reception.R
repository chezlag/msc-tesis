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

tab <- merge(
  collap(dty[(emitted)], turnoverMUI ~ year + seccion, fsum),
  collap(dty, turnoverMUI ~ year + seccion, fsum) |> setnames("turnoverMUI", "total"),
  by = c("year", "seccion"), all = TRUE
)
setnames(tab, "turnoverMUI", "turnoverInTicket")
tab[is.na(turnoverInTicket), turnoverInTicket := 0]
tab[, szTicket := turnoverInTicket / total]

fwrite(tab[!is.na(seccion)], "out/data/share_eticket_by_industry.csv")

# Percent of inputs provided by each sector -----------------------------------

clean_cou_detailed <- function(file, range_supply, range_use) {
  `:=` <- .SD <- total <- codigo <- wt <- NULL
  # Share of products belonging to each industry
  supply <- readxl::read_excel(file, range = range_supply) |>
    janitor::clean_names()
  data.table::setDT(supply)
  data.table::setnames(supply, "oferta_importada", "imports")
  sectorlist <- names(supply)[names(supply) %nin% c(
    "codigo", "denominacion", "x3", "x4", "x5", "x6", "oferta_total", "produccion_total",
    "imports", "margenes_totales", "impuestos_menos_subvenciones_sobre_los_productos",
    "ajuste_cif_fob_sobre_la_oferta_nacional"
  )]
  supplylist <- c(sectorlist, "imports")
  supply[, total := rowSums(.SD), .SDcols = supplylist]
  supply[, (supplylist) := lapply(.SD, \(x) x / total), .SDcols = supplylist]
  weights <- data.table::melt(
    supply[!is.na(as.integer(codigo))],
    id.vars = "codigo",
    measure.vars = supplylist,
    variable.name = "supply_industry",
    value.name = "wt"
  )
  # Convert product-intermediate use to industry-intermediate use table
  use <- readxl::read_excel(file, range = range_use) |>
    janitor::clean_names()
  data.table::setDT(use)
  cols <- c("codigo", sectorlist)
  intuse <- merge(
    weights,
    use[!is.na(as.integer(codigo)), ..cols],
    by = "codigo"
  )
  intuse[, (sectorlist) := lapply(.SD, \(x) x * wt), .SDcols = sectorlist]
  indintuse <- collapse::collap(
    intuse,
    arsenal::formulize(sectorlist, "supply_industry"),
    collapse::fsum
  )
  # Share of industry intermediate use supplied by each industry
  indintuse <- data.table::melt(
    indintuse,
    id.vars = "supply_industry",
    measure.vars = sectorlist,
    variable.name = "demand_industry"
  )
  indintuse[, supply_industry := stringr::str_remove(supply_industry, "_\\d+")]
  indintuse[, demand_industry := stringr::str_remove(demand_industry, "_\\d+")]
  indintuse <- collapse::collap(
    indintuse, value ~ demand_industry + supply_industry, fsum
  )
  indintuse[, total := fsum(value), demand_industry]
  indintuse[, value := value / total]
  # Convert product-final use to industry-final use table
  oldnames <- c(
    "utilizacion_intermedia_total",
    "gasto_de_consumo_final_hogares",
    "gasto_de_consumo_final_del_gobierno_e_isflsh",
    "formacion_bruta_de_capital_fijo",
    "variacion_de_existencias1",
    "exportaciones"
  )
  newnames <- c("intermediate", "households", "government", "fbkf", "ve", "exports")
  data.table::setnames(use, oldnames, newnames)
  cols <- c("codigo", newnames)
  finaluse <- merge(
    weights,
    use[!is.na(as.integer(codigo)), ..cols],
    by = "codigo"
  )
  finaluse[, (newnames) := lapply(.SD, \(x) x * wt), .SDcols = newnames]
  finaluse[, supply_industry := stringr::str_remove(supply_industry, "_\\d+")]
  indfinaluse <- collapse::collap(
    finaluse,
    arsenal::formulize(newnames, "supply_industry"),
    collapse::fsum
  )
  # Share of industry supply destined to each final use
  indfinaluse[, total := rowSums(.SD), .SDcols = newnames]
  indfinaluse[, (newnames) := lapply(.SD, \(x) x / total), .SDcols = newnames]
  # return list of datasets
  ret <- list(indintuse, indfinaluse)
  names(ret) <- c("Intermediate", "Final")
  ret
}

cou12d <- clean_cou_detailed("src/data/2012_Detallada_COU_C.xlsx", "A8:DO142", "A149:DP283")
cou12d[[1]] |> setnames("value", "szDemand")
cou12d[[1]][, demand_industry := str_to_upper(demand_industry)]
cou12d[[1]][, supply_industry := str_to_upper(supply_industry)]
cou12d[[2]][, supply_industry := str_to_upper(supply_industry)]

outfilelist <- c("cou_intermediate.csv", "cou_final.csv") %>% paste0("out/data/", .)
walk2(cou12d, outfilelist, \(x, y) fwrite(x, y))

dmd <- cou12d[[1]][, -("total")]
dmd[is.na(szDemand), szDemand := 0]

# Probability of receiving e-ticket by sector --------------------------------

prob <- merge(
  tab, dmd,
  by.x = "seccion", by.y = "supply_industry",
  allow.cartesian = TRUE
)
prob[, probTicketReception := szDemand * szTicket]
ret <- collap(prob, probTicketReception ~ year + demand_industry, fsum)

fwrite(ret, "out/data/prob_ticket_reception_by_industry.csv")
