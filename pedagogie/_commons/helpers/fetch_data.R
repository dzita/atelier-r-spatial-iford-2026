# =====================================================================
# fetch_data.R
# Atelier IFORD x GDSG 2026 - Helpers de telechargement avec fallback
# Auteur : Ramesesse Dzita
# -----
# Strategie : chaque fonction `fetch_*` tente d'abord de telecharger
# depuis la source officielle ; si le wifi de l'IFORD est instable ou
# que le serveur ne repond pas, elle bascule automatiquement sur le
# fichier local pre-telecharge dans 02_DATASETS_CAMEROUN/.
#
# Utilisation type dans les demos :
#   source(here::here("01_PEDAGOGIE/demos/_helpers/fetch_data.R"))
#   adm3 <- fetch_gadm_cameroon(level = 3)
# =====================================================================

suppressPackageStartupMessages({
  library(here)
  library(fs)
  library(httr2)
})

# Racine du dossier datasets (relatif au projet)
.DATASETS_ROOT <- here::here("02_DATASETS_CAMEROUN")

# ---------------------------------------------------------------------
# Utilitaire generique : telecharge si necessaire, sinon retourne le
# chemin local.
# ---------------------------------------------------------------------
download_if_missing <- function(url, dest_path, timeout = 60, force = FALSE) {
  dest_path <- normalizePath(dest_path, mustWork = FALSE)
  fs::dir_create(fs::path_dir(dest_path))

  if (file.exists(dest_path) && !force) {
    message(sprintf("[fetch_data] Fichier deja present : %s", dest_path))
    return(dest_path)
  }

  message(sprintf("[fetch_data] Telechargement : %s", url))
  ok <- tryCatch({
    req <- httr2::request(url) |>
      httr2::req_timeout(timeout) |>
      httr2::req_user_agent("IFORD-GDSG-Workshop-2026 (ramondzita@gmail.com)")
    resp <- httr2::req_perform(req, path = dest_path)
    !httr2::resp_is_error(resp)
  }, error = function(e) {
    message(sprintf("[fetch_data] ECHEC : %s", conditionMessage(e)))
    FALSE
  })

  if (!ok) {
    if (file.exists(dest_path)) {
      message("[fetch_data] Telechargement KO mais fichier local trouve - on l'utilise.")
      return(dest_path)
    }
    stop(sprintf(
      "Impossible de telecharger ni de trouver localement : %s\n  -> Telecharger manuellement et placer dans %s",
      url, dest_path
    ))
  }
  dest_path
}

# ---------------------------------------------------------------------
# GADM Cameroun (limites administratives)
# Source officielle : https://gadm.org/download_country.html
# Licence : libre pour usage academique, pas de redistribution commerciale
# ---------------------------------------------------------------------
fetch_gadm_cameroon <- function(level = 3, force = FALSE) {
  stopifnot(level %in% 0:3)
  url <- sprintf(
    "https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_%d.json",
    level
  )
  dest <- file.path(.DATASETS_ROOT, "admin_boundaries",
                    sprintf("gadm41_CMR_%d.json", level))
  download_if_missing(url, dest, force = force)
}

# ---------------------------------------------------------------------
# WorldPop top-down population 2020 100m unconstrained (Cameroun)
# Source : https://hub.worldpop.org/geodata/summary?id=49866
# Licence : CC-BY 4.0 (Tatem 2017, Stevens et al. 2015)
# ATTENTION : ~150 Mo
# ---------------------------------------------------------------------
fetch_worldpop_cmr_2020 <- function(force = FALSE) {
  url <- "https://data.worldpop.org/GIS/Population/Global_2000_2020/2020/CMR/cmr_ppp_2020.tif"
  dest <- file.path(.DATASETS_ROOT, "population_grids",
                    "CMR_pop_WorldPop_top-down_100m_2020.tif")
  download_if_missing(url, dest, timeout = 600, force = force)
}

# WorldPop constrained 2020 (bati uniquement) - utile en J8 pour comparer
fetch_worldpop_cmr_2020_constrained <- function(force = FALSE) {
  url <- "https://data.worldpop.org/GIS/Population/Global_2000_2020_Constrained/2020/maxar_v1/CMR/cmr_ppp_2020_constrained.tif"
  dest <- file.path(.DATASETS_ROOT, "population_grids",
                    "CMR_pop_WorldPop_top-down_constrained_100m_2020.tif")
  download_if_missing(url, dest, timeout = 600, force = force)
}

# ---------------------------------------------------------------------
# GHS-POP 2020 100m (JRC) - top-down concurrent de WorldPop
# Source : https://human-settlement.emergency.copernicus.eu/download.php?ds=pop
# Licence : CC-BY 4.0
# Note : on telecharge la tuile globale 100m (~zip large) ou un extrait CMR
# Pour l'atelier on s'attend a un extrait CMR pre-decoupe dans 02_DATASETS/
# ---------------------------------------------------------------------
fetch_ghspop_cmr_2020 <- function() {
  local <- file.path(.DATASETS_ROOT, "population_grids",
                     "CMR_pop_GHSL_R2023A_100m_2020.tif")
  if (!file.exists(local)) {
    stop(
      "GHS-POP doit etre pre-telecharge (tuile globale trop volumineuse).\n",
      "  1) https://human-settlement.emergency.copernicus.eu/download.php?ds=pop\n",
      "  2) Choisir GHS_POP_E2020_GLOBE_R2023A_4326_3ss (ou la tuile R6 Afrique)\n",
      "  3) Decouper sur l'emprise du Cameroun et placer en : ", local
    )
  }
  local
}

# ---------------------------------------------------------------------
# Meta HRSL Cameroun
# Source : https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates
# Licence : CC-BY 4.0
# ---------------------------------------------------------------------
fetch_meta_hrsl_cmr <- function(force = FALSE) {
  url <- "https://data.humdata.org/dataset/c9d22555-a78f-4ec3-8a6c-7c5a8de46b9e/resource/4d3c20f7-fb16-4f4f-9c0c-c33da7a4b8f0/download/population_cmr_2018-10-01.csv.zip"
  dest <- file.path(.DATASETS_ROOT, "population_grids",
                    "CMR_HRSL_Meta_30m_2018.csv.zip")
  out <- tryCatch(
    download_if_missing(url, dest, timeout = 600, force = force),
    error = function(e) {
      message("[fetch_data] HRSL : URL HDX possiblement obsolete. Verifier :")
      message("  https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates")
      NA_character_
    }
  )
  out
}

# ---------------------------------------------------------------------
# Sites pilotes RGPH4 (Bamenda 1, Fongo Tongo, Buea, Mora) - emprises
# Reconstruites par filtrage de GADM ADM3
# ---------------------------------------------------------------------
fetch_pilot_sites_rgph4 <- function() {
  require(sf)
  adm3_path <- fetch_gadm_cameroon(level = 3)
  adm3 <- sf::read_sf(adm3_path)
  # Les noms exacts dans GADM peuvent varier (accents, casse).
  sites <- adm3[grepl("Bamenda I|Bamenda 1|Fongo[- ]?Tongo|Buea|Mora",
                      adm3$NAME_3, ignore.case = TRUE), ]
  if (nrow(sites) == 0) {
    warning("Sites pilotes non trouves dans GADM ADM3 - verifier les noms NAME_3.")
  }
  sites
}

# ---------------------------------------------------------------------
# SRTM 1 arc-second sur emprise (via package elevatr)
# ---------------------------------------------------------------------
fetch_srtm <- function(aoi_sf, zoom = 9) {
  if (!requireNamespace("elevatr", quietly = TRUE)) {
    stop("Package elevatr requis : install.packages('elevatr')")
  }
  elevatr::get_elev_raster(locations = aoi_sf, z = zoom, clip = "locations")
}

# ---------------------------------------------------------------------
# DHS Cameroun 2018 - clusters GPS anonymises
# ATTENTION : DHS requiert une inscription prealable + autorisation
# de projet. On NE PEUT PAS telecharger en clair.
# ---------------------------------------------------------------------
fetch_dhs_clusters_cmr_2018 <- function() {
  local <- file.path(.DATASETS_ROOT, "DHS_MICS",
                     "CMGE71FL.shp")  # convention DHS GPS shapefile
  if (!file.exists(local)) {
    stop(
      "Clusters DHS Cameroun 2018 absents.\n",
      "  1) Creer un compte sur https://dhsprogram.com/data/dataset_admin/login_main.cfm\n",
      "  2) Soumettre un projet (gratuit, validation sous 24-48h)\n",
      "  3) Telecharger 'Cameroun 2018 DHS - Geographic Data' (CMGE71FL.zip)\n",
      "  4) Dezipper dans : ", dirname(local)
    )
  }
  local
}

# ---------------------------------------------------------------------
# Tableau recapitulatif des sources utilisees dans l'atelier
# ---------------------------------------------------------------------
list_datasets <- function() {
  data.frame(
    nom = c("GADM CMR ADM0-3", "WorldPop 2020 100m", "WorldPop 2020 constrained",
            "GHS-POP 2020 R2023A", "Meta HRSL CMR 2018", "DHS CMR 2018",
            "SRTM 30m"),
    url = c("https://gadm.org/download_country.html",
            "https://hub.worldpop.org/geodata/summary?id=49866",
            "https://hub.worldpop.org/geodata/summary?id=24784",
            "https://human-settlement.emergency.copernicus.eu/download.php?ds=pop",
            "https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates",
            "https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm",
            "via package elevatr (AWS Terrain Tiles)"),
    licence = c("Free academic", "CC-BY 4.0", "CC-BY 4.0",
                "CC-BY 4.0", "CC-BY 4.0", "DHS Program (inscription)",
                "Public domain"),
    stringsAsFactors = FALSE
  )
}
