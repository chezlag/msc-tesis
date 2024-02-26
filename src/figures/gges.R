library(groundhog)
pkgs <- c(
  "data.table",
  "did",
  "forcats",
  "ggplot2",
  "ggsci",
  "magrittr",
  "purrr",
  "stringr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)
source("src/lib/tidy_did.R")
source("src/lib/theme_set.R")

gges_all <- function(spec, yvar, ylab) {
  est <- readRDS(paste0("out/analysis/did.y.all.", spec, ".RDS"))
  tidy <- est$dynamic[[yvar]] |> tidy_did() |> setDT()
  attgt <- est$attgt[[yvar]]
  simple <- est$simple[[yvar]]

  sig <- ifelse(
    inrange(0, tidy_did(simple)$conf.low, tidy_did(simple)$conf.high),
    "",
    "**"
  )

  tidy[y.name == yvar & inrange(event, -4, 4)] %>%
    .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
    ggplot(aes(x = event, y = estimate, color = treat, fill = treat)) +
      geom_point(size = 2) +
      geom_rect(
        aes(
          ymin = conf.low,
          ymax = conf.high,
          xmin = event - 0.1,
          xmax = event + 0.1,
          fill = treat
        ),
        alpha = 0.4,
        inherit.aes = FALSE
      ) +
      geom_hline(yintercept = 0, linetype = "dashed") +
      scale_x_continuous(breaks = -4:3) +
      scale_y_continuous(labels = scales::dollar_format()) +
      scale_color_startrek() +
      scale_fill_startrek() +
      labs(
        x = "Años desde el tratamiento", y = ylab
      ) +
      theme(legend.position = "none")

  ggsave(
    paste0("out/figures/did.y.all.", yvar, ".", spec, ".png"),
    width = 170,
    height = 100,
    units = "mm"
  )
}

gges_by_industry <- function(spec, yvar, ylab) {
  est <- readRDS(paste0("out/analysis/did.y.by_industry.", spec, ".RDS"))
  items <- grep(yvar, names(est$dynamic))
  indlist <- str_remove(names(est$dynamic)[items], paste0(yvar, "."))
  tidy <-
    map2(
      est$dynamic[items],
      indlist,
      \(x, y) tidy_did(x) %>% setDT() %>% .[, sector := y]
    ) |>
    reduce(rbind)
  tidy[inrange(event, -4, 2)] %>%
    .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
    ggplot(aes(x = event, y = estimate, color = sector)) +
      geom_point(position = position_dodge(width = .3)) +
      geom_rect(
        aes(
          ymin = conf.low,
          ymax = conf.high,
          xmin = event - .1,
          xmax = event + .1,
          fill = sector,
          alpha = fct_rev(treat)
        ),
        inherit.aes = FALSE,
        position = position_dodge(width = .3)
      ) +
      facet_wrap(~sector, scale = "free_y") +
      geom_hline(yintercept = 0, linetype = "dashed") +
      scale_x_continuous(breaks = -4:3) +
      scale_color_d3() +
      scale_fill_d3() +
      scale_alpha_discrete(range = c(0.2, 0.6)) +
      labs(
        x = "Años desde el tratamiento", y = ylab,
        color = NULL, fill = NULL, alpha = NULL
      )

  ggsave(
    paste0("out/figures/did.y.by_industry.", yvar, ".", spec, ".png"),
    width = 170,
    height = 100,
    units = "mm"
  )
}

gges_by_size <- function(spec, yvar, ylab) {
  est <- readRDS(paste0("out/analysis/did.y.by_size.", spec, ".RDS"))
  items <- grep(yvar, names(est$dynamic))
  sizelist <- str_remove(names(est$dynamic)[items], paste0(yvar, "."))
  tidy <-
    map2(
      est$dynamic[items],
      sizelist,
      \(x, y) tidy_did(x) %>% setDT() %>% .[, sizeQuartile := y]
    ) |>
    reduce(rbind)
  tidy[inrange(event, -4, 2)] %>%
    .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
    ggplot(aes(x = event, y = estimate, color = sizeQuartile)) +
      geom_point(position = position_dodge(width = .3)) +
      geom_rect(
        aes(
          ymin = conf.low,
          ymax = conf.high,
          xmin = event - .1,
          xmax = event + .1,
          fill = sizeQuartile,
          alpha = fct_rev(treat)
        ),
        inherit.aes = FALSE,
        position = position_dodge(width = .3)
      ) +
      facet_wrap(~sizeQuartile, scale = "free_y") +
      geom_hline(yintercept = 0, linetype = "dashed") +
      scale_x_continuous(breaks = -4:3) +
      scale_color_d3() +
      scale_fill_d3() +
      scale_alpha_discrete(range = c(0.2, 0.6)) +
      labs(
        x = "Años desde el tratamiento", y = ylab,
        alpha = NULL,
        color = "Cuartil de facturación pre-tratamiento", 
        fill = "Cuartil de facturación pre-tratamiento"
      )

  ggsave(
    paste0("out/figures/did.y.by_size.", yvar, ".", spec, ".png"),
    width = 170,
    height = 100,
    units = "mm"
  )
}

gges_quarterly <- function(spec, yvar, ylab) {
  est <- readRDS(paste0("out/analysis/did.q.all.", spec, ".RDS"))
  tidy <- est$dynamic[[yvar]] |> tidy_did() |> setDT()
  attgt <- est$attgt[[yvar]]
  simple <- est$simple[[yvar]]

  sig <- ifelse(
    inrange(0, tidy_did(simple)$conf.low, tidy_did(simple)$conf.high),
    "",
    "**"
  )

  tidy[y.name == yvar & inrange(event, -20, 12)] %>%
    .[, treat := fifelse(event < 0, "Pre", "Post")] %>%
    ggplot(aes(x = event, y = estimate, color = treat, fill = treat)) +
    geom_point(size = 2) +
    geom_rect(
      aes(
        ymin = conf.low,
        ymax = conf.high,
        xmin = event - 0.1,
        xmax = event + 0.1,
        fill = treat
      ),
      alpha = 0.4,
      inherit.aes = FALSE
    ) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_x_continuous(breaks = seq(-20, 12, 4)) +
    scale_y_continuous(labels = scales::dollar_format()) +
    scale_color_startrek() +
    scale_fill_startrek() +
    labs(
      x = "Trimestres desde el tratamiento", y = ylab,
      caption = paste0("Overall ATT: ", round(simple$overall.att, 3), sig)
    ) +
    theme(legend.position = "none")

  ggsave(
    paste0("out/figures/did.q.all.", yvar, ".", spec, ".png"),
    width = 170,
    height = 100,
    units = "mm"
  )
}
