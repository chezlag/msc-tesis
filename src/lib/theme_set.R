# groundhog.library("cowplot", "2024-01-15")
library(cowplot)
# library(extrafont)
# loadfonts()
# par(family = "LM Roman 10")
theme_set(
  cowplot::theme_half_open(font_size = 10) +
    cowplot::background_grid("y") +
    theme(
      legend.position = "bottom",
      legend.box = "vertical",
      legend.margin = margin(),
      panel.grid.major.x = element_line(),
      panel.border = element_rect(color = "grey30")
    )
)
