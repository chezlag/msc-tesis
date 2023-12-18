library(fastverse)
library(fst)

# funciones
source("src/lib/load_custom_functions.r")
# CLI parsing
source("src/lib/cli_parsing_oi.r")
# Read data
dat <- read_fst(opt$input, as.data.table = TRUE)

# Ordeno datos por identificador y año
setorder(dat, fid, year)

# Tipos de DJ --------------------------------------------------------

# Declaración ficta: tiene información en las variables de renta ficta
dat[, djFict := !(is.na(v290) & is.na(v260) & is.na(v291) & is.na(v292))]

# Solo IPAT: no tiene resultado fiscal pero si patrimonio
dat[, declaraResultadoFiscal := !(is.na(v155) & is.na(v156))]
dat[, declaraPatrimonio := !(is.na(v13) & is.na(v30) & is.na(v79) & is.na(v80))]

# Categorías de declaración
dat[, tipoDJ := fcase(
    djFict, "Fict",
    !djFict & declaraResultadoFiscal, "Real",
    !djFict & !declaraResultadoFiscal & declaraPatrimonio, "IPAT",
    !djFict & !declaraResultadoFiscal & !declaraPatrimonio, "."
)]

# t <- dat[, .N, by = "tipoDJ"]
# t[, pct := round(N / sum(N), 3) ]
# t
# dat[, .N, by = c("year", "tipoDJ")] |> dcast(year ~ tipoDJ)
# dat[, .N, by = .(declaraResultadoFiscal, djFict)]
# # dat[, .N, by = .(declaraResultadoFiscal, declaraPatrimonio, djFict)]
# t <- dat[, .N, by = .(djFict, declaraResultadoFiscal, declaraPatrimonio, tipoDJ)]
# setorder(t, -djFict, declaraResultadoFiscal)
# t

# Declaración Ficta ------------------------------------------------------

## Ventas e ingresos operativos ------------------------------------------

# Ventas
dat |> rowtotal("ventas", c("v160", "v161", "v162"))

# Problemas con ventas

# Diagnóstico
# dat |> compare_columns("v100", "ventas")
# tgtVars <- c("v160", "v161", "v162", "v100", "ventas", "tipoDJ")
# dat[v100 > ventas, ..tgtVars]

# Problema 1: v100 > ventas (n = 4)
# Solución: conservo reconstrucción

# Problema 2: ventas missing y v100 está (n = 5)
dat[is.na(ventas) & !is.na(v100), ventas := v100]

# Ingresos operativos fictos
dat |> rowtotal("ingresoOperativoFict", c("ventas", "v198"), .if = "(djFict)")

# Problema 3: Reconstrucción es NA, original existe (n = 4)
dat[djFict & is.na(ingresoOperativoFict) & !is.na(v199), ingresoOperativoFict := v199]


## Ingresos y renta fictos -------------------------------------------------------

### Combinación K/L (mixtos) -----------------------------------------------------

# ingresos por tramos
dat[, TempY1 := v260]
dat[, TempY2 := v261]
dat[, TempY3 := v262]
# Recupero toda la información posible
# Aparece la renta pero no el ingreso
dat[is.na(TempY1) & !is.na(v280), TempY1 := round(v280 / .132)]
dat[is.na(TempY2) & !is.na(v281), TempY2 := round(v281 / .36)]
dat[is.na(TempY3) & !is.na(v282), TempY3 := round(v282 / .48)]
# rentas por tramos
dat[, TempR1 := round(TempY1 * 0.132)]
dat[, TempR2 := round(TempY2 * 0.36)]
dat[, TempR3 := round(TempY3 * 0.48)]

# ingreso mixto ficto total
dat |> rowtotal("ingresoMixFict", c("TempY1", "TempY2", "TempY3"))

# renta ficta total
dat |> rowtotal("rentaMixFict", c("TempR1", "TempR2", "TempR3"))

# Elimino variables temporales
dat |> drop_columns("Temp*")

### Puros de L ---------------------------------------------------------------

# ingresos de trabajo por tramos
# ingresos por tramos
dat[, TempY1 := v267]
dat[, TempY2 := v268]
dat[, TempY3 := v269]
# Recupero toda la información posible
# Aparece la renta pero no el ingreso
dat[is.na(TempY1) & !is.na(v287), TempY1 := v287 / .48]
dat[is.na(TempY2) & !is.na(v288), TempY2 := v288 / .60]
dat[is.na(TempY3) & !is.na(v289), TempY3 := v289 / .72]
# rentas por tramos
dat[, TempR1 := round(TempY1 * 0.48)]
dat[, TempR2 := round(TempY2 * 0.60)]
dat[, TempR3 := round(TempY3 * 0.72)]

# ingreso puro de trabajo ficto total
dat |> rowtotal("ingresoLabFict", c("TempY1", "TempY2", "TempY3"))

# renta pura de trabajo ficta total
dat |> rowtotal("rentaLabFict", c("TempR1", "TempR2", "TempR3"))

# Elimino variables temporales
dat |> drop_columns("Temp*")

# Problemas

# Inconsistencias en el llenado – no hay
# tgtVars <- c("v267","v287", "v268", "v288", "v269", "v289")
# a <- aggr(dat[(djFict), ..tgtVars], plot = FALSE)
# plot(a, numbers = TRUE, prop = FALSE, cex.axis = .9, oma = c(8, 5, 5, 3))

# Reconstrucción vs original – va como piña (diferencias de redondeo)
# dat |> rowtotal("rentaLabFictRRAA", c("v287", "v288", "v289"))
# dat[(djFict)] |> compare_columns("rentaLabFict", "rentaLabFictRRAA")
# dat[, diff := rentaLabFict - rentaLabFict]
# dat[, diff] |> summary()
# as.integer(round(dat[!is.na(diff), diff]) == 0) |> mean()

### Puros de K ---------------------------------------------------

dat[, ingresoCapFict := v270]
dat[is.na(ingresoCapFict) & !is.na(v271), ingresoCapFict := v271 / .48]
dat[, rentaCapFict := round(ingresoCapFict * 0.48)]

# Diagnostico de problemas

# Reconstrucción vs original – perfecto
# dat[(djFict)] |> compare_columns("rentaCapFict", "v271")

### Otras rentas fictas --------------------------------------------------------

# ingresos
dat[, TempY1 := v294]
dat[, TempY2 := v265]
dat[, TempY3 := v266]
# rentas
dat[, TempR1 := v295]
dat[, TempR2 := v285]
dat[, TempR3 := v286]
# si Y<R – igualo ingresos a rentas
dat[TempY1 < TempR1, TempY1 := TempR1]
dat[TempY2 < TempR2, TempY2 := TempR2]
dat[TempY3 < TempR3, TempY3 := TempR3]
# otros ingresos y rentas totales
dat |> rowtotal("ingresoOtrFict", c("TempY1", "TempY2", "TempY3"))
dat |> rowtotal("rentaOtrFict", c("TempR1", "TempR2", "TempR3"))
# Elimino variables temporales
dat |> drop_columns("Temp*")

# Problemas

# Inconsistencias en el llenado
# tgtVars <- c("v294","v295", "v265", "v285", "v266", "v286")
# a <- aggr(dat[(djFict), ..tgtVars], plot = FALSE)
# plot(a, numbers = TRUE, prop = FALSE, cex.axis = .9, oma = c(8, 5, 5, 3))


### Pre-2014: IRPF y rentas que no son por K ni L ---------------------

# ingresos
dat[, TempY1 := v263]
dat[, TempY2 := v264]
# rentas
dat[, TempR1 := v283]
dat[, TempR2 := v284]
# Recupero toda la información posible
# Aparece la renta pero no el ingreso
dat[is.na(TempY1) & !is.na(v283), TempY1 := round(v283 / .48)]
dat[is.na(TempY2) & !is.na(v284), TempY2 := round(v284 / .60)]
# rentas por tramos
dat[, TempR1 := round(TempY1 * 0.48)]
dat[, TempR2 := round(TempY2 * 0.48)]
# ingresos y rentas no derivadas de K/L o IRAE por opcion
dat |> rowtotal("ingresoOldFict", c("TempY1", "TempY2"))
dat |> rowtotal("rentaOldFict", c("TempR1", "TempR2"))
# elimino variables temporales
dat |> drop_columns("Temp*")

# Problemas

# Inconsistencias en el llenado – 2Y sin R, 1R sin Y – reconstruyo
# tgtVars <- c("v263", "v283", "v264", "v284")
# a <- aggr(dat[(djFict), ..tgtVars], plot = FALSE)
# plot(a, numbers = TRUE, prop = FALSE, cex.axis = .9, oma = c(8, 5, 5, 3))

### Renta ficta bruta -----------------------------------------------------------------------

# suma de ingresos y rentas
ingresoVarlist <- c("ingresoMixFict", "ingresoLabFict", "ingresoCapFict", "ingresoOtrFict", "ingresoOldFict")
rentaVarlist <- sapply(ingresoVarlist, \(x) stringr::str_replace(x, "ingreso", "renta"))
dat |> rowtotal("ingresoBrutoFict", ingresoVarlist)
dat |> rowtotal("rentaBrutaFict", rentaVarlist)
# fix: redondeo para comparar
dat[, ingresoBrutoFict := round(ingresoBrutoFict)]
dat[, rentaBrutaFict := round(rentaBrutaFict)]

# hotfix: errores de redondeo para ver si salio bien la comparacion
dat[round(v290 - rentaBrutaFict) == 1, rentaBrutaFict := rentaBrutaFict + 1]
# dat[round(v290 - rentaBrutaFict) == 2, rentaBrutaFict := rentaBrutaFict + 2]

# Diagnóstico
# Reconstrucción vs original –– solo mejoras
# dat[(djFict)] |> compare_columns("v290", "rentaBrutaFict")
# dat[, diff := v290 - rentaBrutaFict]
# dat[diff > 0, diff] |> summary()
# dat[diff > 0, .N]
# dat[, diff := NULL]

## Costos y tasa de markup implícitos ----------------------------------------------------

# costos implicitos en la declaración ficta
dat[(djFict), costosFict := ingresoBrutoFict - rentaBrutaFict]
dat[(djFict) & costosFict <= 1, costosFict := NA]
# tasa de markup implícita
dat[(djFict), markupFict := (ingresoBrutoFict / costosFict)]
dat[(djFict), markupLernerFict := 1 - costosFict / ingresoBrutoFict]

dat[(djFict), .(markupLernerFict, markupFict)] |> summary()
# dat[(djFict), .N]
# dat[markupFict < Inf, .N]
# dat[markupFict < 5, .N]

## Deducciones admitidas y resultado fiscal ---------------------------------------------

# Total de deducciones admitidas
dat[(djFict), sueldoSociosFict := v291]
dat[(djFict), otrasDeduccFict := v292]
dat[(djFict), deduccFict := rowSums(.SD, na.rm = TRUE), .SDcols = c("sueldoSociosFict", "otrasDeduccFict")]
dat[(djFict) & is.na(deduccFict) & !is.na(v293), deduccFict := v293]

# Resultado fiscal
dat[(djFict), Temp := -deduccFict]
dat |> rowtotal("resultadoFiscal", c("rentaBrutaFict", "Temp"), .if = "(djFict)")

# Elimino variables temporales
dat |> drop_columns("Temp*")

# Problemas

# Diagnóstico
# Reconstruccion de lo existente
# dat[, TempR1 := abs(v155)]
# dat[, TempR2 := -abs(v156)]
# dat |> rowtotal("resultadoFiscalRRAA", c("TempR1", "TempR2"))
# dat |> drop_columns("Temp*")

# dat[(djFict), diff := resultadoFiscal - resultadoFiscalRRAA]
# Muestra 2: Diferencia surge de mala declaración y conservo mi resultado
# dat[, TempSample2 := (diff < 0) & (!is.na(v155) & !is.na(v156))]
# dat[(TempSample2), .N]
# dat[(TempSample2), .(resultadoFiscal, v155, v156)]
# tomo el valor del resultado como el correcto
# Parece que el v155 se chispoteó, pero todas las variables apuntan al que reconstruí.

dat[(djFict)] |> compare_columns("ingresoOperativoFict", "ingresoBrutoFict")
# dat[, Temp1 := ingresoOperativoFict - ingresoBrutoFict]
# dat[Temp1 < 0, Temp1] |> summary()
# tgtVars <- c("ventas", "ingresoOperativoFict", "ingresoBrutoFict", "v260", "v261", "v262", "v290")
# dat[(Temp1 > 0), ..tgtVars] |> head()
# dat |> drop_columns("Temp*")

## IRAE -----------------------------------------------------------------

dat[djFict & resultadoFiscal > 0, irae := round(resultadoFiscal * 0.25)]
dat[djFict & v301 > irae, irae := irae + 1]
dat[(djFict)] |> compare_columns("v301", "irae")
dat[djFict & v301 > irae, .(v301, irae)] |> head()

# Declaración real -------------------------------------------------------------

# Identificación con dummy para simplificar
dat[, djReal := (tipoDJ == "Real")]

## Ingresos ---------------------------------------------------------------
# Ya cree ventas para todas las observaciones en la sección de declaración ficta.
# En ambos tipos de declaraciones `ventas = v160 + v161 + v162`.

# costosVarlist <- c("v102", "v103", "v195", "v196", "v105", "v106", "v177", "v176", "v100")
# dat[(djReal), ..costosVarlist] |>
#     gg_miss_var(show_pct = TRUE)

## Costos y gastos ------------------------------------------------------------------

# Costos
costosVarlist <- c("v102", "v103", "v195", "v196", "v105", "v106")
dat[, v106 := -v106]
dat |> rowtotal("costos", costosVarlist, .if = "(djReal)")
dat[, v106 := -v106]
# hotfix: v177 > costos
dat[v177 > costos, costos := v177]
# dat |> compare_columns("v177", "costos") # iguales
# dat[, diff := v177 - costos]
# dat[diff < 0, .(v177, costos)]

# Gastos
gastosVarlist <- c("v178", "v179", "v163", "v164", "v165", "v166", "v167", "v168", "v169", "v170", "v171", "v172", "v173", "v174", "v175")
dat |> rowtotal("gastos", gastosVarlist, .if = "(djReal)")
# dat[(djReal)] |> compare_columns("v176", "gastos")
# dat[, diff := v176 - gastos]
# dat[(djReal), diff] |> summary()
# dat[, c(gastosVarlist, "v176", "gastos")] |> head()

# Suma de costos y gastos admitidos
dat |> rowtotal("costosGastos", c("costos", "gastos"))
dat[(djReal), costosGastos] |> summary()
# dat[costosGastos < 0, ..costosVarlist]

## Otros ingresos y egresos -------------------------------------------------

# Otros ingresos
oingVarlist <- c("v180", "v225", "v182")
dat |> rowtotal("otrosIng", oingVarlist)
# dat |> compare_columns("v184", "otrosIng")

# Otros egresos
oegrVarlist <- c("v181", "v226", "v183")
dat |> rowtotal("otrosEgr", oegrVarlist)
# dat |> compare_columns("v185", "otrosEgr")
dat[, TempEgr := -otrosEgr]

# Otros ingresos y egresos
dat |> rowtotal("otrosIngEgr", c("otrosIng", "TempEgr"), .if = "(djReal)")
dat[, otrosIngEgr] |> summary()

# Dropeo temporales
dat |> drop_columns("Temp*")

## Resultados Financieros -----------------------------------------------

# Resultados financieros positivos
posVarlist <- c("v186", "v187", "v191", "v193")
dat |> rowtotal("resultadosFinancierosPos", posVarlist)
# dat |> compare_columns("v108", "resultadosFinancierosPos")

# Resultados financieros negativos
negVarlist <- c("v188", "v189", "v190", "v192", "v194")
dat |> rowtotal("resultadosFinancierosNeg", negVarlist)
# dat |> compare_columns("v109", "resultadosFinancierosNeg")
dat[, TempNeg := -resultadosFinancierosNeg]

# Resultado financiero total
dat |> rowtotal("resultadosFinancieros", c("resultadosFinancierosPos", "TempNeg"), .if = "(djReal)")
# dat[(djReal), resultadosFinancieros] |> summary()
# dat[, v109 := -v109]
# dat |> rowtotal("TempResFin", c("v108", "v109"))
# dat[, v109 := -v109]
# dat |> compare_columns("TempResFin", "resultadosFinancieros")

# Dropeo temporales
dat |> drop_columns("Temp*")

# source('src/lib/fun_mvencode.r')
# dat |> rowtotal("Temp", c("v108", "v109"))
# dat |> mvencode("Temp", 0, .if = "(djReal)")
# miss_var_plot(dat[(djReal)], c("Temp", "v108", "v109"), prop = TRUE)
# dat |> drop_columns("Temp*")

## Resultado contable ------------------------------------------------

dat[, costosGastos := -costosGastos]
tgtVarlist <- c("ventas", "costosGastos", "otrosIngEgr", "resultadosFinancieros")
dat |> rowtotal("resultadoContable", tgtVarlist, .if = "(djReal)")
dat[, costosGastos := -costosGastos]

dat[, v115 := -v115]
dat |> rowtotal("TempRes", c("v114", "v115"))
dat[, v115 := -v115]
dat[(djReal)] |> compare_columns("TempRes", "resultadoContable")
dat[(djReal), Tempdiff := TempRes - resultadoContable]
dat[, .(Tempdiff)] |> summary()
dat |> drop_columns("Temp*")

## Ajustes contables --------------------------------------------------

# Ajustes positivos
posVarlist <- c("v118", "v120", "v122", "v124", "v126", "v130", "v132", "v201", "v203", "v205", "v207", "v211", "v212", "v213", "v214", "v216", "v217", "v218", "v219", "v221", "v227", "v223")
dat |> rowtotal("ajustesContablesPos", posVarlist, .if = "(djReal)")
dat[(djReal)] |> compare_columns("v136", "ajustesContablesPos")

# Ajustes negativos
negVarlist <- c("v119", "v121", "v123", "v125", "v127", "v131", "v133", "v202", "v204", "v209", "v210", "v215", "v220", "v222", "v228", "v224")
dat |> rowtotal("ajustesContablesNeg", negVarlist, .if = "(djReal)")
dat[(djReal)] |> compare_columns("v137", "ajustesContablesNeg")
dat[, TempNeg := -ajustesContablesNeg]

# Total ajustes contables
dat |> rowtotal("ajustesContables", c("ajustesContablesPos", "TempNeg"), .if = "(djReal)")

# drop temporales
dat |> drop_columns("Temp*")

## Ajustes fiscales --------------------------------------------------

# Ajustes positivos
posVarlist <- c("v141", "v251", "v250", "v147")
dat |> rowtotal("ajustesFiscalesPos", posVarlist, .if = "(djReal)")

# Ajustes negativos
negVarlist <- c("v140", "v144", "v158", "v148", "v151", "v154")
dat |> rowtotal("ajustesFiscalesNeg", negVarlist, .if = "(djReal)")
dat[, TempNeg := -ajustesFiscalesNeg]

# Total ajustes contables
dat |> rowtotal("ajustesFiscales", c("ajustesFiscalesPos", "TempNeg"), .if = "(djReal)")

# drop temporales
dat |> drop_columns("Temp*")

## Resultado Fiscal ---------------------------------------------------

rfVarlist <- c("resultadoContable", "ajustesContables", "ajustesFiscales")
dat |> rowtotal("resultadoFiscal", rfVarlist, .if = "(djReal)")

# dat[, v156 := -v156]
# dat |> rowtotal("TempRes", c("v155", "v156"), .if = "(djReal)")
# dat[, v156 := -v156]
# dat[(djReal)] |> compare_columns("TempRes", "resultadoFiscal")
# dat |> drop_columns("Temp*")

## IRAE ---------------------------------------------------------------

dat[djReal & resultadoFiscal > 0, irae := round(resultadoFiscal * 0.25)]
dat[djReal & v301 > irae, irae := irae + 1]
# dat[(djReal)] |> compare_columns("v301", "irae")
# dat[djReal & v301 > irae, .(v301, irae)] |> head()

# Save ----------------------------------------------------------------

write_fst(dat, opt$output)
