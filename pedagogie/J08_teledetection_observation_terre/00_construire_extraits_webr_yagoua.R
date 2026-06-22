# 00_construire_extraits_webr_yagoua.R
# -------------------------------------------------------------------------
# Atelier IFORD × GDSG · J8 — Télédétection et observation de la Terre
#
# Objet  : Construire les 3 extraits GeoJSON utilisés par `runtime.qmd` (WebR).
#          Le runtime ne peut pas mosaïquer 15 tuiles GHSL ni charger 5 CSV.gz
#          Open Buildings dans le navigateur → on prépare en amont, depuis le
#          poste formateur, des fichiers légers (EPSG:4326, polygones validés,
#          bâtiments filtrés sur la bbox d'AOI01 + buffer 1 km).
#
# Sortie : pedagogie/_commons/data/jour_08_extraits/
#           ├── aoi01_yagoua.geojson      (~ 50 ko)
#           ├── flood01_yagoua.geojson    (~ 200 ko)
#           └── batiments_yagoua.geojson  (~ 2-5 Mo, ~10 000 bâtiments)
#
# Pré-requis :
#   - Avoir exécuté `fetch_data.R::fetch_emsr772_dir()`
#   - Avoir exécuté `fetch_data.R::fetch_open_buildings_dir()`
#
# Conception : Edith Darin (GDSG/IFORD) — pipeline d'analyse
# Adaptation runtime : Ramesesse Dzita
# -------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(readr)
  library(rprojroot)
})

# -- 0. Localiser les chemins de manière reproductible ---------------------
projet_root <- rprojroot::find_root(rprojroot::has_file("README.md"))
source(file.path(projet_root, "pedagogie", "_commons", "helpers",
                 "fetch_data.R"))

dossier_sortie <- file.path(projet_root, "pedagogie", "_commons", "data",
                            "jour_08_extraits")
dir.create(dossier_sortie, recursive = TRUE, showWarnings = FALSE)

# -- 1. AOI01 (zone Yagoua) + polygones d'inondation ------------------------
message("[1/3] Construction de aoi01_yagoua.geojson et flood01_yagoua.geojson")

emsr_root <- fetch_emsr772_dir()

shp_aoi <- list.files(emsr_root,
  pattern = "AOI01.*areaOfInterestA.*\\.shp$",
  full.names = TRUE, recursive = TRUE)[1]
shp_flood <- list.files(emsr_root,
  pattern = "AOI01.*floodDepthA.*\\.shp$",
  full.names = TRUE, recursive = TRUE)[1]

stopifnot("AOI01 areaOfInterestA introuvable" = !is.na(shp_aoi))
stopifnot("AOI01 floodDepthA introuvable"     = !is.na(shp_flood))

aoi01 <- sf::st_read(shp_aoi, quiet = TRUE) |>
  sf::st_make_valid() |>
  sf::st_transform(4326)

flood01 <- sf::st_read(shp_flood, quiet = TRUE) |>
  sf::st_make_valid() |>
  sf::st_transform(4326) |>
  # on ne garde que la colonne d'intérêt (allège le GeoJSON)
  dplyr::select(value)

sf::st_write(aoi01,
             file.path(dossier_sortie, "aoi01_yagoua.geojson"),
             delete_dsn = TRUE, quiet = TRUE)
sf::st_write(flood01,
             file.path(dossier_sortie, "flood01_yagoua.geojson"),
             delete_dsn = TRUE, quiet = TRUE)

message("    AOI01    : ", round(as.numeric(sf::st_area(aoi01)) / 1e6, 1), " km²")
message("    Inondé   : ",
        round(sum(as.numeric(sf::st_area(flood01))) / 1e6, 2), " km²")
message("    Classes  : ", paste(unique(flood01$value), collapse = " | "))

# -- 2. Bâtiments Open Buildings filtrés sur la zone Yagoua ----------------
message("[2/3] Construction de batiments_yagoua.geojson")

ob_dir <- fetch_open_buildings_dir()
ob_files <- list.files(ob_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
stopifnot("Aucun CSV.gz Open Buildings trouvé" = length(ob_files) > 0)

# Bounding box d'AOI01 + buffer 1 km pour garder les bâtiments en bordure
aoi01_buffer <- aoi01 |>
  sf::st_transform(32633) |>           # UTM zone 33N pour buffer en mètres
  sf::st_buffer(dist = 1000) |>
  sf::st_transform(4326)
bbox_aoi <- sf::st_bbox(aoi01_buffer)

# Lecture incrémentale des 5 CSV.gz, filtre bbox + confiance >= 0.7
message("    Lecture des ", length(ob_files), " tuiles CSV.gz…")
batiments_raw <- purrr::map_dfr(ob_files, function(f) {
  readr::read_csv(f, show_col_types = FALSE,
                  col_select = c("latitude", "longitude", "confidence",
                                 "area_in_meters")) |>
    dplyr::filter(confidence >= 0.7,
                  longitude >= bbox_aoi["xmin"], longitude <= bbox_aoi["xmax"],
                  latitude  >= bbox_aoi["ymin"], latitude  <= bbox_aoi["ymax"])
})

message("    Bâtiments retenus (bbox + confiance >= 0.7) : ",
        format(nrow(batiments_raw), big.mark = " "))

# Conversion en sf, points centroids des bâtiments
batiments_sf <- sf::st_as_sf(batiments_raw,
                             coords = c("longitude", "latitude"),
                             crs = 4326)

# Filtre spatial final exact sur le buffer (et non plus juste la bbox)
batiments_yagoua <- sf::st_filter(batiments_sf, aoi01_buffer)

message("    Après filtre spatial exact AOI01 + 1 km : ",
        format(nrow(batiments_yagoua), big.mark = " "))

sf::st_write(batiments_yagoua,
             file.path(dossier_sortie, "batiments_yagoua.geojson"),
             delete_dsn = TRUE, quiet = TRUE)

# -- 3. Vérifier la taille des extraits ------------------------------------
message("[3/3] Vérification des tailles")
fichiers <- list.files(dossier_sortie, full.names = TRUE)
for (f in fichiers) {
  taille_ko <- round(file.info(f)$size / 1024, 1)
  message("    ", basename(f), " : ", taille_ko, " ko")
}

message("\nOK. Les extraits WebR de Yagoua sont prêts dans :")
message("  ", dossier_sortie)
message("Le runtime.qmd peut maintenant être rendu (quarto render).")
