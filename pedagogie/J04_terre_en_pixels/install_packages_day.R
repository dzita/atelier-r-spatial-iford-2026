## ============================================================================
## J04 — La Terre en pixels : les donnees d'observation continue
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026 -- genere depuis script_formateur_J04.R
## ============================================================================

## Liste alignee sur les library() REELLEMENT utilises par la journee.
##
## NOTE : le paquet 'raster' a ete RETIRE. C'est l'ancetre de 'terra', du meme
## auteur ; il masque des dizaines de fonctions de terra portant le meme nom
## (extract, crop, area...) et l'on ne sait plus laquelle on appelle.
## exactextractr accepte directement les SpatRaster : la conversion vers
## l'ancien format n'a plus lieu d'etre.

pkgs_j04 <- c(
  "terra",          # LE package raster moderne
  "sf",             # donnees vectorielles
  "tidyverse",      # dplyr, ggplot2, readr, stringr...
  "readxl",         # lecture des .xlsx WorldPop
  "haven",          # lecture SPSS (.sav) -- donnees EDS
  "exactextractr",  # statistiques zonales precises sur les bords
  "classInt",       # discretisation (Jenks, quantiles...)
  "RColorBrewer",   # palettes cartographiques
  "viridis",        # palettes perceptuellement uniformes
  "tmap"            # cartographie thematique -- VERSION 4 requise
)

a_installer <- pkgs_j04[!pkgs_j04 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  install.packages(a_installer)
} else {
  message("Tous les packages du J04 sont deja installes.")
}

# Verification : tout doit se charger sans erreur
invisible(lapply(pkgs_j04, function(p) {
  ok <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))

## terra >= 1.7 est requis (SpatRaster, terraOptions, classify).
v_terra <- tryCatch(packageVersion("terra"), error = function(e) NULL)
if (!is.null(v_terra)) {
  message("\nterra installe : version ", v_terra)
  if (v_terra < "1.7.0")
    warning("terra ", v_terra, " detecte : le materiel du J04 exige terra >= 1.7.0.")
}

## Le squelette tmap de la section 5 suit l'API tmap 4.
v_tmap <- tryCatch(packageVersion("tmap"), error = function(e) NULL)
if (!is.null(v_tmap) && v_tmap < "4.0.0")
  warning("tmap ", v_tmap, " detecte : le materiel suit l'API tmap >= 4.0.0.")
