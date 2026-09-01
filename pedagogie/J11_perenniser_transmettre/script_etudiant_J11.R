## ============================================================================
## SCRIPT ÉTUDIANT — J11 · Pérenniser et transmettre : la formation ne s'arrête pas ici
## Atelier IFORD × GDSG 2026 · Vendredi 7 août 2026
## ----------------------------------------------------------------------------
## Ce script reprend la trame de la démonstration du formateur : les commentaires
## et les lectures de données sont fournis, le reste du code est à écrire par vous,
## sous la supervision du formateur. Travaillez depuis la racine du projet
## (ouvrir atelier-r-spatial-iford-2026.Rproj) ; les chemins sont relatifs.
## Solution complète : script_etudiant_J11_corrige.R
## ============================================================================

## ============================================================================
## [PREPARATION ATELIER - GDSG, juillet 2026]
## Ce script s'execute depuis la RACINE du projet RStudio :
##   1. Ouvrir atelier-r-spatial-iford-2026.Rproj (les chemins sont relatifs).
##   2. Donnees : datasets/ (fournies avec ce dossier ; chemins relatifs)
##   3. Les sorties de ce script sont ecrites dans outputs/.
## NB : fichiers references mais PAS ENCORE dans le Drive (voir README donnees) :
##      - datasets/FIES_Cameroun.csv
for (d in c("outputs/indices", "outputs/metadata", "outputs/tableaux"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
## ============================================================================

################################################################################
# ATELIER IFORD - DONNÉES SPATIALES, ANALYSE ET MANIPULATION DANS R
# Jour 10 : Flux de travail reproductibles
# Script complet 
# Author: Marcial TEDA
################################################################################

#Séquence 1 — Introduction : La reproductibilité en science des données géospatiales
# Voir les explications élaborer sur Word

#Séquence 2 — R Markdown : créer des rapports dynamiques avec données ECAM5

#2.1 Architecture d'un fichier R Markdown
#Un fichier R Markdown (.Rmd) est composé de trois éléments fondamentaux : l'en-tête YAML (métadonnées), les chunks R (blocs de code exécutable) et le texte Markdown (narration). Quand vous cliquez sur 'Knit', R exécute tous les chunks dans l'ordre, injecte les sorties (tableaux, graphiques, valeurs) dans le texte, puis convertit le tout via Pandoc vers le format cible (Word, HTML, PDF).

#Concept clé : le flux R Markdown
#Fichier .Rmd → [knitr exécute les chunks R] → Fichier .md intermédiaire → [Pandoc convertit] → Word / HTML / PDF

#2.2 Créer votre premier rapport ECAM5
#Ouvrez RStudio → File → New File → R Markdown. Copiez le code ci-dessous dans votre fichier rapport_ecam5.Rmd :

# ---
# title: "Analyse des Conditions de Vie des Ménages — ECAM5 2022"
# subtitle: "Rapport de synthèse régionale"
# author: "Institut National de la Statistique du Cameroun"
# date: "`r format(Sys.Date(), '%d %B %Y')`"
# output:
#   word_document:
#     toc: true
#     toc_depth: 3
#     reference_docx: modele_ins.docx  # Template Word personnalisé
#   html_document:
#     toc: true
#     toc_float: true
#     theme: flatly
#     code_folding: hide
# bibliography: references.bib
# lang: fr
# ---

# ```{r setup, include=FALSE}
# Options globales — s'appliquent à tous les chunks suivants
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Chargement des packages
library(haven)        # Lire les fichiers .dta (Stata)
library(tidyverse)    # Manipulation + visualisation de données
library(sf)           # Données spatiales vectorielles
library(kableExtra)   # Tableaux HTML/Word améliorés
library(flextable)    # Tableaux Word professionnels
library(janitor)      # Nettoyage des noms de variables
library(labelled)     # Gestion des labels Stata dans R
library(scales)       # Formatage des axes ggplot2
# ```

#2.3 Chargement et exploration initiale des données ECAM5
#L'enquête ECAM5 (Enquête Camerounaise Auprès des Ménages, 5ème édition, 2022) couvre l'ensemble du territoire national. Elle contient des modules sur la consommation des ménages, l'accès aux services de base, l'emploi et la pauvreté. Le fichier ecam5.dta est au format Stata et conserve les labels de variables.

# ```{r chargement-ecam5}
# ── Chargement des données ECAM5 ──────────────────────────────────────
# Le fichier .dta conserve les labels Stata — haven les lit correctement
ecam5 <- haven::read_dta("datasets/ecam5.dta")

# Aperçu de la structure
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Extraction d'un tableau de présentation
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# ```

#2.4 Intégrer des statistiques inline et des graphiques
#La puissance de R Markdown réside dans l'injection de valeurs calculées directement dans le texte narratif, éliminant tout risque d'erreur de 

# ```{r calculs-inline}
# Calculs préalables stockés dans des objets R
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# ```

## Utilisation dans le texte Markdown :
# Selon l'ECAM5 (2022), le taux de pauvreté national s'établit à
# `r round(taux_pauvrete_nat, 1)`% de la population. La région la
# plus touchée est `r region_plus_pauvre`.

# ```{r graphique-pauvrete-region, fig.cap="Taux de pauvreté par région (ECAM5, 2022)"}
# Graphique en barres horizontales — taux de pauvreté régional
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# ```

#2.5 Cartographie inline avec les données gadm41_CMR et ECAM5
#Il est possible d'intégrer des cartes choroplèthes directement dans le rapport R Markdown. La carte est générée par R à chaque compilation, garantissant qu'elle reflète toujours les données les plus récentes.


# ```{r carte-pauvrete, fig.cap="Carte du taux de pauvreté par région — ECAM5 2022", fig.width=9, fig.height=7}
library(sf)

# Chargement du fond de carte administratif
cmr_reg <- st_read("datasets/gadm41_CMR_1.shp", quiet = TRUE)

# Calcul du taux de pauvreté par région
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Jointure spatiale — harmoniser les noms de régions
# Adapter les noms selon les données réelles
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Carte choroplèthe
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# ```
#Séquence 3 — Quarto : la génération suivante des documents reproductibles

#3.1 Quarto vs R Markdown — Comprendre les différences
#Quarto est le successeur officiel de R Markdown, développé par Posit (ex-RStudio). Il supporte nativement R, Python, Julia et Observable JS dans le même document. La syntaxe est légèrement différente mais la philosophie est identique.

#Caractéristique	R Markdown	Quarto
#Fichier	.Rmd	.qmd
#Langages supportés	R (principalement)	R, Python, Julia, Observable JS
#Options de chunk	Dans l'en-tête ```{r option=val}	YAML inline : #| option: val
#Formats de sortie	Word, HTML, PDF, Slides	Idem + sites web, livres, dashboards
#Installation	Package R knitr	Logiciel indépendant (quarto.org)
#Recommandé pour	Projets R purs existants	Nouveaux projets, multi-langages

#3.2 Structure d'un fichier Quarto
#Créez le fichier rapport_eesi3.qmd pour analyser l'enquête sur l'emploi et le secteur informel (EESI3) :

# ---
# title: "Emploi et Secteur Informel au Cameroun — EESI3"
# author:
#   - name: "Département des Statistiques Économiques"
#     affiliation: "Institut National de la Statistique — Cameroun"
# date: today
# date-format: "DD MMMM YYYY"
# lang: fr
# format:
#   html:
#     toc: true
#     toc-depth: 4
#     code-fold: true
#     theme: cosmo
#     embed-resources: true  # Document HTML autonome (pas de dépendances externes)
#   docx:
#     toc: true
#     reference-doc: template_ins.docx
# execute:
#   echo: true
#   warning: false
#   message: false
#   cache: true   # Mettre en cache les calculs lourds
# ---

# ```{r}
#| label: setup
#| include: false

library(haven)
library(tidyverse)
library(sf)
library(flextable)
library(janitor)
library(labelled)

# Chargement EESI3 — Enquête sur l'Emploi et le Secteur Informel
eesi3 <- haven::read_dta("datasets/eesi3.dta") |>
  janitor::clean_names()  # Noms de variables en minuscules sans espaces

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# ```

#3.3 Analyse du secteur informel avec EESI3
#L'EESI3 permet de distinguer les travailleurs du secteur formel et informel selon des critères de protection sociale, de contrat de travail et de couverture fiscale. Le code suivant produit une analyse régionale complète.

# ```{r}
#| label: secteur-informel
#| fig-cap: "Part du secteur informel dans l'emploi — EESI3"
#| fig-width: 9
#| fig-height: 6

# Calcul du taux d'informalité par région et sexe
# (adapter les noms de variables selon le vrai codebook EESI3)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Visualisation
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# ```

#3.4 Paramétrer un rapport Quarto
#Les rapports paramétrés permettent de générer automatiquement un rapport différent pour chaque région avec le même fichier .qmd. C'est une fonctionnalité clé pour les INS qui produisent des rapports régionaux.


# ── En-tête YAML avec paramètres ─────────────────────────────────────────
# ---
# params:
#   region_cible: "Centre"
#   annee: 2022
# ---

# ```{r}
#| label: filtre-region

# Le paramètre est accessible via params$region_cible
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# ```

# ── Compilation paramétrée depuis R (dans la console RStudio) ────────────

# Générer les rapports pour toutes les régions
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

#Exercice pratique 3.4
#Créez un rapport Quarto paramétré pour l'analyse de la pauvreté par région (données ECAM5). Le rapport doit générer automatiquement :
#Un titre personnalisé avec le nom de la région
#Un tableau des indicateurs de pauvreté pour cette région uniquement
#Une carte du district sanitaire correspondant (DS.geojson)
#Un graphique de comparaison avec la moyenne nationale
#Utilisez purrr::walk() pour générer les 10 rapports régionaux en une seule commande.


#Module 4 — Automatisation et traitement par lots de données d'enquêtes

#4.1 Le principe DRY — Don't Repeat Yourself
#Toute analyse qui doit être répétée (même code, paramètres différents) doit être transformée en fonction. En INS, cela concerne typiquement : l'analyse par région, l'analyse par quintile de consommation, l'analyse par cycle d'enquête, etc.
#4.2 Créer des fonctions d'analyse réutilisables

## ── Fonctions d'analyse pour données d'enquêtes ──────────────────────────

# Fonction 1 : Calculer les principaux indicateurs de bien-être
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Fonction 2 : Exporter un tableau flextable vers Word
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................


#4.3 Traitement par lots avec purrr
#Le package purrr permet d'appliquer une fonction à une liste d'objets (régions, groupes, fichiers) sans boucle for explicite. C'est plus lisible, plus sûr et plus performant.

# ── Analyse multidimensionnelle par lots — ECAM5 ─────────────────────────

library(purrr)
library(fs)     # Gestion de fichiers (fs::dir_create, fs::path)

# Créer le dossier de sortie
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Définir les groupes d'analyse
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Appliquer la fonction à chaque groupe et exporter
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

#4.4 Intégration des données FIES (FAO) pour la sécurité alimentaire
#Les données FIES (Food Insecurity Experience Scale) de la FAO pour le Cameroun permettent de mesurer l'insécurité alimentaire à différents niveaux de sévérité. Voici comment les intégrer dans un pipeline automatisé.

# ── Pipeline FIES FAO — Sécurité alimentaire ────────────────────────────

# Chargement des données FIES
# Le fichier FIES contient les réponses aux 8 questions de l'échelle
fies <- readr::read_csv("datasets/FIES_Cameroun.csv", locale = locale(encoding = "UTF-8"))

# Les 8 items FIES (nommés fies_1 à fies_8 dans le fichier)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Calcul du score FIES brut (somme des réponses positives)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Taux d'insécurité alimentaire par région
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Export automatique
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................


#Module 5 — Traitement par lots de données spatiales : images Sentinel-2

#5.1 Présentation des bandes Sentinel-2 disponibles
#Nous disposons des images Sentinel-2 Level-2A du 26 juin 2026 pour le Cameroun. Ces images atmosphériquement corrigées sont prêtes pour l'analyse de la végétation et de l'occupation des sols.
# Pour la suite, voir fichier Word

#5.2 Pipeline de calcul d'indices végétation automatisé
#Le NDVI (Normalized Difference Vegetation Index) et le NDWI (Normalized Difference Water Index) sont les deux indices les plus utilisés en télédétection agricole et environnementale. Nous allons les calculer automatiquement et exporter les cartes.

# ── Calcul automatisé d'indices spectraux — Sentinel-2 ───────────────────

library(terra)   # Traitement raster (successeur de raster)
library(sf)
library(tidyverse)
library(fs)

# Répertoire des images Sentinel-2
rep_sentinel <- "data/sentinel2/"
prefix_date  <- "2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_"

# ── Chargement des bandes ────────────────────────────────────────────────
charger_bande <- function(bande) {
  fichier <- paste0(rep_sentinel, prefix_date, bande, "_(Raw).tiff")
  if (!file.exists(fichier)) stop("Fichier introuvable : ", fichier)
  terra::rast(fichier)
}

# Charger toutes les bandes
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ── Définition et calcul des indices spectraux ───────────────────────────

# Dictionnaire des indices à calculer
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Calcul automatisé de tous les indices
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

#5.3 Extraction zonale par district sanitaire
#L'extraction zonale permet d'obtenir les statistiques (moyenne, écart-type, min, max) d'un indice spectral pour chaque unité géographique (district sanitaire, région, département). C'est une opération fondamentale en analyse spatiale pour la santé publique.

# ── Extraction zonale NDVI par district sanitaire ────────────────────────

# Chargement des districts sanitaires
districts <- sf::st_read("datasets/DS.geojson", quiet = TRUE)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Vérification et harmonisation des projections
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Extraction zonale pour chaque indice
extraction_zonale <- function(r_indice, vecteur, id_col = "NOM_DS") {
  # Conversion sf → SpatVector (terra)
  vect_terra <- terra::vect(vecteur)

  # Extraction (fun = liste des statistiques voulues)
  stats <- terra::extract(
    r_indice, vect_terra,
    fun = function(x) c(
      mean = mean(x, na.rm = TRUE),
      sd   = sd(x,   na.rm = TRUE),
      min  = min(x,  na.rm = TRUE),
      max  = max(x,  na.rm = TRUE),
      p25  = quantile(x, 0.25, na.rm = TRUE),
      p75  = quantile(x, 0.75, na.rm = TRUE)
    ),
    bind = TRUE  # Conserver les colonnes du vecteur
  )
  as.data.frame(stats)
}

# Application à tous les indices
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Export CSV
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Affichage des 5 districts avec le NDVI moyen le plus bas (stress végétatif)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

#5.4 Analyse croisée : NDVI × Données DHS (santé maternelle)
#Nous pouvons croiser les indices Sentinel-2 avec les données DHS (Demographic and Health Surveys) pour analyser les liens entre environnement végétal et indicateurs de santé.

# ── Croisement NDVI × DHS — Indicateurs de santé maternelle ─────────────

library(haven)  # Pour lire le fichier CMIR71FL.SAV (femmes DHS)

# Chargement des données DHS — module femmes
dhs_femmes <- haven::read_sav("datasets/CMIR71FL.SAV") |>
  janitor::clean_names()

# Variables d'intérêt :
# v024 = région, v005 = pondération, v201 = nb enfants nés vivants
# v212 = âge 1er accouchement, m15 = lieu de l'accouchement

# Extraction des coordonnées GPS (fichier CMGE71FL.shp)
dhs_gps <- sf::st_read("datasets/CMGE71FL.shp", quiet = TRUE)

# Extraction du NDVI aux points GPS des grappes DHS
ndvi_grappes <- terra::extract(
  rasters_indices$NDVI,
  terra::vect(dhs_gps),
  bind = TRUE
)

# Jointure avec les données femmes via l'identifiant de grappe
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Analyse : corrélation NDVI moyen de la grappe × CPN (consultations prénatales)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................


#Module 6 — Normes de publication : métadonnées et principes FAIR

#6.1 Les principes FAIR — Définition et enjeux
#Les principes FAIR ont été formalisés en 2016 dans la revue Scientific Data (Wilkinson et al., 2016). Ils constituent désormais le standard international pour la gestion et le partage des données de recherche et statist

#Principe	Signification	Traduction	Exigence concrète
#F	Findable	Trouvable	Identifiant unique (DOI/URI), métadonnées riches, indexé dans catalogue
#A	Accessible	Accessible	Protocole ouvert, authentification explicite, métadonnées persistantes même si données retirées
#I	Interoperable	Interopérable	Formats standards (CSV, GeoJSON, GeoTIFF), vocabulaires contrôlés, liens vers d'autres données
#R	Reusable	Réutilisable	Licence claire, provenance documentée, standards disciplinaires respectés

#6.2 Créer des métadonnées avec R
#En R, le package dataspice (rOpenSci) et les formats Dublin Core / ISO 19139 permettent de générer des métadonnées conformes aux standards internationaux directement depuis vos scripts.

# ── Génération de métadonnées FAIR avec R ────────────────────────────────

# Installation si nécessaire :
# install.packages("dataspice")  # Métadonnées pour datasets
# install.packages("geometa")    # Métadonnées géospatiales ISO 19115/19139

library(jsonlite)

# ── Approche 1 : Métadonnées JSON-LD (format web sémantique) ──────────────
# Compatible avec schema.org — indexé par Google Dataset Search

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Écriture du fichier de métadonnées
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ── Approche 2 : Métadonnées géospatiales ISO 19115 avec geometa ─────────

library(geometa)

# Création d'un objet de métadonnées ISO 19115
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Identifiant unique de la ressource
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Informations sur la ressource
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Étendue spatiale (bounding box du Cameroun)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Mots-clés thématiques
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Export XML ISO 19139
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

#6.3 Métadonnées pour les données spatiales Sentinel-2
#Les données raster issues de Sentinel-2 doivent être accompagnées de métadonnées précisant la date d'acquisition, le satellite, le niveau de traitement, la projection et les indices calculés.

# ── Métadonnées pour les indices Sentinel-2 exportés ─────────────────────

# Fonction générique de génération de métadonnées raster
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Générer et sauvegarder les métadonnées pour chaque indice
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

#6.4 Gestion de l'environnement R avec renv
#Un des obstacles majeurs à la reproductibilité est l'évolution des packages R. Le package renv crée un instantané (snapshot) de toutes les versions de packages utilisées dans un projet, permettant de les restaurer identiquement sur une autre machine ou dans six mois.

# ── Gestion d'environnement avec renv ────────────────────────────────────

# Installation (une seule fois)
# install.packages("renv")

library(renv)

# ── Initialisation d'un projet renv ───────────────────────────────────────
# À faire au début de tout nouveau projet
# renv::init()  # Crée renv.lock, .Rprofile, et renv/

# ── Enregistrer l'état actuel des packages ────────────────────────────────
# Après avoir installé/mis à jour des packages
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................

# Le fichier renv.lock contient :
# {
#   "R": { "Version": "4.4.0" },
#   "Packages": {
#     "sf": { "Version": "1.0-16", "Source": "CRAN" },
#     "terra": { "Version": "1.7-71", "Source": "CRAN" },
#     ...
#   }
# }

# ── Restaurer l'environnement (sur une autre machine) ─────────────────────
# Un collègue clone le projet et exécute :
# renv::restore()  # Installe exactement les mêmes versions

# ── Vérifier l'état de l'environnement ───────────────────────────────────
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J11_corrige.R)
# ..........................................................................
# Indique quels packages sont installés mais pas dans le lock, et vice versa


#Module 7 — Présentations de projets de groupe

#7.1 Organisation des groupes et thèmes
#Les participants se répartissent en 4 groupes de travail. Chaque groupe reçoit un jeu de données réel et un objectif d'analyse. Le livrable est un rapport Quarto (.qmd) qui produit un fichier Word (.docx) reproductible.

#Groupe	Thème	Données	Indicateurs attendus
#G1	Pauvreté et accès aux services de base	ecam5.dta + gadm41_CMR	Taux de pauvreté / région, carte choroplèthe, décomposition milieu
#G2	Sécurité alimentaire et insécurité	FIES FAO + ecam5.dta	Prévalence insécurité modérée/sévère, comparaison FIES × dépenses alimentaires ECAM5
#G3	Santé maternelle et environnement	CMIR71FL.SAV + NDVI + DS.geojson	CPN par district, corrélation NDVI × mortalité infantile, carte
#G4	Emploi informel et végétation	eesi3.dta + NDWI + gadm41_CMR	Informalité par région, carte NDWI, croisement emploi agricole × végétation


#7.2 Structure attendue du rapport de groupe
#Chaque groupe produit un fichier Quarto structuré comme suit. Le respect de cette structure garantit la reproductibilité et facilite l'évaluation.


# ── Structure type du rapport de groupe ─────────────────────────────────

# rapport_groupe_G1.qmd
# ├── 1. Introduction (contexte, questions de recherche, hypothèses)
# ├── 2. Sources de données (description, date, source, accès)
# ├── 3. Méthodologie
# │   ├── 3.1 Nettoyage et préparation des données
# │   ├── 3.2 Indicateurs construits et formules
# │   └── 3.3 Méthodes d'analyse spatiale utilisées
# ├── 4. Résultats
# │   ├── 4.1 Tableaux statistiques (flextable)
# │   ├── 4.2 Graphiques (ggplot2)
# │   └── 4.3 Cartes thématiques (ggplot2 + sf)
# ├── 5. Discussion et limites
# ├── 6. Conclusion et recommandations
# └── 7. Références et métadonnées

# ── Critères d'évaluation ─────────────────────────────────────────────────
# ✓ Le document se compile sans erreur (quarto render rapport.qmd)
# ✓ Toutes les données sont chargées depuis des chemins relatifs
# ✓ Aucune valeur codée en dur dans le texte (tout est calculé dynamiquement)
# ✓ Les cartes incluent une légende, un titre, une source
# ✓ Un fichier metadata.json accompagne le rapport


#7.3 Script de présentation avec Quarto Reveal.js
#Quarto permet également de créer des présentations reproductibles en format HTML (Reveal.js), qui sont directement projetables depuis le navigateur sans installation de PowerPoint.

# ── En-tête YAML pour présentation Quarto Reveal.js ─────────────────────
# ---
# title: "Analyse de la Pauvreté au Cameroun"
# subtitle: "Résultats ECAM5 2022 — Groupe 1"
# author: "Institut National de la Statistique"
# format:
#   revealjs:
#     theme: moon
#     slide-number: true
#     chalkboard: true
#     code-fold: true
#     transition: fade
#     footer: "Formation Géospatiale R — Jour 10"
# ---

# ## Slide 1 : Contexte
# La pauvreté au Cameroun affecte **37.5%** de la population selon l'ECAM5 2022.
# Elle présente une forte **dimension régionale** et **rurale/urbaine**.

# ## Slide 2 : Carte des résultats {.scrollable}
# ```{r}
#| echo: false
#| fig-width: 10
#| fig-height: 7
# [insérer ici le code de la carte choroplèthe]
# ```

#Séquence 8 — Synthèse : bonnes pratiques et feuille de route

#Voir fichier Word

#The End



