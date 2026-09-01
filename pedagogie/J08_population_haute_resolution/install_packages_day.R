## ============================================================================
## J08 -- Compter chaque habitant : la grille de population
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026
## ============================================================================

## Liste alignee sur les library() REELLEMENT charges par demo_formateur_J08.qmd
## et par les trois scripts de scripts/. Rien de plus.
##
## Paquets volontairement ECARTES, et a quelle journee ils appartiennent :
##   haven, janitor, naniar, srvyr, survey ...... J05 (enquetes ponderees)
##   stringi, ggrepel ........................... J05 (cles de jointure, etiquettes)
##   spdep, gstat, automap ...................... J06/J07 (autocorrelation,
##                                                 interpolation) -- AUCUN n'est
##                                                 charge au J08
##   osmdata .................................... J09 (routes OSM, Overpass)
##   tidyterra .................................. J09 (rasters dans ggplot2)
##   sae, ranger, Metrics, caret ................ J10 (Fay-Herriot, foret
##                                                 aleatoire, RMSE/MAE). Le
##                                                 module 8 du J08 cite ranger
##                                                 et Metrics, mais UNIQUEMENT
##                                                 dans un bloc eval: false --
##                                                 aucun appel n'est execute.
##   mapview, leafsync .......................... jamais : widgets interactifs,
##                                                 interdits dans un document
##                                                 distribue (regle 6.6)
## Les inclure ici allongerait l'installation de plusieurs dizaines de minutes
## en salle, pour des paquets jamais charges au J08.

pkgs_j08 <- c(
  "sf",             # vecteurs Simple Features : GeoPackage GADM, reprojections
  "terra",          # rasters : rast, crop, mask, global, sprc, mosaic, project
  "exactextractr",  # statistiques zonales ponderees par fraction de cellule
  "dplyr",          # filter, mutate, left_join, arrange
  "tidyr",          # pivot_longer (structure par age, comparaison de sources)
  "readr",          # read_csv / write_csv
  "ggplot2",        # choropletes geom_sf, barres, series temporelles
  "tmap",           # cartographie thematique raster -- VERSION 4 requise
  "scales"          # label_comma, label_number, echelle log
)

## Paquets OPTIONNELS : utilises uniquement par le module 9, dans un bloc
## eval: false (mapedit::editMap est interactif -- il attend qu'un humain
## dessine un polygone, donc il ne peut pas s'executer au rendu Quarto).
## Le document reste rendable sans eux ; ne les installer que si l'on veut
## faire l'atelier de dessin en direct en salle.
pkgs_j08_optionnels <- c(
  "mapedit",        # editMap() : dessiner une zone a la main
  "leaflet"         # fond de carte de editMap()
)

a_installer <- pkgs_j08[!pkgs_j08 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  install.packages(a_installer)
} else {
  message("Tous les packages obligatoires du J08 sont deja installes.")
}

## Verification : tout doit se charger sans erreur
invisible(lapply(pkgs_j08, function(p) {
  ok <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))

## Optionnels : on signale seulement, on n'installe pas d'office.
message("\nPaquets optionnels (module 9 interactif uniquement) :")
invisible(lapply(pkgs_j08_optionnels, function(p) {
  ok <- p %in% rownames(installed.packages())
  message(ifelse(ok, "OK      : ", "ABSENT  : "), p,
          if (!ok) "  -- install.packages(\"" else "",
          if (!ok) p else "", if (!ok) "\") pour l'atelier en direct" else "")
}))

## ---------------------------------------------------------------------------
## CONTROLE DE VERSION : tmap >= 4.0.0
## ---------------------------------------------------------------------------
## Le materiel du J08 utilise l'API tmap 4 :
##   tm_raster(col.scale = , col.legend = , col_alpha = )
##   tm_polygons(fill = , fill.scale = , fill.legend = )
##   tm_scale_intervals(), tm_legend(), tm_title(), tmap_arrange()
## Avec tmap 3, TOUS les blocs cartographiques echouent
## ("unused argument (col.scale)"). Ce n'est pas une degradation partielle :
## c'est un echec complet du module 3 au module 9.
v_tmap <- tryCatch(packageVersion("tmap"), error = function(e) NULL)
if (!is.null(v_tmap)) {
  message("\ntmap installe : version ", v_tmap)
  if (v_tmap < "4.0.0")
    warning("tmap ", v_tmap, " detecte : le materiel du J08 exige tmap >= 4.0.0. ",
            "Lancez install.packages(\"tmap\") pour mettre a jour.")
} else {
  warning("tmap n'est pas installe.")
}

## ---------------------------------------------------------------------------
## CONTROLE : terra doit savoir lire les GeoTIFF et les GeoPackage
## ---------------------------------------------------------------------------
v_terra <- tryCatch(packageVersion("terra"), error = function(e) NULL)
if (!is.null(v_terra)) {
  message("terra installe : version ", v_terra)
  if (v_terra < "1.7.0")
    warning("terra ", v_terra, " detecte : ifel(), sprc() et mosaic() du ",
            "module 7 supposent terra >= 1.7.0.")
}

## ---------------------------------------------------------------------------
## Rappel sur les donnees
## ---------------------------------------------------------------------------
## Le dossier datasets/ doit contenir les 12 fichiers listes dans
## datasets/LISEZMOI.md :
##   cmr_admpop_adm1_2025.csv
##   gadm41_CMR.gpkg
##   cmr_pop_2015_CN_100m_R2025A_v1.tif
##   cmr_pop_2025_CN_100m_R2025A_v1.tif
##   cmr_pop_2030_CN_100m_R2025A_v1.tif
##   7 tuiles GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R*_C*.zip
## Depuis la racine du projet :
##   source("outils/distribuer_donnees.R")
if (dir.exists("datasets")) {
  fichiers <- list.files("datasets")
  message("\nFichiers presents dans datasets/ : ", length(fichiers))
  n_ghs <- length(grep("^GHS_POP_E2025.*\\.zip$", fichiers))
  message("  dont tuiles GHS-POP E2025 (.zip) : ", n_ghs, " / 7")
  if (n_ghs < 7)
    message("  ATTENTION : le module 7 (mosaique GHS-POP) sera incomplet.")
} else {
  message("\nATTENTION : dossier datasets/ absent. Lancez, depuis la racine ",
          "du projet, source(\"outils/distribuer_donnees.R\").")
}
