tag_section <- function(x) {
  ret <- data.table::fcase(
    x == "A", "Agriculture, forestry & fishing",
    x == "B", "Mining & quarrying",
    x == "C", "Manufacturing",
    x == "D", "Electricty, gas & AC supply",
    x == "E", "Water supply",
    x == "F", "Construction",
    x == "G", "Wholesale & retail trade",
    x == "H", "Transportation & storage",
    x == "I", "Accomodation & food service",
    x == "J", "Information & communication",
    x == "K", "Financial & insurance act.",
    x == "L", "Real estate act.",
    x == "M", "Personal, sci. & tech. act.",
    x == "N", "Adm. & support act.",
    x == "O", "Public admin. & defense",
    x == "P", "Education",
    x == "Q", "Human health & social work act.",
    x == "R", "Arts, entertainment & rec. act.",
    x == "S", "Other service act.",
    x == "T", "Act. of households as employers",
    x == "X", "Not classified"
  )
  ret
}
