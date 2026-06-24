# Atelier IFORD × GDSG 2026 — Données spatiales dans R

Site pédagogique de l'atelier régional **« Données spatiales, analyse et manipulation dans R »**, organisé par l'**IFORD** (Yaoundé) avec le **Geospatial Data Science Group (GDSG)**.

**27 juillet – 7 août 2026 · 10 jours · Niveau débutant en R et SIG.**

✅ **Tous les modules sont livrés** (juin 2026). Exécution dans le navigateur via WebR — aucune installation requise pour la lecture.

## Calendrier et accès direct

| Date | Jour | Thème | Runtime navigateur (WebR) |
|---|---|---|---|
| Lundi 27 juillet 2026 | **J1** | Introduction à R et à la pensée spatiale | [Lancer J1](J01_intro_R_pensee_spatiale/runtime.qmd) |
| Mardi 28 juillet 2026 | **J2** | Données vectorielles `sf` et CRS | [Lancer J2](J02_sf_CRS_vecteurs/runtime.qmd) |
| Mercredi 29 juillet 2026 | **J3** | Données raster avec `terra` | [Lancer J3](J03_donnees_raster_terra/runtime.qmd) |
| Jeudi 30 juillet 2026 | **J4** | Gestion des données + DHS Cameroun 2018 | [Lancer J4](J04_gestion_donnees_tidyverse/runtime.qmd) |
| Vendredi 31 juillet 2026 | **J5** | Visualisation et cartographie | [Lancer J5](J05_visualisation_cartographie/runtime.qmd) |
| Samedi 1ᵉʳ août 2026 | **J6** | Statistiques spatiales (Moran's I, LISA, KDE) | [Lancer J6](J06_statistiques_spatiales/runtime.qmd) |
| Lundi 3 août 2026 | **J7** | Population haute résolution + bottom-up | [Lancer J7](J07_population_haute_resolution/runtime.qmd) |
| Mardi 4 août 2026 | **J8** | Télédétection et observation de la Terre | [Lancer J8](J08_teledetection_observation_terre/runtime.qmd) |
| Mercredi 5 août 2026 | **J9** | Applications spatiales sciences sociales | [Lancer J9](J09_applications_spatiales_sciences_sociales/runtime.qmd) |
| Vendredi 7 août 2026 | **J10** | Flux reproductibles + mini-projet + clôture | [Lancer J10](J10_workflows_reproductibles/runtime.qmd) |

> Dimanche 2 août : repos. Jeudi 6 août : rédaction libre du mini-projet J10.

## Pour chaque jour, 7 fichiers

Schéma identique partout :

| Fichier | Rôle | Pour qui |
|---|---|---|
| `README.md` | Synthèse jour, objectifs, déroulé, données | Tout le monde |
| `slides.qmd` | Support revealjs animé (théorie + plan) | Formateur en salle |
| `demo.qmd` | Rapport Quarto complet (toutes opérations) | RStudio desktop |
| `demo.R` | Miroir condensé `demo.qmd` (script de salle) | Formateur en démo |
| `runtime.qmd` | WebR exécutable navigateur | Participants en autonomie |
| `exercice.qmd` | Devoirs Q1-Qn + mini-projet final | Participants |
| `corrige.qmd` | Solutions des exercices | Distribution post-session |
| `install_packages_day.R` | Packages spécifiques au jour | Formateur, première install |

Le `runtime.qmd` n'exécute pas tout : il couvre les opérations **portables sur WebR** (sf, dplyr, ggplot2, tidyverse). Les opérations non portables (terra, srvyr, spdep, mapedit, ncdf4, ecmwfr, tmap interactif) sont présentées en blocs `r` lecture seule (avec leur code commenté) et renvoient à `demo.qmd` pour exécution sous RStudio desktop.

## Programme détaillé (synthèse IFORD)

**J1 — Introduction à R et à la pensée spatiale.** Configuration R & RStudio, bases R pour la science des données, concepts de données spatiales, systèmes de référence de coordonnées (CRS), aperçu des données spatiales en statistiques nationales.

**J2 — Données vectorielles dans R.** Package `sf`, lecture/écriture Shapefile et GeoJSON, inspection d'objets spatiaux, opérations spatiales de base (sous-réglages, filtrage, jointure), cartographie des frontières administratives du Cameroun, lien avec données CSV (districts de santé).

**J3 — Données raster avec `terra`.** Packages `terra` et `raster`, lecture des rasters dérivés des satellites, opérations raster (découpe, masque, rééchantillonnage, agrégation), combinaison raster + vecteur, étude de cas : MNT SRTM Cameroun.

**J4 — Gestion des données pour l'analyse spatiale.** Remise à niveau Tidyverse (`dplyr`, `tidyr`), lien tabulaires/recensements et objets spatiaux, gestion des données manquantes et incohérentes, jointures spatiales et agrégation d'attributs, étude de cas : microfichiers EDS-MICS Cameroun 2018 (HR/PR) liés aux régions ADM1.

**J5 — Visualisation et cartographie.** Cartes thématiques avec `ggplot2` et `tmap` v4, choroplèthes et cartes à points, cartes interactives `tmap_mode("view")` Leaflet, principes de bonne conception cartographique, production de cartes pour rapports officiels.

**J6 — Statistiques spatiales et analyse.** Analyse des motifs ponctuels, autocorrélation spatiale (`Moran's I`), estimation de la densité de noyau (KDE), cartographie des points chauds (LISA), étude de cas : répartition spatiale des établissements de santé OSM Cameroun.

**J7 — Cartographie population haute résolution.** Ensembles démographiques en grille (WorldPop R2025A, GHSL, Meta HRSL), approche **bottom-up** (méthode GDSG, Darin & Leasure 2023), désagrégation des recensements, évaluation et validation, étude de cas : grille de population du Mfoundi (Yaoundé) + 4 sites pilotes RGPH 4 (Bamenda 1, Fongo Tongo, Buea, Mora).

**J8 — Télédétection et observation de la Terre.** Bases de l'imagerie satellite pour les non-spécialistes, accès aux données gratuites (Copernicus, GHSL Built-Up, Google Open Buildings), extraction des statistiques de zones bâties, activation Copernicus EMSR772 Yagoua 2024 (inondations), évaluation exposition bâtiments / population.

**J9 — Applications en sciences spatiales et sociales.** Données de conflits ACLED (Armed Conflict Location & Event Data), réanalyse climatique Copernicus ERA5 (température, anomalies), agrégation temporelle/spatiale, présentations de projets inspirants.

**J10 — Flux reproductibles et clôture.** Rapports reproductibles Quarto multi-format (HTML/PPTX/PDF/Word), contrôle de version Git, automatisation `purrr::map_dfr`, mini-projet en groupe (grille 6 éléments + restitution 5 min × 6 étapes), principes FAIR, métadonnées géospatiales (ISO 19115), feuille de route INS/BUCREP.

## Ressources transverses

### Au niveau racine du dépôt

- [`../README.md`](../README.md) — présentation générale, démarrage rapide, équipe, licence.
- [`../MANUEL_SUPPORT_TECHNIQUE.md`](../MANUEL_SUPPORT_TECHNIQUE.md) — manuel formateur (architecture, 17 datasets fichés, troubleshooting WebR, FAQ pédagogique par jour, urgences atelier).
- [`../environnement_technique/install_packages.R`](../environnement_technique/install_packages.R) — installation globale de tous les packages atelier.
- [`../environnement_technique/guide_installation.md`](../environnement_technique/guide_installation.md) — guide pas-à-pas pour participants.

### Dans `pedagogie/`

- `_commons/helpers/fetch_data.R` — résolution de chemins datasets (locale + fallback).
- `_commons/helpers/citations.bib` — bibliographie commune.
- `_commons/styles/` — feuilles de style SCSS revealjs + reference-doc PPTX IFORD.
- `_commons/img/logo-iford.jpg` — logo institutionnel.
- `_commons/data/` — extraits légers servis par les runtimes WebR.
- `_extensions/r-wasm/live/` — extension Quarto pour le runtime WebR.

## Modes d'accès

### Vous lisez en ligne (le plus simple)

Tout ce site est servi sur GitHub Pages : <https://dzita.github.io/atelier-r-spatial-iford-2026/>. Aucune installation. WebR charge R et les packages dans la page (~30 s la première fois, en cache ensuite).

### Vous voulez faire tourner les démos completes en local

```bash
git clone https://github.com/dzita/atelier-r-spatial-iford-2026.git
cd atelier-r-spatial-iford-2026
```

Ouvrir `atelier-r-spatial-iford-2026.Rproj` dans **RStudio**, puis dans la console :

```r
source("environnement_technique/install_packages.R")
```

Puis ouvrir le `demo.qmd` d'un jour pour l'exécuter en direct.

### Vous êtes formateur en salle

Ouvrir `demo.R` du jour dans RStudio et exécuter ligne par ligne sur projecteur (miroir condensé de `demo.qmd`, sans la prose narrative).

## Crédits

- **Lead Coordinator GDSG** : Pr Mathias Kuépié
- **Co-Lead GDSG** : Pr Franklin Bouba Djourdebbé
- **Conception J7/J8/J10** : Edith Darin (Senior Researcher, ex-WorldPop/Oxford, référente bottom-up).
- **Architecture J4/J5/J6** : Jean Saturnin Alogo Samba.
- **Animation unique + lead IT/infrastructure + intégration finale** : Ramesesse Dzita — <ramondzita@gmail.com>.

Le programme officiel IFORD est dans le document de cadrage `Atelier sur l'analyse des données Géospatiales avec R.docx`. Ce site en est l'**implémentation technique reproductible**.
