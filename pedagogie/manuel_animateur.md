# Manuel d'animation — Démos R Spatial IFORD × GDSG 2026

> **Pour Ramesesse Dzita, animateur unique des 10 jours.**
> Yaoundé, 27 juillet – 7 août 2026.
> Ce manuel ne décrit pas les concepts pédagogiques (voir les `.qmd` pour ça), il décrit **comment exécuter les démos en salle** sans surprise.

---

## 1. Avant l'atelier (J-30 à J-1)

### 1.1 Logiciels à installer sur la machine de démo

| Logiciel | Version | Source | Pourquoi |
|---|---|---|---|
| R | ≥ 4.4.0 | <https://cran.r-project.org/> | Moteur d'exécution |
| RStudio Desktop | ≥ 2024.04 | <https://posit.co/download/rstudio-desktop/> | IDE |
| Quarto CLI | ≥ 1.5 | <https://quarto.org/docs/get-started/> | Rendu des `.qmd` |
| Git | ≥ 2.40 | <https://git-scm.com/downloads> | Versioning + J10 |
| QGIS | ≥ 3.34 LTR | <https://qgis.org/fr/site/forusers/download.html> | Inspection visuelle rapide des fichiers |
| GDAL/GEOS/PROJ | via OS | `brew install gdal geos proj` (mac) · `apt install libgdal-dev libgeos-dev libproj-dev` (Linux) · binaires CRAN (Windows) | Dépendances de `sf` et `terra` |
| Docker Desktop (optionnel) | ≥ 4.30 | <https://www.docker.com/products/docker-desktop/> | Plan B environnement participants |

Sur la machine projecteur, installer aussi **un navigateur récent** (Firefox ou Chrome) pour ouvrir les sorties Leaflet/Quarto HTML.

### 1.2 Packages R à pré-installer

Lancer une seule fois :

```r
source("environnement_technique/install_packages.R")
source("environnement_technique/verification_setup.R")
```

`verification_setup.R` te dit ce qui manque. Refais tourner jusqu'à ce qu'il soit vert.

### 1.3 Datasets à télécharger en amont

Le wifi de l'IFORD peut être lent ou intermittent. Télécharge **avant** le J1 :

| Dataset | Taille | Lien | Destination locale |
|---|---|---|---|
| GADM Cameroun ADM0-3 | ~10 Mo | <https://gadm.org/download_country.html> (choisir CMR, GeoPackage) | `datasets/cameroun/admin_boundaries/gadm41_CMR.gpkg` |
| BUCREP RGPH4 ADM officiel | ? | Contact direct BUCREP via Pr Kuépié | `datasets/cameroun/admin_boundaries/CMR_adm3_BUCREP_2025.gpkg` |
| WorldPop 2020 100m CMR | ~150 Mo | <https://hub.worldpop.org/geodata/summary?id=49866> | `datasets/cameroun/population_grids/CMR_pop_WorldPop_top-down_100m_2020.tif` |
| WorldPop 2020 constrained | ~30 Mo | <https://hub.worldpop.org/geodata/summary?id=24784> | `datasets/cameroun/population_grids/CMR_pop_WorldPop_top-down_constrained_100m_2020.tif` |
| GHS-POP 2020 R2023A 3" | ~3 Go (global) | <https://human-settlement.emergency.copernicus.eu/download.php?ds=pop> | Découper sur CMR → `CMR_pop_GHSL_R2023A_100m_2020.tif` |
| Meta HRSL CMR 2018 | ~50 Mo | <https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates> | `datasets/cameroun/population_grids/CMR_HRSL_Meta_30m_2018.tif` (convertir depuis CSV ou GeoTIFF selon le format publié) |
| EDS-MICS CMR 2018 clusters GPS | ~5 Mo | <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm> (inscription requise, projet à soumettre 24-48h avant) | `datasets/cameroun/dhs_mics/CMGE71FL.shp` |
| EDS-MICS CMR 2018 KR/HR/IR | ~30 Mo | idem ci-dessus, fichiers individuels/ménages | `datasets/cameroun/dhs_mics/` |
| Google Open Buildings v3 (Cameroun) | ~variable, ~1 Go | <https://sites.research.google/open-buildings/> (choisir tuiles `s2_token` couvrant CMR) | `datasets/cameroun/batiments/` |
| Sentinel-2 L2A (zones pilotes) | ~variable, ~500 Mo par tuile | <https://browser.dataspace.copernicus.eu/> (extraire tuiles couvrant Buea, Mora, Bamenda 1, Fongo Tongo en juillet 2025) | `datasets/cameroun/teledetection/` |
| SRTM 30m | auto via `elevatr` | <https://lpdaac.usgs.gov/products/srtmgl1v003/> | géré par `elevatr` |

**Astuce** : créer une clé USB avec tous les datasets pour les distribuer en salle aux participants — évite que 25 personnes téléchargent simultanément 150 Mo sur le wifi IFORD.

### 1.4 Vérifier le pipeline complet avant J1

Une semaine avant, exécute chaque `.R` de bout en bout dans l'ordre J01 → J10. Note les warnings et les durées. Cela te donne une référence pour détecter une dégradation en salle (wifi, machine, version d'un package).

---

## 2. Pendant l'atelier

### 2.1 Arborescence à projeter

```
IFORD_Atelier_Geospatial_R_2026/
├── pedagogie/
│   ├── demos/                   ← ce dossier
│   │   ├── _helpers/            ← fonctions communes (fetch_data, theme, citations)
│   │   ├── J01_intro_R_pensee_spatiale.qmd     ← version animation pédagogique
│   │   ├── J01_intro_R_pensee_spatiale.R       ← version exécutable rapide
│   │   ├── J02_sf_CRS_vecteurs.qmd / .R
│   │   ├── ... (J03 à J10)
│   │   └── manuel_animateur.md  ← le présent document
│   ├── slides/                  ← decks revealjs (à produire séparément)
│   ├── exercices/, corriges/, cheatsheets/, evaluations/
├── datasets/cameroun/
└── environnement_technique/
```

### 2.2 Workflow par jour, en salle

1. **À l'arrivée (8h30) :**
   - Ouvrir RStudio.
   - Ouvrir le projet `IFORD_Atelier_Geospatial_R_2026.Rproj` (ou créer un projet à la racine si pas encore fait).
   - Ouvrir le `.qmd` du jour côté **gauche** (Source pane).
   - Ouvrir le `.R` du jour côté **droit** (deuxième Source pane via Panes → Show Source Pane on Right ou Ctrl+Shift+0).
   - Mode présentation projecteur : `View → Zoom In` jusqu'à police lisible au fond (~16-18 pt).

2. **Pendant l'animation :**
   - Naviguer dans le `.qmd` pour le narratif et les blocs commentés (les participants lisent le rendu HTML s'ils l'ont).
   - Exécuter le `.R` ligne par ligne (Ctrl+Entrée) pour ne pas attendre les chunks Quarto.
   - Si une cellule prend trop de temps (>30 s, ex. téléchargement WorldPop), expliquer ce qu'elle fait pendant qu'elle tourne, et garder un fallback `readRDS()` prêt si elle échoue.

3. **À la fin de la journée :**
   - Rendre le `.qmd` (`quarto render J0X_xxx.qmd`) — ce sera distribué aux participants le lendemain matin (ou sur clé USB).
   - Sauvegarder les sorties dans `pedagogie/JXX_…/_outputs/J0X/`.
   - Remplir `livrables_formateurs/rapports_quotidiens/J0X.md` (5 lignes : ce qui a marché, ce qui a coincé, ce qu'on garde pour demain).

### 2.3 Raccourcis RStudio à connaître par cœur

| Raccourci | Action |
|---|---|
| `Ctrl + Entrée` | Exécuter la ligne courante |
| `Ctrl + Shift + Entrée` | Exécuter tout le chunk Quarto |
| `Ctrl + Shift + K` | Knit / Render |
| `Ctrl + Shift + N` | Nouveau script R |
| `Ctrl + Alt + I` | Insérer un chunk de code (dans `.qmd`) |
| `Alt + -` | Insérer `<-` |
| `Ctrl + Shift + M` | Insérer le pipe `|>` (R ≥ 4.1) |
| `Ctrl + L` | Nettoyer la console |
| `F1` sur une fonction | Aide |
| `F2` sur une fonction | Aller au code source |
| `Ctrl + Shift + F10` | Redémarrer R (utile entre deux modules) |

### 2.4 Gestion du wifi en salle

- Tous les `.R` utilisent `_commons/helpers/fetch_data.R` qui **essaie le téléchargement** puis **bascule sur le fichier local** s'il échoue.
- En cas de coupure totale : tous les datasets sont déjà sur la clé USB (cf. §1.3). Distribuer la clé.
- Si un participant a un souci d'environnement, le rediriger vers le **Posit Cloud** template (lien donné le J1) — ça contourne 80 % des problèmes locaux.

---

## 3. Convention de lecture des fichiers

| Fichier | À quoi ça sert |
|---|---|
| `JXX_xxx.qmd` | **Pour les participants** : version pédagogique complète, narration en prose, blocs de code avec sorties rendues. À distribuer rendu en HTML ou PDF. |
| `JXX_xxx.R` | **Pour toi en salle** : script linéaire, sans narration, exécutable cellule par cellule. Inclut les `# ---` qui marquent les sections (utiliser Code Navigator de RStudio). |
| `_commons/helpers/*.R` | Helpers communs. Toujours `source()` en tête de chaque démo. |

---

## 4. En cas de pépin

| Symptôme | Action |
|---|---|
| Un package ne se charge pas | `install.packages("nom_du_package", dependencies = TRUE)` puis `library()` |
| `sf` refuse d'ouvrir un shapefile | Vérifier que les 4 fichiers (`.shp`, `.shx`, `.dbf`, `.prj`) sont présents au même endroit |
| `terra` crash sur un gros raster | Augmenter la RAM : `terra::terraOptions(memfrac = 0.8)` ou découper l'emprise |
| Quarto refuse de rendre | `quarto check` en terminal — souvent un package R manquant ou un YAML mal formé |
| Téléchargement bloqué | Vérifier le fallback local ; sinon clé USB |
| Reproductibilité à long terme | `renv::snapshot()` à la fin du J10 — voir `environnement_technique/renv.lock` |

---

## 5. Mention de paternité et licences

Tout le code dans `demos/` est diffusé sous **CC-BY 4.0** au nom du Geospatial Data Science Group de l'IFORD. Les datasets gardent leur licence propre (voir `datasets/README_donnees.md`). Les citations méthodologiques sont dans `_commons/helpers/citations.bib`.

---

*Dernière mise à jour : 20 mai 2026, Ramesesse Dzita.*
