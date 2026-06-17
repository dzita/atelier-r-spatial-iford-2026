# J3 — Cartographie thématique : `tmap` et `ggplot2`

**Atelier IFORD × GDSG · Mercredi 29 juillet 2026 · Yaoundé · 8 heures**

## Objectifs pédagogiques

À la fin de J3, chaque participant doit pouvoir :

1. Construire une carte choroplèthe propre avec `tmap` v4 — choisir une classification, une palette, un découpage adapté à la donnée.
2. Basculer entre le mode statique (`tmap_mode("plot")`) pour la publication et le mode interactif (`tmap_mode("view")`) pour l'exploration.
3. Produire la même carte en `ggplot2 + geom_sf` quand l'intégration à un rapport scientifique le justifie.
4. Décorer une carte de production : titre, sous-titre, légende, flèche du nord, échelle, crédits.
5. Empiler plusieurs cartes côte à côte avec `tmap_arrange()` pour comparer deux indicateurs.
6. Exporter en PNG haute résolution, en PDF vectoriel et en HTML interactif.

## Déroulé horaire (8 h)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J2 + intro J3 | 30 min | Slides |
| Théorie 1 — Sémiologie graphique appliquée | 45 min | Slides |
| Démo 1 — Choroplèthe `tmap` basique | 1 h | demo + Q1 |
| Théorie 2 — Classifications et palettes | 45 min | Slides |
| Démo 2 — Quatre classifications comparées | 1 h | demo + Q2–Q3 |
| Théorie 3 — Décoration et publication | 45 min | Slides |
| Démo 3 — Multi-panel, export, interactif | 1 h 30 | demo + Q4–Q5 |
| Synthèse + Q6 + Q&A | 30 min | Slides |

## Packages utilisés

- `tmap` (≥ 4.0) — moteur cartographique thématique principal
- `sf` — données vectorielles (hérité de J2)
- `dplyr`, `tibble` — manipulation
- `ggplot2` + `ggspatial` — alternative scientifique
- `classInt` — algorithmes de classification (Jenks, head/tails…)
- `RColorBrewer`, `viridisLite` — palettes
- `leaflet` — cartes interactives (via `tmap_mode("view")`)
- `scales` — formatage des étiquettes

## Données mobilisées

- ADM1, ADM2 du Cameroun (Lambert 3119) — exportés J2 dans `CMR_admin_lambert.gpkg`
- Estimations BUCREP de population régionale 2019 (table construite en J1)
- Indicateurs sociaux simulés (taux d'électrification, accès eau améliorée, taille moyenne ménage) — simulés à partir des proportions EDS-MICS 2018

## Pré-requis

- J1 et J2 validés
- Q6 du J2 terminé (GeoPackage multi-couches dans `outputs/`)

## Fichiers du jour

`README.md`, `slides.qmd`, `demo.qmd`, `demo.R`, `runtime.qmd`, `exercice.qmd`, `corrige.qmd`.
