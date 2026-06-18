# =====================================================================
# install_packages_day.R
# J2 — Données vectorielles sf et CRS
# Packages minimaux pour suivre la journée.
# =====================================================================
#
# Convention atelier IFORD x GDSG 2026 :
#   - Chaque dossier JXX_.../ contient un install_packages_day.R
#     qui liste UNIQUEMENT les packages necessaires pour ce jour.
#   - Pour installer tout l'environnement d'un coup, lancer plutot :
#     source("environnement_technique/install_packages.R")
# =====================================================================

pkgs_J02 <- c(
  # Recyclage de J1
  "here", "fs", "tibble", "dplyr", "tidyr", "sf", "ggplot2",
  # Nouveautés de J2 — opérations vectorielles avancées
  "lwgeom",         # opérations géométriques étendues (Voronoï, sphère)
  "rmapshaper",     # simplification de géométries (Visvalingam, etc.)
  "s2"              # géométrie sphérique (utilisé en interne par sf)
)

manquants <- pkgs_J02[!pkgs_J02 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J2] Tous les packages necessaires sont deja installes.")
} else {
  message("[J2] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, dependencies = TRUE)
}

# Verification fonctionnelle : sf charge bien GDAL/GEOS/PROJ + lwgeom OK
if (requireNamespace("sf", quietly = TRUE) &&
    requireNamespace("lwgeom", quietly = TRUE)) {
  message("[J2] sf + lwgeom operationnels. Versions des libs systeme :")
  print(sf::sf_extSoftVersion())
}
