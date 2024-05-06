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
  # final uses sz
  couf <- fread("out/data/cou_final.csv")[, .(supply_industry, households, exports)]
  couf[, householdsAboveMedian := households > fmedian(households)]
  couf[, exportsAboveMedian := exports > fmedian(exports)]
  dt <- merge(dt, couf, by.x = "seccion", by.y = "supply_industry", all.x = TRUE)
  # intermediate uses (imports)
  coui <- fread("out/data/cou_intermediate.csv")[
    supply_industry == "IMPORTS", .(demand_industry, szDemand)
  ]
  coui[, importsAboveMedian := szDemand > fmedian(szDemand)]
  dt <- merge(dt, coui, by.x = "seccion", by.y = "demand_industry", all.x = TRUE)
  # export
  dt
}
