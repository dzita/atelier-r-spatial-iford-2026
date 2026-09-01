## ============================================================================
## SCRIPT ÉTUDIANT — CORRIGÉ — J7 · Le hasard a-t-il une géographie ? Statistiques spatiales
## Atelier IFORD × GDSG 2026 · Lundi 3 août 2026
## Version complète du script étudiant (distribution en fin de journée).
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
packages_requis <- c("sf", "terra", "sp", "spdep", "spatstat",
                     "ggplot2", "tmap", "tmaptools", "dplyr",
                     "tidyr", "readr", "haven", "KernSmooth",
                     "SpatialKDE", "RColorBrewer", "viridis",
                     "leaflet", "mapview", "spatialreg",
                     "gstat", "classInt")

for (pkg in packages_requis) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

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
options(scipen = 999)  # Désactiver notation scientifique
tmap_mode('plot')      # Mode statique par défaut

#SECTION 1 : CHARGEMENT ET PRÉPARATION DES DONNÉES
#Présentation du corpus de données
#Ce module utilise un ensemble riche de données réelles couvrant le Cameroun. Chaque source apporte une dimension analytique complémentaire :

# ============================================================
# SECTION 1 : CHARGEMENT ET PRÉPARATION DES DONNÉES
# ============================================================

# ---- 1.1 Données géographiques de base du Cameroun ---------

# Districts sanitaires (polygones)
ds_cmr <- st_read("datasets/DS.geojson")
cat("Districts sanitaires chargés :", nrow(ds_cmr), "districts\n")
print(st_crs(ds_cmr))

# Pays limitrophes
pays_lim <- st_read("datasets/Pays_limitrophes_Cmr.shp")

# Reprojeter en WGS84 si nécessaire
wgs84 <- 4326
if (st_crs(ds_cmr)$epsg != wgs84) {
  ds_cmr <- st_transform(ds_cmr, wgs84)
}
if (st_crs(pays_lim)$epsg != wgs84) {
  pays_lim <- st_transform(pays_lim, wgs84)
}

# ---- 1.2 Données DHS : Grappes ménages (points) -----------

# Fichier géospatial DHS (localisation des grappes)
dhs_geo <- st_read("datasets/CMGE71FL.shp")
cat("Grappes DHS chargées :", nrow(dhs_geo), "grappes\n")
head(dhs_geo)

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
cat('=== Informations Sentinel-2 B08 ===\n')
print(b08)
cat('Résolution :', res(b08), 'm\n')
cat('Étendue :', ext(b08)[1], ext(b08)[2], ext(b08)[3], ext(b08)[4], '\n')

# ============================================================
# SECTION 2 : PRÉPARATION DES DONNÉES PONCTUELLES DHS
# ============================================================

# ---- 2.1 Vérification et nettoyage des grappes DHS ---------

# Inspecter les colonnes disponibles
names(dhs_geo)
summary(dhs_geo)

# Filtrer uniquement les coordonnées valides (lat/lon non nulles)
dhs_points <- dhs_geo %>%
  filter(!is.na(LATNUM) & !is.na(LONGNUM)) %>%
  filter(LATNUM != 0 & LONGNUM != 0) %>%
  st_transform(wgs84)

cat('Grappes avec coordonnées valides :', nrow(dhs_points), '\n')

# ---- 2.2 Jointure attributaire avec données ménages --------

# Préparer un indicateur de santé par grappe
# Exemple : taux de prévalence de la malnutrition (variable hv205)
# Adapter les noms de variables selon le dictionnaire DHS

if ('DHSCLUST' %in% names(dhs_hr) & 'DHSCLUST' %in% names(dhs_points)) {

  # Calcul d'indicateurs par grappe
  indicateurs_grappe <- dhs_hr %>%
    group_by(DHSCLUST) %>%
    summarise(
      n_menages     = n(),
      eau_amelioree = mean(hv201 %in% c(11,12,13,14,21,31,41,51,71), na.rm=TRUE) * 100,
      elect_access  = mean(hv206 == 1, na.rm=TRUE) * 100
    )

  # Jointure avec données spatiales
  dhs_points <- dhs_points %>%
    left_join(indicateurs_grappe, by = 'DHSCLUST')

  cat('Jointure réussie. Variables disponibles:\n')
  print(names(dhs_points))
}

# ---- 2.3 Carte exploratoire des grappes DHS ----------------

tmap_mode('plot')
tm_shape(ds_cmr) +
  tm_borders(col = 'grey60', lwd = 0.5) +
tm_shape(dhs_points) +
  tm_dots(col = 'URBAN_RURA', palette = c('red','blue'),
          title = 'Milieu', size = 0.3, alpha = 0.7) +
tm_layout(
  title = 'Localisation des grappes DHS - Cameroun',
  legend.outside = TRUE
)


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
coords <- st_coordinates(dhs_points)
x_pts  <- coords[,1]
y_pts  <- coords[,2]

# Définir la fenêtre d'observation = frontière du Cameroun
cmr_union <- st_union(ds_cmr)
cmr_owin  <- as.owin(cmr_union)

# Créer l'objet ppp
ppp_dhs <- ppp(x = x_pts, y = y_pts, window = cmr_owin)
cat('Nombre de points dans ppp :', ppp_dhs$n, '\n')

# Visualisation brute
plot(ppp_dhs, main = 'Grappes DHS - Motif ponctuel brut',
     cols = 'steelblue', cex = 0.5)

# ---- 3.2 Test de complète aléatoire spatiale (CSR) ---------

# Test quadrat : divise la zone en cellules, compare les
# fréquences observées vs attendues sous HPP (Homogeneous Poisson)
qt_test <- quadrat.test(ppp_dhs, nx = 10, ny = 10)
print(qt_test)
# Interprétation : p < 0.05 => rejet de la CSR

plot(qt_test,
     main = 'Test quadrat CSR - Grappes DHS',
     cex = 0.5)

# ---- 3.3 Statistique G (plus proches voisins) --------------

# G(r) = P(distance au plus proche voisin <= r)
# Si G(r) > G_CSR(r) => agrégation
# Si G(r) < G_CSR(r) => régularité

G_func <- Gest(ppp_dhs)
plot(G_func,
     main = 'Fonction G - Test d agrégation',
     col = c('black','red','blue'),
     lwd = 2)
legend('topleft',
       legend = c('G observée','G théorique CSR','G enveloppe'),
       col = c('black','red','blue'), lty = 1)

# ---- 3.4 Statistique K de Ripley (multi-échelle) -----------

# K(r) = intensité^-1 * E[nb points dans cercle rayon r]
# L(r) = sqrt(K(r)/pi) - r   (transformation stabilisante)
# Si L(r) > 0 => agrégation à l'échelle r

K_func <- Kest(ppp_dhs, correction = 'Ripley')
L_func <- Lest(ppp_dhs, correction = 'Ripley')

plot(L_func,
     main = 'Fonction L de Ripley - Grappes DHS',
     lwd = 2)
abline(h = 0, col = 'red', lty = 2, lwd = 2)

# ---- 3.5 Enveloppes de simulation (test Monte-Carlo) -------

# Comparer l'observé à 99 simulations sous CSR
# ATTENTION : long à calculer (réduire nsim si nécessaire)
set.seed(42)
env_L <- envelope(ppp_dhs, Lest,
                  nsim = 99, rank = 1,
                  correction = 'Ripley',
                  verbose = FALSE)

plot(env_L,
     main = 'Test CSR par enveloppes Monte-Carlo (n=99)',
     lwd = 2,
     shade = c('lo','hi'))
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
bw_scott <- bw.scott(ppp_dhs)
cat('Bandwidth Scott :', bw_scott, '\n')

# Largeur de bande par validation croisée
# (plus précise mais plus lente)
# bw_cv <- bw.diggle(ppp_dhs)  # décommenter si nécessaire

# Calcul de la densité
kde_dhs <- density.ppp(ppp_dhs,
                        sigma = bw_scott,
                        kernel = 'gaussian')

# Visualisation
par(mfrow = c(1,2))
plot(kde_dhs,
     main = paste0('KDE Grappes DHS\n(bandwidth = ',
                   round(bw_scott,3), ')'),
     col = viridis::viridis(100))
plot(ppp_dhs, add = TRUE, cex = 0.2, col = 'white')

# Tester plusieurs bandwidth
plot(density(ppp_dhs, sigma = 0.5),
     main = 'KDE sigma=0.5°', col = viridis::inferno(100))
par(mfrow = c(1,1))

# ---- 4.2 KDE avec données Sentinel-2 comme fond -----------

# Convertir kde en raster terra pour superposer Sentinel-2
kde_raster <- rast(kde_dhs)
crs(kde_raster) <- 'EPSG:4326'

# Reprojeter true_color si nécessaire
true_color_wgs <- project(true_color, kde_raster, method = 'bilinear')

# Affichage combiné
plotRGB(true_color_wgs, r=1, g=2, b=3, stretch='lin',
        main = 'Densité grappes DHS sur image Sentinel-2')
plot(kde_raster, add = TRUE, alpha = 0.5, col = viridis::plasma(50))

# ---- 4.3 KDE par milieu urbain/rural ---------------------

# Séparer urbain et rural
dhs_urbain <- dhs_points %>% filter(URBAN_RURA == 'U')
dhs_rural  <- dhs_points %>% filter(URBAN_RURA == 'R')

coords_u <- st_coordinates(dhs_urbain)
coords_r <- st_coordinates(dhs_rural)

ppp_urbain <- ppp(coords_u[,1], coords_u[,2], window = cmr_owin)
ppp_rural  <- ppp(coords_r[,1], coords_r[,2], window = cmr_owin)

par(mfrow = c(1,2))
plot(density(ppp_urbain, sigma = 0.3),
     main = 'Densité - Grappes URBAINES',
     col = viridis::magma(100))
plot(density(ppp_rural, sigma = 0.3),
     main = 'Densité - Grappes RURALES',
     col = viridis::viridis(100))
par(mfrow = c(1,1))

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
dhs_ds_join <- st_join(dhs_points, ds_cmr, join = st_within)

# Calculer un indicateur moyen par district
# (adapter le nom du district selon le fichier DS.geojson)
var_id_ds <- names(ds_cmr)[1]  # Première colonne = ID

# Indicateurs par district
resume_ds <- dhs_ds_join %>%
  st_drop_geometry() %>%
  group_by(across(all_of(var_id_ds))) %>%
  summarise(
    n_grappes      = n(),
    pct_urbain     = mean(URBAN_RURA == 'U', na.rm=TRUE) * 100,
    tx_eau         = mean(eau_amelioree, na.rm=TRUE),
    tx_electricite = mean(elect_access, na.rm=TRUE)
  ) %>%
  ungroup()

# Jointure avec couche ds_cmr
ds_indicateurs <- ds_cmr %>%
  left_join(resume_ds, by = var_id_ds)

# Remplacer NA par la moyenne (imputation simple)
ds_indicateurs$tx_eau[is.na(ds_indicateurs$tx_eau)] <-
  mean(ds_indicateurs$tx_eau, na.rm=TRUE)

# ---- 5.2 Construction de la matrice de poids spatiaux ------

# MÉTHODE 1 : Contiguïté (voisins qui partagent une frontière)
# Style 'W' = ligne-standardisée (somme = 1)
nb_queen <- poly2nb(ds_indicateurs, queen = TRUE)
lw_queen <- nb2listw(nb_queen, style = 'W', zero.policy = TRUE)

cat('Nombre de districts :', length(nb_queen), '\n')
cat('Nb moyen de voisins :', mean(card(nb_queen)), '\n')

# Visualiser les liens de contiguïté
coords_ds <- st_coordinates(st_centroid(ds_indicateurs))
plot(st_geometry(ds_indicateurs),
     col = 'lightyellow', border = 'grey60',
     main = 'Matrice de contiguïté (Queen) - Districts sanitaires')
plot(nb_queen, coords_ds, add = TRUE,
     col = 'steelblue', lwd = 0.5)

# MÉTHODE 2 : K plus proches voisins (k=4)
nb_knn4 <- knn2nb(knearneigh(coords_ds, k = 4))
lw_knn4 <- nb2listw(nb_knn4, style = 'W', zero.policy = TRUE)

# ---- 5.3 Moran's I Global ---------------------------------

# Test pour le taux d'accès à l'eau potable
moran_eau <- moran.test(ds_indicateurs$tx_eau,
                         listw = lw_queen,
                         zero.policy = TRUE)
print(moran_eau)
# Interprétation : si p < 0.05 et I > 0 => clustering spatial

# Test pour le taux d'électrification
moran_elec <- moran.test(ds_indicateurs$tx_electricite,
                          listw = lw_queen,
                          zero.policy = TRUE)
print(moran_elec)

# ---- 5.4 Diagramme de Moran (Moran Plot) ------------------

# Standardiser la variable
z_eau <- scale(ds_indicateurs$tx_eau)[,1]

# Calculer le lag spatial (moyenne des voisins)
lag_z_eau <- lag.listw(lw_queen, z_eau, zero.policy = TRUE)

# Créer le dataframe pour ggplot
moran_df <- data.frame(
  z          = z_eau,
  lag_z      = lag_z_eau,
  quadrant   = case_when(
    z_eau > 0 & lag_z_eau > 0 ~ 'HH (Haut-Haut)',
    z_eau < 0 & lag_z_eau < 0 ~ 'LL (Bas-Bas)',
    z_eau > 0 & lag_z_eau < 0 ~ 'HL (Haut-Bas)',
    z_eau < 0 & lag_z_eau > 0 ~ 'LH (Bas-Haut)',
    TRUE ~ 'Neutre'
  )
)

ggplot(moran_df, aes(x = z, y = lag_z, color = quadrant)) +
  geom_point(size = 2, alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = 'dashed') +
  geom_vline(xintercept = 0, linetype = 'dashed') +
  geom_smooth(method = 'lm', se = FALSE, color = 'black', lwd=1) +
  scale_color_manual(values = c(
    'HH (Haut-Haut)' = '#d7191c',
    'LL (Bas-Bas)'   = '#2c7bb6',
    'HL (Haut-Bas)'  = '#fdae61',
    'LH (Bas-Haut)'  = '#abd9e9'
  )) +
  labs(
    title = "Diagramme de Moran - Accès à l'eau potable",
    subtitle = paste0('I = ', round(moran_eau$estimate[1], 3),
                      ' | p = ', round(moran_eau$p.value, 4)),
    x = 'Valeur standardisée (z)',
    y = 'Lag spatial (moyenne voisins)',
    color = 'Quadrant LISA'
  ) +
  theme_minimal(base_size = 12)
 
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

lisa_eau <- localmoran(ds_indicateurs$tx_eau,
                        listw = lw_queen,
                        zero.policy = TRUE)

# Attacher les résultats au sf
ds_indicateurs$lisa_I    <- lisa_eau[, 'Ii']
ds_indicateurs$lisa_z    <- lisa_eau[, 'Z.Ii']
ds_indicateurs$lisa_pval <- lisa_eau[, 'Pr(z != E(Ii))']

# Seuil de significativité
alpha_seuil <- 0.05

# Assigner les quadrants
z_eau   <- scale(ds_indicateurs$tx_eau)[,1]
lag_eau <- lag.listw(lw_queen, z_eau, zero.policy = TRUE)

ds_indicateurs$lisa_quad <- 'Non significatif'
ds_indicateurs$lisa_quad[ds_indicateurs$lisa_pval < alpha_seuil &
                           z_eau > 0 & lag_eau > 0] <- 'HH - Point chaud'
ds_indicateurs$lisa_quad[ds_indicateurs$lisa_pval < alpha_seuil &
                           z_eau < 0 & lag_eau < 0] <- 'LL - Point froid'
ds_indicateurs$lisa_quad[ds_indicateurs$lisa_pval < alpha_seuil &
                           z_eau > 0 & lag_eau < 0] <- 'HL - Outlier +'
ds_indicateurs$lisa_quad[ds_indicateurs$lisa_pval < alpha_seuil &
                           z_eau < 0 & lag_eau > 0] <- 'LH - Outlier -'

cat('Distribution des quadrants LISA :\n')
print(table(ds_indicateurs$lisa_quad))

# ---- 6.2 Carte LISA (Points chauds) -----------------------

palette_lisa <- c(
  'HH - Point chaud'  = '#d7191c',
  'LL - Point froid'  = '#2c7bb6',
  'HL - Outlier +'    = '#fdae61',
  'LH - Outlier -'    = '#abd9e9',
  'Non significatif'  = '#f0f0f0'
)

tm_shape(ds_indicateurs) +
  tm_fill('lisa_quad',
          palette = palette_lisa,
          title   = 'Quadrant LISA') +
  tm_borders(col = 'white', lwd = 0.3) +
tm_shape(pays_lim) +
  tm_borders(col = 'black', lwd = 1.2) +
tm_layout(
  title  = "Carte LISA - Accès à l'eau potable\nDistricts sanitaires du Cameroun",
  legend.outside = TRUE,
  legend.title.size = 0.9
) +
tm_compass(position = c('left','top')) +
tm_scale_bar(position = c('left','bottom'))

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
gi_star <- localG(ds_indicateurs$tx_eau,
                   listw = lw_queen,
                   zero.policy = TRUE)

ds_indicateurs$gi_star  <- as.numeric(gi_star)

# Classer selon z-score (z > 1.96 => p<0.05, z > 2.58 => p<0.01)
ds_indicateurs$gi_class <- cut(
  ds_indicateurs$gi_star,
  breaks = c(-Inf, -2.58, -1.96, -1.65, 1.65, 1.96, 2.58, Inf),
  labels = c(
    'Cold Spot 99%', 'Cold Spot 95%', 'Cold Spot 90%',
    'Non significatif',
    'Hot Spot 90%', 'Hot Spot 95%', 'Hot Spot 99%'
  )
)

# Carte Gi*
palette_gi <- c(
  'Cold Spot 99%' = '#084594', 'Cold Spot 95%' = '#2171b5',
  'Cold Spot 90%' = '#6baed6', 'Non significatif' = '#f7f7f7',
  'Hot Spot 90%'  = '#fdae6b', 'Hot Spot 95%'  = '#e6550d',
  'Hot Spot 99%'  = '#a63603'
)

tm_shape(ds_indicateurs) +
  tm_fill('gi_class',
          palette = palette_gi,
          title   = 'Getis-Ord Gi*') +
  tm_borders(col = 'white', lwd = 0.3) +
tm_shape(pays_lim) +
  tm_borders(col = 'black', lwd = 1.2) +
tm_layout(
  title  = "Points chauds - Accès eau potable (Gi*)\nCameroun 2024",
  legend.outside = TRUE
) +
tm_compass(position = c('left','top')) +
tm_scale_bar(position = c('left','bottom'))

# ---- 7.2 Comparaison LISA vs Gi* --------------------------

# Tableau de concordance
table(LISA = ds_indicateurs$lisa_quad,
      Gi   = ds_indicateurs$gi_class)

# ---- 7.3 KDE comme surface de points chauds ---------------

# Discrétiser la KDE en classes percentiles
kde_vals   <- values(kde_raster)
p90 <- quantile(kde_vals, 0.90, na.rm=TRUE)
p95 <- quantile(kde_vals, 0.95, na.rm=TRUE)
p99 <- quantile(kde_vals, 0.99, na.rm=TRUE)

kde_hotspot <- classify(kde_raster,
  rcl = matrix(c(
    0,   p90, 1,
    p90, p95, 2,
    p95, p99, 3,
    p99, Inf,  4
  ), ncol=3, byrow=TRUE))

plot(kde_hotspot,
     main = 'Points chauds KDE - Grappes DHS',
     col  = c('#f7f7f7','#fdae6b','#e6550d','#a63603'),
     legend = TRUE)
plot(st_geometry(ds_cmr), add=TRUE,
     border = 'grey40', lwd = 0.4)


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
resume_sante_ds <- dhs_ds_join %>%
  st_drop_geometry() %>%
  group_by(across(all_of(var_id_ds))) %>%
  summarise(
    score_sante = mean(c(
      mean(eau_amelioree, na.rm=TRUE)/100,
      mean(elect_access, na.rm=TRUE)/100
    ), na.rm=TRUE) * 100
  )

# ---- 8.2 Intégration données ECAM 2022 ---------------------

# Explorer la structure ECAM
cat('Variables ECAM disponibles :\n')
cat(paste(names(ecam)[1:30], collapse=', '), '\n')

# Vérifier si une variable région est disponible
# (adapter selon la codification ECAM 2022)
if ('region' %in% tolower(names(ecam))) {
  vars_region <- names(ecam)[tolower(names(ecam)) == 'region']
  ecam_resume <- ecam %>%
    group_by(across(all_of(vars_region))) %>%
    summarise(
      n_menages = n(),
      .groups = 'drop'
    )
  print(ecam_resume)
}

# ---- 8.3 Carte composite : ECAM + districts sanitaires -----

# Indicateurs de population (WorldPop)
# Agréger pop_admin2 par grande région si possible
if ('admin2name' %in% names(pop_admin2)) {
  pop_resume <- pop_admin2 %>%
    arrange(desc(T_TL)) %>%
    slice_head(n = 20)
  print(pop_resume[, c('admin2name','T_TL')])
}

# ---- 8.4 Analyse Sentinel-2 : Indice NDVI ------------------

# NDVI = (B08 - B04) / (B08 + B04)
# Proche de 1 => végétation dense
# Proche de 0 => sol nu, zones urbaines
ndvi <- (b08 - b04) / (b08 + b04)
names(ndvi) <- 'NDVI'

# NDWI = (B03 - B08) / (B03 + B08) - eau
ndwi <- (b03 - b08) / (b03 + b08)
names(ndwi) <- 'NDWI'

# Carte NDVI
plot(ndvi,
     main = 'NDVI - Sentinel-2 (26 juin 2026)',
     col  = colorRampPalette(c('#a50026','#ffffbf','#006837'))(100),
     range = c(-0.5, 0.9))

# Superposer les districts sanitaires
ndvi_crop <- crop(ndvi, vect(ds_cmr))
ndvi_mask <- mask(ndvi_crop, vect(ds_cmr))

# Statistiques NDVI par district sanitaire
ndvi_stats_ds <- extract(ndvi_mask,
                          vect(ds_indicateurs),
                          fun = mean, na.rm = TRUE,
                          bind = TRUE)
ndvi_df <- as.data.frame(ndvi_stats_ds)

ds_indicateurs$ndvi_moy <- ndvi_df$NDVI

# Carte NDVI moyen par district
tm_shape(ds_indicateurs) +
  tm_fill('ndvi_moy',
          style  = 'jenks', n = 6,
          palette = '-RdYlGn',
          title   = 'NDVI moyen') +
  tm_borders(col = 'white', lwd = 0.2) +
tm_layout(
  title  = 'Couverture végétale moyenne\npar district sanitaire (Sentinel-2)',
  legend.outside = TRUE
)


# ============================================================
# SECTION 9 : CARTE DE SYNTHÈSE INTERACTIVE
# ============================================================

# ---- 9.1 Carte statique multi-indicateurs ------------------

tmap_mode('plot')

carte_synthese <- tm_shape(ds_indicateurs) +
  tm_fill('gi_class',
          palette  = palette_gi,
          title    = 'Points chauds\n(Gi* Eau potable)',
          colorNA  = 'grey90') +
  tm_borders(col = 'white', lwd = 0.2) +
tm_shape(pays_lim) +
  tm_borders(col = 'black', lwd = 1.5) +
tm_shape(dhs_points) +
  tm_dots(col = 'URBAN_RURA',
          palette = c('R'='#1f78b4','U'='#e31a1c'),
          size  = 0.15, alpha = 0.5,
          title = 'Milieu DHS') +
tm_layout(
  title       = 'Analyse spatiale Cameroun\nPoints chauds eau + Grappes DHS',
  legend.outside      = TRUE,
  legend.outside.size = 0.2,
  frame = TRUE
) +
tm_compass(type = '8star', position = c(0.02, 0.08), size = 2) +
tm_scale_bar(position = c(0.02, 0.02))

print(carte_synthese)

# Sauvegarder la carte
tmap_save(carte_synthese, "outputs/carte_synthese_jour6.png", dpi=300)

# ---- 9.2 Carte interactive Leaflet -------------------------

tmap_mode('view')

tm_shape(ds_indicateurs) +
  tm_fill('gi_class', palette = palette_gi, alpha = 0.7,
          popup.vars = c('tx_eau','tx_electricite','ndvi_moy')) +
  tm_borders() +
tm_shape(dhs_points) +
  tm_dots(col = 'URBAN_RURA', palette = c('R'='blue','U'='red'),
          popup.vars = TRUE) +
tm_basemap(server = 'OpenStreetMap')

# Revenir au mode statique
tmap_mode('plot')

# ---- 9.3 Export complet des résultats ----------------------

# Sauvegarder le shapefile enrichi
st_write(ds_indicateurs,
         "outputs/resultats_jour6_districts.gpkg",
         delete_dsn = TRUE)

# Tableau récapitulatif
recap <- ds_indicateurs %>%
  st_drop_geometry() %>%
  select(where(is.numeric)) %>%
  summarise(across(everything(), list(
    moy = ~mean(.x, na.rm=TRUE),
    med = ~median(.x, na.rm=TRUE)
  )))

write.csv(recap, "outputs/resume_indicateurs_jour6.csv", row.names=FALSE)
cat("\n✅ Analyse du Jour 6 terminée. Fichiers sauvegardés.\n")

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


 
