define_industry <- function(x) {
  ret <- data.table::fcase(
    x %in% c("A", "B"), "a_b",
    x %in% c("D", "E"), "d_e",
    x %in% c("G", "I"), "g_i",
    x %in% c("H", "J"), "h_j",
    x %in% c("M", "N"), "m_n",
    x %in% c("P", "Q", "R", "S", "T"), "p_q_r_s_t",
    x %in% c("C", "F", "K", "L", "O"), stringr::str_to_lower(x)
  )
  ret
}
