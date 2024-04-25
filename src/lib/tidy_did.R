library(groundhog)
pkgs <- c("modelsummary", "broom")
groundhog.library(pkgs, "2024-01-15")

tidy.AGGTEobj <- function(x, ...) {
  s <- x$DIDparams
  if (x$type == "simple") {
    ret <- data.frame(
      y.name = s$yname,
      term = "Overall ATT",
      estimate = x$overall.att,
      std.error = x$overall.se,
      p.value = 2 * pnorm(-abs(x$overall.att / x$overall.se)),
      conf.low = x$overall.att - x$overall.se * qnorm(1 - s$alp / 2),
      conf.high = x$overall.att + x$overall.se * qnorm(1 - s$alp / 2)
    )
  }
  if (x$type == "dynamic") {
    ret <- data.frame(
      y.name = s$yname,
      term = paste0("ATT, l = ", x$egt),
      event = x$egt,
      estimate = x$att.egt,
      std.error = x$se.egt,
      p.value = 2 * pnorm(-abs(x$att.egt / x$se.egt)), # TODO: Check how to get confindence-band p-value (now it's pointwise pvalue)
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
    panel.balanced = s$panel,
    control.group = s$control_group,
    anticipation = s$anticipation
  )
  ret
}

tidy_did_list <- function(x) {
  ret <- list(
    tidy = tidy.AGGTEobj(x),
    glance = glance.AGGTEobj(x)
  )
  class(ret) <- "modelsummary_list"
  ret
}

tidy_did <- function(x) {
  ret <- tidy.AGGTEobj(x)
  ret
}
