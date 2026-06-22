# =====================================================================
# 00_extraire_pop_pour_webr.R
# Atelier IFORD x GDSG 2026 - Jour 7 (Population haute resolution)
#
# Produit des extraits LEGERS des rasters WorldPop pour le runtime WebR
# (les TIF originaux pesent ~25 Mo chacun, trop lourd pour WebR).
#
# Strategie : on garde l'emprise sur la zone urbaine de Yaounde
# (departement du Mfoundi) qui est l'echelle centrale de l'atelier.
# Resultat : ~1-2 Mo par raster apres crop + compression DEFLATE.
#
# A executer UNE SEULE FOIS sur la machine de l'animateur apres avoir
# place les datasets Edith dans
# pedagogie/datasets/cameroun/jour_07_population/
# (ou en pointant vers C:/Dev/GitHub/jour_07_cartographie_*/data/).
#
# Production :
#   - pop_2015_mfoundi.tif  (~1 Mo)
#   - pop_2025_mfoundi.tif  (~1 Mo)
#   - pop_2030_mfoundi.tif  (~1 Mo)
#   - admpop_adm1_2025.csv  (copie du CSV admin pop, leger)
#   - gadm41_CMR_adm1.geojson (extrait ADM1 pour WebR, leger)
#   - gadm41_CMR_adm2_mfoundi.geojson (Mfoundi pour le focus Yaounde)
#
# Usage :
#   source("pedagogie/_commons/data/jour_07_extraits/00_extraire_pop_pour_webr.R")
#
# Dependances :
#   install.packages(c("sf", "terra", "dplyr", "readr"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 600)

.deps <- c("sf", "terra", "dplyr", "readr")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J7-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(sf)
  library(terra)
  library(dplyr)
  library(readr)
})

# Resolution de chemins independante du working directory
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

source(file.path(.PROJECT_ROOT, "pedagogie", "_commons", "helpers",
                 "fetch_data.R"))

dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "jour_07_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------------------
# 1. Charger GADM ADM1 et ADM2 (couches du GeoPackage Edith)
# ----------------------------------------------------------------------
gadm_path <- fetch_gadm_cmr_gpkg()
message("[J7-extrait] Lecture GADM ", gadm_path)

cmr1 <- st_read(gadm_path, layer = "ADM_ADM_1", quiet = TRUE)
cmr2 <- st_read(gadm_path, layer = "ADM_ADM_2", quiet = TRUE)

# Extraire Mfoundi (Yaounde)
mfoundi <- cmr2 |> filter(NAME_2 == "Mfoundi")

# Exporter les vecteurs leges en GeoJSON
st_write(cmr1, file.path(dir_out, "gadm41_CMR_adm1.geojson"),
         delete_dsn = TRUE, quiet = TRUE)
st_write(mfoundi, file.path(dir_out, "gadm41_CMR_adm2_mfoundi.geojson"),
         delete_dsn = TRUE, quiet = TRUE)

message(sprintf("[J7-extrait] GADM ADM1 : %d regions / %.0f Ko",
                nrow(cmr1),
                file.size(file.path(dir_out, "gadm41_CMR_adm1.geojson")) / 1024))
message(sprintf("[J7-extrait] Mfoundi (Yaounde) : %.0f Ko",
                file.size(file.path(dir_out, "gadm41_CMR_adm2_mfoundi.geojson")) / 1024))

# ----------------------------------------------------------------------
# 2. Crop+mask des 3 rasters WorldPop sur Mfoundi
# ----------------------------------------------------------------------
for (year in c("2015", "2025", "2030")) {
  message(sprintf("[J7-extrait] Crop WorldPop %s sur Mfoundi...", year))
  r <- rast(fetch_worldpop_constrained_cmr(year))
  mfoundi_v <- vect(st_transform(mfoundi, crs(r)))
  r_mfoundi <- mask(crop(r, mfoundi_v), mfoundi_v)
  out_path <- file.path(dir_out, sprintf("pop_%s_mfoundi.tif", year))
  writeRaster(r_mfoundi, out_path, overwrite = TRUE,
              datatype = "FLT4S",
              gdal = c("COMPRESS=DEFLATE", "ZLEVEL=9", "PREDICTOR=2"))
  message(sprintf("  -> %s (%.1f Mo, %d cellules, total = %s habitants)",
                  basename(out_path),
                  file.size(out_path) / 1024^2,
                  ncell(r_mfoundi),
                  format(round(global(r_mfoundi, "sum", na.rm = TRUE)$sum),
                         big.mark = " ")))
}

# ----------------------------------------------------------------------
# 3. Copier le CSV admpop (deja leger, juste pour servir WebR)
# ----------------------------------------------------------------------
csv_src <- fetch_admpop_adm1_cmr_2025()
csv_dst <- file.path(dir_out, "admpop_adm1_2025.csv")
file.copy(csv_src, csv_dst, overwrite = TRUE)
message(sprintf("[J7-extrait] CSV admpop : %s (%.0f Ko)",
                basename(csv_dst), file.size(csv_dst) / 1024))

# ----------------------------------------------------------------------
# 4. README extraits
# ----------------------------------------------------------------------
readme <- tibble(
  fichier = list.files(dir_out, pattern = "\\.(tif|csv|geojson)$"),
  source  = "Edith Darin (workshop_material/jour_07/data) - extraits Mfoundi",
  usage   = "Runtime WebR J7 (chargement via download.file relatif)"
)
write_csv(readme, file.path(dir_out, "extraits_README.csv"))

cat("\n========================================================\n")
cat(" Extraction WorldPop pour WebR J7 terminee.\n")
cat("========================================================\n")
cat(" Fichiers dans :\n")
cat("  ", normalizePath(dir_out), "\n\n")
print(readme)
