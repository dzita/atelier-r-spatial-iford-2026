# =====================================================================
# J02 — Données vectorielles sf et CRS (version exécution salle)
# Atelier IFORD x GDSG · Yaoundé 28 juillet 2026 · Animateur : R. Dzita
# =====================================================================

# ---- 0. Pré-vol -----------------------------------------------------
# library() : charge un package deja installe
library(here)     # chemins portables a partir de la racine du projet
library(sf)       # "simple features" : standard pour donnees vectorielles
library(dplyr)    # verbes filter, mutate, group_by, summarise
library(tibble)   # tableaux modernes
library(ggplot2)  # cartes en couches

# source() : execute un script externe, ici pour charger fetch_gadm_cameroon()
source(here("pedagogie", "_commons", "helpers", "fetch_data.R"))

# ---- 1. Lecture multi-format ----------------------------------------
# read_sf() : lecture spatiale unifiee, format detecte par l'extension
adm1 <- read_sf(fetch_gadm_cameroon(1))   # niveau 1 = regions
adm2 <- read_sf(fetch_gadm_cameroon(2))   # niveau 2 = departements
adm3 <- read_sf(fetch_gadm_cameroon(3))   # niveau 3 = arrondissements

nrow(adm1)  # 10 regions attendues
nrow(adm2)  # ~58 departements
nrow(adm3)  # ~365 arrondissements

names(adm1)         # colonnes attributaires + geometry
st_crs(adm1)$epsg   # code EPSG du CRS courant (4326 = WGS84 attendu)

# ---- 2. Inspecter sans tout charger ---------------------------------
# st_layers() : liste les couches d'un fichier spatial sans charger les geometries
st_layers(fetch_gadm_cameroon(3))

# Filtrer dès la lecture via SQL exécuté par GDAL avant retour dans R
# Avantage : on ne charge que ce dont on a besoin (rapide sur gros fichiers)
litoral <- read_sf(
  fetch_gadm_cameroon(3),
  query = "SELECT * FROM gadm41_CMR_3 WHERE NAME_1 = 'Littoral'"
)
nrow(litoral)   # nombre d'arrondissements de la region Littoral

# ---- 3. Reprojeter et comparer trois CRS ----------------------------
# st_transform() : change le CRS (le repere), pas la donnee
# EPSG:3119 = Lambert Cameroun ; 32632 = UTM 32 N ; 3857 = Web Mercator
adm1_lambert <- st_transform(adm1, 3119)
adm1_utm32   <- st_transform(adm1, 32632)
adm1_3857    <- st_transform(adm1, 3857)

# Petite fonction : superficie totale en km2 (st_area renvoie des m2 avec unite)
total_km2 <- function(x) sum(as.numeric(st_area(x))) / 1e6

# Comparaison au chiffre officiel : 475 442 km2
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
# Le filtre est attributaire, donc independant du CRS : on le fait avant
regions_nord <- adm1 |>
  filter(NAME_1 %in% c("Nord", "Adamaoua", "Extrême-Nord", "Est"))

# Reprojection UTM seulement maintenant, pour mesurer en metres
regions_nord_utm <- st_transform(regions_nord, 32632)
regions_nord_utm$superficie_km2 <- as.numeric(st_area(regions_nord_utm)) / 1e6
# st_drop_geometry() : retire la colonne geometry pour affichage tabulaire
regions_nord_utm |>
  st_drop_geometry() |>
  select(NAME_1, superficie_km2) |>
  arrange(desc(superficie_km2))

# ---- 5. Buffer 50 km autour de Yaoundé ------------------------------
# st_point(c(lon, lat)) + st_sfc(crs = 4326) : point en WGS84 (degres)
yaounde_pt  <- st_sfc(st_point(c(11.5021, 3.8480)), crs = 4326)
# Reprojection en UTM (metres) AVANT le buffer (sinon dist non comprise)
yaounde_utm <- st_transform(yaounde_pt, 32632)
# st_buffer() : zone tampon ; dist = 50 000 m = 50 km
buffer_50km <- st_buffer(yaounde_utm, dist = 50000)
# Verification : pour un disque, sqrt(aire/pi) = rayon ; on doit lire ~50 km
sqrt(as.numeric(st_area(buffer_50km)) / pi) / 1000  # ~ 50 km

# ---- 6. Intersection : ADM3 dans le buffer --------------------------
# Memes CRS obligatoires pour intersect : on aligne adm3 sur le buffer (UTM 32 N)
adm3_utm <- st_transform(adm3, 32632)
# st_intersection() : portion d'adm3 qui tombe dans le buffer
dans_buffer <- st_intersection(buffer_50km, adm3_utm)
nrow(dans_buffer)
head(dans_buffer$NAME_3, 10)

# ---- 7. Union : silhouette du Cameroun ------------------------------
# st_union() : fusionne 10 polygones en un seul (frontiere nationale)
cmr_silhouette <- st_union(adm1)
ggplot() +
  geom_sf(data = cmr_silhouette, fill = "grey90", color = "black", linewidth = 0.6) +
  labs(title    = "Silhouette nationale du Cameroun",
       subtitle = "CRS : WGS 84 (EPSG:4326) — st_union(adm1), 10 régions fusionnées en 1",
       caption  = "Source : GADM v4.1 · IFORD × GDSG 2026") +
  theme_minimal()

# ---- 8. Dissolve : ADM3 -> ADM1 -------------------------------------
# Pattern dissolve : group_by(cle) + summarise(geometry = st_union(geometry))
adm1_from_adm3 <- adm3 |>
  group_by(NAME_1) |>
  summarise(n_arrondissements = n(),
            geometry = st_union(geometry),
            .groups = "drop")
nrow(adm1_from_adm3)  # 10
sum(adm1_from_adm3$n_arrondissements)  # ~365

# ---- 9. Centroïdes des régions --------------------------------------
# st_centroid() : centre geometrique de chaque polygone (un POINT par feature)
centroides_adm1 <- st_centroid(adm1)

ggplot() +
  geom_sf(data = adm1, fill = "grey95", color = "grey60") +
  geom_sf(data = centroides_adm1, color = "red", size = 2) +
  geom_sf_text(data = centroides_adm1, aes(label = NAME_1),
               nudge_y = 0.3, size = 3) +
  labs(title    = "Centroïdes géométriques des 10 régions du Cameroun",
       subtitle = "CRS : WGS 84 (EPSG:4326) — st_centroid() (≠ chef-lieu administratif)",
       caption  = "Source : GADM v4.1 · IFORD × GDSG 2026") +
  theme_minimal()

# ---- 10. Voronoï des chefs-lieux ------------------------------------
# Tibble manuel des 10 chefs-lieux + leurs coordonnees GPS
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
  # st_as_sf() : conversion en sf (POINT WGS84 a partir des colonnes lon/lat)
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

# Voronoi : decoupe du plan en cellules autour de chaque point
chefs_pts_union <- st_union(chefs_lieux)              # MULTIPOINT requis
voronoi_box     <- st_voronoi(chefs_pts_union)
voronoi_cells   <- st_collection_extract(voronoi_box, "POLYGON") |> st_sf(crs = 4326)
voronoi_cmr     <- st_intersection(voronoi_cells, st_union(adm1))   # decoupe sur silhouette

ggplot() +
  geom_sf(data = voronoi_cmr, fill = NA, color = "grey50", linewidth = 0.4) +
  geom_sf(data = adm1, fill = NA, color = "grey80", linewidth = 0.2) +
  geom_sf(data = chefs_lieux, color = "red", size = 2.5) +
  geom_sf_text(data = chefs_lieux, aes(label = ville),
               nudge_y = 0.25, size = 2.8, fontface = "bold") +
  labs(title    = "Zones d'influence des chefs-lieux régionaux du Cameroun",
       subtitle = "Diagramme de Voronoï (CRS : WGS 84 / EPSG:4326) découpé sur la silhouette nationale",
       caption  = "Source : GADM v4.1 · IFORD × GDSG 2026") +
  theme_minimal()

# ---- 11. Validation des géométries ----------------------------------
# Reflexe systematique apres st_transform() : verifier puis reparer
adm3_lambert <- st_transform(adm3, 3119)
table(st_is_valid(adm3_lambert))         # compte des TRUE / FALSE
adm3_lambert_clean <- st_make_valid(adm3_lambert)   # reparation GEOS
all(st_is_valid(adm3_lambert_clean))     # controle global, doit etre TRUE

# ---- 12. Export GeoPackage multi-couches ----------------------------
# out_path <- here("pedagogie","J02_sf_CRS_vecteurs","outputs","CMR_admin_lambert.gpkg")
# dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
# write_sf(st_transform(adm1, 3119), out_path, layer = "adm1", delete_dsn = TRUE)
# write_sf(st_transform(adm3, 3119), out_path, layer = "adm3", delete_layer = TRUE)
# write_sf(st_transform(voronoi_cmr, 3119), out_path, layer = "voronoi_chefs_lieux", delete_layer = TRUE)
# st_layers(out_path)

# Fin J2
