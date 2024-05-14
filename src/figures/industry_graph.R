library(groundhog)
pkgs <- c(
  "fastverse",
  "igraph",
  "graphlayouts",
  "ggraph",
  "ggforce",
  "purrr"
)
date <- "2024-01-15"
groundhog.library(pkgs, date)

source("src/lib/tag_industry.R")

# Input data ---------------------------------------------------------------

tkt <- fread("out/data/share_eticket_by_industry.csv")
tkt[, namedyear := paste0("szTicket", year)]
sz <- tkt |> dcast(supply ~ namedyear, value.var = "szTicket")

cou <- fread("out/data/cou.csv") |>
  merge(sz, by = "supply")
setnames(cou, "value", "weight")

# Build network ------------------------------------------------------------

net <- graph_from_data_frame(d = cou[weight > 0], directed = TRUE)

indsize <- collap(cou, weight ~ supply)
size <- indsize$weight / sum(indsize$weight)
names(size) <- indsize$supply
V(net)$size <- size * 150
V(net)$name <- tag_industry(V(net)$name)
V(net)$clu <- as.character(membership(cluster_optimal(net)))

# Plot ---------------------------------------------------------------------

p1 <- ggraph(net, layout = "stress", circular = TRUE) +
  # geom_edge_link0(aes(edge_linewidth = weight), edge_colour = "grey66") +
  geom_edge_link0(aes(edge_linewidth = weight, alpha = szTicket2016), edge_colour = "black") +
  geom_node_point(aes(size = size, fill = clu), shape = 21) +
  # geom_node_label(aes(filter = size >= 20, label = name), family = "sans", size = 2, position = position_dodge(width = 1)) +
  geom_node_label(aes(filter = size >= 20, label = name), family = "sans", size = 4, position = position_dodge(width = 1)) +
  scale_edge_width(range = c(0.2, 3)) +
  scale_size(range = c(0.2, 20)) +
  labs(subtitle = "(a) Inter-industry trade network (2012)") +
  # theme_graph() +
  theme(legend.position = "none", plot.subtitle = element_text(hjust = 0.5))

ggsave("out/figures/industry_graph.png", width = 170, height = 120, units = "mm")
