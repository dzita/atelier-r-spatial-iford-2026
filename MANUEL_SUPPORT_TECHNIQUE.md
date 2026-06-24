# Manuel de support technique — Atelier IFORD × GDSG 2026

**Atelier R-spatial · 10 jours · Yaoundé · 27 juillet – 7 août 2026**

> Document interne destiné à **Ramesesse Dzita** (animateur unique), pour assurer le support technique pendant la livraison. Synthèse de l'expérience accumulée pendant la construction du matériel : pièges WebR, astuces déploiement, troubleshooting datasets, FAQ pédagogique. À garder ouvert pendant les sessions.

---

## Table des matières

1. [Architecture du dépôt](#1-architecture-du-depot)
2. [Stack technique et flux de rendu](#2-stack-technique-et-flux-de-rendu)
3. [Runtime WebR — comment ça marche, où ça casse](#3-runtime-webr)
4. [Datasets — fiche détaillée par fichier](#4-datasets)
5. [Procédures d'installation participant](#5-installation-participant)
6. [Déploiement GitHub Pages](#6-deploiement-gh-pages)
7. [Troubleshooting — les pannes déjà rencontrées](#7-troubleshooting)
8. [FAQ pédagogique par jour](#8-faq-pedagogique)
9. [Procédures d'urgence pendant l'atelier](#9-procedures-urgence)
10. [Maintenance post-atelier](#10-maintenance)

---

## 1. Architecture du dépôt {#1-architecture-du-depot}

```
atelier-r-spatial-iford-2026/
├── atelier-r-spatial-iford-2026.Rproj    # Marqueur de racine RStudio + rprojroot
├── .here                                  # Marqueur de racine here::here()
├── .gitignore                             # Exclut datasets lourds (.DTA, gros TIF, ZIP)
├── README.md                              # Présentation générale du repo
├── MANUEL_SUPPORT_TECHNIQUE.md            # Ce document
│
├── environnement_technique/
│   └── install_packages.R                 # Installation globale tous packages atelier
│
├── datasets/cameroun/                     # Datasets canoniques (parfois .gitignored)
│   ├── admin_boundaries/                  # GADM JSON ADM0-3
│   ├── population_grids/                  # WorldPop, GHS-POP, Meta HRSL
│   ├── dhs_mics/                          # DHS Cameroun 2018 (microfichiers .DTA)
│   ├── elevation/                         # SRTM tile
│   ├── cmr_sante/                         # OSM healthcare
│   ├── CM_2018_DHS/                       # Pack DHS complet (.gitignored, ~500 Mo)
│   ├── jour_07_population/                # WorldPop R2025A + GHS-POP tuiles
│   ├── jour_08_teledetection/             # GHSL + EMSR772 + Open Buildings
│   ├── jour_09_acled_era5/                # ACLED CSV + ERA5 NetCDF
│   └── jour_10/                           # Dataset Edith fil rouge (commité, léger)
│
└── pedagogie/                             # Cœur pédagogique (= projet Quarto)
    ├── _quarto.yml                        # Config Quarto + navbar + resources
    ├── _extensions/r-wasm/live/           # Extension Quarto pour WebR
    ├── _commons/
    │   ├── data/                          # Extraits LÉGERS pour runtime WebR (≤ 5 Mo chacun)
    │   ├── helpers/
    │   │   ├── fetch_data.R              # Centralise tous les fetch_*()
    │   │   └── citations.bib              # Bibliographie atelier
    │   ├── styles/                        # SCSS revealjs + iford_reference.pptx
    │   └── img/                           # Logo IFORD + visuels
    ├── datasets/cameroun/                 # Symlink vers ../datasets/cameroun/
    │
    ├── INDEX.md                           # Page d'accueil du site
    ├── J01_intro_R_pensee_spatiale/       # Chaque jour suit le même schéma :
    │   ├── README.md                      #   - synthèse jour, objectifs, données
    │   ├── slides.qmd                     #   - support revealjs animé
    │   ├── demo.qmd                       #   - rapport complet (RStudio)
    │   ├── demo.R                         #   - miroir condensé (salle)
    │   ├── runtime.qmd                    #   - WebR navigateur
    │   ├── exercice.qmd                   #   - questions à faire
    │   ├── corrige.qmd                    #   - solutions
    │   └── install_packages_day.R         #   - packages du jour
    ├── J02_sf_CRS_vecteurs/
    ├── J03_donnees_raster_terra/
    ├── J04_gestion_donnees_tidyverse/
    ├── J05_visualisation_cartographie/
    ├── J06_statistiques_spatiales/
    ├── J07_population_haute_resolution/
    ├── J08_teledetection_observation_terre/
    ├── J09_applications_spatiales_sciences_sociales/
    └── J10_workflows_reproductibles/
```

**Règles d'or de l'architecture** :

- **Deux marqueurs de racine concurrents** : `atelier-r-spatial-iford-2026.Rproj` à la racine du repo, et `_quarto.yml` dans `pedagogie/`. C'est la source de 80 % des bugs de chemin. Toujours ancrer explicitement avec `rprojroot::find_root(rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj"))` plutôt que `here::here()` qui peut résoudre vers `pedagogie/`.
- **Datasets versionnés UNE seule fois** : sous `datasets/cameroun/`. Ce dossier est référencé depuis `pedagogie/datasets/cameroun/` (soit par symlink soit par chemin). Jamais de duplication.
- **`_commons/data/`** : extraits **légers** (≤ 5 Mo chacun) pour le runtime WebR uniquement. Pré-générés par des scripts `00_*.R` côté formateur, puis commités. Ne JAMAIS y mettre les originaux WorldPop ou GHSL — c'est l'erreur classique qui fait passer le repo de 50 Mo à 5 Go.
- **Convention de nommage des extraits** : `_commons/data/jour_XX_extraits/...` pour les jours qui consomment des données spécifiques (J7, J8, J9, J10) ; `_commons/data/<source>/...` pour les datasets transverses (`gadm41_CMR_*.json`, `dhs_cmr/`, `cmr_sante/`, `cmr_srtm/`).

---

## 2. Stack technique et flux de rendu {#2-stack-technique-et-flux-de-rendu}

### Logiciels requis sur le poste animateur

| Outil | Version min | Usage |
|---|---|---|
| R | 4.4+ (4.6 utilisé) | Moteur d'exécution R |
| RStudio | 2024.04+ | IDE pour ouvrir le `.Rproj`, lancer les démos |
| Quarto | 1.4+ | Rendu des `.qmd` (HTML/PPTX/PDF/Word + WebR) |
| Git | 2.40+ | Versionning + push GitHub Pages |
| Python | 3.10+ (pour Quarto reveal) | Optionnel |
| TinyTeX | dernier | Optionnel, requis pour rendu PDF |
| QGIS LTR | 3.34+ | Inspection visuelle datasets (optionnel) |

### Packages R

Installation globale via :

```r
source("environnement_technique/install_packages.R")
```

Packages clés et leur rôle :

| Catégorie | Packages | Usage atelier |
|---|---|---|
| Spatial vecteur | `sf` | Tous jours, primaire |
| Spatial raster | `terra` | J3, J7, J8 |
| Extraction zonale | `exactextractr` | J7, J8 (desktop seulement, pas WebR) |
| Tidyverse | `dplyr`, `tidyr`, `readr`, `tibble`, `purrr` | Tous jours |
| Lecture DHS | `haven`, `srvyr` | J4 desktop |
| Cartographie | `ggplot2`, `tmap` (v4+) | Tous jours |
| Stats spatiales | `spdep` | J6 desktop |
| OSM | `osmdata` | J6 bootstrap |
| Reproductibilité | `here`, `rprojroot`, `fs`, `usethis`, `renv` | J10 |
| Quarto | `quarto`, `knitr`, `rmarkdown` | Tous jours |
| WebR | `webr` (installé en interne par r-wasm/live) | Runtimes |
| Climat | `ecmwfr`, `ncdf4` | J9 desktop |
| Conflit | `acledR` (CRAN) | J9 desktop |

### Flux de rendu

**Pour un fichier `demo.qmd` desktop** :
```powershell
quarto render pedagogie\JXX_*\demo.qmd --to html
quarto render pedagogie\JXX_*\demo.qmd --to pptx
quarto render pedagogie\JXX_*\demo.qmd --to pdf   # nécessite TinyTeX
```

**Pour le projet complet (déploie le site)** :
```powershell
cd pedagogie
quarto render
```
Génère `pedagogie/_site/` qui contient le site statique. Sera poussé sur la branche `gh-pages` par la CI (GitHub Action).

**Pour la preview locale d'un runtime** :
```powershell
quarto preview pedagogie\JXX_*\runtime.qmd
```
Lance un serveur sur `http://localhost:<port>/` avec hot reload. La preview tourne dans `_site/` — si tu ajoutes un fichier à `_commons/data/`, **coupe et relance** la preview (le serveur ne sync pas automatiquement les resources nouvellement ajoutées).

---

## 3. Runtime WebR — comment ça marche, où ça casse {#3-runtime-webr}

### Vue d'ensemble

WebR est R compilé en WebAssembly. Il tourne dans le navigateur, dans un Web Worker isolé. Aucune installation côté participant : ils ouvrent une URL et tout marche.

Le runtime IFORD utilise l'extension Quarto **`r-wasm/live`** (v0.1.3-dev). Cette extension :
- Crée des cellules `{webr}` exécutables dans le `.qmd`.
- Initialise WebR au boot de la page (CDN `webr.r-wasm.org`).
- Pré-charge des packages (déclarés dans `webr.packages` du YAML).
- Pré-charge des fichiers dans le filesystem virtuel (`webr.resources` du YAML).

### YAML type d'un runtime

```yaml
---
title: "JX — ..."
engine: knitr
webr:
  packages:
    - sf
    - dplyr
    - ggplot2
  resources:
    - ../_commons/data/gadm41_CMR_1.json
    - ../_commons/data/dhs_cmr/foo.csv
---
```

### Mécanique du pré-chargement de fichiers

C'est notre découverte la plus importante. La JS de boot (`webr-setup.ojs` lignes 60-94) :
1. Lit la liste `webr.resources` (relative au `.qmd`).
2. Pour chaque fichier, fait `fetch(file)` **dans le main thread** (avec l'origine de la page).
3. Écrit le contenu dans le filesystem virtuel WebR via `webR.FS.writeFile()`.

**Conséquence cruciale** : les chemins relatifs du YAML se résolvent contre l'origine de la page navigateur. Donc :
- En `quarto preview` local : `fetch('../_commons/...')` → `http://localhost:PORT/_commons/...` → fichier local servi par Quarto. **Marche hors-ligne**.
- En prod GitHub Pages : `fetch('../_commons/...')` → `https://dzita.github.io/atelier-r-spatial-iford-2026/_commons/...` → CDN. **Marche en ligne**.

Le même YAML fonctionne dans les deux contextes. Pas de hardcoding d'URL.

### `collapsePath` du JS de boot

Le chemin déclaré `../_commons/data/foo.json` est **collapsé** au moment de l'écriture VM : le `../` est strippé, le reste préservé. Donc dans la VM le fichier est à `_commons/data/foo.json`.

**Conséquence pour le code R des runtimes** :
```r
# Le YAML déclare : ../_commons/data/gadm41_CMR_1.json
# Dans la VM, le fichier est à : _commons/data/gadm41_CMR_1.json
adm1 <- read_sf("_commons/data/gadm41_CMR_1.json")
```

Pas de `download.file()`, pas de `webr_get()`, pas de helper. Juste un read direct depuis le chemin pre-collapsé.

### Pourquoi `download.file("/_commons/...")` ne marche PLUS

Dans WebR < 0.5, le shim `download.file` acceptait les URLs root-relatives `/foo`. Depuis WebR 0.6 (notre version), le shim utilise XMLHttpRequest **dans le worker** qui n'a pas de base URL — `/foo` est jugé invalide → `SyntaxError: Failed to execute 'open' on 'XMLHttpRequest': Invalid URL`.

C'est pour ça qu'on est passé à la pré-déclaration `webr.resources`. **Ne JAMAIS revenir à `download.file()` dans les cellules runtime**.

### `tmap` n'est pas portable sur WebR

`tmap` v4 a trop de dépendances système (libproj, libgeos compilés). Il n'est pas dans `repos.r-wasm.org`. Tous les runtimes utilisent `ggplot2 + geom_sf` à la place. La leçon "tmap plot vs view" reste dans `demo.qmd` desktop uniquement.

### `srvyr`, `spdep`, `ncdf4`, `mapedit`, `exactextractr`, `ecmwfr`, `acledR` : pas portables

Ces packages reposent sur des dépendances système non disponibles dans WebR. Les modules concernés (J4 srvyr pondéré, J6 spdep formel, J7 exactextractr, J8 mapedit, J9 ERA5) ont une **version runtime allégée** qui fait l'équivalent à la main (par exemple Moran's I + permutation Monte Carlo codés manuellement en J6 au lieu de `spdep::moran.test`) et renvoient vers `demo.qmd` desktop pour la version complète.

### Packages disponibles : pré-déclarer pour fluidifier le boot

Tous les packages standards CRAN les plus courants sont disponibles via `repo.r-wasm.org`. **Pré-déclare tous les packages dont les cellules vont avoir besoin** dans `webr.packages` du YAML. Sinon le premier `library(sf)` dans une cellule télécharge `sf` + ses 11 dépendances transitives dans la sortie de cellule, ce qui pollue l'affichage utilisateur. Pré-déclaration = téléchargement discret au boot dans la status bar.

### Mode `autorun` vs clic manuel

```yaml
{webr}
#| autorun: true   # s'exécute au chargement de la page
```

Sans `autorun: true`, l'utilisateur doit cliquer **Run code**. Pour les démos formateur, mettre `autorun: true` sur la première cellule de chargement (data + packages) pour que tout soit prêt en bas de page. Pour les cellules pédagogiques où on veut que le participant lise avant de cliquer, laisser sans `autorun`.

### `edit: false`, `output: false`, `context: setup` — attention

L'option `context: setup` vient de knitr/RMarkdown, **pas reconnue** par `r-wasm/live` 0.1.3-dev. Une cellule avec `context: setup` ne s'exécute pas. Utiliser `autorun: true` uniquement.

`edit: false` cache le code editor (la cellule devient invisible pour l'utilisateur mais s'exécute). `output: false` cache la sortie. Combinés avec `autorun: true`, c'est utile pour des setups discrets.

---

## 4. Datasets — fiche détaillée par fichier {#4-datasets}

Pour chaque dataset, voici son origine, sa structure, sa taille, sa licence, où le télécharger, où le poser, comment vérifier qu'il est correct.

### 4.1 GADM v4.1 Cameroun (ADM0-3)

- **Quoi** : limites administratives officielles 4 niveaux (pays, région, département, commune).
- **Format** : GeoJSON (un fichier par niveau).
- **Tailles** : ADM0 ~50 ko, ADM1 ~190 ko, ADM2 ~750 ko, ADM3 ~2.5 Mo.
- **Licence** : libre académique, pas de redistribution commerciale.
- **CRS** : WGS84 (EPSG:4326).
- **Source** : <https://gadm.org/download_country.html> → Cameroon → JSON.
- **URL directe** : `https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_<niveau>.json`
- **Emplacement local** : `datasets/cameroun/admin_boundaries/gadm41_CMR_<niveau>.json`
- **Helper R** : `fetch_gadm_cameroon(level = 0|1|2|3)` dans `fetch_data.R`
- **Embarqué WebR** : oui, dans `_commons/data/gadm41_CMR_*.json` (ADM0, ADM1, ADM2, ADM3 selon le jour)
- **Jours qui l'utilisent** : J1 (ADM1), J2 (ADM1+ADM3), J3 (ADM0+ADM1), J4 (ADM1), J5 (ADM1), J6 (ADM2), J7 (ADM1+ADM2 via GeoJSON allégé)
- **Vérification** : `sf::read_sf(path) |> nrow()` retourne 1, 10, 58, 360 pour ADM0/1/2/3.

### 4.2 WorldPop top-down 100m unconstrained (CMR 2020)

- **Quoi** : grille de population 100m, méthode top-down (Stevens et al. 2015).
- **Format** : GeoTIFF.
- **Taille** : ~150 Mo.
- **Licence** : CC-BY 4.0 (citer Tatem 2017).
- **CRS** : WGS84.
- **Source** : <https://hub.worldpop.org/geodata/summary?id=49866>
- **URL directe** : `https://data.worldpop.org/GIS/Population/Global_2000_2020/2020/CMR/cmr_ppp_2020.tif`
- **Emplacement** : `datasets/cameroun/population_grids/CMR_pop_WorldPop_top-down_100m_2020.tif`
- **Helper** : `fetch_worldpop_cmr_2020()`
- **Embarqué WebR** : NON (trop lourd). Extraits Mfoundi générés par bootstrap (cf. 4.13).
- **Jour** : J7 desktop principalement, J3 mention conceptuelle.

### 4.3 WorldPop top-down constrained 100m R2025A (CMR 2015/2025/2030)

- **Quoi** : grille de population 100m **contrainte sur le bâti**, release 2025A (la plus récente). 3 années : 2015, 2025, 2030.
- **Format** : GeoTIFF, 3 fichiers.
- **Taille** : ~30 Mo chacun (×3).
- **Licence** : CC-BY 4.0.
- **CRS** : WGS84.
- **Source** : <https://hub.worldpop.org/geodata/summary?id=24784> (variantes par année dans Drive d'Edith)
- **Emplacement** : `datasets/cameroun/jour_07_population/cmr_pop_<année>_CN_100m_R2025A_v1.tif`
- **Helper** : `fetch_worldpop_constrained_cmr(year = c(2015, 2025, 2030))`
- **Embarqué WebR** : extraits Mfoundi (Yaoundé département) pré-calculés ~1 Mo chacun (`_commons/data/jour_07_extraits/pop_<année>_mfoundi.tif`).
- **Jour** : J7.

### 4.4 GHS-POP 2020 100m R2023A (CMR)

- **Quoi** : grille de population 100m JRC, alternative à WorldPop.
- **Format** : GeoTIFF, tuile mondiale 3 Go à découper sur l'emprise CMR.
- **Source** : <https://human-settlement.emergency.copernicus.eu/download.php?ds=pop>
- **Emplacement** : `datasets/cameroun/population_grids/CMR_pop_GHSL_R2023A_100m_2020.tif`
- **Helper** : `fetch_ghspop_cmr_2020()`
- **Embarqué WebR** : NON.
- **Jour** : J7 (comparaison méthodologique avec WorldPop).

### 4.5 GHSL Built-Up R2023A 100m (CMR, 2015 + 2025)

- **Quoi** : surface bâtie en m² par pixel 100m, mondiale, JRC. Pour le Cameroun, **15 tuiles ZIP** à décompresser puis mosaïquer.
- **Format** : ZIP contenant GeoTIFF, projection Mollweide (`ESRI:54009`).
- **Tailles** : ~10-50 Mo par tuile.
- **Licence** : CC-BY 4.0 (JRC).
- **Source** : <https://human-settlement.emergency.copernicus.eu/download.php?ds=bu>
- **Emplacement** : `datasets/cameroun/jour_08_teledetection/GHS-BUILT/` (dossier avec 15 zips × 2 années = 30 zips)
- **Helper** : `fetch_ghs_built_dir()`
- **Embarqué WebR** : NON (trop lourd). Le runtime J8 ne couvre PAS la partie GHSL.
- **Jour** : J8 desktop Partie I.
- **Mosaïque** : `terra::vrt()` ou `terra::mosaic()` après `terra::rast()` sur chaque tuile.
- **Reprojection obligatoire** avant `exact_extract` : GADM est en EPSG:4326, GHSL en `ESRI:54009`. Reprojeter GADM dans le CRS du raster, pas l'inverse.

### 4.6 EMSR772 Copernicus Emergency — Yagoua 2024

- **Quoi** : activation Copernicus EMS suite aux inondations de Yagoua nord Cameroun, septembre 2024. 3 zones d'intérêt (AOI01, AOI02, AOI03).
- **Format** : ZIP par AOI, contenant des shapefiles (`areaOfInterestA_v*.shp`, `floodDepthA_v*.shp`).
- **Taille** : ~5-20 Mo par AOI.
- **Licence** : libre (Copernicus EMS, attribution).
- **CRS** : UTM zone 33N (EPSG:32633).
- **Source** : <https://emergency.copernicus.eu/mapping/list-of-components/EMSR772>
- **Emplacement** : `datasets/cameroun/jour_08_teledetection/EMSR772_products/` (avec sous-dossiers par AOI)
- **Helper** : `fetch_emsr772_dir()`
- **Embarqué WebR** : extraits AOI01 uniquement (`_commons/data/jour_08_extraits/aoi01_yagoua.geojson` + `flood01_yagoua.geojson`), reprojetés WGS84.
- **Jour** : J8 Partie II.
- **Piège** : géométries Copernicus livrées en urgence ont souvent des vertices dupliqués. **Toujours appliquer `st_make_valid()` après `st_read()`** sinon `st_area` ou `st_filter` plante avec `wk_handle.wk_wkb`.
- **Structure ZIP inconsistante** : AOI01 a un sous-dossier, AOI02/03 ont les fichiers à la racine. Le code utilise `list.files(..., recursive = TRUE)` pour absorber les deux cas.

### 4.7 Google Open Buildings v3

- **Quoi** : empreintes de bâtiments générées par ML sur imagerie satellite haute-résolution. Couvre l'Afrique + Asie + Am. latine.
- **Format** : CSV compressés `.csv.gz` par tuile S2.
- **Taille** : ~10-30 Mo par tuile compressée, plusieurs millions de polygones.
- **Licence** : CC-BY 4.0 (Sirko et al. 2021).
- **CRS** : WGS84.
- **Source** : <https://sites.research.google/open-buildings/>
- **Emplacement** : `datasets/cameroun/jour_08_teledetection/Open Buildings/` (5 fichiers `.csv.gz` couvrant la région Yagoua)
- **Helper** : `fetch_open_buildings_dir()`
- **Filtrage standard** : `confidence >= 0.7` (recommandé par Google ; en dessous, on garde des bruits de modèle).
- **Embarqué WebR** : extrait pré-filtré sur la bbox AOI01 (`_commons/data/jour_08_extraits/batiments_yagoua.geojson`), ~5-15k bâtiments, ~2-3 Mo.
- **Jour** : J8 Partie II.

### 4.8 DHS Cameroun 2018 (microfichiers Stata complets)

- **Quoi** : Enquête Démographique et de Santé Cameroun 2018, microfichiers individuels par recode (HR/PR/IR/MR/KR/BR/CR/FW).
- **Format** : Stata `.DTA`, 7 fichiers, total ~300-500 Mo.
- **Licence** : DHS Program (compte gratuit + soumission projet, validation 24-48 h).
- **Source** : <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm>
- **Emplacement** : `datasets/cameroun/CM_2018_DHS/CM<RC>71DT/CM<RC>71FL.DTA` où `<RC>` = HR/PR/...
- **Helper** : `fetch_dhs_recode_cmr_2018(recode = "HR")` etc.
- **`.gitignored`** : oui (trop lourd + licence).
- **Embarqué WebR** : extraits CSV légers générés par `00_extraire_dhs_pour_webr.R` (HR + PR), ~3-5 Mo chacun (`_commons/data/dhs_cmr/dhs_cmr_2018_*_extrait.csv`).
- **Jour** : J4 (microfichier HR + PR, jointures, agrégations), J1 (indicateurs agrégés via API DHS), J5 (indicateurs DHS sur carte).

### 4.9 DHS StatCompiler API — indicateurs agrégés par région

- **Quoi** : 5 indicateurs DHS Cameroun 2018 agrégés par région via l'API StatCompiler (`rdhs::dhs_data`). Format long pivoté.
- **Format** : CSV.
- **Taille** : < 10 ko.
- **Indicateurs** : `WS_SRCE_H_IMP` (eau améliorée %), `HC_ELEC_H_ELC` (électricité %), `ED_LITR_W_LIT` (alphabétisation femmes %), `ED_LITR_M_LIT` (alphabétisation hommes %), `HC_HHSZ_H_AVG` (taille moyenne ménage).
- **Source** : <https://api.dhsprogram.com/rest/dhs/data> (via `rdhs::dhs_data()`).
- **Emplacement** : `_commons/data/dhs_cmr/indicateurs_dhs_cmr_2018.csv`
- **Script de génération** : `_commons/data/dhs_cmr/00_telecharger_dhs_indicateurs.R`
- **Embarqué WebR** : oui.
- **Jour** : J1, J5.

### 4.10 DHS clusters GPS Cameroun 2018

- **Quoi** : positions GPS (lat/lon) des grappes d'enquête, avec offset de confidentialité.
- **Format** : Shapefile.
- **Source** : DHS Program (même compte que microfichiers, dossier "Geographic Data" `CMGE71FL.zip`).
- **Emplacement** : `datasets/cameroun/dhs_mics/CMGE71FL.shp` (+ .dbf .shx .prj)
- **Helper** : `fetch_dhs_clusters_cmr_2018()`
- **Jour** : J4 (méthodologie), J5 (cartographie ponctuelle).

### 4.11 SRTM 30 arc-sec Cameroun

- **Quoi** : Modèle Numérique de Terrain ~1 km de résolution (30 arc-sec), agrégé depuis SRTM 30 m officiel NASA/USGS.
- **Format** : GeoTIFF.
- **Taille** : ~3 Mo (cropé sur emprise CMR).
- **Licence** : libre (NASA/USGS).
- **Source** : `geodata::elevation_30s("CMR")` (téléchargement programmatique depuis UC Davis).
- **Emplacement** : `_commons/data/cmr_srtm/srtm_cmr_30s.tif`
- **Script de génération** : `_commons/data/cmr_srtm/00_telecharger_srtm.R`
- **Embarqué WebR** : oui (~3 Mo).
- **Jour** : J3.
- **Note** : ce N'EST PAS du SRTM 30 m natif (qui ferait ~1 Go pour le pays). C'est une version agrégée par UC Davis pour usage régional.

### 4.12 OSM Healthcare facilities Cameroun

- **Quoi** : établissements de santé OpenStreetMap (hôpitaux, cliniques, pharmacies, centres de santé) pour le Cameroun, récupérés via Overpass API.
- **Format** : CSV.
- **Taille** : ~200-500 ko.
- **Licence** : ODbL (OpenStreetMap).
- **Source** : Overpass API (`osmdata::add_osm_feature("amenity", c("hospital","clinic","pharmacy","doctors"))`).
- **Emplacement** : `_commons/data/cmr_sante/etablissements_sante_osm.csv`
- **Script de génération** : `_commons/data/cmr_sante/00_telecharger_osm_sante.R`
- **Embarqué WebR** : oui.
- **Jour** : J6 (statistiques spatiales : KDE, Moran's I, LISA).
- **Anti-piège** : 4 mirrors Overpass dans le script de bootstrap pour gérer les timeouts ; relancer si échec.

### 4.13 Population administrative ADM1 (OCHA COD-PS 2025)

- **Quoi** : population totale par région ADM1, par sexe et 5 grands groupes d'âge, source officielle BUCREP via OCHA.
- **Format** : CSV.
- **Source** : <https://data.humdata.org/dataset/cod-ps-cmr>
- **Emplacement** : `datasets/cameroun/jour_07_population/cmr_admpop_adm1_2025.csv`
- **Helper** : `fetch_admpop_adm1_cmr_2025()`
- **Embarqué WebR** : copie dans `_commons/data/jour_07_extraits/admpop_adm1_2025.csv`
- **Jour** : J7.

### 4.14 ACLED Cameroun

- **Quoi** : événements de conflits armés au Cameroun, base académique ACLED (Armed Conflict Location & Event Data Project).
- **Format** : CSV (export du dashboard ACLED Explorer).
- **Taille** : ~1-5 Mo selon période.
- **Licence** : ACLED Terms of Use (académique gratuit, commercial sur demande).
- **Source** : <https://acleddata.com/data-export-tool/> (compte requis).
- **Emplacement** : `datasets/cameroun/jour_09_acled_era5/ACLED_Data.csv`
- **Embarqué WebR** : copié dans `_commons/data/jour_09_extraits/ACLED_Data.csv` (étape manuelle, ou via `Copy-Item` PowerShell).
- **Jour** : J9 Partie I.

### 4.15 ERA5 réanalyse climatique Copernicus (Cameroun)

- **Quoi** : température 2m de surface, données mensuelles, format NetCDF.
- **Format** : NetCDF `.nc`.
- **Taille** : ~5-20 Mo selon période.
- **Licence** : libre (Copernicus CDS, compte gratuit + token).
- **Source** : <https://cds.climate.copernicus.eu/> (via package `ecmwfr` ou téléchargement web).
- **Emplacement** : `datasets/cameroun/jour_09_acled_era5/era5_t2m_cmr.nc`
- **Helper** : `fetch_era5_t2m_cmr()` (avec instructions de token CDS).
- **`.gitignored`** : oui (compte CDS requis).
- **Embarqué WebR** : NON (`ncdf4` n'est pas portable WebR).
- **Jour** : J9 Partie II desktop.

### 4.16 Indicateurs régionaux démo (dataset Edith J10)

- **Quoi** : 10 régions Cameroun avec 7 indicateurs démographiques et sociaux (population, ménages, eau améliorée %, alphabétisation %, écoles, formations sanitaires, superficie km²).
- **Format** : GeoPackage + Shapefile + CSV (3 variantes pour démontrer la portabilité).
- **Taille** : < 200 ko chacun.
- **Licence** : libre (matériel pédagogique Edith Darin pour atelier IFORD).
- **CRS** : WGS84.
- **Source** : repo `jour_10_flux_reproductibles_projets` d'Edith Darin (Drive partagé).
- **Emplacement** : `datasets/cameroun/jour_10/regions_indicateurs_demo.gpkg` (+ variantes)
- **Helper** : `fetch_indicateurs_regions_demo(format = "gpkg" | "shp" | "csv")`
- **Script de génération** : `pedagogie/J10_workflows_reproductibles/00_copier_datasets_edith_j10.R` (copie depuis le repo Edith vers le repo atelier + miroir dans `_commons/data/jour_10_extraits/`)
- **Embarqué WebR** : oui.
- **Jour** : J10 (fil rouge).
- **Note importante** : ce sont des **valeurs d'entraînement pédagogique**, pas des statistiques officielles. À NE PAS citer comme chiffres BUCREP. Pour usage réel : ECAM 4, MICS, EDS-MICS 2018, RGPH.

### 4.17 DATA_ECOLE.zip (bonus J7)

- **Quoi** : datasets pédagogiques Edith pour la démo bottom-up GDSG (sites pilotes RGPH 4 : Bamenda 1, Fongo Tongo, Buea, Mora).
- **Format** : ZIP.
- **Source** : Drive privé Edith Darin (matériel formateur).
- **Emplacement** : `datasets/cameroun/jour_07_population/DATA_ECOLE.zip`
- **Helper** : `fetch_data_ecole_cmr()`
- **`.gitignored`** : oui (matériel formateur non public).
- **Jour** : J7 bonus.

---

## 5. Procédures d'installation participant {#5-installation-participant}

### 5.1 Pré-atelier : email aux participants (1 semaine avant)

Sujet : « Atelier IFORD R-spatial — installation à faire AVANT le 27 juillet »

Contenu type :

> Bonjour,
>
> Pour limiter les pertes de temps en début d'atelier, merci d'**installer ces 4 outils sur votre ordinateur** avant votre arrivée à l'IFORD :
>
> 1. **R 4.4 ou plus récent** : <https://cran.r-project.org/>
> 2. **RStudio Desktop** : <https://posit.co/download/rstudio-desktop/>
> 3. **Quarto CLI** : <https://quarto.org/docs/get-started/>
> 4. **Git** : <https://git-scm.com/downloads>
>
> Une fois installé, ouvrir RStudio et exécuter dans la console :
>
> ```r
> install.packages(c("sf", "terra", "tmap", "ggplot2", "dplyr", "tidyr", "readr", "tibble", "purrr", "here", "rprojroot", "fs", "usethis", "renv", "quarto"))
> ```
>
> Ce premier `install.packages()` prendra 15 à 30 minutes selon votre connexion. **À faire avant l'atelier**, pas le jour J. Si vous bloquez, écrivez à <ramondzita@gmail.com>.
>
> Apportez votre ordinateur chargé avec son chargeur, un adaptateur de prise française si vous venez d'un pays voisin.
>
> À très bientôt,
> Ramesesse Dzita

### 5.2 J1 matin (30 min) — diagnostic poste

Faire tourner ces 4 commandes dans la console R de chaque participant :

```r
R.version.string                                # doit être ≥ 4.4
quarto::quarto_version()                        # doit être ≥ 1.4
Sys.which("git")                                # doit retourner un chemin non vide
library(sf); library(terra); library(ggplot2)   # doit charger sans erreur
```

Si l'un échoue : prendre 10 min avec le participant pour réinstaller, ou lui faire utiliser **Posit Cloud** en backup.

### 5.3 Posit Cloud — solution de secours

Si un poste est trop vieux ou que les installations cassent :

1. Le participant crée un compte gratuit sur <https://posit.cloud>
2. Il fork ou clone le repo IFORD (créer un projet depuis URL Git)
3. Il a accès à R + RStudio dans le navigateur, identique au desktop

**Limitation** : compte gratuit Posit Cloud = 25 h/mois. Faire les démos courtes en cloud, le mini-projet en local. Le formateur peut prévoir 2-3 comptes éducation Posit Cloud Team pour partager.

### 5.4 Clone du repo

```bash
git clone https://github.com/<ton-username>/atelier-r-spatial-iford-2026.git
cd atelier-r-spatial-iford-2026
```

Ouvrir `atelier-r-spatial-iford-2026.Rproj` dans RStudio.

Premier rendu :

```bash
quarto preview pedagogie/INDEX.md
```

---

## 6. Déploiement GitHub Pages {#6-deploiement-gh-pages}

### Workflow

Le repo a une GitHub Action qui :
1. Détecte un push sur `main`
2. Lance `quarto render` dans `pedagogie/`
3. Pousse le contenu de `pedagogie/_site/` sur la branche `gh-pages`
4. GitHub Pages sert <https://dzita.github.io/atelier-r-spatial-iford-2026/>

### Configuration Pages

`Settings → Pages → Source : Deploy from a branch → Branch : gh-pages → / (root)`

### Vérification post-push

Aller sur <https://dzita.github.io/atelier-r-spatial-iford-2026/> et vérifier :
- La page INDEX charge.
- La navbar a 10 entrées (J1 à J10).
- Cliquer sur J1 → runtime se charge, WebR boote (status bar en haut), section 5 et 6 fonctionnent.

Si l'action GitHub échoue, regarder les logs dans **Actions**. Causes fréquentes :
- Un nouveau package non disponible dans le cache R-Quarto Action → ajouter à `install_packages.R` global.
- Un YAML cassé → vérifier les `:` et l'indentation des nouveaux fichiers.
- Un chemin absolu introduit par erreur → grep avant chaque commit pour `C:\` `C:/`.

---

## 7. Troubleshooting — les pannes déjà rencontrées {#7-troubleshooting}

### 7.1 `Failed to execute 'open' on 'XMLHttpRequest': Invalid URL`

**Symptôme** : dans une cellule WebR, `download.file("/_commons/...")` ou `download.file("../_commons/...")` jette cette erreur.

**Cause** : WebR 0.6 (notre version) tourne dans un Web Worker sans `window.location`. Les URL relatives ne se résolvent plus.

**Fix permanent** : utiliser le mécanisme `webr.resources` du YAML (cf. section 3). **Tous nos runtimes utilisent ce pattern, ne JAMAIS revenir aux `download.file()`**.

### 7.2 `cannot open the connection` / `Can't download .../foo.csv. Error 404: Not Found`

**Symptôme** : un fichier déclaré dans `webr.resources` ne se charge pas.

**Causes possibles** :
1. Le fichier n'est pas physiquement présent à l'emplacement attendu sur le disque. → `Get-ChildItem pedagogie\_commons\data\<sous-dossier>\`
2. Le fichier n'a pas été pris en compte par Quarto preview parce qu'il a été ajouté APRÈS le lancement de la preview. → Ctrl+C la preview et relancer.
3. Le `_quarto.yml` n'inclut pas le dossier dans `resources`. → Vérifier le bloc `resources:` du YAML (doit inclure `_commons/data/**`).

**Procédure** : `ls pedagogie\_site\_commons\data\<sous-dossier>\` — si le fichier n'est pas dans `_site/`, il n'a pas été copié → relancer la preview.

### 7.3 `here::here()` retourne `pedagogie/` au lieu du repo racine

**Cause** : `_quarto.yml` agit comme marqueur de racine concurrent à `.Rproj`.

**Fix** : utiliser `rprojroot::find_root(rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj"))` à la place. Documenté dans J10 demo + corrige.

### 7.4 Geometrie Copernicus invalide (`wk_handle.wk_wkb : Loop 0 is not valid, vertices duplicated`)

**Symptôme** : `st_area` ou `st_filter` sur un shapefile EMSR772 jette cette erreur.

**Fix** : `st_make_valid()` après `st_read()`. Documenté dans J8 demo + corrige.

```r
aoi01 <- st_read("...areaOfInterestA_v1.shp", quiet = TRUE) |> st_make_valid()
```

### 7.5 `quarto render` casse parce que `tmap` n'est pas dispo en WebR

**Symptôme** : un runtime déclare `tmap` dans `webr.packages`, le boot WebR plante avec "package tmap not found in repo.r-wasm.org".

**Fix** : retirer `tmap` du YAML runtime, remplacer le code `tm_shape(...)` par l'équivalent `ggplot(...) + geom_sf(...)`. Pattern appliqué à J5, J7, J10 runtime. La leçon `tmap` reste dans `demo.qmd` desktop.

### 7.6 `sf` plante au chargement WebR avec "GDAL not found"

**Symptôme** : `library(sf)` ne boot pas en WebR.

**Cause** : WebR build officielle inclut sf + GDAL + GEOS + PROJ. Si erreur, c'est que la version WebR a régressé. → vérifier `https://repo.r-wasm.org/bin/emscripten/contrib/4.6/sf_*.tgz`.

**Fix de contournement** : restreindre la démo aux opérations qui ne nécessitent pas GDAL en WebR (pas de read_sf sur shapefile, oui sur GeoJSON pur).

### 7.7 Render PDF échoue avec "tlmgr not found" ou "pdflatex error"

**Cause** : TinyTeX pas installé.

**Fix** :
```r
quarto::quarto_install_tinytex()
# ou
install.packages("tinytex"); tinytex::install_tinytex()
```

### 7.8 Render PPTX écrase la mise en page IFORD

**Cause** : le `reference-doc: ../_commons/styles/iford_reference.pptx` n'est pas trouvé.

**Fix** : vérifier que le fichier existe, et qu'il a bien les layouts attendus par Quarto (Title Slide, Title and Content, etc.). Le tester avec un `.qmd` minimal d'abord.

### 7.9 Téléchargement DHS bloque sur "project not approved yet"

**Cause** : un compte DHS Program neuf doit soumettre un projet et attendre 24-48h pour validation.

**Workaround pendant l'atelier** : le formateur partage les fichiers `.DTA` sur clé USB (licence DHS permet usage en formation interne).

### 7.10 OSM Overpass timeout

**Symptôme** : le bootstrap `00_telecharger_osm_sante.R` retourne `502 Bad Gateway` ou timeout.

**Fix** : le script essaie 4 mirrors successivement. Si tous échouent, attendre 5-10 min et relancer (Overpass est gratuit et souvent saturé).

### 7.11 Premier boot WebR de la page = lent (30 à 60 secondes)

**Cause** : téléchargement WebR runtime (~10 Mo) + packages (~50 Mo) au premier accès.

**Comportement attendu** : la status bar en haut affiche "Downloading webR" puis "Downloading package: ...". Une fois fini, tout est en cache navigateur — les visites suivantes sont instantanées.

**À expliquer aux participants** : "patientez 1 minute la première fois, ensuite c'est instantané".

---

## 8. FAQ pédagogique par jour {#8-faq-pedagogique}

### J1 — Intro R + pensée spatiale

- **Q : Pourquoi `tibble` au lieu de `data.frame` ?** R : affichage plus lisible, types stricts, intégration tidyverse. `data.frame` fonctionne aussi, c'est juste plus moderne.
- **Q : C'est quoi un CRS ?** R : Système de Référence des Coordonnées. C'est la "règle de jeu" qui convertit (lat, lon) en (x, y) sur la carte. Sans CRS, st_distance retourne un nombre sans dimension. Avec CRS, ça retourne des mètres.
- **Q : Pourquoi `|>` plutôt que `%>%` ?** R : `|>` est le pipe natif R (depuis 4.1), `%>%` vient de `magrittr`. Les deux fonctionnent. On utilise `|>` pour ne pas dépendre d'un package additionnel.

### J2 — sf et CRS

- **Q : Quel CRS choisir pour le Cameroun ?** R : EPSG:3119 (Cameroun Lambert) pour mesurer surfaces et distances avec précision sur tout le pays. EPSG:32632 (UTM 32N) pour l'ouest, EPSG:32633 (UTM 33N) pour l'est. Pour visualiser sur le web : EPSG:3857 (Web Mercator). Pour stocker : WGS84 (4326).
- **Q : `st_area` donne 0 ou des m² aberrants ?** R : oublié de reprojeter. WGS84 mesure en degrés² qui ne veut rien dire. Toujours `st_transform()` dans un CRS projeté avant `st_area`.
- **Q : Différence buffer vs voronoi ?** R : buffer = "zone autour d'un point/polygone à distance donnée". Voronoi = "partition de l'espace où chaque cellule est la zone la plus proche d'un seed". Buffer = local, voronoi = global.

### J3 — terra raster

- **Q : `terra` vs `raster` ?** R : `terra` (2020+) remplace `raster` (2010). Plus rapide, syntaxe plus claire. Tout nouveau code = `terra`.
- **Q : `crop` vs `mask` ?** R : `crop` rogne l'emprise rectangulaire (boundingbox). `mask` met à NA les pixels en dehors du polygone. On enchaîne souvent `crop` puis `mask` pour limiter la mémoire.
- **Q : Résolution 30 arc-sec, c'est combien en mètres ?** R : ~1 km à l'équateur, ~700 m aux latitudes nord. Pour avoir du vrai 30 m, télécharger SRTM 1-arc-sec officiel.

### J4 — tidyverse + DHS

- **Q : `left_join` vs `inner_join` ?** R : `left_join` garde TOUTES les lignes de gauche (et NA si pas de match à droite). `inner_join` ne garde que les lignes qui matchent des deux côtés. En analyse, `left_join` est le défaut (ne pas perdre d'observations).
- **Q : Pourquoi `srvyr` ne marche pas en WebR ?** R : dépend de packages C qui ne sont pas portables. Le runtime J4 fait les indicateurs "non pondérés" (assez pour la pédagogie). La version pondérée correcte (avec design DHS) est dans `demo.qmd` desktop.
- **Q : Quelle est la double clé DHS ?** R : `(cluster_id, menage_id)` ou plus formellement `(HV001, HV002)`. Joindre sur `menage_id` SEUL est faux car le même numéro de ménage existe dans plusieurs clusters.

### J5 — cartographie

- **Q : `tmap` vs `ggplot2 + geom_sf` ?** R : `tmap` est déclaratif, conçu pour les cartes (échelle, flèche nord, mode interactif). `ggplot2` est la grammaire graphique générale étendue au spatial. Les deux marchent ; `tmap` est plus économe en code pour de la cartographie thématique.
- **Q : Quelle palette choisir ?** R : séquentielle (viridis, ColorBrewer YlOrRd) pour ordinal/continu, divergente (RdBu) pour gain/perte autour de 0, qualitative (Set1) pour catégoriel. Toujours penser daltonien-friendly → viridis ou cividis.
- **Q : Comment exporter une carte propre ?** R : `ggsave("carte.png", width=7, height=5, dpi=200)` ou `tmap_save(carte, "carte.png", width=7, height=5, dpi=200, units="in")`. 200 dpi est le minimum imprimable.

### J6 — statistiques spatiales

- **Q : Moran's I, c'est quoi exactement ?** R : un score entre -1 et +1 qui mesure l'autocorrélation spatiale. +1 = forte autocorrélation positive (zones voisines se ressemblent). 0 = aléatoire. -1 = forte autocorrélation négative (échiquier). En pratique on regarde le score + le p-value (test par permutation).
- **Q : LISA c'est différent de Moran's I ?** R : oui. Moran's I = un score global pour toute la carte. LISA (Local Indicators of Spatial Association) = un score PAR unité géographique, permet d'identifier les clusters Hot-Hot, Cold-Cold, Hot-Cold, Cold-Hot.
- **Q : KDE c'est quoi ?** R : Kernel Density Estimation. Estime la "densité" d'un nuage de points en lissant avec une fonction kernel. Très utile pour visualiser où se concentrent les facilités, événements, etc.

### J7 — population haute résolution

- **Q : Top-down vs bottom-up, c'est quoi la diff ?** R : top-down (WorldPop classique, Stevens 2015) = on part de la population administrative (recensement) et on la **redistribue** sur la grille avec des contraintes (bâti, route, lumière). Bottom-up (Darin & Leasure 2023, méthode GDSG) = on part d'**enquêtes locales géo-référencées** (bottom-up) et on extrapole avec un modèle bayésien. **Complémentaires, pas concurrents.**
- **Q : Quelle release WorldPop choisir ?** R : la plus récente. En 2026, c'est R2025A (constrained). Les anciennes (R2020A unconstrained) sont obsolètes pour les pays africains où le bâti a beaucoup évolué.
- **Q : Pourquoi pas exactextractr en WebR ?** R : dépendances Boost.Geometry pas portables. En WebR, on agrège pixel→ADM avec `terra::extract(..., fun="mean")` qui marche mais est moins précis sur les bordures.

### J8 — télédétection

- **Q : GHSL vs Open Buildings ?** R : GHSL mesure la **surface bâtie en m²** par pixel 100m (output continu). Open Buildings donne une **empreinte vectorielle** de chaque bâtiment (output discret). GHSL = analyse globale agrégée, Open Buildings = analyse fine par bâtiment.
- **Q : Pourquoi Mollweide pour GHSL ?** R : Mollweide est une projection equal-area (préserve les surfaces). Comme GHSL mesure des m² de bâti, on veut une projection qui ne déforme pas. WGS84 ne marche pas car la surface d'un pixel varie avec la latitude.
- **Q : 5 pers/bât, c'est sérieux ?** R : c'est une approximation. Au Cameroun la taille moyenne DHS 2018 est ~5.5. À adapter : 8-10 en milieu rural (concessions élargies), 3-4 en urbain dense moderne. À calibrer avec WorldPop sur la même AOI pour validation croisée.

### J9 — sciences sociales

- **Q : ACLED c'est fiable ?** R : c'est la référence académique pour les conflits armés. Source de presse + ONG + officiel, triangulé. Limite : sous-déclaration dans les zones de presse difficile (Extrême-Nord rural au Cameroun).
- **Q : ERA5 c'est de la mesure ou un modèle ?** R : c'est de la **réanalyse** : un modèle climatique qui ingère toutes les observations disponibles (stations, satellites) et produit un état atmosphérique cohérent partout dans le monde. Pas une mesure directe — un meilleur estimateur que les stations isolées.

### J10 — reproductibilité

- **Q : `here` vs `rprojroot` ?** R : `here` est une couche facile au-dessus de `rprojroot`. 90% du temps `here::here()` suffit. Quand il y a des marqueurs concurrents (cas IFORD avec `.Rproj` + `_quarto.yml`), utiliser `rprojroot::find_root()` qui permet d'ancrer EXPLICITEMENT sur un fichier.
- **Q : Pourquoi Git pour de la statistique ?** R : (a) historique versionné = on peut revenir à n'importe quelle version, (b) un seul fichier source au lieu de `analyse_v1`/`v2`/`FINAL`, (c) collaboration : 2 personnes peuvent travailler sur le même projet sans s'écraser.
- **Q : Le mini-projet doit utiliser quoi comme données ?** R : `regions_indicateurs_demo.gpkg` (le dataset fil rouge de J10). Pas des vraies stats Cameroun. C'est un exercice de méthode, pas de production statistique.

---

## 9. Procédures d'urgence pendant l'atelier {#9-procedures-urgence}

### Le wifi IFORD tombe pendant une démo runtime

- Annoncer "wifi en pause" calmement.
- **Pivoter vers `demo.qmd` desktop** qui ne nécessite pas internet (les datasets sont en local).
- Si vraiment besoin du runtime : utiliser le hotspot du téléphone du formateur pour redémarrer un participant à la fois.

### Un participant a un poste qui ne lance pas R/RStudio

- Le faire utiliser **Posit Cloud** (compte gratuit ou comptes Team partagés).
- Sinon, le faire travailler en **binôme** avec son voisin.

### Le déploiement gh-pages est cassé

- Rendu local fonctionne quand même. Faire la démo sur `quarto preview` local.
- Vérifier les logs GitHub Actions le soir.

### Un dataset .DTA DHS est corrompu

- Faire le module **avec les CSV extraits** (`_commons/data/dhs_cmr/...`) qui sont commités au repo.
- Le module 4 (srvyr pondéré) saute, on reste sur les indicateurs non pondérés.

### Un participant veut voir le code source d'une fonction

- `getMethod("st_distance", "sfc")` ou `body(<fonction>)` ou directement le repo GitHub du package.

### Coupure courant pendant J6 (LISA)

- Pré-rendre les cartes en PNG la veille, les avoir sur clé USB.
- Faire la démo "à blanc" en montrant le code + les PNG préfabriqués.

---

## 10. Maintenance post-atelier {#10-maintenance}

### Refresh annuel

- **GADM** : nouvelle release tous les 2-3 ans, vérifier `https://gadm.org`.
- **WorldPop** : nouvelle release annuelle en moyenne. Bumper le helper `fetch_worldpop_constrained_cmr` à la dernière (`R2026A`, `R2027A`...).
- **DHS Cameroun** : prochaine enquête prévue ~2030. Pas de bump avant.
- **OSM** : refresh par `Rscript pedagogie/_commons/data/cmr_sante/00_telecharger_osm_sante.R` (réinterroge Overpass).
- **ACLED** : refresh annuel via le dashboard.
- **GHSL** : nouvelle release attendue R2024A ou R2025A en 2026. Bumper les liens.

### Bump de version de l'extension r-wasm/live

- Vérifier `https://github.com/r-wasm/live/releases`. Si bump, tester sur J1 d'abord en preview locale avant de propager.
- **Si la nouvelle version casse `webr.resources`** : pinner à `0.1.3-dev` jusqu'à ce qu'on comprenne la régression.

### Bump de WebR

- Le binaire WebR est servi par `webr.r-wasm.org`. On ne le contrôle pas. **Tester périodiquement** (chaque trimestre) que les runtimes fonctionnent toujours en preview locale ET en prod.
- En cas de régression, ouvrir un issue sur `r-wasm/webr`.

### Refresh du Drive Edith

- Si Edith met à jour ses datasets (`jour_07_population`, `jour_10_flux_reproductibles_projets`), relancer le bootstrap correspondant (`00_copier_datasets_edith_jXX.R`).
- Les chemins candidats dans les scripts couvrent : `~/Dev/GitHub/...`, `$USERPROFILE/Dev/GitHub/...`, `$HOME/Dev/GitHub/...`. À adapter si nécessaire.

### Évolution des slides reveal

- Le thème `_commons/styles/slides_revealjs.scss` peut être enrichi (couleurs IFORD, footer animé).
- Pour ajouter un logo en bas de slide : éditer `_commons/styles/iford_reference.pptx`.

---

## Annexe — Contacts utiles

- **Ramesesse Dzita** (auteur du code, animateur unique) : <ramondzita@gmail.com>
- **Pr Mathias Kuépié** (Lead Coordinator GDSG, IFORD) : contact IFORD direct
- **Pr Franklin Bouba Djourdebbé** (Co-Lead GDSG, IFORD) : contact IFORD direct
- **Edith Darin** (Senior Researcher, ex-WorldPop/Oxford) : pour questions bottom-up + datasets J7/J8/J10
- **Jean Saturnin Alogo Samba** : pour questions architecture J4/J5/J6
- **Marcial Teda Soh Fossi** : co-formateur GDSG (collègue)

---

## Annexe — Liens importants

- **Site live (production)** : <https://dzita.github.io/atelier-r-spatial-iford-2026/>
- **Repo GitHub** : <https://github.com/dzita/atelier-r-spatial-iford-2026>
- **Documentation Quarto** : <https://quarto.org/docs/guide/>
- **Documentation WebR** : <https://docs.r-wasm.org/webr/latest/>
- **Documentation r-wasm/live** : <https://r-wasm.github.io/quarto-live/>
- **Geocomputation with R** (Lovelace) : <https://r.geocompx.org/>
- **DHS Program** : <https://dhsprogram.com/>
- **WorldPop Hub** : <https://hub.worldpop.org/>
- **GADM** : <https://gadm.org/>
- **Copernicus EMS** : <https://emergency.copernicus.eu/>
- **Open Buildings** : <https://sites.research.google/open-buildings/>
- **ACLED** : <https://acleddata.com/>
- **Copernicus CDS (ERA5)** : <https://cds.climate.copernicus.eu/>

---

*Document maintenu par Ramesesse Dzita · GDSG IFORD · v1.0 juin 2026*
