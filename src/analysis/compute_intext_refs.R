library(groundhog)
pkgs <- c("fastverse", "fst", "purrr")
date <- "2024-01-15"
groundhog.library(pkgs, date)

# read datasets
samples <- read_fst("out/data/samples.fst", as.data.table = TRUE)
dts <- read_fst("out/data/firms_static.fst", as.data.table = TRUE) %>%
  .[samples, on = "fid"]
dty <- read_fst("out/data/firms_yearly.fst", as.data.table = TRUE) %>%
  .[samples, on = "fid"]

# List of commands
cmdlist <-
  c(
    "dts[(inSample3), .N]",
    "(dty[(inSample3), fmean(Scaler1)] / 1e6) |> round(digits = 1)",
    "dty[(inSample3), fmean(neverTreated)] |> round(digits = 1)",
    "dty[(inSample3), fmean(emittedAnyT)] |> round(digits = 1)",
    "dts[(emittedAnyT), .N]",
    "round(100 * dts[(inSample3), fmean(neverTreated)], digits = 1)"
  )
outlist <-
  map(cmdlist, \(x) eval(parse(text = x)) |> as.character()) |> unlist()

# Parse commands
tab <- data.table(cmd = cmdlist, out = outlist)

# export table
fwrite(tab, "out/analysis/intext_refs.csv")
