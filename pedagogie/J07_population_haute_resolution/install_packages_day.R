# =====================================================================
# install_packages_day.R
# J7 - Cartographie de la population a haute resolution
# Conception pedagogique : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita (GDSG/IFORD)
# =====================================================================

pkgs_J07 <- c(
  # Recyclage J2/J3/J4 (deja installes normalement)
  "sf", "terra", "dplyr", "tidyr", "readr", "ggplot2", "tibble",
  # Recyclage J3 - statistiques zonales rapides sur gros rasters
  "exactextractr",
  # Recyclage J5 - cartographie tmap v4
  "tmap",
  # Nouveau du jour
  "scales",       # formatage des etiquettes
  "mapedit",      # edition interactive de polygones (Exercice 5)
  "leaflet"       # fond de carte pour mapedit
)

# Posit Public Package Manager : binaires pre-compiles pour R 4.6+
repo <- "https://packagemanager.posit.co/cran/latest"
options(timeout = 600)

manquants <- pkgs_J07[!pkgs_J07 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J7] Tous les packages necessaires sont deja installes.")
} else {
  message("[J7] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, repos = repo)
}

# Verifications operationnelles
checks <- c(
  terra         = "raster moderne (rast, crop, mask, global, project)",
  tmap          = "cartographie statique et interactive (v4)",
  exactextractr = "statistiques zonales rapides (sum par polygone)",
  mapedit       = "edition interactive de polygones (Exercice 5)",
  leaflet       = "fond de carte (Esri.WorldImagery, OpenStreetMap)",
  scales        = "formatage etiquettes (comma, number_format)"
)
for (pkg in names(checks)) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("[J7] %s OK : %s", pkg, checks[pkg]))
  } else {
    warning(sprintf("[J7] %s manquant : %s", pkg, checks[pkg]))
  }
}
