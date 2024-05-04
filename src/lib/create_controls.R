create_controls <- function(dt) {
  `:=` <- birth_date <- ageQuartile <- assetsDecile <- sizeDecile <-
    Scaler1 <- Scaler3 <- industry <- seccion <- NULL # NSE evaluation
  # age quartiles – sample specific
  quartiles <- dt[, quantile(as.numeric(birth_date), probs = seq(0, 1, 0.25), na.rm = TRUE)]
  dt[, ageQuartile := cut(as.numeric(birth_date), breaks = quartiles, labels = 1:4)]
  dt[is.na(ageQuartile), ageQuartile := 4] # missing as young
  # size and assets deciles – sample specific
  deciles <- dt[, quantile(Scaler3, probs = seq(0, 1, 0.1), na.rm = TRUE)] # assets
  dt[, assetsDecile := cut(Scaler3, breaks = deciles, labels = 1:10)]
  dt[is.na(assetsDecile), assetsDecile := floor(runif(1, 1, 11))]
  deciles <- dt[, quantile(Scaler1, probs = seq(0, 1, 0.1), na.rm = TRUE)] # revenue
  dt[, sizeDecile := cut(Scaler1, breaks = deciles, labels = 1:10)]
  dt[is.na(sizeDecile), sizeDecile := floor(runif(1, 1, 11))]
  # Above/below median assets
  dt[, assetsAboveMedian := as.integer(assetsDecile) >= 6]
  # industry sector
  dt[, industry := fcase(
    seccion %in% c("A", "B"), "a_b",
    seccion %in% c("D", "E"), "d_e",
    seccion %in% c("G", "I"), "g_i",
    seccion %in% c("H", "J"), "h_j",
    seccion %in% c("M", "N"), "m_n",
    seccion %in% c("P", "Q", "R", "S", "T"), "p_q_r_s_t",
    seccion %in% c("C", "F", "K", "L", "O"), str_to_lower(seccion)
  )]
  # final hh consumption sz
  cou12 <- fread("out/data/cou_hh_consumption.csv")[, .(supply, szHHConsumption, szExport)]
  cou12[, finalAboveMedian := szHHConsumption > fmedian(szHHConsumption)]
  cou12[, exportAboveMedian := szExport > fmedian(szExport)]
  dt <- merge(dt, cou12, by.x = "industry", by.y = "supply")
  dt
}
