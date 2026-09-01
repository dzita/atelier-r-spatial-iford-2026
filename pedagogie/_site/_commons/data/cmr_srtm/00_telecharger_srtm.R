# =====================================================================
# 00_telecharger_srtm.R
# Atelier IFORD x GDSG 2026 - Jour 3 (Donnees raster terra)
#
# Telecharge le MNT SRTM agrege 30 arc-sec (~1 km) du Cameroun via
# geodata::elevation_30s("CMR"), crop sur l'emprise pays, et produit
# srtm_cmr_30s.tif pour la pedagogie J3 (desktop + runtime WebR).
#
# A executer UNE SEULE FOIS sur la machine de l'animateur, puis commit
# le .tif produit. Le runtime WebR le telecharge ensuite via download.file
# (les packages geodata, terra, sf en mode reseau ne sont pas portables
# sur WebR).
#
# Usage :
#   source("pedagogie/_commons/data/cmr_srtm/00_telecharger_srtm.R")
#
# Dependances :
#   install.packages(c("geodata", "terra", "sf"))
# =====================================================================

# Timeout long pour les downloads HTTPS (Windows + libcurl coupent vite)
options(timeout = 1200)

# Installation conditionnelle des dependances
.deps <- c("geodata", "terra", "sf")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[SRTM] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(geodata)
  library(terra)
  library(sf)
})

# Helper retry pour les downloads coupes
with_retry <- function(expr, n = 4, wait = 5) {
  for (i in seq_len(n)) {
    res <- tryCatch(expr, error = function(e) e)
    if (!inherits(res, "error") && !is.null(res)) return(res)
    message(sprintf("[SRTM] Tentative %d/%d echouee, retry dans %ds...",
                    i, n, wait))
    Sys.sleep(wait)
  }
  stop("Echec apres ", n, " tentatives.")
}

# Resolution de chemins independante du working directory (PowerShell
# Rscript depuis la racine OU RStudio source() depuis n'importe ou).
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)
out_dir <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "cmr_srtm")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
out_path <- file.path(out_dir, "srtm_cmr_30s.tif")

# Repertoire de cache pour geodata
cache_dir <- tempfile("geodata_cache_")
dir.create(cache_dir, recursive = TRUE)

message("[SRTM] Telechargement elevation_30s pour le Cameroun...")
elev <- with_retry(geodata::elevation_30s(country = "CMR", path = cache_dir))
message(sprintf("[SRTM] Raster brut : %d colonnes x %d lignes, res ~%.4f deg",
                ncol(elev), nrow(elev), res(elev)[1]))

# Crop strict sur l'emprise officielle du Cameroun
# (geodata renvoie deja une tuile pays, mais on assure la coherence)
bbox_cmr <- ext(8.5, 16.2, 1.7, 13.1)
elev_cmr <- crop(elev, bbox_cmr)

# Mask sur la silhouette nationale GADM
gadm0_path <- file.path("datasets", "cameroun", "admin_boundaries",
                        "gadm41_CMR_0.json")
if (file.exists(gadm0_path)) {
  message("[SRTM] Masquage sur la silhouette GADM ADM0...")
  adm0 <- vect(read_sf(gadm0_path))
  elev_cmr <- mask(elev_cmr, adm0)
}

# Renommer la couche pour clarte pedagogique
names(elev_cmr) <- "elevation_m"

# Sauvegarde GeoTIFF compresse (deflate level 9)
writeRaster(elev_cmr, out_path, overwrite = TRUE,
            datatype = "INT2S",
            gdal = c("COMPRESS=DEFLATE", "ZLEVEL=9", "PREDICTOR=2"))

# Resume
taille_ko <- round(file.size(out_path) / 1024, 1)
message(sprintf("[SRTM] GeoTIFF ecrit : %s (%s ko)", out_path, taille_ko))
message(sprintf("[SRTM] Resolution finale : ~%.4f deg (~%.0f m)",
                res(elev_cmr)[1], res(elev_cmr)[1] * 111000))
cat("\nStats elevation (m) :\n")
print(global(elev_cmr, c("min", "mean", "max"), na.rm = TRUE))

cat("\nPour publication runtime WebR : commit le fichier\n   ",
    out_path, "\n",
    "Le runtime J3 le chargera via download.file('/_commons/data/cmr_srtm/srtm_cmr_30s.tif').\n",
    sep = "")
