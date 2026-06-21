# =====================================================================
# 00_telecharger_osm_sante.R
# Atelier IFORD x GDSG 2026 — Jour 6 (Statistiques spatiales)
#
# Télécharge depuis OpenStreetMap les établissements de santé du
# Cameroun et produit etablissements_sante_osm.csv pour le matériel
# pédagogique de J6.
#
# A executer UNE SEULE FOIS sur la machine de l'animateur, puis commit
# le CSV produit. Le runtime WebR utilise directement le CSV (osmdata
# n'est pas portable sur WebR).
#
# Usage :
#   source("pedagogie/_commons/data/cmr_sante/00_telecharger_osm_sante.R")
#
# Dependances :
#   install.packages(c("osmdata", "sf", "dplyr", "readr"))
# =====================================================================

# Timeout long pour les downloads HTTPS (Windows + libcurl coupent vite)
options(timeout = 1200)

# Installation conditionnelle des dependances
.deps <- c("osmdata", "sf", "dplyr", "readr")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[OSM] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(osmdata)
  library(sf)
  library(dplyr)
  library(readr)
})

# Resolution de chemins independante du working directory
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

# Emprise officielle du Cameroun (longitude / latitude)
bbox_cmr <- c(8.5, 1.7, 16.2, 13.1)

# Requete Overpass : amenity = hospital / clinic / doctors / pharmacy
# + healthcare = * (pour les noeuds OSM modernes)
message("[OSM] Requete Overpass pour les facilites de sante du Cameroun...")
message("      (peut prendre 30 a 60 secondes selon Overpass)")

cmr_sante <- opq(bbox = bbox_cmr, timeout = 120) |>
  add_osm_features(features = list(
    "amenity" = c("hospital", "clinic", "doctors", "pharmacy"),
    "healthcare" = c("hospital", "clinic", "centre", "dispensary",
                     "doctor", "pharmacy", "yes")
  )) |>
  osmdata_sf()

# On garde uniquement les points (les polygones et lignes sont rares
# pour les facilites de sante et compliquent l'analyse statistique)
pts <- cmr_sante$osm_points
message(sprintf("[OSM] %d points retournes par Overpass.", nrow(pts)))

# On normalise : on garde les colonnes utiles et on garantit les noms
pts_norm <- pts |>
  st_as_sf() |>
  transmute(
    osm_id      = osm_id,
    nom         = coalesce(name, name.fr, name.en, paste0("OSM_", osm_id)),
    type        = coalesce(
      healthcare,
      amenity,
      "indetermine"
    ),
    operateur   = operator,
    ville       = `addr:city`,
    region_osm  = `addr:state`,
    geometry    = geometry
  ) |>
  filter(!st_is_empty(geometry))

# Filtrer en gardant les facilites a l'interieur de l'emprise stricte
# (Overpass peut retourner des points juste hors bbox a cause de l'index)
emprise_cmr <- st_polygon(list(matrix(
  c(bbox_cmr[1], bbox_cmr[2],
    bbox_cmr[3], bbox_cmr[2],
    bbox_cmr[3], bbox_cmr[4],
    bbox_cmr[1], bbox_cmr[4],
    bbox_cmr[1], bbox_cmr[2]),
  ncol = 2, byrow = TRUE
))) |> st_sfc(crs = 4326)

pts_norm <- pts_norm |> filter(lengths(st_within(geometry, emprise_cmr)) > 0)
message(sprintf("[OSM] %d points conserves apres filtre emprise.",
                nrow(pts_norm)))

# Extraction des coordonnees pour export CSV
coords <- st_coordinates(pts_norm)
out <- pts_norm |>
  st_drop_geometry() |>
  mutate(longitude = round(coords[, 1], 5),
         latitude  = round(coords[, 2], 5)) |>
  filter(!is.na(longitude), !is.na(latitude))

# Categorie simplifiee pour l'analyse
# (basee uniquement sur les tags OSM reels, aucune simulation)
out <- out |>
  mutate(categorie = case_when(
    type %in% c("hospital")                        ~ "Hopital",
    type %in% c("clinic", "centre", "dispensary",
                "centre de sante", "doctors",
                "doctor")                          ~ "Centre/Clinique",
    type %in% c("pharmacy")                        ~ "Pharmacie",
    TRUE                                            ~ "Autre"
  ))

# Note pedagogique J6 : OSM ne renseigne pas le nombre de consultations
# ni le personnel de chaque facilite. Pour la statistique spatiale (Moran,
# LISA), on ne fabrique PAS de variable simulee. A la place, J6 agrege
# les facilites par departement ADM2 (count) et fait les analyses sur
# cette variable derivee de comptage, qui reste 100% reelle.

# Sauvegarde
out_path <- file.path(.PROJECT_ROOT,
                      "pedagogie", "_commons", "data", "cmr_sante",
                      "etablissements_sante_osm.csv")
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write_csv(out, out_path)
message(sprintf("[OSM] CSV ecrit : %s (%d lignes)",
                out_path, nrow(out)))

# Resume rapide
cat("\nResume par categorie :\n")
print(table(out$categorie))

cat("\nPremieres lignes :\n")
print(head(out, 5))
