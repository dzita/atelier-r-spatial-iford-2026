# =====================================================================
# fetch_data.R
# Atelier IFORD x GDSG 2026 - Auteur : Ramesesse Dzita
# -----
# Strategie "telechargement manuel" :
#   1. Chaque fonction fetch_*() verifie qu'un fichier local existe.
#   2. Si oui  -> retourne le chemin local.
#   3. Si non  -> stop() avec un message clair contenant :
#                 - le lien officiel pour telecharger,
#                 - le dossier exact ou placer le fichier.
#
# Avantages par rapport au telechargement automatique :
#   - Aucune dependance reseau pendant l'animation.
#   - Le participant voit explicitement quels fichiers manquent.
#   - Pas de fichier corrompu en cas d'echec SSL.
#   - Plus simple a documenter et a reproduire.
#
# Convention d'organisation des datasets :
#   datasets/<pays>/<theme>/<fichier>
#   exemples : datasets/cameroun/admin_boundaries/gadm41_CMR_0.json
#              datasets/cameroun/population_grids/CMR_pop_WorldPop_100m_2020.tif
#              datasets/cameroun/dhs_mics/CMHR71FL.DTA
#
# Utilisation type dans les demos :
#   source(here::here("pedagogie", "_commons", "helpers", "fetch_data.R"))
#   adm3 <- sf::read_sf(fetch_gadm_cameroon(level = 3))
# =====================================================================

suppressPackageStartupMessages({
  library(here)
  library(fs)
})

# Racine du dossier datasets (relatif au projet).
# On force la detection sur le .Rproj racine plutot que sur here::here(),
# qui peut etre dupe par pedagogie/_quarto.yml (utilise par le runtime WebR).
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)
.DATASETS_ROOT <- file.path(.PROJECT_ROOT, "datasets")

# Taille minimale acceptable pour un fichier reel (en octets).
# En dessous : considere corrompu / placeholder vide.
.MIN_VALID_BYTES <- 1024L  # 1 ko

# ---------------------------------------------------------------------
# Helper generique : exige un fichier local, sinon stop avec
# instructions de telechargement.
# ---------------------------------------------------------------------
require_local_file <- function(local_path, url, description, note = NULL) {
  local_path <- normalizePath(local_path, mustWork = FALSE)
  fs::dir_create(fs::path_dir(local_path))

  if (file.exists(local_path) && file.size(local_path) >= .MIN_VALID_BYTES) {
    return(local_path)
  }

  # Nettoyer un eventuel fichier vide / placeholder
  if (file.exists(local_path) && file.size(local_path) < .MIN_VALID_BYTES) {
    try(file.remove(local_path), silent = TRUE)
  }

  msg <- sprintf(
    paste0(
      "\n=================================================================\n",
      " FICHIER MANQUANT : %s\n",
      "=================================================================\n",
      " Lien officiel    : %s\n",
      " Placer le fichier dans :\n",
      "   %s\n",
      "=================================================================\n"
    ),
    description, url, local_path
  )
  if (!is.null(note)) {
    msg <- paste0(msg, " Note : ", note, "\n",
                  "=================================================================\n")
  }
  stop(msg, call. = FALSE)
}

# ---------------------------------------------------------------------
# GADM Cameroun (limites administratives ADM0-ADM3)
# Source officielle : https://gadm.org/download_country.html
# Page directe pays  : https://gadm.org/download_country.html (choisir CMR)
# Format             : 4 fichiers JSON (un par niveau)
# Licence            : libre pour usage academique, pas de redistribution
# Dossier reception  : datasets/cameroun/admin_boundaries/
# ---------------------------------------------------------------------
fetch_gadm_cameroon <- function(level = 3) {
  stopifnot(level %in% 0:3)
  local <- file.path(.DATASETS_ROOT, "cameroun", "admin_boundaries",
                     sprintf("gadm41_CMR_%d.json", level))
  url <- sprintf(
    "https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_%d.json",
    level
  )
  require_local_file(
    local_path  = local,
    url         = url,
    description = sprintf("GADM v4.1 Cameroun, niveau ADM%d (JSON)", level),
    note        = "Page de reference : https://gadm.org/download_country.html (choisir Cameroon)"
  )
}

# ---------------------------------------------------------------------
# WorldPop top-down 2020 100m unconstrained - Cameroun
# Source officielle : https://hub.worldpop.org/geodata/summary?id=49866
# Format            : GeoTIFF ~150 Mo
# Licence           : CC-BY 4.0 (Tatem 2017, Stevens et al. 2015)
# Dossier reception : datasets/cameroun/population_grids/
# ---------------------------------------------------------------------
fetch_worldpop_cmr_2020 <- function() {
  local <- file.path(.DATASETS_ROOT, "cameroun", "population_grids",
                     "CMR_pop_WorldPop_top-down_100m_2020.tif")
  url <- "https://data.worldpop.org/GIS/Population/Global_2000_2020/2020/CMR/cmr_ppp_2020.tif"
  require_local_file(
    local_path  = local,
    url         = url,
    description = "WorldPop top-down 2020 100m unconstrained (CMR)",
    note        = "~150 Mo. Page de reference : https://hub.worldpop.org/geodata/summary?id=49866"
  )
}

# ---------------------------------------------------------------------
# WorldPop top-down 2020 100m constrained (bati uniquement) - Cameroun
# Source officielle : https://hub.worldpop.org/geodata/summary?id=24784
# Format            : GeoTIFF ~30 Mo
# Licence           : CC-BY 4.0
# Dossier reception : datasets/cameroun/population_grids/
# ---------------------------------------------------------------------
fetch_worldpop_cmr_2020_constrained <- function() {
  local <- file.path(.DATASETS_ROOT, "cameroun", "population_grids",
                     "CMR_pop_WorldPop_top-down_constrained_100m_2020.tif")
  url <- "https://data.worldpop.org/GIS/Population/Global_2000_2020_Constrained/2020/maxar_v1/CMR/cmr_ppp_2020_constrained.tif"
  require_local_file(
    local_path  = local,
    url         = url,
    description = "WorldPop top-down 2020 100m constrained (CMR)",
    note        = "~30 Mo. Page de reference : https://hub.worldpop.org/geodata/summary?id=24784"
  )
}

# ---------------------------------------------------------------------
# GHS-POP 2020 100m (JRC) - Cameroun
# Source officielle : https://human-settlement.emergency.copernicus.eu/download.php?ds=pop
# Format            : GeoTIFF, tuile globale a decouper sur emprise CMR
# Licence           : CC-BY 4.0
# Dossier reception : datasets/cameroun/population_grids/
# ---------------------------------------------------------------------
fetch_ghspop_cmr_2020 <- function() {
  local <- file.path(.DATASETS_ROOT, "cameroun", "population_grids",
                     "CMR_pop_GHSL_R2023A_100m_2020.tif")
  url <- "https://human-settlement.emergency.copernicus.eu/download.php?ds=pop"
  require_local_file(
    local_path  = local,
    url         = url,
    description = "GHS-POP 2020 100m R2023A - extrait Cameroun",
    note        = paste0(
      "Telecharger GHS_POP_E2020_GLOBE_R2023A_4326_3ss (tuile globale ~3 Go OU ",
      "extrait Afrique R6), decouper sur l'emprise du Cameroun ",
      "avec gdal_translate -projwin xmin ymax xmax ymin ..."
    )
  )
}

# ---------------------------------------------------------------------
# Meta HRSL Cameroun 2018
# Source officielle : https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates
# Format            : CSV ou GeoTIFF ~50 Mo
# Licence           : CC-BY 4.0
# Dossier reception : datasets/cameroun/population_grids/
# ---------------------------------------------------------------------
fetch_meta_hrsl_cmr <- function() {
  local <- file.path(.DATASETS_ROOT, "cameroun", "population_grids",
                     "CMR_HRSL_Meta_30m_2018.tif")
  url <- "https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates"
  require_local_file(
    local_path  = local,
    url         = url,
    description = "Meta HRSL Cameroun 2018 - 30m",
    note        = paste0(
      "Si le format publie est .csv.zip : convertir en GeoTIFF avec ",
      "terra::rasterize() ou QGIS avant utilisation. ~50 Mo."
    )
  )
}

# ---------------------------------------------------------------------
# DHS Cameroun 2018 - clusters GPS anonymises (shapefile)
# Source officielle : https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm
# Format            : Shapefile (4 fichiers .shp/.shx/.dbf/.prj)
# Licence           : DHS Program (inscription + projet a soumettre 24-48h avant)
# Dossier reception : datasets/cameroun/dhs_mics/
# ---------------------------------------------------------------------
fetch_dhs_clusters_cmr_2018 <- function() {
  local <- file.path(.DATASETS_ROOT, "cameroun", "dhs_mics",
                     "CMGE71FL.shp")
  url <- "https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm"
  require_local_file(
    local_path  = local,
    url         = url,
    description = "DHS Cameroun 2018 - clusters GPS (CMGE71FL.shp)",
    note        = paste0(
      "Inscription requise sur dhsprogram.com avec soumission d'un projet ",
      "(validation 24-48h). Dezipper le fichier 'Cameroun 2018 DHS - Geographic Data' ",
      "(CMGE71FL.zip) dans le dossier reception."
    )
  )
}

# ---------------------------------------------------------------------
# DHS Cameroun 2018 - microfichiers Stata complets (recode HR/PR/IR/MR/KR/BR/CR/FW)
# Source officielle : https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm
# Format            : Stata .DTA (7 fichiers, total ~300-500 Mo)
# Licence           : DHS Program - usage formation interne IFORD/GDSG
# Emplacement reception : pedagogie/datasets/cameroun/CM_2018_DHS/
#
# Recode codes :
#   HR = Household Recode      (1 ligne par menage)
#   PR = Person Recode         (1 ligne par membre de menage)
#   IR = Individual Recode     (femmes 15-49, fertility/health)
#   MR = Men Recode            (hommes 15-59)
#   KR = Kids Recode           (enfants <5 ans, nutrition/vaccin)
#   BR = Birth Recode          (historique naissances)
#   CR = Couple Recode         (couples co-residant)
#   FW = Fieldworker data
#
# Usage :
#   hr_path  <- fetch_dhs_recode_cmr_2018("HR")
#   menages  <- haven::read_dta(hr_path)
# ---------------------------------------------------------------------
fetch_dhs_recode_cmr_2018 <- function(recode = c("HR","PR","IR","MR","KR","BR","CR","FW")) {
  recode <- match.arg(toupper(recode),
                      c("HR","PR","IR","MR","KR","BR","CR","FW"))
  rel_path <- file.path("CM_2018_DHS",
                        sprintf("CM%s71DT", recode),
                        sprintf("CM%s71FL.DTA", recode))
  # On tente 2 emplacements pour rester souple : celui mis par l'animateur
  # (pedagogie/datasets/cameroun/) ET l'emplacement canonique (datasets/cameroun/dhs_mics/).
  candidates <- c(
    file.path(.PROJECT_ROOT, "pedagogie", "datasets", "cameroun", rel_path),
    file.path(.PROJECT_ROOT, "datasets", "cameroun", "dhs_mics", rel_path)
  )
  for (p in candidates) {
    if (file.exists(p) && file.size(p) >= .MIN_VALID_BYTES) {
      return(normalizePath(p, mustWork = TRUE))
    }
  }
  stop(sprintf(
    paste0(
      "\n=================================================================\n",
      " DHS Cameroun 2018 - recode %s introuvable.\n",
      "=================================================================\n",
      " Telecharger le pack CM_2018_DHS depuis :\n",
      "   https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm\n",
      " Extraire dans :\n",
      "   pedagogie/datasets/cameroun/CM_2018_DHS/\n",
      " Le sous-dossier attendu est :\n",
      "   pedagogie/datasets/cameroun/CM_2018_DHS/CM%s71DT/CM%s71FL.DTA\n",
      "=================================================================\n"
    ),
    recode, recode, recode
  ), call. = FALSE)
}

# ---------------------------------------------------------------------
# SRTM Cameroun 30 arc-sec (~1 km) - tuile pays preparee
# Source officielle : geodata::elevation_30s("CMR") qui agrège SRTM officiel
# Format            : GeoTIFF ~3 Mo (apres crop sur emprise CMR)
# Licence           : NASA / USGS - libre
# Dossier reception : datasets/cameroun/elevation/
#
# Pipeline de bootstrap : pedagogie/_commons/data/cmr_srtm/00_telecharger_srtm.R
# (a executer UNE SEULE FOIS sur la machine de l'animateur, commit du tif).
# Le runtime WebR consomme directement le .tif via download.file sur Pages.
# ---------------------------------------------------------------------
fetch_srtm_cameroon <- function() {
  local <- file.path(.DATASETS_ROOT, "cameroun", "elevation",
                     "CMR_srtm_30s.tif")
  # Fallback : tif embarque dans pedagogie/_commons/data/cmr_srtm/
  fallback <- file.path(.PROJECT_ROOT, "pedagogie", "_commons",
                        "data", "cmr_srtm", "srtm_cmr_30s.tif")
  if (file.exists(local) && file.size(local) >= .MIN_VALID_BYTES) {
    return(local)
  }
  if (file.exists(fallback) && file.size(fallback) >= .MIN_VALID_BYTES) {
    return(fallback)
  }
  require_local_file(
    local_path  = local,
    url         = "https://geodata.ucdavis.edu/geodata/elevation/wc2.1_30s/wc2.1_30s_elev.tif",
    description = "MNT SRTM Cameroun 30 arc-sec (~1 km)",
    note        = paste0(
      "Pour generer le fichier automatiquement :\n",
      "  source('pedagogie/_commons/data/cmr_srtm/00_telecharger_srtm.R')\n",
      "Le script appelle geodata::elevation_30s('CMR') et crop sur l'emprise CMR.\n",
      "Le tif produit (~3 Mo) doit etre commit dans le repo pour le runtime WebR."
    )
  )
}

# ---------------------------------------------------------------------
# Sites pilotes RGPH4 (Bamenda 1, Fongo Tongo, Buea, Mora)
# Reconstitues par filtrage de GADM ADM3.
# ---------------------------------------------------------------------
fetch_pilot_sites_rgph4 <- function() {
  require(sf)
  adm3_path <- fetch_gadm_cameroon(level = 3)
  adm3 <- sf::read_sf(adm3_path)
  sites <- adm3[grepl("Bamenda I|Bamenda 1|Fongo[- ]?Tongo|Buea|Mora",
                      adm3$NAME_3, ignore.case = TRUE), ]
  if (nrow(sites) == 0) {
    warning("Sites pilotes non trouves dans GADM ADM3 - verifier les noms NAME_3.")
  }
  sites
}

# ---------------------------------------------------------------------
# Tableau recapitulatif des sources utilisees dans l'atelier.
# Utile pour la doc participant et le manuel animateur.
# ---------------------------------------------------------------------
list_datasets <- function() {
  data.frame(
    nom = c(
      "GADM CMR ADM0-3",
      "WorldPop 2020 100m unconstrained",
      "WorldPop 2020 100m constrained",
      "GHS-POP 2020 R2023A",
      "Meta HRSL CMR 2018",
      "DHS CMR 2018 (clusters GPS)"
    ),
    url = c(
      "https://gadm.org/download_country.html",
      "https://hub.worldpop.org/geodata/summary?id=49866",
      "https://hub.worldpop.org/geodata/summary?id=24784",
      "https://human-settlement.emergency.copernicus.eu/download.php?ds=pop",
      "https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates",
      "https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm"
    ),
    licence = c(
      "Free academic",
      "CC-BY 4.0",
      "CC-BY 4.0",
      "CC-BY 4.0",
      "CC-BY 4.0",
      "DHS Program (inscription)"
    ),
    dossier_reception = c(
      "datasets/cameroun/admin_boundaries/",
      "datasets/cameroun/population_grids/",
      "datasets/cameroun/population_grids/",
      "datasets/cameroun/population_grids/",
      "datasets/cameroun/population_grids/",
      "datasets/cameroun/dhs_mics/"
    ),
    stringsAsFactors = FALSE
  )
}