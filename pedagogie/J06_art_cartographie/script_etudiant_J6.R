## ============================================================================
## SCRIPT ÉTUDIANT — J6 · Faire parler les cartes : l'art de la visualisation
## Atelier IFORD × GDSG 2026 · Samedi 1er août 2026
## ----------------------------------------------------------------------------
## Ce script reprend la trame de la démonstration du formateur : les commentaires
## et les lectures de données sont fournis, le reste du code est à écrire par vous,
## sous la supervision du formateur. Travaillez depuis la racine du projet
## (ouvrir atelier-r-spatial-iford-2026.Rproj) ; les chemins sont relatifs.
## Solution complète : script_etudiant_J6_corrige.R
## ============================================================================

## ============================================================================
## [PREPARATION ATELIER - GDSG, juillet 2026]
## Ce script s'execute depuis la RACINE du projet RStudio :
##   1. Ouvrir atelier-r-spatial-iford-2026.Rproj (les chemins sont relatifs).
##   2. Donnees : datasets/ (fournies avec ce dossier ; chemins relatifs)
##   3. Les sorties de ce script sont ecrites dans outputs/.
## NB : fichiers references mais PAS ENCORE dans le Drive (voir README donnees) :
##      - datasets/FIES_Cameroun.csv
for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
## ============================================================================

################################################################################
# ATELIER IFORD - DONNÉES SPATIALES, ANALYSE ET MANIPULATION DANS R
# Jour 5 : Visualisation et cartographie
# Script complet
################################################################################
#Author: Marcial TEDA

#INTRODUCTION GÉNÉRALE
#Ce manuel pédagogique constitue le guide complet du Jour 5 de la formation en analyse des données géospatiales avec R. Il s'adresse principalement aux professionnels des Instituts Nationaux de Statistique (INS) et des Instituts de Cartographie du Cameroun et de la région Afrique centrale.

#La visualisation cartographique est l'étape finale qui transforme des données brutes en informations communicables. Une carte bien conçue peut résumer en un coup d'oeil ce que des tableaux de chiffres ne parviennent pas à transmettre. Ce Jour 5 vous apprendra à produire, sous R, des cartes de qualité professionnelle adaptées aux publications officielles, aux bulletins statistiques et aux rapports de l'INS.

#Données utilisées tout au long de ce Jour 5
#- CMGC72FL.csv / CMHR71FL.SAV / CMIR71FL.SAV / CMGE71FL.shp : Enquête démographique et de santé (DHS), Cameroun
#- ecam5.dta : Enquête camerounaise auprès des ménages, 5e édition (2022)
#- gadm41_CMR_shp : Frontières administratives du Cameroun (niveaux 0-3)
#- CMR_population_v1_0_admin_level2.csv / CMR_household_v1_0_admin_level2.csv : Population et ménages par arrondissement
#- Données FIES (FAO) : Insécurité alimentaire au Cameroun
#- DS.geojson : Districts sanitaires du Cameroun
#- Pays_limitrophes_Cmr.shp : Pays voisins du Cameroun
#- Images Sentinel-2 (B08, B11, True Color) : données satellitaires 26 juin 2026

#Objectifs pédagogiques du Jour 5
#À l'issue de cette journée, vous serez capable de :
#1.	Produire des cartes thématiques (choropleth, points, symboles proportionnels) avec ggplot2 et tmap
#2.	Créer des cartes interactives (zoom, popups) avec Leaflet et mapview
#3.	Appliquer les principes fondamentaux de la sémiologie graphique et de la conception cartographique
#4.	Préparer et exporter des cartes prêtes pour insertion dans des rapports officiels
#5.	Calculer et visualiser des indices végétation/humidité à partir d'images Sentinel-2

#SEQUENCE 0 — Préparation de l'environnement de travail

#0.1 Installation des packages
#Exécutez ce bloc une seule fois au début de la formation. Si les packages sont déjà installés, R les ignorera silencieusement.

# ─────────────────────────────────────────────────────────────────────────
# JOUR 5 — VISUALISATION ET CARTOGRAPHIE AVEC R
# Formation géodonnées — INS & Instituts de Cartographie du Cameroun
# ─────────────────────────────────────────────────────────────────────────

# 0.1 INSTALLATION DES PACKAGES NÉCESSAIRES
# Exécuter UNE SEULE FOIS (peut prendre 5-10 minutes selon la connexion)

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Installer uniquement les packages manquants
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#0.2 Chargement des packages et définition des chemins

# 0.2 CHARGEMENT DES PACKAGES ET PARAMÉTRAGE GLOBAL

library(sf)            # Données vectorielles
library(terra)         # Données raster
library(ggplot2)       # Graphiques et cartes ggplot2
library(tmap)          # Cartographie thématique
library(ggspatial)     # Ornements cartographiques ggplot2
library(scales)        # Formatage des axes et légendes
library(viridis)       # Palettes viridis
library(RColorBrewer)  # Palettes ColorBrewer
library(leaflet)       # Cartes interactives
library(mapview)       # Visualisation rapide interactive
library(haven)         # Lecture SPSS/Stata
library(readr)         # Lecture CSV
library(dplyr)         # Manipulation données
library(tidyr)         # Restructuration données
library(cowplot)       # Composition graphiques
library(patchwork)     # Composition ggplot2

# ── Définir le répertoire de travail ──────────────────────────────────
# Adaptez ce chemin à votre machine
# setwd("C:/Formation_Geodonnees_R")   # Windows   # [GDSG] desactive : ouvrir le .Rproj (chemins relatifs racine projet)
# setwd("/home/user/Formation_Geodonnees_R")  # Linux / Mac

# ── Définir les chemins vers les données ──────────────────────────────
# Données DHS
chemin_dhs_csv  <- "datasets/CMGC72FL.csv"
chemin_dhs_sav  <- "datasets/CMHR71FL.SAV"
chemin_dhs_wom  <- "datasets/CMIR71FL.SAV"
chemin_dhs_shp  <- "datasets/CMGE71FL.shp"
# Données ECAM5
chemin_ecam5    <- "datasets/ecam5.dta"
# Données géospatiales
chemin_gadm1    <- "datasets/gadm41_CMR_1.shp"   # Régions
chemin_gadm2    <- "datasets/gadm41_CMR_2.shp"   # Départements
chemin_gadm3    <- "datasets/gadm41_CMR_3.shp"   # Arrondissements
chemin_ds       <- "datasets/DS.geojson"       # Districts sanitaires
chemin_lim      <- "datasets/Pays_limitrophes_Cmr.shp"
# Données population et ménages
chemin_pop      <- "datasets/CMR_population_v1_0_admin_level2.csv"
chemin_men      <- "datasets/CMR_household_v1_0_admin_level2.csv"
# Données FIES
chemin_fies     <- "datasets/FIES_Cameroun.csv"
# Images Sentinel-2
chemin_b08      <- "datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B08_(Raw).tiff"
chemin_b11      <- "datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B11_(Raw).tiff"
chemin_tc       <- "datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_True_color.tiff"
# Répertoire de sortie
dir.create("output/cartes", recursive = TRUE, showWarnings = FALSE)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................
# Sys.setlocale('LC_ALL', 'French_France.UTF-8')  # Windows

# ── Mode tmap par défaut ──────────────────────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#0.3 Chargement et préparation des données
# 0.3 CHARGEMENT ET PRÉPARATION DE TOUTES LES DONNÉES

# ── 1. Frontières administratives du Cameroun ─────────────────────────
rgn <- st_read(chemin_gadm1, quiet = TRUE)  # 10 régions
dep <- st_read(chemin_gadm2, quiet = TRUE)  # 58 départements
arr <- st_read(chemin_gadm3, quiet = TRUE)  # ~360 arrondissements
lim <- st_read(chemin_lim,   quiet = TRUE)  # Pays limitrophes

# ── 2. Districts sanitaires ───────────────────────────────────────────
ds <- st_read(chemin_ds, quiet = TRUE)

# ── 3. Données DHS ────────────────────────────────────────────────────
# Points GPS des clusters d'enquête
dhs_pts <- st_read(chemin_dhs_shp, quiet = TRUE)

# Données ménages DHS (fichier CSV)
dhs_men_raw <- read_csv(chemin_dhs_csv, show_col_types = FALSE)

# Données femmes DHS (fichier SPSS .sav)
dhs_wom_raw <- read_sav(chemin_dhs_wom)

# ── 4. ECAM5 ──────────────────────────────────────────────────────────
ecam5 <- read_dta(chemin_ecam5)

# ── 5. Population et ménages par arrondissement ────────────────────────
pop   <- read_csv(chemin_pop, show_col_types = FALSE)
men   <- read_csv(chemin_men, show_col_types = FALSE)

# ── 6. Données FIES (insécurité alimentaire) ──────────────────────────
# Si le fichier FIES est disponible en CSV
# fies <- read_csv(chemin_fies, show_col_types = FALSE)

# ── 7. Images Sentinel-2 ──────────────────────────────────────────────
b08  <- rast(chemin_b08)  # Bande proche infrarouge (NIR)
b11  <- rast(chemin_b11)  # Bande infrarouge moyen (SWIR)
tc   <- rast(chemin_tc)   # Image couleur réelle (RGB)

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── Reprojeter tout en WGS84 (EPSG:4326) si nécessaire ────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── Vérifications rapides ─────────────────────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#SEQUENCE 1 — Cartes thématiques avec ggplot2

#ggplot2 est la bibliothèque graphique la plus utilisée sous R. Depuis sa version 3.x, elle intègre nativement le support des objets sf grâce à geom_sf(). Cette approche présente l'avantage d'être parfaitement cohérente avec la syntaxe ggplot2 que vous connaissez peut-être déjà pour les graphiques statistiques.

#1.1 Concepts fondamentaux — la grammaire cartographique avec ggplot2

#En ggplot2, une carte est construite par couches successives (layers). Chaque couche ajoute un élément visuel :
#•	ggplot() : initialise le graphique et définit les données
#•	geom_sf() : dessine les géométries (polygones, lignes, points)
#•	aes(fill=..., color=..., size=...) : mappe des variables aux propriétés visuelles
#•	scale_fill_*() : contrôle la palette de couleurs
#•	theme_*() : contrôle l'apparence générale
#•	labs() : titre, sous-titre, légende
#•	annotation_scale() et annotation_north_arrow() : ornements cartographiques

#1.2 Carte choroplèthe — Taux de mortalité infantile par région (DHS)
#Objectif : Visualiser la mortalité infantile au niveau régional à partir des données DHS Cameroun.

# ── SEQUENCE 1.2 : Carte choroplèthe — Mortalité infantile (DHS) ────────

# Étape 1 : Calculer le taux de mortalité infantile par cluster DHS
# Les données DHS contiennent les variables :
# - V005 : facteur de pondération (diviser par 1 000 000)
# - B5  : enfant encore en vie (1=oui, 0=décédé)
# - B7  : âge au décès en mois
# - V101: région de résidence

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Étape 2 : Joindre avec les frontières régionales
# Note : Les codes régions DHS doivent correspondre à ceux du shapefile
# Adapter selon les codes dans vos données réelles
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Étape 3 : Construire la carte choroplèthe avec ggplot2
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Afficher la carte
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Sauvegarder en haute résolution
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#1.3 Carte choroplèthe — Dépenses de consommation des ménages (ECAM5)
# ── SEQUENCE 1.3 : Carte choroplèthe — Consommation ménages (ECAM5) ─────

# ECAM5 contient typiquement les variables suivantes :
# - region    : identifiant de la région
# - milieu    : urbain/rural
# - pcexp     : dépenses de consommation par tête (XAF par an)
# - hhsize    : taille du ménage
# - welfare_index / s00q01, s00q04 : identifiants géographiques

# Calculer la consommation médiane par région
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Jointure avec les polygones régionaux
# La clé de jointure doit correspondre — à adapter selon vos données
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Carte choroplèthe de la consommation
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................


#1.4 Carte à points proportionnels — Clusters DHS
#Les cartes à points proportionnels représentent une troisième variable par la taille des symboles. Elles sont idéales pour visualiser des volumes ou des effectifs.

# ── SEQUENCE 1.4 : Carte à points proportionnels — Clusters DHS ─────────

# Les points GPS des clusters DHS (CMGE71FL.shp) contiennent :
# - DHSCLUST : numéro du cluster
# - URBAN_RURA : U = urbain, R = rural
# - LATNUM / LONGNUM : coordonnées géographiques
# - ALT_GPS : altitude

# Calculer un indicateur synthétique par cluster depuis les données ménages
# Exemple : taux d'utilisation des moustiquaires (V461 ou ML0 dans DHS)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Joindre avec les points géographiques
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Carte avec symboles proportionnels
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#1.5 Cartes en facettes — Comparaison par milieu ou par indicateur
# ── SEQUENCE 1.5 : Cartes en facettes — Comparaison urbain/rural ────────

# Les facettes permettent de produire plusieurs petites cartes côte à côte
# Exemple : taux de vaccination par région, comparaison Urbain vs Rural

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Joindre avec géographie
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Carte avec facettes Urbain / Rural
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#SEQUENCE 2 — Cartographie avancée avec tmap
#tmap (Thematic Maps) est un package R spécialement conçu pour la cartographie thématique. Il offre une syntaxe intuitive similaire à ggplot2 mais optimisée pour les cartes. Son atout majeur : le même code fonctionne en mode statique et en mode interactif, simplement en changeant tmap_mode('plot') en tmap_mode('view').

#2.1 Structure de base de tmap
# ── MODULE 2.1 : Structure fondamentale de tmap ──────────────────────

# La syntaxe tmap s'articule autour de blocs empilés :
#   tm_shape(data)  : définit les données et la géométrie
#   + tm_polygons() : dessine les polygones (avec remplissage + bordure)
#   + tm_borders()  : dessine uniquement les bordures
#   + tm_dots()     : dessine des points
#   + tm_lines()    : dessine des lignes
#   + tm_text()     : ajoute des étiquettes
#   + tm_layout()   : contrôle le titre, légende, fond
#   + tm_compass()  : ajoute une rose des vents
#   + tm_scale_bar(): ajoute une barre d'échelle

# Exemple minimal — régions du Cameroun
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── Basculer entre mode statique et interactif ────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#2.2 Carte choroplèthe avancée — Insécurité alimentaire (FIES/FAO)

# ── MODULE 2.2 : Choroplèthe avancée — Insécurité alimentaire FIES ────

# Les données FIES (Food Insecurity Experience Scale) de la FAO donnent
# la prévalence de l'insécurité alimentaire modérée et sévère par région.

# Structure attendue du fichier FIES :
# region | fies_moderate | fies_severe | annee

# Si fichier CSV disponible :
# fies <- read_csv(chemin_fies)

# Simulons la structure si le CSV n'est pas encore disponible :
# (Remplacer par les vraies données FIES quand disponibles)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Jointure avec le shapefile des régions
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── Carte tmap de l'insécurité alimentaire ────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Afficher
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Sauvegarder
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#2.3 Carte à symboles proportionnels — Population par département

# ── MODULE 2.3 : Symboles proportionnels — Population (CMR_population) ─

# Lire les données de population au niveau 2 (département/arrondissement)
# CMR_population_v1_0_admin_level2.csv contient la population par unité admin

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Agréger au niveau département si nécessaire
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Calculer le centroïde de chaque département pour positionner les symboles
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Carte tmap avec symboles proportionnels
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................


#2.4 Carte multi-couches — Données de santé + Districts sanitaires

# ── MODULE 2.4 : Carte multi-couches — Districts sanitaires + DHS ─────

# Calculer la couverture CPN4 (4 consultations prénatales) par district
# Variable DHS : V023 = strate d'enquête, M14 = nb consultations prénatales

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Joindre avec points GPS
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Carte multi-couches avec tmap
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#SEQUENCE 3 — Cartes interactives avec Leaflet et mapview
#Leaflet est une bibliothèque JavaScript de cartographie interactive, accessible depuis R via le package du même nom. Les cartes Leaflet permettent le zoom, le panoramique, les info-bulles (popups) et le changement de fond de carte. Elles sont idéales pour les portails web, les dashboards Shiny et les rapports HTML.

#Quand utiliser les cartes interactives ?
#- Pour un rapport HTML ou un tableau de bord web
#- Pour l'exploration des données en interne (inspecteur de données)
#- Quand les utilisateurs doivent zoomer sur une zone précise
#- Pour des présentations interactives lors de formations ou réunions
#ATTENTION : Les cartes interactives ne peuvent pas être insérées dans des PDF/Word. Elles doivent être sauvegardées en HTML ou en image capturée.

#3.1 Carte Leaflet de base — Districts sanitaires interactifs

# ── MODULE 3.1 : Carte Leaflet de base ───────────────────────────────

library(leaflet)
library(leaflet.extras)

# Préparer les données avec une variable à visualiser
# Ici on ajoute une variable fictive de couverture si non disponible
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Palette de couleurs pour le remplissage interactif
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Construire la carte Leaflet
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Afficher dans RStudio
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Sauvegarder en HTML autonome
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#3.2 Carte Leaflet choroplèthe — Population avec gradient de couleurs

# ── MODULE 3.2 : Choroplèthe Leaflet — Population par département ─────

# Joindre population avec département
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Palette continue (NumericInput -> couleur)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Popup HTML détaillé
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#3.3 Visualisation rapide avec mapview

# ── MODULE 3.3 : Exploration rapide avec mapview ──────────────────────

# mapview génère instantanément une carte interactive d'un objet sf
# C'est l'outil idéal pour EXPLORER les données avant de produire une carte

# Vue rapide des régions
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Vue rapide des points DHS colorés par milieu
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Superposition de plusieurs couches mapview (+)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Sauvegarder mapview en HTML
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................
# Note : mapshot() requiert le package webshot ou webshot2

#SEQUENCE 4 — Principes de conception cartographique & Images Sentinel-2
#4.1 Les principes fondamentaux de la sémiologie graphique
#La sémiologie graphique, formalisée par Jacques Bertin en 1967, définit les variables visuelles qui permettent de transmettre de l'information. Une carte réussie respecte ces principes pour que l'information soit immédiatement perceptible.

#Variable visuelle	Usage recommandé
#Couleur (teinte)	Distinguer des catégories qualitatives (régions, types de milieu)
#Valeur (clarté/obscurité)	Représenter une quantité ordonnée ou un taux
#Taille	Représenter des quantités absolues (population, effectifs)
#Forme	Distinguer des types de points (hôpitaux, écoles, marchés)
#Grain/texture	Rarement utilisé sur les cartes numériques
#Orientation	Indiquer une direction (flèches de migration, vents)

#4.1.1 Règles d'or pour des cartes professionnelles
#•	Règle 1 : Une carte = un message. Ne jamais surcharger une carte de variables.
#•	Règle 2 : Titre obligatoire, clair et informatif (quoi, où, quand, pour qui).
#•	Règle 3 : Source et date toujours mentionnées en bas de carte.
#•	Règle 4 : Légende complète — chaque élément graphique doit y figurer.
#•	Règle 5 : Rose des vents et barre d'échelle sur toute carte de localisation.
#•	Règle 6 : Le nord est généralement en haut, sauf raison cartographique valide.
#•	Règle 7 : Choisir les palettes selon le type de données : séquentielle, divergente ou qualitative.
#•	Règle 8 : Les cartes destinées à l'impression doivent être exportées à 300 dpi minimum.
#•	Règle 9 : Tester la lisibilité en noir et blanc et pour les daltoniens.

#4.1.2 Choix des palettes de couleurs

# ── SEQUENCE 4.1.2 : Palettes de couleurs recommandées ─────────────────

# 3 types de palettes selon le type de variable :

# 1. PALETTES SÉQUENTIELLES (une variable quantitative : taux, indice)
#    Usage : données qui vont de bas à élevé, ex. taux de mortalité
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# viridis : perceptivement uniforme, daltonien-friendly
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# 2. PALETTES DIVERGENTES (variable avec centre neutre : écart à la moyenne)
#    Usage : données qui ont un point zéro central (excédent/déficit, différence)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# 3. PALETTES QUALITATIVES (variable catégorielle)
#    Usage : régions, milieu, type d'établissement
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# PALETTES PERSONNALISÉES CAMEROUN
# Couleurs officielles du drapeau camerounais
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Afficher les palettes disponibles dans RColorBrewer
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#4.2 Traitement des images Sentinel-2
#Les images Sentinel-2 sont des données satellitaires à résolution de 10 à 60 mètres, fournies gratuitement par l'Agence Spatiale Européenne (ESA). Nous disposons de trois bandes pour le Cameroun en date du 26 juin 2026 :
#•	B08 (NIR — Proche Infrarouge) : détection de la végétation et de l'eau
#•	B11 (SWIR — Infrarouge à ondes courtes) : humidité du sol, zones brûlées
#•	True Color (RGB) : image couleur naturelle pour la visualisation

##4.2.1 Affichage de l'image couleur réelle

# ── SEQUENCE 4.2.1 : Image Sentinel-2 — Couleur réelle ─────────────────

library(terra)

# Lire l'image True Color (RGB)
tc <- rast(chemin_tc)

# Vérifier les informations de l'image
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Reprojeter en WGS84 si nécessaire
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Afficher l'image True Color
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Superposer les frontières administratives
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#4.2.2 Calcul du NDVI — Indice de végétation normalisé

# ── MODULE 4.2.2 : Calcul du NDVI (Normalized Difference Vegetation Index)

# NDVI = (NIR - Rouge) / (NIR + Rouge)
# Ici nous n'avons que B08 (NIR) et B11 (SWIR)
# Calculons plutôt le NDMI (Normalized Difference Moisture Index)
# NDMI = (NIR - SWIR) / (NIR + SWIR)
# NDMI > 0 : végétation bien hydratée, < 0 : stress hydrique/sol nu

# Lire les bandes
nir  <- rast(chemin_b08)   # Bande 8 : proche infrarouge
swir <- rast(chemin_b11)   # Bande 11 : infrarouge moyen

# Rééchantillonner pour avoir la même résolution si nécessaire
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Reprojeter en WGS84
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Calcul du NDMI
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Afficher le NDMI
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Sauvegarder le raster NDMI
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Statistiques du NDMI
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#4.2.3 Carte NDMI intégrée avec ggplot2

# ── SEQUENCE 4.2.3 : Intégration NDMI dans une carte ggplot2 ───────────

library(stars)    # Pour convertir terra en stars (compatible ggplot2)

# Convertir le raster terra en objet stars pour ggplot2
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Carte NDMI avec ggplot2
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#SEQUENCE 5 — Production de cartes pour rapports officiels
#La production d'une carte pour un rapport officiel (bulletin statistique, rapport annuel INS, publication FAO, etc.) exige une attention particulière à la mise en page, à la résolution, au format d'export et à la composition visuelle. Ce module vous apprend à assembler plusieurs cartes en un seul panneau et à exporter dans les formats requis.

#5.1 Composition multi-cartes avec cowplot et patchwork

# ── SEQUENCE 5.1 : Composition multi-cartes — cowplot ──────────────────

library(cowplot)
library(patchwork)

# Supposons que vous ayez déjà créé :
# - carte_mortalite  : taux mortalité infantile
# - carte_conso      : consommation ECAM5
# - carte_fies       : insécurité alimentaire (tmap -> convertir en ggplot)
# - carte_ndmi       : NDMI Sentinel-2

# ── Méthode patchwork (pour objets ggplot2 uniquement) ────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── Méthode cowplot (plus fine, permet texte libre et images) ─────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Ajouter un titre commun
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#5.2 Exportation dans tous les formats
# ── MODULE 5.2 : Exportation dans tous les formats professionnels ─────

# GGPLOT2 — Formats raster haute résolution
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# GGPLOT2 — Format vectoriel (pour impression sans perte de qualité)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Conseil SVG : Format idéal pour les publications web, éditable sous Inkscape

# TMAP — Tous les formats
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# TMAP — Mode interactif HTML
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# RASTER TERRA
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# PNG depuis terra
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#5.3 Carte institutionnelle complète pour rapport officiel

# ── SEQUENCE 5.3 : Carte institutionnelle INS — Toutes les règles ────────

# Cette carte respecte toutes les normes cartographiques professionnelles :
# 1. Titre informatif (quoi / où / quand)
# 2. Source et date
# 3. Légende complète
# 4. Rose des vents
# 5. Barre d'échelle
# 6. Système de projection mentionné
# 7. Bordure nette
# 8. Palette adaptée (séquentielle, daltonien-friendly)
# 9. Fond contextuel (pays limitrophes, mer)
# 10. Export à 300 dpi pour impression

# Calculer la densité de population par km² au niveau département
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# Exporter à 300 dpi pour rapport officiel
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

#6.1 Exercice 1 — Carte de la prévalence du paludisme (DHS)

#Consigne de l'exercice 1 (45 min)
#À partir des données DHS (CMIR71FL.SAV), produisez une carte choroplèthe au niveau régional montrant :
#a) Le taux de prévalence du paludisme chez les enfants de moins de 5 ans (variable ML0 ou HC57)
#b) Le taux d'utilisation des moustiquaires imprégnées (variable ML101)
#Utilisez tmap avec une palette divergente et exportez la carte en PNG 300 dpi.
#La carte doit inclure : titre, source, échelle, rose des vents, légende.

#6.2 Exercice 2 — Carte interactive des ménages par arrondissement
#Consigne de l'exercice 2 (30 min)
#À partir de CMR_household_v1_0_admin_level2.csv, créez une carte Leaflet interactive montrant le nombre de ménages par arrondissement.
#Exigences : fond CartoDB.Positron, palette YlOrRd, popup avec le nom et le nombre de ménages, légende, barre de recherche.
#Exportez la carte en HTML autonome.

#6.3 Exercice 3 — Carte institutionnelle complète (évaluation)
#Consigne de l'exercice 3 — Évaluation finale (60 min)
#Produisez une carte institutionnelle professionnelle sur le thème de votre choix :
#- Thème 1 : Indice de richesse des ménages (DHS — variable V190)
#- Thème 2 : Taux de chômage ou d'emploi informel (ECAM5)
#- Thème 3 : Densité des districts sanitaires par région
#La carte DOIT respecter toutes les normes professionnelles : titre, source, date, rose des vents, échelle, légende complète, système de coordonnées, export 300 dpi PNG + PDF.
#Durée : 60 minutes. Travail individuel ou en binôme.

#SQUENCE 7 — Récapitulatif et bonnes pratiques
#7.1 Checklist d'une carte professionnelle

#Critère	Standard professionnel
#Titre informatif	Répond aux questions Quoi / Où / Quand
#Légende complète	Tous les éléments visuels y figurent
#Source(s)	Nom de la base, institution, année
#Date de production	Mois et année de création de la carte
#Rose des vents	Présente sur toute carte de référence
#Barre d'échelle	Obligatoire pour les cartes de localisation
#Système de projection	Mentionné dans le sous-titre ou caption
#Palette appropriée	Séquentielle / divergente / qualitative
#Résolution 300 dpi	Pour toute impression professionnelle
#Format vectoriel PDF/SVG	Pour modifications ultérieures
#Test daltonisme	Utiliser palette viridis ou colorblind-safe
#Test n&b	La carte reste lisible en noir et blanc

#7.2 Récapitulatif des fonctions clés

# ── RÉCAPITULATIF DES FONCTIONS ESSENTIELLES ─────────────────────────

# ── ggplot2 ──────────────────────────────────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── tmap ─────────────────────────────────────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── Leaflet ──────────────────────────────────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── terra (Sentinel-2) ───────────────────────────────────────────────
rast(chemin)                         # Lire un raster
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................

# ── Composition ──────────────────────────────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J6_corrige.R)
# ..........................................................................
