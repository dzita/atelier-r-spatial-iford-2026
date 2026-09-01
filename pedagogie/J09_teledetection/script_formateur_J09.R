## ============================================================================
## PROGRAMME DE FORMATION R -- DONNEES SPATIALES, ANALYSE ET MANIPULATION DANS R
## J09 -- VOIR LE TERRITOIRE DEPUIS L'ESPACE : TELEDETECTION, BATI, INONDATIONS
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Mercredi 5 aout 2026
## Referents : E. Darin, M. Teda, R. Dzita -- Support : R. Elandi
##
## CE FICHIER EST LE MIROIR DE demo_formateur_J09.qmd : meme code, meme ordre.
## Le .qmd est la SOURCE UNIQUE : toute correction se fait la-bas, puis on
## regenere ce script. Ne jamais corriger ce fichier a la main.
##
## Donnees : datasets/ (chemins relatifs, a plat). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
## ============================================================================

## --- Se placer dans le dossier de la journee --------------------------------
## Tous les chemins de ce script sont relatifs a CE dossier. Quarto s'y place
## automatiquement au rendu ; Rscript, non. On le fait donc explicitement, que
## le script soit lance depuis le dossier du jour, depuis pedagogie/ ou depuis
## la racine du projet.
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
## Trois reponses, et elles ne se valent pas :
##   1. On mesure un RAYONNEMENT -- la physique du capteur (modules 1 et 2).
##   2. On mesure un PRODUIT DERIVE fabrique par quelqu'un d'autre --
##      GHS-BUILT, Open Buildings, Copernicus EMS (modules 3 a 9). C'est
##      confortable, et c'est la que se cachent les hypotheses non prises.
##   3. On CROISE deux produits independants et on regarde ou ils divergent.
##      C'est le module 7 : deux methodes defendables, deux reponses.
## ----------------------------------------------------------------------


## ========================================================================
## 0. MISE EN PLACE
## ========================================================================

## L'installation se fait une seule fois, via install_packages_day.R.
##
## --- BLOC DE REFERENCE, NON EXECUTE ---
# install.packages(c("sf", "dplyr", "ggplot2", "tidyr", "readr",
#                    "terra", "exactextractr", "tmap", "osmdata"))

library(sf)            # donnees vectorielles : lecture, CRS, predicats
library(dplyr)         # verbes de manipulation de tableaux
library(ggplot2)       # graphiques et cartes statiques
library(tidyr)         # pivot_longer / pivot_wider
library(readr)         # lecture et ecriture de CSV
library(terra)         # LE package raster moderne
library(exactextractr) # statistiques zonales ponderees par fraction de cellule
library(tmap)          # cartographie thematique -- API version 4
library(osmdata)       # interrogation de l'API Overpass d'OpenStreetMap

options(scipen = 999)
terra::terraOptions(progress = 0)

cat("sf            :", as.character(packageVersion("sf")), "\n")
cat("terra         :", as.character(packageVersion("terra")), "(1.7 minimum)\n")
cat("tmap          :", as.character(packageVersion("tmap")), "(4.0 minimum)\n")
cat("exactextractr :", as.character(packageVersion("exactextractr")), "\n")


## ------------------------------------------------------------------------
## 0.1 DEUX REGLAGES QUI DECIDENT DE LA JUSTESSE DES CHIFFRES
## ------------------------------------------------------------------------

# --- 1. Moteur geometrique -------------------------------------------------
# sf peut calculer sur la sphere (moteur s2, defaut) ou dans le plan (GEOS).
# s2 REFUSE ce que GEOS accepte : sur des shapefiles operationnels produits en
# urgence -- ce qui est exactement le cas des produits Copernicus EMS -- les
# auto-intersections sont frequentes et s2 fait echouer st_intersection().
sf_use_s2(FALSE)
cat("Moteur spherique s2 actif :", sf_use_s2(), "(FALSE = calcul planaire GEOS)\n")

# --- 2. Le CRS dans lequel on MESURE ---------------------------------------
# EPSG:4326 (WGS84) est en DEGRES. Une surface ou une longueur calculee dessus
# n'a aucun sens metrique. Pour le Cameroun : UTM zone 33N, EPSG:32633.
crs_mesure <- 32633
cat("CRS de mesure retenu : EPSG:", crs_mesure, " (UTM 33N, unite = metre)\n", sep = "")

# --- 3. Mode de rendu cartographique ---------------------------------------
# tmap "plot" = image statique. Le mode "view" embarque toutes les geometries
# DANS le HTML produit : quelques Mo deviennent plusieurs dizaines de Mo.
tmap_mode("plot")

## ----------------------------------------------------------------------
## POURQUOI sf_use_s2(FALSE) N'EST PAS UN DETAIL DE CONFORT
##
## Le moteur s2 traite la Terre comme une sphere ; GEOS comme un plan. Un
## polygone dont le contour se recoupe est refuse par s2 et accepte par GEOS.
## Les produits de cartographie rapide -- Copernicus EMS produit ses vecteurs
## en quelques heures apres une catastrophe -- contiennent precisement ce type
## de defaut. Soit on desactive s2 et on repare avec st_make_valid() a la
## lecture, soit st_intersection() s'arrete au milieu de la journee.
##
## CONTREPARTIE : avec s2 desactive, un calcul sur des coordonnees en degres
## devient un calcul planaire sur des degres, c'est-a-dire faux. C'est pour
## cela que "reprojeter avant toute mesure" devient obligatoire, et non plus
## seulement recommande.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## OU CE SCRIPT CHERCHE-T-IL SES FICHIERS ?
##
## Tous les chemins sont relatifs a ce dossier : datasets/ pour les entrees,
## outputs/ pour les sorties. Les fichiers sont A PLAT dans datasets/ : pas de
## sous-dossier GHS-BUILT/, pas de EMSR772_products/, pas de dossier
## "Open Buildings" avec un espace dans son nom. C'est une contrainte de
## l'outil de distribution des donnees, qui repere les litteraux
## datasets/nom_de_fichier par expression reguliere.
## ----------------------------------------------------------------------

# Inventaire de depart : on regarde ce qui est REELLEMENT dans datasets/
# avant d'ecrire la moindre ligne d'analyse.
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
if (length(zip_2015) > 0) cat(paste0("    ", basename(zip_2015)), sep = "\n")
if (length(zip_2025) > 0) cat(paste0("    ", basename(zip_2025)), sep = "\n")

## ----------------------------------------------------------------------
## UN PIEGE DE NOMMAGE A CONNAITRE AVANT LA SALLE
##
## Le materiel source cherchait les tuiles GHS_BUILT_S_E2020 -- un millesime
## qui N'EXISTE PAS dans les donnees livrees. Les archives disponibles sont
## 2015 et 2025. Un list.files() sur un motif introuvable ne leve aucune
## erreur : il renvoie un vecteur de longueur zero, et le mosaic() qui suit
## echoue dix lignes plus loin avec un message qui ne parle pas du vrai
## probleme. Si l'un des deux comptages ci-dessus vaut 0, ARRETEZ-VOUS ICI.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 1 -- CE QU'UN SATELLITE MESURE REELLEMENT
## ========================================================================
## Conserve de la version precedente de la journee, reecrit. Sans ce module,
## la journee n'est plus une journee de teledetection : c'est une journee de
## statistiques zonales sur des produits fabriques par d'autres.
##
## 1.1 DE LA SURFACE AU FICHIER : LA CHAINE COMPLETE
## Un satellite ne photographie pas. Il MESURE une quantite de rayonnement
## electromagnetique, dans un intervalle de longueurs d'onde, pendant un temps
## donne, pour une portion de surface donnee. Tout le reste est reconstruction.
##   Emission     -> angle solaire variable
##   Reflexion    -> LA grandeur d'interet : la reflectance
##   Traversee    -> aerosols, vapeur d'eau, nuages alterent le signal
##   Detection    -> bruit du capteur, saturation
##   Quantification -> 12 bits chez Sentinel-2 ; 8 bits sur une image de visu
##   Correction   -> L1C -> L2A : un MODELE, pas une mesure
##   Livraison    -> un GeoTIFF par bande, parfois reechantillonne
##
## 1.2 LES TROIS RESOLUTIONS -- ET UNE QUATRIEME DONT PERSONNE NE PARLE
##   RESOLUTION SPATIALE   : taille au sol d'un pixel. Fixe ce qu'on pourra
##     voir et ce qu'on ne verra JAMAIS. Aucun algorithme ne recupere
##     l'information qui n'a pas ete acquise.
##   RESOLUTION SPECTRALE  : nombre et largeur des bandes. 13 pour Sentinel-2,
##     plusieurs centaines en hyperspectral. Decide de la capacite a
##     distinguer un toit en tole d'un sol nu lateritique.
##   RESOLUTION TEMPORELLE : delai de revisite. 5 jours (Sentinel-2), 16
##     (Landsat), 1 (MODIS). Decide si l'on peut suivre une inondation -- qui
##     dure une semaine -- ou seulement une deforestation.
##   RESOLUTION RADIOMETRIQUE : nombre de niveaux distinguables. 12 bits =
##     4096 niveaux et une mesure de reflectance ; 8 bits = 256 niveaux et
##     PLUS AUCUNE mesure physique, seulement une apparence pour l'ecran.
##     C'est la quatrieme, celle qu'on oublie, et c'est elle qui piege cette
##     journee.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## 1.3 SIGNATURES SPECTRALES : POURQUOI CA MARCHE
## ------------------------------------------------------------------------

# ATTENTION : valeurs typiques saisies a la main, a but d'illustration.
# Ce n'est PAS une mesure faite sur une image satellite. Aucun chiffre issu
# de ce tableau ne doit etre cite.
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

cat("Nombre de lignes du schema :", nrow(signatures), "\n")
cat("Surfaces representees      :",
    paste(unique(signatures$surface), collapse = ", "), "\n")

print(
  ggplot(signatures,
         aes(x = longueur_onde_nm, y = reflectance,
             colour = surface, shape = surface)) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.6) +
    scale_x_continuous(breaks = c(492, 560, 665, 833, 1610),
                       labels = c("Bleu\n492", "Vert\n560", "Rouge\n665",
                                  "PIR\n833", "SWIR\n1610")) +
    scale_colour_manual(values = c("Vegetation dense" = "#1B7837",
                                   "Sol nu"           = "#B35806",
                                   "Bati dense"       = "#762A83",
                                   "Eau libre"        = "#2166AC")) +
    labs(
      title = "Signatures spectrales typiques (schema pedagogique)",
      subtitle = "Valeurs saisies a la main : illustration du raisonnement, pas une mesure",
      x = "Longueur d'onde (nm) et bande Sentinel-2 correspondante",
      y = "Reflectance (0-1)",
      colour = NULL, shape = NULL
    ) +
    theme_minimal()
)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- SIGNATURES SPECTRALES
##
## CE QUE LA FIGURE CODE. Cinq longueurs d'onde en abscisse, choisies parce
## qu'elles correspondent a cinq bandes Sentinel-2. En ordonnee la
## REFLECTANCE : part du rayonnement incident renvoyee, entre 0 et 1. Une
## couleur = un type de surface. Chaque point est une valeur typique saisie a
## la main, PAS une mesure.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Relier les points par une ligne suggere
## une continuite qui n'existe pas : un capteur multispectral ne mesure qu'aux
## cinq positions marquees, et il integre sur une largeur de bande. L'axe
## vertical part de 0 : une reflectance de 0,01 et une de 0,05 ne sont pas
## "proches", elles sont dans un rapport de 1 a 5.
##
## CE QUI SE LIT. Trois ecarts font le reste de la journee. La vegetation
## s'effondre dans le Rouge (la chlorophylle absorbe) et explose dans le PIR
## (la structure des feuilles diffuse) : c'est le NDVI. Le bati et le sol nu
## montent dans le SWIR ou la vegetation redescend : c'est le NDBI. L'eau
## s'effondre dans le PIR et plus encore dans le SWIR : c'est le MNDWI.
##
## CE QUI NE SE LIT PAS. Le bati dense et le sol nu ont des profils presque
## paralleles -- limite de fond de la detection du bati par indice, et elle
## est physique, pas algorithmique. La figure ne dit rien non plus de la
## variabilite : une "foret" n'a pas une signature, elle en a une
## distribution.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 1.4 OU TROUVER LES IMAGES, GRATUITEMENT
##   Copernicus Data Space  : Sentinel-1/2/3/5P, 10-60 m, compte gratuit
##   USGS EarthExplorer     : Landsat depuis 1972, 30 m, compte gratuit
##   NASA Earthdata         : MODIS, VIIRS, SRTM, GPM, 250 m - 1 km
##   Copernicus EMS         : cartes de crise vectorielles, libre
##   GHSL (Commission eur.) : GHS-BUILT, GHS-POP, GHS-SMOD, libre
##   Google Open Buildings  : empreintes de batiments, CC BY 4.0
##   Google Earth Engine    : catalogue + calcul dans le nuage, quota
##
## DEUX FAMILLES A NE PAS CONFONDRE. Les trois premieres livrent de la DONNEE
## BRUTE : vous portez toute la chaine et toute l'incertitude. Les suivantes
## livrent un PRODUIT DERIVE : quelqu'un a deja fait la chaine, avec ses choix
## et ses seuils. C'est plus rapide, souvent mieux fait -- et plus dangereux,
## parce que les hypotheses ne sont plus dans votre code, elles sont dans une
## documentation que personne n'ouvre. Toute la suite de cette journee
## travaille sur des produits derives : le travail consiste donc, a chaque
## etape, a REMETTRE L'HYPOTHESE DANS LE TEXTE.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## 1.5 OUVRIR UNE IMAGE ET LA CONTROLER : LE CODE DE REFERENCE
## ------------------------------------------------------------------------
## --- BLOC DE REFERENCE, NON EXECUTE ---
## C'est le controle a faire sur TOUTE image, avant tout traitement.
#
# chemin_rouge <- file.path("datasets", "bande_rouge_a_fournir.tif")
# chemin_pir   <- file.path("datasets", "bande_pir_a_fournir.tif")
# b04 <- terra::rast(chemin_rouge)
# b08 <- terra::rast(chemin_pir)
#
# # 1. Emprise, CRS, resolution REELS -- jamais ceux annonces par le fournisseur
# cat("Dimensions      :", dim(b04), "(lignes, colonnes, couches)\n")
# cat("Resolution      :", res(b04), "unites du CRS\n")
# cat("CRS             :", terra::crs(b04, describe = TRUE)$name, "\n")
# print(terra::ext(b04))
#
# # 2. La resolution est-elle en metres ou en degres ?
# if (terra::is.lonlat(b04)) {
#   cat("ATTENTION : raster en coordonnees geographiques (degres).\n")
#   cat("  pixel ~", round(res(b04)[1] * 111320), "m a l'equateur\n")
# }
#
# # 3. Plage de valeurs : 0-255 = image de visualisation, PAS de la reflectance
# print(terra::minmax(b04))
#
# # 4. Les bandes sont-elles alignees entre elles ?
# cat("Geometries comparables :",
#     terra::compareGeom(b04, b08, stopOnError = FALSE), "\n")
#
# # 5. Nodata : combien de cellules vides ?
# cat("Cellules NA :", terra::global(is.na(b04), "sum")[1, 1],
#     "sur", terra::ncell(b04), "\n")


## ========================================================================
## MODULE 2 -- LES INDICES DE DIFFERENCE NORMALISEE
## ========================================================================
## ----------------------------------------------------------------------
## POURQUOI CE MODULE NE CALCULE PAS DE NDVI AUJOURD'HUI
##
## La tuile Sentinel-2 du depot NE PERMET PAS de construire un exercice
## honnete. Quatre defauts verifies, dont chacun suffirait seul :
##  1. ELLE EST ABSENTE DU POSTE : jamais distribuee dans le magasin central.
##  2. ELLE EST PARTIELLE : 11,5-14,9 E et 2,5-5,8 N, soit l'Est et le Sud
##     seulement. Yaounde et Douala -- les deux villes que la version
##     precedente pretendait comparer -- n'y sont pas entierement. Une
##     extraction zonale par region renverrait NA pour la plupart des unites.
##  3. ELLE EST EN WGS84 A ~150 m, et non en UTM a 10 m : reechantillonnee au
##     telechargement. Annoncer "10 m" est faux d'un facteur 15.
##  4. LES BANDES B03 (Vert) ET B04 (Rouge) SONT ABSENTES du magasin central.
##     Or B04 est au denominateur du NDVI et B03 au numerateur du MNDWI :
##     ces deux indices ne sont PAS CALCULABLES.
## Cinquieme defaut : l'image "True color" disponible est codee sur 8 BITS.
## Elle ne porte aucune reflectance. Calculer un NDVI dessus produit des
## nombres qui n'ont aucun sens physique -- et cela ne plante pas.
##
## DECISION, conforme au 3.7 des regles de l'atelier : module livre en expose,
## avec du code de reference NON EXECUTE. On ne pretend pas calculer un NDVI
## qu'on ne peut pas calculer.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 2.1 LA FORME GENERALE D'UN INDICE NORMALISE
##
##      indice = (bande A - bande B) / (bande A + bande B)
##
## Trois proprietes en decoulent :
##  - LE RESULTAT EST BORNE ENTRE -1 ET +1. Deux territoires deviennent
##    comparables meme si l'un a ete image sous un eclairement plus fort : la
##    division normalise en partie l'effet de l'illumination.
##  - LE RAPPORT, PAS LA DIFFERENCE. Un indice ne dit pas "il y a beaucoup de
##    vegetation", il dit "le PIR domine largement le Rouge". Une prairie
##    seche et une foret dense peuvent partager un NDVI moyen.
##  - LE DENOMINATEUR PEUT S'APPROCHER DE ZERO. Sur les bords de tuile, sur
##    le nodata, sur l'ombre profonde, A + B tend vers 0 et l'indice degenere
##    vers +-1. IL FAUT MASQUER LE NODATA AVANT DE CALCULER, JAMAIS APRES.
##    Un histogramme d'indice avec deux pics a -1 et +1 est presque toujours
##    le symptome de ce defaut, pas une bimodalite du paysage.
##
## 2.2 LES TROIS INDICES DE LA JOURNEE
##   NDVI  = (PIR - Rouge) / (PIR + Rouge)   B08, B04
##           detecte : vegetation chlorophyllienne active
##           confond : prairie seche et sol nu clair ; nuage et eau
##   NDBI  = (SWIR - PIR) / (SWIR + PIR)     B11, B08
##           detecte : surfaces impermeables, bati
##           confond : sol nu, sable, roche affleurante -- defaut de fond
##   MNDWI = (Vert - SWIR) / (Vert + SWIR)   B03, B11
##           detecte : eau libre en surface
##           confond : ombre de relief, toits sombres ; ne voit pas l'eau
##                     sous canopee
##
## CE QUE CES INDICES NE SONT PAS.
##  - Le NDVI n'est pas une mesure de biomasse : il sature, et sur une foret
##    tropicale dense il est plat et ne discrimine plus rien.
##  - Le NDBI n'est pas une mesure de bati : en zone sahelienne, en saison
##    seche, un sol nu lateritique et un quartier de toles ont des signatures
##    voisines. Un NDBI seuille y produit des "villes" la ou il n'y a que du
##    sol nu. C'est la raison de fond pour laquelle le module 3 utilise
##    GHS-BUILT.
##  - Le MNDWI ne voit que l'eau LIBRE EN SURFACE. Une zone inondee sous
##    couvert vegetal n'apparait pas. C'est pour cela que Copernicus EMS
##    s'appuie largement sur du RADAR (Sentinel-1) : il traverse les nuages
##    et fonctionne de nuit -- une inondation arrive rarement par ciel degage.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## 2.3 UN CALCUL D'INDICE, SUR LES VALEURS DU SCHEMA
## ------------------------------------------------------------------------

# RAPPEL : ces reflectances sont des valeurs typiques saisies a la main.
# L'exercice porte sur la FORMULE, pas sur un chiffre a citer.
sig_large <- signatures %>%
  select(surface, bande, reflectance) %>%
  tidyr::pivot_wider(names_from = bande, values_from = reflectance)

cat("Tableau large :", nrow(sig_large), "surfaces x",
    ncol(sig_large) - 1, "bandes\n")

indices_schema <- sig_large %>%
  mutate(
    NDVI  = (PIR  - Rouge) / (PIR  + Rouge),
    NDBI  = (SWIR - PIR)   / (SWIR + PIR),
    MNDWI = (Vert - SWIR)  / (Vert + SWIR)
  ) %>%
  select(surface, NDVI, NDBI, MNDWI) %>%
  mutate(across(c(NDVI, NDBI, MNDWI), ~ round(.x, 3)))

print(indices_schema)

# Controle : aucun indice ne doit sortir de [-1, 1]. Si c'est le cas,
# c'est que le denominateur est passe pres de zero.
hors_bornes <- indices_schema %>%
  tidyr::pivot_longer(-surface, names_to = "indice", values_to = "valeur") %>%
  filter(abs(valeur) > 1)
cat("Valeurs hors de [-1, 1] :", nrow(hors_bornes), "\n")

indices_long <- indices_schema %>%
  tidyr::pivot_longer(-surface, names_to = "indice", values_to = "valeur")

print(
  ggplot(indices_long, aes(x = surface, y = valeur, fill = indice)) +
    geom_col(position = "dodge") +
    geom_hline(yintercept = 0, colour = "grey30") +
    scale_fill_manual(values = c(NDVI = "#1B7837", NDBI = "#762A83",
                                 MNDWI = "#2166AC")) +
    coord_cartesian(ylim = c(-1, 1)) +
    labs(
      title = "Les trois indices appliques aux signatures schematiques",
      subtitle = "Chaque indice est maximal pour la surface qu'il est cense detecter",
      x = NULL, y = "Valeur de l'indice (borne a [-1, 1])", fill = NULL
    ) +
    theme_minimal()
)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- LES TROIS INDICES SUR LE SCHEMA
##
## CE QUE LA FIGURE CODE. Une barre = un indice calcule pour un type de
## surface. La hauteur est la valeur de l'indice, bornee par construction
## entre -1 et +1. La ligne a 0 est le point de bascule.
##
## CE QUE LES CHOIX TECHNIQUES FONT. L'axe vertical est FIXE a [-1, 1] par
## coord_cartesian() et non laisse libre : un axe ajuste aux donnees donnerait
## l'impression d'ecarts enormes, alors qu'on veut montrer ou chaque valeur se
## place dans L'ETENDUE POSSIBLE. La palette est QUALITATIVE -- trois indices
## sans ordre entre eux -- et non sequentielle.
##
## CE QUI SE LIT. Chaque indice est bien maximal pour la surface qu'il vise.
## La mecanique fonctionne.
##
## CE QUI NE SE LIT PAS. Le NDBI du sol nu est du meme ordre que celui du
## bati : la confusion annoncee est dans les chiffres, pas seulement dans le
## discours. Et surtout : ces valeurs sont INVENTEES. Un pixel reel est un
## melange de surfaces ("pixel mixte") ; a 150 m, un pixel de banlieue
## contient toits, arbres, route et sol nu a la fois, et la valeur mesuree est
## une moyenne ponderee de tout cela.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 2.4 LE CODE DE REFERENCE, POUR LE JOUR OU L'IMAGE EXISTE
## ------------------------------------------------------------------------
## --- BLOC DE REFERENCE, NON EXECUTE ---
## B03 et B04 sont absentes du magasin central, et la tuile disponible est en
## 8 bits, partielle et a 150 m. Trame a reprendre le jour ou une image
## exploitable est fournie.
#
# b03 <- terra::rast(file.path("datasets", "bande_verte_a_fournir.tif"))
# b04 <- terra::rast(file.path("datasets", "bande_rouge_a_fournir.tif"))
# b08 <- terra::rast(file.path("datasets", "bande_pir_a_fournir.tif"))
# b11 <- terra::rast(file.path("datasets", "bande_swir_a_fournir.tif"))
#
# # --- 1. ALIGNER : le SWIR est natif a 20 m, le PIR a 10 m ---------------
# if (!terra::compareGeom(b08, b11, stopOnError = FALSE)) {
#   b11 <- terra::resample(b11, b08, method = "bilinear")
#   cat("B11 reechantillonnee sur la grille de B08 :", res(b11), "\n")
# }
#
# # --- 2. MASQUER LE NODATA AVANT DE CALCULER -----------------------------
# masque_valide <- !is.na(b04) & !is.na(b08) & (b04 + b08) > 0
# b04 <- terra::mask(b04, masque_valide, maskvalues = 0)
# b08 <- terra::mask(b08, masque_valide, maskvalues = 0)
#
# # --- 3. PASSER EN REFLECTANCE (0-1) -------------------------------------
# b03_r <- b03 / 10000; b04_r <- b04 / 10000
# b08_r <- b08 / 10000; b11_r <- b11 / 10000
#
# # --- 4. CALCULER ---------------------------------------------------------
# ndvi  <- (b08_r - b04_r) / (b08_r + b04_r)
# ndbi  <- (b11_r - b08_r) / (b11_r + b08_r)
# mndwi <- (b03_r - b11_r) / (b03_r + b11_r)
#
# # --- 5. CONTROLER AVANT D'AFFICHER --------------------------------------
# print(terra::global(ndvi, c("mean", "sd", "min", "max"), na.rm = TRUE))
#
# # --- 6. BORNER L'AFFICHAGE SUR LES CENTILES 1 ET 99 ---------------------
# bornes <- terra::global(ndvi, function(x) quantile(x, c(0.01, 0.99), na.rm = TRUE))
# terra::plot(ndvi, range = as.numeric(bornes[1, ]),
#             main = "NDVI (affichage borne aux centiles 1 et 99)")
#
# # --- 7. CE QU'IL NE FAUT PAS FAIRE --------------------------------------
# # Calculer un indice sur une image "True color" 8 bits : ses canaux ont ete
# # etires et contrastes pour l'ecran. Le calcul produit des nombres ; ils ne
# # mesurent rien. Aucune erreur n'est levee. C'est tout le probleme.

## ----------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI -- ET IL L'EST DEJA
##
## Un tableau de reflectances moyennes par region dirait "le Centre a un NDVI
## moyen de 0,62". La carte du meme indice montre OU la vegetation cede, et
## que les zones de faible NDVI forment des taches CONTIGUES le long des axes
## routiers et autour des villes. Un bloc contigu ne s'explique pas par les
## caracteristiques propres de chaque pixel, mais par ce que les pixels
## partagent PARCE QU'ILS SONT VOISINS. Le passage d'une liste de valeurs a un
## systeme de voisinages fait de la ressemblance entre voisins l'objet a
## expliquer, et non un bruit a moyenner.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 3 -- DU PIXEL AU PRODUIT : GHS-BUILT
## ========================================================================
## 3.1 CE QU'EST GHS-BUILT -- ET CE QU'IL N'EST PAS
##
## Le Global Human Settlement Layer (GHSL) est produit par le Centre commun de
## recherche de la Commission europeenne. La couche GHS-BUILT-S donne, pour
## chaque cellule de 100 m x 100 m, la SURFACE DE BATI EN METRES CARRES
## contenue dans cette cellule -- une valeur continue entre 0 et 10 000, et
## non une classe. Elle est fabriquee par apprentissage supervise sur des
## images Landsat et Sentinel-2.
##
## ----------------------------------------------------------------------
## "SURFACE BATIE" N'EST PAS "SURFACE URBANISEE"
##
## Confondre les deux est l'erreur d'interpretation la plus frequente sur ce
## produit.
## CE QUE GHS-BUILT-S MESURE : l'emprise au sol des structures construites --
## toits, dalles, hangars. Rien d'autre.
## CE QU'IL NE MESURE PAS :
##  - les cours, jardins, rues et places : un tissu urbain classique ne
##    depasse guere 30 a 50 % de surface batie ;
##  - la HAUTEUR : une tour de vingt etages et un hangar de plain-pied de meme
##    emprise comptent identiquement (c'est GHS-BUILT-H qui porte la hauteur) ;
##  - l'USAGE : usine, entrepot, ecole et immeuble sont indiscernables ;
##  - l'OCCUPATION : un batiment vide compte comme un batiment plein.
##
## CONSEQUENCE A ENONCER EN SALLE : une part batie de 3 % dans un departement
## NE VEUT PAS DIRE que 3 % de sa population vit en ville. Elle veut dire que
## 3 % de sa superficie est couverte par des toits. C'est un indicateur de
## PRESSION PHYSIQUE SUR LE SOL, pas un indicateur d'urbanisation au sens
## demographique.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 3.2 TROIS FONCTIONS, REUTILISEES TOUTE LA JOURNEE
## ------------------------------------------------------------------------
## Elles viennent du script formateur source, reecrites avec des chemins a
## plat et, surtout, avec l'INSTRUMENTATION qui manquait : une operation
## raster qui echoue a moitie ne leve pas d'erreur, elle remplit de NA.

# --------------------------------------------------------------------------
# charger_ghsl(annee) : mosaique les tuiles GHS-BUILT d'un millesime
# --------------------------------------------------------------------------
# Les tuiles sont livrees zippees, une par archive, dans la grille mondiale
# GHSL (Mollweide, ESRI:54009 -- projection EQUIVALENTE, donc les surfaces y
# sont justes). On decompresse dans un repertoire temporaire : on n'ecrit
# jamais dans datasets/, qui est un dossier d'entrees.
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

  cat("  resolution :", paste(res(mosaique), collapse = " x "),
      "(unite du CRS)\n")
  cat("  CRS        :", terra::crs(mosaique, describe = TRUE)$name, "\n")
  cat("  emprise    : "); print(terra::ext(mosaique))

  attr(mosaique, "codes_tuiles") <- sort(codes)
  mosaique
}

# --------------------------------------------------------------------------
# preparer_raster(raster, pays) : decoupe le raster sur un contour
# --------------------------------------------------------------------------
# crop() reduit a l'emprise rectangulaire (rapide), mask() met a NA tout ce
# qui est hors du polygone (precis). Faire crop AVANT mask.
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

# --------------------------------------------------------------------------
# resumer_bati(...) : statistique zonale sur une couche de polygones
# --------------------------------------------------------------------------
# exact_extract() pondere chaque cellule par la FRACTION de sa surface
# couverte par le polygone. terra::extract() par defaut compte la cellule
# entiere du cote ou tombe son centre : sur 100 m, l'ecart est negligeable au
# niveau national, mais il ne l'est plus sur un petit departement.
resumer_bati <- function(polygones, raster, annee, id_col, nom_col,
                         etiquette = "") {

  # Extraction : dans le CRS DU RASTER.
  pol_raster <- sf::st_transform(polygones, terra::crs(raster))
  bati_km2   <- exactextractr::exact_extract(raster, pol_raster, "sum",
                                             progress = FALSE) / 1e6

  # Surface : dans le CRS DE MESURE (UTM 33N), pas en degres.
  pol_mesure    <- sf::st_transform(polygones, crs_mesure)
  surface_km2   <- as.numeric(sf::st_area(pol_mesure)) / 1e6

  cat("--- resumer_bati(", etiquette, ", ", annee, ") ---\n", sep = "")
  cat("  polygones            :", nrow(polygones), "\n")
  cat("  CRS d'extraction     :", terra::crs(raster, describe = TRUE)$name, "\n")
  cat("  CRS de mesure        : EPSG:", crs_mesure, "\n", sep = "")
  cat("  bati total           :", round(sum(bati_km2, na.rm = TRUE), 1), "km2\n")
  cat("  surface totale       :", round(sum(surface_km2), 0), "km2\n")
  cat("  polygones sans bati  :", sum(bati_km2 == 0, na.rm = TRUE), "\n")
  cat("  extractions NA       :", sum(is.na(bati_km2)), "\n")

  pol_raster %>%
    mutate(
      annee          = annee,
      surface_km2    = surface_km2,
      bati_km2       = bati_km2,
      part_batie_pct = 100 * bati_km2 / surface_km2
    ) %>%
    select(all_of(c(id_col, nom_col)), annee, surface_km2, bati_km2,
           part_batie_pct)
}

## ------------------------------------------------------------------------
## 3.3 LES LIMITES ADMINISTRATIVES, CONTROLEES AVANT USAGE
## ------------------------------------------------------------------------

# Une lecture, une fois. On lit les trois niveaux ici et nulle part ailleurs :
# un rechargement plus loin ecraserait la preparation.
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

# CONTROLE DE VALIDITE : superficie officielle du Cameroun = 475 442 km2.
surface_officielle_km2 <- 475442

surf_4326 <- tryCatch(
  as.numeric(sum(sf::st_area(cmr0))) / 1e6,
  error = function(e) NA_real_
)
surf_utm  <- as.numeric(sum(sf::st_area(sf::st_transform(cmr0, crs_mesure)))) / 1e6
surf_moll <- as.numeric(sum(sf::st_area(sf::st_transform(cmr0, "ESRI:54009")))) / 1e6

comparaison_crs <- data.frame(
  crs = c("EPSG:4326 (degres, s2 desactive)",
          "EPSG:32633 (UTM 33N, conforme)",
          "ESRI:54009 (Mollweide, equivalente)"),
  surface_km2 = round(c(surf_4326, surf_utm, surf_moll), 0)
) %>%
  mutate(ecart_pct = round(100 * (surface_km2 - surface_officielle_km2) /
                             surface_officielle_km2, 2))

print(comparaison_crs)
cat("\nReference officielle :", surface_officielle_km2, "km2\n")

## ----------------------------------------------------------------------
## LE TABLEAU QU'IL FAUT LIRE LIGNE PAR LIGNE
##
## EPSG:4326. Le CRS est en degres. Avec s2 desactive, st_area() calcule une
## aire planaire sur des degres : un nombre de "degres carres", que la
## division par 1e6 transforme en absurdite. Ce n'est pas une approximation,
## c'est une grandeur qui n'existe pas.
##
## EPSG:32633, UTM 33N. Notre CRS de mesure. UTM est une projection CONFORME :
## elle conserve les angles, pas les surfaces. La zone 33N est calee sur
## 12-18 E ; le Cameroun s'etend de 8,5 a 16,2 E, donc son flanc occidental
## est a ~4 degres du meridien central. La distorsion y atteint quelques pour
## cent : acceptable pour une mesure departementale, visible sur le total.
##
## ESRI:54009, Mollweide. Projection de la grille GHSL. EQUIVALENTE : les
## surfaces y sont justes partout, au prix d'une deformation des formes. Pour
## un total national, c'est la reference.
##
## A RETENIR. "Reprojeter avant de mesurer" ne suffit pas : il faut
## reprojeter DANS LA BONNE FAMILLE. Conforme pour les angles, equivalente
## pour les surfaces, equidistante pour les distances depuis un point. Aucune
## projection ne fait les trois.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 3.4 MOSAIQUER LES TUILES ET DECOUPER SUR LE PAYS
## ------------------------------------------------------------------------

bati_2015 <- charger_ghsl(2015)
bati_2025 <- charger_ghsl(2025)

# CONTROLE CRITIQUE : les deux millesimes couvrent-ils la MEME emprise ?
# Si une tuile manque d'un cote, la difference 2025-2015 melange une
# croissance reelle et un trou de couverture. L'erreur ne leve rien.
codes_2015 <- attr(bati_2015, "codes_tuiles")
codes_2025 <- attr(bati_2025, "codes_tuiles")

cat("Tuiles 2015 :", paste(codes_2015, collapse = ", "), "\n")
cat("Tuiles 2025 :", paste(codes_2025, collapse = ", "), "\n")

manquantes_2015 <- setdiff(codes_2025, codes_2015)
manquantes_2025 <- setdiff(codes_2015, codes_2025)

cat("\nPresentes en 2025 mais absentes en 2015 :",
    if (length(manquantes_2015)) paste(manquantes_2015, collapse = ", ") else "aucune", "\n")
cat("Presentes en 2015 mais absentes en 2025 :",
    if (length(manquantes_2025)) paste(manquantes_2025, collapse = ", ") else "aucune", "\n")

if (length(manquantes_2015) || length(manquantes_2025)) {
  cat("\n*** ASYMETRIE DE COUVERTURE DETECTEE ***\n")
  cat("Les deux millesimes ne portent pas sur la meme emprise.\n")
  cat("La section 3.5 restreint les deux rasters a leur intersection.\n")
}

## ----------------------------------------------------------------------
## L'ASYMETRIE DE COUVERTURE : LE PIEGE MAJEUR DU MODULE
##
## Au moment d'ecrire ce materiel, le lot livre comptait 8 TUILES POUR 2025 ET
## 7 POUR 2015 : la tuile R7_C19 du millesime 2015 est absente. Le comptage
## ci-dessus le confirme ou l'infirme sur votre poste -- il est la pour ca.
##
## CE QUE CELA FERAIT SI ON NE LE VOYAIT PAS : sur la zone couverte par
## R7_C19, le raster 2015 vaut NA. exact_extract(..., "sum") traite les NA
## comme absents, donc renvoie un bati 2015 sous-estime -- voire 0. Le "gain
## 2015 -> 2025" y devient egal a la totalite du bati 2025, et la croissance
## relative explose. Sur une carte, cette region ressortirait en rouge vif
## comme la plus dynamique du pays. Personne ne relirait le code.
##
## TRAITEMENT ADOPTE : restreindre les deux millesimes a l'intersection de
## leurs emprises valides, et declarer la zone perdue. Une unite sans donnee
## reste sans donnee -- elle n'est pas a zero.
## ----------------------------------------------------------------------

bati_2015_cmr <- preparer_raster(bati_2015, cmr0, "GHS-BUILT 2015")
bati_2025_cmr <- preparer_raster(bati_2025, cmr0, "GHS-BUILT 2025")

## ------------------------------------------------------------------------
## 3.5 ALIGNER LES DEUX MILLESIMES SUR UNE EMPRISE COMMUNE
## ------------------------------------------------------------------------

# --------------------------------------------------------------------------
# aligner_millesimes() : ne comparer que ce qui est comparable
# --------------------------------------------------------------------------
# Ajout par rapport au script source, rendu necessaire par l'asymetrie de
# tuiles. Les tuiles GHSL partagent la meme grille : un simple crop suffit a
# les aligner exactement.
aligner_millesimes <- function(r_ancien, r_recent) {

  emprise_commune <- terra::intersect(terra::ext(r_ancien), terra::ext(r_recent))
  a <- terra::crop(r_ancien, emprise_commune)
  b <- terra::crop(r_recent, emprise_commune)

  cat("--- aligner_millesimes() ---\n")
  cat("  geometries comparables apres crop :",
      terra::compareGeom(a, b, stopOnError = FALSE), "\n")

  valide <- !is.na(a) & !is.na(b)
  n_valide <- as.numeric(terra::global(valide, "sum", na.rm = TRUE)[1, 1])
  cat("  cellules valides dans LES DEUX millesimes :", n_valide,
      "sur", terra::ncell(a), "\n")

  a2 <- terra::mask(a, valide, maskvalues = 0)
  b2 <- terra::mask(b, valide, maskvalues = 0)

  cat("  bati 2015 avant / apres alignement :",
      round(as.numeric(terra::global(a, "sum", na.rm = TRUE)[1, 1]) / 1e6, 1), "/",
      round(as.numeric(terra::global(a2, "sum", na.rm = TRUE)[1, 1]) / 1e6, 1), "km2\n")
  cat("  bati 2025 avant / apres alignement :",
      round(as.numeric(terra::global(b, "sum", na.rm = TRUE)[1, 1]) / 1e6, 1), "/",
      round(as.numeric(terra::global(b2, "sum", na.rm = TRUE)[1, 1]) / 1e6, 1), "km2\n")

  list(ancien = a2, recent = b2)
}

paire <- aligner_millesimes(bati_2015_cmr, bati_2025_cmr)
bati_2015_ok <- paire$ancien
bati_2025_ok <- paire$recent

# Apercu de controle. On BORNE l'affichage aux centiles 1 et 99 : sans cela,
# une poignee de cellules de centre-ville a 10 000 m2 ecrase toute la palette.
bornes_affichage <- terra::global(
  bati_2025_ok,
  function(x) quantile(x, c(0.01, 0.99), na.rm = TRUE)
)
cat("Bornes d'affichage (centiles 1 et 99) :",
    paste(round(as.numeric(bornes_affichage[1, ]), 1), collapse = " - "), "m2\n")

terra::plot(
  bati_2025_ok,
  range = as.numeric(bornes_affichage[1, ]),
  col = hcl.colors(50, "Inferno", rev = TRUE),
  main = "GHS-BUILT-S 2025 : surface batie par cellule de 100 m",
  plg = list(title = "m2 bati / cellule")
)
plot(sf::st_geometry(sf::st_transform(cmr1, terra::crs(bati_2025_ok))),
     add = TRUE, border = "grey30", lwd = 0.5)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- LA MOSAIQUE GHS-BUILT 2025
##
## CE QUE LA FIGURE CODE. Chaque pixel de 100 m x 100 m est colore selon le
## nombre de METRES CARRES DE TOIT qu'il contient, de 0 a 10 000. Ni densite
## de population, ni classe d'occupation du sol.
##
## CE QUE LES CHOIX TECHNIQUES FONT. L'affichage est BORNE AUX CENTILES 1 ET
## 99 : les valeurs extremes sont ecretees VISUELLEMENT, pas supprimees de la
## donnee. Sans ce bornage, les cellules de centre-ville saturees a 10 000 m2
## absorberaient toute l'echelle. La palette est SEQUENTIELLE (luminosite
## monotone) : elle code un ordre, correct pour une quantite positive. Une
## palette divergente serait ici un contresens -- il n'y a pas de "point
## neutre" dans une surface batie.
##
## CE QUI SE LIT. Le bati camerounais est extremement concentre : quelques
## taches vives, un semis de bourgs le long des axes, de vastes etendues a
## zero. Les alignements clairs suivent des routes, pas des reliefs.
##
## CE QUI NE SE LIT PAS. La hauteur, l'usage, l'occupation. Et surtout : UNE
## CELLULE A 0 N'EST PAS UNE CELLULE SANS HUMAINS. L'habitat tres disperse, ou
## construit en materiaux legers sous couvert vegetal, passe partiellement
## sous le radar du produit.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 4 -- MESURER LE BATI : NATIONAL, REGIONAL, DEPARTEMENTAL
## ========================================================================

## ------------------------------------------------------------------------
## 4.1 LE NIVEAU NATIONAL
## ------------------------------------------------------------------------

cmr0_raster <- sf::st_transform(cmr0, terra::crs(bati_2015_ok))
surface_cmr0_km2 <- as.numeric(
  sum(sf::st_area(sf::st_transform(cmr0, crs_mesure)))
) / 1e6

cat("Surface nationale retenue (UTM 33N) :", round(surface_cmr0_km2, 0), "km2\n")

national_2015 <- tibble::tibble(
  annee = 2015,
  bati_km2 = exactextractr::exact_extract(bati_2015_ok, cmr0_raster, "sum",
                                          progress = FALSE) / 1e6
) %>%
  mutate(part_batie_pct = 100 * bati_km2 / surface_cmr0_km2)

national_2025 <- tibble::tibble(
  annee = 2025,
  bati_km2 = exactextractr::exact_extract(bati_2025_ok, cmr0_raster, "sum",
                                          progress = FALSE) / 1e6
) %>%
  mutate(part_batie_pct = 100 * bati_km2 / surface_cmr0_km2)

national <- bind_rows(national_2015, national_2025)
print(national)

changement_national <- national %>%
  tidyr::pivot_wider(names_from = annee,
                     values_from = c(bati_km2, part_batie_pct)) %>%
  mutate(
    gain_bati_km2        = bati_km2_2025 - bati_km2_2015,
    croissance_pct       = 100 * gain_bati_km2 / bati_km2_2015,
    delta_part_batie_pct = part_batie_pct_2025 - part_batie_pct_2015
  )

print(changement_national)

cat("\nLecture : en dix ans, le bati national passe de ",
    round(changement_national$bati_km2_2015, 0), " a ",
    round(changement_national$bati_km2_2025, 0), " km2, soit ",
    round(changement_national$croissance_pct, 1), " % de croissance relative.\n",
    sep = "")

## ----------------------------------------------------------------------
## DEUX CHIFFRES, DEUX QUESTIONS DIFFERENTES
##
## Le GAIN ABSOLU repond a : "ou faut-il des routes, des ecoles, de
## l'assainissement ?" C'est une quantite de metres carres a desservir.
## La CROISSANCE RELATIVE repond a : "ou le rythme est-il le plus rapide ?"
## C'est un rapport, et un rapport a un denominateur.
##
## Ces deux indicateurs NE CLASSENT PAS les territoires dans le meme ordre.
## Un departement qui passe de 1 a 2 km2 affiche +100 % et un gain de 1 km2.
## Douala, qui passe de 120 a 160 km2, affiche +33 % et un gain de 40 km2. Le
## premier gagne le classement du rythme, le second est celui qui pose un
## probleme d'equipement. Publier la seule croissance relative, c'est mettre
## en tete de classement les unites les plus petites -- mecaniquement.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.2 LE NIVEAU REGIONAL (ADM1)
## ------------------------------------------------------------------------

regions_2015 <- resumer_bati(cmr1, bati_2015_ok, 2015, "GID_1", "NAME_1", "ADM1")
regions_2025 <- resumer_bati(cmr1, bati_2025_ok, 2025, "GID_1", "NAME_1", "ADM1")

# Seuil declare : en dessous de ce bati initial, la croissance relative n'a
# pas de sens (un denominateur minuscule fabrique des taux a trois chiffres).
# Le seuil est ECRIT dans le code, pas subi.
seuil_bati_min_km2 <- 1

n_avant <- nrow(regions_2015)

regions_chg <- regions_2015 %>%
  sf::st_drop_geometry() %>%
  select(GID_1, NAME_1,
         bati_km2_2015 = bati_km2,
         part_batie_pct_2015 = part_batie_pct) %>%
  left_join(
    regions_2025 %>%
      sf::st_drop_geometry() %>%
      select(GID_1,
             bati_km2_2025 = bati_km2,
             part_batie_pct_2025 = part_batie_pct),
    by = "GID_1"
  ) %>%
  mutate(
    gain_bati_km2 = bati_km2_2025 - bati_km2_2015,
    croissance_pct = if_else(
      bati_km2_2015 >= seuil_bati_min_km2,
      100 * gain_bati_km2 / bati_km2_2015,
      NA_real_
    ),
    delta_part_batie_pct    = part_batie_pct_2025 - part_batie_pct_2015,
    part_nationale_2025_pct = 100 * bati_km2_2025 / sum(bati_km2_2025)
  ) %>%
  arrange(desc(gain_bati_km2))

cat("--- Jointure 2015 <-> 2025 sur GID_1 ---\n")
cat("  lignes avant :", n_avant, " | lignes apres :", nrow(regions_chg), "\n")
cat("  NA sur bati_km2_2025 apres jointure :",
    sum(is.na(regions_chg$bati_km2_2025)), "\n")
cat("  regions sous le seuil de ", seuil_bati_min_km2,
    " km2 de bati 2015 (croissance non calculee) : ",
    sum(is.na(regions_chg$croissance_pct)), "\n", sep = "")
cat("  somme des parts nationales :",
    round(sum(regions_chg$part_nationale_2025_pct, na.rm = TRUE), 2),
    "% (doit valoir 100)\n")

print(regions_chg)

regions_resume <- regions_chg %>%
  mutate(
    rang_gain       = min_rank(desc(gain_bati_km2)),
    rang_croissance = min_rank(desc(croissance_pct)),
    rang_part_2025  = min_rank(desc(part_batie_pct_2025)),
    ecart_de_rang   = abs(rang_gain - rang_croissance)
  ) %>%
  arrange(rang_gain)

print(regions_resume %>%
        select(NAME_1, bati_km2_2025, gain_bati_km2, croissance_pct,
               rang_gain, rang_croissance, ecart_de_rang))

cat("\nEcart de rang maximal entre gain absolu et croissance relative :",
    max(regions_resume$ecart_de_rang, na.rm = TRUE), "places\n")
cat("Correlation de Spearman entre les deux classements :",
    round(cor(regions_resume$gain_bati_km2, regions_resume$croissance_pct,
              method = "spearman", use = "complete.obs"), 3), "\n")

## ----------------------------------------------------------------------
## POURQUOI SPEARMAN ET PAS PEARSON
##
## PEARSON mesure une association LINEAIRE ; il est sensible aux valeurs
## extremes, et avec dix regions dont une pese demesurement, un seul point
## peut fixer le coefficient.
## SPEARMAN est le Pearson calcule sur les RANGS. Il mesure si les deux
## classements vont dans le meme sens, sans supposer de forme fonctionnelle.
## C'est exactement la question posee : le classement par gain absolu et le
## classement par croissance relative sont-ils le meme classement ?
##
## Avec dix unites, aucun des deux ne doit etre presente avec un test de
## significativite : la puissance est derisoire. Le coefficient est ici un
## RESUME DESCRIPTIF de l'ecart entre deux ordres, rien de plus.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.3 LES CARTES REGIONALES
## ------------------------------------------------------------------------

carte_part_2025 <- ggplot(regions_2025) +
  geom_sf(aes(fill = part_batie_pct), colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "magma", direction = -1,
                       na.value = "grey85") +
  labs(
    title = "Part de surface batie GHS-BUILT en 2025",
    subtitle = "Regions (ADM1) du Cameroun -- m2 de toit rapportes a la superficie",
    fill = "% bati",
    caption = "Source : GHSL GHS-BUILT-S R2023A, 100 m. Gris = donnee absente."
  ) +
  theme_minimal()

print(carte_part_2025)

ggsave("outputs/J09_part_batie_2025.png", carte_part_2025,
       width = 8, height = 5.5, dpi = 180)

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- PART BATIE 2025
##
## CE QUE LA CARTE CODE. La couleur d'une region = la somme des metres carres
## de toit, divisee par sa superficie, en pourcentage. "Part batie" au sens
## GHS-BUILT, et non "part urbanisee" au sens demographique.
##
## CE QUE LES CHOIX TECHNIQUES FONT. La palette magma inversee est
## SEQUENTIELLE et perceptuellement uniforme : un ecart de couleur egal
## correspond a un ecart de valeur egal, ce que ne garantit pas un
## arc-en-ciel. L'echelle est CONTINUE : aucune discretisation n'est imposee,
## donc aucune classe n'est fabriquee. Une discretisation en quantiles
## donnerait cinq classes de deux regions ; en intervalles egaux, neuf regions
## dans la premiere classe et le Littoral seul dans la derniere. Les trois
## images racontent le MEME TABLEAU autrement. Le na.value = "grey85" est
## explicite : UNE REGION SANS DONNEE EST GRISE, ELLE N'EST PAS A ZERO.
##
## CE QUI SE LIT. Le contraste est ecrasant : Littoral et Centre concentrent
## l'essentiel, l'Est et l'Adamaoua sont quasi vides. Aucune region n'atteint
## quelques pour cent -- rappel que "bati" est une notion tres restrictive.
##
## CE QUI NE SE LIT PAS. La carte est une MOYENNE REGIONALE. Le Littoral doit
## sa valeur a Douala, sur une fraction minuscule de son territoire.
## Attribuer a un habitant du Littoral la caracteristique moyenne de sa region
## est une ERREUR ECOLOGIQUE -- risque permanent de la choropleth.
## ----------------------------------------------------------------------

# La colonne de geometrie est "collante" chez sf : select() la conserve.
regions_carto <- regions_2025 %>%
  select(GID_1, NAME_1) %>%
  left_join(regions_chg, by = c("GID_1", "NAME_1"))

cat("Jointure carto : ", nrow(regions_2025), " -> ", nrow(regions_carto),
    " lignes (doit etre identique)\n", sep = "")

carte_gain <- ggplot(regions_carto) +
  geom_sf(aes(fill = gain_bati_km2), colour = "white", linewidth = 0.2) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0, na.value = "grey85") +
  labs(
    title = "Gain de surface batie entre 2015 et 2025",
    subtitle = "Difference en km2 -- combien de toits nouveaux a desservir",
    fill = "Gain (km2)",
    caption = "Palette divergente centree sur 0. Gris = donnee absente."
  ) +
  theme_minimal()

print(carte_gain)

ggsave("outputs/J09_gain_bati_2015_2025.png", carte_gain,
       width = 8, height = 5.5, dpi = 180)

carte_croissance <- ggplot(regions_carto) +
  geom_sf(aes(fill = croissance_pct), colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "plasma", na.value = "grey85") +
  labs(
    title = "Croissance relative du bati 2015-2025",
    subtitle = paste0("En % du bati de 2015. Gris : bati 2015 < ",
                      seuil_bati_min_km2, " km2, taux non calcule"),
    fill = "% croissance",
    caption = "Source : GHSL GHS-BUILT-S R2023A."
  ) +
  theme_minimal()

print(carte_croissance)

ggsave("outputs/J09_croissance_bati_2015_2025.png", carte_croissance,
       width = 8, height = 5.5, dpi = 180)

## ----------------------------------------------------------------------
## LECTURE DES DEUX CARTES -- GAIN ET CROISSANCE
##
## CE QUE LES CARTES CODENT. La premiere une DIFFERENCE en km2 ; la seconde un
## RAPPORT en % du point de depart. Meme donnee source, deux messages.
##
## CE QUE LES CHOIX TECHNIQUES FONT. La carte de gain utilise une palette
## DIVERGENTE centree sur 0 : le blanc marque l'absence de changement. Choix
## correct quand la valeur zero a un sens intrinseque. La carte de croissance
## utilise une palette SEQUENTIELLE : un taux de croissance est ici positif
## partout, il n'y a pas de point neutre a marquer ; une divergente y
## creerait un faux seuil. Sur la seconde carte, LE GRIS N'EST PAS "PAS DE
## CROISSANCE" : c'est "taux non calcule, denominateur sous le seuil declare".
##
## CE QUI SE LIT. Les deux cartes ne se ressemblent pas. Le Littoral domine
## les gains et disparait des taux. L'ECART ENTRE LES DEUX CARTES EST PLUS
## INFORMATIF QUE CHACUNE : il localise ou un rythme rapide porte sur de
## petits volumes, et ou un rythme modeste porte sur des volumes qui saturent
## deja les reseaux.
##
## CE QUI NE SE LIT PAS. Ni l'une ni l'autre ne dit POURQUOI. Une croissance
## du bati peut venir d'un exode rural, d'un projet minier, d'un camp de
## deplaces -- ou d'une amelioration de la detection entre deux versions de
## l'algorithme GHSL. Cette derniere hypothese est rarement enoncee et elle
## est reelle.
## ----------------------------------------------------------------------

graphique_bati <- ggplot(regions_chg,
                         aes(x = bati_km2_2015, y = bati_km2_2025,
                             label = NAME_1)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey40") +
  geom_point(size = 2.8, colour = "#2C7FB8") +
  geom_text(vjust = -0.7, size = 3) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Bati regional 2015 vs 2025 (echelles logarithmiques)",
    subtitle = "La diagonale est la stabilite : tout point au-dessus a gagne du bati",
    x = "Bati 2015 (km2, echelle log)",
    y = "Bati 2025 (km2, echelle log)"
  ) +
  theme_minimal()

print(graphique_bati)

## ----------------------------------------------------------------------
## LECTURE DU NUAGE -- 2015 CONTRE 2025
##
## CE QUE LA FIGURE CODE. Un point = une region. Abscisse : bati 2015 ;
## ordonnee : bati 2025. La diagonale pointillee est y = x, donc la stabilite.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Les deux axes sont en ECHELLE
## LOGARITHMIQUE. Sans cela, le Littoral et le Centre ecraseraient les huit
## autres regions dans un coin illisible. En echelle log, un ECART VERTICAL
## CONSTANT A LA DIAGONALE REPRESENTE UNE CROISSANCE RELATIVE CONSTANTE, pas
## un gain absolu constant : le log transforme la lecture du graphique en
## lecture de taux.
##
## CE QUI SE LIT. Tous les points sont au-dessus de la diagonale : aucune
## region n'a perdu de bati (GHS-BUILT ne modelise pratiquement pas la
## demolition). L'alignement est serre : dix ans n'ont rebattu aucune carte.
##
## CE QUI NE SE LIT PAS. Le log COMPRESSE VISUELLEMENT LES GRANDS ECARTS.
## Deux points voisins en haut a droite peuvent differer de dizaines de km2.
## Ne jamais lire un volume sur un axe log : le lire dans le tableau.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.4 UNE TYPOLOGIE EN QUATRE PROFILS
## ------------------------------------------------------------------------

# Deux medianes croisees : rythme (gain) x etat (part batie). Ce sont des
# seuils RELATIFS a l'echantillon des dix regions -- par construction, chaque
# moitie contient cinq regions. Ce n'est pas une classification absolue.
med_gain <- median(regions_chg$gain_bati_km2, na.rm = TRUE)
med_part <- median(regions_chg$part_batie_pct_2025, na.rm = TRUE)

cat("Mediane du gain 2015-2025      :", round(med_gain, 2), "km2\n")
cat("Mediane de la part batie 2025  :", round(med_part, 3), "%\n")

regions_typo <- regions_chg %>%
  mutate(
    profil = case_when(
      gain_bati_km2 >= med_gain & part_batie_pct_2025 >= med_part ~
        "Croissance forte et tissu dense",
      gain_bati_km2 >= med_gain ~ "Croissance forte",
      part_batie_pct_2025 >= med_part ~ "Tissu dense",
      TRUE ~ "Croissance moderee"
    )
  )

cat("\nEffectifs par profil :\n")
print(regions_typo %>% count(profil, name = "nb_regions"))

print(regions_typo %>%
        select(NAME_1, bati_km2_2025, gain_bati_km2, part_batie_pct_2025, profil) %>%
        arrange(profil, desc(gain_bati_km2)))

regions_typo_carto <- regions_2025 %>%
  select(GID_1, NAME_1) %>%
  left_join(regions_typo %>% select(GID_1, profil), by = "GID_1")

cat("Regions sans profil affecte :", sum(is.na(regions_typo_carto$profil)), "\n")

carte_typo <- ggplot(regions_typo_carto) +
  geom_sf(aes(fill = profil), colour = "white", linewidth = 0.2) +
  scale_fill_manual(
    values = c("Croissance forte et tissu dense" = "#B2182B",
               "Croissance forte"                = "#FD8D3C",
               "Tissu dense"                     = "#2C7FB8",
               "Croissance moderee"              = "#FEE8C8"),
    na.value = "grey85"
  ) +
  labs(
    title = "Typologie pedagogique de la croissance batie",
    subtitle = "Croisement de deux medianes : rythme (gain) x etat (part batie 2025)",
    fill = "Profil",
    caption = "Seuils RELATIFS aux dix regions. Changer d'echantillon change la typologie."
  ) +
  theme_minimal()

print(carte_typo)

ggsave("outputs/J09_typologie_bati.png", carte_typo,
       width = 8, height = 5.5, dpi = 180)

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- TYPOLOGIE EN QUATRE PROFILS
##
## CE QUE LA CARTE CODE. Chaque region est classee dans une des quatre cases
## d'un tableau a double entree : au-dessus ou en dessous de la mediane du
## gain, au-dessus ou en dessous de la mediane de la part batie 2025.
##
## CE QUE LES CHOIX TECHNIQUES FONT. La palette est QUALITATIVE : quatre
## couleurs sans ordre implicite, parce que les profils ne sont pas
## hierarchises. Les seuils sont les MEDIANES DE L'ECHANTILLON DES DIX
## REGIONS. Par construction, cinq regions sont au-dessus et cinq en dessous,
## quelle que soit la realite. Refaite sur les 58 departements, ou sur le
## Cameroun plus le Tchad, DES REGIONS CHANGERAIENT DE CASE SANS QUE RIEN
## N'AIT BOUGE SUR LE TERRAIN. La typologie decrit une position relative dans
## un ensemble, pas une propriete intrinseque.
##
## CE QUI SE LIT. "Croissance forte et tissu deja dense" isole les regions ou
## la pression s'ajoute a une pression existante.
##
## CE QUI NE SE LIT PAS. La distance au seuil : une region juste au-dessus de
## la mediane et une region tres au-dessus portent la meme couleur. Exercice :
## remplacer les medianes par des quartiles ou par des seuils absolus, et
## compter combien de regions changent de case.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.5 DESCENDRE A L'ADM2 : LE MAUP EN ACTION
## ------------------------------------------------------------------------

departements_2015 <- resumer_bati(cmr2, bati_2015_ok, 2015, "GID_2", "NAME_2", "ADM2")
departements_2025 <- resumer_bati(cmr2, bati_2025_ok, 2025, "GID_2", "NAME_2", "ADM2")

n_dept_avant <- nrow(departements_2015)

departements_chg <- departements_2015 %>%
  sf::st_drop_geometry() %>%
  select(GID_2, NAME_2,
         bati_km2_2015 = bati_km2,
         part_batie_pct_2015 = part_batie_pct) %>%
  left_join(
    departements_2025 %>%
      sf::st_drop_geometry() %>%
      select(GID_2,
             bati_km2_2025 = bati_km2,
             part_batie_pct_2025 = part_batie_pct),
    by = "GID_2"
  ) %>%
  mutate(
    gain_bati_km2 = bati_km2_2025 - bati_km2_2015,
    croissance_pct = if_else(
      bati_km2_2015 >= seuil_bati_min_km2,
      100 * gain_bati_km2 / bati_km2_2015,
      NA_real_
    )
  ) %>%
  arrange(desc(gain_bati_km2))

cat("--- Jointure ADM2 ---\n")
cat("  lignes avant :", n_dept_avant, " | apres :", nrow(departements_chg), "\n")
cat("  NA sur bati 2025 :", sum(is.na(departements_chg$bati_km2_2025)), "\n")
cat("  departements sous le seuil de ", seuil_bati_min_km2,
    " km2 (croissance non calculee) : ",
    sum(is.na(departements_chg$croissance_pct)), " sur ",
    nrow(departements_chg), "\n", sep = "")

cat("\nLes 10 departements au plus fort gain absolu :\n")
print(departements_chg %>% slice_head(n = 10))

cat("\nLes 10 departements a la plus forte croissance relative :\n")
print(departements_chg %>%
        filter(!is.na(croissance_pct)) %>%
        arrange(desc(croissance_pct)) %>%
        slice_head(n = 10))

# MAUP : le meme phenomene, agrege a deux mailles, donne deux resultats.
dispersion <- bind_rows(
  regions_chg %>%
    summarise(maille = "ADM1 (10 regions)",
              n = n(),
              min_part = min(part_batie_pct_2025, na.rm = TRUE),
              median_part = median(part_batie_pct_2025, na.rm = TRUE),
              max_part = max(part_batie_pct_2025, na.rm = TRUE)),
  departements_chg %>%
    summarise(maille = "ADM2 (58 departements)",
              n = n(),
              min_part = min(part_batie_pct_2025, na.rm = TRUE),
              median_part = median(part_batie_pct_2025, na.rm = TRUE),
              max_part = max(part_batie_pct_2025, na.rm = TRUE))
) %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)),
         rapport_max_sur_median = round(max_part / median_part, 1))

print(dispersion)

cat("\nLa part batie NATIONALE est la meme dans les deux cas :",
    round(changement_national$part_batie_pct_2025, 4), "%\n")
cat("Mais l'ecart entre l'unite la plus batie et l'unite mediane passe d'un\n")
cat("rapport de ", dispersion$rapport_max_sur_median[1], " a ADM1 a un rapport de ",
    dispersion$rapport_max_sur_median[2], " a ADM2.\n", sep = "")

## ----------------------------------------------------------------------
## MAUP -- LE PROBLEME DE L'UNITE SPATIALE MODIFIABLE
##
## Le MAUP (Modifiable Areal Unit Problem) enonce que les resultats d'une
## analyse spatiale dependent de la maille d'agregation. Deux composantes :
##
## EFFET D'ECHELLE. Le meme bati, agrege sur 10 regions ou 58 departements, ne
## produit pas la meme distribution. Le total national est identique -- c'est
## une somme --, mais tout ce qui decrit la VARIABILITE change : ecart
## max/mediane, identite de l'unite la plus dense, nombre d'unites "sans bati
## detecte". Plus la maille est fine, plus les extremes sont extremes, parce
## que l'agregation grossiere melange dans une meme unite un centre-ville et
## sa brousse environnante.
##
## EFFET DE ZONAGE. A nombre d'unites constant, redecouper les frontieres
## change aussi les resultats. C'est le mecanisme du redecoupage electoral.
##
## REGLE PRATIQUE. Ne pas chercher la "bonne" maille : il n'y en a pas.
## Choisir la maille de la DECISION qu'on eclaire. Un arbitrage budgetaire
## entre regions se fait a l'ADM1 ; un plan d'assainissement a l'ADM2 ou plus
## fin. Et dans les deux cas, ECRIRE LA MAILLE SOUS LA CARTE.
##
## ERREUR ECOLOGIQUE. Corollaire : plus la maille est grossiere, plus il est
## tentant -- et faux -- de transferer la valeur de l'agregat aux individus.
## "Le Littoral est bati a X %" n'autorise pas "un habitant du Littoral vit
## dans une zone batie a X %".
## ----------------------------------------------------------------------

departements_carto <- departements_2025 %>%
  select(GID_2, NAME_2) %>%
  left_join(departements_chg %>% select(GID_2, gain_bati_km2, croissance_pct),
            by = "GID_2")

cat("Departements cartographies :", nrow(departements_carto),
    "| sans gain calcule :", sum(is.na(departements_carto$gain_bati_km2)), "\n")

carte_dept_gain <- ggplot(departements_carto) +
  geom_sf(aes(fill = gain_bati_km2), colour = "white", linewidth = 0.12) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0, na.value = "grey85") +
  labs(
    title = "Gain de bati 2015-2025 au niveau departemental (ADM2)",
    subtitle = "La meme donnee que la carte regionale, agregee autrement",
    fill = "Gain (km2)",
    caption = "58 departements. Gris = donnee absente, jamais zero."
  ) +
  theme_minimal()

print(carte_dept_gain)

ggsave("outputs/J09_gain_bati_adm2.png", carte_dept_gain,
       width = 8, height = 6, dpi = 180)

## ----------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI -- CE QUE LE TABLEAU NE CONTIENT PAS
##
## Le tableau departements_chg classe les 58 departements par gain : il donne
## un palmares. La carte donne trois choses de plus :
##  - LA CONTIGUITE. Les departements a fort gain forment des grappes autour
##    de Douala, de Yaounde, et le long de l'axe qui les relie. Un bloc
##    contigu ne s'explique pas par les caracteristiques propres de chaque
##    departement, mais par ce qu'ils partagent PARCE QU'ILS SONT VOISINS.
##  - LA FORME DES VIDES. Les zones sans gain dessinent l'Est forestier et le
##    Nord sahelien, deux vides d'origines totalement differentes. Un tableau
##    les met cote a cote en fin de classement sans jamais le dire.
##  - L'ECART ENTRE DEUX MAILLES. Superposer mentalement cette carte a la
##    carte regionale montre ou l'agregation masquait une heterogeneite
##    interne forte -- et c'est la que l'erreur ecologique guette.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 4.6 EXPORTS DU MODULE
## ------------------------------------------------------------------------

readr::write_csv(regions_chg, "outputs/J09_regions_bati_2015_2025.csv")
readr::write_csv(regions_typo, "outputs/J09_regions_typologie_bati.csv")
readr::write_csv(departements_chg, "outputs/J09_departements_bati_2015_2025.csv")

sf::st_write(regions_carto, "outputs/J09_regions_bati_2015_2025.gpkg",
             delete_dsn = TRUE, quiet = TRUE)
sf::st_write(departements_carto, "outputs/J09_departements_bati_2015_2025.gpkg",
             delete_dsn = TRUE, quiet = TRUE)

cat("Fichiers ecrits dans outputs/ :\n")
cat(paste0("  ", list.files("outputs", pattern = "^J09_")), sep = "\n")


## ========================================================================
## MODULE 5 -- CAS REEL : LES INONDATIONS DE YAGOUA, 2024
## ========================================================================
## 5.1 COPERNICUS EMS : LA CHAINE IMAGE -> VECTEUR -> PRODUIT
##
## Le Copernicus Emergency Management Service cartographie les zones touchees
## par une catastrophe a partir d'images satellite, en quelques heures a
## quelques jours apres l'evenement. Un Etat, une agence de l'ONU ou une ONG
## declenche une "activation" ; le service commande des images, les analyse et
## publie des couches vectorielles librement reutilisables.
##
## L'activation EMSR772 (GLIDE FL-2024-000162-CMR) porte sur les inondations
## de 2024 dans la region de YAGOUA, a l'Extreme-Nord du Cameroun, dans la
## plaine du Logone. Trois zones d'interet tres eloignees :
##   AOI01 = Yagoua  -> zone d'etude principale, modules 5 a 8
##   AOI02 = Makari  -> zone de generalisation, module 9
##   AOI03 = Waza    -> zone de generalisation, module 9
##
## Produits livres par zone :
##   areaOfInterestA : perimetre cartographie par EMS      (1 polygone)
##   floodDepthA     : polygones de CLASSE DE PROFONDEUR   (1 par zone/classe)
##   observedEventA  : emprise globale de l'evenement observe
##   imageFootprintA : etendue de l'image satellite utilisee
##
## ----------------------------------------------------------------------
## UNE DEPENDANCE A VERIFIER AVANT LA SALLE
##
## Dans le materiel source, l'archive EMSR772_AOI01_DEL_PRODUCT_v2.zip
## N'ETAIT PAS DECOMPRESSEE, et le fichier
## EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.shp -- lu a la LIGNE 90 du script
## formateur d'origine -- N'EXISTAIT NULLE PART SUR DISQUE. Les zones AOI02 et
## AOI03 etaient, elles, deja extraites. Autrement dit : le module central de
## la journee dependait d'un fichier absent. Le script n'aurait pas demarre.
##
## Ce script lit les shapefiles DEJA EXTRAITS ET RENOMMES A PLAT dans
## datasets/. Tous les unzip() d'EMSR772 du script source ont ete SUPPRIMES :
## un dossier de donnees est un dossier d'entrees, on n'y ecrit pas pendant
## une seance. Quelqu'un doit avoir extrait l'archive AOI01 en amont et
## verifie que floodDepthA en sort bien. C'est le point 1 de _A_FAIRE_J09.md.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 5.2 LIRE LES COUCHES EMSR772, A PLAT
## ------------------------------------------------------------------------

# Lecture unique, avec reparation immediate. Les produits de cartographie
# rapide contiennent frequemment des auto-intersections : sans
# st_make_valid(), le st_intersection() du module 8 echoue.
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

# Superficie de l'AOI officielle, mesuree dans le CRS de mesure.
if (!is.null(aoi01_complet)) {
  surf_aoi_officielle <- as.numeric(
    sum(sf::st_area(sf::st_transform(aoi01_complet, crs_mesure)))
  ) / 1e6
  cat("Surface de l'AOI01 officielle :", round(surf_aoi_officielle, 0), "km2\n")
  cat("Emprise (degres) :\n")
  print(sf::st_bbox(aoi01_complet))
  if ("locality" %in% names(aoi01_complet))
    cat("Localite declaree :", paste(aoi01_complet$locality, collapse = ", "), "\n")
}

## ------------------------------------------------------------------------
## 5.3 LA FENETRE D'ETUDE : UNE REDUCTION ASSUMEE
## ------------------------------------------------------------------------

# ----------------------------------------------------------------------
# CHOIX DE METHODE, A ENONCER EN SALLE
# ----------------------------------------------------------------------
# L'AOI01 officielle couvre ~6 870 km2 (plus de 100 km de large) et contient
# plus de 400 000 batiments Open Buildings a confidence >= 0,7. Toutes les
# operations de cette journee y deviendraient trop lentes pour une seance.
# On reduit a une fenetre ad hoc de 5 x 5 km, centree sur le secteur le plus
# densement inonde, pres de Yagoua.
#
# CONSEQUENCE, a repeter : TOUS les chiffres des modules 5 a 8 portent sur
# cette fenetre, PAS sur l'AOI01 officielle. Ils ne doivent jamais etre cites
# comme un bilan de l'inondation de Yagoua.
# ----------------------------------------------------------------------
fenetre_zoom <- sf::st_bbox(
  c(xmin = 15.31957, ymin = 10.22218, xmax = 15.36528, ymax = 10.26745),
  crs = sf::st_crs(aoi01_complet)
)

aoi01 <- sf::st_intersection(aoi01_complet, sf::st_as_sfc(fenetre_zoom))
aoi01 <- sf::st_make_valid(aoi01)
flood01 <- sf::st_filter(flood01_complet, aoi01)

surf_aoi01 <- as.numeric(
  sum(sf::st_area(sf::st_transform(aoi01, crs_mesure)))
) / 1e6

cat("--- Reduction de fenetre ---\n")
cat("  AOI01 : ", nrow(aoi01_complet), " -> ", nrow(aoi01), " polygone(s)\n", sep = "")
cat("  flood : ", nrow(flood01_complet), " -> ", nrow(flood01),
    " polygone(s)\n", sep = "")
cat("  surface retenue :", round(surf_aoi01, 2), "km2 sur",
    round(surf_aoi_officielle, 0), "km2 officiels, soit",
    round(100 * surf_aoi01 / surf_aoi_officielle, 2), "%\n")
cat("  CRS conserve :", sf::st_crs(aoi01)$input, "\n")

# Structure de la table floodDepth : une ligne = un polygone d'une classe.
colonnes_utiles <- intersect(c("obj_desc", "value", "det_method", "event_type"),
                            names(flood01))
cat("Colonnes descriptives presentes :", paste(colonnes_utiles, collapse = ", "), "\n\n")

print(flood01 %>% sf::st_drop_geometry() %>% select(all_of(colonnes_utiles)))

cat("\nClasses de profondeur presentes dans la fenetre :\n")
print(table(flood01$value, useNA = "ifany"))

# Surface inondee : mesuree en UTM 33N. En degres, ce chiffre serait faux.
flood01_mesure <- sf::st_transform(flood01, crs_mesure)
surface_par_classe <- flood01 %>%
  sf::st_drop_geometry() %>%
  mutate(surface_km2 = as.numeric(sf::st_area(flood01_mesure)) / 1e6) %>%
  group_by(value) %>%
  summarise(nb_polygones = n(),
            surface_km2 = round(sum(surface_km2), 3),
            .groups = "drop") %>%
  arrange(value) %>%
  mutate(part_de_la_fenetre_pct = round(100 * surface_km2 / surf_aoi01, 1))

print(surface_par_classe)

surface_inondee_km2 <- sum(surface_par_classe$surface_km2)
cat("\nSurface inondee totale dans la fenetre :", round(surface_inondee_km2, 3),
    "km2, soit", round(100 * surface_inondee_km2 / surf_aoi01, 1),
    "% de la fenetre\n")

## ----------------------------------------------------------------------
## "CLASSE DE PROFONDEUR" N'EST PAS UNE MESURE IN SITU
##
## La colonne value contient des tranches du type "0.50 - 1.00", en metres.
## Il est tentant de les lire comme des releves de hauteur d'eau. Ce n'en sont
## pas.
##
## COMMENT CES CLASSES SONT PRODUITES. Un operateur delimite l'etendue de
## l'eau sur une image -- le plus souvent une image RADAR Sentinel-1, parce
## qu'elle traverse les nuages et fonctionne de nuit. Puis la hauteur d'eau
## est ESTIMEE en croisant cette etendue avec un modele numerique de terrain.
## La precision du resultat est donc celle du modele de terrain -- souvent
## quelques metres en vertical, soit le meme ordre que les classes qu'on
## pretend distinguer.
##
## CE QUE CELA IMPLIQUE.
##  - Les classes sont ORDONNEES, mais leurs bornes ne sont pas des mesures.
##  - La donnee est DATEE : elle decrit l'eau au moment de l'acquisition. Une
##    image prise trois jours plus tot donnerait une autre carte. Le produit
##    n'est pas "l'inondation de Yagoua 2024", c'est "l'eau visible ce
##    jour-la".
##  - L'eau SOUS COUVERT VEGETAL OU SOUS LES TOITS est mal detectee. Un
##    quartier peut avoir les pieds dans l'eau sans figurer dans un polygone.
##
## Ces trois limites S'AJOUTENT -- elles ne se compensent pas -- et elles vont
## toutes dans le sens d'une SOUS-ESTIMATION de l'exposition.
## ----------------------------------------------------------------------

carte_flood <- ggplot() +
  geom_sf(data = aoi01, fill = "grey95", colour = "steelblue", linewidth = 0.9) +
  geom_sf(data = flood01, aes(fill = value), colour = NA, alpha = 0.85) +
  scale_fill_brewer(palette = "YlOrRd", na.value = "grey70") +
  labs(
    title = "EMSR772 -- AOI01 (Yagoua) : classes de profondeur d'inondation",
    subtitle = paste0("Fenetre d'etude de ", round(surf_aoi01, 1),
                      " km2 -- PAS l'AOI01 officielle de ",
                      round(surf_aoi_officielle, 0), " km2"),
    fill = "Profondeur (m)",
    caption = "Source : Copernicus EMS, activation EMSR772 (2024)."
  ) +
  theme_minimal()

print(carte_flood)

ggsave("outputs/J09_carte_flood_aoi01.png", carte_flood,
       width = 8, height = 6, dpi = 180)

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- PROFONDEURS D'INONDATION
##
## CE QUE LA CARTE CODE. Chaque polygone colore est une zone qu'un operateur
## Copernicus EMS a classee dans une tranche de profondeur ESTIMEE. Le contour
## bleu est la fenetre d'etude, pas l'AOI officielle. Le fond gris clair est
## la partie NON CLASSEE comme inondee -- ce qui ne veut pas dire "seche",
## mais "pas detectee comme inondee sur l'image utilisee".
##
## CE QUE LES CHOIX TECHNIQUES FONT. La palette YlOrRd est SEQUENTIELLE et
## appliquee a une variable ORDINALE. Attention : value est lue comme du
## TEXTE, donc l'ordre alphabetique coincide ici avec l'ordre numerique par
## chance, pas par construction -- verifier ce point sur toute autre
## activation. Les polygones sont traces sans bordure : a cette echelle, des
## contours noirs rempliraient l'image de traits.
##
## CE QUI SE LIT. L'eau suit un RESEAU, pas une tache : elle epouse des
## chenaux, des depressions, d'anciens bras. Signature d'une inondation de
## plaine alluviale, tres differente d'une inondation urbaine par
## ruissellement qui remplirait des cuvettes fermees.
##
## CE QUI NE SE LIT PAS. Ni la duree de la submersion -- la carte est un
## instantane -- ni la vitesse du courant, ni le nombre de personnes. Et
## surtout, la FORME ETROITE ET DECOUPEE de ces polygones est le facteur qui
## va faire diverger les deux methodes de comptage du module 7. Ce n'est pas
## un detail esthetique : c'est la cause du desaccord.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 6 -- COMPTER LES EXPOSES : GOOGLE OPEN BUILDINGS
## ========================================================================
## 6.1 CE QU'EST OPEN BUILDINGS
##
## Base d'empreintes de batiments produite par Google Research a partir
## d'imagerie a tres haute resolution, couvrant l'Afrique et l'Asie du Sud.
## Distribuee par tuile, en CSV compresse, sous licence CC BY 4.0.
##   latitude, longitude : position du CENTROIDE (ce sont des points)
##   geometry            : empreinte polygonale (WKT) -- c'est elle qui porte
##                         la forme
##   area_in_meters      : surface ESTIMEE par le modele, pas mesuree
##   confidence          : probabilite que l'objet soit un batiment (0 a 1)
##                         -- LE PARAMETRE LE PLUS LOURD DE LA JOURNEE
##   full_plus_code      : identifiant, sans usage analytique ici
##
## Les tuiles brutes pesent plusieurs Go. Le fichier livre,
## open_buildings_yagoua.gpkg, est deja restreint a l'AOI01 officielle plus
## une marge de 5 km, produit une fois par
## scripts/preparation/preparer_open_buildings_J09.R -- dont c'est la seule
## raison d'exister : TRACER LA PROVENANCE.
## ------------------------------------------------------------------------

chemin_ob <- "datasets/open_buildings_yagoua.gpkg"

if (file.exists(chemin_ob)) {
  cat("Couches du GeoPackage :\n")
  print(sf::st_layers(chemin_ob))
}

batiments_source <- sf::st_read(chemin_ob, quiet = TRUE)

cat("\n--- Open Buildings (zone de Yagoua, deja restreinte) ---\n")
cat("  batiments      :", format(nrow(batiments_source), big.mark = " "), "\n")
cat("  colonnes       :", paste(names(batiments_source), collapse = ", "), "\n")
cat("  CRS            :", sf::st_crs(batiments_source)$input, "\n")
cat("  type geometrie :",
    paste(unique(as.character(sf::st_geometry_type(batiments_source))),
          collapse = ", "), "\n")
print(sf::st_bbox(batiments_source))

# On ne suppose PAS que les colonnes existent : on verifie.
colonnes_attendues <- c("latitude", "longitude", "area_in_meters", "confidence")
for (col in colonnes_attendues) {
  cat("  colonne", col, ":",
      if (col %in% names(batiments_source)) "presente" else "*** ABSENTE ***", "\n")
}

print(head(sf::st_drop_geometry(batiments_source), 3))

## ------------------------------------------------------------------------
## 6.2 LE SEUIL DE CONFIANCE : UN PARAMETRE, PAS UNE DONNEE
## ------------------------------------------------------------------------

# Le seuil est declare ICI, une fois, en variable nommee. Il n'est jamais
# ecrit en dur au milieu d'un filter().
seuil_confiance <- 0.7

if ("confidence" %in% names(batiments_source)) {

  cat("Distribution du champ confidence :\n")
  print(round(summary(batiments_source$confidence), 3))

  repartition_conf <- batiments_source %>%
    sf::st_drop_geometry() %>%
    mutate(conf_classe = cut(confidence, c(0, 0.5, 0.7, 1),
                             labels = c("<0.5", "0.5-0.7", ">=0.7"),
                             include.lowest = TRUE)) %>%
    count(conf_classe, name = "nb") %>%
    mutate(pct = round(100 * nb / sum(nb), 1))

  print(repartition_conf)

  # Sensibilite du comptage au seuil : c'est CE tableau qui doit etre montre,
  # pas le seul chiffre a 0,7.
  sensibilite <- lapply(c(0.5, 0.6, 0.65, 0.7, 0.75, 0.8, 0.9), function(s) {
    data.frame(seuil = s,
               nb_batiments = sum(batiments_source$confidence >= s, na.rm = TRUE))
  }) %>%
    bind_rows() %>%
    mutate(
      ecart_vs_07_pct = round(
        100 * (nb_batiments - nb_batiments[seuil == 0.7]) /
          nb_batiments[seuil == 0.7], 1)
    )

  cat("\nSensibilite du comptage au seuil de confiance :\n")
  print(sensibilite)

} else {
  cat("*** Colonne 'confidence' absente : le seuil ne peut pas etre applique.\n")
  cat("*** Verifier le contenu de open_buildings_yagoua.gpkg (_A_FAIRE_J09.md).\n")
}

## ----------------------------------------------------------------------
## POURQUOI 0,7 -- ET CE QUE CE CHIFFRE DECIDE
##
## confidence est la probabilite, estimee par le modele de Google, que l'objet
## detecte soit reellement un batiment. Le seuil arbitre entre deux erreurs,
## et il n'existe pas de valeur "juste" dans l'absolu :
##  - SEUIL BAS (0,5) : peu de batiments manques, mais des objets qui n'en
##    sont pas passent dans le compte -- rochers, tas de terre, ombres
##    portees, meules. En estimation de population, un faux positif ajoute
##    cinq habitants imaginaires.
##  - SEUIL HAUT (0,8+) : compte plus sur, mais les constructions petites, en
##    materiaux legers, ou masquees par des arbres disparaissent. Or ce sont
##    precisement les habitations les plus vulnerables. LE BIAIS N'EST PAS
##    ALEATOIRE : il frappe systematiquement les plus pauvres.
##
## 0,7 est un COMPROMIS CONVENTIONNEL, aligne sur la pratique courante des
## analyses humanitaires. Ce n'est pas une propriete des donnees.
##
## REGLE DE METHODE. Le seuil doit etre (1) declare dans le code en variable
## nommee, (2) ecrit dans le rapport, (3) accompagne d'un test de sensibilite.
## Un resultat qui bascule entre 0,65 et 0,75 n'est pas un resultat : c'est le
## seuil qu'on lit, pas le territoire. Pour une decision operationnelle, mieux
## vaut publier une fourchette "0,6 a 0,8" qu'un chiffre unique faussement
## precis.
## ----------------------------------------------------------------------

# --- 1. Restreindre a la fenetre d'etude -----------------------------------
if (sf::st_crs(batiments_source) != sf::st_crs(aoi01)) {
  cat("Harmonisation des CRS avant filtre spatial :\n")
  cat("  batiments :", sf::st_crs(batiments_source)$input, "\n")
  cat("  aoi01     :", sf::st_crs(aoi01)$input, "\n")
  batiments_source <- sf::st_transform(batiments_source, sf::st_crs(aoi01))
} else {
  cat("CRS deja identiques :", sf::st_crs(aoi01)$input, "\n")
}

n_avant_fenetre <- nrow(batiments_source)
batiments_fenetre <- sf::st_filter(batiments_source, aoi01)
cat("Batiments : ", format(n_avant_fenetre, big.mark = " "), " -> ",
    format(nrow(batiments_fenetre), big.mark = " "),
    " apres restriction a la fenetre\n", sep = "")

# --- 2. Appliquer le seuil de confiance ------------------------------------
if ("confidence" %in% names(batiments_fenetre)) {
  batiments_ok <- batiments_fenetre %>% filter(confidence >= seuil_confiance)
} else {
  batiments_ok <- batiments_fenetre
  cat("*** Seuil non applique (colonne absente) ***\n")
}

cat("Batiments a confidence >= ", seuil_confiance, " : ",
    format(nrow(batiments_ok), big.mark = " "),
    " (", round(100 * nrow(batiments_ok) / max(nrow(batiments_fenetre), 1), 1),
    " % de la fenetre)\n", sep = "")

# --- 3. Version ponctuelle, pour le comptage point-dans-polygone -----------
# L'ordre c(longitude, latitude) est IMPERATIF : inverser ne leve aucune
# erreur, cela place simplement les points ailleurs.
if (all(c("longitude", "latitude") %in% names(batiments_ok))) {
  batiments_pts <- batiments_ok %>%
    sf::st_drop_geometry() %>%
    sf::st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
  cat("Points reconstruits depuis les colonnes longitude / latitude.\n")
} else {
  batiments_pts <- sf::st_centroid(batiments_ok)
  cat("Colonnes lon/lat absentes : centroides calcules par st_centroid().\n")
}

batiments_pts <- sf::st_transform(batiments_pts, sf::st_crs(aoi01))

# CONTROLE : les points doivent tomber dans la fenetre. S'ils n'y sont pas,
# c'est que longitude et latitude ont ete inversees.
dans_fenetre <- lengths(sf::st_intersects(batiments_pts, aoi01)) > 0
cat("Points tombant dans la fenetre :", sum(dans_fenetre), "sur",
    nrow(batiments_pts), "\n")
if (sum(dans_fenetre) < 0.9 * nrow(batiments_pts))
  cat("*** ALERTE : verifier l'ordre c(longitude, latitude) ***\n")

batiments_aoi01 <- batiments_pts[dans_fenetre, ]
cat("Batiments retenus dans AOI01 (fenetre) :",
    format(nrow(batiments_aoi01), big.mark = " "), "\n")

## ------------------------------------------------------------------------
## 6.3 BATIMENTS TOUCHES ET VENTILATION PAR CLASSE
## ------------------------------------------------------------------------

# st_filter() utilise par defaut le predicat st_intersects : un batiment est
# "touche" si son POINT intersecte au moins un polygone de floodDepth.
batiments_inondes <- sf::st_filter(batiments_aoi01, flood01)

pct_bat_inondes <- 100 * nrow(batiments_inondes) / max(nrow(batiments_aoi01), 1)

cat("Batiments dans la fenetre  :",
    format(nrow(batiments_aoi01), big.mark = " "), "\n")
cat("Batiments touches          :",
    format(nrow(batiments_inondes), big.mark = " "), "\n")
cat("Part touchee               :", round(pct_bat_inondes, 1), "%\n")

# ----------------------------------------------------------------------
# HYPOTHESE EXPLICITE, a ecrire sous chaque chiffre qui en decoule
# ----------------------------------------------------------------------
# On convertit un nombre de batiments en un nombre de personnes en supposant
# un taux d'occupation moyen. 5 personnes par batiment correspond a un ordre
# de grandeur de milieu rural / semi-urbain au nord du Cameroun. Ce n'est PAS
# une mesure : c'est un parametre.
# ----------------------------------------------------------------------
pers_par_batiment <- 5

pop_aoi01    <- nrow(batiments_aoi01) * pers_par_batiment
pop_inondee  <- nrow(batiments_inondes) * pers_par_batiment

cat("Population estimee dans la fenetre :",
    format(pop_aoi01, big.mark = " "), "personnes\n")
cat("Population estimee touchee         :",
    format(pop_inondee, big.mark = " "), "personnes\n")
cat("  (hypothese :", pers_par_batiment, "personnes par batiment)\n")

# Sensibilite a l'hypothese : le meme comptage sous cinq taux d'occupation.
sensibilite_pop <- data.frame(
  pers_par_batiment = c(3, 4, 5, 6, 7)
) %>%
  mutate(
    pop_fenetre = nrow(batiments_aoi01) * pers_par_batiment,
    pop_touchee = nrow(batiments_inondes) * pers_par_batiment
  )

cat("\nSensibilite a l'hypothese d'occupation :\n")
print(sensibilite_pop)

## ----------------------------------------------------------------------
## L'HYPOTHESE x 5 : CE QU'ELLE FAIT, ET CE QU'ELLE NE FAIT PAS
##
## CE QU'ELLE FAIT. Elle transforme un objet physique compte par un
## algorithme (un toit) en une grandeur demographique (des personnes). C'est
## un changement de NATURE, pas un changement d'unite.
##
## TROIS RAISONS DE S'EN MEFIER.
##  1. TOUS LES BATIMENTS NE SONT PAS HABITES. Greniers, hangars, latrines,
##     enclos : dans un village sahelien, une concession compte plusieurs
##     constructions pour un seul menage. Le facteur 5 surestime alors.
##  2. LA TAILLE DES MENAGES VARIE FORTEMENT. Entre l'Extreme-Nord et Douala,
##     le rapport va du simple au triple. Un facteur unique aplatit
##     exactement la variation qu'on cherche a decrire.
##  3. LE FACTEUR EST CONSTANT, DONC L'ERREUR EST PROPORTIONNELLE. Point
##     crucial : puisque pop = nb x 5, la PART de population touchee est
##     rigoureusement egale a la PART de batiments touches. Le facteur
##     s'annule au numerateur et au denominateur. Il n'apporte donc AUCUNE
##     information au pourcentage -- il habille un comptage de batiments en
##     langage demographique, ce qui lui donne une autorite qu'il n'a pas.
##
## CE QU'IL FAUT EN FAIRE. Publier le nombre de batiments, qui est ce qu'on a
## mesure. Publier la population comme un ORDRE DE GRANDEUR ASSORTI D'UNE
## FOURCHETTE. Et la confronter a une source independante : c'est le module 7.
## ----------------------------------------------------------------------

# st_join() peut DUPLIQUER des lignes : un batiment situe a la limite de deux
# polygones de profondeur sera apparie deux fois. On compte avant / apres.
n_avant_join <- nrow(batiments_inondes)

batiments_depth <- sf::st_join(batiments_inondes, flood01["value"])

n_apres_join <- nrow(batiments_depth)
cat("--- st_join(batiments, flood) ---\n")
cat("  lignes avant :", n_avant_join, " | apres :", n_apres_join, "\n")
cat("  duplications :", n_apres_join - n_avant_join, "\n")
cat("  appariements sans classe (NA) :", sum(is.na(batiments_depth$value)), "\n")

if (n_apres_join > n_avant_join) {
  cat("  -> des batiments chevauchent deux polygones de profondeur.\n")
  cat("  -> on ne garde qu'une ligne par batiment (la premiere classe).\n")
  batiments_depth <- batiments_depth[!duplicated(sf::st_coordinates(batiments_depth)), ]
  cat("  lignes apres deduplication :", nrow(batiments_depth), "\n")
}

ventilation <- batiments_depth %>%
  sf::st_drop_geometry() %>%
  count(value, name = "nb_batiments") %>%
  arrange(value) %>%
  mutate(
    pop_estimee = nb_batiments * pers_par_batiment,
    part_pct    = round(100 * nb_batiments / sum(nb_batiments), 1)
  )

cat("\nBatiments touches par classe de profondeur :\n")
print(ventilation)

bilan_aoi01 <- tibble::tibble(
  zone                  = "AOI01 (fenetre 5x5 km)",
  nb_batiments_aoi      = nrow(batiments_aoi01),
  nb_batiments_inondes  = nrow(batiments_inondes),
  pct_batiments_inondes = round(pct_bat_inondes, 1),
  pop_estimee_aoi       = pop_aoi01,
  pop_inondee           = pop_inondee
)

print(bilan_aoi01)

if (nrow(ventilation) > 0) {
  g_vent <- ggplot(ventilation, aes(x = value, y = nb_batiments, fill = value)) +
    geom_col() +
    geom_text(aes(label = nb_batiments), vjust = -0.4, size = 3.4) +
    scale_fill_brewer(palette = "YlOrRd", guide = "none") +
    labs(
      title = "Batiments touches par classe de profondeur d'inondation",
      subtitle = paste0("Fenetre de ", round(surf_aoi01, 1),
                        " km2 pres de Yagoua -- seuil de confiance ",
                        seuil_confiance),
      x = "Classe de profondeur estimee (m)",
      y = "Nombre de batiments"
    ) +
    theme_minimal()
  print(g_vent)
  ggsave("outputs/J09_batiments_par_profondeur.png", g_vent,
         width = 8, height = 4.5, dpi = 180)
}

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- VENTILATION PAR CLASSE DE PROFONDEUR
##
## CE QUE LA FIGURE CODE. Une barre = une classe de profondeur ESTIMEE. Sa
## hauteur est le nombre de batiments dont le CENTROIDE tombe dans un polygone
## de cette classe. "Batiment" = objet detecte par Open Buildings avec une
## confiance >= 0,7 ; "classe de profondeur" = estimation EMS croisant
## l'etendue d'eau avec un modele de terrain.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Trois decisions determinent entierement
## ces hauteurs. LE SEUIL DE 0,7 fixe qui est un batiment. LE PREDICAT
## st_intersects SUR DES POINTS fixe qui est touche : un batiment dont le toit
## chevauche une zone inondee mais dont le centroide est en dehors compte pour
## non touche. LA DEDUPLICATION apres st_join() fixe la classe attribuee a un
## batiment a cheval sur deux polygones -- on garde la premiere, c'est
## arbitraire.
##
## CE QUI SE LIT. La distribution est tres desequilibree : la majorite des
## batiments touches le sont par les classes les moins profondes. Cela oriente
## la reponse operationnelle.
##
## CE QUI NE SE LIT PAS. Le nombre de personnes. La duree de la submersion. La
## VULNERABILITE du bati -- une case en banco et une maison en parpaings ne
## reagissent pas a la meme hauteur d'eau, et Open Buildings ne dit rien du
## materiau. Une classe absente du graphique ne signifie pas "aucun batiment a
## cette profondeur" : elle peut signifier "aucun polygone de cette classe
## dans la fenetre retenue".
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 7 -- DEUX METHODES, DEUX REPONSES
## ========================================================================
## C'est le moment le plus important de la journee. On confronte l'estimation
## fondee sur le comptage de batiments a une source INDEPENDANTE : la grille
## WorldPop 2024, construite a partir de donnees censitaires et de covariables
## satellitaires, a 100 m. L'enjeu n'est pas de designer un gagnant : c'est de
## comprendre POURQUOI deux methodes defendables donnent des reponses
## differentes, et de savoir laquelle repond a quelle question.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## 7.1 OUVRIR ET CONTROLER LA GRILLE WORLDPOP
## ------------------------------------------------------------------------

chemin_worldpop <- "datasets/cmr_pop_2024_CN_100m_R2025A_v1.tif"

worldpop <- terra::rast(chemin_worldpop)

cat("--- Raster WorldPop 2024 (Cameroun, 100 m) ---\n")
print(worldpop)
cat("\nResolution :", paste(res(worldpop), collapse = " x "), "\n")
cat("CRS        :", terra::crs(worldpop, describe = TRUE)$name,
    "(EPSG:", terra::crs(worldpop, describe = TRUE)$code, ")\n")
cat("Coordonnees geographiques (degres) :", terra::is.lonlat(worldpop), "\n")
if (terra::is.lonlat(worldpop))
  cat("  taille approx. du pixel :",
      round(res(worldpop)[1] * 111320), "m a l'equateur\n")
cat("Emprise :\n")
print(terra::ext(worldpop))

# La fenetre d'etude est-elle bien DANS l'emprise du raster ? Une extraction
# hors emprise ne leve pas d'erreur : elle renvoie NA ou 0.
bb_aoi <- sf::st_bbox(sf::st_transform(aoi01, terra::crs(worldpop)))
e_wp   <- terra::ext(worldpop)
couvre <- bb_aoi["xmin"] >= e_wp[1] && bb_aoi["xmax"] <= e_wp[2] &&
          bb_aoi["ymin"] >= e_wp[3] && bb_aoi["ymax"] <= e_wp[4]
cat("\nLa fenetre d'etude est contenue dans l'emprise WorldPop :", couvre, "\n")
if (!couvre)
  cat("*** ALERTE : extraction partiellement hors emprise, resultats non fiables ***\n")

cat("Population nationale WorldPop 2024 (somme du raster) :",
    format(round(as.numeric(terra::global(worldpop, "sum", na.rm = TRUE)[1, 1])),
           big.mark = " "), "habitants\n")

## ------------------------------------------------------------------------
## 7.2 L'EXTRACTION ZONALE, ET CE QUE exact_extract FAIT EXACTEMENT
## ------------------------------------------------------------------------

# Harmonisation des CRS AVANT extraction, et affichage de la decision.
aoi01_wp <- sf::st_transform(aoi01, terra::crs(worldpop))
cat("CRS aoi01 -> CRS worldpop :", sf::st_crs(aoi01)$input, "->",
    sf::st_crs(aoi01_wp)$input, "\n")

pop_aoi01_worldpop <- sum(
  exactextractr::exact_extract(worldpop, aoi01_wp, "sum", progress = FALSE)
)

# Union des polygones d'inondation : sans elle, un habitant situe sous deux
# polygones qui se recouvrent serait compte deux fois.
flood01_union <- sf::st_union(flood01)
flood01_union_sf <- sf::st_transform(sf::st_as_sf(flood01_union),
                                     terra::crs(worldpop))

cat("Polygones flood avant union :", nrow(flood01),
    "| apres union :", length(flood01_union), "\n")

pop_inondee_worldpop <- sum(
  exactextractr::exact_extract(worldpop, flood01_union_sf, "sum",
                               progress = FALSE)
)

cat("\nWorldPop -- population de la fenetre :",
    format(round(pop_aoi01_worldpop), big.mark = " "), "\n")
cat("WorldPop -- population en zone inondee :",
    format(round(pop_inondee_worldpop), big.mark = " "), "\n")
cat("WorldPop -- part de la population en zone inondee :",
    round(100 * pop_inondee_worldpop / pop_aoi01_worldpop, 1), "%\n")

## ----------------------------------------------------------------------
## CE QUE FAIT exact_extract, ET POURQUOI CELA CHANGE LE RESULTAT
##
## Quand un polygone recouvre une grille, la question "quelle population
## contient-il ?" n'a pas de reponse evidente pour les cellules coupees.
##
## terra::extract() par defaut applique LA REGLE DU CENTRE : une cellule
## compte pour le polygone dans lequel tombe son centre, entierement ou pas du
## tout.
##
## exact_extract() calcule, pour chaque cellule, la FRACTION DE SA SURFACE
## couverte par le polygone, et pondere la valeur par cette fraction. Une
## cellule couverte a 30 % contribue pour 30 % de ses habitants.
##
## QUAND L'ECART DEVIENT DECISIF. Il croit quand la taille des polygones se
## rapproche de celle des cellules, et quand les polygones sont ETROITS ET
## DECOUPES -- exactement le cas de floodDepth. Un couloir d'inondation de
## 60 m de large sur une grille de 100 m ne contient presque aucun centre de
## cellule : la regle du centre y renverrait une population proche de zero.
##
## CONTREPARTIE A ENONCER. La ponderation par fraction suppose que la
## population est UNIFORMEMENT REPARTIE A L'INTERIEUR DE CHAQUE CELLULE DE
## 100 m. C'est faux a cette echelle : dans une cellule qui contient un hameau
## et un champ, tout le monde est du cote du hameau. exact_extract ne mesure
## donc pas la population du couloir inonde ; il mesure la population de la
## surface, sous l'hypothese d'homogeneite intracellulaire. C'est mieux que la
## regle du centre, ce n'est pas la verite.
## ----------------------------------------------------------------------

## ------------------------------------------------------------------------
## 7.3 LA CONFRONTATION
## ------------------------------------------------------------------------

# Troisieme methode, plus robuste sur des polygones etroits : ponderer par la
# SURFACE BATIE inondee plutot que compter des centroides.
part_surface_batie_inondee <- NA_real_
geom_types <- unique(as.character(sf::st_geometry_type(batiments_ok)))

if (any(grepl("POLYGON", geom_types))) {
  bat_mesure <- sf::st_transform(batiments_ok, crs_mesure)
  bat_mesure$surface_m2 <- as.numeric(sf::st_area(bat_mesure))

  flood_mesure <- sf::st_transform(sf::st_as_sf(flood01_union), crs_mesure)

  inter_bati <- tryCatch(
    sf::st_intersection(bat_mesure, flood_mesure),
    error = function(e) { cat("st_intersection echouee :",
                              conditionMessage(e), "\n"); NULL }
  )

  if (!is.null(inter_bati) && nrow(inter_bati) > 0) {
    surf_batie_totale  <- sum(bat_mesure$surface_m2, na.rm = TRUE)
    surf_batie_inondee <- sum(as.numeric(sf::st_area(inter_bati)), na.rm = TRUE)
    part_surface_batie_inondee <- 100 * surf_batie_inondee / surf_batie_totale

    cat("--- Troisieme methode : surface batie inondee ---\n")
    cat("  surface batie totale  :", round(surf_batie_totale), "m2\n")
    cat("  surface batie inondee :", round(surf_batie_inondee), "m2\n")
    cat("  part de la surface batie inondee :",
        round(part_surface_batie_inondee, 1), "%\n")
    cat("  (a comparer aux", round(pct_bat_inondes, 1),
        "% obtenus en comptant des centroides)\n")
  }
} else {
  cat("Geometries non polygonales (", paste(geom_types, collapse = ", "),
      ") : la troisieme methode n'est pas calculable.\n", sep = "")
}

comparaison_pop <- tibble::tibble(
  methode = c("Batiments x 5 personnes",
              "WorldPop 2024 (raster 100 m)"),
  pop_fenetre = round(c(pop_aoi01, pop_aoi01_worldpop)),
  pop_zone_inondee = round(c(pop_inondee, pop_inondee_worldpop))
) %>%
  mutate(
    part_inondee_pct = round(100 * pop_zone_inondee / pop_fenetre, 1)
  )

cat("=== Comparaison des deux methodes d'estimation (fenetre AOI01) ===\n")
print(comparaison_pop)

ecart_total <- 100 * (comparaison_pop$pop_fenetre[1] -
                        comparaison_pop$pop_fenetre[2]) /
  comparaison_pop$pop_fenetre[2]
ecart_inonde <- 100 * (comparaison_pop$pop_zone_inondee[1] -
                         comparaison_pop$pop_zone_inondee[2]) /
  comparaison_pop$pop_zone_inondee[2]

cat("\nEcart relatif sur la population TOTALE de la fenetre :",
    round(ecart_total, 1), "%\n")
cat("Ecart relatif sur la population EN ZONE INONDEE      :",
    round(ecart_inonde, 1), "%\n")
cat("\nRapport des deux ecarts :",
    round(abs(ecart_inonde) / max(abs(ecart_total), 0.01), 1),
    ": c'est ce rapport qui est le resultat du module.\n")

readr::write_csv(comparaison_pop, "outputs/J09_comparaison_methodes_population.csv")

comp_long <- comparaison_pop %>%
  select(methode, pop_fenetre, pop_zone_inondee) %>%
  tidyr::pivot_longer(-methode, names_to = "perimetre", values_to = "population") %>%
  mutate(perimetre = recode(perimetre,
                            pop_fenetre = "Fenetre entiere",
                            pop_zone_inondee = "Zone inondee"))

g_comp <- ggplot(comp_long, aes(x = perimetre, y = population, fill = methode)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = format(population, big.mark = " ")),
            position = position_dodge(width = 0.9), vjust = -0.4, size = 3.2) +
  scale_fill_manual(values = c("Batiments x 5 personnes" = "#AEC6CF",
                               "WorldPop 2024 (raster 100 m)" = "#C23B22")) +
  labs(
    title = "Deux methodes independantes, deux reponses",
    subtitle = "Elles s'accordent sur la fenetre entiere et divergent sur la zone inondee",
    x = NULL, y = "Personnes (estimation)", fill = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(g_comp)

ggsave("outputs/J09_comparaison_methodes.png", g_comp,
       width = 8, height = 4.5, dpi = 180)

## ----------------------------------------------------------------------
## POURQUOI LES DEUX METHODES DIVERGENT EN ZONE INONDEE
## (le raisonnement central de la journee -- le derouler lentement)
##
## SUR LA FENETRE ENTIERE, ELLES S'ACCORDENT -- meme ordre de grandeur. C'est
## deja une information : cela valide raisonnablement l'hypothese de 5
## personnes par batiment SUR CETTE ZONE PRECISE. Deux chaines de production
## independantes -- l'une part de toits detectes par Google, l'autre de
## recensements desagreges par WorldPop -- convergent. C'est le meilleur
## argument dont on dispose pour utiliser le facteur 5 ici, et IL NE SE
## TRANSPORTE PAS AILLEURS.
##
## SUR LA ZONE INONDEE, ELLES DIVERGENT NETTEMENT. La cause n'est ni un bug ni
## une erreur de donnees : c'est une difference de GEOMETRIE DU COMPTAGE.
##  - La methode "batiments" demande : LE CENTROIDE DE CE BATIMENT TOMBE-T-IL
##    DANS UN POLYGONE D'INONDATION ? Question BINAIRE, SUR UN POINT. Or les
##    polygones floodDepth sont ETROITS ET DECOUPES : beaucoup de batiments
##    les bordent sans que leur centre y tombe. Un batiment a moitie dans
##    l'eau compte pour zero.
##  - La methode "WorldPop" demande : QUELLE FRACTION DE SURFACE DE CHAQUE
##    CELLULE CE POLYGONE RECOUVRE-T-IL ? Question CONTINUE, SUR UNE SURFACE.
##    Un couloir qui traverse une cellule peuplee en recupere une part
##    proportionnelle, meme s'il ne contient aucune habitation.
##
## LES DEUX ONT UN BIAIS, ET ILS SONT DE SENS OPPOSES.
##  - Le comptage de centroides SOUS-ESTIME : il rejette tout batiment dont le
##    centre manque le polygone de peu, alors qu'un batiment a cheval sur une
##    zone inondee est sinistre.
##  - L'extraction ponderee SURESTIME : elle suppose la population
##    uniformement repartie dans chaque cellule de 100 m, alors qu'en plaine
##    inondable les habitants sont groupes plutot sur les points hauts. Le
##    couloir d'eau recupere une part de population qui, sur le terrain, n'y
##    habite pas.
##
## CE QUE LE FORMATEUR DOIT FAIRE DIRE A LA SALLE. Ni "la bonne reponse est
## WorldPop", ni "la bonne reponse est le comptage". La bonne reponse est :
## LA QUESTION ETAIT MAL POSEE. "Combien de personnes sont touchees" suppose
## une definition de "touche" -- l'eau dans la maison ? l'acces coupe ? le
## champ detruit ? -- et chaque definition appelle une geometrie de calcul
## differente.
##
## CE QU'IL FAUT FAIRE A LA PLACE. La troisieme methode calculee plus haut :
## LA PART DE SURFACE BATIE INONDEE. Elle intersecte les polygones de
## batiments avec les polygones d'inondation et mesure une surface -- elle ne
## rejette pas les batiments a cheval et ne suppose pas d'homogeneite
## intracellulaire. C'est l'estimateur le plus robuste des trois. Et le bon
## rendu final n'est pas un chiffre : c'est une FOURCHETTE ENTRE LES TROIS
## METHODES, accompagnee de la phrase qui dit ce que chacune compte.
## ----------------------------------------------------------------------

# tmap en mode "plot" : image statique.
worldpop_aoi01 <- terra::mask(
  terra::crop(worldpop, terra::vect(aoi01_wp)),
  terra::vect(aoi01_wp)
)

cat("Raster recadre sur la fenetre :", terra::ncell(worldpop_aoi01), "cellules\n")
cat("Population de la fenetre (somme du raster recadre) :",
    round(as.numeric(terra::global(worldpop_aoi01, "sum", na.rm = TRUE)[1, 1])),
    "\n")

carte_wp <- tm_shape(worldpop_aoi01) +
  tm_raster(
    col.scale = tm_scale_intervals(n = 6, style = "quantile",
                                   values = "brewer.yl_or_rd"),
    col.legend = tm_legend(title = "Population (hab / cellule 100 m)")
  ) +
  tm_shape(flood01) +
  tm_borders(col = "black", lwd = 1.6) +
  tm_shape(aoi01) +
  tm_borders(col = "steelblue", lwd = 2.5) +
  tm_title("AOI01 -- WorldPop 2024 et contours d'inondation")

print(carte_wp)

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- WORLDPOP ET CONTOURS D'INONDATION SUPERPOSES
##
## CE QUE LA CARTE CODE. Couleur de fond = habitants estimes par cellule de
## 100 m (WorldPop 2024). Contours noirs = polygones d'inondation EMS.
## Contour bleu = fenetre d'etude.
##
## CE QUE LES CHOIX TECHNIQUES FONT. La discretisation est en QUANTILES (6
## classes) : chaque classe contient a peu pres le meme nombre de cellules.
## Cela maximise le contraste et revele la structure fine -- mais cela
## FABRIQUE DU CONTRASTE la ou il n'y en a peut-etre pas : si la population
## est presque uniforme, les quantiles produiront quand meme six classes bien
## differenciees. Une discretisation en intervalles egaux donnerait ici une
## image presque uniforme. Les deux images sont exactes et ne racontent pas la
## meme histoire -- demonstration la plus directe qu'UNE CARTE EST UN
## ARGUMENT, PAS UN CONSTAT.
##
## CE QUI SE LIT -- ET C'EST LE POINT. Les cellules les plus peuplees forment
## un ALIGNEMENT D'HABITAT qui ne recoupe qu'en partie les polygones noirs. On
## voit a l'oeil la cause du desaccord du module 7 : l'eau et les gens ne sont
## pas exactement au meme endroit.
##
## CE QUI NE SE LIT PAS. WorldPop est un MODELE, pas un recensement : les
## effectifs par cellule sont produits en desagregeant un total administratif
## a l'aide de covariables (bati, routes, lumieres nocturnes). Corollaire
## important : WORLDPOP UTILISE LE BATI DETECTE COMME COVARIABLE, donc les
## deux methodes comparees ici NE SONT PAS TOTALEMENT INDEPENDANTES. Leur
## accord sur la fenetre entiere est un peu moins probant qu'il n'y parait.
## Il faut le dire.
## ----------------------------------------------------------------------

## --- BLOC DE REFERENCE, NON EXECUTE -- regle 6.6 de l'atelier ------------
## tmap_mode("view"), mapview et leaflet produisent des cartes interactives
## tres agreables en seance. Mais ils EMBARQUENT TOUTES LES GEOMETRIES dans le
## HTML produit : avec quelques milliers de batiments, le rapport passe de
## quelques Mo a plusieurs dizaines de Mo. Sur ce projet, un document est deja
## monte a 17 Mo pour cette raison. A utiliser en DEMONSTRATION LIVE dans
## RStudio, jamais dans un document rendu.
#
# tmap_mode("view")
# tm_shape(aoi01) +
#   tm_borders(col = "steelblue", lwd = 3) +
#   tm_shape(flood01) +
#   tm_polygons(
#     fill = "value",
#     fill.scale = tm_scale_categorical(values = "brewer.yl_or_rd"),
#     fill.legend = tm_legend(title = "Profondeur (m)"),
#     fill_alpha = 0.7
#   ) +
#   tm_shape(batiments_aoi01) +
#   tm_dots(fill = "white", size = 0.05) +
#   tm_title("EMSR772 -- AOI01 : Yagoua, profondeurs d'inondation 2024") +
#   tm_basemap(c("Esri.WorldImagery", "OpenStreetMap"))
# tmap_mode("plot")   # NE JAMAIS OUBLIER de revenir en mode statique


## ========================================================================
## MODULE 8 -- INFRASTRUCTURES : LES ROUTES COUPEES
## ========================================================================
## 8.1 OPENSTREETMAP ET L'API OVERPASS
##
## OpenStreetMap est une base geographique libre et collaborative. Chaque
## objet est un noeud, une ligne (way) ou une relation, decrit par des
## ETIQUETTES cle = valeur. La cle "highway" identifie les routes ; sa valeur
## donne le type (motorway, primary, secondary, tertiary, residential,
## track...). L'acces depuis R se fait par l'API Overpass, via osmdata.
##
## ----------------------------------------------------------------------
## TROIS CHOSES A SAVOIR AVANT D'INTERROGER OVERPASS EN SALLE
##
## C'EST UN SERVICE PUBLIC GRATUIT A USAGE LIMITE. Quelques requetes
## simultanees seulement ; il repond regulierement 429 (trop de requetes) ou
## 504 (delai depasse). Vingt participants qui lancent la meme requete au meme
## moment la font echouer pour tout le monde. PREVOIR SYSTEMATIQUEMENT UN
## REPLI LOCAL.
##
## LA COUVERTURE EST TRES HETEROGENE. Excellente dans les zones cartographiees
## lors de reponses humanitaires (le Humanitarian OpenStreetMap Team a
## beaucoup travaille sur l'Extreme-Nord camerounais), lacunaire ailleurs.
## Cette heterogeneite n'est pas aleatoire : elle correle avec l'histoire des
## crises. Comparer deux regions sur une densite de routes OSM peut donc
## comparer DEUX INTENSITES DE CARTOGRAPHIE plutot que deux reseaux reels.
##
## LA LICENCE EST L'ODbL. Toute reutilisation doit citer OpenStreetMap et ses
## contributeurs.
## ----------------------------------------------------------------------

bbox01 <- sf::st_bbox(aoi01)

cat("=== Requete OpenStreetMap (Overpass) ===\n")
cat("Emprise interrogee :\n")
print(bbox01)
cat("Tag recherche : highway\n")

# Repli local, prepare une fois par
# scripts/preparation/preparer_routes_osm_J09.R
fichier_osm_local <- "datasets/routes_aoi01_yagoua.gpkg"
cat("Copie locale de secours :", fichier_osm_local,
    "-- presente :", file.exists(fichier_osm_local), "\n")

# On borne la tentative a 30 secondes. Sans setTimeLimit(), osmdata reessaie
# en interne avec des pauses de plusieurs minutes : la seance s'arrete
# pendant que R attend en silence.
routes_osm <- tryCatch(
  {
    setTimeLimit(elapsed = 30, transient = TRUE)
    requete_osm <- opq(bbox = bbox01) %>% add_osm_feature(key = "highway")
    osm_data <- osmdata_sf(requete_osm)
    cat("Reponse Overpass recue.\n")
    osm_data$osm_lines
  },
  error = function(e) {
    cat("Requete Overpass indisponible (", conditionMessage(e), ").\n", sep = "")
    cat("Bascule sur la copie locale :", fichier_osm_local, "\n")
    if (file.exists(fichier_osm_local)) {
      sf::st_read(fichier_osm_local, quiet = TRUE)
    } else {
      cat("*** Copie locale absente : le module 8 ne peut pas s'executer. ***\n")
      NULL
    }
  },
  finally = setTimeLimit(elapsed = Inf, transient = FALSE)
)

if (!is.null(routes_osm)) {
  cat("\n--- Routes recuperees ---\n")
  cat("  segments  :", nrow(routes_osm), "\n")
  cat("  CRS       :", sf::st_crs(routes_osm)$input, "\n")
  cat("  colonnes  :", length(names(routes_osm)), "au total\n")
  cat("  repartition par type :\n")
  print(table(routes_osm$highway, useNA = "ifany"))
}

if (!is.null(routes_osm)) {

  # Harmonisation des CRS avant tout croisement, et on l'affiche.
  if (sf::st_crs(routes_osm) != sf::st_crs(aoi01)) {
    cat("Harmonisation : routes", sf::st_crs(routes_osm)$input,
        "-> aoi01", sf::st_crs(aoi01)$input, "\n")
    routes_osm <- sf::st_transform(routes_osm, sf::st_crs(aoi01))
  } else {
    cat("CRS deja identiques :", sf::st_crs(aoi01)$input, "\n")
  }

  routes_aoi01 <- sf::st_filter(routes_osm, aoi01)
  cat("Segments dans la fenetre :", nrow(routes_aoi01), "\n")

  # LONGUEUR : mesuree en UTM 33N. En degres, ce chiffre n'aurait pas de sens.
  routes_aoi01 <- sf::st_transform(routes_aoi01, crs_mesure) %>%
    mutate(longueur_km = as.numeric(sf::st_length(.)) / 1000)

  longueur_totale <- sum(routes_aoi01$longueur_km, na.rm = TRUE)
  cat("Longueur totale du reseau dans la fenetre :",
      round(longueur_totale, 2), "km\n")
  cat("Densite routiere :", round(longueur_totale / surf_aoi01, 2), "km/km2\n")
}

if (!is.null(routes_osm) && exists("routes_aoi01")) {

  flood_union_mesure <- sf::st_transform(sf::st_as_sf(flood01_union), crs_mesure)

  n_avant_inter <- nrow(routes_aoi01)

  routes_inondees <- tryCatch(
    sf::st_intersection(routes_aoi01, flood_union_mesure) %>%
      sf::st_collection_extract("LINESTRING") %>%
      mutate(longueur_km = as.numeric(sf::st_length(.)) / 1000),
    error = function(e) {
      cat("st_intersection echouee :", conditionMessage(e), "\n")
      NULL
    }
  )

  cat("--- st_intersection(routes, inondation) ---\n")
  cat("  segments entrants :", n_avant_inter, "\n")
  cat("  segments sortants :",
      if (is.null(routes_inondees)) 0 else nrow(routes_inondees), "\n")
  cat("  (le nombre peut AUGMENTER : une route traversant deux polygones\n")
  cat("   est decoupee en plusieurs troncons)\n")

  if (!is.null(routes_inondees) && nrow(routes_inondees) > 0) {

    longueur_inondee <- sum(routes_inondees$longueur_km, na.rm = TRUE)
    pct_routes <- 100 * longueur_inondee / longueur_totale

    cat("\nLongueur de route inondee :", round(longueur_inondee, 2), "km\n")
    cat("Part du reseau inondee    :", round(pct_routes, 1), "%\n")

    detail_routes <- routes_inondees %>%
      sf::st_drop_geometry() %>%
      group_by(highway) %>%
      summarise(nb_troncons = n(),
                longueur_km = round(sum(longueur_km), 3),
                .groups = "drop") %>%
      arrange(desc(longueur_km))

    cat("\nLongueur inondee par type de route :\n")
    print(detail_routes)

    readr::write_csv(detail_routes,
                     "outputs/J09_routes_inondees_osm_aoi01.csv")
  }
}

## ----------------------------------------------------------------------
## POURQUOI st_intersection ET PAS st_filter
##
## st_filter() selectionne les objets ENTIERS qui touchent une zone : une
## route de 8 km qui traverse 200 m d'inondation serait comptee pour 8 km.
## C'est ce qu'on voulait pour les batiments -- un batiment est atteint ou ne
## l'est pas -- et c'est faux pour une ligne.
##
## st_intersection() DECOUPE geometriquement chaque route sur la frontiere des
## polygones. La longueur obtenue est bien la portion submergee. C'est pour
## cela que le nombre de segments peut augmenter.
##
## st_collection_extract("LINESTRING") est indispensable derriere : quand une
## route ne touche un polygone qu'en un point, st_intersection renvoie une
## GEOMETRYCOLLECTION melant points et lignes, et st_length() sur une
## collection echoue ou renvoie des valeurs incoherentes.
## ----------------------------------------------------------------------

if (!is.null(routes_osm) && exists("routes_inondees") &&
    !is.null(routes_inondees) && nrow(routes_inondees) > 0) {

  carte_routes <- ggplot() +
    geom_sf(data = sf::st_transform(aoi01, crs_mesure),
            fill = "grey96", colour = "steelblue", linewidth = 0.9) +
    geom_sf(data = sf::st_transform(flood01, crs_mesure),
            aes(fill = value), colour = NA, alpha = 0.6) +
    geom_sf(data = routes_aoi01, colour = "grey25", linewidth = 0.4) +
    geom_sf(data = routes_inondees, colour = "#C23B22", linewidth = 1.1) +
    scale_fill_brewer(palette = "YlOrRd", na.value = "grey80") +
    labs(
      title = "Reseau routier OpenStreetMap et troncons inondes",
      subtitle = paste0("Fenetre AOI01 -- ", round(longueur_inondee, 2), " km sur ",
                        round(longueur_totale, 2), " km, soit ",
                        round(pct_routes, 1), " % du reseau"),
      fill = "Profondeur (m)",
      caption = "Routes : OpenStreetMap (ODbL). Inondation : Copernicus EMS EMSR772."
    ) +
    theme_minimal()

  print(carte_routes)

  ggsave("outputs/J09_routes_inondees.png", carte_routes,
         width = 8, height = 6, dpi = 180)
}

## ----------------------------------------------------------------------
## LECTURE DE LA CARTE -- ROUTES ET TRONCONS INONDES
##
## CE QUE LA CARTE CODE. Lignes grises = reseau routier tel qu'OSM le decrit
## dans la fenetre ; lignes rouges = portions dont la geometrie intersecte un
## polygone d'inondation. Fond colore = classes de profondeur.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Les rouges sont traces PLUS EPAIS : une
## difference d'epaisseur, et pas seulement de couleur, reste lisible en noir
## et blanc et pour un lecteur daltonien. Le decoupage vient de
## st_intersection(), donc un troncon rouge s'arrete exactement au bord du
## polygone -- la precision apparente de cette limite est celle du produit
## EMS, pas celle du terrain. Toutes les longueurs sont mesurees en UTM 33N.
##
## CE QUI SE LIT. Les coupures ne sont pas reparties au hasard : elles se
## concentrent la ou une route franchit une depression. Une seule coupure au
## bon endroit isole tout un secteur -- l'information operationnelle est
## TOPOLOGIQUE, pas metrique.
##
## CE QUI NE SE LIT PAS -- ET C'EST MAJEUR. La carte dit quelle LONGUEUR est
## sous l'eau ; elle ne dit pas quelle CONNECTIVITE est perdue. 0,5 km coupe
## sur un axe unique isole un village ; 3 km coupes sur un maillage dense ne
## coupent rien. Repondre a la question de la connectivite demande une analyse
## de graphe (composantes connexes apres retrait des troncons inondes), qui
## deborde cette journee mais qui est le bon prolongement. Deuxieme limite :
## une route absente d'OSM est absente de la carte, et n'apparaitra jamais
## comme coupee. LE NON-CARTOGRAPHIE EST INVISIBLE, PAS NUL.
## ----------------------------------------------------------------------


## ========================================================================
## MODULE 9 -- GENERALISER : UNE FONCTION, TROIS ZONES
## ========================================================================
## 9.1 LE PRINCIPE DRY
##
## Les modules 5 a 8 ont traite AOI01 etape par etape. Refaire la meme chose
## pour AOI02 et AOI03 en copiant-collant serait la garantie d'un bug : une
## correction appliquee a un endroit et pas aux deux autres. Le principe DRY
## (Don't Repeat Yourself) dit : une seule definition, plusieurs applications.
##
## La fonction ci-dessous differe de celle du script source sur un point :
## elle prend des CHEMINS EXPLICITES plutot qu'un repertoire a explorer avec
## list.files(). Les shapefiles sont livres a plat dans datasets/, donc un
## list.files() sur un motif "floodDepthA" renverrait les trois zones melees,
## et l'indice [1] en choisirait une au hasard de l'ordre alphabetique. C'est
## un piege classique des chemins a plat.
## ------------------------------------------------------------------------

analyser_inondation <- function(chemin_aoi, chemin_flood, batiments_sf,
                                zone_id, pers_par_bat = 5) {

  cat("\n=== analyser_inondation(", zone_id, ") ===\n", sep = "")

  if (!file.exists(chemin_aoi) || !file.exists(chemin_flood)) {
    cat("  *** fichier(s) absent(s), zone ignoree ***\n")
    return(tibble::tibble(
      zone = zone_id, nb_batiments_aoi = NA_integer_,
      nb_batiments_inondes = NA_integer_, pct_batiments_inondes = NA_real_,
      pop_estimee_aoi = NA_real_, pop_inondee = NA_real_,
      couverture_batiments = "fichiers absents"
    ))
  }

  aoi   <- sf::st_make_valid(sf::st_read(chemin_aoi, quiet = TRUE))
  flood <- sf::st_make_valid(sf::st_read(chemin_flood, quiet = TRUE))

  cat("  AOI   :", nrow(aoi), "polygone(s), CRS", sf::st_crs(aoi)$input, "\n")
  cat("  flood :", nrow(flood), "polygone(s)\n")

  surf_aoi <- as.numeric(sum(sf::st_area(sf::st_transform(aoi, crs_mesure)))) / 1e6
  cat("  surface AOI :", round(surf_aoi, 0), "km2 (mesuree en UTM 33N)\n")

  if (sf::st_crs(batiments_sf) != sf::st_crs(aoi)) {
    cat("  harmonisation CRS batiments ->", sf::st_crs(aoi)$input, "\n")
    batiments_sf <- sf::st_transform(batiments_sf, sf::st_crs(aoi))
  }

  bat_aoi     <- sf::st_filter(batiments_sf, aoi)
  bat_inondes <- sf::st_filter(bat_aoi, flood)

  cat("  batiments dans l'AOI :", nrow(bat_aoi), "\n")
  cat("  batiments inondes    :", nrow(bat_inondes), "\n")

  # GARDE-FOU : sans batiment dans la zone, le pourcentage serait 0/0 = NaN.
  # Une unite sans observation N'EST PAS une unite a zero. On le declare.
  couverture <- if (nrow(bat_aoi) == 0) {
    cat("  *** AUCUN batiment : la couche Open Buildings ne couvre pas cette zone ***\n")
    "non couverte par la couche batiments"
  } else if (nrow(bat_aoi) < 50) {
    cat("  *** couverture tres faible (", nrow(bat_aoi),
        " batiments) : resultat non interpretable ***\n", sep = "")
    "couverture insuffisante (< 50 batiments)"
  } else {
    "couverte"
  }

  tibble::tibble(
    zone                  = zone_id,
    nb_batiments_aoi      = nrow(bat_aoi),
    nb_batiments_inondes  = nrow(bat_inondes),
    pct_batiments_inondes = if (nrow(bat_aoi) > 0)
      round(100 * nrow(bat_inondes) / nrow(bat_aoi), 1) else NA_real_,
    pop_estimee_aoi       = if (nrow(bat_aoi) > 0)
      nrow(bat_aoi) * pers_par_bat else NA_real_,
    pop_inondee           = if (nrow(bat_aoi) > 0)
      nrow(bat_inondes) * pers_par_bat else NA_real_,
    couverture_batiments  = couverture
  )
}

## ------------------------------------------------------------------------
## 9.2 APPLICATION AUX TROIS ZONES
## ------------------------------------------------------------------------

# AUCUN unzip() ici : les shapefiles EMSR772 sont livres deja extraits et
# renommes a plat dans datasets/. Le script source decompressait les archives
# AOI02 et AOI03 DANS le dossier de donnees a chaque execution -- un dossier
# d'entrees n'est pas un dossier de travail.

bilan_aoi01_fonction <- bilan_aoi01 %>%
  mutate(couverture_batiments = "couverte (fenetre reduite 5x5 km)")

bilan_aoi02 <- analyser_inondation(
  "datasets/EMSR772_AOI02_areaOfInterestA.shp",
  "datasets/EMSR772_AOI02_floodDepthA.shp",
  batiments_pts, "AOI02 (Makari)"
)

bilan_aoi03 <- analyser_inondation(
  "datasets/EMSR772_AOI03_areaOfInterestA.shp",
  "datasets/EMSR772_AOI03_floodDepthA.shp",
  batiments_pts, "AOI03 (Waza)"
)

bilan_total <- bind_rows(bilan_aoi01_fonction, bilan_aoi02, bilan_aoi03)

cat("\n=== Bilan des trois zones EMSR772 ===\n")
print(bilan_total)

readr::write_csv(bilan_total, "outputs/J09_bilan_trois_zones.csv")

## ----------------------------------------------------------------------
## LE PIEGE DE CE MODULE : UNE FONCTION JUSTE SUR DES DONNEES QUI NE SUIVENT
## PAS
##
## analyser_inondation() est correcte. Et pourtant, deux des trois lignes du
## tableau ne veulent rien dire.
##
## LA RAISON. La couche open_buildings_yagoua.gpkg a ete preparee en ne
## retenant que les batiments situes dans AOI01 PLUS UNE MARGE DE 5 KM. Or les
## trois zones EMSR772 sont tres eloignees : Yagoua, Makari, Waza, jusqu'a
## ~300 km de distance. La couche NE COUVRE PAS AOI02 ni AOI03.
##
## CE QUI SE SERAIT PASSE SANS GARDE-FOU. nrow(bat_aoi) vaut 0, donc
## 100 * 0 / 0 renvoie NaN, et 0 * 5 renvoie une population de 0. Le tableau
## aurait affiche "0 batiment touche, 0 personne" pour deux zones REELLEMENT
## INONDEES en 2024. Aucune erreur n'aurait ete levee. Un lecteur presse
## aurait conclu que ces zones sont epargnees.
##
## C'est le mecanisme de L'ABSENCE SILENCIEUSE, sous sa forme la plus
## dangereuse : UN ZERO QUI RESSEMBLE A UNE MESURE. La colonne
## couverture_batiments existe pour que ce zero ne puisse pas etre lu comme
## une information.
##
## REGLE GENERALE. Une unite sans observation reste SANS DONNEE : grise sur
## une carte, NA dans un tableau, jamais zero. Le seuil en dessous duquel on
## refuse d'interpreter -- ici 50 batiments -- est DECLARE DANS LE CODE.
##
## POUR VRAIMENT TRAITER AOI02 ET AOI03 : retourner aux tuiles Open Buildings
## d'origine et refaire l'etape de preparation sur les trois emprises. Ces
## tuiles ne sont pas livrees avec la journee -- limite assumee du materiel.
## ----------------------------------------------------------------------

# On ne trace QUE les zones effectivement couvertes. Tracer une barre a zero
# pour une zone non couverte reviendrait a affirmer qu'elle n'a pas ete
# touchee -- exactement ce qu'on veut eviter.
bilan_tracable <- bilan_total %>%
  filter(couverture_batiments %in%
           c("couverte", "couverte (fenetre reduite 5x5 km)"))

cat("Zones tracables :", nrow(bilan_tracable), "sur", nrow(bilan_total), "\n")
cat("Zones ecartees  :",
    paste(bilan_total$zone[!bilan_total$zone %in% bilan_tracable$zone],
          collapse = ", "), "\n")

if (nrow(bilan_tracable) > 0) {
  g_bilan <- bilan_tracable %>%
    select(zone, nb_batiments_aoi, nb_batiments_inondes) %>%
    tidyr::pivot_longer(-zone, names_to = "categorie", values_to = "nb") %>%
    mutate(categorie = recode(categorie,
                              nb_batiments_aoi = "Total dans la zone",
                              nb_batiments_inondes = "Touches par l'inondation")) %>%
    ggplot(aes(x = zone, y = nb, fill = categorie)) +
    geom_col(position = "dodge") +
    scale_fill_manual(values = c("Total dans la zone" = "#AEC6CF",
                                 "Touches par l'inondation" = "#C23B22")) +
    labs(
      title = "Batiments exposes aux inondations -- EMSR772, Yagoua 2024",
      subtitle = "Seules les zones couvertes par la couche Open Buildings sont tracees",
      x = NULL, y = "Nombre de batiments", fill = NULL
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")

  print(g_bilan)
  ggsave("outputs/J09_bilan_zones.png", g_bilan, width = 8, height = 4.5, dpi = 180)
}

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- BILAN PAR ZONE
##
## CE QUE LA FIGURE CODE. Deux barres par zone : nombre total de batiments
## detectes (confiance >= 0,7) et nombre dont le centroide tombe dans un
## polygone d'inondation.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Les zones non couvertes sont ABSENTES du
## graphique, et le cat() juste au-dessus les nomme. Les afficher a zero
## aurait produit une affirmation fausse. Les barres sont cote a cote
## ("dodge") et non empilees : empiler "touches" sur "total" compterait deux
## fois les memes batiments -- erreur frequente quand une categorie est un
## sous-ensemble de l'autre.
##
## CE QUI SE LIT. L'ordre de grandeur de l'exposition sur la fenetre etudiee.
##
## CE QUI NE SE LIT PAS. Toute comparaison entre zones, puisqu'une seule est
## documentee. Et le total lui-meme n'est pas un bilan de l'inondation de
## Yagoua : il porte sur une fenetre de quelques km2 dans une AOI officielle
## de plusieurs milliers de km2.
## ----------------------------------------------------------------------


## ========================================================================
## FIN DE JOURNEE
## ========================================================================
## Le glossaire par domaine, le recapitulatif des fonctions cles, les huit
## exercices (chacun portant un piege nomme) et les prolongements vers le J10
## et le J11 sont dans demo_formateur_J09.qmd, sections "Fin de journee".
## Ils y sont en TABLEAUX, ce qu'un commentaire R rend illisible.
##
## RAPPEL DES CHIFFRES A NE PAS CITER HORS CONTEXTE :
##  - batiments et population de la fenetre AOI01 -> fenetre ad hoc ~5x5 km,
##    quand l'AOI01 officielle fait plusieurs milliers de km2 ;
##  - population estimee (x 5) -> hypothese d'occupation non calibree ;
##  - part de batiments touches -> depend du seuil 0,7 ET du predicat ;
##  - longueur de route inondee -> depend de la completude d'OSM ;
##  - gain de bati 2015-2025 -> depend de la symetrie de couverture des tuiles ;
##  - croissance relative -> seuil de 1 km2 de bati initial declare ;
##  - AOI02 et AOI03 -> non couvertes : leurs zeros ne sont pas des mesures.
## ========================================================================

cat("=== Fin de la journee J09 ===\n")
cat("Fichiers produits dans outputs/ :\n")
sorties <- list.files("outputs", pattern = "^J09_")
if (length(sorties)) cat(paste0("  ", sorties), sep = "\n") else
  cat("  (aucun -- verifier que les donnees sont bien dans datasets/)\n")
cat("\nRappel : tous les chiffres du cas Yagoua portent sur une fenetre de ~5 x 5 km,\n")
cat("sous l'hypothese de", pers_par_batiment, "personnes par batiment et un seuil de\n")
cat("confiance de", seuil_confiance, ". Ils ne constituent pas un bilan de l'inondation.\n")
