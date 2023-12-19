# Specific groups of functions
source("src/lib/stata_helpers.R")

# All single-use functions without grouping
directory_path <- "src/lib"
file_pattern <- "^fun_.*\\.[rR]$"
file_list <- list.files(directory_path, pattern = file_pattern, full.names = TRUE)
for (file in file_list) source(file)
source("src/lib/winsorize.r")
