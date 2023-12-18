library(data.table)

create_lag_by_group <- function(dt, condition, oldvarname, newvarname, idvars) {
    dt[eval(parse(text = condition)), (newvarname) := get(oldvarname)]
    dt[, (newvarname) := fmax(get(newvarname)), by = idvars]
}