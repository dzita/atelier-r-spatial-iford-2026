# =====================================================================
# install_packages.R
# Atelier IFORD x GDSG 2026 - Auteur : Ramesesse Dzita
# Installation des packages R necessaires pour les 10 jours de l'atelier.
#
# Fonctionne sur :
#   - Windows local (R 4.6.0 + RTools 4.5)  <- machine animateur, participants
#   - macOS local
#   - Linux (Docker rocker/geospatial)       <- fallback environnement
# =====================================================================

# ---------------------------------------------------------------------
# 1. Choix du miroir CRAN selon la plateforme
# ---------------------------------------------------------------------
if (.Platform$OS.type == "windows") {
  # Posit Public Package Manager - Windows binaires
  options(
    repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"),
    Ncpus = max(1L, parallel::detectCores() - 1L)
  )
  cat("[install_packages] Plateforme Windows detectee. Miroir PPM Windows.\n")
} else if (Sys.info()["sysname"] == "Linux") {
  # PPM Linux binaires precompiles (Ubuntu Jammy 22.04 = base rocker/geospatial)
  options(
    repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"),
    Ncpus = max(1L, parallel::detectCores() - 1L)
  )
  cat("[install_packages] Plateforme Linux detectee. Miroir PPM Linux Jammy.\n")
} else {
  # macOS et autres : CRAN standard
  options(
    repos = c(CRAN = "https://cran.rstudio.com"),
    Ncpus = max(1L, parallel::detectCores() - 1L)
  )
  cat("[install_packages] Plateforme macOS/autre detectee. CRAN standard.\n")
}

# ---------------------------------------------------------------------
# 2. Packages organises par theme pedagogique
# ---------------------------------------------------------------------

pkgs_core <- c(
  "renv",         # reproductibilite (snapshot des versions)
  "remotes",      # installation depuis GitHub
  "here",         # chemins relatifs au projet
  "fs"            # systeme de fichiers
)

pkgs_tidy <- c(
  "tidyverse",    # dplyr, tidyr, readr, ggplot2, purrr, stringr, forcats
  "lubridate",    # dates
  "janitor",      # nettoyage de noms de colonnes (clean_names)
  "skimr",        # exploration rapide (skim)
  "haven",        # lecture .dta / .sav / .sas7bdat (DHS, MICS, ECAM)
  "readxl",       # lecture Excel
  "writexl",      # ecriture Excel
  "data.table",   # performance
  "stringi"       # operations chaines avancees (translit ASCII pour clean_region)
)

pkgs_spatial_vector <- c(
  "sf",           # vecteurs (remplace sp)
  "lwgeom",       # geometries avancees (st_make_valid, etc.)
  "s2",           # geometrie spherique pour sf
  "geos",         # operations geos rapides (alternative directe)
  "rmapshaper",   # simplification topologique (preserve voisinages)
  "nngeo",        # voisinage k plus proches
  "tidygeocoder"  # geocoding (Nominatim, ARCGIS, etc.)
)

pkgs_spatial_raster <- c(
  "terra",        # rasters (remplace raster::)
  "stars",        # cubes de donnees raster/vecteur
  "exactextractr",# extraction zonale rapide
  "tidyterra",    # interface tidy pour terra (geom_spatraster pour ggplot2)
  "elevatr"       # acces SRTM / NASADEM via AWS Terrain Tiles
)

pkgs_cartography <- c(
  "tmap",         # cartographie thematique (>= v4 prefere)
  "leaflet",      # cartes interactives
  "mapview",      # exploration interactive rapide
  "ggspatial",    # echelle + fleche nord pour ggplot2 + geom_sf
  "rnaturalearth",
  "rnaturalearthdata",
  "classInt",     # classifications (jenks, fisher, quantile, etc.) - J3
  "biscale",      # cartes bivariees - J3
  "cols4all",     # palettes cartographiques v4.0+
  "scales"        # formatage des axes (label_number, etc.)
)

pkgs_spatial_stats <- c(
  "spdep",        # voisinage, Moran's I, LISA
  "spatialreg",   # regressions spatiales
  "gstat",        # geostatistique, krigeage
  "automap",      # krigeage automatique
  "spatstat"      # processus ponctuels, KDE
)

pkgs_demography_data <- c(
  # wpp2024 retire le 15 juin 2026 : indisponible sur CRAN et PPM pour R 4.6.0
  # (Warning: 'package wpp2024 is not available for this version of R')
  # Probablement en attente d'un release compatible. Reactiver si besoin :
  #   install.packages("wpp2024")  # quand dispo
  "rdhs",         # acces DHS Program API
  "srvyr",        # design d'enquete tidy (wrapper survey)
  "survey"        # plan de sondage pondere (base)
)

pkgs_remote_sensing <- c(
  # MODIStsp retire (echec frequent sur Windows + non utilise dans les demos finales)
  "httr2"         # requetes HTTP modernes (utilise par fetch_data.R)
)

pkgs_reporting <- c(
  "quarto",       # interface R vers Quarto CLI
  "rmarkdown",    # compatibilite RMarkdown
  "knitr",        # moteur de chunks
  "kableExtra",   # tables HTML/PDF
  "gt",           # tables publication (style scientifique)
  "DT",           # tables HTML interactives
  "flexdashboard",
  "shiny",        # apps web interactives
  "bslib"         # themes bootstrap
)

pkgs_modeling <- c(
  # Optionnels mais utiles pour J9 (bottom-up) et tests
  "Rcpp",         # base de l'interfacage R/C++
  "broom",        # tidy(model)
  "performance",  # qualite des modeles
  "DHARMa"        # diagnostic residuels GLM
)

pkgs_all <- unique(c(
  pkgs_core, pkgs_tidy,
  pkgs_spatial_vector, pkgs_spatial_raster, pkgs_cartography,
  pkgs_spatial_stats,
  pkgs_demography_data,
  pkgs_remote_sensing,
  pkgs_reporting,
  pkgs_modeling
))

cat(sprintf("\n[install_packages] %d packages CRAN a installer.\n\n", length(pkgs_all)))

# ---------------------------------------------------------------------
# 3a. PRE-INSTALL : raster en isole + Bioconductor deps + timeout
# ---------------------------------------------------------------------
# Raison : observation 15 juin 2026 sur Windows + R 4.6.0 :
#   - 'raster' echoue parfois lors d'une cascade automatique, ce qui
#     fait tomber tmap / exactextractr / elevatr / mapview / rnaturalearth.
#     L'installer en premier, isolement, casse cette cascade.
#   - 'performance' et 'INLA' dependent de 'Rgraphviz' et 'graph', qui
#     sont sur Bioconductor (PAS CRAN). On les installe via BiocManager.
#   - INLA telecharge un .tar.gz de 61 Mo : timeout par defaut (60s)
#     insuffisant. On l'etend a 600s.

cat("[install_packages] PRE : raster en isole...\n")
if (!requireNamespace("raster", quietly = TRUE)) {
  tryCatch(install.packages("raster", quiet = TRUE),
           error = function(e) cat("  [raster] ECHEC pre-install :", conditionMessage(e), "\n"))
}

cat("[install_packages] PRE : Bioconductor (Rgraphviz, graph)...\n")
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", quiet = TRUE)
}
tryCatch({
  if (!requireNamespace("Rgraphviz", quietly = TRUE) ||
      !requireNamespace("graph", quietly = TRUE)) {
    BiocManager::install(c("Rgraphviz", "graph"), update = FALSE, ask = FALSE, quiet = TRUE)
  }
}, error = function(e) cat("  [Bioconductor] ECHEC :", conditionMessage(e), "\n"))

# Timeout etendu pour les gros downloads (INLA, etc.)
options(timeout = max(600, getOption("timeout")))

# ---------------------------------------------------------------------
# 3b. Installation tolerante a l'echec (boucle principale)
# ---------------------------------------------------------------------
install_safe <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  [OK deja] %s\n", pkg))
    return(invisible(TRUE))
  }
  res <- tryCatch(
    {
      install.packages(pkg, dependencies = TRUE, quiet = TRUE)
      requireNamespace(pkg, quietly = TRUE)
    },
    error = function(e) FALSE,
    warning = function(w) requireNamespace(pkg, quietly = TRUE)
  )
  cat(sprintf("  [%s] %s\n", if (isTRUE(res)) "OK" else "ECHEC", pkg))
  invisible(res)
}

invisible(lapply(pkgs_all, install_safe))

# ---------------------------------------------------------------------
# 4. Packages hors CRAN (best-effort)
# ---------------------------------------------------------------------

cat("\n[install_packages] Tentative d'installation de packages hors CRAN...\n")

# 4.1 INLA (depot dedie, peut echouer en compilation sur Windows sans RTools)
tryCatch({
  if (!requireNamespace("INLA", quietly = TRUE)) {
    install.packages(
      "INLA",
      repos = c(getOption("repos"), INLA = "https://inla.r-inla-download.org/R/stable"),
      dep = TRUE
    )
    cat("  [INLA] tentative effectuee, verifier requireNamespace('INLA')\n")
  } else {
    cat("  [INLA] deja installe\n")
  }
}, error = function(e) {
  cat("  [INLA] ECHEC :", conditionMessage(e), "\n")
  cat("         -> J9 fonctionnera avec GLM frequentiste (deja prevu en fallback)\n")
})

# 4.2 wopr (WorldPop Open Population Repository) - depuis GitHub
tryCatch({
  if (!requireNamespace("wopr", quietly = TRUE)) {
    remotes::install_github("wpgp/wopr", upgrade = "never", quiet = TRUE)
    cat("  [wopr] installe depuis GitHub\n")
  } else {
    cat("  [wopr] deja installe\n")
  }
}, error = function(e) {
  cat("  [wopr] ECHEC :", conditionMessage(e), "\n")
  cat("         -> J9 utilisera donnees simulees (deja prevu en fallback)\n")
})

# 4.3 brms (bayesian regression - lourd, peut prendre 5 min)
# Decommenter si vous voulez la version bayesienne de J9
# install_safe("brms")

# ---------------------------------------------------------------------
# 5. Resume
# ---------------------------------------------------------------------
cat("\n=====================================================================\n")
cat(" Installation terminee.\n")
cat(" Lancer maintenant : source('environnement_technique/verification_setup.R')\n")
cat("=====================================================================\n")
   