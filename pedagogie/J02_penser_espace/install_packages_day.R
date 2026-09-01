## ============================================================================
## J02 — Penser l'espace : où, et pourquoi là ?
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026 -- genere depuis script_formateur_J02.R
## ============================================================================

## Liste alignee sur les library() REELLEMENT utilises par la journee.
## Les paquets d'analyse spatiale avancee (spdep, spatialreg, gstat, automap,
## exactextractr, stars, tidyterra) relevent des journees J07 et suivantes :
## ils sont installes par le install_packages_day.R de ces journees-la.
## Les inclure ici allongeait l'installation de plusieurs dizaines de minutes
## en salle, pour des paquets jamais charges au J02.

pkgs_j02 <- c(
  "tidyverse",   # dplyr, ggplot2, tidyr, readr, tibble...
  "haven",       # lire les fichiers SPSS (.sav) -- donnees EDS/DHS
  "janitor",     # clean_names() et nettoyage de tableaux
  "skimr",       # resumes statistiques rapides
  "gt",          # tableaux de presentation
  "patchwork",   # composer plusieurs graphiques ggplot2
  "sf",          # donnees vectorielles (Simple Features)
  "terra",       # rasters : images satellite
  "tmap",        # cartographie thematique -- VERSION 4 requise
  "leaflet",     # necessaire au mode interactif tmap_mode("view")
  "ggrepel"      # etiquettes non chevauchantes (section 4.3)
)

a_installer <- pkgs_j02[!pkgs_j02 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  install.packages(a_installer)
} else {
  message("Tous les packages du J02 sont deja installes.")
}

# Verification : tout doit se charger sans erreur
invisible(lapply(pkgs_j02, function(p) {
  ok <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))

## Le materiel de cette journee utilise l'API tmap 4 (tm_scalebar(), fill =,
## tm_scale_intervals(), tm_title()). Avec tmap 3, les blocs cartographiques
## echoueront.
v_tmap <- tryCatch(packageVersion("tmap"), error = function(e) NULL)
if (!is.null(v_tmap)) {
  message("\ntmap installe : version ", v_tmap)
  if (v_tmap < "4.0.0")
    warning("tmap ", v_tmap, " detecte : le materiel du J02 exige tmap >= 4.0.0. ",
            "Lancez install.packages(\"tmap\") pour mettre a jour.")
}
