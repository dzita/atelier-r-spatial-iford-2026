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

## Données mobilisées

- GADM v4.1 Cameroun ADM0, ADM1, ADM2, ADM3 (déjà téléchargés en J1, dans `datasets/cameroun/admin_boundaries/`).
- Tibble des chefs-lieux régionaux camerounais (construit en séance, ∼10 points GPS).

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
