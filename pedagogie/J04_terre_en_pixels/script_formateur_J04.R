## ============================================================================
## PROGRAMME DE FORMATION R -- DONNEES SPATIALES, ANALYSE ET MANIPULATION DANS R
## J04 -- LA TERRE EN PIXELS : LES DONNEES D'OBSERVATION CONTINUE
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Jeudi 30 juillet 2026
## Referents : M. Teda, R. Dzita -- Support : R. Elandi
##
## CE FICHIER EST LE MIROIR DE demo_formateur_J04.qmd : meme code, meme ordre,
## memes commentaires. Toute correction faite ici doit l'etre aussi dans le
## .qmd, et inversement.
##
## Donnees : datasets/ (chemins relatifs). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
## ============================================================================

## --- Se placer dans le dossier de la journee --------------------------------
## Tous les chemins de ce script sont relatifs a CE dossier. Quarto s'y place
## automatiquement au rendu ; Rscript, non. On le fait donc explicitement, que
## le script soit lance depuis le dossier du jour, depuis pedagogie/ ou depuis
## la racine du projet.
.dossier_jour <- "J04_terre_en_pixels"
if (!dir.exists("datasets")) {
  for (.p in c(.dossier_jour,
               file.path("pedagogie", .dossier_jour))) {
    if (dir.exists(file.path(.p, "datasets"))) { setwd(.p); break }
  }
}
if (!dir.exists("datasets"))
  stop("Dossier datasets/ introuvable. Ouvrez atelier-r-spatial-iford-2026.Rproj, ",
       "lancez source('outils/distribuer_donnees.R'), puis relancez ce script.")
cat("Dossier de travail :", getwd(), "

")

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)

## ----------------------------------------------------------------------
## Comment utiliser ce script
##
## Executez-le section par section (Ctrl+Entree sous RStudio), en verifiant
## chaque sortie avant de passer a la suivante. Ce dossier est autonome :
## donnees dans datasets/, sorties dans outputs/, chemins relatifs.
##
## Prealable, une seule fois : source("install_packages_day.R")
## ----------------------------------------------------------------------

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)


## ========================================================================
## 1. MISE EN PLACE
## ========================================================================
## L'installation se fait une seule fois, via install_packages_day.R. Le bloc
## ci-dessous n'est là qu'à titre de référence — il n'est pas exécuté.
##
## --- BLOC DE REFERENCE, NON EXECUTE ---
# # BLOC DE REFERENCE, NON EXECUTE.
# # L'installation reelle : source("install_packages_day.R")
# install.packages(c("terra", "sf", "tidyverse", "haven", "readxl",
#                    "RColorBrewer", "viridis", "classInt",
#                    "exactextractr", "tmap"))

library(terra)        # LE package raster moderne
library(sf)           # donnees vecteur (vu au J03)
library(tidyverse)    # dplyr, ggplot2, readr...
library(haven)        # lecture SPSS (.sav) pour les donnees EDS
library(RColorBrewer) # palettes cartographiques
library(viridis)      # palettes perceptuellement uniformes
library(classInt)     # discretisation (Jenks, quantiles...)
library(exactextractr)# extraction raster par polygone, precise sur les bords
library(tmap)         # cartographie thematique

## POURQUOI PAS library(raster) ?
## Le paquet 'raster' est l'ancetre de 'terra', du meme auteur. Il fonctionne
## encore, mais il masque des dizaines de fonctions de terra portant le meme
## nom -- extract(), crop(), area()... -- et l'on ne sait plus laquelle on
## appelle. On s'en tient a terra, et on ne charge 'raster' nulle part.

options(scipen = 999)              # pas de notation scientifique
terra::terraOptions(progress = 0)  # pas de barre de progression

cat("terra :", as.character(packageVersion("terra")), "(1.7 minimum)\n")

## ----------------------------------------------------------------------
## Où ce document cherche-t-il ses fichiers ?
##
## Tous les chemins sont relatifs à ce dossier : datasets/ pour les entrées,
## outputs/ pour les sorties. Quarto s'y place automatiquement au rendu.
##
## Nul besoin de setwd() — et c'est même à proscrire : un chemin absolu du
## type C:/Formation_GeoR/… casse dès qu'on change de poste, ce qui est
## précisément ce qu'on cherche à éviter en travaillant par projet RStudio.
##
## ----------------------------------------------------------------------


## ========================================================================
## 2.1 COMPRENDRE LES DONNÉES SENTINEL-2 AVANT DE LES OUVRIR
## ========================================================================
#Sentinel-2 est un satellite de l'Agence Spatiale Européenne (ESA) qui acquiert des images multibandes à haute résolution. Voici les bandes qui nous intéressent aujourd'hui 


## ========================================================================
## 2.2 CHARGEMENT DES RASTERS SENTINEL-2
## ========================================================================
# Données réelles du 26 juin 2026 pour le Cameroun

# --- Chemins vers les fichiers (adaptez à votre dossier) ---
chemin_b08 <- "datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B08_(Raw).tiff"
chemin_b11 <- "datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B11_(Raw).tiff"
chemin_rgb <- "datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_True_color.tiff"

# --- Chargement avec terra::rast() ---
b08 <- terra::rast(chemin_b08)  # Bande NIR (Proche Infrarouge)
b11 <- terra::rast(chemin_b11)  # Bande SWIR
rgb <- terra::rast(chemin_rgb)  # Image True Color (3 couches : R, G, B)

# --- Vérification immédiate ---
cat("=== BANDE B08 (NIR) ===\n")
print(b08)

cat("\n=== BANDE B11 (SWIR) ===\n")
print(b11)

cat("\n=== IMAGE TRUE COLOR ===\n")
print(rgb)
# Exemple de sortie pour b08 :
# class       : SpatRaster
# dimensions  : 2743, 3421, 1  (nrow, ncol, nlyr) — lignes, colonnes, couches
# resolution  : 0.0000899, 0.0000899  (x, y) — en degrés (WGS84)
# extent      : 8.4956, 8.8032, 3.8611, 4.1078  (xmin, xmax, ymin, ymax)
# coord. ref. : WGS 84 (EPSG:4326)
# source      : ...B08_(Raw).tiff
# name        : 2026-06-26..._B08_(Raw)
# min value   : 0
# max value   : 8943

## Décoder ce que terra vous annonce.
##
## | Ligne affichée | Ce qu'elle signifie |
## | dimensions | lignes × colonnes × couches — le nombre de pixels |
## | resolution | la taille d'un pixel au sol, dans l'unité du CRS |
## | extent | l'emprise : les quatre bords de l'image |
## | coord. ref. | le système de coordonnées |
## | min/max values | la plage des valeurs mesurées |
##
## La résolution est la notion qui change tout. À 10 m, un pixel couvre une
## maison ; à 1 km, il couvre un quartier entier. Elle fixe ce qu'on peut
## voir — et ce qu'on ne verra jamais, quel que soit le traitement appliqué
## ensuite.
##
## Attention à ce que la sortie affiche réellement : notre tuile est en
## degrés, avec une résolution d'environ 0,0013° — soit à peu près 150 m, et
## non les 10 m natifs de Sentinel-2. Elle a été rééchantillonnée au
## téléchargement. Le constater dès l'ouverture évite d'annoncer une
## précision qu'on n'a pas.
##
## Regardez aussi la plage de valeurs. Une bande Sentinel-2 brute monte à
## plusieurs milliers : ce ne sont pas des couleurs, ce sont des mesures de
## réflectance codées en entiers. C'est précisément pour cela qu'on ne peut
## pas les mélanger avec une image visuelle bornée à 255 — le point sur
## lequel bute la section 4.1.
##

## ========================================================================
## 2.3 EXPLORATION COMPLÈTE DES MÉTADONNÉES RASTER
## ========================================================================
# --- Dimensions spatiales ---
cat("Nombre de lignes     :", nrow(b08), "\n")
cat("Nombre de colonnes   :", ncol(b08), "\n")
cat("Nombre de couches    :", nlyr(b08), "\n")
cat("Nombre total pixels  :", ncell(b08), "\n")

# --- Résolution spatiale ---
res_b08 <- res(b08)
cat("Résolution X (long.) :", res_b08[1], "degrés", "\n")
cat("Résolution Y (lat.)  :", res_b08[2], "degrés", "\n")
cat("Taille approx. pixel :", round(res_b08[1] * 111320, 0), "m à l'équateur\n")

# --- Emprise géographique ---
emprise <- ext(b08)
cat("Longitude min :", xmin(b08), "  max :", xmax(b08), "\n")
cat("Latitude  min :", ymin(b08), "  max :", ymax(b08), "\n")

# --- Système de coordonnées ---
cat("CRS de B08 :", crs(b08, describe = TRUE)$name, "\n")
cat("EPSG code  :", crs(b08, describe = TRUE)$code, "\n")

# --- Statistiques des valeurs ---
stats_b08 <- terra::global(b08, fun = c("min", "max", "mean", "sd"), na.rm = TRUE)
print(stats_b08)

# --- Nombre de pixels sans données ---
nb_na <- terra::global(b08, fun = "isNA")
cat("Pixels NA (no-data) :", nb_na$isNA, "sur", ncell(b08), "\n")
cat("Proportion NA       :", round(nb_na$isNA / ncell(b08) * 100, 2), "%\n")

# --- Comparaison des propriétés B08 vs B11 ---
cat("\n--- Comparaison résolutions ---\n")
cat("B08 (NIR)  :", nrow(b08), "x", ncol(b08), "| résolution ≈", round(res(b08)[1]*111320,0), "m\n")
cat("B11 (SWIR) :", nrow(b11), "x", ncol(b11), "| résolution ≈", round(res(b11)[1]*111320,0), "m\n")


## ========================================================================
## 2.4 VISUALISATION DES IMAGES
## ========================================================================
# --- Visualisation rapide avec terra::plot() ---
# Bande NIR seule — palette de gris par défaut
terra::plot(b08,
            main = "Bande B08 — Proche Infrarouge (NIR) — 26 juin 2026",
            col  = gray.colors(256),
            axes = TRUE)

# --- Bande B11 avec palette viridis ---

# --- Visualisation rapide avec terra::plot() ---
# Bande NIR seule — palette de gris par défaut
terra::plot(b08,
            main = "Bande B08 — Proche Infrarouge (NIR) — 26 juin 2026",
            col  = gray.colors(256),
            axes = TRUE)

# --- Bande B11 avec palette viridis ---
terra::plot(b11,
            main = "Bande B11 — SWIR — 26 juin 2026",
            col  = viridis::viridis(256, option = "plasma"),
            axes = TRUE)

# --- Image True Color (composition R-G-B) ---
# Pour afficher une image couleur, on indique les numéros de couche (1=R, 2=G, 3=B)
terra::plotRGB(rgb,
               r = 1, g = 2, b = 3,   # R=couche1, G=couche2, B=couche3
               scale = 255,            # valeurs de 0 à 255
               stretch = "lin",        # étirement linéaire (améliore le contraste)
               main = "Composition True Color — Sentinel-2 — 26 juin 2026")

# --- Alternative : étirement histogramme (souvent meilleur pour Sentinel-2) ---
terra::plotRGB(rgb,
               r = 1, g = 2, b = 3,
               stretch = "hist",
               main = "True Color avec étirement histogramme")

# --- Panneau multi-vues : 1 ligne, 3 colonnes ---
par(mfrow = c(1, 3))
terra::plot(b08, main = "B08 - NIR",  col = gray.colors(256), legend = FALSE)
terra::plot(b11, main = "B11 - SWIR", col = viridis::magma(256), legend = FALSE)
terra::plotRGB(rgb, r=1, g=2, b=3, stretch="lin", main = "True Color")
par(mfrow = c(1, 1))  # Remettre à 1 seule fenêtre


## ========================================================================
## 2.5 CHARGEMENT DES DONNÉES VECTORIELLES GADM (FRONTIÈRES CAMEROUN)
## ========================================================================
# GADM v4.1 fournit 4 niveaux pour le Cameroun :
#   Niveau 0 : pays (1 polygone)
#   Niveau 1 : régions (10 polygones)
#   Niveau 2 : départements (58 polygones)

# --- Chargement avec sf ---
cam_pays <- sf::st_read("datasets/gadm41_CMR_0.shp", quiet = TRUE)
cam_regions <- sf::st_read("datasets/gadm41_CMR_1.shp", quiet = TRUE)
cam_depts   <- sf::st_read("datasets/gadm41_CMR_2.shp", quiet = TRUE)

# --- Inspection rapide ---
cat("Pays     :", nrow(cam_pays), "entité  | Colonnes :", ncol(cam_pays), "\n")
cat("Régions  :", nrow(cam_regions), "entités | Colonnes :", ncol(cam_regions), "\n")
cat("Dépt.    :", nrow(cam_depts), "entités | Colonnes :", ncol(cam_depts), "\n")

# Aperçu des colonnes disponibles
names(cam_depts)
# [1] "GID_0" "NAME_0" "GID_1" "NAME_1" "GID_2" "NAME_2" "VARNAME_2"
#     "NL_NAME_2" "TYPE_2" "ENGTYPE_2" "CC_2" "HASC_2" "geometry"

# --- Carte rapide de contrôle ---
par(mfrow = c(1, 2))
plot(sf::st_geometry(cam_regions), main = "Régions (N=10)",
     col = RColorBrewer::brewer.pal(10, "Set3"), border = "white")
plot(sf::st_geometry(cam_depts), main = "Départements (N=58)",
     col  = "#D6E4F0", border = "grey40")
par(mfrow = c(1, 1))

# --- Vérification du CRS ---
cat("CRS GADM :", sf::st_crs(cam_pays)$epsg, "\n")
# Doit être 4326 (WGS84) — même projection que nos rasters Sentinel-2


## ========================================================================
## 3.1 DÉCOUPE (CROP) : RÉDUIRE L'EMPRISE SPATIALE
## ========================================================================
#La découpe (crop) réduit l'emprise d'un raster à un rectangle englobant une zone d'intérêt. C'est la première opération à faire pour alléger les fichiers avant tout traitement.

# Objectif : isoler une région spécifique du Cameroun

# --- Exemple 1 : Découpe sur le département du Mfoundi (Yaoundé) ---
# Isolons d'abord le département Mfoundi dans les données GADM
mfoundi <- cam_depts[cam_depts$NAME_2 == "Mfoundi", ]
cat("Département sélectionné :", mfoundi$NAME_2, "(", mfoundi$NAME_1, ")\n")

# --- Crop de la bande B08 sur l'emprise de Mfoundi ---
# terra accepte un objet sf directement !
b08_mfoundi <- terra::crop(b08, mfoundi)
cat("Taille AVANT découpe :", ncell(b08), "pixels\n")
cat("Taille APRÈS découpe :", ncell(b08_mfoundi), "pixels\n")

# --- Visualisation de la découpe ---
terra::plot(b08_mfoundi,
            main = "B08 NIR — Mfoundi (Yaoundé)",
            col  = viridis::viridis(256))
plot(sf::st_geometry(mfoundi), add = TRUE, border = "red", lwd = 2)

# --- Exemple 2 : Découpe de toutes les bandes en une fois ---
# Très utile pour préparer un empilage (stack) cohérent
rgb_mfoundi <- terra::crop(rgb, mfoundi)
terra::plotRGB(rgb_mfoundi, r=1, g=2, b=3, stretch="lin",
               main = "True Color — Mfoundi (Yaoundé)")
plot(sf::st_geometry(mfoundi), add = TRUE, border = "yellow", lwd = 2)

# --- Exemple 3 : decoupe par emprise personnalisee --------------------------
# PREMIER REFLEXE : savoir OU se trouve l'image avant de vouloir la decouper.
cat("Emprise de b08 :\n"); print(terra::ext(b08))
cat("CRS de b08     :", terra::crs(b08, describe = TRUE)$name, "\n")

## ----------------------------------------------------------------------
## Ne jamais coder une emprise en dur sans la confronter à l'image
##
## Une version antérieure de ce support zoomait sur Douala — emprise ext(9.3,
## 10.2, 3.7, 4.5) — en annonçant reprojeter « dans le CRS de b08, UTM 32N ».
## Deux affirmations fausses, et un plantage à la clé :
##
## | Affirmé | Réalité |
## | CRS du raster : UTM 32N | WGS 84 (EPSG:4326), en degrés |
## | Zone couverte : Littoral, Douala | 11,5° à 14,9° E — le sud-est du pays |
## | Résolution : 10 m | ≈ 0,0013° soit environ 150 m |
##
## L'emprise de Douala ne recoupe tout simplement pas l'image, d'où l'erreur
## [crop] extents do not overlap. La tuile fournie couvre l'Est et le Sud —
## région de Yokadouma, bassin de la Boumba.
##
## La parade : dériver la fenêtre de zoom de l'emprise réelle du raster,
## plutôt que de la saisir à la main. Le code s'adapte alors à n'importe
## quelle tuile.
##
## ----------------------------------------------------------------------

# --- Fenetre de zoom derivee de l'image elle-meme ---------------------------
e <- terra::ext(b08)
larg <- (e$xmax - e$xmin) / 4      # un quart de la largeur
haut <- (e$ymax - e$ymin) / 4      # un quart de la hauteur
cx <- (e$xmin + e$xmax) / 2        # centre de l'image
cy <- (e$ymin + e$ymax) / 2

zone_zoom <- terra::ext(cx - larg, cx + larg, cy - haut, cy + haut)
b08_zoom  <- terra::crop(b08, zone_zoom)

cat("Zoom :", ncol(b08_zoom), "x", nrow(b08_zoom), "pixels",
    "sur", ncol(b08), "x", nrow(b08), "\n")

terra::plot(b08_zoom,
            main = "B08 (NIR) — quart central de la tuile, sud-est du Cameroun",
            col  = gray.colors(256))

# --- Et si l'emprise voulue etait dans un AUTRE CRS ? -----------------------
# Le cas general : on dispose de coordonnees en degres, le raster est projete
# (ou l'inverse). On ne compare jamais deux emprises de CRS differents.
#
# La bonne sequence : construire un POLYGONE, le reprojeter, puis decouper.
# terra::ext() seul ne porte aucun CRS -- c'est la source de l'erreur classique.
emprise_poly     <- terra::as.polygons(zone_zoom, crs = "EPSG:4326")
emprise_projetee <- terra::project(emprise_poly, terra::crs(b08))
b08_zoom2        <- terra::crop(b08, emprise_projetee)

cat("Meme resultat par les deux voies ?",
    all(dim(b08_zoom) == dim(b08_zoom2)), "\n")
# Ici les deux CRS coincident, donc oui. Le detour reste la methode sure des
# que les CRS different.


## ========================================================================
## 3.2 MASQUE (MASK) : CONSERVATION DE LA FORME RÉELLE D'UN POLYGONE
## ========================================================================
# Après crop (rectangulaire), mask suit exactement les contours du polygone

# --- Mask de B08 sur le département Mfoundi ---

b08_crop <- terra::crop(b08, mfoundi)

b08_mask <- terra::mask(b08_crop, terra::vect(mfoundi))
# Note : terra::mask() attend un SpatVector, pas sf — on convertit avec vect()

# --- Comparaison visuelle crop vs mask ---
par(mfrow = c(1, 2))
terra::plot(b08_crop, main = "Après crop() — forme rectangulaire",
            col = viridis::viridis(256))
plot(sf::st_geometry(mfoundi), add = TRUE, border = "red", lwd = 2)

terra::plot(b08_mask, main = "Après mask() — forme exacte du polygone",
            col = viridis::viridis(256))
plot(sf::st_geometry(mfoundi), add = TRUE, border = "red", lwd = 2)
par(mfrow = c(1, 1))

# --- Mask sur une région entière (exemple : Centre) ---
region_centre <- cam_regions[cam_regions$NAME_1 == "Centre", ]
b08_centre <- terra::crop(b08, region_centre) |>
              terra::mask(terra::vect(region_centre))

terra::plot(b08_centre,
            main = "B08 NIR — Région Centre",
            col  = viridis::magma(256))
plot(sf::st_geometry(region_centre), add = TRUE, border = "white", lwd = 2)

# --- Statistiques sur zone masquée ---
stats_centre <- terra::global(b08_centre, fun = c("mean", "sd", "min", "max"),
                               na.rm = TRUE)
cat("\nStatistiques B08 — Région Centre :\n")
print(stats_centre)

## Pourquoi rééchantillonner. Deux rasters ne se combinent que s'ils
## partagent exactement la même grille : même résolution, même emprise, même
## origine, même CRS. Sentinel-2 fournit B08 à 10 m et B11 à 20 m —
## additionner les deux directement échoue.
##
## resample() reconstruit l'un sur la grille de l'autre. La méthode compte :
##
## - bilinear interpole entre les pixels voisins. C'est le bon choix pour une
## grandeur continue — réflectance, température, altitude. - near (plus
## proche voisin) recopie la valeur du pixel le plus proche. Obligatoire pour
## une variable catégorielle — un code d'occupation du sol : interpoler entre
## « forêt » (3) et « eau » (5) donnerait « 4 », c'est-à-dire rien du tout.
##
## Rééchantillonner n'ajoute jamais d'information. Passer une bande de 20 m à
## 10 m ne révèle aucun détail : cela fabrique quatre pixels là où il y en
## avait un. La précision réelle reste celle de la source la plus grossière —
## et c'est elle qu'il faut annoncer dans une publication.
##
## Le même raisonnement vaut pour notre tuile, déjà ramenée à ~150 m : aucun
## traitement ne lui rendra les 10 m d'origine.
##

## ========================================================================
## 3.3 RÉÉCHANTILLONNAGE (RESAMPLE) : HARMONISER LES RÉSOLUTIONS
## ========================================================================
## Sur les produits Sentinel-2 natifs, B08 est à 10 m et B11 à 20 m : leurs
## grilles sont incompatibles et l'addition échoue.
##
## ----------------------------------------------------------------------
## Dans notre tuile, les deux bandes ont déjà été ramenées à la même grille
## au téléchargement — le code ci-dessous le vérifie et l'affiche. Le
## rééchantillonnage y est donc sans effet, mais le geste reste indispensable
## : sur des bandes brutes, il conditionne tout calcul d'indice. On le
## conserve pour cette raison, et parce qu'il rend la vérification explicite.
##
## ----------------------------------------------------------------------

# Objectif : aligner la grille de B11 sur celle de B08.

# Verification des resolutions AVANT reechantillonnage
cat("Résolution B08 :", res(b08), "\n")
cat("Résolution B11 :", res(b11), "\n")
cat("Dimensions B08 :", dim(b08), "\n")
cat("Dimensions B11 :", dim(b11), "\n")

# --- Rééchantillonnage de B11 vers la grille de B08 ---
# Méthode bilinear : appropriée pour les valeurs de réflectance (données continues)
b11_resample <- terra::resample(b11, b08, method = "bilinear")

# Vérification APRÈS rééchantillonnage
cat("\nAprès rééchantillonnage :\n")
cat("Résolution B11_resample :", res(b11_resample), "\n")
cat("Dimensions B11_resample :", dim(b11_resample), "\n")
cat("Identique a B08 ?", all(dim(b11_resample) == dim(b08)), "\n")

# Les deux grilles etaient-elles deja identiques AVANT l'operation ?
cat("Deja alignees avant reechantillonnage ?",
    all(dim(b11) == dim(b08)) && all(res(b11) == res(b08)), "\n")

# --- Comparaison visuelle avant/après ---
par(mfrow = c(1, 2))
terra::plot(b11,
            main = paste0("B11 original (", nrow(b11), "x", ncol(b11), " pixels)"),
            col = viridis::plasma(256))
terra::plot(b11_resample,
            main = paste0("B11 rééch. (", nrow(b11_resample), "x", ncol(b11_resample), " pixels)"),
            col = viridis::plasma(256))
par(mfrow = c(1, 1))


## ========================================================================
## 3.4 AGRÉGATION : RÉDUIRE LA RÉSOLUTION SPATIALE
## ========================================================================
#L'agrégation consiste à réduire la résolution d'un raster en regroupant des pixels voisins. Utile pour créer des données moins volumineuses ou pour correspondre à des données de moindre résolution.

# Objectif : reduire volontairement la resolution, pour alleger les calculs

# --- Agrégation par facteur 3 : 10m → ~30m ---
b08_30m <- terra::aggregate(b08, fact = 3, fun = "mean", na.rm = TRUE)
cat("10m :", nrow(b08), "x", ncol(b08), "pixels\n")
cat("30m :", nrow(b08_30m), "x", ncol(b08_30m), "pixels\n")
cat("Ratio :", round(ncell(b08) / ncell(b08_30m), 1), "fois moins de pixels\n")

# --- Agrégation par facteur 10 : 10m → ~100m ---
b08_100m <- terra::aggregate(b08, fact = 10, fun = "mean", na.rm = TRUE)
cat("100m :", nrow(b08_100m), "x", ncol(b08_100m), "pixels\n")

# --- Agrégation par facteur 50 : 10m → ~500m (résolution MODIS) ---
b08_500m <- terra::aggregate(b08, fact = 50, fun = "mean", na.rm = TRUE)

# --- Comparaison multi-résolutions ---
par(mfrow = c(2, 2))
terra::plot(b08,      main = "Original 10m",  col = gray.colors(256), legend=FALSE)
terra::plot(b08_30m,  main = "Agrégé 30m",    col = gray.colors(256), legend=FALSE)
terra::plot(b08_100m, main = "Agrégé 100m",   col = gray.colors(256), legend=FALSE)
terra::plot(b08_500m, main = "Agrégé 500m",   col = gray.colors(256), legend=FALSE)
par(mfrow = c(1, 1))

# --- Agrégation avec d'autres fonctions statistiques ---
# Utile pour l'analyse d'occupation du sol (max = classe dominante)
b08_max  <- terra::aggregate(b08, fact = 5, fun = "max")
b08_med  <- terra::aggregate(b08, fact = 5, fun = "median", na.rm = TRUE)


## ========================================================================
## 3.5 EMPILAGE DE COUCHES (STACK) ET ARITHMÉTIQUE RASTER
## ========================================================================
# --- Création d'un stack multi-bandes ---
# On empile B08 et B11_resample (maintenant à la même résolution)
stack_s2 <- c(b08, b11_resample)
names(stack_s2) <- c("NIR_B08", "SWIR_B11")
cat("Stack créé :", nlyr(stack_s2), "couches\n")
print(stack_s2)

# --- Accès aux couches individuelles ---
nir  <- stack_s2[["NIR_B08"]]   # Par nom
swir <- stack_s2[[2]]            # Par index

# --- Normalisation : rapporter les valeurs entre 0 et 1 ---
# Les valeurs Sentinel-2 L2A varient de 0 à 10000
# Diviser par 10000 donne la réflectance réelle (0-1)
nir_ref  <- nir  / 10000
swir_ref <- swir / 10000

cat("Réflectance NIR  — min :", minmax(nir_ref)[1],
    "| max :", minmax(nir_ref)[2], "\n")
cat("Réflectance SWIR — min :", minmax(swir_ref)[1],
    "| max :", minmax(swir_ref)[2], "\n")

# --- Sauvegarde du stack ---
terra::writeRaster(stack_s2,
                   filename  = "outputs/stack_B08_B11_Cameroun.tif",
                   overwrite = TRUE,
                   datatype  = "INT2U")  # Entier non signé 16 bits (économise de l'espace)
cat("Stack sauvegardé.\n")


## ========================================================================
## 4.1 CALCUL DES INDICES SPECTRAUX À PARTIR DES BANDES RÉELLES
## ========================================================================
#Les indices spectraux combinent plusieurs bandes pour mettre en valeur une caractéristique du terrain (végétation, eau, zones brûlées, humidité du sol). Ils sont au cœur de la télédétection appliquée aux statistiques environnementales.


## ========================================================================
## 4.1.1 LE NDVI — ET POURQUOI IL N'EST PAS CALCULABLE ICI
## ========================================================================
## Le NDVI (Normalized Difference Vegetation Index) est l'indice le plus
## connu de la télédétection :
##
## > NDVI = (NIR − Rouge) / (NIR + Rouge) > > soit, pour Sentinel-2 : (B08 −
## B04) / (B08 + B04)
##
## Il repose sur un fait biologique simple : une feuille en bonne santé
## absorbe le rouge pour la photosynthèse et réfléchit massivement le proche
## infrarouge. Plus l'écart entre les deux est grand, plus la végétation est
## dense et active.
##
## ----------------------------------------------------------------------
## Pourquoi ce document ne calcule pas de NDVI
##
## Il faudrait la bande B04 (rouge, en réflectance). Nous ne disposons que de
## B08, B11 et de l'image True_color.
##
## La tentation est d'extraire le rouge de True_color — c'est ce que faisait
## une version antérieure de ce support. C'est faux, et l'erreur mérite
## d'être vue.
##
## | | B08 | True_color |
## | Nature | réflectance mesurée | composition visuelle |
## | Codage | entier 16 bits | entier 8 bits |
## | Plage de valeurs | ≈ 0 à 10 000 | 0 à 255 |
## | Traitement | brut | étiré pour l'œil humain |
##
## Les deux ne sont ni dans la même unité, ni sur la même échelle. Dans la
## fraction, b08 écrase le terme rouge : le résultat vaut presque 1 partout,
## et la grille de lecture habituelle — « au-dessus de 0,6, forêt dense » —
## ne signifie plus rien.
##
## Le calcul ne lèverait aucune erreur. Il produirait une carte plausible et
## fausse, ce qui est pire qu'un plantage.
##
## **Règle générale : ne jamais combiner deux bandes qui n'ont pas subi le
## même traitement radiométrique.** Pour un vrai NDVI, télécharger B04 sur
## Copernicus, même date et même emprise.
##
## ----------------------------------------------------------------------

## Calculons donc l'indice que nos données permettent réellement.
##

## ========================================================================
## 4.1.2 LE NDMI — L'HUMIDITÉ DE LA VÉGÉTATION
## ========================================================================
## B08 et B11 sont toutes deux des bandes de réflectance brute, issues de la
## même chaîne de traitement, dans la même unité et sur la même échelle. Les
## combiner est légitime.
##
## > NDMI = (NIR − SWIR) / (NIR + SWIR) > > soit, pour Sentinel-2 : (B08 −
## B11) / (B08 + B11)
##
## L'eau contenue dans les feuilles absorbe l'infrarouge moyen (B11) et
## laisse passer le proche infrarouge (B08). L'écart mesure donc la teneur en
## eau de la végétation — et non sa densité, que mesurerait le NDVI.
##
# --- Calcul brut -------------------------------------------------------------
# B11 a ete reechantillonne en section 3.3 pour aligner sa grille sur celle de
# B08 : deux rasters ne se combinent que s'ils partagent resolution et emprise.
ndmi_brut <- (b08 - b11_resample) / (b08 + b11_resample)
names(ndmi_brut) <- "NDMI"

cat("NDMI brut  — min :", round(minmax(ndmi_brut)[1], 3),
    "| max :", round(minmax(ndmi_brut)[2], 3), "\n")

# --- PIEGE : les bordures de nodata polluent l'indice ------------------------
# Le calcul brut sort exactement -1 et +1. Ces valeurs ne sont pas des mesures :
# elles apparaissent la ou une bande vaut 0 (bordure de tuile, pixel sans
# donnee). La fraction degenere alors en +/-1.
#
# Consequence pratique : quelques pixels de bord suffisent a etirer l'echelle
# de couleurs sur [-1, 1] et a aplatir toute la carte, ou l'essentiel du signal
# tient en realite entre -0.5 et 0.6.
somme <- b08 + b11_resample
cat("Pixels a somme nulle (nodata) :",
    terra::global(somme == 0, "sum", na.rm = TRUE)[[1]], "\n")

# On les ecarte AVANT de calculer.
ndmi <- terra::ifel(somme == 0, NA, ndmi_brut)
names(ndmi) <- "NDMI"

cat("NDMI nettoye — min :", round(minmax(ndmi)[1], 3),
    "| max :", round(minmax(ndmi)[2], 3), "\n")

# Ou se situe vraiment la masse des valeurs ?
q <- terra::global(ndmi, fun = function(x)
       stats::quantile(x, c(0.01, 0.5, 0.99), na.rm = TRUE))
cat("Centiles 1 / 50 / 99 :", round(unlist(q), 3), "\n")

# Lecture :
#   >  0.3     vegetation bien alimentee en eau, zones humides
#   -0.3 a 0.3 vegetation moderement hydratee
#   < -0.3     vegetation seche, sol nu, bati

# On borne l'echelle sur les centiles, pas sur les extremes : une carte se lit
# sur la masse des valeurs, pas sur ses accidents.
bornes <- as.numeric(unlist(q))[c(1, 3)]
terra::plot(ndmi,
            main  = "NDMI — humidite de la vegetation, 26 juin 2026",
            col   = colorRampPalette(c("#A0522D", "#F5DEB3", "#006994"))(256),
            range = bornes,
            axes  = TRUE)
plot(sf::st_geometry(cam_pays), add = TRUE, border = "black", lwd = 1.5)

## ----------------------------------------------------------------------
## Quatre indices qu'on confond souvent
##
## | Indice | Formule | Ce qu'il mesure | Calculable ici ? |
## | NDMI | (B08 − B11)/(B08 + B11) | eau dans la végétation | oui |
## | NDVI | (B08 − B04)/(B08 + B04) | densité de végétation | non — B04 absente |
## | NDWI (McFeeters) | (B03 − B08)/(B03 + B08) | surfaces en eau | non — B03 absente |
## | NBR | (B08 − B12)/(B08 + B12) | zones brûlées | non — B12 absente |
##
## Une version antérieure de ce support calculait « NDWI » et « NBR » avec
## exactement la même formule que le NDMI, en n'annonçant que des seuils
## différents. Trois noms pour un seul calcul : ce sont bien trois indices
## distincts, qui exigent des bandes différentes.
##
## Le J09, journée télédétection, reprendra ces indices avec un jeu de bandes
## complet.
##
## ----------------------------------------------------------------------


## --- Classer un indice continu ---------------------------------------
## Une carte en dégradé se lit mal quand il faut compter ou comparer.
## Découper l'indice en classes donne une carte catégorielle, plus directe à
## interpréter — au prix d'une perte d'information, et de seuils qu'il faut
## assumer.
##
# terra::classify() prend une matrice a 3 colonnes : de, a, valeur affectee.
ndmi_classes <- terra::classify(ndmi,
  matrix(c(
    -Inf, -0.3, 1,   # tres sec : sol nu, bati, roche
    -0.3,  0.0, 2,   # sec
     0.0,  0.2, 3,   # humidite moderee
     0.2,  0.4, 4,   # humide
     0.4,  Inf, 5    # tres humide : zones inondees, vegetation gorgee d'eau
  ), ncol = 3, byrow = TRUE))

couleurs_ndmi <- c("#A0522D", "#DEB887", "#F5F5DC", "#7FB3D5", "#1A5276")
labels_ndmi   <- c("Tres sec", "Sec", "Modere", "Humide", "Tres humide")

terra::plot(ndmi_classes,
            main   = "NDMI en 5 classes — Cameroun",
            col    = couleurs_ndmi,
            legend = FALSE)
legend("bottomright", legend = labels_ndmi, fill = couleurs_ndmi, cex = 0.8)
plot(sf::st_geometry(cam_regions), add = TRUE, border = "grey30", lwd = 0.8)

terra::writeRaster(ndmi,         "outputs/NDMI_Cameroun_2026-06-26.tif", overwrite = TRUE)
terra::writeRaster(ndmi_classes, "outputs/NDMI_classes_Cameroun.tif",    overwrite = TRUE)
cat("Rasters sauvegardes dans outputs/\n")


## ========================================================================
## 4.2 COMBINAISON RASTER-VECTEUR : EXTRACTION DE STATISTIQUES ZONALES
## ========================================================================
#L'extraction zonale permet de calculer des statistiques raster (moyenne NDMI, somme population) pour chaque unité administrative (polygones). C'est l'opération la plus utile pour les statisticiens des INS : on obtient des indicateurs environnementaux par département ou région.

## Les statistiques zonales, ou comment un raster devient un tableau. C'est
## l'opération qui relie la télédétection à la statistique publique : une
## image de plusieurs millions de pixels se résume en 58 lignes, une par
## département, prêtes à rejoindre n'importe quelle base d'indicateurs.
##
## Les deux méthodes ne donnent pas le même résultat, et c'est normal.
## terra::extract() retient un pixel si son centre tombe dans le polygone :
## un pixel est dedans ou dehors. exact_extract() calcule la fraction de
## chaque pixel réellement couverte et pondère en conséquence.
##
## L'écart est négligeable sur un grand département, sensible sur un petit,
## et important dès que la taille du pixel approche celle de l'unité mesurée.
## Règle pratique : plus les unités sont petites au regard de la résolution,
## plus il faut préférer exact_extract().
##
## La moyenne seule ne suffit d'ailleurs pas. stdev, min et max sont extraits
## en même temps ici, et c'est délibéré : un département à la moyenne modérée
## mais à l'écart-type élevé mélange des zones très sèches et très humides.
## Un chiffre unique l'aurait masqué.
##
# terra::extract() + exactextractr::exact_extract() — deux approches

# --- Méthode 1 : terra::extract() (simple et intégré) ---
ndmi_par_dept <- terra::extract(
  x   = ndmi,
  y   = terra::vect(cam_depts),
  fun = mean,
  na.rm = TRUE,
  ID    = TRUE
)

# Renommer et joindre aux données GADM
names(ndmi_par_dept) <- c("ID", "NDMI_moyen")
cam_depts_ndmi <- cbind(cam_depts, NDMI_moyen = ndmi_par_dept$NDMI_moyen)

cat("Top 5 départements — NDMI le plus élevé (vegetation la mieux hydratee) :\n")
print(head(cam_depts_ndmi[order(-cam_depts_ndmi$NDMI_moyen), 
           c("NAME_1", "NAME_2", "NDMI_moyen")], 5))

cat("\nTop 5 départements — NDMI le plus bas (vegetation la plus seche) :\n")
print(head(cam_depts_ndmi[order(cam_depts_ndmi$NDMI_moyen), 
           c("NAME_1", "NAME_2", "NDMI_moyen")], 5))

# --- Méthode 2 : exactextractr::exact_extract() (plus précis pour les bords) ---
# Prend en compte les pixels partiellement couverts par le polygone
ndmi_exact <- exactextractr::exact_extract(
  x    = ndmi,   # exact_extract() accepte un SpatRaster : plus besoin
                 # de convertir vers l'ancien paquet raster
  y    = cam_depts,
  fun  = c("mean", "median", "stdev", "min", "max"),
  progress = FALSE
)
names(ndmi_exact) <- c("NDMI_moy", "NDMI_med", "NDMI_sd", "NDMI_min", "NDMI_max")

# Jointure avec les informations départementales
cam_depts_stats <- cbind(
  sf::st_drop_geometry(cam_depts[, c("NAME_1", "NAME_2")]),
  ndmi_exact
)

cat("\nStatistiques NDMI par département (extrait) :\n")
print(head(cam_depts_stats[order(-cam_depts_stats$NDMI_moy), ], 10))


## ========================================================================
## 4.3 INTÉGRATION DES DONNÉES DE POPULATION — WORLDPOP
## ========================================================================
# Objectif : calculer NDMI moyen pondéré par la population

# --- Chargement des données de population ---
#pop_data <- readr::read_csv("datasets/CMR_population_v1_0_admin_level2.csv")
#menage_data <- readr::read_csv("datasets/CMR_household_v1_0_admin_level2.csv")
pop_data    <- readxl::read_excel("datasets/CMR_population_v1_0_admin_level2.xlsx")
menage_data <- readxl::read_excel("datasets/CMR_household_v1_0_admin_level2.xlsx")

cat("Structure des donnees de population :\n")
glimpse(pop_data)

# --- PIEGE 1 : les nombres sont stockes en TEXTE dans le fichier Excel -------
# glimpse() ci-dessus le montre : total, lower et upper sont des <chr>, pas des
# <dbl>. Toute arithmetique dessus echouerait ou coercerait en silence.
pop_clean <- pop_data |>
  dplyr::rename_with(tolower) |>
  dplyr::transmute(
    departement = names1,
    pop_total   = as.numeric(total),
    pop_bas     = as.numeric(lower),
    pop_haut    = as.numeric(upper)
  )

menage_clean <- menage_data |>
  dplyr::rename_with(tolower) |>
  dplyr::transmute(departement = names1, menages = as.numeric(total))

cat("\nApres conversion :\n"); glimpse(pop_clean)

# --- PIEGE 2 : les libelles ne concordent pas entre WorldPop et GADM --------
# WorldPop ecrit sans accents ("Benoue", "Nyong et Soo"), GADM avec l'ortho-
# graphe officielle ("Bénoué", "Nyong et So'o"). Une jointure naive perd
# 11 departements sur 58, SANS lever la moindre erreur : left_join() remplit
# avec NA. C'est le meme piege qu'aux J02 et J03.
normaliser <- function(x) {
  x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    tolower() |>
    stringr::str_replace_all("[^a-z ]", " ") |>
    stringr::str_replace_all("\\b(et|de|du|la|le)\\b", " ") |>
    stringr::str_replace_all("\\s+", "")
}

# Verifions d'abord l'ampleur du probleme
essai_naif <- cam_depts_stats |>
  dplyr::left_join(pop_clean, by = c("NAME_2" = "departement"))
cat("\nJointure naive -- departements sans population :",
    sum(is.na(essai_naif$pop_total)), "sur", nrow(essai_naif), "\n")

# --- Jointure sur cle normalisee -------------------------------------------
cam_depts_complet <- cam_depts_stats |>
  dplyr::mutate(cle = normaliser(NAME_2)) |>
  dplyr::left_join(pop_clean    |> dplyr::mutate(cle = normaliser(departement)) |>
                     dplyr::select(-departement), by = "cle") |>
  dplyr::left_join(menage_clean |> dplyr::mutate(cle = normaliser(departement)) |>
                     dplyr::select(-departement), by = "cle")

cat("Apres normalisation -- departements sans population :",
    sum(is.na(cam_depts_complet$pop_total)), "sur",
    nrow(cam_depts_complet), "\n")
# --- NDMI pondere par la population -----------------------------------------
# La moyenne simple traite un departement de 50 000 habitants comme un
# departement d'un million. Ponderer par la population repond a une autre
# question : quelle humidite pour l'habitant MOYEN du pays ?
cam_depts_complet <- cam_depts_complet |>
  dplyr::mutate(
    poids       = pop_total / sum(pop_total, na.rm = TRUE),
    ndmi_pondere = NDMI_moy * poids
  )

ndmi_simple   <- mean(cam_depts_complet$NDMI_moy, na.rm = TRUE)
ndmi_pondere  <- sum(cam_depts_complet$ndmi_pondere, na.rm = TRUE)
cat("NDMI moyen -- par departement :", round(ndmi_simple,  4), "\n")
cat("NDMI moyen -- par habitant    :", round(ndmi_pondere, 4), "\n")
# L'ecart entre les deux mesure la correlation entre humidite et peuplement.

# --- Carte thematique : NDMI moyen par departement ---------------------------
carte_ndmi <- cam_depts |>
  dplyr::left_join(cam_depts_stats, by = c("NAME_1", "NAME_2"))

# plot.sf attend soit UNE couleur, soit autant de couleurs que d'entites.
# Passer 5 couleurs pour 58 departements declenche un avertissement et un
# rendu incoherent : on fournit une fonction de palette, et sf s'en debrouille.
plot(carte_ndmi["NDMI_moy"],
     main    = "NDMI moyen par departement — Cameroun",
     pal     = viridis::viridis,
     nbreaks = 6,
     key.pos = 4)
plot(sf::st_geometry(cam_regions), add = TRUE, border = "white", lwd = 1.5)


## ========================================================================
## 4.4 INTÉGRATION DES DONNÉES DHS GÉOLOCALISÉES
## ========================================================================
# Objectif : associer les valeurs NDMI aux clusters d'enquête DHS

# --- Chargement du shapefile des clusters DHS ---
dhs_geo <- sf::st_read("datasets/CMGE71FL.shp", quiet = TRUE)
cat("Clusters DHS chargés :", nrow(dhs_geo), "\n")
cat("CRS DHS :", sf::st_crs(dhs_geo)$epsg, "\n")

# Aperçu des colonnes
cat("Colonnes :", names(dhs_geo), "\n")

# --- Alignement des CRS ---
if (sf::st_crs(dhs_geo)$epsg != 4326) {
  dhs_geo <- sf::st_transform(dhs_geo, 4326)
  cat("CRS transformé en WGS84 (EPSG:4326)\n")
}

# --- Extraction du NDMI au niveau des clusters DHS ---
# terra::extract() pour données ponctuelles : renvoie la valeur du pixel
ndvi_dhs <- terra::extract(
  x = ndmi,
  y = terra::vect(dhs_geo),
  ID = TRUE
)
names(ndvi_dhs) <- c("ID", "NDMI_cluster")

# Jointure avec les données DHS
dhs_geo_ndvi <- dhs_geo |>
  dplyr::mutate(ID = row_number()) |>
  dplyr::left_join(ndvi_dhs, by = "ID")

cat("\nAperçu NDMI par cluster DHS :\n")
print(summary(dhs_geo_ndvi$NDMI_cluster))

# --- Chargement des données SPSS DHS ---
dhs_women <- haven::read_sav("datasets/CMIR71FL.SAV")
cat("\nDonnées femmes DHS :", nrow(dhs_women), "observations — ",
    ncol(dhs_women), "variables\n")

# Variable cluster pour la jointure (v001 = numéro de cluster dans les données DHS)
dhs_cluster_resume <- dhs_women |>
  dplyr::group_by(V001) |>
  dplyr::summarise(
    nb_femmes      = dplyr::n(),
    age_moyen      = mean(V012, na.rm = TRUE),
    poids_enfant   = mean(`HW2$2`, na.rm = TRUE),   # Poids enfant (si disponible)
  .groups = "drop"
  )

names(dhs_women)
dhs_women$`HW2$2`

# --- Jointure DHS géo + NDMI + données femmes ---
# La variable DHSCLUST dans CMGE71FL.shp correspond à v001 dans CMIR71FL.SAV
dhs_complet <- dhs_geo_ndvi |>
  dplyr::left_join(dhs_cluster_resume, by = c("DHSCLUST" = "V001"))

cat("\nCroisement NDMI-DHS réussi — ", nrow(dhs_complet), "clusters\n")

# --- Visualisation : carte des clusters DHS colorés par NDMI ---
plot(sf::st_geometry(cam_pays), main = "Clusters DHS colorés par NDMI moyen",
     col = "#F0F0F0", border = "grey40")
plot(dhs_geo_ndvi["NDMI_cluster"],
     pch = 16, cex = 0.8,
     pal = viridis::viridis,
     add = TRUE)
plot(sf::st_geometry(cam_regions), add = TRUE, border = "grey40", lwd = 0.7)


## ========================================================================
## VOCABULAIRE DE LA JOURNÉE
## ========================================================================

## --- L'objet raster --------------------------------------------------
## | Terme | Ce que c'est |
## | Raster | une grille régulière de pixels, chacun portant une valeur mesurée |
## | SpatRaster | l'objet raster de terra — l'équivalent de sf pour le vecteur |
## | Résolution | la taille d'un pixel au sol ; fixe ce qu'on peut voir |
## | Emprise (extent) | les quatre bords de l'image |
## | Bande (layer) | une couche de mesure ; une image multispectrale en empile plusieurs |
## | Réflectance | la part de lumière renvoyée par le sol — une mesure, pas une couleur |
##

## --- Les opérations --------------------------------------------------
## | Terme | Ce qu'elle fait | À savoir |
## | crop | découpe sur une emprise rectangulaire | rapide — toujours en premier |
## | mask | met à NA hors d'un polygone | lent — toujours après crop |
## | resample | reconstruit un raster sur la grille d'un autre | bilinear si continu, near si catégoriel |
## | aggregate | regroupe n × n pixels en un seul | réduit la résolution, allège les calculs |
## | classify | découpe une variable continue en classes | les seuils sont un choix, à documenter |
## | extract | statistiques zonales par polygone | pixel dedans/dehors selon son centre |
## | exact_extract | idem, en pondérant les pixels de bord | préférable sur les petites unités |
##

## --- Les indices spectraux -------------------------------------------
## Un indice combine deux bandes sous la forme (A − B) / (A + B). La
## normalisation rend deux images comparables même prises sous des
## éclairements différents.
##
## La condition absolue : les deux bandes doivent avoir subi **le même
## traitement radiométrique**. Mélanger une réflectance brute et une image
## visuelle étirée produit un nombre, jamais un indice.
##

## --- À quoi sert le raster -------------------------------------------
## Le vecteur décrit des objets aux contours nets ; le raster décrit un champ
## continu. D'où quatre usages que le vecteur ne couvre pas :
##
## 1. Mesurer là où personne n'est allé. Une enquête ne couvre que ses
## grappes ; un satellite couvre tout le territoire, y compris les zones
## inaccessibles. 2. Remonter dans le temps. Les archives Sentinel et Landsat
## permettent de comparer deux dates sur la même emprise — impossible avec
## des enquêtes ponctuelles. 3. Produire des covariables environnementales.
## Humidité, température, végétation, altitude : autant de variables
## explicatives disponibles partout, à croiser avec les indicateurs
## démographiques. 4. Descendre sous l'unité administrative. Un raster de
## population à 100 m ne s'arrête pas aux frontières des départements — c'est
## le sujet du J08.
##
## Et la leçon transversale de la journée : **un raster est une mesure, pas
## une image**. Le confondre avec une illustration conduit exactement à
## l'erreur du NDVI de la section 4.1.
##

## ========================================================================
## 5.1 EXERCICES GUIDÉS
## ========================================================================
## À faire en binômes, sur les données réelles de la formation. Chaque binôme
## présente ses résultats en cinq minutes. Comptez dix à quinze minutes par
## exercice.
##
## ----------------------------------------------------------------------
## Avant de choisir une zone d'étude, vérifiez ce que l'image couvre
##
## Notre tuile s'étend de 11,5° à 14,9° de longitude et de **2,5° à 5,8° de
## latitude : elle couvre l'Est et une partie du Sud**, autour de Yokadouma.
##
## Elle ne contient pas l'Adamaoua (au nord de 6°), ni le Littoral, ni le
## Nord, ni l'Ouest. Un crop sur ces régions échouera avec [crop] extents do
## not overlap.
##
## C'est la première vérification de tout travail raster :
## terra::ext(mon_raster), et comparer avec la zone visée.
##
## ----------------------------------------------------------------------

## --- BLOC DE REFERENCE, NON EXECUTE ---
# # ============================================================================
# # EXERCICE 1 -- Humidite de la vegetation dans la region de l'EST
# # ============================================================================
# # a) Isoler la region de l'Est dans cam_regions
# # b) Calculer le NDMI moyen et son ecart-type sur cette region
# # c) Quelle part de la superficie depasse un NDMI de 0.2 ?
# # d) Produire une carte zoomee, frontieres departementales superposees
# 
# # a) Isoler la region  (indice : NAME_1 == "Est")
# # est <- cam_regions[cam_regions$NAME_1 == ___, ]
# 
# # b) Decouper PUIS masquer -- crop d'abord, c'est bien plus rapide
# # ndmi_est <- terra::crop(ndmi, terra::vect(est)) |>
# #             terra::mask(terra::vect(est))
# # stats_est <- terra::global(ndmi_est, fun = c("mean", "sd"), na.rm = TRUE)
# # print(stats_est)
# 
# # c) Proportion de pixels au-dessus du seuil
# # humide     <- ndmi_est > 0.2
# # prop       <- terra::global(humide, "sum", na.rm = TRUE) /
# #               terra::global(!is.na(ndmi_est), "sum")
# # cat("Part de surface humide :", round(prop * 100, 1), "%\n")
# 
# # d) Carte
# # terra::plot(ndmi_est, main = "NDMI — region de l'Est",
# #             col = colorRampPalette(c("#A0522D","#F5DEB3","#006994"))(256))
# # plot(sf::st_geometry(cam_depts[cam_depts$NAME_1 == "Est", ]),
# #      add = TRUE, border = "grey20")
# 
# # ============================================================================
# # EXERCICE 2 -- Comparer plusieurs departements
# # ============================================================================
# # Les regions entierement couvertes par la tuile sont rares : on descend donc
# # au departement. Choisissez-en trois dans l'Est ou le Sud, et produisez :
# #   | Departement | NDMI_moyen | NDMI_sd | Surface_km2 |
# #
# # Verifiez d'abord lesquels sont couverts :
# # couverts <- cam_depts[!is.na(
# #   terra::extract(ndmi, terra::vect(cam_depts), fun = mean, na.rm = TRUE)[, 2]
# # ), c("NAME_1", "NAME_2")]
# # print(sf::st_drop_geometry(couverts))
# #
# # Puis iterez -- boucle for() ou purrr::map_dfr().
# # Attention : mesurer une surface exige un CRS metrique. Projetez avant
# # st_area(), sinon le resultat est en degres carres, sans signification.
# 
# # ============================================================================
# # EXERCICE 3 -- Carte de synthese avec tmap
# # ============================================================================
# # Carte du NDMI moyen par departement, avec titre, legende, echelle, flèche
# # nord, frontieres regionales superposees et grappes EDS en surimpression.

## --- BLOC DE REFERENCE, NON EXECUTE ---
# library(tmap)
# tmap_mode("plot")  # mode statique, pour export
# 
# # Données : carte_ndmi (objet sf avec NDMI_moy, créé en section 4.3)
# 
# # Squelette a completer -- syntaxe tmap 4.
# # Rappel des differences avec tmap 3, que vous croiserez dans du code ancien :
# #   tm_fill("var", palette=, style=, n=)  ->  tm_polygons(fill = "var",
# #       fill.scale = tm_scale_intervals(style =, n =, values =))
# #   tm_layout(title = )                   ->  tm_title()
# #   tm_scale_bar()                        ->  tm_scalebar()
# #
# # ma_carte <-
# #   tm_shape(carte_ndmi) +
# #     tm_polygons(
# #       fill        = "NDMI_moy",
# #       fill.scale  = tm_scale_intervals(style = "quantile", n = 5,
# #                                        values = "brewer.br_bg"),
# #       fill.legend = tm_legend(title = "NDMI moyen"),
# #       col = "white", lwd = 0.3
# #     ) +
# #   tm_shape(cam_regions) +
# #     tm_borders(col = "grey30", lwd = 0.8) +
# #   tm_shape(dhs_geo) +
# #     tm_dots(fill = "#C00000", size = 0.2) +
# #     tm_title("NDMI moyen par departement -- Cameroun") +
# #     tm_scalebar(position = c("left", "bottom")) +
# #     tm_compass(type = "4star", position = c("right", "top")) +
# #     tm_layout(frame = FALSE, legend.outside = TRUE)
# #
# # tmap_save(ma_carte, "outputs/carte_NDMI_Cameroun.png",
# #           dpi = 300, width = 8, height = 10)

