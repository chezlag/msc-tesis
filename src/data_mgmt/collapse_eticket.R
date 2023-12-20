library(fastverse)
library(fst)
library(lubridate)

cfe <- read_fst("src/data/dgi_firmas/out/data/eticket_transactions.fst", as.data.table = TRUE)

static <- list(
    cfe[, .(dateFirstReception = fmin(date) |> lubridate::as_date()), by = id_receptor] |>
        setnames("id_receptor", "fid"),
    cfe[, .(dateFirstEmission = fmin(date) |> lubridate::as_date()), by = id_emisor] |>
        setnames("id_emisor", "fid")
) |>
    lapply(setkeyv, "fid") |>
    purrr::reduce(merge, all = TRUE)

yearly <- list(
    collap(cfe, nTickets ~ id_receptor + year, fsum) |>
        setnames(c("id_receptor", "nTickets"), c("fid", "nTicketsReceived")),
    collap(cfe, nTickets ~ id_emisor + year, fsum) |>
        setnames(c("id_emisor", "nTickets"), c("fid", "nTicketsEmitted")),
    collap(cfe[(positiveAmount)], grossAmount + netAmount ~ id_receptor + year, fsum) |>
        setnames(c("id_receptor", "grossAmount", "netAmount"), c("fid", "grossAmountReceived", "netAmountReceived")),
    collap(cfe[(positiveAmount)], grossAmount + netAmount ~ id_emisor + year, fsum) |>
        setnames(c("id_emisor", "grossAmount", "netAmount"), c("fid", "grossAmountEmitted", "netAmountEmitted"))
) |>
    lapply(setkeyv, c("fid", "year")) |>
    purrr::reduce(merge, all = TRUE)

quarterly <- list(
    collap(cfe, nTickets ~ id_receptor + quarter, fsum) |>
        setnames(c("id_receptor", "nTickets"), c("fid", "nTicketsReceived")),
    collap(cfe, nTickets ~ id_emisor + quarter, fsum) |>
        setnames(c("id_emisor", "nTickets"), c("fid", "nTicketsEmitted")),
    collap(cfe[(positiveAmount)], grossAmount + netAmount ~ id_receptor + quarter, fsum) |>
        setnames(c("id_receptor", "grossAmount", "netAmount"), c("fid", "grossAmountReceived", "netAmountReceived")),
    collap(cfe[(positiveAmount)], grossAmount + netAmount ~ id_emisor + quarter, fsum) |>
        setnames(c("id_emisor", "grossAmount", "netAmount"), c("fid", "grossAmountEmitted", "netAmountEmitted"))
) |>
    lapply(setkeyv, c("fid", "quarter")) |>
    purrr::reduce(merge, all = TRUE)

# Export
write_fst(static, "out/data/eticket_static.fst")
write_fst(yearly, "out/data/eticket_yearly.fst")
write_fst(quarterly, "out/data/eticket_quarterly.fst")
