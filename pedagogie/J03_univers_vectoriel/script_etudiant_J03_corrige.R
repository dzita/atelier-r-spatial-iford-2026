## ============================================================================
## SCRIPT ETUDIANT -- CORRIGE -- J03 : L'UNIVERS VECTORIEL
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Mercredi 29 juillet 2026
## Version complete de la trame etudiante, distribuee en fin de journee.
## ============================================================================

## --- Se placer dans le dossier de la journee --------------------------------
## Tous les chemins de ce script sont relatifs a CE dossier. Quarto s'y place
## automatiquement au rendu ; Rscript, non. On le fait donc explicitement, que
## le script soit lance depuis le dossier du jour, depuis pedagogie/ ou depuis
## la racine du projet.
.dossier_jour <- "J03_univers_vectoriel"
if (!dir.exists("datasets")) {
  for (.p in c(.dossier_jour,
               file.path("pedagogie", .dossier_jour))) {
    if (dir.exists(file.path(.p, "datasets"))) { setwd(.p); break }
  }
}
if (!dir.exists("datasets"))
  stop("Dossier datasets/ introuvable. Ouvrez atelier-r-spatial-iford-2026.Rproj, ",
       "lancez source('outils/distribuer_donnees.R'), puis relancez ce script.")
cat("Dossier de travail :", getwd(), "\n")

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
suppressPackageStartupMessages(library(sf))
sf::sf_use_s2(FALSE)

## ----------------------------------------------------------------------
## Un réglage technique, posé une fois pour toutes
##
## Ce document commence par sf::sf_use_s2(FALSE).
##
## Par défaut, sf traite les coordonnées en degrés sur une sphère, via la
## bibliothèque s2. C'est mathématiquement plus juste, mais beaucoup plus
## exigeant sur la propreté des géométries : la moindre auto-intersection
## fait échouer le calcul, avec un message du type *« Loop 0 is not valid:
## Edge 5359 crosses edge 5361 »*.
##
## Les données réelles — et DS.geojson en particulier — ne sont presque
## jamais assez propres pour cela. On repasse donc au moteur planaire (GEOS),
## plus tolérant.
##
## Ce que cela n'autorise pas : mesurer sur des degrés. Toute superficie ou
## distance de ce document est calculée après reprojection en UTM, comme le
## veut la règle d'or des CRS.
##
## ----------------------------------------------------------------------

################################################################################
# ATELIER IFORD x GDSG 2026 - DONNEES SPATIALES, ANALYSE ET MANIPULATION DANS R
# J03 : L'univers vectoriel - points, lignes et territoires
################################################################################


## ========================================================================
## LES PAQUETS DE LA JOURNÉE
## ========================================================================
## Neuf paquets, tous installés par install_packages_day.R. Trois seulement
## sont au cœur du J03 — sf, dplyr, ggplot2 — les autres complètent.
##
## | Paquet | Rôle | À quoi il sert ici |
## | sf | Simple Features | lire, écrire et manipuler les données vectorielles ; remplace l'ancien sp |
## | dplyr | grammaire des tableaux | filter, select, mutate, left_join — fonctionne tel quel sur un objet sf |
## | ggplot2 | visualisation | cartes par couches avec geom_sf() |
## | tmap | cartographie thématique | cartes publiables, classification, légendes |
## | mapview | exploration interactive | vérifier une couche en un appel, dans RStudio |
## | haven | import SPSS / Stata | lire les fichiers EDS .sav |
## | readr | import CSV | read_csv(), read_delim() |
## | janitor | nettoyage | clean_names() uniformise les noms de colonnes |
## | RColorBrewer | palettes | jeux de couleurs conçus pour la cartographie |
##

## ========================================================================
## 1.1 QU'EST-CE QUE LE PACKAGE SF ?
## ========================================================================
#Le package sf (Simple Features) est la bibliothèque de référence pour la manipulation de données géographiques vectorielles dans R. Il a été adopté comme standard par la communauté R en remplacement du package sp.
#📌 Simple Features : définition
#Les 'Simple Features' (ISO 19125) sont un standard international définissant comment représenter des géométries vectorielles (points, lignes, polygones) et leurs attributs associés dans un format tabulaire.
#Dans sf, un objet géographique est simplement un data.frame R ordinaire avec une colonne spéciale 'geometry' contenant la forme géographique.

#Philosophie centrale : en sf, un objet spatial est un data.frame augmenté d'une colonne de géométrie. Toutes les fonctions dplyr (filter, select, mutate, group_by, etc.) fonctionnent directement sur les objets sf.


## ========================================================================
## 1.2 LES TYPES DE GÉOMÉTRIES
## ========================================================================
#Le standard Simple Features définit plusieurs types de géométries. Voici ceux que vous rencontrerez dans les données camerounaises :

library(sf)

# --- POINT : localisation d'une formation sanitaire, d'un ménage enquêté ---
# Exemple : créer un point à Yaoundé (longitude, latitude)
pt_yaounde <- st_point(c(11.5021, 3.8480))
cat('Type :', class(pt_yaounde), '\n')

# --- MULTIPOINT : plusieurs localisations GPS d'enquête ---
coords_gps <- matrix(c(11.50, 3.84,
                        9.70, 4.06,
                       14.32, 5.37), ncol = 2, byrow = TRUE)
multipt <- st_multipoint(coords_gps)

# --- LINESTRING : réseau routier, fleuve ---
route <- st_linestring(matrix(c(9.20, 4.05, 10.00, 3.85, 11.50, 3.84),
                              ncol = 2, byrow = TRUE))

# --- POLYGON : district sanitaire, région administrative ---
# Un polygone = matrice de coordonnées fermée (1er = dernier point)
district_exemple <- st_polygon(list(
  matrix(c(11.0, 3.5,  12.0, 3.5,  12.0, 4.5,  11.0, 4.5,  11.0, 3.5),
         ncol = 2, byrow = TRUE)
))

# --- MULTIPOLYGON : région composée de plusieurs polygones ---
# C'est le type le plus fréquent dans les shapefiles administratifs

# Vérifier le type d'un objet
cat('Géométrie district :', st_geometry_type(district_exemple), '\n')


## ========================================================================
## 1.3 STRUCTURE D'UN OBJET SF
## ========================================================================
#Comprendre la structure d'un objet sf est fondamental. Chargeons les districts sanitaires du Cameroun pour l'explorer.

# Exploration de la structure d'un objet sf
# Données : DS.geojson (districts sanitaires du Cameroun)

# Chargement
# --- Une fonction de lecture, appelee partout dans ce document --------------
# DS.geojson demande deux preparations systematiques. Plutot que de les
# repeter -- et d'en oublier une --, on les enferme dans une fonction.
lire_ds <- function(chemin = 'datasets/DS.geojson') {
  st_read(chemin, quiet = TRUE) |>
    # a) Reparer les geometries : sommets dupliques et auto-intersections.
    #    Invisible a l'affichage, bloquant des le premier calcul geometrique.
    #    st_make_valid() sous GEOS (s2 desactive) les corrige toutes ;
    #    sous s2, il en resterait 3 sur 200.
    sf::st_make_valid() |>
    # b) Nommer les attributs utilement. Export DHIS2 : le nom du district est
    #    dans 'name' prefixe par "District ", et la region dans 'parentName'
    #    prefixee par "Region ". Aucune colonne ne s'appelle 'region'.
    dplyr::mutate(
      district = sub('^District\\s+', '', name),
      region   = sub('^Region\\s+',   '', parentName)
    )
}

ds <- lire_ds()

# --- STRUCTURE GÉNÉRALE ---
# sf affiche automatiquement les métadonnées géographiques
print(ds)          # Affichage complet avec métadonnées
class(ds)          # [1] 'sf' 'data.frame' → sf EST un data.frame !

# --- MÉTADONNÉES GÉOGRAPHIQUES ---
st_crs(ds)         # Système de coordonnées de référence (SCR/CRS)
st_bbox(ds)        # Emprise spatiale (xmin, ymin, xmax, ymax)
st_geometry_type(ds) # Type de géométrie de chaque entité
nrow(ds)           # Nombre d'entités géographiques
ncol(ds)           # Nombre de colonnes (attributs + geometry)

# --- ACCÈS À LA COLONNE GEOMETRY ---
st_geometry(ds)    # Extraire la géométrie seule
names(ds)          # Noms de toutes les colonnes

# --- ATTRIBUTS TABULAIRES (comme un data.frame ordinaire) ---
head(ds, 3)        # Premières lignes
str(ds)            # Structure détaillée des colonnes
summary(ds)        # Résumé statistique de chaque colonne

# Point clé à retenir
#Un objet sf est à la fois un data.frame ET un objet spatial. Vous pouvez utiliser toutes les fonctions R classiques (nrow, ncol, names, head, summary, $, [, etc.) et AUSSI les fonctions spatiales sf (st_crs, st_bbox, st_geometry_type...).

## Ce que cet affichage vous apprend, et pourquoi il compte.
##
## class(ds) renvoie "sf" "data.frame". C'est l'idée fondatrice de la journée
## : un objet spatial est un tableau ordinaire, avec une colonne en plus.
## Tous les verbes dplyr de la veille — filter, select, mutate, group_by —
## fonctionnent dessus sans adaptation.
##
## Cette colonne s'appelle geometry. Elle ne contient pas un nombre mais une
## forme : ici un MULTIPOLYGON, c'est-à-dire un district éventuellement fait
## de plusieurs morceaux disjoints — une enclave, une île.
##
## L'en-tête que sf affiche mérite qu'on s'y arrête :
##
## | Ligne | Ce qu'elle dit |
## | 200 features and 13 fields | 200 objets, 13 attributs — la géométrie n'est pas comptée comme un champ |
## | Geometry type: MULTIPOLYGON | des surfaces, potentiellement en plusieurs parties |
## | Bounding box | l'emprise : le Cameroun s'étend de 8,5° à 16,2° de longitude |
## | Geodetic CRS: WGS 84 | des degrés, pas des mètres — donc rien de mesurable en l'état |
##
#La fonction universelle de lecture dans sf est st_read(). Elle supporte nativement plus de 200 formats géospatiaux : shapefile, GeoJSON, GeoPackage, KML, PostGIS, etc.


## ========================================================================
## 2.1 LECTURE D'UN FICHIER GEOJSON : DS.GEOJSON
## ========================================================================
# LECTURE D'UN GEOJSON
# Fichier : DS.geojson — Districts sanitaires du Cameroun

library(sf)
library(dplyr)

# Lecture brute, pour voir ce que st_read() annonce :
ds_brut <- st_read('datasets/DS.geojson')

# st_read() affiche automatiquement :
# - le nom de la couche
# - le type de geometrie (MULTIPOLYGON, POINT...)
# - le nombre d'entites (features) et d'attributs (fields)
# - l'emprise spatiale (bounding box)
# - le systeme de coordonnees (CRS)
# L'argument quiet = TRUE supprime ces messages.

# En pratique, on passe par lire_ds() : lecture + preparation en un geste.
ds <- lire_ds()

cat('\nDistricts sanitaires :', nrow(ds), '| regions distinctes :',
    dplyr::n_distinct(ds$region), '\n')
head(sort(unique(ds$region)))

# Vérifications de base
glimpse(ds)      # Vue rapide de la structure (dplyr)
nrow(ds)         # Combien de districts sanitaires ?
names(ds)        # Quelles colonnes / attributs ?

## Un fichier réel n'a jamais les colonnes qu'on espère. Celui-ci vient d'un
## export DHIS2, le système d'information sanitaire. D'où des noms techniques
## — parentGraph, grandParentId, hasCoordinatesDown — et **aucune colonne
## nommée region**.
##
## L'information existe pourtant : parentName contient « Region Littoral », «
## Region Centre »… et name contient « District Abo ». Il suffisait de
## retirer les préfixes, ce que fait lire_ds().
##
## La leçon vaut au-delà de ce fichier : inspecter avant de supposer. Un
## names() et un head() coûtent dix secondes ; un script écrit sur des noms
## de colonnes imaginés coûte une demi-journée.
##

## ========================================================================
## 2.2 LECTURE D'UN SHAPEFILE : PAYS LIMITROPHES ET GADM
## ========================================================================
# Règle importante : on passe le chemin du fichier .shp
# Les fichiers .dbf, .prj, .shx doivent être dans le MÊME dossier

# --- Pays limitrophes du Cameroun ---
# Meme principe que lire_ds() : une lecture, une preparation, une fonction.
# Ce shapefile contient des entites sans nom de pays (attributs vides). Elles
# n'ont rien a etiqueter : geom_label() s'en plaindrait a chaque carte
# ("Removed 5 rows containing missing values"). On les ecarte a la lecture.
lire_pays <- function(chemin = 'datasets/Pays_limitrophes_Cmr.shp') {
  st_read(chemin, quiet = TRUE) |>
    dplyr::filter(!is.na(COUNTRY), COUNTRY != '')
}

pays_brut <- st_read('datasets/Pays_limitrophes_Cmr.shp', quiet = TRUE)
cat('Entites lues :', nrow(pays_brut),
    '| sans nom de pays :', sum(is.na(pays_brut$COUNTRY) | pays_brut$COUNTRY == ''), '\n')

pays_lim <- lire_pays()
cat('Entites conservees :', nrow(pays_lim), '\n')
st_crs(pays_lim)        # Vérifier le système de coordonnées
plot(st_geometry(pays_lim), main = 'Pays limitrophes du Cameroun')

# --- Données administratives GADM niveau 2 (Arrondissements) ---
# gadm41_CMR_shp contient plusieurs fichiers .shp :
# gadm41_CMR_0.shp  → frontière nationale
# gadm41_CMR_1.shp  → régions
# gadm41_CMR_2.shp  → départements / arrondissements

cmr_national  <- st_read('datasets/gadm41_CMR_0.shp', quiet = TRUE)
cmr_regions   <- st_read('datasets/gadm41_CMR_1.shp', quiet = TRUE)
cmr_depart    <- st_read('datasets/gadm41_CMR_2.shp', quiet = TRUE)

cat('Régions :', nrow(cmr_regions), '\n')   # 10 régions au Cameroun
cat('Niveaux 2 :', nrow(cmr_depart), '\n')  # Départements / arrondissements

# Aperçu des colonnes GADM
names(cmr_regions)
# GID_0, NAME_0, GID_1, NAME_1, VARNAME_1, TYPE_1, ENGTYPE_1...


## ========================================================================
## 2.3 LECTURE DES FICHIERS DHS : CMGE71FL.SHP (GPS CLUSTERS)
## ========================================================================
# LECTURE DU FICHIER GPS DHS
# CMGE71FL.shp — Coordonnées GPS des grappes d'enquête DHS
# (Cameroun DHS 2018)

dhs_gps <- st_read('datasets/CMGE71FL.shp', quiet = TRUE)

# Exploration
head(dhs_gps, 5)
names(dhs_gps)
# Colonnes clés DHS GPS :
# DHSID      : identifiant unique de la grappe
# DHSCC      : code pays (CM = Cameroun)
# DHSYEAR    : année de l'enquête (2018)
# DHSCLUST   : numéro de grappe (permet le lien avec CMHR71FL.SAV)
# URBAN_RURA : U = urbain, R = rural
# LATNUM     : latitude
# LONGNUM    : longitude
# ALT_GPS    : altitude

# Vérifier la projection
st_crs(dhs_gps)
# CRS habituel DHS : WGS84 (EPSG:4326)

# Nombre de grappes
nrow(dhs_gps)  # ~ 567 grappes pour DHS Cameroun 2018

# Répartition urbain / rural
table(dhs_gps$URBAN_RURA)


## ========================================================================
## 2.4 LECTURE DES DONNÉES SPSS DHS : CMHR71FL.SAV ET CMIR71FL.SAV
## ========================================================================
# LECTURE DES FICHIERS SPSS (.sav) — Données DHS
# CMHR71FL.SAV : questionnaire Ménage (Household Recode)
# CMIR71FL.SAV : questionnaire Femmes (Individual/Women Recode)

library(haven)

# Lecture du fichier ménages DHS
dhs_menage <- read_sav('datasets/CMHR71FL.SAV')

# Lecture du fichier femmes DHS
dhs_femmes <- read_sav('datasets/CMIR71FL.SAV')

# Dimensions
dim(dhs_menage)  # lignes × colonnes
dim(dhs_femmes)

# Les fichiers DHS ont des centaines de variables — ciblons les clés
dhs_menage_reduit <- dhs_menage %>%
  select(
    HV001,   # Numéro de grappe (lien avec GPS)
    HV002,   # Numéro de ménage
    HV007,   # Année de l'interview
    HV025,   # Milieu (1=urbain, 2=rural)
    HV270,   # Quintile de richesse
    HV271,   # Score de richesse
    HV206,   # Accès à l'électricité
    HV205,   # Type de toilettes
    HV201,   # Source d'eau de boisson
    HV009    # Nombre de membres du ménage
  )

# Convertir les labels SPSS en facteurs R lisibles
dhs_menage_reduit <- dhs_menage_reduit %>%
  mutate(across(where(is.labelled), as_factor))

# Résumé
summary(dhs_menage_reduit[, c('HV025', 'HV270')])


## ========================================================================
## 2.5 LECTURE DES DONNÉES CSV : POPULATION ET MÉNAGES
## ========================================================================
# LECTURE DES FICHIERS CSV
# CMR_population_v1_0_admin_level2.csv  — Population WorldPop (58 departements)
# CMR_household_v1_0_admin_level2.csv   — Menages WorldPop
# CMGC72FL.csv                          — Covariables contextuelles DHS

library(readr)
library(janitor)

# --- PIEGE : les deux fichiers WorldPop n'ont PAS le meme separateur ---------
# La population est en POINTS-VIRGULES, les menages en VIRGULES. read_csv()
# sur le premier renverrait une colonne unique -- sans lever d'erreur.
# Reflexe : ouvrir un CSV inconnu dans un editeur de texte avant de l'importer.

pop_adm2 <- read_delim('datasets/CMR_population_v1_0_admin_level2.csv',
                       delim = ';', show_col_types = FALSE) %>%
  clean_names()

menage_adm2 <- read_csv('datasets/CMR_household_v1_0_admin_level2.csv',
                        show_col_types = FALSE) %>%
  clean_names()

# --- Les colonnes REELLES de ces fichiers ------------------------------------
names(pop_adm2)
# id          identifiant du departement
# names1      nom du departement (sans accents !)
# total       estimation centrale
# lower/upper intervalle de credibilite -- ces chiffres sont MODELISES
# uncertainty largeur relative de cet intervalle
head(pop_adm2, 5)

# --- Covariables contextuelles des grappes DHS ------------------------------
# ATTENTION : ce fichier ne contient AUCUNE coordonnee. C'est CMGE71FL.shp,
# deja charge en section 2.3, qui porte la geometrie. Les deux se relient
# par le numero de grappe, DHSCLUST.
covar_dhs <- read_csv('datasets/CMGC72FL.csv', show_col_types = FALSE) %>%
  clean_names()

cat('Covariables :', nrow(covar_dhs), 'grappes x', ncol(covar_dhs), 'variables\n')
cat('Colonnes de coordonnees dans ce CSV ? ',
    any(grepl('^lat|^lon', names(covar_dhs))), '\n\n')

# --- Recoller geometrie (shapefile) et attributs (CSV) ----------------------
dhs_gps_sf <- dhs_gps %>%                     # le shapefile de la section 2.3
  rename_with(tolower) %>%
  left_join(covar_dhs, by = 'dhsclust')

cat('Grappes geolocalisees et enrichies :', nrow(dhs_gps_sf), '\n')


## ========================================================================
## 2.6 ÉCRITURE ET EXPORT DE FICHIERS SPATIAUX
## ========================================================================
# --- Export en GeoJSON ---
st_write(ds, 'outputs/districts_sanitaires_export.geojson',
         delete_dsn = TRUE)  # delete_dsn = remplacer si existe

# --- Export en Shapefile ---
st_write(cmr_regions, 'outputs/regions_cameroun.shp',
         delete_dsn = TRUE)

# --- Export en GeoPackage (recommandé : 1 seul fichier) ---
# Le GeoPackage est le format moderne recommandé.
# Il stocke plusieurs couches dans un seul fichier .gpkg
st_write(ds,          'outputs/cameroun.gpkg', layer = 'districts_sanitaires', delete_dsn = TRUE)
st_write(cmr_regions, 'outputs/cameroun.gpkg', layer = 'regions', append = TRUE)
st_write(dhs_gps,     'outputs/cameroun.gpkg', layer = 'grappes_dhs', append = TRUE)

# Lister les couches d'un GeoPackage
st_layers('outputs/cameroun.gpkg')

# Relire une couche spécifique du GeoPackage
regions_verif <- st_read('outputs/cameroun.gpkg', layer = 'regions', quiet = TRUE)

#SEQUNCE 3 — INSPECTION D'OBJETS SPATIAUX

#NB: Avant toute analyse, il est indispensable de comprendre la structure de vos données spatiales : système de coordonnées, emprise géographique, cohérence des géométries, distribution des attributs.


## ========================================================================
## 3.1 LE SYSTÈME DE COORDONNÉES DE RÉFÉRENCE (CRS/SCR)
## ========================================================================
#Le CRS définit comment les coordonnées numériques sont liées à la surface terrestre. C'est la source principale d'erreurs dans les analyses SIG : deux couches dans des CRS différents ne peuvent pas être combinées directement.

#📌 WGS84 vs UTM : les deux CRS principaux au Cameroun
#• WGS84 (EPSG:4326) : coordonnées en degrés décimaux (longitude, latitude). Standard mondial GPS, DHS, GADM, WorldPop.
#• UTM Zone 33N (EPSG:32633) : coordonnées en mètres, adapté au Cameroun occidental et central.
#• UTM Zone 34N (EPSG:32634) : adapté au Cameroun oriental.
#Règle : utilisez WGS84 pour la visualisation, et UTM pour les calculs de distances et de superficies.

library(sf)

# Charger toutes nos couches
ds        <- lire_ds()
pays_lim  <- lire_pays()
cmr_nat   <- st_read('datasets/gadm41_CMR_0.shp', quiet = TRUE)
dhs_gps   <- st_read('datasets/CMGE71FL.shp', quiet = TRUE)

# --- Vérifier le CRS de chaque couche ---
st_crs(ds)$epsg        # Code EPSG numérique
st_crs(ds)$wkt         # Définition WKT complète
st_crs(ds)$input       # Nom court

# Vérification rapide de tous les CRS
cat('DS districts      :', st_crs(ds)$epsg, '\n')
cat('Pays limitrophes  :', st_crs(pays_lim)$epsg, '\n')
cat('Cameroun national :', st_crs(cmr_nat)$epsg, '\n')
cat('DHS GPS           :', st_crs(dhs_gps)$epsg, '\n')

# --- Reprojection (transformer le CRS) ---
# Tous doivent être dans le même CRS avant toute opération spatiale !

# Reprojeter en WGS84 (4326) si nécessaire
ds_wgs84 <- st_transform(ds, crs = 4326)

# Reprojeter en UTM Zone 33N (en mètres) pour les calculs
ds_utm   <- st_transform(ds, crs = 32633)

# Vérification après reprojection
st_crs(ds_utm)$epsg  # Doit afficher 32633

# Calculer la surface des districts (en km²) — nécessite un CRS métrique
ds_utm$superficie_km2 <- as.numeric(st_area(ds_utm)) / 1e6
summary(ds_utm$superficie_km2)


## ========================================================================
## 3.2 EMPRISE SPATIALE ET VISUALISATION RAPIDE
## ========================================================================
# Emprise de chaque couche
st_bbox(ds)
# xmin      ymin      xmax      ymax
# Longitude ouest, Latitude sud, Longitude est, Latitude nord

# Visualisation rapide avec plot() de base
par(mfrow = c(1, 2))  # 2 cartes côte à côte

# Carte 1 : Districts sanitaires (géométrie uniquement)
plot(st_geometry(ds),
     main  = 'Districts Sanitaires du Cameroun',
     col   = 'lightblue',
     border = 'gray40',
     lwd   = 0.5)

# Carte 2 : Superposition districts + grappes DHS
plot(st_geometry(ds),
     main   = 'Districts sanitaires + Grappes DHS',
     col    = 'lightyellow',
     border = 'gray60')
plot(st_geometry(dhs_gps),
     add = TRUE,       # Superposer sur la carte existante
     pch = 20,         # Type de point (cercle plein)
     col = 'red',
     cex = 0.5)        # Taille des points
legend('bottomright',
       legend = c('Districts sanitaires', 'Grappes DHS 2018'),
       fill   = c('lightyellow', NA),
       pch    = c(NA, 20),
       col    = c('gray60', 'red'))

par(mfrow = c(1, 1))  # Revenir à 1 seule carte


## ========================================================================
## 3.3 VALIDATION ET CORRECTION DES GÉOMÉTRIES
## ========================================================================
# On travaille ici sur ds_brut -- la version NON preparee, lue en section 2.1.
# lire_ds() applique deja st_make_valid(), donc 'ds' est valide : la lecon
# serait vide sur lui.
validite <- st_is_valid(ds_brut)
table(validite)  # Combien sont valides / invalides ?

# Identifier les géométries invalides
invalides <- which(!validite)
if (length(invalides) > 0) {
  cat('Geometries invalides :', length(invalides), 'sur', nrow(ds_brut), '\n')
  print(st_is_valid(ds_brut[invalides, ], reason = TRUE))
} else {
  cat('Toutes les geometries sont valides.\n')
}

# Correction automatique
ds_valid <- st_make_valid(ds_brut)
cat('Apres correction :', sum(st_is_valid(ds_valid)), '/', nrow(ds_valid),
    'geometries valides\n')

# LE MOTEUR GEOMETRIQUE CHANGE LE RESULTAT.
# Avec s2 actif (moteur spherique, defaut de sf), st_make_valid() laissait
# 3 geometries invalides sur 200 : s2 refuse des auto-intersections que
# GEOS accepte. C'est pourquoi ce document desactive s2 des le depart.
cat('Moteur spherique s2 actif ?', sf::sf_use_s2(), '\n')

# POURQUOI CELA COMPTE.
# Une geometrie invalide ne se voit pas a l'affichage : la carte s'affiche
# normalement. Elle ne se manifeste qu'au premier calcul geometrique, par un
# message enigmatique :
#   "Loop 0 is not valid: Edge 3010 has duplicate vertex with edge 3012"
# C'est pour cette raison que lire_ds() applique st_make_valid() d'office :
# le filtrage spatial (4.2), la zone tampon (4.3) et les jointures (5.x)
# echouent tous sans cette correction.
all(st_is_valid(ds_valid))  # Doit afficher TRUE

# --- Détecter les géométries vides ---
vides <- st_is_empty(ds)
cat('Géométries vides :', sum(vides), '\n')

# --- Statistiques sur les géométries ---
# Superficie des districts (après projection en mètres)
ds_utm <- st_transform(ds, 32633)
ds_utm$aire_km2 <- as.numeric(st_area(ds_utm)) / 1e6

cat('Surface totale (km²) :', sum(ds_utm$aire_km2), '\n')
cat('Plus grand district :', max(ds_utm$aire_km2), 'km²\n')
cat('Plus petit district :', min(ds_utm$aire_km2), 'km²\n')

# Périmètre des frontières
ds_utm$perimetre_km <- as.numeric(st_perimeter(ds_utm)) / 1000

## Une géométrie invalide ne se voit pas. La carte s'affiche normalement, le
## tableau d'attributs est complet, nrow() donne le bon compte. Le problème
## n'apparaît qu'au premier calcul géométrique — filtrage spatial, zone
## tampon, jointure — sous la forme d'un message opaque :
##
##   Loop 0 is not valid: Edge 5359 crosses edge 5361
##
## Ici, 135 districts sur 200 sont invalides : bords qui se croisent, sommets
## dupliqués. C'est banal pour des données produites par numérisation ou par
## export successif. st_make_valid() les répare toutes.
##
## Le compte affiché juste au-dessus fait la démonstration : la validation
## n'est pas une précaution théorique, c'est ce qui sépare un script qui
## tourne d'un script qui s'arrête.
##

## ========================================================================
## 3.4 EXPLORATION DES ATTRIBUTS AVEC DPLYR
## ========================================================================
library(dplyr)

# Rappel : un sf est un data.frame, dplyr fonctionne directement

# --- Statistiques par région (si colonne région dans DS) ---
# Adaptez 'nom_region' selon les colonnes réelles de votre DS.geojson
ds %>%
  as.data.frame() %>%   # Supprimer la géométrie pour le résumé
  group_by(region) %>%   # colonne creee en section 2.1 depuis parentName
  summarise(
    n_districts = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_districts))

# --- Joindre la population aux districts ---
pop_adm2 <- readr::read_delim('datasets/CMR_population_v1_0_admin_level2.csv',
                              delim = ';',
                             show_col_types = FALSE) %>%
  janitor::clean_names()

# Aperçu des colonnes pour identifier la clé de jointure
names(pop_adm2)
names(ds)

# Densité de population
# (après jointure attributaire — voir MODULE 5)

#Le filtrage et le sous-réglage sont des opérations fondamentales : sélectionner un sous-ensemble d'entités géographiques selon leurs attributs ou leur relation spatiale avec d'autres couches.


## ========================================================================
## 4.1 FILTRAGE PAR ATTRIBUTS
## ========================================================================
library(sf)
library(dplyr)

# Charger les données
ds        <- lire_ds()
cmr_reg   <- st_read('datasets/gadm41_CMR_1.shp', quiet = TRUE)
dhs_gps   <- st_read('datasets/CMGE71FL.shp', quiet = TRUE)

# --- MÉTHODE 1 : Opérateur [ comme data.frame ---
# Sélectionner les districts d'une région spécifique
# (Adaptez 'nom_colonne' selon les colonnes réelles de DS.geojson)
ds_centre <- ds[ds$region == 'Centre', ]

# --- MÉTHODE 2 : filter() de dplyr (recommandée) ---
# Plus lisible, intégration naturelle avec le pipe %>%
ds_centre <- ds %>% filter(region == 'Centre')

# Plusieurs conditions
ds_grandes <- ds %>%
  filter(region %in% c('Centre', 'Littoral', 'Ouest'))

# --- Filtrage des grappes DHS urbaines ---
dhs_urbain <- dhs_gps %>% filter(URBAN_RURA == 'U')
dhs_rural  <- dhs_gps %>% filter(URBAN_RURA == 'R')

cat('Grappes urbaines :', nrow(dhs_urbain), '\n')
cat('Grappes rurales  :', nrow(dhs_rural),  '\n')

# --- Filtrage des régions GADM par nom ---
# La colonne NAME_1 contient les noms de régions dans GADM
reg_nord <- cmr_reg %>% filter(NAME_1 %in% c('Nord', 'Adamaoua', 'Extrême-Nord'))
reg_sud  <- cmr_reg %>% filter(NAME_1 %in% c('Sud', 'Centre', 'Est'))

cat('Régions septentrionales :', nrow(reg_nord), '\n')

# Visualisation rapide
plot(st_geometry(cmr_reg), col = 'lightgray', border = 'white', main = 'Filtrage régions')
plot(st_geometry(reg_nord), col = 'orange', add = TRUE)
plot(st_geometry(reg_sud),  col = 'steelblue', add = TRUE)


## ========================================================================
## 4.2 SOUS-RÉGLAGE SPATIAL (SPATIAL SUBSETTING)
## ========================================================================
#Le sous-réglage spatial sélectionne des entités en fonction de leur relation géographique avec d'autres entités (intersection, appartenance, proximité...).

# --- Exemple 1 : Grappes DHS dans une région administrative ---
# Sélectionner les grappes DHS situées dans la région Centre


## --- Étape 1 : Extraire la région Centre -----------------------------
centre_poly <- cmr_reg %>% filter(NAME_1 == 'Centre')


## --- Étape 2 : S'assurer que les deux couches ont le même CRS --------
st_crs(centre_poly) == st_crs(dhs_gps)  # Doit être TRUE

# Si FALSE : reprojeter
dhs_gps_wgs <- st_transform(dhs_gps, st_crs(centre_poly))


## --- Étape 3 : Sous-réglage spatial avec l'opérateur [ ---------------
grappes_centre <- dhs_gps_wgs[centre_poly, ]
cat('Grappes dans la région Centre :', nrow(grappes_centre), '\n')

# Même résultat avec st_filter() — plus explicite
grappes_centre2 <- st_filter(dhs_gps_wgs, centre_poly)

# --- Exemple 2 : Districts sanitaires dans les régions frontalières ---
# Régions ayant une frontière internationale
reg_frontiere <- cmr_reg %>%
  filter(NAME_1 %in% c('Adamaoua', 'Nord', 'Extrême-Nord',
                        'Est', 'Sud', 'Littoral'))

ds_frontiere <- st_filter(ds, reg_frontiere)
cat('Districts en zone frontalière :', nrow(ds_frontiere), '\n')

# --- Exemple 3 : Prédicat spatial explicite ---
# st_intersects, st_within, st_contains, st_overlaps, st_touches

# Districts qui INTERSECTENT la région Nord
reg_nord_1 <- cmr_reg %>% filter(NAME_1 == 'Nord')
ds_nord <- st_filter(ds, reg_nord_1, .predicate = st_intersects)

# Points DHS DANS la région Extrême-Nord
reg_en <- cmr_reg %>% filter(NAME_1 == 'Extrême-Nord')
dhs_en <- st_filter(dhs_gps_wgs, reg_en, .predicate = st_within)

## La zone tampon, ou comment fabriquer de la proximité. st_buffer(obj, 5000)
## entoure chaque objet d'une auréole de 5 km. Le résultat n'est plus un
## point : c'est une surface, qu'on peut croiser avec n'importe quelle autre
## couche.
##
## Deux précautions.
##
## L'unité est celle du CRS. En UTM, dist = 5000 vaut 5 kilomètres. En WGS84,
## 5000 vaudrait 5 000 degrés — un non-sens. C'est pourquoi le code projette
## avant de tamponner.
##
## Les tampons se recouvrent. Deux grappes distantes de 6 km produisent deux
## disques qui se chevauchent. Compter la population dans l'union de ces
## disques n'est pas la même chose que sommer la population de chacun :
## st_union() fusionne d'abord, sinon on double le décompte.
##
## À quoi cela sert en démographie : « combien de personnes vivent à moins de
## 5 km d'un centre de santé ? » est une question d'accessibilité, et elle ne
## se pose qu'en termes de distance — donc de géométrie.
##

## ========================================================================
## 4.3 SÉLECTION PAR ZONE TAMPON (BUFFER)
## ========================================================================
# Important : st_buffer() nécessite un CRS métrique (mètres)
# On travaille en UTM Zone 33N (EPSG:32633)

dhs_utm <- st_transform(dhs_gps, 32633)
ds_utm  <- st_transform(ds, 32633)

# --- Buffer de 5 km autour des grappes DHS rurales ---
dhs_rural_utm <- dhs_utm %>% filter(URBAN_RURA == 'R')
buffer_5km <- st_buffer(dhs_rural_utm, dist = 5000)  # dist en mètres

# Fusionner tous les buffers en un seul polygone
buffer_union <- st_union(buffer_5km)

# --- Grappes DHS à moins de 10 km d'une frontière ---
# Récupérer la frontière nationale du Cameroun
cmr_nat <- st_read('datasets/gadm41_CMR_0.shp', quiet = TRUE) %>%
  st_transform(32633)

# Calculer la distance entre chaque grappe et la frontière nationale
# st_boundary() extrait le contour (ligne frontière)
frontiere_ligne <- st_boundary(cmr_nat)

dist_frontiere <- st_distance(dhs_utm, frontiere_ligne)
# dist_frontiere est une matrice en mètres

# Ajouter la distance minimale comme attribut
dhs_utm$dist_frontiere_km <- as.numeric(dist_frontiere[, 1]) / 1000

# Grappes à moins de 30 km de la frontière
dhs_frontalier <- dhs_utm %>% filter(dist_frontiere_km < 30)
cat('Grappes à moins de 30 km des frontières :', nrow(dhs_frontalier), '\n')

#Les jointures permettent de combiner des informations provenant de sources différentes — une opération quotidienne à l'INS. Nous distinguons la jointure attributaire (sur une clé commune) et la jointure spatiale (sur la localisation).


## ========================================================================
## 5.1 JOINTURE ATTRIBUTAIRE : POPULATION + LIMITES ADMINISTRATIVES
## ========================================================================
# Combiner donnees de population (CSV) avec geometries (SHP)

library(sf); library(dplyr); library(readr); library(janitor)

cmr_depart <- st_read('datasets/gadm41_CMR_2.shp', quiet = TRUE)

# --- Les deux cles en presence ----------------------------------------------
# GADM ecrit les noms officiels, accentues : "Benoue" s'y lit "Bénoué".
# WorldPop les ecrit sans accents et avec des variantes de liaison.
cat('GADM       :', head(cmr_depart$NAME_2, 4), '\n')
cat('WorldPop   :', head(pop_adm2$names1,   4), '\n\n')

# --- Tentative naive : jointure sur le nom brut -----------------------------
essai_naif <- cmr_depart %>%
  st_drop_geometry() %>%
  left_join(pop_adm2, by = c('NAME_2' = 'names1'))

cat('Jointure naive -- departements sans population :',
    sum(is.na(essai_naif$total)), 'sur', nrow(essai_naif), '\n')
# left_join ne previent JAMAIS d'un non-appariement : il remplit avec NA.
# Compter les NA apres chaque jointure est le reflexe qui sauve une analyse.

# --- La solution : normaliser les libelles ----------------------------------
# On retire accents, casse, ponctuation, et les mots de liaison ("et", "de",
# "du", "la", "le") qui varient d'une source a l'autre.
normaliser <- function(x) {
  x %>%
    stringi::stri_trans_general('Latin-ASCII') %>%
    tolower() %>%
    stringr::str_replace_all('[^a-z ]', ' ') %>%
    stringr::str_replace_all('\\b(et|de|du|la|le)\\b', ' ') %>%
    stringr::str_replace_all('\\s+', '')
}

# Verification sur les cas qui echouaient
tibble(
  gadm     = c('Bénoué', 'Ndé', "Nyong et So'o", 'Koupé Manengouba'),
  worldpop = c('Benoue', 'Nde', 'Nyong et Soo',  'Koupe et Manengouba')
) %>%
  mutate(cle_gadm = normaliser(gadm), cle_wp = normaliser(worldpop),
         concorde = cle_gadm == cle_wp) %>%
  print()

# --- Jointure sur la cle normalisee -----------------------------------------
cmr_pop <- cmr_depart %>%
  mutate(cle = normaliser(NAME_2)) %>%
  left_join(pop_adm2   %>% mutate(cle = normaliser(names1)) %>%
              select(cle, pop_total = total, pop_bas = lower,
                     pop_haut = upper, incertitude = uncertainty),
            by = 'cle') %>%
  left_join(menage_adm2 %>% mutate(cle = normaliser(names1)) %>%
              select(cle, menages = total),
            by = 'cle')

cat('\nApres normalisation -- departements sans population :',
    sum(is.na(cmr_pop$pop_total)), 'sur', nrow(cmr_pop), '\n\n')

# --- Ce que la jointure rend possible ---------------------------------------
cmr_pop <- cmr_pop %>%
  mutate(taille_moy_menage = round(pop_total / menages, 2))

cmr_pop %>%
  st_drop_geometry() %>%
  select(NAME_2, NAME_1, pop_total, menages, taille_moy_menage) %>%
  arrange(desc(pop_total)) %>%
  head(10) %>%
  print()

summary(cmr_pop$taille_moy_menage)


## ========================================================================
## 5.2 JOINTURE SPATIALE : GRAPPES DHS → DISTRICTS SANITAIRES
## ========================================================================
# JOINTURE SPATIALE
# Associer chaque grappe DHS à son district sanitaire

# Harmoniser les CRS
ds_wgs  <- st_transform(ds, 4326)
dhs_wgs <- st_transform(dhs_gps, 4326)

# --- st_join() : jointure spatiale principale ---
# Par défaut : st_intersects (le point est DANS le polygone)
dhs_avec_district <- st_join(dhs_wgs, ds_wgs,
                              join = st_within)

# Vérification
cat('Grappes avec district assigne :',
    sum(!is.na(dhs_avec_district$district)), 'sur', nrow(dhs_avec_district), '\n')
# 'district' est la colonne creee par lire_ds() a partir de 'name'.
# Les grappes sans district tombent hors des polygones : soit en mer, soit
# dans les interstices laisses par le decoupage sanitaire.

# --- Compter le nombre de grappes par district ---
nb_grappes_par_ds <- dhs_avec_district %>%
  as.data.frame() %>%
  group_by(district) %>%
  summarise(nb_grappes = n(), .groups = 'drop')

# Ramener ce compte dans la couche districts
ds_avec_grappes <- ds_wgs %>%
  left_join(nb_grappes_par_ds, by = 'district')

# --- Jointure spatiale inverse ---
# Associer chaque district au pays limitrophe (si frontalier)
pays_wgs <- st_transform(pays_lim, 4326)
ds_pays  <- st_join(ds_wgs, pays_wgs %>% select(NOM_PAYS = COUNTRY),
                    join = st_intersects, left = TRUE)
# Les districts non-frontaliers auront NA dans NOM_PAYS

## La jointure spatiale, c'est demander à la carte plutôt qu'à une clé.
## st_join(dhs_wgs, ds_wgs, join = st_within) pose à chaque grappe : *dans
## quel district suis-je tombée ?* — et rapatrie les attributs du district
## gagnant.
##
## Le résultat affiché plus haut mérite lecture : 429 grappes sur 430 ont
## trouvé leur district. La grappe manquante tombe hors de tout polygone — le
## découpage sanitaire ne couvre pas parfaitement le littoral, et les
## coordonnées EDS sont volontairement déplacées de 2 à 5 km pour protéger
## l'anonymat. Un point côtier peut donc se retrouver en mer.
##
## Le prédicat choisi change le résultat. st_within exige que le point soit
## strictement à l'intérieur ; st_intersects accepte aussi les points posés
## exactement sur une frontière. Sur des données réelles, l'écart est faible
## mais jamais nul — et c'est toujours au bord que se logent les cas
## litigieux.
##
## C'est l'opération qu'aucun logiciel statistique classique ne sait faire,
## et la raison d'être de toute cette formation.
##

## ========================================================================
## 5.3 JOINTURE DHS : LIER MÉNAGES SPATIALISÉS AUX INDICATEURS
## ========================================================================
# JOINTURE COMPLÈTE DHS
# Fusionner GPS + Données ménages → puis spatial vers districts

library(haven)

# --- Étape 1 : Charger et nettoyer le fichier ménages DHS ---
dhs_men <- read_sav('datasets/CMHR71FL.SAV') %>%
  select(DHSCLUST = HV001,   # Numéro de grappe (clé de jointure)
         milieu   = HV025,   # 1=urbain, 2=rural
         richesse = HV270,   # Quintile de richesse
         eau      = HV201,   # Source eau de boisson
         elec     = HV206,   # Électricité
         nb_membres = HV009  # Taille du ménage
  ) %>%
  mutate(across(where(is.labelled), as_factor))

# --- Étape 2 : Agréger par grappe ---
# Calculer des indicateurs moyens par grappe
indicateurs_grappe <- dhs_men %>%
  group_by(DHSCLUST) %>%
  summarise(
    n_menages     = n(),
    taille_moy    = mean(as.numeric(nb_membres), na.rm = TRUE),
    pct_elec      = mean(as.numeric(elec) == 1, na.rm = TRUE) * 100,
    q_richesse_moy = mean(as.numeric(richesse), na.rm = TRUE),
    .groups = 'drop'
  )

# --- Étape 3 : Joindre avec les coordonnées GPS ---
dhs_gps_attr <- dhs_gps %>%
  left_join(indicateurs_grappe, by = 'DHSCLUST')

cat('Grappes avec données ménages :', sum(!is.na(dhs_gps_attr$n_menages)), '\n')

# --- Étape 4 : Jointure spatiale vers les districts sanitaires ---
dhs_gps_attr_wgs <- st_transform(dhs_gps_attr, 4326)
ds_wgs           <- st_transform(ds, 4326)

ds_indicateurs <- st_join(ds_wgs, dhs_gps_attr_wgs, join = st_contains) %>%
  as.data.frame() %>%
  group_by(district) %>%
  summarise(
    pct_elec_moy = mean(pct_elec, na.rm = TRUE),
    richesse_moy  = mean(q_richesse_moy, na.rm = TRUE),
    .groups = 'drop'
  )

# Rejoindre avec la géométrie des districts
ds_final <- ds_wgs %>% left_join(ds_indicateurs, by = 'district')

#Ce module est le point culminant de la journée : produire des cartes professionnelles et informatives des données camerounaises. Nous utilisons ggplot2 (cartes statiques), tmap (cartes thématiques) et mapview (exploration interactive).


## ========================================================================
## 6.1 CARTE DE BASE AVEC GGPLOT2 : FRONTIÈRES NATIONALES ET RÉGIONALES
## ========================================================================
library(sf)
library(ggplot2)
library(dplyr)
library(RColorBrewer)

# Charger toutes les couches nécessaires
cmr_nat  <- st_read('datasets/gadm41_CMR_0.shp', quiet = TRUE)
cmr_reg  <- st_read('datasets/gadm41_CMR_1.shp', quiet = TRUE)
pays_lim <- lire_pays()
ds       <- lire_ds()
dhs_gps  <- st_read('datasets/CMGE71FL.shp', quiet = TRUE)

# Harmoniser les CRS
pays_lim <- st_transform(pays_lim, 4326)
cmr_nat  <- st_transform(cmr_nat,  4326)
cmr_reg  <- st_transform(cmr_reg,  4326)
ds       <- st_transform(ds,       4326)
dhs_gps  <- st_transform(dhs_gps,  4326)

# --- CARTE 1 : Frontières nationales + pays limitrophes ---
carte_base <- ggplot() +

  # Couche 1 : Pays limitrophes (fond gris)
  geom_sf(data  = pays_lim,
          fill  = 'gray92',
          color = 'gray60',
          linewidth  = 0.3) +

  # Couche 2 : Frontière nationale Cameroun
  geom_sf(data  = cmr_nat,
          fill  = '#E8F4F8',
          color = '#2E75B6',
          linewidth  = 0.8) +

  # Couche 3 : Régions
  geom_sf(data  = cmr_reg,
          fill  = NA,
          color = 'gray30',
          linewidth  = 0.4,
          linetype = 'dashed') +

  # Labels des régions
  geom_sf_text(data     = cmr_reg,
               aes(label = NAME_1),
               size     = 2.5,
               color    = 'gray20',
               fontface = 'bold') +

  # Labels des pays limitrophes
  geom_sf_label(data     = pays_lim,
                aes(label = COUNTRY),
                size     = 2.2,
                color    = 'gray40',
                fill     = 'white',
                alpha    = 0.7,
                linewidth = 0.1) +

  # Emprise sur le Cameroun + un peu de contexte
  coord_sf(xlim = c(8.3, 16.3),
           ylim = c(1.5, 13.2)) +

  labs(
    title    = 'Cameroun : Régions administratives et pays limitrophes',
    subtitle = 'Source : GADM v4.1, 2024',
    caption  = 'Système de coordonnées : WGS84 (EPSG:4326)',
    x = 'Longitude', y = 'Latitude'
  ) +

  theme_minimal(base_size = 11) +
  theme(
    plot.title    = element_text(face = 'bold', color = '#1F4E79', size = 13),
    plot.subtitle = element_text(color = 'gray40', size = 9),
    panel.grid    = element_line(color = 'gray90', linewidth = 0.3)
  )

print(carte_base)

# Sauvegarde
ggsave('outputs/carte_base_cameroun.png',
       plot   = carte_base,
       width  = 18,
       height = 22,
       units  = 'cm',
       dpi    = 300)


## ========================================================================
## 6.2 CARTE THÉMATIQUE : DISTRICTS SANITAIRES COLORÉS PAR RÉGION
## ========================================================================
# Palette de 10 couleurs (une par région)
couleurs_regions <- brewer.pal(10, 'Set3')

carte_ds <- ggplot() +

  # Fond : pays limitrophes
  geom_sf(data  = pays_lim,
          fill  = 'gray94',
          color = 'gray70',
          linewidth  = 0.2) +

  # Districts sanitaires colorés par région
  geom_sf(data = ds,
          aes(fill = region),
          color = 'white',
          size  = 0.15) +

  # Contour des régions GADM par-dessus
  geom_sf(data  = cmr_reg,
          fill  = NA,
          color = 'gray20',
          linewidth  = 0.6) +

  # Frontière nationale
  geom_sf(data  = cmr_nat,
          fill  = NA,
          color = '#1F4E79',
          size  = 1.0) +

  scale_fill_brewer(palette = 'Set3', name = 'Région') +

  coord_sf(xlim = c(8.3, 16.3), ylim = c(1.5, 13.2)) +

  labs(
    title    = 'Districts Sanitaires du Cameroun par Région',
    subtitle = 'Source : Ministère de la Santé Publique du Cameroun',
    caption  = 'WGS84 (EPSG:4326)',
    x = NULL, y = NULL
  ) +

  theme_minimal(base_size = 10) +
  theme(
    plot.title  = element_text(face = 'bold', color = '#1F4E79', size = 12),
    legend.position = 'right',
    panel.grid  = element_line(color = 'gray90', linewidth = 0.2)
  )

print(carte_ds)
ggsave('outputs/carte_districts_sanitaires.png',
       carte_ds, width = 20, height = 24, units = 'cm', dpi = 300)

## Lire cette carte. Chaque point est une grappe d'enquête, colorée et
## symbolisée selon son milieu. La forme redouble la couleur volontairement :
## un lecteur daltonien, ou une impression en noir et blanc, distinguent
## encore le triangle du cercle. **Ne jamais faire reposer une information
## sur la seule couleur.**
##
## Deux choses sautent aux yeux, qu'aucun tableau ne montrait. Les grappes
## urbaines se concentrent en quelques foyers — Douala, Yaoundé, les chefs-
## lieux régionaux — tandis que les rurales tapissent le territoire. Et le
## **maillage est plus lâche à l'est** : forêt, faible densité, accès
## difficile. Une carte d'indicateur construite sur ces grappes sera donc
## mécaniquement moins fiable dans cette zone.
##
## C'est un point de méthode important : la géographie de l'échantillon
## conditionne la qualité de tout ce qu'on en tire. On le verra formalisé au
## J07, avec les statistiques spatiales.
##

## ========================================================================
## 6.3 CARTE AVEC LES GRAPPES DHS SELON LE MILIEU DE RÉSIDENCE
## ========================================================================
# Séparer urbain et rural
dhs_urb <- dhs_gps %>% filter(URBAN_RURA == 'U')
dhs_rur <- dhs_gps %>% filter(URBAN_RURA == 'R')

# Un libelle lisible plutot qu'un code a une lettre
dhs_milieu <- dhs_gps %>%
  mutate(milieu = dplyr::recode(URBAN_RURA, U = 'Urbain', R = 'Rural'))

carte_dhs <- ggplot() +

  # Fond pays limitrophes
  geom_sf(data = pays_lim, fill = 'gray94', color = 'gray70', size = 0.2) +

  # Cameroun en fond
  geom_sf(data = cmr_nat, fill = 'white', color = NA) +

  # Régions
  geom_sf(data = cmr_reg, fill = NA, color = 'gray70', linewidth = 0.3) +

  # Les grappes, en UNE couche : la couleur et la forme sont MAPPEES sur la
  # variable milieu, via aes(). C'est ce qui fait apparaitre une legende.
  # Fixer color = '#C00000' hors de aes() colore les points mais ne cree
  # aucune legende -- et scale_color_manual() n'a alors rien a quoi se
  # raccrocher ("No shared levels found").
  geom_sf(data = dhs_milieu,
          aes(color = milieu, shape = milieu),
          size = 1.9, alpha = 0.8) +

  # Frontière nationale
  geom_sf(data = cmr_nat, fill = NA, color = '#1F4E79', linewidth = 0.9) +

  scale_color_manual(name = 'Milieu',
                     values = c('Urbain' = '#C00000', 'Rural' = '#2E8B57')) +
  scale_shape_manual(name = 'Milieu', values = c('Urbain' = 17, 'Rural' = 16)) +

  coord_sf(xlim = c(8.3, 16.3), ylim = c(1.5, 13.2)) +

  labs(
    title    = 'Localisation des grappes DHS Cameroun 2018',
    subtitle = paste0('Urbain (rouge) : n=', nrow(dhs_urb),
                      '   Rural (vert) : n=', nrow(dhs_rur)),
    caption  = 'Source : DHS Programme 2018 — Cameroun',
    x = NULL, y = NULL
  ) +

  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = 'bold', color = '#1F4E79'))

print(carte_dhs)
ggsave('outputs/carte_grappes_dhs.png',
       carte_dhs, width = 18, height = 22, units = 'cm', dpi = 300)


## ========================================================================
## 6.4 CARTE INTERACTIVE AVEC MAPVIEW
## ========================================================================
## ----------------------------------------------------------------------
## Pourquoi ce bloc n'est pas exécuté
##
## mapview produit un widget autonome : il insère dans le HTML **toutes les
## géométries affichées**, plus la pile JavaScript de rendu. Ici, ds pèse à
## lui seul 20 Mo de GeoJSON. Le document rendu dépasserait allègrement les
## 50 Mo, pour un interactif qui n'a d'intérêt qu'en direct.
##
## Le code reste complet et commenté : lancez-le dans RStudio, la carte
## s'ouvre dans le panneau Viewer.
##
## ----------------------------------------------------------------------

## --- BLOC DE REFERENCE, NON EXECUTE ---
# # CARTE INTERACTIVE — mapview  (A LANCER DANS RSTUDIO, PAS AU RENDU)
# # Idéal pour l'exploration et la vérification des données
# 
# library(mapview)
# 
# # Vue rapide d'une seule couche
# mapview(ds, zcol = 'region',
#         layer.name = 'Districts sanitaires')
# 
# # --- Superposer plusieurs couches ---
# carte_interactive <- mapview(
#   pays_lim,
#   col.regions  = 'gray90',
#   color        = 'gray60',
#   layer.name   = 'Pays limitrophes',
#   alpha.regions = 0.3
# ) +
# mapview(
#   ds,
#   col.regions = hcl.colors(10, 'Spectral'),
#   zcol        = 'region',
#   layer.name  = 'Districts sanitaires'
# ) +
# mapview(
#   dhs_gps,
#   zcol        = 'URBAN_RURA',
#   col.regions = c('#C00000', '#2E8B57'),
#   layer.name  = 'Grappes DHS 2018',
#   cex         = 3
# )
# 
# carte_interactive  # Affiche la carte dans le panneau Viewer de RStudio
# 
# # Sauvegarder en HTML (partageable sans R)
# # NB : mapshot() exige le paquet webshot2 et un navigateur Chrome/Chromium
# # installe sur le poste. Sans cela, l'appel echoue. C'est pourquoi il n'est
# # pas dans install_packages_day.R : a installer seulement si besoin.
# #   install.packages("webshot2")
# mapview::mapshot(carte_interactive,
#                  url = 'outputs/carte_interactive_cameroun.html')


## ========================================================================
## 6.5 CARTE THÉMATIQUE AVEC TMAP : DENSITÉ DE POPULATION
## ========================================================================
## ggplot2 sait faire des cartes ; tmap est conçu pour cela. Il apporte les
## objets que le cartographe attend d'emblée — classification en classes,
## échelle, flèche du nord, mentions de source — sans avoir à les bricoler.
##
library(tmap)
tmap_mode('plot')   # 'plot' = statique ; 'view' = interactif (cf. 6.4)

# --- Calculer la densite : mesurer exige un CRS metrique --------------------
cmr_pop_utm <- st_transform(cmr_pop, 32633)          # UTM 33N, en metres
cmr_pop_utm$superficie_km2 <- as.numeric(st_area(cmr_pop_utm)) / 1e6
cmr_pop_utm$densite        <- cmr_pop_utm$pop_total / cmr_pop_utm$superficie_km2

# On revient en WGS84 pour l'affichage : mesurer en metres, dessiner en degres.
cmr_pop_wgs <- st_transform(cmr_pop_utm, 4326)

# --- La carte, en syntaxe tmap 4 -------------------------------------------
# Differences avec tmap 3 : le remplissage est 'fill' (et non 'col'), les
# echelles passent par tm_scale_*() au lieu du couple palette=/style=/n=,
# le titre par tm_title(), et tm_scale_bar() est devenu tm_scalebar().
carte_tmap <- tm_shape(pays_lim) +
  tm_polygons(fill = 'gray92', col = 'gray70', lwd = 0.5) +

tm_shape(cmr_pop_wgs) +
  tm_polygons(
    fill        = 'densite',
    fill.scale  = tm_scale_intervals(style = 'jenks', n = 6,
                                     values = 'brewer.yl_or_rd'),
    fill.legend = tm_legend(title = 'Densité (hab/km²)'),
    col = 'white', lwd = 0.3
  ) +

tm_shape(cmr_reg) +
  tm_borders(col = 'gray30', lwd = 0.8) +

tm_shape(cmr_nat) +
  tm_borders(col = '#1F4E79', lwd = 1.5) +

  tm_title('Densité de population par département — Cameroun',
           size = 1.1, color = '#1F4E79') +
  tm_compass(type = '8star', position = c('left', 'bottom'), size = 2) +
  tm_scalebar(position = c('left', 'bottom')) +
  tm_credits('Sources : WorldPop, GADM v4.1 — SCR : WGS84 (EPSG:4326)',
             position = c('right', 'bottom'), size = 0.6) +
  tm_layout(frame = FALSE, bg.color = 'white', legend.outside = TRUE)

carte_tmap

tmap_save(carte_tmap, 'outputs/carte_densite_population.png',
          width = 20, height = 25, units = 'cm', dpi = 300)

## Densité et population ne racontent pas la même histoire. Un département
## vaste et peuplé peut être moins dense qu'un petit département moyennement
## peuplé. C'est la densité qui pilote les besoins — écoles, centres de
## santé, réseaux — et elle n'existe pas sans géométrie : aucun fichier ne la
## contient, il a fallu mesurer les surfaces.
##
## Le découpage en classes n'est pas neutre. style = 'jenks' cherche les
## ruptures naturelles du nuage de valeurs et fait ressortir les groupes
## réellement distincts. style = 'quantile' mettrait le même nombre de
## départements dans chaque classe, garantissant une carte contrastée — y
## compris là où les écarts sont dérisoires. Le choix des seuils est un acte
## d'interprétation : il s'assume et se documente en légende.
##
## La palette non plus. brewer.yl_or_rd est séquentielle : elle progresse
## dans une seule direction, pour une quantité qui croît, et reste lisible en
## niveaux de gris comme pour les daltoniens. Une palette à teintes multiples
## suggérerait à tort des catégories sans ordre.
##

## ========================================================================
## VOCABULAIRE DE LA JOURNÉE
## ========================================================================

## --- Les objets ------------------------------------------------------
## | Terme | Ce que c'est |
## | Simple Feature | norme ISO 19125 : une géométrie et ses attributs dans une ligne de tableau |
## | Objet sf | un data.frame plus une colonne geometry |
## | POINT / LINESTRING / POLYGON | les trois formes de base |
## | MULTI‑ | la même chose en plusieurs morceaux disjoints — une commune avec une enclave |
## | Emprise (bounding box) | le plus petit rectangle contenant la couche |
## | Géométrie invalide | bords qui se croisent ou sommets dupliqués ; invisible à l'affichage, bloquante au calcul |
##

## --- Le positionnement -----------------------------------------------
## | Terme | Ce que c'est |
## | CRS | la convention qui traduit un lieu en deux nombres |
## | EPSG:4326 | WGS84, en degrés — pour afficher |
## | EPSG:32632 / 32633 | UTM 32N / 33N, en mètres — pour mesurer |
## | Reprojeter | st_transform() : mêmes lieux, autres nombres |
## | s2 / GEOS | moteur sphérique ou planaire ; s2 est plus juste, GEOS plus tolérant |
##

## --- Les opérations --------------------------------------------------
## | Terme | Ce que c'est |
## | Jointure attributaire | left_join() — la clé est un identifiant partagé |
## | Jointure spatiale | st_join() — la clé est la position |
## | st_within / st_intersects | « strictement dedans » ou « dedans, bord compris » |
## | Sous-réglage spatial | obj[zone, ] — garder ce qui touche une zone |
## | Zone tampon | st_buffer() — une auréole de rayon fixé, dans l'unité du CRS |
## | Centroïde | le point d'équilibre d'un polygone ; peut tomber hors de celui-ci |
##

## --- À quoi sert le vectoriel ----------------------------------------
## Le vecteur répond à des questions qu'un tableau ne peut pas formuler :
##
## 1. « Dans quoi suis-je ? » — rattacher une grappe d'enquête à son district
## sans disposer d'aucun code commun. C'est la jointure spatiale, et c'est ce
## que ni STATA ni SPSS ne savent faire. 2. « À quelle distance ? » —
## accessibilité aux services, aires de desserte, populations à moins de 5 km
## d'un centre de santé. 3. « Combien par unité de surface ? » — la densité,
## premier indicateur proprement spatial, qui n'existe pas sans géométrie. 4.
## « Qui est à côté de qui ? » — le voisinage, qui portera tout le J07.
##
## Et une leçon transversale, apprise trois fois aujourd'hui : **les données
## réelles mentent sur leur forme**. Colonnes aux noms inattendus,
## séparateurs inconstants, libellés non concordants, géométries invalides.
## Inspecter d'abord, coder ensuite.
##

## ========================================================================
## EXERCICES RÉCAPITULATIFS
## ========================================================================
## À réaliser individuellement ou en binôme ; les solutions sont discutées en
## groupe en fin de journée. Le corrigé complet est dans
## script_etudiant_J03_corrige.R.
##

## --- Exercice 1 — Prise en main (30 min) -----------------------------
## 1. Charger DS.geojson et afficher ses cinq premières lignes. 2. Vérifier
## le CRS, puis reprojeter en UTM zone 33N (EPSG:32633). 3. Calculer la
## superficie en km² de chaque district sanitaire. Rappel : mesurer en degrés
## n'a aucun sens — projeter d'abord. 4. Identifier le district le plus grand
## et le plus petit. 5. Produire une carte simple avec ggplot2, régions GADM
## superposées.
##

## --- Exercice 2 — Intermédiaire (45 min) -----------------------------
## 1. Joindre CMR_population_v1_0_admin_level2.csv à gadm41_CMR_2.shp.
## Attention au séparateur ; et à la normalisation des libellés. 2. Calculer
## la densité de population par unité administrative. 3. Cartographier cette
## densité avec tmap : palette "brewer.blues", classification par quantiles.
## 4. Joindre spatialement les grappes DHS rurales aux districts sanitaires.
## 5. Exporter le résultat en GeoPackage, deux couches — districts enrichis
## et grappes.
##

## --- Exercice 3 — Avancé (60 min) ------------------------------------
## 1. Depuis CMHR71FL.SAV, calculer le taux d'accès à l'eau potable par
## grappe. 2. Rattacher ces indicateurs aux coordonnées GPS de CMGE71FL.shp,
## via DHSCLUST. 3. Joindre spatialement le résultat aux districts
## sanitaires. 4. Produire une carte thématique des districts selon le taux
## moyen d'accès. 5. Exporter une carte interactive mapview d'au moins cinq
## couches.
##

## ========================================================================
## ANNEXE A — AIDE-MÉMOIRE SF
## ========================================================================
## --- BLOC DE REFERENCE, NON EXECUTE ---
# # BLOC DE REFERENCE, NON EXECUTE -- a garder sous la main.
# 
# # LECTURE / ECRITURE
# st_read('fichier.shp')                          # lire un fichier spatial
# st_write(obj, 'outputs/sortie.gpkg', 'couche')  # ecrire
# st_layers('outputs/fichier.gpkg')               # lister les couches
# 
# # SYSTEMES DE COORDONNEES
# st_crs(obj)                        # lire le CRS
# st_transform(obj, 4326)            # reprojeter en WGS84 (degres)
# st_transform(obj, 32633)           # reprojeter en UTM 33N (metres)
# 
# # GEOMETRIE
# st_geometry(obj)                   # extraire la geometrie
# st_geometry_type(obj)              # POINT, POLYGON, MULTIPOLYGON...
# st_bbox(obj)                       # emprise : xmin, ymin, xmax, ymax
# st_is_valid(obj)                   # verifier la validite
# st_make_valid(obj)                 # corriger
# 
# # MESURES -- exigent un CRS metrique !
# st_area(obj)                       # superficie
# st_distance(obj1, obj2)            # distance
# st_length(obj)                     # longueur (lignes)
# 
# # OPERATIONS GEOMETRIQUES
# st_buffer(obj, dist = 5000)        # zone tampon de 5 km
# st_union(obj)                      # fusionner les geometries
# st_intersection(obj1, obj2)        # intersection
# st_difference(obj1, obj2)          # difference
# st_centroid(obj)                   # centroide
# 
# # FILTRAGE SPATIAL
# obj[masque, ]                      # sous-reglage par l'operateur [
# st_filter(obj, zone)               # equivalent, plus explicite
# st_intersects(obj1, obj2)          # matrice d'intersection
# st_within(obj1, obj2)              # points dans polygones
# 
# # JOINTURES
# st_join(obj1, obj2)                # spatiale -- la cle est la position
# left_join(sf_obj, df, by = 'cle')  # attributaire -- la cle est un identifiant
# 
# # CONVERSION
# st_as_sf(df, coords = c('lon', 'lat'), crs = 4326)   # tableau -> sf
# st_drop_geometry(obj)                                # sf -> tableau


## ========================================================================
## ANNEXE B — CODES EPSG UTILES AU CAMEROUN
## ========================================================================
## | Code | Système | Unité | Usage |
## | 4326 | WGS84 | degrés | GPS, EDS, web — pour afficher |
## | 32632 | UTM zone 32N | mètres | Cameroun ouest (Douala) — pour mesurer |
## | 32633 | UTM zone 33N | mètres | Cameroun centre (Yaoundé) — pour mesurer |
## | 32634 | UTM zone 34N | mètres | Cameroun est |
## | 4222 | Arc 1960 | degrés | ancien système local, cartes IGN historiques |
##
## --- BLOC DE REFERENCE, NON EXECUTE ---
# # Deux objets sont-ils dans le meme CRS ?
# st_crs(objet1) == st_crs(objet2)
# 
# # Tout ramener a un CRS commun avant toute operation croisee
# crs_cible <- 4326
# objet2 <- st_transform(objet2, crs_cible)


## ========================================================================
## ANNEXE C — POUR ALLER PLUS LOIN
## ========================================================================
## - Geocomputation with R, Lovelace, Nowosad & Muenchow —
## <https://r.geocompx.org> (libre accès) - Documentation sf —
## <https://r-spatial.github.io/sf/> - Documentation tmap —
## <https://r-tmap.github.io/tmap/> - Programme DHS —
## <https://dhsprogram.com/data/> - WorldPop — <https://hub.worldpop.org/> -
## GADM, limites administratives — <https://gadm.org/>
##
## Demain (J04) : la Terre en pixels — les données raster avec terra,
## résolution, emprise, algèbre de bandes et extraction vers des polygones.
##
