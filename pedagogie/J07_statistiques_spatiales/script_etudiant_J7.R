## ============================================================================
## SCRIPT ÉTUDIANT — J7 · Le hasard a-t-il une géographie ? Statistiques spatiales
## Atelier IFORD × GDSG 2026 · Lundi 3 août 2026
## ----------------------------------------------------------------------------
## Ce script reprend la trame de la démonstration du formateur : les commentaires
## et les lectures de données sont fournis, le reste du code est à écrire par vous,
## sous la supervision du formateur. Travaillez depuis la racine du projet
## (ouvrir atelier-r-spatial-iford-2026.Rproj) ; les chemins sont relatifs.
## Solution complète : script_etudiant_J7_corrige.R
## ============================================================================

## ============================================================================
## [PREPARATION ATELIER - GDSG, juillet 2026]
## Ce script s'execute depuis la RACINE du projet RStudio :
##   1. Ouvrir atelier-r-spatial-iford-2026.Rproj (les chemins sont relatifs).
##   2. Donnees : datasets/ (fournies avec ce dossier ; chemins relatifs)
##   3. Les sorties de ce script sont ecrites dans outputs/.
## NB : fichiers references mais PAS ENCORE dans le Drive (voir README donnees) :
##      - datasets/FIES_Cameroun.csv
##      - datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B03_(Raw).tiff
##      - datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B04_(Raw).tiff
for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
## ============================================================================

################################################################################
# ATELIER IFORD - DONNÉES SPATIALES, ANALYSE ET MANIPULATION DANS R
# Jour 6 : Statistiques spatiales et analyse - Motifs ponctuels, KDE, Moran, Hotspots
# ============================================================
# Formation en Analyse des Données Géospatiales avec R
# Destiné aux 
# R version 4.4
# ============================================================

# Script complet 
################################################################################
#Author: Marcial TEDA
#OBJECTIFS ET PLAN DU JOUR 6
#Cette journée de formation constitue une immersion complète dans les statistiques spatiales appliquées. Vous travaillerez exclusivement avec des données réelles du Cameroun, en combinant des données d'enquêtes ménages (DHS, ECAM), des données de population (WorldPop), des données satellitaires (Sentinel-2) et des données administratives.

#Objectifs pédagogiques
#•	Comprendre les fondements théoriques des processus ponctuels spatiaux et savoir tester la randomité spatiale
#•	Calculer et interpréter l'autocorrélation spatiale globale (Moran's I) et locale (LISA)
#•	Produire des surfaces de densité par estimation de noyau (KDE) et en choisir la largeur de bande optimale
#•	Identifier et cartographier des points chauds (hot spots) avec les statistiques Gi* et LISA
#•	Analyser la répartition spatiale des infrastructures de santé et des ménages avec les données DHS et ECAM
#•	Intégrer des données satellitaires Sentinel-2 pour enrichir l'analyse géospatiale


#SECTION 0 : INSTALLATION ET CONFIGURATION
#0.1 Packages requis pour le Jour 6
#Le Jour 6 mobilise une large palette de packages spécialisés en statistiques spatiales. Voici les principaux :

#Package	Version min.	Usage principal
#sf	1.0+	Lecture, manipulation, écriture de données vectorielles (geojson, shp)
#terra	1.7+	Données raster (Sentinel-2), calcul NDVI, masquage
#spdep	1.3+	Matrices de poids spatiaux, Moran's I, LISA, Gi*
#spatstat	3.0+	Processus ponctuels, test CSR, fonctions G, K, L
#tmap	3.3+	Cartographie thématique (statique et interactive)
#ggplot2	3.4+	Graphiques statistiques (diagramme de Moran, etc.)
#haven	2.5+	Lecture fichiers .sav (SPSS) et .dta (Stata) DHS/ECAM
#dplyr	1.1+	Manipulation et agrégation des données tabulaires
#KernSmooth	2.23+	Estimation noyau 2D classique
#classInt	0.4+	Discrétisation des variables (Jenks, quantiles, etc.)


# ---- 0. INSTALLATION ET CHARGEMENT DES PACKAGES ----------

# Installer les packages si non disponibles
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Chargement des packages
library(sf)          # Données vecteur (Simple Features)
library(terra)       # Données raster
library(sp)          # Classes spatiales legacy
library(spdep)       # Dépendance spatiale, Moran's I
library(spatstat)    # Analyse des processus ponctuels
library(ggplot2)     # Visualisation
library(tmap)        # Cartographie thématique
library(dplyr)       # Manipulation de données
library(readr)       # Lecture CSV
library(haven)       # Lecture .sav, .dta
library(KernSmooth)  # Estimation densité noyau
library(SpatialKDE)  # KDE spatialisée sur raster
library(RColorBrewer)# Palettes de couleurs
library(viridis)     # Palettes perceptuelles
library(classInt)    # Classes de discrétisation

# Définir le répertoire de travail
# setwd("C:/Formation_SIG_R/Jour6")  # Adapter selon votre machine   # [GDSG] desactive : ouvrir le .Rproj (chemins relatifs racine projet)

# Options globales
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

#SECTION 1 : CHARGEMENT ET PRÉPARATION DES DONNÉES
#Présentation du corpus de données
#Ce module utilise un ensemble riche de données réelles couvrant le Cameroun. Chaque source apporte une dimension analytique complémentaire :

# ============================================================
# SECTION 1 : CHARGEMENT ET PRÉPARATION DES DONNÉES
# ============================================================

# ---- 1.1 Données géographiques de base du Cameroun ---------

# Districts sanitaires (polygones)
ds_cmr <- st_read("datasets/DS.geojson")
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Pays limitrophes
pays_lim <- st_read("datasets/Pays_limitrophes_Cmr.shp")

# Reprojeter en WGS84 si nécessaire
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 1.2 Données DHS : Grappes ménages (points) -----------

# Fichier géospatial DHS (localisation des grappes)
dhs_geo <- st_read("datasets/CMGE71FL.shp")
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Fichier ménages DHS
dhs_hr <- read.csv("datasets/CMGC72FL.csv")

# Fichier femmes DHS (.sav)
dhs_ir <- haven::read_sav("datasets/CMHR71FL.SAV")

# Fichier hommes DHS (.sav)
dhs_mr <- haven::read_sav("datasets/CMIR71FL.SAV")

# Enquête ménage (données ECAM)
ecam <- haven::read_dta("datasets/ecam5.dta")

# ---- 1.3 Données de population et ménages admin ----------

pop_admin2 <- read.csv("datasets/CMR_population_v1_0_admin_level2.csv")
hh_admin2  <- read.csv("datasets/CMR_household_v1_0_admin_level2.csv")

# ---- 1.4 Données FIES (FAO) - Insécurité alimentaire -----
# Note : adapter le nom exact du fichier FIES disponible
fies_cmr <- read.csv("datasets/FIES_Cameroun.csv")

# ---- 1.5 Données Sentinel-2 (raster) ----------------------

# Bande verte (B03)
b03 <- rast("datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B03_(Raw).tiff")
# Bande rouge (B04)
b04 <- rast("datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B04_(Raw).tiff")
# Bande PIR (B08)
b08 <- rast("datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B08_(Raw).tiff")
# Bande SWIR (B11)
b11 <- rast("datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B11_(Raw).tiff")
# Composition colorée vraie
true_color <- rast("datasets/2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_True_color.tiff")

# Afficher les métadonnées raster
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ============================================================
# SECTION 2 : PRÉPARATION DES DONNÉES PONCTUELLES DHS
# ============================================================

# ---- 2.1 Vérification et nettoyage des grappes DHS ---------

# Inspecter les colonnes disponibles
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Filtrer uniquement les coordonnées valides (lat/lon non nulles)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 2.2 Jointure attributaire avec données ménages --------

# Préparer un indicateur de santé par grappe
# Exemple : taux de prévalence de la malnutrition (variable hv205)
# Adapter les noms de variables selon le dictionnaire DHS

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 2.3 Carte exploratoire des grappes DHS ----------------

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................


#SECTION 2 : ANALYSE DES MOTIFS PONCTUELS
#Fondements théoriques
#L'analyse des motifs ponctuels (Point Pattern Analysis) est une branche de la statistique spatiale qui s'intéresse à la distribution géographique d'événements discrets dans l'espace. Elle cherche à répondre à la question : la distribution observée des points est-elle le fruit du hasard, ou révèle-t-elle une structure spatiale (agrégation, régularité) ?

#Hypothèse nulle : Complète Aléatoire Spatiale (CSR)
#Un processus de Poisson Homogène (HPP) génère des points de manière :
#  1) Indépendante : la présence d'un point n'influence pas les autres
#  2) Homogène : intensité constante dans toute la zone
#Si les données rejettent la CSR, on parle de :
#  - Agrégation (clustering) : les points se regroupent - fréquent en santé publique
#  - Régularité (over-dispersion) : les points s'évitent - fréquent pour les puits


# ============================================================
# SECTION 3 : ANALYSE DES MOTIFS PONCTUELS (POINT PATTERNS)
# ============================================================

# THÉORIE : Un processus ponctuel spatial est un mécanisme
# stochastique qui génère un ensemble de points dans l'espace.
# On cherche à tester si les points sont :
#  - Aléatoires (CSR : Complete Spatial Randomness)
#  - Agrégés (clusters)
#  - Réguliers (dispersés)

# ---- 3.1 Création d'un objet ppp (planar point pattern) ----

# Extraire les coordonnées
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Définir la fenêtre d'observation = frontière du Cameroun
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Créer l'objet ppp
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Visualisation brute
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 3.2 Test de complète aléatoire spatiale (CSR) ---------

# Test quadrat : divise la zone en cellules, compare les
# fréquences observées vs attendues sous HPP (Homogeneous Poisson)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................
# Interprétation : p < 0.05 => rejet de la CSR

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 3.3 Statistique G (plus proches voisins) --------------

# G(r) = P(distance au plus proche voisin <= r)
# Si G(r) > G_CSR(r) => agrégation
# Si G(r) < G_CSR(r) => régularité

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 3.4 Statistique K de Ripley (multi-échelle) -----------

# K(r) = intensité^-1 * E[nb points dans cercle rayon r]
# L(r) = sqrt(K(r)/pi) - r   (transformation stabilisante)
# Si L(r) > 0 => agrégation à l'échelle r

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 3.5 Enveloppes de simulation (test Monte-Carlo) -------

# Comparer l'observé à 99 simulations sous CSR
# ATTENTION : long à calculer (réduire nsim si nécessaire)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................
# Si la courbe noire sort de l'enveloppe grise => pas CSR

#SECTION 3 : ESTIMATION DE LA DENSITÉ DE NOYAU (KDE)
#Théorie de la KDE
#L'estimation par noyau (Kernel Density Estimation) transforme un nuage de points discrets en une surface continue représentant l'intensité ou la densité du phénomène. Chaque point contribue à la densité locale selon une fonction noyau, généralement gaussienne, centrée sur ce point.

#Choix de la largeur de bande (bandwidth h)
#La largeur de bande h est le paramètre critique de la KDE :
#  - h trop petit  : surface très irrégulière (surapprentissage), suit chaque point
#  - h trop grand  : surface trop lisse (sous-apprentissage), perd les détails locaux
#Méthodes automatiques disponibles dans R :
#  bw.scott()    : règle de Scott (rapide, bonne pour distributions normales)
#  bw.nrd()      : règle de Silverman (similaire à Scott)
#  bw.diggle()   : validation croisée leave-one-out (plus précise, plus lente)
#  bw.ppl()      : pseudo-vraisemblance (bon compromis vitesse/précision)
#Recommandation : tester 3-4 valeurs et comparer visuellement

# ============================================================
# SECTION 4 : ESTIMATION DE LA DENSITÉ DE NOYAU (KDE)
# ============================================================

# THÉORIE : La KDE estime la densité de probabilité d'une
# variable spatiale. Elle 'lisse' les points ponctuels pour
# créer une surface continue.
# Formule : f(x) = (1/nh) * SUM K((x - xi)/h)
#   n = nb de points, h = bandwidth (fenêtre de lissage)
#   K = fonction noyau (souvent gaussienne)

# ---- 4.1 KDE avec spatstat (objets ppp) --------------------

# Largeur de bande automatique (méthode de Scott)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Largeur de bande par validation croisée
# (plus précise mais plus lente)
# bw_cv <- bw.diggle(ppp_dhs)  # décommenter si nécessaire

# Calcul de la densité
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Visualisation
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Tester plusieurs bandwidth
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 4.2 KDE avec données Sentinel-2 comme fond -----------

# Convertir kde en raster terra pour superposer Sentinel-2
kde_raster <- rast(kde_dhs)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Affichage combiné
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 4.3 KDE par milieu urbain/rural ---------------------

# Séparer urbain et rural
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

#KDE et données Sentinel-2 : intégration raster
#La combinaison KDE + Sentinel-2 permet de contextualiser les densités de population :
#  - Zones de forte densité KDE sur fond NDVI faible => urbanisation probable
#  - Zones de forte densité KDE sur fond NDVI fort => peuplement en forêt
#  - NDWI élevé + forte densité => risque sanitaire (accès eau, assainissement)
#Fonctions utiles : project(), crop(), mask(), plotRGB() du package terra

#SECTION 4 : AUTOCORRÉLATION SPATIALE - MORAN'S I
#Fondements de l'autocorrélation spatiale
#La Première loi de Tobler en géographie stipule : 'tout est lié à tout, mais les choses proches sont plus liées que les choses éloignées'. L'autocorrélation spatiale mesure formellement cette tendance des valeurs similaires à se regrouper dans l'espace.

#Matrice de poids spatiaux : le coeur de l'analyse
#Avant tout calcul d'autocorrélation, il faut définir qui est le 'voisin' de qui. Cette définition de voisinage est encodée dans la matrice de poids spatiaux W.

#Type de voisinage	Fonction R	Quand l'utiliser ?
#Contiguïté Reine (Queen)	poly2nb(..., queen=TRUE)	Polygones qui partagent un côté OU un sommet (recommandé par défaut)
#Contiguïté Tour (Rook)	poly2nb(..., queen=FALSE)	Polygones qui partagent uniquement un côté (plus strict)
#K plus proches voisins	knn2nb(knearneigh(...))	Données ponctuelles ou polygones irréguliers (garantit des voisins)
#Seuil de distance	dnearneigh(...)	Quand la distance a une signification physique (ex: 50 km de rayon)

#Interprétation du Moran's I
#Valeur de I	Signification	Exemple concret
#I proche de +1	Forte autocorrélation positive	Les zones riches entourent des zones riches (ségrégation)
#I proche de 0	Distribution aléatoire	Pas de structure spatiale détectable
#I proche de -1	Forte autocorrélation négative	Alternance régulière haute/basse valeur (rare en pratique)
#I attendu sous H0	E(I) = -1/(n-1)	Pour n=100 unités, E(I) = -0.010, proche de 0

# ============================================================
# SECTION 5 : AUTOCORRÉLATION SPATIALE - MORAN'S I
# ============================================================

# THÉORIE : L'autocorrélation spatiale mesure dans quelle
# mesure les valeurs similaires (élevées ou faibles) sont
# regroupées dans l'espace.
# Moran's I :
#   I > 0 => autocorrélation positive (clusters de valeurs similaires)
#   I < 0 => autocorrélation négative (dispersion en échiquier)
#   I ≈ 0 => distribution spatiale aléatoire
#
# Formule : I = (n/S0) * (sum_ij w_ij*(xi-xbar)*(xj-xbar))
#               / sum_i (xi-xbar)^2

# ---- 5.1 Agréger les données DHS par district sanitaire ----

# Jointure spatiale : attribuer chaque grappe à son district
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Calculer un indicateur moyen par district
# (adapter le nom du district selon le fichier DS.geojson)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Indicateurs par district
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Jointure avec couche ds_cmr
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Remplacer NA par la moyenne (imputation simple)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 5.2 Construction de la matrice de poids spatiaux ------

# MÉTHODE 1 : Contiguïté (voisins qui partagent une frontière)
# Style 'W' = ligne-standardisée (somme = 1)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Visualiser les liens de contiguïté
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# MÉTHODE 2 : K plus proches voisins (k=4)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 5.3 Moran's I Global ---------------------------------

# Test pour le taux d'accès à l'eau potable
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................
# Interprétation : si p < 0.05 et I > 0 => clustering spatial

# Test pour le taux d'électrification
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 5.4 Diagramme de Moran (Moran Plot) ------------------

# Standardiser la variable
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Calculer le lag spatial (moyenne des voisins)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Créer le dataframe pour ggplot
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................
 
#SECTION 5 : STATISTIQUES LOCALES (LISA)
#Du global au local : les indicateurs LISA
#Le Moran's I global résume l'autocorrélation en un seul chiffre pour tout le territoire. Les indicateurs LISA (Local Indicators of Spatial Association, Anselin 1995) décomposent cette mesure pour identifier précisément quels districts contribuent positivement ou négativement à l'autocorrélation globale.

#Les quatre quadrants du diagramme de Moran
#HH (Haut-Haut) : valeur élevée entourée de valeurs élevées => POINT CHAUD
 #  Exemple : district avec bon accès à l'eau entouré de districts similaires

#LL (Bas-Bas) : valeur faible entourée de valeurs faibles => POINT FROID
#   Exemple : cluster de districts avec faible accès aux services

#HL (Haut-Bas) : valeur élevée entourée de valeurs faibles => OUTLIER POSITIF
 #  Exemple : ville (chef-lieu) bien équipée dans une région peu développée

#LH (Bas-Haut) : valeur faible entourée de valeurs élevées => OUTLIER NÉGATIF
 #  Exemple : enclave défavorisée dans une zone globalement bien équipée

# ============================================================
# SECTION 6 : LISA - STATISTIQUES LOCALES DE MORAN
# ============================================================

# THÉORIE : Les indicateurs LISA (Local Indicators of Spatial
# Association) décomposent le Moran's I global en contributions
# locales pour détecter des CLUSTERS et OUTLIERS spatiaux.
# Quadrants LISA :
#   HH = Haut-Haut (cluster de valeurs élevées = point chaud)
#   LL = Bas-Bas   (cluster de valeurs faibles)
#   HL = Haut entouré de bas (outlier spatial +)
#   LH = Bas entouré de haut (outlier spatial -)

# ---- 6.1 Calcul des statistiques locales de Moran ---------

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Attacher les résultats au sf
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Seuil de significativité
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Assigner les quadrants
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 6.2 Carte LISA (Points chauds) -----------------------

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

#SECTION 6 : CARTOGRAPHIE DES POINTS CHAUDS
##Méthodes de détection des points chauds
#La cartographie des points chauds (hot spot mapping) est devenue un outil central en santé publique, en planification du développement et en analyse de la sécurité alimentaire. Elle permet d'identifier rapidement les zones qui nécessitent une intervention prioritaire.

#Méthode	Package R	Avantages / Limites
#LISA HH (Moran local)	spdep::localmoran()	Testée statistiquement, décompose spatial / non-spatial. Sensible au découpage administratif.
#Getis-Ord Gi*	spdep::localG()	Détecte les clusters de valeurs élevées. Z-score directement interprétable. Très utilisé en SIG.
#KDE seuillé (percentile)	spatstat / terra	Flexible, visuel, indépendant du découpage. Sensible au bandwidth choisi.
#SaTScan (local)	SpatialEpi::kulldorff()	Détecte des clusters circulaires optimaux. Très utilisé en épidémiologie spatiale.

#Statistique de Getis-Ord Gi*
#La statistique Gi* mesure, pour chaque unité spatiale, si les valeurs de cette unité et de ses voisines sont significativement élevées (hot spot) ou faibles (cold spot) par rapport à la moyenne globale.
#Interprétation du z-score Gi*
#z-score > +2.58  => Hot spot statistiquement significatif à 99% (p < 0.01)
#z-score > +1.96  => Hot spot significatif à 95% (p < 0.05)
#z-score > +1.65  => Hot spot significatif à 90% (p < 0.10)
#z-score entre -1.65 et +1.65 => Non significatif (distribution aléatoire locale)
#z-score < -1.65  => Cold spot significatif à 90%
#z-score < -1.96  => Cold spot significatif à 95%
#z-score < -2.58  => Cold spot significatif à 99%
# ============================================================
# SECTION 7 : CARTOGRAPHIE DES POINTS CHAUDS
# ============================================================

# THÉORIE : Un 'point chaud' (hot spot) est une zone où
# la concentration d'un phénomène est significativement
# plus élevée que partout ailleurs.
# Méthodes :
#  - LISA HH (section précédente)
#  - Getis-Ord Gi* (alternative populaire)
#  - KDE avec seuils de percentile

# ---- 7.1 Statistique de Getis-Ord Gi* ---------------------

# Gi* identifie les clusters de valeurs élevées (hot spots)
# et faibles (cold spots) avec un z-score
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Classer selon z-score (z > 1.96 => p<0.05, z > 2.58 => p<0.01)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Carte Gi*
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 7.2 Comparaison LISA vs Gi* --------------------------

# Tableau de concordance
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 7.3 KDE comme surface de points chauds ---------------

# Discrétiser la KDE en classes percentiles
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................


#SECTION 7 : PRATIQUE - RÉPARTITION SPATIALE DES ÉTABLISSEMENTS DE SANTÉ
#Contexte de l'exercice pratique
#Cet exercice pratique intègre l'ensemble des compétences acquises au cours de la journée. Vous allez analyser la répartition spatiale des services de santé au Cameroun en combinant les données DHS, l'enquête ECAM 2022, les données Sentinel-2 et les statistiques spatiales.

#Objectif de l'exercice pratique
#Question de recherche : 'Existe-t-il des inégalités spatiales dans l'accès aux services
#de santé au Cameroun, et si oui, où se situent les zones prioritaires d'intervention ?'

#Indicateurs à analyser :
#  1) Accès à l'eau potable (proxy santé environnementale) - données DHS
#  2) Couverture végétale NDVI (contexte environnemental) - Sentinel-2 2026
#  3) Densité des ménages (distribution spatiale) - KDE sur grappes DHS
#  4) Inégalités spatiales - LISA et Gi* par district sanitaire

# ============================================================
# SECTION 8 : PRATIQUE - RÉPARTITION SPATIALE
# DES ÉTABLISSEMENTS DE SANTÉ ET DONNÉES ECAM
# ============================================================

# ---- 8.1 Extraction des établissements de santé depuis DHS --

# Les grappes DHS sont le proxy des communautés
# Construire un score composite de santé communautaire
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 8.2 Intégration données ECAM 2022 ---------------------

# Explorer la structure ECAM
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Vérifier si une variable région est disponible
# (adapter selon la codification ECAM 2022)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 8.3 Carte composite : ECAM + districts sanitaires -----

# Indicateurs de population (WorldPop)
# Agréger pop_admin2 par grande région si possible
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 8.4 Analyse Sentinel-2 : Indice NDVI ------------------

# NDVI = (B08 - B04) / (B08 + B04)
# Proche de 1 => végétation dense
# Proche de 0 => sol nu, zones urbaines
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Superposer les districts sanitaires
ndvi_crop <- crop(ndvi, vect(ds_cmr))
ndvi_mask <- mask(ndvi_crop, vect(ds_cmr))

# Statistiques NDVI par district sanitaire
ndvi_stats_ds <- extract(ndvi_mask,
                          vect(ds_indicateurs),
                          fun = mean, na.rm = TRUE,
                          bind = TRUE)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Carte NDVI moyen par district
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................


# ============================================================
# SECTION 9 : CARTE DE SYNTHÈSE INTERACTIVE
# ============================================================

# ---- 9.1 Carte statique multi-indicateurs ------------------

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Sauvegarder la carte
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 9.2 Carte interactive Leaflet -------------------------

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Revenir au mode statique
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ---- 9.3 Export complet des résultats ----------------------

# Sauvegarder le shapefile enrichi
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# Tableau récapitulatif
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J7_corrige.R)
# ..........................................................................

#Formats d'export recommandés
#PNG 300 dpi    : pour les rapports et présentations
#SVG            : pour l'édition vectorielle (Inkscape, Illustrator)
#PDF            : pour l'impression haute qualité
#GeoPackage     : pour partager les données enrichies avec d'autres SIG
#Commandes :
#  tmap_save(carte, 'outputs/fichier.png', dpi=300, width=20, height=16, units='cm')
  #tmap_save(carte, 'outputs/fichier.pdf')
 # st_write(objet_sf, 'outputs/fichier.gpkg', delete_dsn=TRUE)
 
#EXERCICES D'APPLICATION
#Exercice 1 : Test de randomité spatiale (débutant)
#En utilisant les grappes DHS urbaines uniquement :
#1.	Créer un objet ppp pour les grappes urbaines avec st_union(ds_cmr) comme fenêtre
#2.	Effectuer le test quadrat avec nx=8, ny=8
#3.	Tracer et interpréter la fonction G
#4.	Conclure sur la nature du processus ponctuel (agrégé, aléatoire, régulier)

#Exercice 2 : Comparaison de KDE (intermédiaire)
#Comparer la densité de grappes DHS entre régions du Cameroun :
#5.	Extraire les grappes du Grand Nord (Adamaoua, Nord, Extrême-Nord)
#6.	Calculer la KDE avec 3 bandwidths différents (bw.scott, bw.diggle, valeur manuelle)
#7.	Produire une carte comparative 3x1 avec par(mfrow=c(1,3))
#8.	Calculer la corrélation entre NDVI moyen et densité KDE par district

#Exercice 3 : Analyse LISA multi-indicateurs (avancé)
#Reproduire l'analyse LISA pour deux indicateurs différents :
#9.	Calculer l'autocorrélation spatiale du NDVI moyen par district sanitaire
#10.	Calculer le Moran's I du taux d'électrification
#11.	Produire une carte de synthèse 2x2 : Gi* eau, Gi* électricité, LISA eau, NDVI
#12.	Identifier les districts en situation de cumul de défaveurs (cold spot eau + cold spot électricité)
#13.	Exporter ces districts prioritaires en GeoPackage pour un rapport

##Questions de réflexion pour les participants
#1. Pourquoi les coordonnées DHS sont-elles délibérément décalées (déplacement aléatoire) ?
#   Quel impact cela a-t-il sur nos analyses spatiales ?

#2. La valeur de Moran's I dépend du choix de la matrice de poids W.
#   Comment vérifier la robustesse de vos résultats ?

#3. Quel est le danger de la 'gambler's fallacy' (erreur du joueur) dans l'interprétation
#   des points chauds ? Comment l'éviter dans vos rapports ?

#4. Les données Sentinel-2 du 26 juin 2026 capturent un état instantané du territoire.
#   Quelles précautions prendre pour des comparaisons temporelles ?


 
