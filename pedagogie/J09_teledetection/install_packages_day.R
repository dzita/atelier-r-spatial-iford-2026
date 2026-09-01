## ============================================================================
## J09 -- Voir le territoire depuis l'espace : teledetection, bati, inondations
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026 -- genere depuis demo_formateur_J09.qmd
## ============================================================================

## Liste alignee, un pour un, sur les library() REELLEMENT appeles par
## demo_formateur_J09.qmd. Rien de plus.
##
## Le surdimensionnement de cette liste coute cher : sur les journees
## precedentes, on comptait 24 paquets declares pour 13 utilises (J02),
## 14 pour 10 (J04), 14 pour 9 (J05) -- soit plusieurs dizaines de minutes
## d'installation en salle pour des paquets jamais charges.

pkgs_j09 <- c(
  "sf",             # donnees vectorielles : lecture, CRS, predicats spatiaux
  "dplyr",          # verbes de manipulation de tableaux
  "ggplot2",        # graphiques et cartes statiques (geom_sf)
  "tidyr",          # pivot_longer / pivot_wider
  "readr",          # lecture / ecriture de CSV
  "terra",          # rasters : rast, mosaic, crop, mask, global
  "exactextractr",  # statistiques zonales ponderees par fraction de cellule
  "tmap",           # cartographie thematique -- VERSION 4 requise
  "osmdata"         # interrogation de l'API Overpass d'OpenStreetMap
)

## ----------------------------------------------------------------------------
## PAQUETS ECARTES, et a quelle journee ils appartiennent
## ----------------------------------------------------------------------------
## here          : le materiel source l'utilisait pour construire ses chemins.
##                 L'atelier travaille en chemins relatifs au dossier du jour
##                 ("datasets/", "outputs/"), detectes par l'outil de
##                 distribution des donnees. here() casserait cette detection.
##                 Ecarte de TOUTES les journees.
## tidyverse     : meta-paquet. On charge les cinq composants reellement
##                 utilises plutot que la vingtaine qu'il tire.
## raster        : ancetre de terra, du meme auteur ; il masque des dizaines de
##                 fonctions de terra portant le meme nom (extract, crop,
##                 area...) et l'on ne sait plus laquelle on appelle. Ecarte
##                 depuis le J04.
## mapview,
## leaflet       : widgets interactifs. Ils embarquent les geometries dans le
##                 HTML produit (un document du projet est monte a 17 Mo pour
##                 cette raison). Le J09 n'en charge aucun ; les cartes
##                 interactives sont en blocs eval:false dans le .qmd.
## haven, readxl : lecture SPSS / Excel. Aucune donnee d'enquete ce jour.
##                 -> J05 (EDS, ECAM5) et J08 (xlsx WorldPop).
## classInt,
## RColorBrewer,
## viridis       : discretisation et palettes. ggplot2 fournit ici
##                 scale_fill_viridis_c(), scale_fill_gradient2() et
##                 scale_fill_brewer() sans dependance supplementaire.
##                 classInt reste utile pour l'EXERCICE 3 du J09 (comparer
##                 quantiles / intervalles egaux / Jenks) : l'installer alors
##                 a la demande, il n'est pas requis pour le rendu.
## scales        : formatage d'axes. -> J08 et J10.
## mapedit       : trace d'une zone a la souris. -> J08.
## sae, survey   : estimation en petits domaines. -> J10.
## rgee          : Google Earth Engine. Renvoye au J10 ; installation lourde
##                 (environnement Python + authentification OAuth) qui n'est
##                 pas realisable en salle.
## ----------------------------------------------------------------------------

a_installer <- pkgs_j09[!pkgs_j09 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  install.packages(a_installer)
} else {
  message("Tous les packages du J09 sont deja installes.")
}

## Verification : tout doit se charger sans erreur
invisible(lapply(pkgs_j09, function(p) {
  ok <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))

## ----------------------------------------------------------------------------
## Controles de version
## ----------------------------------------------------------------------------

## tmap >= 4 : l'API a change en profondeur entre la version 3 et la version 4.
## Le materiel du J09 ecrit tm_raster(col.scale = tm_scale_intervals(...)) et
## tm_polygons(fill = ..., fill.scale = tm_scale_categorical(...)). En tmap 3,
## ces arguments n'existent pas et les cartes echouent.
v_tmap <- tryCatch(packageVersion("tmap"), error = function(e) NULL)
if (!is.null(v_tmap)) {
  message("\ntmap installe : version ", v_tmap)
  if (v_tmap < "4.0.0")
    warning("tmap ", v_tmap, " detecte : le materiel du J09 suit l'API tmap >= 4.0.0. ",
            "Mettre a jour avant la seance (install.packages('tmap')).")
}

## terra >= 1.7 : SpatRaster, terraOptions, mosaic sur liste, global().
v_terra <- tryCatch(packageVersion("terra"), error = function(e) NULL)
if (!is.null(v_terra)) {
  message("terra installe : version ", v_terra)
  if (v_terra < "1.7.0")
    warning("terra ", v_terra, " detecte : le materiel du J09 exige terra >= 1.7.0.")
}

## sf >= 1.0 : sf_use_s2() et st_make_valid() y sont disponibles.
v_sf <- tryCatch(packageVersion("sf"), error = function(e) NULL)
if (!is.null(v_sf)) {
  message("sf installe : version ", v_sf)
  if (v_sf < "1.0.0")
    warning("sf ", v_sf, " detecte : sf_use_s2() exige sf >= 1.0.0.")
}

## osmdata : le module 8 interroge l'API publique Overpass. Elle peut etre
## indisponible en seance ; le .qmd bascule alors automatiquement sur la copie
## locale datasets/routes_aoi01_yagoua.gpkg. Verifier sa presence AVANT la
## seance vaut mieux que decouvrir l'indisponibilite devant les participants.
if (dir.exists("datasets")) {
  message("\nCopie locale OSM de secours presente : ",
          file.exists(file.path("datasets", "routes_aoi01_yagoua.gpkg")))
}
