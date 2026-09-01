# J2 — Données vectorielles `sf` et CRS

**Atelier IFORD × GDSG · Mardi 28 juillet 2026 · Yaoundé · 8 heures**

## Objectifs pédagogiques

À la fin de J2, chaque participant doit pouvoir :

1. Lire et écrire des fichiers spatiaux dans tous les formats courants (Shapefile, GeoJSON, GeoPackage, KML).
2. Maîtriser les transformations entre CRS (WGS 84, UTM, Lambert) et choisir la projection adaptée à une question donnée.
3. Appliquer les opérations vectorielles de base : `st_buffer`, `st_intersection`, `st_union`, `st_difference`, `st_centroid`.
4. Dissoudre une couche multi-niveaux (ADM3 → ADM1) par agrégation géométrique avec `st_union` + `group_by`.
5. Valider et réparer des géométries malformées (`st_make_valid`, `st_is_valid`).
6. Construire un diagramme de Voronoï autour des chefs-lieux régionaux camerounais.

## Déroulé horaire (8 h)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J1 + intro J2 | 30 min | Slides |
| Théorie 1 — Lecture/écriture multi-format | 45 min | Slides |
| Démo 1 — Lire shp, gpkg, geojson, kml | 1 h | demo.R + Q1 |
| Théorie 2 — CRS appliqué | 45 min | Slides |
| Démo 2 — Reprojection + comparaison de superficies | 1 h | demo.R + Q2 |
| Théorie 3 — Opérations vectorielles | 1 h | Slides |
| Démo 3 — buffer, intersection, dissolve, voronoi | 1 h 30 | demo.R + Q3–Q5 |
| Synthèse + Q6 + Q&A | 30 min | Slides |

## Packages utilisés

- `sf` — opérations vectorielles et CRS
- `dplyr` — manipulation attributaire
- `tibble` — tables
- `ggplot2` — visualisation
- `lwgeom` — opérations géométriques avancées (Voronoï notamment)
- `rmapshaper` — simplification de géométries

## Données utilisées

### Embarqué dans le repo (chargé automatiquement par le runtime WebR)

- `pedagogie/_commons/data/gadm41_CMR_0.json` — limites administratives Cameroun niveau 0 (frontière nationale), GeoJSON, ~0.2 Mo, source GADM v4.1 (<https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_0.json>) — résolu par `fetch_gadm_cameroon(0)`.
- `pedagogie/_commons/data/gadm41_CMR_1.json` — 10 régions ADM1 du Cameroun, GeoJSON, ~1 Mo, source GADM v4.1 (<https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_1.json>) — résolu par `fetch_gadm_cameroon(1)`. Pré-chargé dans la VM WebR via `resources:` du `runtime.qmd`.
- `pedagogie/_commons/data/gadm41_CMR_2.json` — 58 départements ADM2, GeoJSON, ~3 Mo, source GADM v4.1 (<https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_2.json>) — résolu par `fetch_gadm_cameroon(2)`. Utilisé par `corrige.qmd` (Q1, Q4, Q6) et `demo.R`.
- `pedagogie/_commons/data/gadm41_CMR_3.json` — ~365 arrondissements ADM3, GeoJSON, ~10 Mo, source GADM v4.1 (<https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_3.json>) — résolu par `fetch_gadm_cameroon(3)`. Pré-chargé dans la VM WebR via `resources:` du `runtime.qmd`.

Le tibble `chefs_lieux` (10 chefs-lieux régionaux : Ngaoundéré, Yaoundé, Bertoua, Maroua, Douala, Garoua, Bamenda, Bafoussam, Ebolowa, Buea) est **construit en séance** dans `demo.qmd`, `demo.R`, `runtime.qmd`, `exercice.qmd` et `corrige.qmd` à partir de coordonnées GPS approximatives (source : OpenStreetMap + connaissance terrain). Ce n'est pas un fichier dataset.

### À télécharger manuellement (utilisé par demo.qmd desktop, trop lourd pour le repo)

Aucun pour J2. Toutes les données utilisées par les cinq fichiers du jour (`slides.qmd`, `demo.qmd`, `demo.R`, `runtime.qmd`, `exercice.qmd`, `corrige.qmd`) sont embarquées dans `pedagogie/_commons/data/`.

Les Shapefiles BUCREP officiels mentionnés en slides (partie 4, cadrage RGPH 4) sont évoqués comme exemple théorique mais ne sont pas distribués dans le repo ni chargés par le code du jour.

## Pré-requis

- Avoir validé les objectifs pédagogiques de J1.
- Avoir Q6 du J1 terminé (ou avoir consulté le corrigé).

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `slides.qmd` | Diaporama revealjs, projection en salle |
| `demo.qmd` | Démonstration complète avec explication avant chaque bloc R |
| `demo.R` | Script court pour exécution rapide en salle |
| `runtime.qmd` | Version WebR pour participants sans R local |
| `exercice.qmd` | Énoncés Q1 à Q6 |
| `corrige.qmd` | Solutions Q1 à Q6 (distribué J+1 matin) |
| `install_packages_day.R` | Installation des packages strictement nécessaires pour J2 |
