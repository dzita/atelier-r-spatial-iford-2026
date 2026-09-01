## ============================================================================
## SCRIPT ETUDIANT -- J03 : L'UNIVERS VECTORIEL
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Mercredi 29 juillet 2026
##
## MODE D'EMPLOI. Les commentaires portent la consigne : lisez-les, puis
## ecrivez votre code aux emplacements marques ">>> A COMPLETER". Avancez
## section par section, en verifiant chaque resultat avant de continuer.
## Le corrige complet est distribue en fin de journee.
##
## Donnees : datasets/ (chemins relatifs). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
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


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- POINT : localisation d'une formation sanitaire, d'un ménage enquêté ---
# Exemple : créer un point à Yaoundé (longitude, latitude)

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- MULTIPOINT : plusieurs localisations GPS d'enquête ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- LINESTRING : réseau routier, fleuve ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- POLYGON : district sanitaire, région administrative ---
# Un polygone = matrice de coordonnées fermée (1er = dernier point)

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- MULTIPOLYGON : région composée de plusieurs polygones ---
# C'est le type le plus fréquent dans les shapefiles administratifs

# Vérifier le type d'un objet


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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
    # a) Reparer les geometries : sommets dupliques et auto-intersections.
    #    Invisible a l'affichage, bloquant des le premier calcul geometrique.
    #    st_make_valid() sous GEOS (s2 desactive) les corrige toutes ;
    #    sous s2, il en resterait 3 sur 200.
    # b) Nommer les attributs utilement. Export DHIS2 : le nom du district est
    #    dans 'name' prefixe par "District ", et la region dans 'parentName'
    #    prefixee par "Region ". Aucune colonne ne s'appelle 'region'.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- STRUCTURE GÉNÉRALE ---
# sf affiche automatiquement les métadonnées géographiques

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- MÉTADONNÉES GÉOGRAPHIQUES ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- ACCÈS À LA COLONNE GEOMETRY ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- ATTRIBUTS TABULAIRES (comme un data.frame ordinaire) ---

# Point clé à retenir
#Un objet sf est à la fois un data.frame ET un objet spatial. Vous pouvez utiliser toutes les fonctions R classiques (nrow, ncol, names, head, summary, $, [, etc.) et AUSSI les fonctions spatiales sf (st_crs, st_bbox, st_geometry_type...).

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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


# Lecture brute, pour voir ce que st_read() annonce :

# st_read() affiche automatiquement :
# - le nom de la couche
# - le type de geometrie (MULTIPOLYGON, POINT...)
# - le nombre d'entites (features) et d'attributs (fields)
# - l'emprise spatiale (bounding box)
# - le systeme de coordonnees (CRS)
# L'argument quiet = TRUE supprime ces messages.

# En pratique, on passe par lire_ds() : lecture + preparation en un geste.


# Vérifications de base

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Données administratives GADM niveau 2 (Arrondissements) ---
# gadm41_CMR_shp contient plusieurs fichiers .shp :
# gadm41_CMR_0.shp  → frontière nationale
# gadm41_CMR_1.shp  → régions
# gadm41_CMR_2.shp  → départements / arrondissements


# Aperçu des colonnes GADM
# GID_0, NAME_0, GID_1, NAME_1, VARNAME_1, TYPE_1, ENGTYPE_1...


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 2.3 LECTURE DES FICHIERS DHS : CMGE71FL.SHP (GPS CLUSTERS)
## ========================================================================
# LECTURE DU FICHIER GPS DHS
# CMGE71FL.shp — Coordonnées GPS des grappes d'enquête DHS
# (Cameroun DHS 2018)


# Exploration
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
# CRS habituel DHS : WGS84 (EPSG:4326)

# Nombre de grappes

# Répartition urbain / rural


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 2.4 LECTURE DES DONNÉES SPSS DHS : CMHR71FL.SAV ET CMIR71FL.SAV
## ========================================================================
# LECTURE DES FICHIERS SPSS (.sav) — Données DHS
# CMHR71FL.SAV : questionnaire Ménage (Household Recode)
# CMIR71FL.SAV : questionnaire Femmes (Individual/Women Recode)


# Lecture du fichier ménages DHS

# Lecture du fichier femmes DHS

# Dimensions

# Les fichiers DHS ont des centaines de variables — ciblons les clés

# Convertir les labels SPSS en facteurs R lisibles

# Résumé


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 2.5 LECTURE DES DONNÉES CSV : POPULATION ET MÉNAGES
## ========================================================================
# LECTURE DES FICHIERS CSV
# CMR_population_v1_0_admin_level2.csv  — Population WorldPop (58 departements)
# CMR_household_v1_0_admin_level2.csv   — Menages WorldPop
# CMGC72FL.csv                          — Covariables contextuelles DHS


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- PIEGE : les deux fichiers WorldPop n'ont PAS le meme separateur ---------
# La population est en POINTS-VIRGULES, les menages en VIRGULES. read_csv()
# sur le premier renverrait une colonne unique -- sans lever d'erreur.
# Reflexe : ouvrir un CSV inconnu dans un editeur de texte avant de l'importer.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Les colonnes REELLES de ces fichiers ------------------------------------
# id          identifiant du departement
# names1      nom du departement (sans accents !)
# total       estimation centrale
# lower/upper intervalle de credibilite -- ces chiffres sont MODELISES
# uncertainty largeur relative de cet intervalle

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Covariables contextuelles des grappes DHS ------------------------------
# ATTENTION : ce fichier ne contient AUCUNE coordonnee. C'est CMGE71FL.shp,
# deja charge en section 2.3, qui porte la geometrie. Les deux se relient
# par le numero de grappe, DHSCLUST.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Recoller geometrie (shapefile) et attributs (CSV) ----------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 2.6 ÉCRITURE ET EXPORT DE FICHIERS SPATIAUX
## ========================================================================
# --- Export en GeoJSON ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Export en Shapefile ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Export en GeoPackage (recommandé : 1 seul fichier) ---
# Le GeoPackage est le format moderne recommandé.
# Il stocke plusieurs couches dans un seul fichier .gpkg

# Lister les couches d'un GeoPackage

# Relire une couche spécifique du GeoPackage

#SEQUNCE 3 — INSPECTION D'OBJETS SPATIAUX

#NB: Avant toute analyse, il est indispensable de comprendre la structure de vos données spatiales : système de coordonnées, emprise géographique, cohérence des géométries, distribution des attributs.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 3.1 LE SYSTÈME DE COORDONNÉES DE RÉFÉRENCE (CRS/SCR)
## ========================================================================
#Le CRS définit comment les coordonnées numériques sont liées à la surface terrestre. C'est la source principale d'erreurs dans les analyses SIG : deux couches dans des CRS différents ne peuvent pas être combinées directement.

#📌 WGS84 vs UTM : les deux CRS principaux au Cameroun
#• WGS84 (EPSG:4326) : coordonnées en degrés décimaux (longitude, latitude). Standard mondial GPS, DHS, GADM, WorldPop.
#• UTM Zone 33N (EPSG:32633) : coordonnées en mètres, adapté au Cameroun occidental et central.
#• UTM Zone 34N (EPSG:32634) : adapté au Cameroun oriental.
#Règle : utilisez WGS84 pour la visualisation, et UTM pour les calculs de distances et de superficies.


# Charger toutes nos couches

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Vérifier le CRS de chaque couche ---

# Vérification rapide de tous les CRS

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Reprojection (transformer le CRS) ---
# Tous doivent être dans le même CRS avant toute opération spatiale !

# Reprojeter en WGS84 (4326) si nécessaire

# Reprojeter en UTM Zone 33N (en mètres) pour les calculs

# Vérification après reprojection

# Calculer la surface des districts (en km²) — nécessite un CRS métrique


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 3.2 EMPRISE SPATIALE ET VISUALISATION RAPIDE
## ========================================================================
# Emprise de chaque couche
# xmin      ymin      xmax      ymax
# Longitude ouest, Latitude sud, Longitude est, Latitude nord

# Visualisation rapide avec plot() de base

# Carte 1 : Districts sanitaires (géométrie uniquement)

# Carte 2 : Superposition districts + grappes DHS


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 3.3 VALIDATION ET CORRECTION DES GÉOMÉTRIES
## ========================================================================
# On travaille ici sur ds_brut -- la version NON preparee, lue en section 2.1.
# lire_ds() applique deja st_make_valid(), donc 'ds' est valide : la lecon
# serait vide sur lui.

# Identifier les géométries invalides

# Correction automatique

# LE MOTEUR GEOMETRIQUE CHANGE LE RESULTAT.
# Avec s2 actif (moteur spherique, defaut de sf), st_make_valid() laissait
# 3 geometries invalides sur 200 : s2 refuse des auto-intersections que
# GEOS accepte. C'est pourquoi ce document desactive s2 des le depart.

# POURQUOI CELA COMPTE.
# Une geometrie invalide ne se voit pas a l'affichage : la carte s'affiche
# normalement. Elle ne se manifeste qu'au premier calcul geometrique, par un
# message enigmatique :
#   "Loop 0 is not valid: Edge 3010 has duplicate vertex with edge 3012"
# C'est pour cette raison que lire_ds() applique st_make_valid() d'office :
# le filtrage spatial (4.2), la zone tampon (4.3) et les jointures (5.x)
# echouent tous sans cette correction.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Détecter les géométries vides ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Statistiques sur les géométries ---
# Superficie des districts (après projection en mètres)


# Périmètre des frontières

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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

# Rappel : un sf est un data.frame, dplyr fonctionne directement

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Statistiques par région (si colonne région dans DS) ---
# Adaptez 'nom_region' selon les colonnes réelles de votre DS.geojson

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Joindre la population aux districts ---

# Aperçu des colonnes pour identifier la clé de jointure

# Densité de population
# (après jointure attributaire — voir MODULE 5)

#Le filtrage et le sous-réglage sont des opérations fondamentales : sélectionner un sous-ensemble d'entités géographiques selon leurs attributs ou leur relation spatiale avec d'autres couches.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 4.1 FILTRAGE PAR ATTRIBUTS
## ========================================================================

# Charger les données

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- MÉTHODE 1 : Opérateur [ comme data.frame ---
# Sélectionner les districts d'une région spécifique
# (Adaptez 'nom_colonne' selon les colonnes réelles de DS.geojson)

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- MÉTHODE 2 : filter() de dplyr (recommandée) ---
# Plus lisible, intégration naturelle avec le pipe %>%

# Plusieurs conditions

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Filtrage des grappes DHS urbaines ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Filtrage des régions GADM par nom ---
# La colonne NAME_1 contient les noms de régions dans GADM


# Visualisation rapide


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 4.2 SOUS-RÉGLAGE SPATIAL (SPATIAL SUBSETTING)
## ========================================================================
#Le sous-réglage spatial sélectionne des entités en fonction de leur relation géographique avec d'autres entités (intersection, appartenance, proximité...).

# --- Exemple 1 : Grappes DHS dans une région administrative ---
# Sélectionner les grappes DHS situées dans la région Centre


## --- Étape 1 : Extraire la région Centre -----------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## --- Étape 2 : S'assurer que les deux couches ont le même CRS --------

# Si FALSE : reprojeter


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## --- Étape 3 : Sous-réglage spatial avec l'opérateur [ ---------------

# Même résultat avec st_filter() — plus explicite

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Exemple 2 : Districts sanitaires dans les régions frontalières ---
# Régions ayant une frontière internationale


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Exemple 3 : Prédicat spatial explicite ---
# st_intersects, st_within, st_contains, st_overlaps, st_touches

# Districts qui INTERSECTENT la région Nord

# Points DHS DANS la région Extrême-Nord

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Buffer de 5 km autour des grappes DHS rurales ---

# Fusionner tous les buffers en un seul polygone

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Grappes DHS à moins de 10 km d'une frontière ---
# Récupérer la frontière nationale du Cameroun

# Calculer la distance entre chaque grappe et la frontière nationale
# st_boundary() extrait le contour (ligne frontière)

# dist_frontiere est une matrice en mètres

# Ajouter la distance minimale comme attribut

# Grappes à moins de 30 km de la frontière

#Les jointures permettent de combiner des informations provenant de sources différentes — une opération quotidienne à l'INS. Nous distinguons la jointure attributaire (sur une clé commune) et la jointure spatiale (sur la localisation).


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 5.1 JOINTURE ATTRIBUTAIRE : POPULATION + LIMITES ADMINISTRATIVES
## ========================================================================
# Combiner donnees de population (CSV) avec geometries (SHP)


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Les deux cles en presence ----------------------------------------------
# GADM ecrit les noms officiels, accentues : "Benoue" s'y lit "Bénoué".
# WorldPop les ecrit sans accents et avec des variantes de liaison.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Tentative naive : jointure sur le nom brut -----------------------------

# left_join ne previent JAMAIS d'un non-appariement : il remplit avec NA.
# Compter les NA apres chaque jointure est le reflexe qui sauve une analyse.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- La solution : normaliser les libelles ----------------------------------
# On retire accents, casse, ponctuation, et les mots de liaison ("et", "de",
# "du", "la", "le") qui varient d'une source a l'autre.

# Verification sur les cas qui echouaient

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Jointure sur la cle normalisee -----------------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Ce que la jointure rend possible ---------------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 5.2 JOINTURE SPATIALE : GRAPPES DHS → DISTRICTS SANITAIRES
## ========================================================================
# JOINTURE SPATIALE
# Associer chaque grappe DHS à son district sanitaire

# Harmoniser les CRS

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- st_join() : jointure spatiale principale ---
# Par défaut : st_intersects (le point est DANS le polygone)

# Vérification
# 'district' est la colonne creee par lire_ds() a partir de 'name'.
# Les grappes sans district tombent hors des polygones : soit en mer, soit
# dans les interstices laisses par le decoupage sanitaire.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Compter le nombre de grappes par district ---

# Ramener ce compte dans la couche districts

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Jointure spatiale inverse ---
# Associer chaque district au pays limitrophe (si frontalier)
# Les districts non-frontaliers auront NA dans NOM_PAYS

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Étape 1 : Charger et nettoyer le fichier ménages DHS ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Étape 2 : Agréger par grappe ---
# Calculer des indicateurs moyens par grappe

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Étape 3 : Joindre avec les coordonnées GPS ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Étape 4 : Jointure spatiale vers les districts sanitaires ---


# Rejoindre avec la géométrie des districts

#Ce module est le point culminant de la journée : produire des cartes professionnelles et informatives des données camerounaises. Nous utilisons ggplot2 (cartes statiques), tmap (cartes thématiques) et mapview (exploration interactive).


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 6.1 CARTE DE BASE AVEC GGPLOT2 : FRONTIÈRES NATIONALES ET RÉGIONALES
## ========================================================================

# Charger toutes les couches nécessaires

# Harmoniser les CRS

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- CARTE 1 : Frontières nationales + pays limitrophes ---

  # Couche 1 : Pays limitrophes (fond gris)

  # Couche 2 : Frontière nationale Cameroun

  # Couche 3 : Régions

  # Labels des régions

  # Labels des pays limitrophes

  # Emprise sur le Cameroun + un peu de contexte


# Sauvegarde


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

## ========================================================================
## 6.2 CARTE THÉMATIQUE : DISTRICTS SANITAIRES COLORÉS PAR RÉGION
## ========================================================================
# Palette de 10 couleurs (une par région)


  # Fond : pays limitrophes

  # Districts sanitaires colorés par région

  # Contour des régions GADM par-dessus

  # Frontière nationale


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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

# Un libelle lisible plutot qu'un code a une lettre


  # Fond pays limitrophes

  # Cameroun en fond

  # Régions

  # Les grappes, en UNE couche : la couleur et la forme sont MAPPEES sur la
  # variable milieu, via aes(). C'est ce qui fait apparaitre une legende.
  # Fixer color = '#C00000' hors de aes() colore les points mais ne cree
  # aucune legende -- et scale_color_manual() n'a alors rien a quoi se
  # raccrocher ("No shared levels found").

  # Frontière nationale


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- Calculer la densite : mesurer exige un CRS metrique --------------------

# On revient en WGS84 pour l'affichage : mesurer en metres, dessiner en degres.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

# --- La carte, en syntaxe tmap 4 -------------------------------------------
# Differences avec tmap 3 : le remplissage est 'fill' (et non 'col'), les
# echelles passent par tm_scale_*() au lieu du couple palette=/style=/n=,
# le titre par tm_title(), et tm_scale_bar() est devenu tm_scalebar().


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J03_corrige.R)
# ......................................................................

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
