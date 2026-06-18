# =====================================================================
# install_packages_day.R
# J3 — Données raster dans R avec terra
# Packages minimaux pour suivre la journée.
# =====================================================================
#
# Convention atelier IFORD x GDSG 2026 :
#   - Chaque dossier JXX_.../ contient un install_packages_day.R
#     qui liste UNIQUEMENT les packages necessaires pour ce jour.
#   - Pour installer tout l'environnement d'un coup, lancer plutot :
#     source("environnement_technique/install_packages.R")
# =====================================================================

pkgs_J03 <- c(
  # Recyclage de J1/J2
  "here", "sf", "dplyr", "ggplot2",
  # Nouveautés de J3 — raster avec terra
  "terra",           # moteur raster moderne, successeur de raster
  "exactextractr",   # extraction zonale rapide et précise par polygone
  "tidyterra"        # interface tidyverse pour terra (optionnel mais pratique)
)

manquants <- pkgs_J03[!pkgs_J03 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J3] Tous les packages necessaires sont deja installes.")
} else {
  message("[J3] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, dependencies = TRUE)
}

# Verification fonctionnelle : terra charge bien GDAL/GEOS/PROJ
if (requireNamespace("terra", quietly = TRUE)) {
  message("[J3] terra operationnel. Version : ",
          as.character(packageVersion("terra")))
  message("[J3] Versions des libs GDAL/GEOS/PROJ embarquees :")
  print(terra::gdal(lib = "all"))
}
