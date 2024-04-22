tag_industry <- function(x) {
  ret <- fcase(
    x == "a_b", "Primary act.",
    x == "c", "Manufacturing",
    x == "d_e", "Utilties",
    x == "f", "Construction",
    x == "g_i", "Trade & accom.",
    x == "h_j", "TSC",
    x == "k", "Finance",
    x == "l", "Real estate",
    x == "m_n", "Prof. & sci. act.",
    x == "o", "Government",
    x == "p_q_r_s_t", "Educ., health & oth."
  )
}
