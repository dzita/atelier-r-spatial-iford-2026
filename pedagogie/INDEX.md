# Index pédagogique — Atelier IFORD × GDSG 2026

Navigation rapide entre les 10 jours de l'atelier **« Données spatiales, analyse et manipulation dans R »**, organisé par l'IFORD (Yaoundé) avec le Geospatial Data Science Group (GDSG).

**Atelier régional · 27 juillet – 7 août 2026 · 10 jours · Niveau débutant**

## Calendrier officiel

| Date | Jour | Thème (programme officiel IFORD) | Lien |
|---|---|---|---|
| Lundi 27 juillet 2026 | J1 | Introduction à R et à la pensée spatiale | [J01](J01_intro_R_pensee_spatiale/README.md) |
| Mardi 28 juillet 2026 | J2 | Données vectorielles dans R (`sf`) | [J02](J02_sf_CRS_vecteurs/README.md) |
| Mercredi 29 juillet 2026 | J3 | Données raster dans R (`terra`) | [J03](J03_donnees_raster_terra/README.md) |
| Jeudi 30 juillet 2026 | J4 | Gestion des données pour l'analyse spatiale | _à venir_ |
| Vendredi 31 juillet 2026 | J5 | Visualisation et cartographie | _à venir_ |
| Samedi 1ᵉʳ août 2026 | J6 | Statistiques spatiales et analyse | _à venir_ |
| Lundi 3 août 2026 | J7 | Cartographie population haute résolution + bottom-up | _à venir_ |
| Mardi 4 août 2026 | J8 | Télédétection et observation de la Terre | _à venir_ |
| Mercredi 5 août 2026 | J9 | Sciences spatiales et sociales : projets inspirants | _à venir_ |
| Jeudi 6 août 2026 | J10 | Flux de travail reproductibles + clôture | [J10](J10_mini_projet_synthese/README.md) |

> Dimanche 2 août : jour de repos.
>
> Vendredi 7 août : éventuelle journée tampon / activités optionnelles selon le calendrier IFORD.

## Statut de chaque jour

Légende : ✅ rédigé · 🚧 en cours · ⬜ à venir.

| Jour | Thème (résumé) | README | demo | slides | runtime | exercice | corrigé |
|---|---|---|---|---|---|---|---|
| J1 | Intro R + pensée spatiale | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| J2 | sf et CRS | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| J3 | Raster terra | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| J4 | Gestion données tidyverse | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| J5 | Visualisation cartographie | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| J6 | Stats spatiales (Moran, LISA, KDE) | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| J7 | Pop haute-rés + bottom-up | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| J8 | Télédétection (Sentinel, rgee) | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| J9 | Spatial & social (Malaria Atlas, ACLED) | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| J10 | Reproductibilité + clôture | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Mise à jour : 17 juin 2026 (J1, J2, J3, J5, J10 livrés selon programme officiel ; J4, J6, J7, J8, J9 à produire).

## Détail des thèmes officiels (synthèse du programme IFORD)

**Jour 1 — Introduction à R et à la pensée spatiale.** Configuration R & RStudio, bases de R pour la science des données, introduction aux concepts de données spatiales, systèmes de référence de coordonnées (CRS), aperçu des données spatiales en statistiques nationales.

**Jour 2 — Données vectorielles dans R.** Introduction au package `sf`, lecture et écriture de fichiers Shapefile et GeoJSON, inspection d'objets spatiaux, opérations spatiales de base (sous-réglages, filtrage, jointure), cartographie des frontières administratives du Cameroun, lien avec données CSV (districts de santé).

**Jour 3 — Données raster dans R.** Introduction aux packages `terra` et `raster`, lecture des rasters dérivés des satellites, opérations raster (découpe, masque, rééchantillonnage, agrégation), combinaison raster + vecteur, étude de cas : MNT SRTM et couverture des sols pour le Cameroun.

**Jour 4 — Gestion des données pour l'analyse spatiale.** Remise à niveau Tidyverse (`dplyr`, `tidyr`), lien entre données tabulaires/recensements et objets spatiaux, gestion des données manquantes et incohérentes, jointures spatiales et agrégation d'attributs, étude de cas : lien entre données d'enquêtes ménagères et unités administratives.

**Jour 5 — Visualisation et cartographie.** Cartes thématiques avec `ggplot2` et `tmap`, choroplèthes et cartes à points, cartes interactives avec `leaflet` et `tmap view`, principes d'une bonne conception cartographique, production de cartes pour rapports officiels et publications.

**Jour 6 — Statistiques spatiales et analyse.** Analyse des motifs ponctuels, autocorrélation spatiale (`Moran's I`), estimation de la densité de noyau (KDE), cartographie des points chauds, pratique : analyse de la répartition spatiale des établissements de santé ou des écoles.

**Jour 7 — Cartographie des populations à haute résolution.** Ensembles de données démographiques en grille (WorldPop, GHSL, Meta HRSL), approche de modélisation ascendante (bottom-up) : concept et flux de travail, utilisation de données auxiliaires (bâtiments, utilisation des sols, lumières nocturnes), désagrégation des recensements, évaluation et validation de la précision, étude de cas : construction de la grille de population camerounaise.

**Jour 8 — Télédétection et observation de la Terre.** Bases de l'imagerie satellite pour les non-spécialistes, accès aux données gratuites (Copernicus, SRTM, MODIS), extraction des statistiques de zones bâties et de couverture des sols, utilisation de Google Earth Engine via `rgee` en R, pratique : suivi de la croissance urbaine à Yaoundé/Douala.

**Jour 9 — Applications en sciences spatiales et sociales.** Combinaison des données spatiales et socioéconomiques pour les politiques, cartographie de la pauvreté et estimation de petites surfaces (SAE), analyse de l'accessibilité en santé et éducation, données de conflits et de déplacements (ACLED, HCR), présentations de projets inspirants (Malaria Atlas, exposition aux inondations, sécurité alimentaire, mobilité CDR).

**Jour 10 — Flux de travail reproductibles et renforcement des capacités.** Rapports reproductibles avec R Markdown / Quarto, contrôle de version avec Git, automatisation des tâches spatiales répétitives, présentations de projets de groupe, session de clôture (principes FAIR, normes de métadonnées, feuille de route pour une infrastructure de données spatiales à l'INS/BUCREP, ressources pour l'apprentissage continu).

## Ressources transverses

- `README.md` — présentation générale du dossier `pedagogie/`.
- `manuel_animateur.md` — mode d'emploi pour l'animateur (Ramesesse Dzita).
- `_commons/helpers/fetch_data.R` — chargement des datasets avec fallback local.
- `_commons/helpers/theme_iford.R` — thème ggplot + tmap commun.
- `_commons/helpers/citations.bib` — bibliographie commune.
- `_commons/styles/` — feuilles de style SCSS pour slides revealjs et runtime WebR.
- `_commons/img/logo-iford.jpg` — logo IFORD utilisé partout.
- `_commons/data/` — datasets servis par le runtime WebR.
- Documentation technique : [`environnement_technique/architecture_quarto.md`](../environnement_technique/architecture_quarto.md).

## Pour les participants

- **Vous avez R installé localement** : ouvrir le `.Rproj` et lancer `pedagogie/JXX_…/demo.qmd`.
- **Vous n'avez pas R installé** : utiliser le runtime WebR en ligne sur <https://dzita.github.io/atelier-r-spatial-iford-2026/> — R s'exécute directement dans le navigateur, zéro installation.
- **Tutoriels d'auto-installation** : voir `environnement_technique/guide_installation.md`.

## Référence officielle

Le programme détaillé du jour est dans `Atelier sur l'analyse des données Géospatiales avec R.docx` (référence officielle IFORD). Ce dépôt en est l'**implémentation technique reproductible**.
