# =====================================================================
# J02 — Données vectorielles sf et CRS (version exécution salle)
# Atelier IFORD x GDSG · Yaoundé 28 juillet 2026 · Animateur : R. Dzita
# =====================================================================

# ---- 0. Pré-vol -----------------------------------------------------
library(here)
library(sf)
library(dplyr)
library(tibble)
library(ggplot2)

source(here("pedagogie", "_commons", "helpers", "fetch_data.R"))

# ---- 1. Lecture multi-format ----------------------------------------
adm1 <- read_sf(fetch_gadm_cameroon(1))
adm2 <- read_sf(fetch_gadm_cameroon(2))
adm3 <- read_sf(fetch_gadm_cameroon(3))

nrow(adm1)  # 10
nrow(adm2)  # ~58
nrow(adm3)  # ~365

names(adm1)
st_crs(adm1)$epsg

# ---- 2. Inspecter sans tout charger ---------------------------------
st_layers(fetch_gadm_cameroon(3))

# Filtrer dès la lecture (SQL embarqué GDAL)
litoral <- read_sf(
  fetch_gadm_cameroon(3),
  query = "SELECT * FROM gadm41_CMR_3 WHERE NAME_1 = 'Littoral'"
)
nrow(litoral)

# ---- 3. Reprojeter et comparer trois CRS ----------------------------
adm1_lambert <- st_transform(adm1, 3119)
adm1_utm32   <- st_transform(adm1, 32632)
adm1_3857    <- st_transform(adm1, 3857)

total_km2 <- function(x) sum(as.numeric(st_area(x))) / 1e6

tibble(
  CRS      = c("Lambert CMR", "UTM 32 N", "Web Mercator"),
  superficie_km2 = round(c(total_km2(adm1_lambert),
                           total_km2(adm1_utm32),
                           total_km2(adm1_3857))),
  ecart_pct = round((c(total_km2(adm1_lambert),
                       total_km2(adm1_utm32),
                       total_km2(adm1_3857)) - 475442) / 475442 * 100, 2)
)
# Lambert ~ 0%, UTM ~ 0.5%, WebMerc ~ 4%

# ---- 4. Règle d'or : filtrer en WGS 84, reprojeter pour le calcul ---
regions_nord <- adm1 |>
  filter(NAME_1 %in% c("Nord", "Adamaoua", "Extrême-Nord", "Est"))

regions_nord_utm <- st_transform(regions_nord, 32632)
regions_nord_utm$superficie_km2 <- as.numeric(st_area(regions_nord_utm)) / 1e6
regions_nord_utm |>
  st_drop_geometry() |>
  select(NAME_1, superficie_km2) |>
  arrange(desc(superficie_km2))

# ---- 5. Buffer 50 km autour de Yaoundé ------------------------------
yaounde_pt  <- st_sfc(st_point(c(11.5021, 3.8480)), crs = 4326)
yaounde_utm <- st_transform(yaounde_pt, 32632)
buffer_50km <- st_buffer(yaounde_utm, dist = 50000)
sqrt(as.numeric(st_area(buffer_50km)) / pi) / 1000  # ~ 50 km

# ---- 6. Intersection : ADM3 dans le buffer --------------------------
adm3_utm <- st_transform(adm3, 32632)
dans_buffer <- st_intersection(buffer_50km, adm3_utm)
nrow(dans_buffer)
head(dans_buffer$NAME_3, 10)

# ---- 7. Union : silhouette du Cameroun ------------------------------
cmr_silhouette <- st_union(adm1)
ggplot() +
  geom_sf(data = cmr_silhouette, fill = "grey90", color = "black", linewidth = 0.6) +
  labs(title = "Silhouette du Cameroun (st_union)") +
  theme_minimal()

# ---- 8. Dissolve : ADM3 -> ADM1 -------------------------------------
adm1_from_adm3 <- adm3 |>
  group_by(NAME_1) |>
  summarise(n_arrondissements = n(),
            geometry = st_union(geometry),
            .groups = "drop")
nrow(adm1_from_adm3)  # 10
sum(adm1_from_adm3$n_arrondissements)  # ~365

# ---- 9. Centroïdes des régions --------------------------------------
centroides_adm1 <- st_centroid(adm1)

ggplot() +
  geom_sf(data = adm1, fill = "grey95", color = "grey60") +
  geom_sf(data = centroides_adm1, color = "red", size = 2) +
  geom_sf_text(data = centroides_adm1, aes(label = NAME_1),
               nudge_y = 0.3, size = 3) +
  theme_minimal()

# ---- 10. Voronoï des chefs-lieux ------------------------------------
chefs_lieux <- tibble(
  region = c("Adamaoua","Centre","Est","Extrême-Nord","Littoral",
             "Nord","Nord-Ouest","Ouest","Sud","Sud-Ouest"),
  ville  = c("Ngaoundéré","Yaoundé","Bertoua","Maroua","Douala",
             "Garoua","Bamenda","Bafoussam","Ebolowa","Buea"),
  lon = c(13.5870, 11.5021, 13.6818, 14.3158, 9.7679,
          13.3917, 10.1591, 10.4170, 11.1500, 9.2402),
  lat = c( 7.3214,  3.8480,  4.5775, 10.5910, 4.0511,
           9.3019,  5.9597,  5.4778,  2.9000, 4.1546)
) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

chefs_pts_union <- st_union(chefs_lieux)
voronoi_box     <- st_voronoi(chefs_pts_union)
voronoi_cells   <- st_collection_extract(voronoi_box, "POLYGON") |> st_sf(crs = 4326)
voronoi_cmr     <- st_intersection(voronoi_cells, st_union(adm1))

ggplot() +
  geom_sf(data = voronoi_cmr, fill = NA, color = "grey50", linewidth = 0.4) +
  geom_sf(data = adm1, fill = NA, color = "grey80", linewidth = 0.2) +
  geom_sf(data = chefs_lieux, color = "red", size = 2.5) +
  geom_sf_text(data = chefs_lieux, aes(label = ville),
               nudge_y = 0.25, size = 2.8, fontface = "bold") +
  labs(title = "Zones d'influence des chefs-lieux régionaux") +
  theme_minimal()

# ---- 11. Validation des géométries ----------------------------------
adm3_lambert <- st_transform(adm3, 3119)
table(st_is_valid(adm3_lambert))
adm3_lambert_clean <- st_make_valid(adm3_lambert)
all(st_is_valid(adm3_lambert_clean))

# ---- 12. Export GeoPackage multi-couches ----------------------------
# out_path <- here("pedagogie","J02_sf_CRS_vecteurs","outputs","CMR_admin_lambert.gpkg")
# dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
# write_sf(st_transform(adm1, 3119), out_path, layer = "adm1", delete_dsn = TRUE)
# write_sf(st_transform(adm3, 3119), out_path, layer = "adm3", delete_layer = TRUE)
# write_sf(st_transform(voronoi_cmr, 3119), out_path, layer = "voronoi_chefs_lieux", delete_layer = TRUE)
# st_layers(out_path)

# Fin J2
