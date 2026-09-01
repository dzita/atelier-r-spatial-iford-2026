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

packages_requis <- c(
  # Données géospatiales de base
  "sf",          # Lecture et manipulation de fichiers géospatiaux (shp, geojson, ...)
  "terra",       # Traitement des images raster (Sentinel-2)
  "stars",       # Alternative moderne pour rasters
  # Cartographie statique
  "ggplot2",     # Grammaire des graphiques, cartes thématiques
  "tmap",        # Package cartographique spécialisé, mode statique et interactif
  "ggspatial",   # Ajout flèche nord, échelle dans ggplot2
  "scales",      # Formatage des légendes (pourcentage, milliers, ...)
  "viridis",     # Palettes de couleurs perceptivement uniformes
  "RColorBrewer",# Palettes ColorBrewer adaptées aux cartes
  # Cartographie interactive
  "leaflet",     # Cartes interactives web (comme Google Maps)
  "leaflet.extras", # Fonctionnalités supplémentaires leaflet
  "mapview",     # Visualisation rapide interactive d'objets sf
  # Lecture de données
  "haven",       # Lecture fichiers SPSS (.sav) et Stata (.dta)
  "readr",       # Lecture rapide CSV
  "dplyr",       # Manipulation de données
  "tidyr",       # Restructuration de données
  "forcats",     # Gestion des variables catégorielles
  # Export et mise en page
  "cowplot",     # Assemblage de plusieurs cartes
  "patchwork",   # Composition de graphiques ggplot2
  "gridExtra",   # Grilles de graphiques
  "knitr",       # Génération de rapports
  "htmlwidgets"  # Export widgets interactifs en HTML
)

# Installer uniquement les packages manquants
nouveaux <- packages_requis[!packages_requis %in% installed.packages()[,"Package"]]
if (length(nouveaux) > 0) {
  cat("Installation de :", paste(nouveaux, collapse = ", "), "\n")
  install.packages(nouveaux, repos = "https://cloud.r-project.org")
} else {
  cat("Tous les packages sont deja installes !\n")
}

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
dir_out <- "output/cartes/"

# ── Options globales ──────────────────────────────────────────────────
options(scipen = 999)        # Désactiver la notation scientifique
Sys.setlocale("LC_ALL", "fr_FR.UTF-8")  # Encodage français (Linux/Mac)
# Sys.setlocale('LC_ALL', 'French_France.UTF-8')  # Windows

# ── Mode tmap par défaut ──────────────────────────────────────────────
tmap_mode("plot")   # Mode statique (changer en "view" pour interactif)

cat("Environnement initialise avec succes !\n")

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

cat('Verification des systemes de coordonnees :\n')
cat('Regions   :', st_crs(rgn)$epsg, '\n')
cat('Dep       :', st_crs(dep)$epsg, '\n')
cat('DHS pts   :', st_crs(dhs_pts)$epsg, '\n')
cat('Sentinel2 :', crs(b08, describe=TRUE)$code, '\n')

# ── Reprojeter tout en WGS84 (EPSG:4326) si nécessaire ────────────────
if (is.na(st_crs(rgn)) || st_crs(rgn)$epsg != 4326) {
  rgn <- st_transform(rgn, 4326)
  dep <- st_transform(dep, 4326)
  arr <- st_transform(arr, 4326)
  lim <- st_transform(lim, 4326)
  ds  <- st_transform(ds,  4326)
}

# ── Vérifications rapides ─────────────────────────────────────────────
cat('\nNombre de regions   :', nrow(rgn), '\n')
cat('Nombre de departements:', nrow(dep), '\n')
cat('Nombre de districts  :', nrow(ds),  '\n')
cat('Points DHS          :', nrow(dhs_pts), '\n')
cat('Observations ECAM5  :', nrow(ecam5),   '\n')

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

mortalite_rgn <- dhs_wom_raw %>%
  mutate(
    poids = as.numeric(V005) / 1e6,
    deces_lt5 = ifelse(as.numeric(B5) == 0 & as.numeric(B7) < 60, 1, 0),
    # Naissances vivantes dans les 5 dernières années
    naissance = 1
  ) %>%
  group_by(V101) %>%
  summarise(
    nb_naissances  = sum(poids * naissance, na.rm = TRUE),
    nb_deces_lt5   = sum(poids * deces_lt5, na.rm = TRUE),
    taux_mort = (nb_deces_lt5 / nb_naissances) * 1000,
    .groups = 'drop'
  ) %>%
  rename(region_code = V101)

# Étape 2 : Joindre avec les frontières régionales
# Note : Les codes régions DHS doivent correspondre à ceux du shapefile
# Adapter selon les codes dans vos données réelles
rgn_mort <- rgn %>%
  mutate(region_code = as.character(row_number())) %>%
  left_join(mortalite_rgn, by = 'region_code')

# Étape 3 : Construire la carte choroplèthe avec ggplot2
carte_mortalite <- ggplot() +

  # Couche 1 : Pays limitrophes (contexte géographique)
  geom_sf(data = lim,
          fill = '#F5F5F0',   # Gris très clair pour les pays voisins
          color = '#AAAAAA',  # Bordure grise
          linewidth = 0.3) +

  # Couche 2 : Régions colorées selon le taux de mortalité
  geom_sf(data = rgn_mort,
          aes(fill = taux_mort),    # Variable de remplissage
          color = 'white',           # Bordures blanches entre régions
          linewidth = 0.5) +

  # Couche 3 : Noms des régions
  geom_sf_text(data = rgn_mort,
               aes(label = NAME_1),   # Adapter le nom de colonne
               size = 2.5,
               color = 'black',
               fontface = 'bold',
               check_overlap = TRUE) +

  # Échelle de couleurs : palette séquentielle divergente
  # RdYlGn : Rouge (fort) -> Jaune -> Vert (faible)
  # direction = -1 : rouge = mortalité élevée (mauvais)
  scale_fill_distiller(
    palette   = 'YlOrRd',
    direction = 1,
    name      = 'Décès pour\n1 000 naissances',
    na.value  = '#DDDDDD',
    labels    = label_number(accuracy = 1)
  ) +

  # Flèche nord et échelle
  annotation_scale(
    location = 'bl',     # bl = bas gauche
    width_hint = 0.25,
    text_cex = 0.8
  ) +
  annotation_north_arrow(
    location = 'tl',    # tl = haut gauche
    which_north = 'true',
    pad_x = unit(0.1, 'in'), pad_y = unit(0.1, 'in'),
    style = north_arrow_fancy_orienteering()
  ) +

  # Titres et légende
  labs(
    title    = 'Mortalité infanto-juvénile au Cameroun',
    subtitle = 'Taux de mortalité des moins de 5 ans par région (pour 1 000 naissances vivantes)',
    caption  = 'Source : Enquête Démographique et de Santé (DHS), Cameroun 2018\nProjection : WGS84 (EPSG:4326)',
    x = NULL, y = NULL
  ) +

  # Thème propre, sans quadrillage visible
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_text(face = 'bold', size = 14, hjust = 0),
    plot.subtitle    = element_text(size = 9, color = 'grey40', hjust = 0),
    plot.caption     = element_text(size = 7, color = 'grey50', hjust = 1),
    legend.position  = 'right',
    legend.key.height = unit(1.5, 'cm'),
    panel.grid       = element_blank(),
    panel.background = element_rect(fill = '#D6EAF8', color = NA)  # Bleu eau = océan/contexte
  ) +

  # Limiter la vue au Cameroun
  coord_sf(xlim = c(8.4, 16.1), ylim = c(1.7, 13.1), expand = FALSE)

# Afficher la carte
print(carte_mortalite)

# Sauvegarder en haute résolution
ggsave(
  filename = paste0(dir_out, 'outputs/carte_mortalite_infantile_dhs.png'),
  plot     = carte_mortalite,
  width    = 20, height = 22, units = 'cm',
  dpi      = 300,
  bg       = 'white'
)
cat("Carte exportee : carte_mortalite_infantile_dhs.png\n")

#1.3 Carte choroplèthe — Dépenses de consommation des ménages (ECAM5)
# ── SEQUENCE 1.3 : Carte choroplèthe — Consommation ménages (ECAM5) ─────

# ECAM5 contient typiquement les variables suivantes :
# - region    : identifiant de la région
# - milieu    : urbain/rural
# - pcexp     : dépenses de consommation par tête (XAF par an)
# - hhsize    : taille du ménage
# - welfare_index / s00q01, s00q04 : identifiants géographiques

# Calculer la consommation médiane par région
conso_rgn <- ecam5 %>%
  group_by(region) %>%           # Adapter selon nom de colonne
  summarise(
    conso_mediane = median(as.numeric(pcexp), na.rm = TRUE),
    conso_moy     = mean(as.numeric(pcexp),   na.rm = TRUE),
    n_menages     = n(),
    .groups = 'drop'
  ) %>%
  mutate(
    # Transformer en millions XAF pour faciliter la lecture
    conso_med_Mxaf = conso_mediane / 1e6,
    # Catégoriser
    categorie = cut(conso_mediane,
      breaks = quantile(conso_mediane, probs = c(0, 0.2, 0.4, 0.6, 0.8, 1), na.rm = TRUE),
      labels = c('Très faible','Faible','Moyen','Élevé','Très élevé'),
      include.lowest = TRUE
    )
  )

# Jointure avec les polygones régionaux
# La clé de jointure doit correspondre — à adapter selon vos données
rgn_conso <- rgn %>%
  left_join(conso_rgn, by = c('NAME_1' = 'region'))

# Carte choroplèthe de la consommation
carte_conso <- ggplot() +
  geom_sf(data = lim, fill = '#F5F5F0', color = '#AAAAAA', linewidth = 0.3) +

  geom_sf(data = rgn_conso,
          aes(fill = conso_med_Mxaf),
          color = 'white', linewidth = 0.6) +

  # Palette viridis : bien adaptée aux daltoniens
  scale_fill_viridis_c(
    name   = 'Consommation\nmédiane\n(millions XAF)',
    option = 'plasma',   # plasma, magma, viridis, cividis
    direction = 1,
    labels = label_number(accuracy = 0.1, suffix = 'M'),
    na.value = 'grey80'
  ) +

  annotation_scale(location = 'bl') +
  annotation_north_arrow(location = 'tl',
    style = north_arrow_minimal()) +

  labs(
    title    = 'Niveau de vie des ménages camerounais',
    subtitle = 'Dépenses de consommation médiane par tête et par région — ECAM5 (2022)',
    caption  = 'Source : ECAM5, INS Cameroun (2022) — Valeurs en millions de FCFA par personne/an',
    x = NULL, y = NULL
  ) +

  theme_void(base_size = 11) +
  theme(
    plot.title       = element_text(face = 'bold', size = 13),
    plot.subtitle    = element_text(size = 9, color = 'grey40'),
    plot.caption     = element_text(size = 7, color = 'grey50'),
    legend.position  = 'right',
    plot.background  = element_rect(fill = 'white', color = NA)
  ) +
  coord_sf(xlim = c(8.4, 16.1), ylim = c(1.7, 13.1))

ggsave(paste0(dir_out, 'outputs/carte_conso_ecam5.png'), carte_conso,
       width = 20, height = 22, units = 'cm', dpi = 300, bg = 'white')


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
prev_cluster <- dhs_men_raw %>%
  group_by(v001) %>%   # v001 = numéro de cluster
  summarise(
    n_menages   = n(),
    pct_mosquito = mean(as.numeric(ml101) == 1, na.rm = TRUE) * 100,  # adapter
    .groups = 'drop'
  ) %>%
  rename(DHSCLUST = v001)

# Joindre avec les points géographiques
dhs_carte <- dhs_pts %>%
  left_join(prev_cluster, by = 'DHSCLUST') %>%
  filter(!is.na(LATNUM) & LATNUM != 0)   # Supprimer coordonnées manquantes

# Carte avec symboles proportionnels
carte_pts <- ggplot() +

  # Fond : régions
  geom_sf(data = rgn,
          fill = '#F0F4F8', color = '#CCCCCC', linewidth = 0.4) +

  # Points DHS proportionnels + couleur (URBAN vs RURAL)
  geom_sf(data = dhs_carte,
          aes(
            size  = n_menages,          # Taille = nb de ménages
            color = URBAN_RURA,          # Couleur = milieu de résidence
            alpha = pct_mosquito         # Transparence = taux moustiquaire
          ),
          shape = 16) +                  # Cercle plein

  # Légendes personnalisées
  scale_size_continuous(
    name   = 'Nb de ménages\npar cluster',
    range  = c(1, 8),
    breaks = c(10, 30, 50, 100)
  ) +
  scale_color_manual(
    name   = 'Milieu',
    values = c('U' = '#E74C3C', 'R' = '#2ECC71'),
    labels = c('U' = 'Urbain', 'R' = 'Rural')
  ) +
  scale_alpha_continuous(
    name   = 'Couverture\nmoustiquaires (%)',
    range  = c(0.3, 1)
  ) +

  annotation_scale(location = 'bl') +
  annotation_north_arrow(location = 'tr', style = north_arrow_minimal()) +

  labs(
    title    = 'Distribution des clusters DHS au Cameroun',
    subtitle = 'Taille des symboles = nombre de ménages  |  Couleur = milieu de résidence',
    caption  = 'Source : DHS Programme, Cameroun 2018 (CMGE71FL)',
    x = NULL, y = NULL
  ) +

  theme_minimal(base_size = 10) +
  theme(
    plot.title    = element_text(face = 'bold', size = 12),
    panel.grid    = element_blank(),
    legend.position = 'right'
  ) +
  coord_sf(xlim = c(8.4, 16.1), ylim = c(1.7, 13.1))

ggsave(paste0(dir_out, 'outputs/carte_clusters_dhs.png'), carte_pts,
       width = 22, height = 24, units = 'cm', dpi = 300, bg = 'white')

#1.5 Cartes en facettes — Comparaison par milieu ou par indicateur
# ── SEQUENCE 1.5 : Cartes en facettes — Comparaison urbain/rural ────────

# Les facettes permettent de produire plusieurs petites cartes côte à côte
# Exemple : taux de vaccination par région, comparaison Urbain vs Rural

vaccin_milieu <- dhs_wom_raw %>%
  mutate(
    poids     = as.numeric(V005) / 1e6,
    vaccin_dt = as.numeric(H3) == 1,   # H3 = DTP3 vacciné
    milieu    = ifelse(V025 == 1, 'Urbain', 'Rural')
  ) %>%
  group_by(V101, milieu) %>%
  summarise(
    taux_vaccin = weighted.mean(vaccin_dt, w = poids, na.rm = TRUE) * 100,
    .groups = 'drop'
  )

# Joindre avec géographie
rgn_vaccin <- rgn %>%
  left_join(vaccin_milieu, by = c('NAME_1' = 'V101'))

# Carte avec facettes Urbain / Rural
carte_facettes <- ggplot(rgn_vaccin) +
  geom_sf(aes(fill = taux_vaccin), color = 'white', linewidth = 0.4) +
  facet_wrap(~ milieu, ncol = 2) +   # Une carte par milieu

  scale_fill_distiller(
    palette   = 'RdYlGn',
    direction = 1,
    name      = 'Taux DTP3 (%)',
    limits    = c(0, 100),
    labels    = label_number(suffix = '%'),
    na.value  = 'grey80'
  ) +

  labs(
    title    = 'Couverture vaccinale DTP3 selon le milieu de résidence — Cameroun',
    subtitle = 'Pourcentage d\'enfants de 12-23 mois ayant reçu 3 doses de DTP',
    caption  = 'Source : EDS Cameroun (DHS) 2018'
  ) +

  theme_minimal(base_size = 10) +
  theme(
    strip.text    = element_text(face = 'bold', size = 11),
    strip.background = element_rect(fill = '#D6E4F0', color = NA),
    panel.grid    = element_blank(),
    legend.position = 'bottom',
    legend.key.width = unit(1.5, 'cm')
  )

ggsave(paste0(dir_out, 'outputs/carte_vaccin_facettes.png'), carte_facettes,
       width = 28, height = 18, units = 'cm', dpi = 300, bg = 'white')

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
tm_shape(rgn) +
  tm_polygons(col = 'lightblue', border.col = 'white') +
  tm_layout(title = 'Régions du Cameroun')

# ── Basculer entre mode statique et interactif ────────────────────────
tmap_mode('plot')   # Mode statique (pour export PDF/PNG)
tmap_mode('view')   # Mode interactif (pour explorer dans RStudio)
tmap_mode('plot')   # Remettre en statique pour la suite

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
fies <- data.frame(
  region = unique(rgn$NAME_1),
  fies_mod    = c(45.2, 38.7, 52.1, 61.4, 33.8, 29.5, 56.7, 48.3, 41.9, 37.2),
  fies_severe = c(22.1, 18.4, 28.5, 34.7, 15.2, 12.8, 31.4, 24.6, 19.7, 16.9)
)

# Jointure avec le shapefile des régions
rgn_fies <- rgn %>%
  left_join(fies, by = c('NAME_1' = 'region'))

# ── Carte tmap de l'insécurité alimentaire ────────────────────────────
carte_fies_tmap <- tm_shape(lim) +
  tm_polygons(col = '#F5F5F0', border.col = '#AAAAAA', lwd = 0.5) +

tm_shape(rgn_fies) +
  tm_polygons(
    col           = 'fies_severe',          # Variable à cartographier
    title         = 'Insécurité\nalimentaire\nsévère (%)',
    palette       = '-RdYlGn',               # Rouge = fort, Vert = faible
    style         = 'jenks',                 # Classification naturelle (Jenks)
    n             = 5,                       # Nombre de classes
    border.col    = 'white',
    border.alpha  = 0.8,
    legend.format = list(suffix = '%'),
    popup.vars    = c('Région' = 'NAME_1',
                      'Insécurité modérée (%)' = 'fies_mod',
                      'Insécurité sévère (%)'  = 'fies_severe')
  ) +

# Ajout des noms de régions
tm_shape(rgn_fies) +
  tm_text('NAME_1', size = 0.55, col = 'black', fontface = 'bold',
          just = 'center', remove.overlap = TRUE) +

# Ornements cartographiques
  tm_compass(
    type     = 'arrow',
    position = c('left', 'top'),
    size     = 2
  ) +
  tm_scale_bar(
    breaks   = c(0, 100, 200, 300),
    text.size = 0.65,
    position = c('left', 'bottom')
  ) +

# Mise en page générale
  tm_layout(
    title            = 'Insécurité alimentaire sévère au Cameroun',
    title.size       = 1.1,
    title.fontface   = 'bold',
    title.color      = '#1F4E79',
    legend.outside   = TRUE,
    legend.position  = c('right', 'center'),
    legend.frame     = FALSE,
    bg.color         = '#D6EAF8',
    outer.bg.color   = 'white',
    frame            = TRUE,
    fontfamily       = 'sans'
  ) +
  tm_credits(
    'Source : FAO — FIES Cameroun | Carte : INS Cameroun',
    size     = 0.55,
    position = c('right', 'bottom')
  )

# Afficher
carte_fies_tmap

# Sauvegarder
tmap_save(carte_fies_tmap,
          filename = paste0(dir_out, 'outputs/carte_insecurite_alimentaire_fies.png'),
          width = 20, height = 22, dpi = 300, units = 'cm')

#2.3 Carte à symboles proportionnels — Population par département

# ── MODULE 2.3 : Symboles proportionnels — Population (CMR_population) ─

# Lire les données de population au niveau 2 (département/arrondissement)
# CMR_population_v1_0_admin_level2.csv contient la population par unité admin

head(pop, 3)   # Explorer la structure
names(pop)     # Voir les noms des colonnes

# Agréger au niveau département si nécessaire
pop_dep <- pop %>%
  group_by(admin2_name) %>%  # Adapter le nom de colonne
  summarise(
    pop_totale = sum(population, na.rm = TRUE),   # Adapter
    .groups = 'drop'
  )

# Calculer le centroïde de chaque département pour positionner les symboles
dep_centroides <- dep %>%
  left_join(pop_dep, by = c('NAME_2' = 'admin2_name')) %>%
  st_centroid()     # Transformer polygones en points (centroïdes)

dep_join <- dep %>%
  left_join(pop_dep, by = c('NAME_2' = 'admin2_name'))

# Carte tmap avec symboles proportionnels
carte_pop_tmap <-
  tm_shape(dep_join) +
  tm_polygons(col = '#EBF5FB', border.col = '#A9CCE3', lwd = 0.4) +

  tm_shape(dep_centroides) +
  tm_bubbles(
    size          = 'pop_totale',     # Taille des cercles = population
    col           = 'pop_totale',     # Couleur aussi selon la population
    palette       = 'Blues',
    title.size    = 'Population totale',
    title.col     = '',
    scale         = 1.2,              # Facteur d'échelle global
    border.col    = 'white',
    border.lwd    = 0.5,
    alpha         = 0.8,
    legend.size.is.portrait = TRUE,
    sizes.legend  = c(50000, 200000, 500000, 1000000)
  ) +

  tm_compass(type = 'rose', position = c('right', 'top'), size = 2.5) +
  tm_scale_bar(position = c('left', 'bottom'), text.size = 0.6) +

  tm_layout(
    title          = 'Population par département — Cameroun',
    title.size     = 1.0,
    title.fontface = 'bold',
    legend.outside = TRUE,
    bg.color       = '#EBF5FB',
    frame.double.line = TRUE
  ) +
  tm_credits('Source : WorldPop / OCHA — CMR_population_v1_0_admin_level2',
             position = c('right','bottom'), size = 0.5)

tmap_save(carte_pop_tmap,
          filename = paste0(dir_out, 'outputs/carte_population_dep.png'),
          width = 22, height = 24, dpi = 300)


#2.4 Carte multi-couches — Données de santé + Districts sanitaires

# ── MODULE 2.4 : Carte multi-couches — Districts sanitaires + DHS ─────

# Calculer la couverture CPN4 (4 consultations prénatales) par district
# Variable DHS : V023 = strate d'enquête, M14 = nb consultations prénatales

cpn4_cluster <- dhs_wom_raw %>%
  mutate(
    poids = as.numeric(V005) / 1e6,
    cpn4  = as.numeric(M14) >= 4
  ) %>%
  group_by(V001) %>%   # V001 = cluster
  summarise(
    taux_cpn4 = weighted.mean(cpn4, w = poids, na.rm = TRUE) * 100,
    n_femmes  = n(),
    .groups = 'drop'
  ) %>%
  rename(DHSCLUST = V001)

# Joindre avec points GPS
dhs_cpn4 <- dhs_pts %>%
  left_join(cpn4_cluster, by = 'DHSCLUST') %>%
  filter(!is.na(LATNUM) & LATNUM != 0 & !is.na(taux_cpn4))

# Carte multi-couches avec tmap
carte_sante_multi <-

  # Couche 0 : Pays limitrophes (contexte)
  tm_shape(lim) +
  tm_polygons(col = '#F9F9F7', border.col = '#BBBBBB', lwd = 0.4) +

  # Couche 1 : Districts sanitaires (remplissage fond)
  tm_shape(ds) +
  tm_polygons(
    col        = '#FDFEFE',
    border.col = '#5DADE2',
    lwd        = 0.5,
    alpha      = 0.4
  ) +

  # Couche 2 : Régions (contour épais pour délimitation)
  tm_shape(rgn) +
  tm_borders(col = '#1F4E79', lwd = 1.5) +

  # Couche 3 : Points DHS colorés selon taux CPN4
  tm_shape(dhs_cpn4) +
  tm_dots(
    col         = 'taux_cpn4',
    palette     = 'RdYlGn',
    size        = 0.3,
    title       = 'Couverture\nCPN4 (%)',
    style       = 'quantile',
    n           = 5,
    legend.format = list(suffix = '%'),
    border.col  = 'white',
    border.lwd  = 0.3
  ) +

  # Étiquettes des régions
  tm_shape(rgn) +
  tm_text('NAME_1', size = 0.5, col = '#1F4E79', fontface = 'bold',
          remove.overlap = TRUE) +

  tm_compass(position = c('left','top'), size = 2) +
  tm_scale_bar(position = c('left','bottom')) +

  tm_layout(
    title          = 'Couverture CPN4 par cluster d\'enquête — Cameroun',
    title.size     = 0.95,
    title.fontface = 'bold',
    legend.outside = TRUE,
    bg.color       = '#EBF5FB',
    frame          = TRUE
  ) +
  tm_credits('Sources : DHS Cameroun 2018 | Districts sanitaires MSPSRD',
             position = c('right','bottom'), size = 0.5)

tmap_save(carte_sante_multi,
          filename = paste0(dir_out, 'outputs/carte_cpn4_districts_sante.png'),
          width = 22, height = 25, dpi = 300)

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
ds_interactif <- ds %>%
  mutate(
    # Créer un popup HTML enrichi
    popup_info = paste0(
      '<b>District sanitaire :</b> ', NAME_DS, '<br>',   # Adapter le nom colonne
      '<b>Région sanitaire :</b> ',   NAME_RS, '<br>',
      '<b>Population estimée :</b> ', format(POP_EST, big.mark=','), ' habitants'
    )
  )

# Palette de couleurs pour le remplissage interactif
pal_ds <- colorFactor(
  palette = 'Set3',          # Palette qualitative
  domain  = ds_interactif$NAME_RS  # Variable de couleur
)

# Construire la carte Leaflet
carte_leaflet_ds <- leaflet(ds_interactif) %>%

  # ── Fonds de carte (tiles) ────────────────────────────────────────
  addProviderTiles('Esri.WorldGrayCanvas',  group = 'Gris (sobre)') %>%
  addProviderTiles('OpenStreetMap',          group = 'OpenStreetMap') %>%
  addProviderTiles('Esri.WorldImagery',      group = 'Satellite') %>%
  addProviderTiles('CartoDB.Positron',       group = 'CartoDB clair') %>%

  # ── Polygones des districts sanitaires ────────────────────────────
  addPolygons(
    fillColor   = ~pal_ds(NAME_RS),   # Adapter
    fillOpacity = 0.6,
    color       = 'white',            # Bordures
    weight      = 1,
    opacity     = 0.8,
    popup       = ~popup_info,         # Info-bulle au clic
    label       = ~NAME_DS,            # Étiquette au survol
    labelOptions = labelOptions(
      style = list('font-weight' = 'bold', 'font-size' = '13px'),
      textsize = '13px',
      direction = 'auto'
    ),
    highlight = highlightOptions(
      weight      = 3,
      color       = '#333333',
      fillOpacity = 0.85,
      bringToFront = TRUE
    ),
    group = 'Districts sanitaires'
  ) %>%

  # ── Contours régionaux (couche supplémentaire) ─────────────────────
  addPolygons(
    data        = rgn,
    fill        = FALSE,
    color       = '#1F4E79',
    weight      = 2.5,
    opacity     = 0.9,
    group       = 'Limites régionales'
  ) %>%

  # ── Légende ─────────────────────────────────────────────────────────
  addLegend(
    pal      = pal_ds,
    values   = ~NAME_RS,
    title    = 'Région sanitaire',
    opacity  = 0.7,
    position = 'bottomright'
  ) %>%

  # ── Sélecteur de couches ───────────────────────────────────────────
  addLayersControl(
    baseGroups    = c('Gris (sobre)', 'OpenStreetMap', 'Satellite', 'CartoDB clair'),
    overlayGroups = c('Districts sanitaires', 'Limites régionales'),
    options       = layersControlOptions(collapsed = FALSE)
  ) %>%

  # ── Outils supplémentaires ─────────────────────────────────────────
  addSearchOSM() %>%       # Barre de recherche de lieux
  addResetMapButton() %>%  # Bouton de réinitialisation du zoom
  addMiniMap(              # Mini-carte de localisation
    tiles    = 'Esri.WorldGrayCanvas',
    position = 'bottomleft',
    toggleDisplay = TRUE
  ) %>%

  # ── Vue initiale centrée sur le Cameroun ──────────────────────────
  setView(lng = 12.35, lat = 5.96, zoom = 6)

# Afficher dans RStudio
carte_leaflet_ds

# Sauvegarder en HTML autonome
htmlwidgets::saveWidget(
  carte_leaflet_ds,
  file     = paste0(dir_out, 'outputs/carte_districts_sante_interactive.html'),
  selfcontained = TRUE   # HTML complet sans dépendances externes
)
cat("Carte interactive sauvegardee en HTML\n")

#3.2 Carte Leaflet choroplèthe — Population avec gradient de couleurs

# ── MODULE 3.2 : Choroplèthe Leaflet — Population par département ─────

# Joindre population avec département
dep_pop_leaf <- dep %>%
  left_join(pop_dep, by = c('NAME_2' = 'admin2_name'))

# Palette continue (NumericInput -> couleur)
pal_pop <- colorNumeric(
  palette  = 'YlOrRd',
  domain   = dep_pop_leaf$pop_totale,
  na.color = '#CCCCCC'
)

# Popup HTML détaillé
dep_pop_leaf <- dep_pop_leaf %>%
  mutate(
    popup_pop = paste0(
      '<div style="font-family:Arial;padding:5px">',
      '<h4 style="margin:0;color:#1F4E79">', NAME_2, '</h4>',
      '<hr style="margin:4px 0">',
      '<b>Région :</b> ',    NAME_1,   '<br>',
      '<b>Population :</b> ', format(pop_totale, big.mark=' '), ' hab.<br>',
      '</div>'
    )
  )

carte_pop_leaflet <- leaflet(dep_pop_leaf) %>%
  addProviderTiles('CartoDB.Positron') %>%
  addPolygons(
    fillColor   = ~pal_pop(pop_totale),
    fillOpacity = 0.7,
    color       = 'white', weight = 0.8,
    popup       = ~popup_pop,
    highlight   = highlightOptions(weight=3, color='#555', fillOpacity=0.9,
                                   bringToFront=TRUE),
    label       = ~paste0(NAME_2, ' : ', format(pop_totale, big.mark=' '), ' hab.')
  ) %>%
  addPolygons(
    data  = rgn, fill = FALSE,
    color = '#2E75B6', weight = 2, opacity = 1,
    label = ~NAME_1
  ) %>%
  addLegend(
    pal      = pal_pop,
    values   = ~pop_totale,
    title    = 'Population',
    labFormat = labelFormat(big.mark = ' ', suffix = ' hab.'),
    position = 'bottomright'
  ) %>%
  addMiniMap(toggleDisplay = TRUE) %>%
  setView(lng = 12.35, lat = 5.96, zoom = 6)

carte_pop_leaflet

htmlwidgets::saveWidget(carte_pop_leaflet,
  paste0(dir_out, 'outputs/carte_population_interactive.html'),
  selfcontained = TRUE)

#3.3 Visualisation rapide avec mapview

# ── MODULE 3.3 : Exploration rapide avec mapview ──────────────────────

# mapview génère instantanément une carte interactive d'un objet sf
# C'est l'outil idéal pour EXPLORER les données avant de produire une carte

# Vue rapide des régions
mapview(rgn, zcol = 'NAME_1', legend = TRUE,
        map.types = 'CartoDB.Positron')

# Vue rapide des points DHS colorés par milieu
mapview(dhs_pts, zcol = 'URBAN_RURA',
        col.regions = c('R' = 'green', 'U' = 'red'),
        alpha.regions = 0.8,
        map.types = 'OpenStreetMap')

# Superposition de plusieurs couches mapview (+)
vue_multi <- mapview(ds, zcol = 'NAME_RS', alpha.regions = 0.3,
                     layer.name = 'Districts sanitaires') +
             mapview(rgn, alpha.regions = 0, color = '#1F4E79', lwd = 2,
                     layer.name = 'Régions') +
             mapview(dhs_pts, zcol = 'URBAN_RURA', cex = 3,
                     layer.name = 'Clusters DHS')
vue_multi

# Sauvegarder mapview en HTML
mapshot(vue_multi,
        url  = paste0(dir_out, 'outputs/vue_multicouches_mapview.html'),
        file = paste0(dir_out, 'outputs/vue_multicouches_mapview.png'))
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
RColorBrewer::display.brewer.pal(7, 'YlOrRd')  # Jaune-Orange-Rouge
RColorBrewer::display.brewer.pal(7, 'Blues')   # Nuances de bleu
RColorBrewer::display.brewer.pal(7, 'Greens')  # Nuances de vert

# viridis : perceptivement uniforme, daltonien-friendly
scales::show_col(viridis::viridis(10))
scales::show_col(viridis::magma(10))
scales::show_col(viridis::plasma(10))

# 2. PALETTES DIVERGENTES (variable avec centre neutre : écart à la moyenne)
#    Usage : données qui ont un point zéro central (excédent/déficit, différence)
RColorBrewer::display.brewer.pal(7, 'RdYlGn')  # Rouge -> Vert (négatif->positif)
RColorBrewer::display.brewer.pal(7, 'BrBG')    # Brun -> Bleu-Vert
RColorBrewer::display.brewer.pal(7, 'PuOr')    # Violet -> Orange

# 3. PALETTES QUALITATIVES (variable catégorielle)
#    Usage : régions, milieu, type d'établissement
RColorBrewer::display.brewer.pal(8, 'Set2')    # Couleurs douces
RColorBrewer::display.brewer.pal(8, 'Dark2')   # Couleurs sombres
RColorBrewer::display.brewer.pal(10, 'Paired') # Couleurs par paires

# PALETTES PERSONNALISÉES CAMEROUN
# Couleurs officielles du drapeau camerounais
vert_cam   <- '#007A5E'   # Vert
rouge_cam  <- '#CE1126'   # Rouge
jaune_cam  <- '#FCD116'   # Jaune

# Palette bicolore pour cartes à 2 catégories (Urbain / Rural)
c('#2E86AB', '#E84855')  # Bleu = Urbain, Rouge = Rural

# Afficher les palettes disponibles dans RColorBrewer
RColorBrewer::display.brewer.all()

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
print(tc)
cat('Résolution spatiale :', res(tc), 'mètres\n')
cat('Système de coordonnées :', crs(tc, describe=TRUE)$name, '\n')
cat('Emprise géographique :\n')
print(ext(tc))

# Reprojeter en WGS84 si nécessaire
if (!is.na(crs(tc)) && !grepl('4326', crs(tc, describe=TRUE)$code)) {
  tc_wgs84 <- project(tc, 'EPSG:4326')
} else {
  tc_wgs84 <- tc
}

# Afficher l'image True Color
plotRGB(
  tc_wgs84,
  r = 1, g = 2, b = 3,    # Canaux R, G, B
  stretch = 'lin',          # Étirement linéaire pour améliorer le contraste
  main = 'Image Sentinel-2 True Color — Cameroun (26 juin 2026)',
  axes = TRUE
)

# Superposer les frontières administratives
plot(st_geometry(rgn), add = TRUE, col = NA, border = 'white', lwd = 1.5)
plot(st_geometry(dep), add = TRUE, col = NA, border = 'white', lwd = 0.5)

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
if (!compareGeom(nir, swir, stopOnError = FALSE)) {
  swir_res <- resample(swir, nir, method = 'bilinear')
} else {
  swir_res <- swir
}

# Reprojeter en WGS84
nir_wgs  <- project(nir,      'EPSG:4326')
swir_wgs <- project(swir_res, 'EPSG:4326')

# Calcul du NDMI
ndmi <- (nir_wgs - swir_wgs) / (nir_wgs + swir_wgs)
names(ndmi) <- 'NDMI'

# Limiter aux valeurs valides [-1, 1]
ndmi[ndmi < -1] <- -1
ndmi[ndmi > 1]  <- 1

# Afficher le NDMI
plot(ndmi,
     main   = 'NDMI — Indice d\'humidité de la végétation\nSentinel-2, 26 juin 2026',
     col    = rev(terrain.colors(100)),   # Vert = humide, Jaune/Rouge = sec
     axes   = TRUE
)
plot(st_geometry(rgn), add = TRUE, col = NA, border = 'white', lwd = 1.2)

# Sauvegarder le raster NDMI
writeRaster(ndmi,
            filename  = paste0(dir_out, 'outputs/ndmi_cameroun_26juin2026.tif'),
            overwrite = TRUE)

# Statistiques du NDMI
stats_ndmi <- global(ndmi, fun = c('mean','sd','min','max'), na.rm = TRUE)
cat('\nStatistiques NDMI :\n')
print(round(stats_ndmi, 3))
cat('\nInterprétation :\n')
cat('NDMI > 0.2  : végétation très bien hydratée (forêt dense)\n')
cat('NDMI 0-0.2  : végétation modérément hydratée\n')
cat('NDMI -0.2-0 : végétation stressée ou savane\n')
cat('NDMI < -0.2 : sol nu, zones urbaines, eau\n')

#4.2.3 Carte NDMI intégrée avec ggplot2

# ── SEQUENCE 4.2.3 : Intégration NDMI dans une carte ggplot2 ───────────

library(stars)    # Pour convertir terra en stars (compatible ggplot2)

# Convertir le raster terra en objet stars pour ggplot2
ndmi_stars <- st_as_stars(ndmi)

# Carte NDMI avec ggplot2
carte_ndmi <- ggplot() +

  # Couche raster NDMI
  geom_stars(data = ndmi_stars, aes(fill = NDMI)) +

  # Palette divergente : Brun (sec) -> Vert (humide)
  scale_fill_gradient2(
    low      = '#8B4513',   # Brun sombre = sec
    mid      = '#FFFF99',   # Jaune = neutre
    high     = '#1A5E20',   # Vert foncé = humide
    midpoint = 0,
    name     = 'NDMI',
    limits   = c(-1, 1),
    labels   = label_number(accuracy = 0.1),
    na.value = 'transparent'
  ) +

  # Contours des régions par-dessus
  geom_sf(data = rgn, fill = NA, color = 'white', linewidth = 0.8) +
  geom_sf(data = dep, fill = NA, color = 'white', linewidth = 0.3, alpha = 0.5) +

  # Noms des régions
  geom_sf_text(data = rgn, aes(label = NAME_1),
               size = 2.8, color = 'white', fontface = 'bold',
               check_overlap = TRUE) +

  annotation_scale(location = 'bl', text_cex = 0.8) +
  annotation_north_arrow(location = 'tr', style = north_arrow_minimal()) +

  labs(
    title    = 'Humidité de la végétation au Cameroun',
    subtitle = 'NDMI — Normalized Difference Moisture Index (Sentinel-2, 26 juin 2026)',
    caption  = 'Source : ESA Copernicus / Sentinel-2 L2A — Traitement : R/terra',
    x = NULL, y = NULL
  ) +

  theme_minimal() +
  theme(
    plot.title    = element_text(face = 'bold', size = 13, color = '#1F4E79'),
    plot.subtitle = element_text(size = 9, color = 'grey40'),
    plot.caption  = element_text(size = 7, color = 'grey50'),
    panel.grid    = element_blank(),
    plot.background = element_rect(fill = 'white', color = NA)
  ) +
  coord_sf(xlim = c(8.4, 16.1), ylim = c(1.7, 13.1))

ggsave(paste0(dir_out, 'outputs/carte_ndmi_sentinel2.png'), carte_ndmi,
       width = 20, height = 22, units = 'cm', dpi = 300, bg = 'white')

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
panneau_patchwork <- (carte_mortalite | carte_conso) /
                     (carte_pts       | carte_ndmi)  +
  plot_annotation(
    title    = 'Tableau de bord cartographique — Cameroun 2022-2026',
    subtitle = 'Sources : DHS 2018, ECAM5 2022, FAO FIES, Sentinel-2 2026',
    caption  = 'INS Cameroun — Division des Etudes Démographiques',
    theme    = theme(
      plot.title    = element_text(size = 16, face = 'bold', color = '#1F4E79', hjust = 0),
      plot.subtitle = element_text(size = 10, color = 'grey40'),
      plot.caption  = element_text(size = 8, color = 'grey50')
    )
  )

ggsave(
  filename = paste0(dir_out, 'outputs/tableau_bord_cartographique.png'),
  plot     = panneau_patchwork,
  width    = 42,   # A3 paysage (42 x 29.7 cm)
  height   = 30,
  units    = 'cm',
  dpi      = 300,
  bg       = 'white'
)

# ── Méthode cowplot (plus fine, permet texte libre et images) ─────────
panneau_cowplot <- plot_grid(
  carte_mortalite, carte_conso,
  nrow   = 1,
  labels = c('A. Mortalité infantile', 'B. Consommation ménages'),
  label_size   = 10,
  label_colour = '#1F4E79',
  label_fontface = 'bold'
)

# Ajouter un titre commun
titre_commun <- ggdraw() +
  draw_label(
    'Indicateurs socio-démographiques — Cameroun (DHS 2018 & ECAM5 2022)',
    fontface  = 'bold',
    size      = 13,
    color     = '#1F4E79',
    x = 0.5, y = 0.5, hjust = 0.5
  )

panneau_final <- plot_grid(
  titre_commun,
  panneau_cowplot,
  ncol         = 1,
  rel_heights  = c(0.07, 0.93)  # 7% titre, 93% cartes
)

ggsave(
  filename = paste0(dir_out, 'outputs/panneau_bicartes_dhs_ecam5.png'),
  plot     = panneau_final,
  width = 40, height = 22, units = 'cm', dpi = 300, bg = 'white'
)

#5.2 Exportation dans tous les formats
# ── MODULE 5.2 : Exportation dans tous les formats professionnels ─────

# GGPLOT2 — Formats raster haute résolution
ggsave(paste0(dir_out, 'outputs/carte.png'),
       plot = carte_mortalite, width=20, height=22, units='cm', dpi=300, bg='white')

ggsave(paste0(dir_out, 'carte.jpg'),
       plot = carte_mortalite, width=20, height=22, units='cm', dpi=300,
       quality=95, bg='white')

# GGPLOT2 — Format vectoriel (pour impression sans perte de qualité)
ggsave(paste0(dir_out, 'outputs/carte.pdf'),
       plot = carte_mortalite, width=20, height=22, units='cm', device='pdf')

ggsave(paste0(dir_out, 'carte.svg'),
       plot = carte_mortalite, width=20, height=22, units='cm', device='svg')

# Conseil SVG : Format idéal pour les publications web, éditable sous Inkscape

# TMAP — Tous les formats
tmap_save(carte_fies_tmap,
          filename = paste0(dir_out, 'outputs/carte_fies.png'),
          width=20, height=22, dpi=300, units='cm')

tmap_save(carte_fies_tmap,
          filename = paste0(dir_out, 'outputs/carte_fies.pdf'),
          width=20, height=22, units='cm')

# TMAP — Mode interactif HTML
tmap_mode('view')
carte_fies_interactive <- tm_shape(rgn_fies) +
  tm_polygons(col = 'fies_severe', palette = '-RdYlGn', popup.vars = TRUE) +
  tm_layout(title = 'Insécurité alimentaire — Cameroun')
tmap_save(carte_fies_interactive,
          filename = paste0(dir_out, 'outputs/carte_fies_interactive.html'))
tmap_mode('plot')

# RASTER TERRA
writeRaster(ndmi,
            filename  = paste0(dir_out, 'outputs/ndmi_cameroun.tif'),
            overwrite = TRUE)

# PNG depuis terra
png(paste0(dir_out, 'outputs/ndmi_direct.png'), width=2400, height=2600, res=300)
plot(ndmi, main='NDMI Cameroun', col=rev(terrain.colors(100)))
plot(st_geometry(rgn), add=TRUE, col=NA, border='white', lwd=1.5)
dev.off()

cat('Toutes les cartes ont ete exportees dans :', dir_out, '\n')

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
dep_densité <- dep %>%
  left_join(pop_dep, by = c('NAME_2' = 'admin2_name')) %>%
  mutate(
    # Calculer l'aire en km²
    aire_km2   = as.numeric(st_area(.)) / 1e6,
    densite    = pop_totale / aire_km2
  )

carte_institutionnelle <- ggplot() +

  # 1. Fond océanique / géographique
  theme_minimal(base_size = 10) +
  theme(
    panel.background  = element_rect(fill = '#D6EAF8', color = NA),
    plot.background   = element_rect(fill = 'white',   color = NA),
    panel.border      = element_rect(fill = NA, color = '#2E75B6', linewidth = 1.2),
    panel.grid        = element_blank(),
    plot.title        = element_text(face='bold', size=14, color='#1F4E79', hjust=0),
    plot.subtitle     = element_text(size=9, color='grey30', hjust=0, margin=margin(b=8)),
    plot.caption      = element_text(size=7, color='grey50', hjust=1, margin=margin(t=6)),
    legend.position   = 'right',
    legend.key.height = unit(1.8, 'cm'),
    legend.title      = element_text(face='bold', size=9),
    plot.margin       = margin(10, 10, 10, 10)
  ) +

  # 2. Pays limitrophes
  geom_sf(data = lim, fill='#F0EDE6', color='#999999', linewidth=0.4) +

  # 3. Choroplèthe — densité de population
  geom_sf(data = dep_densité, aes(fill = densite),
          color = 'white', linewidth = 0.4) +

  # 4. Palette viridis
  scale_fill_viridis_c(
    option    = 'inferno', direction = -1,
    name      = 'Densité\n(hab./km²)',
    trans     = 'log10',
    breaks    = c(1, 10, 50, 100, 500),
    labels    = label_number(accuracy=1),
    na.value  = 'grey80'
  ) +

  # 5. Contours régionaux épais
  geom_sf(data = rgn, fill=NA, color='white', linewidth=1.2) +

  # 6. Noms des régions
  geom_sf_text(data = rgn, aes(label=NAME_1),
               size=2.6, color='white', fontface='bold', check_overlap=TRUE) +

  # 7. Rose des vents + échelle
  annotation_north_arrow(
    location='tl', style=north_arrow_fancy_orienteering(fill=c('white','grey20')),
    pad_x=unit(0.15,'in'), pad_y=unit(0.15,'in')
  ) +
  annotation_scale(location='bl', width_hint=0.25,
                   bar_cols=c('grey20','white'), text_col='grey20') +

  # 8. Coordonnées géographiques sur les axes
  scale_x_continuous(breaks=seq(8,16,2), labels=function(x) paste0(x,'°E')) +
  scale_y_continuous(breaks=seq(2,13,2), labels=function(y) paste0(y,'°N')) +

  # 9. Titres professionnels
  labs(
    title    = 'Densité de population par département — République du Cameroun',
    subtitle = 'Nombre d\'habitants au km² | Données WorldPop / OCHA 2020 | Projection : WGS84 (EPSG:4326)',
    caption  = paste0(
      'Sources : CMR_population_v1_0_admin_level2 (WorldPop/OCHA) | ',
      'Fond : gadm41_CMR | Réalisation : INS Cameroun, Division Cartographie, Juin 2026'
    ),
    x = 'Longitude (°Est)',  y = 'Latitude (°Nord)'
  ) +

  coord_sf(xlim=c(8.4, 16.1), ylim=c(1.7, 13.1), expand=FALSE)

# Exporter à 300 dpi pour rapport officiel
ggsave(
  filename = paste0(dir_out, 'outputs/carte_densite_pop_officielle.png'),
  plot     = carte_institutionnelle,
  width    = 24, height = 26, units = 'cm',
  dpi      = 300, bg = 'white'
)

ggsave(
  filename = paste0(dir_out, 'outputs/carte_densite_pop_officielle.pdf'),
  plot     = carte_institutionnelle,
  width    = 24, height = 26, units = 'cm'
)

cat("Carte institutionnelle exportee en PNG et PDF\n")

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
geom_sf(data, aes(fill=var))         # Polygones avec couleur selon variable
geom_sf_text(data, aes(label=var))   # Étiquettes texte
scale_fill_distiller(palette, dir)   # Palette RColorBrewer continue
scale_fill_viridis_c(option)         # Palette viridis continue
scale_fill_manual(values)            # Couleurs manuelles
annotation_scale()                  # Barre d'échelle
annotation_north_arrow()            # Rose des vents
coord_sf(xlim, ylim)                # Emprise géographique
ggsave(path, plot, width, height, dpi) # Export

# ── tmap ─────────────────────────────────────────────────────────────
tmap_mode('plot')/'view'             # Mode statique / interactif
tm_shape(data)                       # Déclarer les données
tm_polygons(col, palette, style, n)  # Polygones choroplèthes
tm_dots(col, size, palette)          # Points colorés
tm_bubbles(size, col, scale)         # Symboles proportionnels
tm_text(var, size, col)              # Étiquettes
tm_borders(col, lwd)                 # Bordures seules
tm_compass(position, type)           # Rose des vents
tm_scale_bar(breaks, position)       # Barre d'échelle
tm_layout(title, legend.outside)     # Mise en page
tm_credits(text, position)           # Crédits / source
tmap_save(carte, filename, dpi)      # Export

# ── Leaflet ──────────────────────────────────────────────────────────
leaflet(data)                        # Initialiser
addProviderTiles(provider)           # Fond de carte
addPolygons(fillColor, popup, label) # Polygones
addLegend(pal, values, title)        # Légende
addLayersControl(baseGroups, ...)    # Sélecteur de couches
addMiniMap()                         # Mini-carte
setView(lng, lat, zoom)              # Vue initiale
htmlwidgets::saveWidget(carte, file) # Export HTML

# ── terra (Sentinel-2) ───────────────────────────────────────────────
rast(chemin)                         # Lire un raster
project(r, 'EPSG:4326')             # Reprojeter
resample(r1, r2, method)             # Rééchantillonner
(nir - swir) / (nir + swir)          # Calcul d'indice (NDMI)
plotRGB(r, r, g, b, stretch)         # Image couleur
writeRaster(r, filename)             # Sauvegarder raster

# ── Composition ──────────────────────────────────────────────────────
(carte1 | carte2) / (carte3 | carte4)  # patchwork
plot_grid(c1, c2, nrow, labels)         # cowplot
plot_annotation(title, subtitle)        # titre commun patchwork
