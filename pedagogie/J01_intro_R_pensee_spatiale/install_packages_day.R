# =====================================================================
# install_packages_day.R
# J1 — Introduction R + pensée spatiale
# Packages minimaux pour suivre la journée.
# =====================================================================
#
# Convention atelier IFORD x GDSG 2026 :
#   - Chaque dossier JXX_.../ contient un install_packages_day.R
#     qui liste UNIQUEMENT les packages necessaires pour ce jour.
#   - Pour installer tout l'environnement d'un coup, lancer plutot :
#     source("environnement_technique/install_packages.R")
# =====================================================================

pkgs_J01 <- c(
  # R essentials + tidyverse
  "here", "fs", "tibble", "dplyr", "tidyr", "readr", "ggplot2",
  "stringr", "janitor", "skimr", "haven",
  # Spatial vectoriel
  "sf",
  # Cartographie
  "tmap", "rnaturalearth", "rnaturalearthdata"
)

manquants <- pkgs_J01[!pkgs_J01 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J1] Tous les packages necessaires sont deja installes.")
} else {
  message("[J1] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, dependencies = TRUE)
}

# Verification fonctionnelle minimale : sf charge bien GDAL/GEOS/PROJ
if (requireNamespace("sf", quietly = TRUE)) {
  message("[J1] sf operationnel. Versions des libs systeme :")
  print(sf::sf_extSoftVersion())
}
