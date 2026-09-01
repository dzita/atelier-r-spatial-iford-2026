## ============================================================================
## J07 -- Le hasard a-t-il une geographie ? Statistiques spatiales
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026
## ============================================================================

## Liste alignee sur les library() REELLEMENT charges par demo_formateur_J7.qmd
## (lignes 86 a 100), plus les paquets appeles en notation qualifiee pkg::fun().
## Verification faite : les seuls pkg:: du document sont haven::, viridis::,
## terra::, spdep::, stats:: -- tous deja dans la liste ci-dessous (stats est
## dans R de base) -- et SpatialEpi::kulldorff(), qui n'apparait QUE dans un
## tableau en commentaire (chunk-13, ligne 853) : aucun appel execute, donc
## SpatialEpi n'est PAS installe.
##
## Paquets volontairement ECARTES, et a quelle journee ils appartiennent :
##   tmaptools .................. jamais charge ici ; tmap 4 suffit pour toutes
##                                les cartes du J07
##   tidyr ...................... J05/J08 (pivot_longer) -- aucun appel au J07
##   spatialreg ................. J11 (modeles SAR/SEM). Le J07 s'arrete a
##                                l'autocorrelation descriptive (Moran, LISA,
##                                Gi*), il n'estime aucun modele spatial
##   gstat, automap ............. J06 (interpolation, krigeage)
##   SpatialEpi ................. cite en commentaire seulement (voir ci-dessus)
##   leaflet, mapview ........... jamais : widgets interactifs, interdits dans
##                                un document distribue (regle 6.6). La section
##                                9.2 du .qmd est neutralisee pour cette raison
##   exactextractr, scales ...... J08 (statistiques zonales ponderees, echelles)
##   osmdata, tidyterra ......... J09
##   sae, ranger, Metrics ....... J10
## Le bloc `packages_requis` du chunk-01 du .qmd en listait 21 : 6 d'entre eux
## ne sont jamais charges. Les installer allongerait la mise en place de
## plusieurs dizaines de minutes en salle, pour rien.

pkgs_j07 <- c(
  "sf",            # vecteurs Simple Features : DS.geojson, shapefiles DHS
  "terra",         # rasters Sentinel-2 : rast, resample, ifel, crop, mask
  "sp",            # classes spatiales legacy (dependance historique de spdep)
  "spdep",         # poids spatiaux, moran.test, localmoran, localG
  "spatstat",      # processus ponctuels : ppp, quadrat.test, Gest, Kest, Lest
  "ggplot2",       # diagramme de Moran
  "tmap",          # cartographie thematique -- VERSION 4 requise (voir plus bas)
  "dplyr",         # filter, group_by, summarise, left_join, %>%
  "readr",         # lecture CSV
  "haven",         # read_sav (.SAV DHS), read_dta (ecam5.dta), zap_labels
  "KernSmooth",    # estimation noyau 2D classique
  "SpatialKDE",    # KDE spatialisee sur raster
  "RColorBrewer",  # palettes de couleurs
  "viridis",       # palettes perceptuelles (viridis, inferno, magma, plasma)
  "classInt"       # discretisation (Jenks, quantiles)
)

## ---------------------------------------------------------------------------
## AVERTISSEMENT : temps d'installation
## ---------------------------------------------------------------------------
## Cinq paquets de cette liste sont LOURDS. Sur un poste sans binaire
## disponible (Linux, ou source force sous Windows/macOS), ils se compilent :
##   spatstat ..... metapaquet (spatstat.geom, .explore, .model, .random,
##                  .linnet, .utils, .data, .sparse) : le plus long de tous
##   spdep ........ chaine s2 / units / sf
##   SpatialKDE ... Rcpp + RcppArmadillo, compilation C++
##   sf ........... dependances systeme GDAL / GEOS / PROJ
##   terra ........ dependances systeme GDAL / GEOS / PROJ
## PREVOIR DU TEMPS : compter 20 a 45 minutes sur une machine neuve, davantage
## sur une connexion lente. A lancer AVANT la salle, jamais pendant.

a_installer <- pkgs_j07[!pkgs_j07 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  install.packages(a_installer)
} else {
  message("Tous les packages du J07 sont deja installes.")
}

## Verification : chaque paquet doit etre TROUVABLE.
## requireNamespace() et non require() : on verifie la presence SANS attacher.
## Attacher les 15 paquets ici fausserait tout test ulterieur sur l'ordre de
## chargement (masquage de dplyr::filter par stats::filter, de terra::extract
## par tidyr::extract, etc.) -- le .qmd doit rester seul maitre de ses library().
invisible(lapply(pkgs_j07, function(p) {
  ok <- suppressWarnings(requireNamespace(p, quietly = TRUE))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))

## ---------------------------------------------------------------------------
## CONTROLE DE VERSION : tmap >= 4.0.0
## ---------------------------------------------------------------------------
## Le materiel du J07 a ete MIGRE vers l'API tmap 4 :
##   tm_fill(fill = , fill.scale = , fill.legend = )
##   tm_dots(fill = , fill.scale = , fill_alpha = )
##   tm_scale_intervals(), tm_scale_categorical(), tm_legend()
##   tm_title() -- le titre n'est plus un argument de tm_layout()
##   tm_scalebar() -- renomme (tm_scale_bar() n'existe plus)
## Avec tmap 3, ces appels echouent ("unused argument (fill.scale)") ou se
## degradent silencieusement. Les cartes des sections 2.3, 6.2, 7.1, 8.4f et
## 9.1 tombent toutes ensemble.
v_tmap <- tryCatch(packageVersion("tmap"), error = function(e) NULL)
if (!is.null(v_tmap)) {
  message("\ntmap installe : version ", v_tmap)
  if (v_tmap < "4.0.0")
    warning("tmap ", v_tmap, " detecte : le materiel du J07 exige tmap >= 4.0.0. ",
            "Lancez install.packages(\"tmap\") pour mettre a jour.")
} else {
  warning("tmap n'est pas installe.")
}

## ---------------------------------------------------------------------------
## CONTROLE : terra doit savoir aligner et combiner deux rasters
## ---------------------------------------------------------------------------
## La section 8.4 utilise resample(), compareGeom(), ifel(), global() et
## minmax() pour construire le NDMI a partir de B08 et B11.
v_terra <- tryCatch(packageVersion("terra"), error = function(e) NULL)
if (!is.null(v_terra)) {
  message("terra installe : version ", v_terra)
  if (v_terra < "1.7.0")
    warning("terra ", v_terra, " detecte : ifel() et compareGeom() de la ",
            "section 8.4 supposent terra >= 1.7.0.")
}

## ---------------------------------------------------------------------------
## CONTROLE : spatstat doit fournir les fonctions de processus ponctuels
## ---------------------------------------------------------------------------
v_spatstat <- tryCatch(packageVersion("spatstat"), error = function(e) NULL)
if (!is.null(v_spatstat)) {
  message("spatstat installe : version ", v_spatstat)
  if (v_spatstat < "3.0.0")
    warning("spatstat ", v_spatstat, " detecte : la section 3 (ppp, ",
            "quadrat.test, Gest, Kest, Lest, envelope) suppose spatstat >= 3.0.0.")
}

## ---------------------------------------------------------------------------
## Rappel sur les donnees
## ---------------------------------------------------------------------------
## Le dossier datasets/ doit contenir les fichiers lus par demo_formateur_J7.qmd
## (voir datasets/LISEZMOI.md). Depuis la racine du projet :
##   source("outils/distribuer_donnees.R")
fichiers_attendus <- c(
  "DS.geojson",                       # districts sanitaires (polygones)
  "Pays_limitrophes_Cmr.shp",         # + .dbf .shx .prj .cpg
  "CMGE71FL.shp",                     # grappes DHS (points) + .dbf .shx .prj
  "CMGC72FL.csv",                     # menages DHS (covariables grappe)
  "CMHR71FL.SAV",                     # DHS .sav
  "CMIR71FL.SAV",                     # DHS .sav
  "ecam5.dta",                        # ECAM5 (variable s09q13a, section 1.6)
  "CMR_population_v1_0_admin_level2.csv",
  "CMR_household_v1_0_admin_level2.csv",
  "2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B08_(Raw).tiff",
  "2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B11_(Raw).tiff",
  "2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_True_color.tiff"
)

## Fichiers compagnons obligatoires des deux shapefiles : un .shp seul ne se lit pas.
compagnons_shp <- c("Pays_limitrophes_Cmr.dbf", "Pays_limitrophes_Cmr.shx",
                    "Pays_limitrophes_Cmr.prj",
                    "CMGE71FL.dbf", "CMGE71FL.shx", "CMGE71FL.prj")

if (dir.exists("datasets")) {
  presents <- list.files("datasets")
  message("\nFichiers presents dans datasets/ : ", length(presents))

  manquants <- fichiers_attendus[!fichiers_attendus %in% presents]
  if (length(manquants)) {
    message("  MANQUANTS (", length(manquants), "/", length(fichiers_attendus), ") :")
    for (f in manquants) message("    - ", f)
  } else {
    message("  Les ", length(fichiers_attendus),
            " fichiers attendus par le .qmd sont tous presents.")
  }

  manq_comp <- compagnons_shp[!compagnons_shp %in% presents]
  if (length(manq_comp))
    message("  ATTENTION : compagnons de shapefile absents : ",
            paste(manq_comp, collapse = ", "),
            " -- st_read() echouera sur le .shp correspondant.")

  ## Les trois tuiles Sentinel-2 : B03 et B04 n'ont JAMAIS ete acquises.
  ## Consequence assumee et documentee en 8.4 du .qmd : ni NDVI, ni NDWI.
  ## Le seul indice calculable est le NDMI = (B08 - B11)/(B08 + B11).
  n_tiff <- length(grep("Sentinel-2.*\\.tiff$", presents))
  message("  Tuiles Sentinel-2 (.tiff) : ", n_tiff, " / 3 (B08, B11, True_color)")
  if (n_tiff < 3)
    message("  ATTENTION : la section 8.4 (NDMI) sera incomplete.")
} else {
  message("\nATTENTION : dossier datasets/ absent. Lancez, depuis la racine ",
          "du projet, source(\"outils/distribuer_donnees.R\").")
}
