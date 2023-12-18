# STATA-like helper functions

# Load libraries
library(data.table)

# compare_columns: similar to compare
compare_columns <- function(dt, col_A, col_B) {
    num_rows_A_gt_B <- dt[get(col_A) > get(col_B), .N]
    num_rows_equal <- dt[get(col_A) == get(col_B), .N]
    num_rows_A_lt_B <- dt[get(col_B) > get(col_A), .N]
    num_rows_missing_A <- dt[is.na(get(col_A)) & !is.na(get(col_B)), .N]
    num_rows_missing_B <- dt[is.na(get(col_B)) & !is.na(get(col_A)), .N]
    num_rows_missing_either <- dt[is.na(get(col_A)) | is.na(get(col_B)), .N]
    num_rows_missing_none <- dt[!is.na(get(col_A)) & !is.na(get(col_B)), .N]
    num_rows_missing_both <- dt[is.na(get(col_A)) & is.na(get(col_B)), .N]
    num_rows_total <- dt[, .N]

    # result <- list(
    #     A_gt_B = num_rows_A_gt_B,
    #     Equal = num_rows_equal,
    #     B_gt_A = num_rows_A_lt_B,
    #     Missing_A = num_rows_missing_A,
    #     Missing_B = num_rows_missing_B,
    #     Missing_Either = num_rows_missing_either,
    #     Missing_None = num_rows_missing_none
    # )
    message_nchars <- c(
        nchar(paste0(col_A, " > ", col_B, ": ")),
        nchar("Jointly defined: "),
        nchar(paste0(col_A, " missing only: ")),
        nchar(paste0(col_B, " missing only: ")),
        nchar("Total: ")
    )
    message_col_result <- max(message_nchars)
    message_padding_len <- sapply(message_nchars, \(x) message_col_result - x)
    message_padding <- sapply(message_padding_len, \(x) strrep(" ", x))

    if (num_rows_A_lt_B > 0) message(col_A, " < ", col_B, ": ", message_padding[1], num_rows_A_lt_B)
    if (num_rows_equal > 0) message(col_A, " = ", col_B, ": ", message_padding[1], num_rows_equal)
    if (num_rows_A_gt_B > 0) message(col_A, " > ", col_B, ": ", message_padding[1], num_rows_A_gt_B)
    message(strrep(" ", message_col_result), strrep("-", nchar(as.character(num_rows_total))))
    message("Jointly defined: ", message_padding[2], num_rows_missing_none)
    if (num_rows_missing_A > 0) message(col_A, " missing only: ", message_padding[3], num_rows_missing_A)
    if (num_rows_missing_B > 0) message(col_B, " missing only: ", message_padding[4], num_rows_missing_B)
    if (num_rows_missing_both > 0) message("Jointly missing: ", message_padding[2], num_rows_missing_both)
    message(strrep(" ", message_col_result), strrep("-", nchar(as.character(num_rows_total))))
    message("Total: ", message_padding[5], num_rows_total)
}

# drop_columns: Drop columns by regex pattern
drop_columns <- function(dt, pattern, message = TRUE) {
    cols_to_drop <- grep(pattern, names(dt), value = TRUE)
    dt[, (cols_to_drop) := NULL]
    if (message) message("Columns dropped: ", cols_to_drop)
    return(dt)
}

# # Sample data.table
# dt <- data.table(
#   ID = 1:5,
#   Name_Age = c("Alice_25", "Bob_30", "Charlie_22", "David_28", "Eve_35"),
#   Score_X = c(90, 85, 78, 92, 88),
#   Score_Y = c(75, 89, 93, 81, 87)
# )

# # Drop columns with "Score_" pattern
# new_dt <- drop_columns_by_pattern(dt, "Score_")

# # Print the modified data.table
# print(new_dt)

# isid: Function to check if a set of variables forms a unique identifier
isid <- function(data, vars_to_check) {
    # Convert data to a data.table if it's not already
    if (!is.data.table(data)) {
        data <- data.table(data)
    }

    # check if unique ids are equal to N
    n_duplicates <- data[, .N] - dim(unique(data[, ..vars_to_check]))[1]

    # If unique say nothing, if not unique message N duplicate
    if (n_duplicates > 0) {
        message(paste(vars_to_check, collapse = ", "), " do not uniquely identify the rows of the dataset.")
        message("There are ", n_duplicates, " duplicates.")
    }
}

# # Example usage:
# # Create a data.table object (replace this with your data)
# dt <- data.table(
#   var1 = c(1, 2, 3, 4, 5),
#   var2 = c("A", "B", "C", "D", "E"),
#   var3 = c(10, 20, 30, 40, 50)
# )

# # Define the set of variables you want to check for uniqueness
# vars_to_check <- c("var1", "var2", "var3")

# # Call the function to check for uniqueness
# result <- isid(dt, vars_to_check)

# # Print the result
# print(result)

# mvencode: Recode columns' missing values to specified value
mvencode <- function(data, columns, missing_code, .if = "") {
    # Check if the data is a data.table
    if (!is.data.table(data)) {
        stop("Input 'data' must be a data.table.")
    }

    # Iterate through the specified columns and encode missing values
    for (col in columns) {
        data[eval(parse(text = .if)), (col) := ifelse(is.na(get(col)), missing_code, get(col))]
    }
}

# # Example usage:
# library(data.table)

# # Create a sample data table with missing values
# dt <- data.table(
#   ID = 1:5,
#   Var1 = c(10, NA, 30, 40, NA),
#   Var2 = c(5, 15, NA, 35, NA)
# )

# # Specify the columns and missing code
# columns_to_encode <- c("Var1", "Var2")
# missing_code <- -999

# # Encode missing values in the specified columns
# encoded_data <- encodeMissingValues(dt, columns_to_encode, missing_code)

# # Print the updated data table
# print(encoded_data)

# rowtotal: Como rowSums() pero preserva el missing si todas las variables son missing
rowtotal <- function(dat, newvarname, varlist, .if = "") {
    # Determinar si hay una condicion de subsetting
    cond2 <- ""
    if (.if != "") cond2 <- paste0(" & ", .if)

    # Agregar columna que indica si todas las columnas en varlist son NA
    dat[, allNA := rowSums(is.na(.SD)) == length(varlist), .SDcols = varlist]

    # Calcular la nueva variable solo para las filas donde allNA es FALSE
    dat[eval(parse(text = paste0("!(allNA)", cond2))), (newvarname) := rowSums(.SD, na.rm = TRUE), .SDcols = varlist]

    # Eliminar la columna auxiliar allNA
    dat[, allNA := NULL]

    return(dat)
}

# # Ejemplo de uso
# library(data.table)

# # Crear un data.table de ejemplo
# dat <- data.table(
#   v160 = c(10, NA, 30, 40),
#   v161 = c(NA, 25, NA, 40),
#   v162 = c(NA, NA, NA, 40)
# )

# newvarname <- "ventas"
# varlist <- c("v160", "v161", "v162")

# # Utilizar la función para calcular y asignar la nueva variable
# result <- rowtotal(dat, newvarname, varlist)

# # Imprimir el resultado
# print(result)