# =====================================================================
# J03 — Données raster dans R avec terra (version exécution salle)
# Atelier IFORD x GDSG · Yaoundé 29 juillet 2026 · Animateur : R. Dzita
# =====================================================================

# ---- 0. Pré-vol -----------------------------------------------------
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
# Le .tif est produit par pedagogie/_commons/data/cmr_srtm/00_telecharger_srtm.R
# (geodata::elevation_30s("CMR") + crop + mask, ~3 Mo).
srtm <- rast(fetch_srtm_cameroon())
names(srtm) <- "elevation_m"

# Inspection
res(srtm); ext(srtm); nlyr(srtm); ncell(srtm)
plot(srtm)

# ---- 2. Charger les polygones ADM -----------------------------------
adm0 <- read_sf(fetch_gadm_cameroon(0))
adm1 <- read_sf(fetch_gadm_cameroon(1))
adm3 <- read_sf(fetch_gadm_cameroon(3))

# ---- 3. crop puis mask ---------------------------------------------
srtm_cmr        <- crop(srtm, adm0)
srtm_cmr_masked <- mask(srtm_cmr, vect(adm0))
plot(srtm_cmr_masked, main = "SRTM cropé et masqué sur le Cameroun")

# ---- 4. aggregate ---------------------------------------------------
srtm_agg <- aggregate(srtm_cmr_masked, fact = 5, fun = "mean", na.rm = TRUE)
res(srtm_agg)

# ---- 5. resample ----------------------------------------------------
template_100m <- rast(srtm_cmr_masked)
res(template_100m) <- c(0.001, 0.001)
srtm_aligned <- resample(srtm_cmr_masked, template_100m, method = "bilinear")

# ---- 6. Algèbre raster ----------------------------------------------
srtm_km <- srtm_cmr_masked / 1000
basse_alt <- srtm_cmr_masked < 500
plot(basse_alt, main = "Zones < 500 m")

zones_classes <- ifel(srtm_cmr_masked < 200, 1,
                ifel(srtm_cmr_masked < 500, 2,
                ifel(srtm_cmr_masked < 1000, 3, 4)))
plot(zones_classes)

# ---- 7. Stat globale ------------------------------------------------
global(srtm_cmr_masked, c("mean", "min", "max", "sd"), na.rm = TRUE) |> round()

# ---- 8. Extraction zonale par région (terra) ------------------------
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
ggplot(adm1_elev) +
  geom_sf(aes(fill = elev_moy), color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "G", name = "Élévation (m)") +
  geom_sf_label(aes(label = NAME_1), size = 2.2, color = "white",
                fontface = "bold") +
  labs(title = "Élévation moyenne par région — Cameroun") +
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
