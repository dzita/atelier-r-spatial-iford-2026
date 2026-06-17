# =====================================================================
# J03 — Cartographie thématique tmap + ggplot2 (version exécution salle)
# Atelier IFORD x GDSG · Yaoundé 29 juillet 2026 · Animateur : R. Dzita
# =====================================================================

# ---- 0. Pré-vol -----------------------------------------------------
library(here)
library(sf)
library(dplyr)
library(tibble)
library(ggplot2)
library(tmap)

source(here("pedagogie", "_commons", "helpers", "fetch_data.R"))
source(here("pedagogie", "_commons", "helpers", "theme_iford.R"))

# ---- 1. Charger ADM1 + indicateurs simules --------------------------
adm1 <- read_sf(fetch_gadm_cameroon(1))

regions <- c("Adamaoua","Centre","Est","Extrême-Nord","Littoral",
             "Nord","Nord-Ouest","Ouest","Sud","Sud-Ouest")
pop_est <- c(1340000, 4400000, 870000, 4200000, 3400000,
             2700000, 2000000, 2000000, 800000, 1700000)

tbl_ind <- tibble(
  NAME_1 = regions, pop_2019 = pop_est,
  pct_urbain      = c(35, 75, 25, 30, 95, 28, 22, 45, 38, 28),
  pct_electricite = c(55, 88, 35, 32, 92, 42, 38, 70, 55, 60),
  taille_mng      = c(5.8, 4.5, 6.2, 6.5, 4.1, 6.0, 5.5, 5.0, 5.5, 5.3)
)

adm1_pop <- adm1 |>
  st_transform(3119) |> st_make_valid() |>
  mutate(superficie_km2 = as.numeric(st_area(geometry)) / 1e6) |>
  left_join(tbl_ind, by = "NAME_1") |>
  mutate(densite = pop_2019 / superficie_km2)

# ---- 2. Choroplèthe minimale ----------------------------------------
setup_tmap_iford()
tm_shape(adm1_pop) + tm_polygons("densite") + tm_text("NAME_1", size = 0.6)

# ---- 3. Choroplèthe publiable ---------------------------------------
tm_shape(adm1_pop) +
  tm_polygons(
    fill = "densite",
    fill.scale = tm_scale_intervals(style = "jenks", n = 5,
                                    values = "brewer.yl_or_rd"),
    fill.legend = tm_legend("Densité\n(hab/km²)"),
    col = "white", lwd = 0.4
  ) +
  tm_text("NAME_1", size = 0.55, col = "grey20", fontface = "bold") +
  tm_compass(type = "arrow", position = c("right", "top"), size = 1.2) +
  tm_scalebar(position = c("left", "bottom"), width = 0.25) +
  tm_title("Densité de population par région — Cameroun 2019",
           position = c("left", "top")) +
  tm_credits("Source : BUCREP (estim.), GADM v4.1 · IFORD × GDSG 2026",
             position = c("right", "bottom"), size = 0.5)

# ---- 4. Comparaison 4 classifications -------------------------------
carte_style <- function(style_str, titre) {
  tm_shape(adm1_pop) +
    tm_polygons(
      fill = "densite",
      fill.scale = tm_scale_intervals(style = style_str, n = 5,
                                      values = "brewer.yl_or_rd"),
      fill.legend = tm_legend("hab/km²"),
      col = "white", lwd = 0.3
    ) +
    tm_title(titre, position = c("left", "top"), size = 0.9)
}

c_equal  <- carte_style("equal",    "Intervalles égaux")
c_quant  <- carte_style("quantile", "Quantiles")
c_jenks  <- carte_style("jenks",    "Jenks (Fisher)")
c_manual <- tm_shape(adm1_pop) +
  tm_polygons(fill = "densite",
              fill.scale = tm_scale_intervals(
                breaks = c(0, 10, 50, 100, 200, 400),
                values = "brewer.yl_or_rd"),
              fill.legend = tm_legend("hab/km²"),
              col = "white", lwd = 0.3) +
  tm_title("Manuel : 0/10/50/100/200/400", position = c("left", "top"), size = 0.9)

tmap_arrange(c_equal, c_quant, c_jenks, c_manual, ncol = 2)

# ---- 5. Multi-panel densite vs urbain -------------------------------
c_dens <- tm_shape(adm1_pop) +
  tm_polygons(fill = "densite",
              fill.scale = tm_scale_intervals(style = "jenks", n = 5,
                                              values = "brewer.yl_or_rd"),
              fill.legend = tm_legend("Densité\n(hab/km²)"),
              col = "white", lwd = 0.3) +
  tm_text("NAME_1", size = 0.45, col = "grey20") +
  tm_title("a. Densité", position = c("left", "top"))

c_urb <- tm_shape(adm1_pop) +
  tm_polygons(fill = "pct_urbain",
              fill.scale = tm_scale_intervals(style = "jenks", n = 5,
                                              values = "brewer.blues"),
              fill.legend = tm_legend("% urbain"),
              col = "white", lwd = 0.3) +
  tm_text("NAME_1", size = 0.45, col = "grey20") +
  tm_title("b. Urbanisation", position = c("left", "top"))

tmap_arrange(c_dens, c_urb, ncol = 2)

# ---- 6. Bascule mode view (interactif) ------------------------------
# tmap_mode("view")
# tm_shape(adm1_pop) +
#   tm_polygons(fill = "densite",
#               fill.scale = tm_scale_intervals(style = "jenks", n = 5,
#                                               values = "brewer.yl_or_rd"),
#               fill_alpha = 0.7)
# tmap_mode("plot")

# ---- 7. Version ggplot2 + geom_sf -----------------------------------
ggplot(adm1_pop) +
  geom_sf(aes(fill = densite), color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "B", trans = "sqrt",
                       name = "Densité\n(hab/km²)") +
  geom_sf_label(aes(label = NAME_1), size = 2.3,
                color = "white", fontface = "bold") +
  labs(title = "Densité de population — Cameroun 2019",
       subtitle = "Lambert Cameroun (EPSG:3119)",
       caption = "Source : BUCREP estim., GADM v4.1") +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank())

# ---- 8. Export PNG + PDF + HTML -------------------------------------
# out_dir <- here("pedagogie", "J03_cartographie_tmap_ggplot", "outputs")
# dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
# tmap_save(c_dens, file.path(out_dir, "densite_jenks.png"),
#           dpi = 300, width = 9, height = 7)
# tmap_save(c_dens, file.path(out_dir, "densite_jenks.pdf"),
#           width = 9, height = 7)

# Fin J3
