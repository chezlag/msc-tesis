library(modelsummary)
library(broom)

tidy.AGGTEobj <- function(x, ...) {
  if (x$type == "simple") {
    s <- x$DIDparams
    ret <- data.frame(
      term = s$yname,
      estimate = x$overall.att,
      std.error = x$overall.se,
      conf.low = x$overall.att - x$overall.se * qnorm(1 - s$alp / 2),
      conf.high = x$overall.att + x$overall.se * qnorm(1 - s$alp / 2)
    )
  }
  if (x$type == "dynamic") {
    ret <- data.frame(
      term = paste0(s$yname, ", l = ", x$egt),
      estimate = x$att.egt,
      std.error = x$se.egt,
      conf.low = x$att.egt - x$se.egt * x$crit.val.egt,
      conf.high = x$att.egt + x$se.egt * x$crit.val.egt
    )
  }
  ret
}

glance.AGGTEobj <- function(x, ...) {
  s <- x$DIDparams
  ret <- data.frame(
    nobs = nrow(s$data),
    ni = s$n,
    ngroup = s$nG,
    ntime = s$nT,
    bstrap = s$bstrap,
    clustervars = s$clustervars,
    est.method = s$est_method,
    panel = s$panel,
    control.group = s$control_group,
    anticipation = s$anticipation
  )
  ret
}

tidy_did <- function(x) {
  if (x$type == "simple") {
    s <- x$DIDparams
    ret <- data.frame(
      y.name = s$yname,
      term = "Overall ATT",
      estimate = x$overall.att,
      std.error = x$overall.se,
      conf.low = x$overall.att - x$overall.se * qnorm(1 - s$alp / 2),
      conf.high = x$overall.att + x$overall.se * qnorm(1 - s$alp / 2)
    )
  }
  if (x$type == "dynamic") {
    s <- x$DIDparams
    ret <- data.frame(
      y.name = s$yname,
      term = paste0("ATT (l = ", x$egt, ")"),
      event = x$egt,
      estimate = x$att.egt,
      std.error = x$se.egt,
      conf.low = x$att.egt - x$se.egt * x$crit.val.egt,
      conf.high = x$att.egt + x$se.egt * x$crit.val.egt
    )
  }
  ret
}
