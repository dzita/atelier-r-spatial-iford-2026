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
# Retry sur plusieurs miroirs Overpass : le defaut Kumi est souvent
# surcharge ou bloque par certains pare-feu. On tente l'officiel d'abord.
overpass_servers <- c(
  "https://overpass-api.de/api/interpreter",         # officiel (France)
  "https://overpass.kumi.systems/api/interpreter",   # Allemagne (defaut osmdata)
  "https://overpass.private.coffee/api/interpreter", # alternatif privacy
  "https://overpass.osm.ch/api/interpreter"          # Suisse
)

construire_requete <- function() {
  opq(bbox = bbox_cmr, timeout = 180) |>
    add_osm_features(features = list(
      "amenity" = c("hospital", "clinic", "doctors", "pharmacy"),
      "healthcare" = c("hospital", "clinic", "centre", "dispensary",
                       "doctor", "pharmacy", "yes")
    ))
}

cmr_sante <- NULL
for (srv in overpass_servers) {
  message(sprintf("[OSM] Essai serveur : %s ...", srv))
  set_overpass_url(srv)
  res <- tryCatch(osmdata_sf(construire_requete()),
                  error = function(e) e)
  if (!inherits(res, "error")) {
    cmr_sante <- res
    message(sprintf("[OSM] OK avec %s", srv))
    break
  }
  message(sprintf("  -> echec : %s", conditionMessage(res)))
  Sys.sleep(3)
}
if (is.null(cmr_sante)) {
  stop("Tous les miroirs Overpass ont echoue. Reessayer dans 5-15 minutes.")
}

# On garde uniquement les points (les polygones et lignes sont rares
# pour les facilites de sante et compliquent l'analyse statistique)
pts <- cmr_sante$osm_points
message(sprintf("[OSM] %d points retournes par Overpass.", nrow(pts)))

# Garantir l'existence des colonnes optionnelles avant le transmute
# (osmdata ne cree pas une colonne si AUCUN point n'a le tag correspondant).
cols_optionnelles <- c("name", "name.fr", "name.en", "operator",
                       "addr:city", "addr:state",
                       "healthcare", "amenity")
for (col in cols_optionnelles) {
  if (!col %in% names(pts)) pts[[col]] <- NA_character_
}

# On normalise : on garde les colonnes utiles et on garantit les noms
pts_norm <- pts |>
  st_as_sf() |>
  transmute(
    osm_id      = osm_id,
    nom         = coalesce(name, name.fr, name.en, paste0("OSM_", osm_id)),
    type        = coalesce(healthcare, amenity, "indetermine"),
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
                "doctor", "yes", "health_centre",
                "health_post", "health_facility")  ~ "Centre/Clinique",
    type %in% c("pharmacy")                        ~ "Pharmacie",
    TRUE                                            ~ "Autre"
  ))

# Aperçu des types non classifies AVANT filtrage final (audit qualite OSM)
types_autres <- out |>
  filter(categorie == "Autre") |>
  count(type, sort = TRUE) |>
  head(10)
cat("\n[OSM] Top 10 types en categorie 'Autre' (sera filtre) :\n")
print(types_autres)

# Filtrer les noeuds bruyants : on garde uniquement les vraies facilites
# de sante identifiables (les noeuds-membres de polygones et autres bruits
# tombent en categorie "Autre" et sont exclus).
n_avant_filtre <- nrow(out)
out <- out |> filter(categorie != "Autre")
message(sprintf(
  "[OSM] Filtrage qualite : %d facilites conservees sur %d points bruts (%.1f%%)",
  nrow(out), n_avant_filtre,
  100 * nrow(out) / n_avant_filtre
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
