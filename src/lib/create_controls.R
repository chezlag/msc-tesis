create_controls <- function(dt) {
  `:=` <- birth_date <- ageQuartile <- assetsDecile <- sizeDecile <-
    Scaler1 <- Scaler3 <- NULL # NSE evaluation
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
  dt
}
