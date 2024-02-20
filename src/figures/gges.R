gges <- function(spec, yvar, ylab) {
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
    paste0("out/figures/tmp/", yvar, "_", spec, ".png"),
    width = 170,
    height = 100,
    units = "mm"
  )
}
