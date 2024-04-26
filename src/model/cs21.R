cs21_att_gt <- function(yname, xformla, data, unbalanced = TRUE) {
  message("Estimating ATT(g,t) for ", yname, " ", xformla)
  did::att_gt(
    yname = yname,
    gname = "G1",
    idname = "fid",
    tname = "year",
    xformla = as.formula(xformla),
    data = data,
    control_group = "notyettreated",
    allow_unbalanced_panel = unbalanced,
    clustervars = "fid",
    est_method = "dr",
    base_period = "universal"
  )
}

cs21_simple <- function(att_gt) {
  did::aggte(
    att_gt,
    type = "simple",
    clustervars = "fid",
    bstrap = TRUE,
    na.rm = TRUE
  )
}

cs21_dynamic <- function(att_gt) {
  did::aggte(
    att_gt,
    type = "dynamic",
    clustervars = "fid",
    bstrap = TRUE,
    na.rm = TRUE
  )
}
