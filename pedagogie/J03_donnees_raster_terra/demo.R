# =====================================================================
# J03 — Données raster dans R avec terra (version exécution salle)
# Atelier IFORD x GDSG · Yaoundé 29 juillet 2026 · Animateur : R. Dzita
# =====================================================================

# ---- 0. Pré-vol -----------------------------------------------------
# terra = package raster moderne (successeur de l'ancien package raster).
# exactextractr = extraction zonale ultra-rapide, precise au pixel-fraction.
library(here)
library(sf)
library(terra)
library(dplyr)
library(tibble)
library(ggplot2)
library(exactextractr)

source(here("pedagogie", "_commons", "helpers", "fetch_data.R"))
source(here("pedagogie", "_commons", "helpers", "theme_iford.R"))

# ---- 1. Charger le SRTM Cameroun (donnees reelles NASA/USGS) -------
# MNT = Modele Numerique de Terrain (chaque pixel = une altitude en m).
# SRTM = mission satellite NASA/USGS, 30 arc-sec ~ 1 km ici.
# rast() = ouverture paresseuse (pointeur fichier, pas de chargement RAM).
srtm <- rast(fetch_srtm_cameroon())
names(srtm) <- "elevation_m"

# Inspection : resolution (taille pixel), emprise, nb bandes, nb cellules
res(srtm); ext(srtm); nlyr(srtm); ncell(srtm)
plot(srtm,
     main = "Altitude (m) — Cameroun",
     plg = list(title = "m"),
     sub = "Source : NASA SRTM 30 arc-sec · IFORD x GDSG 2026")

# ---- 2. Charger les polygones ADM -----------------------------------
adm0 <- read_sf(fetch_gadm_cameroon(0))
adm1 <- read_sf(fetch_gadm_cameroon(1))
adm3 <- read_sf(fetch_gadm_cameroon(3))

# ---- 3. crop puis mask ---------------------------------------------
# crop() = decoupe a la bbox (rectangle englobant) du vecteur.
# mask() = met NA hors des polygones (forme exacte). On enchaine TOUJOURS.
srtm_cmr        <- crop(srtm, adm0)
srtm_cmr_masked <- mask(srtm_cmr, vect(adm0))
plot(srtm_cmr_masked,
     main = "Altitude (m) — Cameroun (cropé + masqué)",
     plg = list(title = "m"),
     sub = "Source : NASA SRTM 30 arc-sec · GADM v4.1 · IFORD x GDSG 2026")

# ---- 4. aggregate ---------------------------------------------------
# aggregate(fact = 5) : 5x5 = 25 pixels fusionnes en 1 (moyenne par defaut).
srtm_agg <- aggregate(srtm_cmr_masked, fact = 5, fun = "mean", na.rm = TRUE)
res(srtm_agg)

# ---- 5. resample ----------------------------------------------------
# resample() = reprojette le raster sur une grille cible (autre resolution / origine).
template_100m <- rast(srtm_cmr_masked)
res(template_100m) <- c(0.001, 0.001)
srtm_aligned <- resample(srtm_cmr_masked, template_100m, method = "bilinear")

# ---- 6. Algèbre raster ----------------------------------------------
# Algebre raster = on traite le raster comme une matrice : ops pixel par pixel.
srtm_km <- srtm_cmr_masked / 1000
basse_alt <- srtm_cmr_masked < 500  # raster booleen (1 = vrai, 0 = faux, NA hors masque)
plot(basse_alt,
     main = "Zones de basse altitude (< 500 m) — Cameroun",
     plg = list(title = "classe"),
     sub = "Source : NASA SRTM 30 arc-sec · IFORD x GDSG 2026")

# Classification : 4 classes d'altitude via ifel() empile.
zones_classes <- ifel(srtm_cmr_masked < 200, 1,
                ifel(srtm_cmr_masked < 500, 2,
                ifel(srtm_cmr_masked < 1000, 3, 4)))
plot(zones_classes,
     main = "Classes d'altitude — Cameroun",
     plg = list(title = "classe (1=<200m, 2=200-500, 3=500-1000, 4=>1000)"),
     sub = "Source : NASA SRTM 30 arc-sec · IFORD x GDSG 2026")

# ---- 7. Stat globale ------------------------------------------------
# global() = statistique calculee sur TOUS les pixels valides du raster.
global(srtm_cmr_masked, c("mean", "min", "max", "sd"), na.rm = TRUE) |> round()

# ---- 8. Extraction zonale par région (terra) ------------------------
# Extraction zonale = pour chaque polygone (region), resumer les pixels qui tombent dedans.
elev_region <- terra::extract(srtm_cmr_masked, vect(adm1),
                              fun = "mean", na.rm = TRUE)
elev_region$NAME_1 <- adm1$NAME_1
arrange(elev_region |> select(NAME_1, elevation_m), desc(elevation_m))

# ---- 9. Extraction zonale (exactextractr - rapide + precis) ---------
elev_exact <- exact_extract(srtm_cmr_masked, adm1, c("mean","min","max"))
adm1_elev <- adm1 |>
  mutate(elev_moy = round(elev_exact$mean),
         elev_min = round(elev_exact$min),
         elev_max = round(elev_exact$max))
adm1_elev |> st_drop_geometry() |>
  select(NAME_1, elev_moy, elev_min, elev_max) |>
  arrange(desc(elev_moy))

# ---- 10. Carte choroplèthe élévation moyenne ------------------------
# Choroplethe : la couleur de chaque region code l'altitude moyenne extraite.
ggplot(adm1_elev) +
  geom_sf(aes(fill = elev_moy), color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "G", name = "Élévation\nmoyenne (m)") +
  geom_sf_label(aes(label = NAME_1), size = 2.2, colour = "black",
                fill = scales::alpha("white", 0.75), label.size = 0,
                fontface = "bold", label.padding = unit(0.1, "lines")) +
  labs(title = "Élévation moyenne par région — Cameroun",
       subtitle = "MNT SRTM 30 arc-sec agrégé par exact_extract",
       caption = "Source : NASA SRTM 30 arc-sec · GADM v4.1 · IFORD x GDSG 2026") +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank())

# ---- 11. Cas RGPH 4 : arrondissements en basse altitude -------------
adm3$pct_basse_alt <- exact_extract(basse_alt, adm3, "mean") * 100
adm3 |> st_drop_geometry() |>
  select(NAME_1, NAME_3, pct_basse_alt) |>
  arrange(desc(pct_basse_alt)) |>
  head(10)

# Fin J3
