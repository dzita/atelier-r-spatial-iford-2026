# =====================================================================
# J05 — Visualisation et cartographie tmap + ggplot2 (exécution salle)
# Atelier IFORD x GDSG · Yaoundé 31 juillet 2026 · Animateur : R. Dzita
# =====================================================================

# ---- 0. Pré-vol -----------------------------------------------------
# here : chemins absolus reproductibles depuis la racine projet.
# sf : objets vectoriels spatiaux. dplyr/tibble : manipulation.
# ggplot2 + tmap : les deux moteurs cartographiques du jour.
library(here)
library(sf)
library(dplyr)
library(tibble)
library(ggplot2)
library(tmap)

# Helpers internes : fetch_data pour télécharger GADM,
# theme_iford pour les défauts visuels IFORD partagés.
source(here("pedagogie", "_commons", "helpers", "fetch_data.R"))
source(here("pedagogie", "_commons", "helpers", "theme_iford.R"))

# ---- 1. Charger ADM1 + indicateurs DHS Cameroun 2018 reels ----------
# Lecture des polygones GADM ADM1 (10 régions du Cameroun).
adm1 <- read_sf(fetch_gadm_cameroon(1))

# NB version script live : on utilise des estimations BUCREP pop_2019
# pour calculer une DENSITÉ (illustrative de la jointure), alors que demo.qmd
# bascule sur les indicateurs DHS réels. Les deux logiques se valent.
regions <- c("Adamaoua","Centre","Est","Extrême-Nord","Littoral",
             "Nord","Nord-Ouest","Ouest","Sud","Sud-Ouest")
pop_est <- c(1340000, 4400000, 870000, 4200000, 3400000,
             2700000, 2000000, 2000000, 800000, 1700000)

# tibble = tableau moderne, plus permissif que data.frame pour les noms et types.
tbl_ind <- tibble(
  NAME_1 = regions, pop_2019 = pop_est,
  pct_urbain      = c(35, 75, 25, 30, 95, 28, 22, 45, 38, 28),
  pct_electricite = c(55, 88, 35, 32, 92, 42, 38, 70, 55, 60),
  taille_mng      = c(5.8, 4.5, 6.2, 6.5, 4.1, 6.0, 5.5, 5.0, 5.5, 5.3)
)

# Préparation cartographique : reproj Lambert + aires + jointure + densité.
adm1_pop <- adm1 |>
  st_transform(3119) |> st_make_valid() |>
  mutate(superficie_km2 = as.numeric(st_area(geometry)) / 1e6) |>
  left_join(tbl_ind, by = "NAME_1") |>
  mutate(densite = pop_2019 / superficie_km2)

# ---- 2. Choroplèthe minimale ----------------------------------------
# setup_tmap_iford applique le thème commun. Squelette minimal en 3 lignes.
setup_tmap_iford()
tm_shape(adm1_pop) + tm_polygons("densite") + tm_text("NAME_1", size = 0.6)

# ---- 3. Choroplèthe publiable ---------------------------------------
# Version "production" : Jenks, palette YlOrRd, contours blancs,
# étiquettes, flèche, échelle, titre, crédits sourcés.
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
  tm_scalebar(position = c("left", "bottom"), breaks = c(0, 100, 200)) +
  tm_title("Densité de population par région — Cameroun 2019",
           position = c("left", "top")) +
  tm_credits(paste("Source : BUCREP (estim. 2019) · GADM v4.1 ·",
                   "classification Jenks · projection Lambert EPSG:3119 ·",
                   "IFORD x GDSG 2026"),
             position = c("right", "bottom"), size = 0.45)

# ---- 4. Comparaison 4 classifications -------------------------------
# Fonction utilitaire : on ne réécrit pas 4 fois la même structure tmap.
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

# 4 méthodes de découpage de la même variable : à comparer visuellement.
c_equal  <- carte_style("equal",    "a. Intervalles égaux")
c_quant  <- carte_style("quantile", "b. Quantiles")
c_jenks  <- carte_style("jenks",    "c. Jenks (Fisher)")
# Cas manuel : seuils choisis arbitrairement (lisibles politiquement).
c_manual <- tm_shape(adm1_pop) +
  tm_polygons(fill = "densite",
              fill.scale = tm_scale_intervals(
                breaks = c(0, 10, 50, 100, 200, 400),
                values = "brewer.yl_or_rd"),
              fill.legend = tm_legend("hab/km²"),
              col = "white", lwd = 0.3) +
  tm_title("d. Manuel : 0/10/50/100/200/400", position = c("left", "top"), size = 0.9)

# tmap_arrange empile en grille (2 colonnes ici = 2x2).
tmap_arrange(c_equal, c_quant, c_jenks, c_manual, ncol = 2)

# ---- 5. Multi-panel densite vs urbain -------------------------------
# Deux cartes côte à côte = comparaison directe des deux indicateurs.
c_dens <- tm_shape(adm1_pop) +
  tm_polygons(fill = "densite",
              fill.scale = tm_scale_intervals(style = "jenks", n = 5,
                                              values = "brewer.yl_or_rd"),
              fill.legend = tm_legend("Densité\n(hab/km²)"),
              col = "white", lwd = 0.3) +
  tm_text("NAME_1", size = 0.45, col = "grey20") +
  tm_compass(type = "arrow", position = c("right", "top"), size = 0.8) +
  tm_scalebar(position = c("left", "bottom")) +
  tm_title("a. Densité de population (hab/km²)",
           position = c("left", "top"), size = 0.9)

c_urb <- tm_shape(adm1_pop) +
  tm_polygons(fill = "pct_urbain",
              fill.scale = tm_scale_intervals(style = "jenks", n = 5,
                                              values = "brewer.blues"),
              fill.legend = tm_legend("% urbain (%)"),
              col = "white", lwd = 0.3) +
  tm_text("NAME_1", size = 0.45, col = "grey20") +
  tm_compass(type = "arrow", position = c("right", "top"), size = 0.8) +
  tm_scalebar(position = c("left", "bottom")) +
  tm_title("b. Taux d'urbanisation des ménages",
           position = c("left", "top"), size = 0.9) +
  tm_credits(paste("Source : BUCREP (estim. 2019) · GADM v4.1 ·",
                   "IFORD x GDSG 2026"),
             position = c("right", "bottom"), size = 0.4)

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
# Même carte en ggplot2 : geom_sf gère les polygones,
# scale_fill_viridis_c applique une palette continue,
# trans = "sqrt" étire les bas pour mieux différencier les densités faibles.
ggplot(adm1_pop) +
  geom_sf(aes(fill = densite), color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "B", trans = "sqrt",
                       name = "Densité\n(hab/km²)") +
  geom_sf_label(aes(label = NAME_1), size = 2.3, colour = "black",
                fill = scales::alpha("white", 0.75), label.size = 0,
                fontface = "bold", label.padding = unit(0.1, "lines")) +
  labs(title = "Densité de population par région — Cameroun 2019",
       subtitle = "Projection Lambert Cameroun (EPSG:3119) · échelle racine carrée",
       caption = "Source : BUCREP (estim. 2019) · GADM v4.1 · IFORD x GDSG 2026") +
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

# Fin J5
