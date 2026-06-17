# J3 — Données raster dans R avec `terra`

**Atelier IFORD × GDSG · Mercredi 29 juillet 2026 · Yaoundé · 6 heures**

## Objectifs pédagogiques

À la fin de J3, chaque participant doit pouvoir :

1. Énoncer ce qu'est un raster — cellules de grille, résolution, étendue, bandes — et distinguer raster vs vecteur.
2. Lire et écrire des fichiers raster (GeoTIFF, NetCDF) avec `terra`.
3. Réaliser les opérations raster fondamentales : découpe (`crop`), masquage (`mask`), rééchantillonnage (`resample`), agrégation (`aggregate`).
4. Pratiquer l'**algèbre raster** : calculs pixel à pixel sur des SpatRaster.
5. **Combiner raster et vecteur** : extraire les valeurs d'un raster par polygones (`extract` et `exactextractr`).
6. Manipuler un raster réel : un MNT SRTM du Cameroun, en calculer la statistique zonale par région.

## Déroulé horaire (6 h d'instruction selon programme officiel)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J2 + intro J3 | 30 min | Slides |
| Théorie 1 — Concepts raster | 45 min | Slides |
| Démo 1 — Lire et inspecter un raster | 45 min | demo + Q1 |
| Théorie 2 — Opérations raster | 45 min | Slides |
| Démo 2 — Crop, mask, resample, aggregate | 1 h | demo + Q2 |
| Théorie 3 — Algèbre raster + combinaison | 30 min | Slides |
| Démo 3 — Extraction zonale SRTM Cameroun | 1 h | demo + Q3–Q5 |
| Synthèse + Q6 + Q&A | 15 min | Slides |

## Packages utilisés

- `terra` (≥ 1.7) — moteur raster principal, successeur de `raster` [@hijmans2024terra]
- `sf` — limites administratives pour l'extraction zonale
- `dplyr` — manipulation attributaire des résultats
- `ggplot2` — visualisation des rasters et résultats
- `exactextractr` — extraction zonale rapide et précise
- `tidyterra` (optionnel) — interface tidyverse pour `terra`

## Données mobilisées

- **SRTM 30 m du Cameroun** (Shuttle Radar Topography Mission) — modèle numérique d'élévation, source principale en démo.
- **GADM ADM1, ADM3** du Cameroun (hérité de J2) pour l'extraction zonale.
- **WorldPop 100 m 2020** pré-chargé (sera approfondi en J7) — pour démo de combinaison raster-vecteur.

## Pré-requis

- J1 et J2 validés.
- Q6 du J2 terminé (GeoPackage multi-couches dans `outputs/`).
- Un GeoTIFF SRTM Cameroun déjà téléchargé dans `datasets/cameroun/elevation/` (via `elevatr::get_elev_raster()` ou manuellement).

## Fichiers du jour

`README.md`, `slides.qmd`, `demo.qmd`, `demo.R`, `runtime.qmd`, `exercice.qmd`, `corrige.qmd`.
