library(data.table)

winsorize_above_quantile <- function(data, sample_var = "", target_year, target_var, quantile_prob = 0.95) {

    if (sample_var == "") {
        threshold <- quantile(data[year == target_year, ..target_var], quantile_prob, na.rm = TRUE)
        data[year == target_year & get(target_var) > threshold, (target_var) := threshold]
    } else {
        threshold <- quantile(data[get(sample_var) & year == target_year, ..target_var], quantile_prob, na.rm = TRUE)
        data[get(sample_var) & year == target_year & get(target_var) > threshold, (target_var) := threshold]
    }

    # No need to return the modified data since it's modified in memory
}

# # Example
# # Create a sample data.table (replace this with your actual data)
# dat <- data.table(year = c(2010, 2010, 2010, 2011, 2011, 2011),
#                   value = c(1.5, 2.0, 2.5, 3.0, 3.5, 4.0))

# # Apply the windsorize_above_quantile function directly to modify dat
# windsorize_above_quantile(dat, target_year = 2010, target_var = "value")

# # Print the modified data.table
# print(dat)