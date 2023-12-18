winsorize <- function(x, q = 0.95) {
    threshold <- quantile(x, q, na.rm = TRUE)
    x[x > threshold] <- threshold
    return(x)
}
