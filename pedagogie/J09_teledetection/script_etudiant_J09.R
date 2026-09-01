## ============================================================================
## SCRIPT ETUDIANT -- TRAME A COMPLETER
## J09 -- VOIR LE TERRITOIRE DEPUIS L'ESPACE : TELEDETECTION, BATI, INONDATIONS
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Mercredi 5 aout 2026
## Referents : E. Darin, M. Teda, R. Dzita -- Support : R. Elandi
##
## MODE D'EMPLOI. Les commentaires portent la consigne : lisez-les, puis
## ecrivez votre code aux emplacements marques ">>> A COMPLETER". Avancez
## section par section, en verifiant chaque sortie avant de continuer.
## Le corrige complet (script_etudiant_J09_corrige.R) est distribue en fin de
## journee.
##
## NOMBRE DE TROUS DANS CETTE TRAME : 66
## (66 marqueurs ">>> A COMPLETER", numerotes de CONSIGNE 1 a CONSIGNE 66)
##
## Les sections "chargement des packages" et "lecture des donnees" sont
## COMPLETES : sans elles, rien ne tourne. Les trous commencent au premier
## verbe de manipulation.
##
## Donnees : datasets/ (chemins relatifs, a plat). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
## ============================================================================

## --- Se placer dans le dossier de la journee --------------------------------
.dossier_jour <- "J09_teledetection"
if (!dir.exists("datasets")) {
  for (.p in c(.dossier_jour,
               file.path("pedagogie", .dossier_jour),
               file.path("..", .dossier_jour))) {
    if (dir.exists(file.path(.p, "datasets"))) { setwd(.p); break }
  }
}
if (!dir.exists("datasets"))
  stop("Dossier datasets/ introuvable. Ouvrez atelier-r-spatial-iford-2026.Rproj, ",
       "lancez source('outils/distribuer_donnees.R'), puis relancez ce script.")
cat("Dossier de travail :", getwd(), "\n\n")

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)

## ----------------------------------------------------------------------
## LA QUESTION DE LA JOURNEE
##
## Que peut-on mesurer d'un territoire quand on ne peut pas y aller ?
##   1. On mesure un RAYONNEMENT -- la physique du capteur (modules 1 et 2).
##   2. On mesure un PRODUIT DERIVE fabrique par quelqu'un d'autre --
##      GHS-BUILT, Open Buildings, Copernicus EMS (modules 3 a 9).
##   3. On CROISE deux produits independants et on regarde ou ils divergent.
##      C'est le module 7 : deux methodes defendables, deux reponses.
## ----------------------------------------------------------------------


## ========================================================================
## 0. MISE EN PLACE  (section complete -- rien a completer ici)
## ========================================================================

## --- BLOC DE REFERENCE, NON EXECUTE ---
# install.packages(c("sf", "dplyr", "ggplot2", "tidyr", "readr",
#                    "terra", "exactextractr", "tmap", "osmdata"))

library(sf)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(terra)
library(exactextractr)
library(tmap)
library(osmdata)

options(scipen = 999)
terra::terraOptions(progress = 0)

cat("sf            :", as.character(packageVersion("sf")), "\n")
cat("terra         :", as.character(packageVersion("terra")), "(1.7 minimum)\n")
cat("tmap          :", as.character(packageVersion("tmap")), "(4.0 minimum)\n")
cat("exactextractr :", as.character(packageVersion("exactextractr")), "\n")

# --- Reglages qui decident de la justesse des chiffres ---------------------
# s2 REFUSE ce que GEOS accepte : sur des shapefiles produits en urgence -- le
# cas des produits Copernicus EMS -- les auto-intersections sont frequentes et
# s2 fait echouer st_intersection(). On bascule sur GEOS.
sf_use_s2(FALSE)
cat("Moteur spherique s2 actif :", sf_use_s2(), "(FALSE = calcul planaire GEOS)\n")

# EPSG:4326 est en DEGRES : une surface ou une longueur calculee dessus n'a
# aucun sens metrique. Pour le Cameroun : UTM zone 33N, EPSG:32633.
crs_mesure <- 32633
cat("CRS de mesure retenu : EPSG:", crs_mesure, " (UTM 33N, unite = metre)\n", sep = "")

tmap_mode("plot")

# --- Inventaire de depart --------------------------------------------------
fichiers_attendus <- c(
  "gadm41_CMR.gpkg",
  "cmr_pop_2024_CN_100m_R2025A_v1.tif",
  "open_buildings_yagoua.gpkg",
  "routes_aoi01_yagoua.gpkg",
  "EMSR772_AOI01_areaOfInterestA.shp",
  "EMSR772_AOI01_floodDepthA.shp",
  "EMSR772_AOI02_areaOfInterestA.shp",
  "EMSR772_AOI02_floodDepthA.shp",
  "EMSR772_AOI03_areaOfInterestA.shp",
  "EMSR772_AOI03_floodDepthA.shp"
)

etat <- data.frame(
  fichier = fichiers_attendus,
  present = file.exists(file.path("datasets", fichiers_attendus))
)
print(etat)

cat("\nArchives GHS-BUILT trouvees dans datasets/ :\n")
zip_2015 <- list.files("datasets", pattern = "^GHS_BUILT_S_E2015.*\\.zip$",
                       full.names = TRUE)
zip_2025 <- list.files("datasets", pattern = "^GHS_BUILT_S_E2025.*\\.zip$",
                       full.names = TRUE)
cat("  millesime 2015 :", length(zip_2015), "tuile(s)\n")
cat("  millesime 2025 :", length(zip_2025), "tuile(s)\n")

## ----------------------------------------------------------------------
## UN PIEGE DE NOMMAGE
##
## Le materiel source cherchait GHS_BUILT_S_E2020 -- un millesime qui
## N'EXISTE PAS. Les archives disponibles sont 2015 et 2025. Un list.files()
## sur un motif introuvable ne leve aucune erreur : il renvoie un vecteur de
## longueur zero, et le mosaic() qui suit echoue dix lignes plus loin avec un
## message qui ne parle pas du vrai probleme.
## Si l'un des deux comptages ci-dessus vaut 0, ARRETEZ-VOUS ICI.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 1 -- CE QU'UN SATELLITE MESURE REELLEMENT
## ========================================================================
## 1.1 Un satellite ne photographie pas : il MESURE une quantite de
## rayonnement electromagnetique dans un intervalle de longueurs d'onde.
##   Emission -> Reflexion (la REFLECTANCE) -> Traversee atmospherique ->
##   Detection -> Quantification -> Correction L1C vers L2A (un MODELE) ->
##   Livraison en GeoTIFF.
##
## 1.2 LES QUATRE RESOLUTIONS
##   SPATIALE      : taille au sol d'un pixel. Fixe ce qu'on ne verra JAMAIS.
##   SPECTRALE     : nombre et largeur des bandes (13 pour Sentinel-2).
##   TEMPORELLE    : delai de revisite (5 j Sentinel-2, 16 Landsat, 1 MODIS).
##   RADIOMETRIQUE : nombre de niveaux distinguables. 12 bits = mesure de
##     reflectance ; 8 bits = apparence pour l'ecran, PLUS AUCUNE mesure
##     physique. C'est celle qu'on oublie, et c'est elle qui piege ce jour.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## 1.3 SIGNATURES SPECTRALES
## ------------------------------------------------------------------------
## Le tableau ci-dessous est fourni : ce sont des valeurs typiques SAISIES A
## LA MAIN, a but d'illustration. Ce n'est PAS une mesure satellite.

signatures <- tibble::tribble(
  ~surface,            ~bande,   ~longueur_onde_nm, ~reflectance,
  "Vegetation dense",  "Bleu",    492,  0.03,
  "Vegetation dense",  "Vert",    560,  0.07,
  "Vegetation dense",  "Rouge",   665,  0.04,
  "Vegetation dense",  "PIR",     833,  0.48,
  "Vegetation dense",  "SWIR",   1610,  0.19,
  "Sol nu",            "Bleu",    492,  0.11,
  "Sol nu",            "Vert",    560,  0.16,
  "Sol nu",            "Rouge",   665,  0.22,
  "Sol nu",            "PIR",     833,  0.29,
  "Sol nu",            "SWIR",   1610,  0.36,
  "Bati dense",        "Bleu",    492,  0.14,
  "Bati dense",        "Vert",    560,  0.17,
  "Bati dense",        "Rouge",   665,  0.20,
  "Bati dense",        "PIR",     833,  0.24,
  "Bati dense",        "SWIR",   1610,  0.32,
  "Eau libre",         "Bleu",    492,  0.06,
  "Eau libre",         "Vert",    560,  0.05,
  "Eau libre",         "Rouge",   665,  0.03,
  "Eau libre",         "PIR",     833,  0.01,
  "Eau libre",         "SWIR",   1610,  0.005
)

## CONSIGNE 1. Affichez le nombre de lignes du tableau et la liste des
## surfaces representees (une seule fois chacune).

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 2. Tracez les signatures : longueur d'onde en abscisse,
## reflectance en ordonnee, une couleur ET une forme de point par surface
## (les deux dans aes(), sinon pas de legende commune). Placez des ruptures
## d'axe aux cinq longueurs d'onde, et titrez en precisant que c'est un
## SCHEMA, pas une mesure.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- SIGNATURES SPECTRALES
##
## CE QUE LA FIGURE CODE. Cinq longueurs d'onde correspondant a cinq bandes
## Sentinel-2 ; en ordonnee la REFLECTANCE (0 a 1).
## CE QUE LES CHOIX TECHNIQUES FONT. Relier les points suggere une continuite
## qui n'existe pas : un capteur ne mesure qu'aux positions marquees. L'axe
## vertical part de 0 : 0,01 et 0,05 sont dans un rapport de 1 a 5.
## CE QUI SE LIT. La vegetation s'effondre dans le Rouge et explose dans le
## PIR (NDVI) ; le bati et le sol nu montent dans le SWIR (NDBI) ; l'eau
## s'effondre dans le PIR et le SWIR (MNDWI).
## CE QUI NE SE LIT PAS. Bati dense et sol nu ont des profils presque
## paralleles : limite PHYSIQUE, pas algorithmique.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 1.5 OUVRIR UNE IMAGE ET LA CONTROLER -- BLOC DE REFERENCE, NON EXECUTE
## ------------------------------------------------------------------------
# chemin_rouge <- file.path("datasets", "bande_rouge_a_fournir.tif")
# b04 <- terra::rast(chemin_rouge)
# cat("Dimensions :", dim(b04), "\n")
# cat("Resolution :", res(b04), "unites du CRS\n")
# cat("CRS        :", terra::crs(b04, describe = TRUE)$name, "\n")
# print(terra::ext(b04))
# print(terra::minmax(b04))   # 0-255 = image de visualisation, PAS de la reflectance
# cat("Cellules NA :", terra::global(is.na(b04), "sum")[1, 1], "\n")


## ========================================================================
## MODULE 2 -- LES INDICES DE DIFFERENCE NORMALISEE
## ========================================================================
## ----------------------------------------------------------------------
## POURQUOI CE MODULE NE CALCULE PAS DE NDVI AUJOURD'HUI
##
## La tuile Sentinel-2 du depot NE PERMET PAS un exercice honnete :
##  1. elle est ABSENTE du poste ;
##  2. elle est PARTIELLE (Est et Sud seulement) ;
##  3. elle est en WGS84 a ~150 m, non en UTM a 10 m ;
##  4. les bandes B03 (Vert) et B04 (Rouge) sont ABSENTES -- or B04 est au
##     denominateur du NDVI et B03 au numerateur du MNDWI ;
##  5. l'image "True color" est en 8 BITS : elle ne porte aucune reflectance.
## Calculer un NDVI dessus produit des nombres sans sens physique -- et cela
## ne plante pas. Module livre en expose, code de reference non execute.
## ----------------------------------------------------------------------
##
## 2.1 LA FORME GENERALE : indice = (A - B) / (A + B)
##  - borne entre -1 et +1 : la division normalise en partie l'eclairement ;
##  - c'est un RAPPORT, pas une quantite : "le PIR domine le Rouge" ;
##  - le denominateur peut s'approcher de zero sur le nodata et les bords de
##    tuile -> MASQUER LE NODATA AVANT DE CALCULER, jamais apres.
##
## 2.2 LES TROIS INDICES
##   NDVI  = (PIR - Rouge) / (PIR + Rouge)
##   NDBI  = (SWIR - PIR)  / (SWIR + PIR)
##   MNDWI = (Vert - SWIR) / (Vert + SWIR)
## ------------------------------------------------------------------------

## CONSIGNE 3. Passez le tableau `signatures` au format LARGE : une ligne par
## surface, une colonne par bande, la valeur etant la reflectance. Affichez
## ensuite le nombre de surfaces et le nombre de bandes obtenus.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 4. Calculez les trois indices sur ce tableau large, gardez
## seulement surface + les trois indices, et arrondissez a 3 decimales.
## Affichez le resultat.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 5. CONTROLE : verifiez qu'aucune valeur ne sort de [-1, 1]. Si
## c'est le cas, c'est que le denominateur est passe pres de zero. Affichez le
## nombre de valeurs hors bornes.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 6. Tracez un diagramme en barres groupees : une barre par indice
## et par surface, ligne horizontale a 0, palette QUALITATIVE (trois indices
## sans ordre entre eux) et axe vertical FIXE a [-1, 1] -- on veut montrer ou
## chaque valeur se place dans l'etendue POSSIBLE de l'indice.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- LES TROIS INDICES
##
## CE QUE LA FIGURE CODE. Une barre = un indice pour un type de surface.
## CE QUE LES CHOIX TECHNIQUES FONT. Axe FIXE a [-1, 1] : un axe ajuste aux
## donnees exagererait les ecarts. Palette QUALITATIVE.
## CE QUI SE LIT. Chaque indice est maximal pour la surface qu'il vise.
## CE QUI NE SE LIT PAS. Le NDBI du sol nu est du meme ordre que celui du
## bati : la confusion est DANS LES CHIFFRES. Et ces valeurs sont INVENTEES :
## un pixel reel est un melange de surfaces.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 2.4 LE CODE DE REFERENCE -- BLOC NON EXECUTE
## ------------------------------------------------------------------------
# # 1. ALIGNER (SWIR natif a 20 m, PIR a 10 m)
# if (!terra::compareGeom(b08, b11, stopOnError = FALSE))
#   b11 <- terra::resample(b11, b08, method = "bilinear")
# # 2. MASQUER LE NODATA AVANT DE CALCULER
# masque_valide <- !is.na(b04) & !is.na(b08) & (b04 + b08) > 0
# b04 <- terra::mask(b04, masque_valide, maskvalues = 0)
# # 3. PASSER EN REFLECTANCE (0-1) : Sentinel-2 L2A est livre x 10000
# # 4. CALCULER  ndvi <- (b08_r - b04_r) / (b08_r + b04_r)
# # 5. CONTROLER  terra::global(ndvi, c("mean","sd","min","max"), na.rm = TRUE)
# # 6. BORNER L'AFFICHAGE SUR LES CENTILES 1 ET 99
# # 7. NE JAMAIS calculer un indice sur une image "True color" 8 bits.


## ========================================================================
## MODULE 3 -- DU PIXEL AU PRODUIT : GHS-BUILT
## ========================================================================
## ----------------------------------------------------------------------
## "SURFACE BATIE" N'EST PAS "SURFACE URBANISEE"
##
## GHS-BUILT-S donne, par cellule de 100 m, la SURFACE DE BATI EN M2 -- une
## valeur continue entre 0 et 10 000. Il ne mesure ni les cours, rues et
## places (un tissu urbain classique ne depasse guere 30 a 50 % de surface
## batie), ni la HAUTEUR, ni l'USAGE, ni l'OCCUPATION.
## CONSEQUENCE : une part batie de 3 % NE VEUT PAS DIRE que 3 % de la
## population vit en ville. C'est un indicateur de PRESSION PHYSIQUE SUR LE
## SOL, pas un indicateur d'urbanisation au sens demographique.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 3.2 FONCTIONS DE LECTURE  (fournies -- ne pas modifier)
## ------------------------------------------------------------------------

charger_ghsl <- function(annee) {

  archives <- list.files(
    "datasets",
    pattern = paste0("^GHS_BUILT_S_E", annee, ".*\\.zip$"),
    full.names = TRUE
  )

  cat("--- charger_ghsl(", annee, ") ---\n", sep = "")
  cat("  archives trouvees :", length(archives), "\n")

  if (length(archives) == 0) {
    stop("Aucune archive GHS_BUILT_S_E", annee, " dans datasets/. ",
         "Verifiez le millesime : les donnees livrees sont 2015 et 2025.")
  }

  codes <- sub(".*_(R\\d+_C\\d+)\\.zip$", "\\1", basename(archives))
  cat("  tuiles :", paste(sort(codes), collapse = ", "), "\n")

  rasters <- lapply(archives, function(zip_path) {
    tmp_dir <- tempfile("ghsl_")
    dir.create(tmp_dir)
    unzip(zip_path, exdir = tmp_dir)
    tif_path <- list.files(tmp_dir, pattern = "\\.tif$",
                           full.names = TRUE, recursive = TRUE)[1]
    if (is.na(tif_path))
      stop("Archive sans .tif : ", basename(zip_path))
    terra::rast(tif_path)
  })

  mosaique <- if (length(rasters) == 1) rasters[[1]] else do.call(mosaic, rasters)

  cat("  resolution :", paste(res(mosaique), collapse = " x "), "\n")
  cat("  CRS        :", terra::crs(mosaique, describe = TRUE)$name, "\n")
  cat("  emprise    : "); print(terra::ext(mosaique))

  attr(mosaique, "codes_tuiles") <- sort(codes)
  mosaique
}

preparer_raster <- function(raster, pays, etiquette = "") {
  pays_vect <- terra::vect(sf::st_transform(pays, terra::crs(raster)))
  sortie <- terra::mask(terra::crop(raster, pays_vect), pays_vect)

  n_total <- terra::ncell(sortie)
  n_na    <- as.numeric(terra::global(is.na(sortie), "sum", na.rm = TRUE)[1, 1])
  cat("--- preparer_raster(", etiquette, ") ---\n", sep = "")
  cat("  cellules totales :", n_total, "\n")
  cat("  cellules NA      :", n_na,
      " (", round(100 * n_na / n_total, 1), "% -- hors frontiere)\n", sep = "")
  cat("  somme du bati    :",
      round(as.numeric(terra::global(sortie, "sum", na.rm = TRUE)[1, 1]) / 1e6, 1),
      "km2\n")
  sortie
}

## CONSIGNE 7. Ecrivez resumer_bati(polygones, raster, annee, id_col, nom_col,
## etiquette) : elle doit
##   (a) reprojeter les polygones dans le CRS DU RASTER pour l'extraction ;
##   (b) extraire la somme du bati avec exact_extract(..., "sum") et la
##       convertir en km2 (les valeurs GHSL sont en m2) ;
##   (c) calculer la SURFACE des polygones dans crs_mesure -- PAS en degres ;
##   (d) instrumenter : nombre de polygones, CRS d'extraction, CRS de mesure,
##       bati total, surface totale, polygones sans bati, extractions NA ;
##   (e) renvoyer la couche avec annee, surface_km2, bati_km2, part_batie_pct.
## RAPPEL : exact_extract pondere chaque cellule par la FRACTION de sa surface
## couverte par le polygone ; terra::extract() compte la cellule entiere du
## cote ou tombe son centre.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ------------------------------------------------------------------------
## 3.3 LES LIMITES ADMINISTRATIVES  (lecture fournie)
## ------------------------------------------------------------------------

chemin_gadm <- "datasets/gadm41_CMR.gpkg"

cat("Couches disponibles dans", chemin_gadm, ":\n")
print(sf::st_layers(chemin_gadm))

lire_gadm <- function(couche) {
  x <- sf::st_read(chemin_gadm, layer = couche, quiet = TRUE)
  n_invalides_avant <- sum(!sf::st_is_valid(x))
  x <- sf::st_make_valid(x)
  cat("--- ", couche, " ---\n", sep = "")
  cat("  entites            :", nrow(x), "\n")
  cat("  colonnes           :", paste(names(x), collapse = ", "), "\n")
  cat("  CRS                :", sf::st_crs(x)$input, "\n")
  cat("  geometries invalides avant / apres st_make_valid() : ",
      n_invalides_avant, " / ", sum(!sf::st_is_valid(x)), "\n", sep = "")
  x
}

cmr0 <- lire_gadm("ADM_ADM_0")
cmr1 <- lire_gadm("ADM_ADM_1")
cmr2 <- lire_gadm("ADM_ADM_2")

cat("\nEmprise du pays (degres) :\n")
print(sf::st_bbox(cmr0))

surface_officielle_km2 <- 475442   # reference : superficie officielle

## CONSIGNE 8. Calculez la superficie totale du pays dans TROIS systemes :
## EPSG:4326 (tel quel, proteger par tryCatch), EPSG:32633 (UTM 33N) et
## ESRI:54009 (Mollweide). Rassemblez-les dans un data.frame avec l'ecart en
## pourcentage a la reference officielle, et affichez-le.
## ATTENDU : la ligne 4326 est absurde (des "degres carres"), UTM 33N est a
## quelques pour cent, Mollweide -- projection EQUIVALENTE -- est la plus
## juste sur une surface nationale.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## A RETENIR : "reprojeter avant de mesurer" ne suffit pas, il faut
## reprojeter DANS LA BONNE FAMILLE. CONFORME pour les angles et les formes
## locales (UTM), EQUIVALENTE pour les surfaces (Mollweide), EQUIDISTANTE
## pour les distances depuis un point. Aucune projection ne fait les trois.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 3.4 MOSAIQUER ET CONTROLER LA SYMETRIE DES MILLESIMES
## ------------------------------------------------------------------------

bati_2015 <- charger_ghsl(2015)
bati_2025 <- charger_ghsl(2025)

## CONSIGNE 9. CONTROLE CRITIQUE. Recuperez les codes de tuiles des deux
## millesimes (attribut "codes_tuiles"), affichez-les, et calculez les
## differences symetriques dans les deux sens. Si une tuile manque d'un cote,
## affichez une alerte explicite.
## POURQUOI : sur la zone d'une tuile manquante en 2015, le raster vaut NA ;
## exact_extract(..., "sum") traite les NA comme absents, donc le "gain"
## 2015-2025 y devient egal a la TOTALITE du bati 2025 et la croissance
## relative explose. La region ressortirait en rouge vif comme la plus
## dynamique du pays, et aucune erreur ne serait levee.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

bati_2015_cmr <- preparer_raster(bati_2015, cmr0, "GHS-BUILT 2015")
bati_2025_cmr <- preparer_raster(bati_2025, cmr0, "GHS-BUILT 2025")

## CONSIGNE 10. Ecrivez aligner_millesimes(r_ancien, r_recent) : croisez les
## deux emprises (terra::intersect sur les ext), recadrez les deux rasters,
## verifiez avec compareGeom() qu'ils sont alignes, construisez un masque des
## cellules valides DANS LES DEUX millesimes, appliquez-le, et affichez le
## bati total avant et apres alignement pour chaque annee. Renvoyez une liste
## a deux elements.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 11. Appliquez la fonction et rangez les resultats dans
## bati_2015_ok et bati_2025_ok.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 12. Affichez la mosaique 2025. Calculez d'abord les CENTILES 1 ET
## 99 de la distribution et bornez l'affichage dessus : sans cela, quelques
## cellules de centre-ville saturees a 10 000 m2 absorbent toute la palette.
## Utilisez une palette SEQUENTIELLE, et superposez les contours ADM1
## reprojetes dans le CRS du raster.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- LA MOSAIQUE GHS-BUILT 2025
##
## CE QUE LA FIGURE CODE. Chaque pixel de 100 m code le nombre de METRES
## CARRES DE TOIT qu'il contient (0 a 10 000).
## CE QUE LES CHOIX TECHNIQUES FONT. Bornage aux centiles 1 et 99 : ecretage
## VISUEL, pas suppression de donnee. Palette SEQUENTIELLE, correcte pour une
## quantite positive ; une divergente serait un contresens.
## CE QUI SE LIT. Le bati est extremement concentre ; les alignements clairs
## suivent des routes, pas des reliefs.
## CE QUI NE SE LIT PAS. La hauteur, l'usage, l'occupation. UNE CELLULE A 0
## N'EST PAS UNE CELLULE SANS HUMAINS.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 4 -- MESURER LE BATI
## ========================================================================

## ------------------------------------------------------------------------
## 4.1 LE NIVEAU NATIONAL
## ------------------------------------------------------------------------

## CONSIGNE 13. Reprojetez cmr0 dans le CRS du raster (pour l'extraction) et
## calculez la surface nationale dans crs_mesure (pour la mesure). Affichez-la.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 14. Construisez deux tibbles (2015 et 2025) avec le bati national
## en km2 et la part batie en %, puis empilez-les. Affichez le resultat.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 15. Passez ce tableau au format large et calculez le GAIN ABSOLU
## (km2), la CROISSANCE RELATIVE (%) et l'ecart de part batie. Affichez, puis
## ecrivez une phrase de lecture avec cat().

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## DEUX CHIFFRES, DEUX QUESTIONS DIFFERENTES
##
## Le GAIN ABSOLU repond a "ou faut-il des routes, des ecoles, de
## l'assainissement ?" ; la CROISSANCE RELATIVE a "ou le rythme est-il le plus
## rapide ?" -- et un rapport a un denominateur. Ils NE CLASSENT PAS les
## territoires dans le meme ordre. Publier la seule croissance relative met en
## tete les unites les plus petites, mecaniquement.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.2 LE NIVEAU REGIONAL (ADM1)
## ------------------------------------------------------------------------

## CONSIGNE 16. Appliquez resumer_bati() a cmr1 pour les deux millesimes
## (cles "GID_1" et "NAME_1").

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 17. DECLAREZ un seuil de bati initial en dessous duquel vous
## refuserez de calculer une croissance relative (un denominateur minuscule
## fabrique des taux a trois chiffres). Le seuil doit etre une VARIABLE
## NOMMEE, ecrite dans le code, pas subie.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 18. Joignez les deux millesimes sur GID_1 (partez du tableau 2015
## sans geometrie), renommez les colonnes avec le suffixe d'annee, puis
## calculez gain_bati_km2, croissance_pct (NA sous le seuil),
## delta_part_batie_pct et part_nationale_2025_pct. Triez par gain decroissant.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 19. INSTRUMENTEZ la jointure : nombre de lignes avant et apres,
## NA sur le bati 2025 apres jointure, nombre de regions sous le seuil, et
## somme des parts nationales (elle DOIT valoir 100). Affichez le tableau.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 20. Ajoutez les rangs par gain, par croissance et par part batie,
## ainsi que l'ecart de rang entre gain et croissance. Affichez le tableau
## trie par rang de gain, puis l'ecart de rang MAXIMAL et la correlation de
## SPEARMAN entre les deux classements.
## POURQUOI SPEARMAN : Pearson mesure une association lineaire et se laisse
## dominer par une valeur extreme ; avec dix regions dont une pese
## demesurement, un seul point fixerait le coefficient. Spearman travaille sur
## les RANGS et repond exactement a la question : les deux classements
## sont-ils le meme classement ?

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ------------------------------------------------------------------------
## 4.3 LES CARTES REGIONALES
## ------------------------------------------------------------------------

## CONSIGNE 21. Cartographiez la part batie 2025 par region. Palette
## SEQUENTIELLE perceptuellement uniforme, echelle CONTINUE (aucune classe
## fabriquee), et surtout na.value = "grey85" : UNE REGION SANS DONNEE EST
## GRISE, ELLE N'EST PAS A ZERO. Mentionnez la source en caption.
## Sauvegardez dans "outputs/J09_part_batie_2025.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- PART BATIE 2025
##
## CE QUE LA CARTE CODE. Somme des m2 de toit / superficie, en %. "Part batie"
## au sens GHS-BUILT, non "part urbanisee" au sens demographique.
## CE QUE LES CHOIX TECHNIQUES FONT. Echelle CONTINUE : aucune classe n'est
## fabriquee. Une discretisation en quantiles donnerait cinq classes de deux
## regions ; en intervalles egaux, neuf regions dans la premiere classe. Les
## trois images racontent le MEME TABLEAU autrement.
## CE QUI SE LIT. Contraste ecrasant : Littoral et Centre concentrent
## l'essentiel ; aucune region n'atteint quelques pour cent.
## CE QUI NE SE LIT PAS. C'est une MOYENNE REGIONALE. Le Littoral doit sa
## valeur a Douala. Attribuer a un habitant la caracteristique moyenne de sa
## region est une ERREUR ECOLOGIQUE.
## ----------------------------------------------------------------------

## CONSIGNE 22. Construisez la couche cartographique en partant de la COUCHE
## GEOGRAPHIQUE (regions_2025) et en lui joignant le tableau de changement --
## jamais l'inverse, qui perdrait la geometrie. Verifiez par cat() que le
## nombre de lignes est inchange.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 23. Cartographiez le GAIN en km2 avec une palette DIVERGENTE
## centree sur 0 (le blanc marque l'absence de changement : correct quand zero
## a un sens intrinseque), na.value gris. Sauvegardez en
## "outputs/J09_gain_bati_2015_2025.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 24. Cartographiez la CROISSANCE RELATIVE avec une palette
## SEQUENTIELLE (un taux est positif partout ici, pas de point neutre a
## marquer). Precisez en sous-titre que le gris signifie "taux non calcule,
## bati 2015 sous le seuil declare" -- et NON "pas de croissance".
## Sauvegardez en "outputs/J09_croissance_bati_2015_2025.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DES DEUX CARTES -- GAIN ET CROISSANCE
##
## Les deux cartes ne se ressemblent pas : le Littoral domine les gains et
## disparait des taux. L'ECART ENTRE LES DEUX CARTES EST PLUS INFORMATIF QUE
## CHACUNE : il localise ou un rythme rapide porte sur de petits volumes, et
## ou un rythme modeste porte sur des volumes qui saturent deja les reseaux.
## CE QUI NE SE LIT PAS : ni l'une ni l'autre ne dit POURQUOI. Une croissance
## du bati peut aussi venir d'une amelioration de la DETECTION entre deux
## versions de l'algorithme GHSL -- hypothese rarement enoncee, et reelle.
## ----------------------------------------------------------------------

## CONSIGNE 25. Tracez le nuage bati 2015 (x) contre bati 2025 (y), avec la
## diagonale y = x en pointilles et le nom des regions en etiquette. Mettez
## LES DEUX AXES EN ECHELLE LOGARITHMIQUE.
## POURQUOI LE LOG : sans lui, deux regions ecrasent les huit autres dans un
## coin. Et en echelle log, un ECART VERTICAL CONSTANT A LA DIAGONALE
## represente une CROISSANCE RELATIVE constante, pas un gain absolu constant.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DU NUAGE. Tous les points sont au-dessus de la diagonale :
## GHS-BUILT ne modelise pratiquement pas la demolition. L'alignement est
## serre : dix ans n'ont rebattu aucune carte. ATTENTION : le log COMPRESSE
## VISUELLEMENT LES GRANDS ECARTS -- ne jamais lire un volume sur un axe log.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.4 UNE TYPOLOGIE EN QUATRE PROFILS
## ------------------------------------------------------------------------

## CONSIGNE 26. Calculez les deux medianes (gain, part batie 2025) et
## affichez-les.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 27. Croisez les deux medianes pour construire quatre profils :
## "Croissance forte et tissu dense", "Croissance forte", "Tissu dense",
## "Croissance moderee". Affichez les effectifs par profil, puis le detail
## trie par profil.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 28. Cartographiez la typologie avec une palette QUALITATIVE
## (quatre couleurs sans ordre implicite : les profils ne sont pas
## hierarchises), na.value gris, et une caption rappelant que LES SEUILS SONT
## RELATIFS aux dix regions. Comptez d'abord les regions sans profil affecte.
## Sauvegardez en "outputs/J09_typologie_bati.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- TYPOLOGIE
##
## Les seuils sont les MEDIANES DE L'ECHANTILLON DES DIX REGIONS : par
## construction, cinq au-dessus et cinq en dessous, quelle que soit la
## realite. Refaite sur 58 departements, DES REGIONS CHANGERAIENT DE CASE SANS
## QUE RIEN N'AIT BOUGE SUR LE TERRAIN. La typologie decrit une POSITION
## RELATIVE dans un ensemble, pas une propriete intrinseque.
## CE QUI NE SE LIT PAS : la distance au seuil. Juste au-dessus et tres
## au-dessus portent la meme couleur.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.5 DESCENDRE A L'ADM2 : LE MAUP EN ACTION
## ------------------------------------------------------------------------

## CONSIGNE 29. Refaites resumer_bati() sur cmr2 (cles "GID_2" et "NAME_2")
## pour les deux millesimes.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 30. Refaites la jointure et les indicateurs de changement au
## niveau departemental, avec LE MEME seuil declare. Instrumentez la jointure
## et affichez les 10 plus forts gains absolus, puis les 10 plus fortes
## croissances relatives. Ce ne sont PAS les memes departements.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 31. Construisez un tableau de dispersion comparant les deux
## mailles (ADM1 et ADM2) : effectif, minimum, mediane et maximum de la part
## batie 2025, plus le rapport max / mediane. Affichez-le, puis affichez la
## part batie NATIONALE -- identique dans les deux cas, puisque c'est une
## somme -- et commentez l'ecart des rapports.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## MAUP -- LE PROBLEME DE L'UNITE SPATIALE MODIFIABLE
##
## EFFET D'ECHELLE : le meme bati, agrege sur 10 regions ou 58 departements,
## ne produit pas la meme distribution. Le total national est identique, mais
## tout ce qui decrit la VARIABILITE change. Plus la maille est fine, plus les
## extremes sont extremes, parce que l'agregation grossiere melange dans une
## meme unite un centre-ville et sa brousse environnante.
## EFFET DE ZONAGE : a nombre d'unites constant, redecouper les frontieres
## change aussi les resultats. C'est le mecanisme du redecoupage electoral.
## REGLE : il n'y a pas de "bonne" maille. Choisir celle de la DECISION qu'on
## eclaire, et ECRIRE LA MAILLE SOUS LA CARTE.
## ERREUR ECOLOGIQUE : "le Littoral est bati a X %" n'autorise pas "un
## habitant du Littoral vit dans une zone batie a X %".
## ----------------------------------------------------------------------

## CONSIGNE 32. Cartographiez le gain a l'ADM2, meme palette divergente que la
## carte regionale, na.value gris, caption rappelant que le gris est une
## absence de donnee et JAMAIS un zero. Sauvegardez en
## "outputs/J09_gain_bati_adm2.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI
##
## Le tableau donne un palmares. La carte donne trois choses de plus :
## LA CONTIGUITE (les departements a fort gain forment des grappes -- un bloc
## contigu s'explique par ce que les unites partagent PARCE QU'ELLES SONT
## VOISINES) ; LA FORME DES VIDES (l'Est forestier et le Nord sahelien, deux
## vides d'origines differentes qu'un tableau met cote a cote) ; L'ECART ENTRE
## DEUX MAILLES (ou l'agregation masquait une heterogeneite interne forte).
## ----------------------------------------------------------------------

## CONSIGNE 33. Exportez les trois tableaux en CSV et les deux couches en
## GeoPackage, dans outputs/, avec le prefixe J09_. Listez ensuite les
## fichiers produits.
## RAPPEL : une sortie n'ecrit JAMAIS dans datasets/, qui est un dossier
## d'entrees.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................


## ========================================================================
## MODULE 5 -- CAS REEL : LES INONDATIONS DE YAGOUA, 2024
## ========================================================================
## L'activation Copernicus EMS EMSR772 (GLIDE FL-2024-000162-CMR) porte sur
## les inondations de 2024 dans la region de YAGOUA (Extreme-Nord, plaine du
## Logone). Trois zones tres eloignees : AOI01 Yagoua, AOI02 Makari,
## AOI03 Waza. Produits : areaOfInterestA, floodDepthA, observedEventA,
## imageFootprintA.
##
## ----------------------------------------------------------------------
## UNE DEPENDANCE A VERIFIER AVANT LA SEANCE
##
## Dans le materiel source, l'archive AOI01 n'etait PAS decompressee et le
## fichier floodDepthA de l'AOI01 -- lu par le script formateur d'origine --
## n'existait nulle part sur disque. Ici, les shapefiles sont livres DEJA
## EXTRAITS ET RENOMMES A PLAT dans datasets/, et tous les unzip() ont ete
## supprimes : un dossier de donnees est un dossier d'entrees.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 5.2 LIRE LES COUCHES EMSR772  (lecture fournie)
## ------------------------------------------------------------------------

lire_emsr <- function(chemin, etiquette) {
  if (!file.exists(chemin)) {
    cat("*** ABSENT :", chemin, "***\n")
    return(NULL)
  }
  x <- sf::st_read(chemin, quiet = TRUE)
  n_inv_avant <- sum(!sf::st_is_valid(x))
  x <- sf::st_make_valid(x)
  cat("--- ", etiquette, " ---\n", sep = "")
  cat("  entites   :", nrow(x), "\n")
  cat("  colonnes  :", paste(names(x), collapse = ", "), "\n")
  cat("  CRS       :", sf::st_crs(x)$input, "\n")
  cat("  geometries invalides avant / apres reparation : ",
      n_inv_avant, " / ", sum(!sf::st_is_valid(x)), "\n", sep = "")
  x
}

aoi01_complet <- lire_emsr("datasets/EMSR772_AOI01_areaOfInterestA.shp",
                           "AOI01 -- zone d'interet (emprise officielle)")
flood01_complet <- lire_emsr("datasets/EMSR772_AOI01_floodDepthA.shp",
                             "AOI01 -- profondeurs d'inondation")

## CONSIGNE 34. Calculez la surface de l'AOI01 OFFICIELLE dans crs_mesure et
## affichez-la, avec l'emprise en degres et la localite declaree si la colonne
## existe. C'est ce chiffre qui justifiera la reduction de fenetre.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ------------------------------------------------------------------------
## 5.3 LA FENETRE D'ETUDE : UNE REDUCTION ASSUMEE
## ------------------------------------------------------------------------
## L'AOI01 officielle couvre ~6 870 km2 et contient plus de 400 000 batiments
## a confidence >= 0,7 : trop pour une seance. On reduit a une fenetre ad hoc
## de 5 x 5 km, centree sur le secteur le plus densement inonde.
## CONSEQUENCE, a repeter : TOUS les chiffres des modules 5 a 8 portent sur
## cette fenetre, PAS sur l'AOI01 officielle. Ils ne doivent jamais etre cites
## comme un bilan de l'inondation de Yagoua.

fenetre_zoom <- sf::st_bbox(
  c(xmin = 15.31957, ymin = 10.22218, xmax = 15.36528, ymax = 10.26745),
  crs = sf::st_crs(aoi01_complet)
)

## CONSIGNE 35. Decoupez aoi01_complet sur cette fenetre (st_intersection),
## reparez le resultat, filtrez flood01_complet sur la fenetre obtenue, puis
## calculez la surface retenue dans crs_mesure. Instrumentez : nombre de
## polygones avant/apres pour les deux couches, surface retenue, part de
## l'AOI officielle, CRS conserve.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 36. Affichez la structure de la table floodDepth : les colonnes
## descriptives reellement presentes (utilisez intersect() sur les noms, ne
## supposez rien), puis la table des classes de profondeur avec useNA.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 37. Calculez la surface inondee PAR CLASSE, mesuree en UTM 33N
## (en degres ce chiffre serait faux), avec le nombre de polygones et la part
## de la fenetre. Affichez, puis affichez la surface inondee totale et sa part.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## "CLASSE DE PROFONDEUR" N'EST PAS UNE MESURE IN SITU
##
## Un operateur delimite l'etendue de l'eau sur une image -- le plus souvent
## RADAR Sentinel-1, parce qu'elle traverse les nuages et fonctionne de nuit.
## Puis la hauteur d'eau est ESTIMEE en croisant cette etendue avec un modele
## numerique de terrain. La precision est donc celle du modele de terrain,
## souvent du meme ordre que les classes qu'on pretend distinguer.
## De plus la donnee est DATEE (l'eau visible le jour de l'image), et l'eau
## sous couvert vegetal ou sous les toits est mal detectee. Ces limites
## S'AJOUTENT, et vont toutes dans le sens d'une SOUS-ESTIMATION.
## ----------------------------------------------------------------------

## CONSIGNE 38. Cartographiez la fenetre et les classes de profondeur.
## Palette SEQUENTIELLE sur variable ordinale, polygones SANS bordure (a cette
## echelle, des contours noirs rempliraient l'image). Rappelez en sous-titre
## la surface de la fenetre ET celle de l'AOI officielle. Sauvegardez en
## "outputs/J09_carte_flood_aoi01.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- PROFONDEURS D'INONDATION
##
## Le fond gris clair n'est pas "sec" : c'est "pas detecte comme inonde sur
## l'image utilisee". ATTENTION : la colonne value est du TEXTE ; l'ordre
## alphabetique coincide ici avec l'ordre numerique PAR CHANCE -- verifier ce
## point sur toute autre activation.
## CE QUI SE LIT. L'eau suit un RESEAU, pas une tache : signature d'une
## inondation de plaine alluviale.
## CE QUI NE SE LIT PAS. Ni la duree, ni le courant, ni le nombre de
## personnes. Et surtout, la FORME ETROITE ET DECOUPEE de ces polygones est la
## CAUSE du desaccord des deux methodes du module 7.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 6 -- COMPTER LES EXPOSES : GOOGLE OPEN BUILDINGS
## ========================================================================
## Colonnes principales : latitude/longitude (CENTROIDE), geometry (empreinte
## polygonale), area_in_meters (surface ESTIMEE), confidence (probabilite
## d'etre un batiment, 0 a 1 -- LE PARAMETRE LE PLUS LOURD DE LA JOURNEE).
## Le fichier livre est deja restreint a l'AOI01 officielle + 5 km de marge.
## ------------------------------------------------------------------------

chemin_ob <- "datasets/open_buildings_yagoua.gpkg"

if (file.exists(chemin_ob)) {
  cat("Couches du GeoPackage :\n")
  print(sf::st_layers(chemin_ob))
}

batiments_source <- sf::st_read(chemin_ob, quiet = TRUE)

cat("\n--- Open Buildings (zone de Yagoua) ---\n")
cat("  batiments      :", format(nrow(batiments_source), big.mark = " "), "\n")
cat("  colonnes       :", paste(names(batiments_source), collapse = ", "), "\n")
cat("  CRS            :", sf::st_crs(batiments_source)$input, "\n")
cat("  type geometrie :",
    paste(unique(as.character(sf::st_geometry_type(batiments_source))),
          collapse = ", "), "\n")
print(sf::st_bbox(batiments_source))

## CONSIGNE 39. NE SUPPOSEZ PAS que les colonnes existent : verifiez la
## presence de latitude, longitude, area_in_meters et confidence, et affichez
## le resultat colonne par colonne. Affichez ensuite les 3 premieres lignes
## sans geometrie.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ------------------------------------------------------------------------
## 6.2 LE SEUIL DE CONFIANCE : UN PARAMETRE, PAS UNE DONNEE
## ------------------------------------------------------------------------

## CONSIGNE 40. DECLAREZ le seuil de confiance en variable nommee, une fois,
## en tete de section. Il ne doit JAMAIS etre ecrit en dur au milieu d'un
## filter().

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 41. Si la colonne confidence existe : affichez son resume, puis la
## repartition en trois classes (<0.5 ; 0.5-0.7 ; >=0.7) avec les pourcentages.
## Sinon, affichez un message d'alerte explicite.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 42. Construisez un TABLEAU DE SENSIBILITE : nombre de batiments
## retenus pour des seuils de 0,5 a 0,9, et ecart en % par rapport au seuil de
## reference 0,7. C'est CE tableau qu'il faut montrer, pas le seul chiffre.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## POURQUOI 0,7
##
## SEUIL BAS (0,5) : peu de batiments manques, mais rochers, tas de terre et
## ombres portees passent dans le compte -- et chaque faux positif ajoute cinq
## habitants imaginaires.
## SEUIL HAUT (0,8+) : compte plus sur, mais les constructions petites, en
## materiaux legers ou masquees par des arbres disparaissent -- precisement
## les habitations les plus vulnerables. LE BIAIS N'EST PAS ALEATOIRE : il
## frappe systematiquement les plus pauvres.
## 0,7 est un COMPROMIS CONVENTIONNEL, pas une propriete des donnees. Un
## resultat qui bascule entre 0,65 et 0,75 n'est pas un resultat.
## ----------------------------------------------------------------------

## CONSIGNE 43. Harmonisez les CRS AVANT le filtre spatial, et AFFICHEZ la
## decision (transformation faite, ou CRS deja identiques). Puis restreignez
## les batiments a la fenetre et comptez avant/apres.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 44. Appliquez le seuil de confiance (si la colonne existe) et
## affichez le nombre retenu ainsi que sa part.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 45. Reconstruisez la version PONCTUELLE des batiments depuis les
## colonnes longitude/latitude si elles existent, sinon par st_centroid().
## L'ORDRE c(longitude, latitude) EST IMPERATIF : l'inverser ne leve aucune
## erreur, cela place simplement les points ailleurs.
## Puis CONTROLEZ : comptez les points qui tombent effectivement dans la
## fenetre et levez une alerte si moins de 90 % y sont. Gardez ceux-la.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ------------------------------------------------------------------------
## 6.3 BATIMENTS TOUCHES ET VENTILATION PAR CLASSE
## ------------------------------------------------------------------------

## CONSIGNE 46. Filtrez les batiments touches par l'inondation (st_filter
## utilise par defaut le predicat st_intersects : un batiment est "touche" si
## son POINT intersecte au moins un polygone). Affichez les effectifs et la
## part touchee.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 47. DECLAREZ l'hypothese d'occupation en variable nommee,
## calculez la population de la fenetre et la population touchee, et
## construisez un TABLEAU DE SENSIBILITE pour 3, 4, 5, 6 et 7 personnes par
## batiment.
## ATTENTION : puisque pop = nb x facteur, la PART de population touchee est
## RIGOUREUSEMENT EGALE a la part de batiments touches. Le facteur s'annule.
## Il n'apporte donc AUCUNE information au pourcentage.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 48. Joignez la classe de profondeur aux batiments touches par
## st_join(). ATTENTION : st_join() peut DUPLIQUER des lignes quand un point
## est a la limite de deux polygones. Comptez AVANT et APRES, affichez le
## nombre de duplications et les appariements sans classe, et dedupliquez si
## necessaire. Puis ventilez par classe (effectif, population estimee, part).

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 49. Construisez le tibble de bilan de l'AOI01 (zone, nombre de
## batiments, nombre touches, part, population estimee, population touchee) et
## affichez-le. Nommez explicitement la zone "AOI01 (fenetre 5x5 km)".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 50. Tracez la ventilation par classe de profondeur (barres,
## effectif en etiquette, palette sequentielle, legende masquee). Sauvegardez
## en "outputs/J09_batiments_par_profondeur.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- VENTILATION PAR CLASSE
##
## Trois decisions techniques determinent ENTIEREMENT ces hauteurs de barres :
## LE SEUIL DE 0,7 (qui est un batiment), LE PREDICAT st_intersects SUR DES
## POINTS (qui est touche -- un batiment dont le toit chevauche l'eau mais
## dont le centroide est dehors compte pour non touche), LA DEDUPLICATION
## apres st_join (quelle classe pour un batiment a cheval).
## CE QUI NE SE LIT PAS : le nombre de personnes, la duree, la VULNERABILITE
## du bati (Open Buildings ne dit rien du materiau). Une classe absente du
## graphique peut signifier "aucun polygone de cette classe dans la fenetre".
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 7 -- DEUX METHODES, DEUX REPONSES
## ========================================================================
## Le moment le plus important de la journee. On confronte l'estimation par
## comptage de batiments a une source INDEPENDANTE : la grille WorldPop 2024.
## ------------------------------------------------------------------------

chemin_worldpop <- "datasets/cmr_pop_2024_CN_100m_R2025A_v1.tif"
worldpop <- terra::rast(chemin_worldpop)

cat("--- Raster WorldPop 2024 (Cameroun, 100 m) ---\n")
print(worldpop)

## CONSIGNE 51. CONTROLEZ le raster avant de vous en servir : resolution, CRS
## (nom ET code EPSG), coordonnees geographiques ou non, taille approximative
## du pixel en metres si le raster est en degres, emprise. Puis VERIFIEZ que
## la fenetre d'etude est bien CONTENUE dans l'emprise du raster -- une
## extraction hors emprise ne leve pas d'erreur, elle renvoie NA ou 0.
## Affichez enfin la population nationale (somme du raster).

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 52. Harmonisez le CRS de la fenetre avec celui du raster, en
## affichant la transformation, puis extrayez la population de la fenetre avec
## exact_extract(..., "sum").

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 53. UNISSEZ les polygones d'inondation avant d'extraire : sans
## union, un habitant situe sous deux polygones qui se recouvrent serait
## compte deux fois. Comptez avant/apres l'union, puis extrayez la population
## en zone inondee et affichez la part.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## CE QUE FAIT exact_extract
##
## terra::extract() par defaut applique LA REGLE DU CENTRE : une cellule
## compte entierement ou pas du tout, selon ou tombe son centre.
## exact_extract() calcule la FRACTION DE SURFACE couverte et pondere.
## L'ECART DEVIENT DECISIF quand les polygones sont ETROITS ET DECOUPES --
## exactement le cas de floodDepth : un couloir de 60 m de large sur une
## grille de 100 m ne contient presque aucun centre de cellule.
## CONTREPARTIE : la ponderation suppose la population UNIFORMEMENT REPARTIE
## DANS CHAQUE CELLULE DE 100 m. C'est faux -- dans une cellule qui contient
## un hameau et un champ, tout le monde est du cote du hameau.
## ----------------------------------------------------------------------

## CONSIGNE 54. TROISIEME METHODE, plus robuste sur des polygones etroits :
## si les geometries des batiments sont polygonales, intersectez-les avec
## l'union des zones inondees EN CRS METRIQUE, et calculez la part de SURFACE
## BATIE inondee. Protegez l'intersection par tryCatch. Comparez le resultat a
## la part obtenue en comptant des centroides.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 55. Construisez le tableau de comparaison des deux methodes
## (population de la fenetre, population en zone inondee, part inondee),
## affichez-le, puis calculez les DEUX ecarts relatifs -- sur la fenetre
## entiere et sur la zone inondee -- et leur RAPPORT. C'est ce rapport qui est
## le resultat du module. Exportez le tableau en
## "outputs/J09_comparaison_methodes_population.csv".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 56. Tracez la comparaison en barres groupees, avec les effectifs
## en etiquette et la legende en bas. Sauvegardez en
## "outputs/J09_comparaison_methodes.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## POURQUOI LES DEUX METHODES DIVERGENT EN ZONE INONDEE
## (le raisonnement central de la journee)
##
## SUR LA FENETRE ENTIERE, ELLES S'ACCORDENT : deux chaines de production
## independantes convergent. C'est le meilleur argument dont on dispose pour
## utiliser le facteur 5 ICI -- et IL NE SE TRANSPORTE PAS AILLEURS.
##
## SUR LA ZONE INONDEE, ELLES DIVERGENT. Ni bug ni erreur de donnees : une
## difference de GEOMETRIE DU COMPTAGE.
##  - "Batiments" demande : LE CENTROIDE TOMBE-T-IL DANS UN POLYGONE ?
##    Question BINAIRE, SUR UN POINT. Les polygones floodDepth sont ETROITS ET
##    DECOUPES : un batiment a moitie dans l'eau compte pour zero.
##  - "WorldPop" demande : QUELLE FRACTION DE SURFACE DE CHAQUE CELLULE CE
##    POLYGONE RECOUVRE-T-IL ? Question CONTINUE, SUR UNE SURFACE.
##
## LES DEUX BIAIS SONT DE SENS OPPOSES. Le comptage de centroides
## SOUS-ESTIME ; l'extraction ponderee SURESTIME (en plaine inondable les
## habitants sont groupes sur les points hauts, pas dans le couloir d'eau).
##
## LA BONNE REPONSE : la question etait mal posee. "Combien de personnes sont
## touchees" suppose une definition de "touche" -- l'eau dans la maison ?
## l'acces coupe ? le champ detruit ? -- et chaque definition appelle une
## geometrie de calcul differente. Le bon rendu final n'est pas un chiffre :
## c'est une FOURCHETTE entre les trois methodes, avec la phrase qui dit ce
## que chacune compte.
## ----------------------------------------------------------------------

## CONSIGNE 57. Recadrez le raster WorldPop sur la fenetre (crop puis mask),
## affichez le nombre de cellules et la somme, puis produisez une carte tmap
## STATIQUE : raster discretise en 6 classes de QUANTILES, contours
## d'inondation en noir, contour de la fenetre en bleu.
## Le mode "view" est interdit dans un document rendu (il embarque toutes les
## geometries dans le HTML).

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- WORLDPOP ET CONTOURS D'INONDATION
##
## La discretisation en QUANTILES maximise le contraste, mais elle FABRIQUE DU
## CONTRASTE la ou il n'y en a peut-etre pas : si la population est presque
## uniforme, les quantiles produiront quand meme six classes bien
## differenciees. Une discretisation en intervalles egaux donnerait une image
## presque uniforme. Les deux sont exactes -- demonstration la plus directe
## qu'UNE CARTE EST UN ARGUMENT, PAS UN CONSTAT.
## CE QUI SE LIT : les cellules les plus peuplees forment un ALIGNEMENT
## D'HABITAT qui ne recoupe qu'en partie les polygones noirs.
## CE QUI NE SE LIT PAS : WorldPop est un MODELE, et il UTILISE LE BATI
## DETECTE COMME COVARIABLE -- les deux methodes comparees NE SONT PAS
## TOTALEMENT INDEPENDANTES. Leur accord est un peu moins probant qu'il n'y
## parait. Il faut le dire.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 8 -- INFRASTRUCTURES : LES ROUTES COUPEES
## ========================================================================
## ----------------------------------------------------------------------
## TROIS CHOSES A SAVOIR SUR OVERPASS
##
## SERVICE PUBLIC GRATUIT A USAGE LIMITE : il repond regulierement 429 ou 504.
## PREVOIR SYSTEMATIQUEMENT UN REPLI LOCAL.
## COUVERTURE TRES HETEROGENE : excellente dans les zones cartographiees lors
## de reponses humanitaires, lacunaire ailleurs. Cette heterogeneite CORRELE
## AVEC L'HISTOIRE DES CRISES.
## LICENCE ODbL : citer OpenStreetMap et ses contributeurs.
## ----------------------------------------------------------------------

bbox01 <- sf::st_bbox(aoi01)
fichier_osm_local <- "datasets/routes_aoi01_yagoua.gpkg"

cat("Emprise interrogee :\n")
print(bbox01)
cat("Copie locale de secours :", fichier_osm_local,
    "-- presente :", file.exists(fichier_osm_local), "\n")

## CONSIGNE 58. Interrogez l'API Overpass pour la cle "highway" sur cette
## emprise, DANS UN tryCatch : bornez la tentative a 30 secondes avec
## setTimeLimit(elapsed = 30, transient = TRUE), et en cas d'echec basculez
## sur la copie locale (si elle existe). Remettez la limite a Inf dans le
## bloc finally.
## POURQUOI LA LIMITE : sans elle, osmdata reessaie en interne avec des pauses
## de plusieurs minutes, et la seance s'arrete pendant que R attend en
## silence.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 59. Si des routes ont ete recuperees : affichez le nombre de
## segments, le CRS, le nombre de colonnes et la repartition par type
## (highway) avec useNA.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 60. Harmonisez les CRS (en affichant la decision), filtrez les
## routes de la fenetre, puis REPROJETEZ EN CRS METRIQUE avant de calculer les
## longueurs. Affichez la longueur totale et la densite routiere en km/km2.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 61. Croisez les routes avec l'union des zones inondees par
## st_intersection(), puis st_collection_extract("LINESTRING"), et recalculez
## les longueurs. Protegez par tryCatch. Instrumentez : segments entrants et
## sortants -- le nombre peut AUGMENTER, une route traversant deux polygones
## etant decoupee en plusieurs troncons.
## POURQUOI PAS st_filter : il garderait la route ENTIERE (8 km comptes pour
## 200 m d'inondation). Correct pour un batiment, faux pour une ligne.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 62. Affichez la longueur inondee, la part du reseau, puis le
## detail par type de route (nombre de troncons et longueur). Exportez en
## "outputs/J09_routes_inondees_osm_aoi01.csv".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 63. Cartographiez le reseau et les troncons inondes. Tracez les
## troncons inondes PLUS EPAIS que le reste : une difference d'epaisseur, et
## pas seulement de couleur, reste lisible en noir et blanc et pour un lecteur
## daltonien. Sauvegardez en "outputs/J09_routes_inondees.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- ROUTES ET TRONCONS INONDES
##
## CE QUI SE LIT. Les coupures se concentrent la ou une route franchit une
## depression. Une seule coupure au bon endroit isole tout un secteur :
## l'information operationnelle est TOPOLOGIQUE, pas metrique.
## CE QUI NE SE LIT PAS -- MAJEUR. La carte dit quelle LONGUEUR est sous
## l'eau, pas quelle CONNECTIVITE est perdue. 0,5 km coupe sur un axe unique
## isole un village ; 3 km sur un maillage dense ne coupent rien. Et une route
## absente d'OSM n'apparaitra jamais comme coupee : LE NON-CARTOGRAPHIE EST
## INVISIBLE, PAS NUL.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 9 -- GENERALISER : UNE FONCTION, TROIS ZONES
## ========================================================================
## Le principe DRY : une seule definition, plusieurs applications.
## ATTENTION : donnez a votre fonction des CHEMINS EXPLICITES, pas un
## repertoire a explorer par list.files(). Les shapefiles sont a plat dans
## datasets/, donc un list.files() sur "floodDepthA" renverrait les trois
## zones melees et l'indice [1] en choisirait une au hasard de l'ordre
## alphabetique. C'est un piege classique des chemins a plat.
## ------------------------------------------------------------------------

## CONSIGNE 64. Ecrivez analyser_inondation(chemin_aoi, chemin_flood,
## batiments_sf, zone_id, pers_par_bat) :
##   (a) si un fichier manque, renvoyer une ligne de NA avec une colonne
##       couverture_batiments explicite -- ne jamais renvoyer de zeros ;
##   (b) lire les deux couches et les REPARER (st_make_valid) ;
##   (c) instrumenter : entites, CRS, surface de l'AOI en UTM 33N ;
##   (d) harmoniser les CRS des batiments AVANT le filtre ;
##   (e) filtrer les batiments de la zone, puis ceux touches ;
##   (f) GARDE-FOU : si aucun batiment, ne PAS calculer 0/0 (= NaN) et ne PAS
##       renvoyer 0 -- declarer "non couverte". Declarer aussi un seuil
##       minimal d'observations (par exemple 50) en dessous duquel le resultat
##       n'est pas interpretable ;
##   (g) renvoyer un tibble avec la colonne couverture_batiments.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## CONSIGNE 65. Appliquez la fonction a AOI02 et AOI03, ajoutez la ligne
## AOI01 (avec sa colonne de couverture), empilez le tout, affichez et
## exportez en "outputs/J09_bilan_trois_zones.csv".
## AUCUN unzip() : les shapefiles sont livres deja extraits et renommes.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LE PIEGE DE CE MODULE
##
## La fonction est correcte, et pourtant deux des trois lignes ne veulent rien
## dire. La couche open_buildings_yagoua.gpkg ne retient que les batiments
## dans AOI01 PLUS 5 KM DE MARGE. Or Yagoua, Makari et Waza sont distants de
## ~300 km : LA COUCHE NE COUVRE PAS AOI02 NI AOI03.
##
## SANS GARDE-FOU : nrow(bat_aoi) vaut 0, 100 * 0 / 0 renvoie NaN, et 0 * 5
## renvoie une population de 0. Le tableau afficherait "0 batiment touche, 0
## personne" pour deux zones REELLEMENT INONDEES en 2024, sans lever d'erreur.
## C'est L'ABSENCE SILENCIEUSE sous sa forme la plus dangereuse : UN ZERO QUI
## RESSEMBLE A UNE MESURE.
##
## REGLE : une unite sans observation reste SANS DONNEE -- grise sur une
## carte, NA dans un tableau, jamais zero. Le seuil en dessous duquel on
## refuse d'interpreter est DECLARE DANS LE CODE.
## ----------------------------------------------------------------------

## CONSIGNE 66. Ne tracez QUE les zones effectivement couvertes : filtrez sur
## la colonne de couverture, affichez le nombre de zones tracables et LE NOM
## des zones ecartees, puis tracez les barres groupees (total / touches).
## Barres COTE A COTE et non empilees : empiler "touches" sur "total"
## compterait deux fois les memes batiments.
## Sauvegardez en "outputs/J09_bilan_zones.png".

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J09_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- BILAN PAR ZONE
##
## Les zones non couvertes sont ABSENTES du graphique, et le cat() au-dessus
## les nomme : les afficher a zero aurait produit une affirmation fausse.
## CE QUI NE SE LIT PAS : toute comparaison entre zones, puisqu'une seule est
## documentee. Et le total n'est pas un bilan de l'inondation de Yagoua.
## ----------------------------------------------------------------------


## ========================================================================
## FIN DE JOURNEE
## ========================================================================
## Le glossaire par domaine, le recapitulatif des fonctions cles, les huit
## exercices et les prolongements vers le J10 et le J11 sont dans
## demo_formateur_J09.qmd, section "Fin de journee".
##
## LES CHIFFRES A NE PAS CITER HORS CONTEXTE :
##  - batiments et population de la fenetre AOI01 -> fenetre ad hoc ~5x5 km ;
##  - population estimee (x 5) -> hypothese d'occupation non calibree ;
##  - part de batiments touches -> depend du seuil 0,7 ET du predicat ;
##  - longueur de route inondee -> depend de la completude d'OSM ;
##  - gain de bati 2015-2025 -> depend de la symetrie des tuiles ;
##  - croissance relative -> seuil de bati initial declare ;
##  - AOI02 et AOI03 -> non couvertes : leurs zeros ne sont pas des mesures.
## ========================================================================

cat("=== Fin de la journee J09 ===\n")
cat("Fichiers produits dans outputs/ :\n")
sorties <- list.files("outputs", pattern = "^J09_")
if (length(sorties)) cat(paste0("  ", sorties), sep = "\n") else
  cat("  (aucun -- verifier que les donnees sont bien dans datasets/)\n")
