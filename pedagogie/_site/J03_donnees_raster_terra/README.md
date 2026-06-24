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

## Données utilisées

### Embarqué dans le repo (chargé automatiquement par le runtime WebR)

- `pedagogie/_commons/data/cmr_srtm/srtm_cmr_30s.tif` — MNT SRTM agrégé à 30 arc-sec (~1 km), GeoTIFF mono-bande `elevation_m`, ~3 Mo. Source : NASA/USGS SRTM via `geodata::elevation_30s("CMR")`, crop + mask sur GADM ADM0. Pipeline de génération : `pedagogie/_commons/data/cmr_srtm/00_telecharger_srtm.R` (exécuté une fois côté animateur, .tif commit dans le repo). Helper : `fetch_srtm_cameroon()`.
- `pedagogie/_commons/data/gadm41_CMR_0.json` — GADM v4.1 Cameroun niveau national (silhouette pays), GeoJSON. Source : https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_0.json. Helper : `fetch_gadm_cameroon(0)`.
- `pedagogie/_commons/data/gadm41_CMR_1.json` — GADM v4.1 niveau ADM1 (10 régions). Source : https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_1.json. Helper : `fetch_gadm_cameroon(1)`.
- `pedagogie/_commons/data/gadm41_CMR_2.json` — GADM v4.1 niveau ADM2 (58 départements), utilisé par `corrige.qmd` Q4. Source : https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_2.json. Helper : `fetch_gadm_cameroon(2)`.
- `pedagogie/_commons/data/gadm41_CMR_3.json` — GADM v4.1 niveau ADM3 (~360 arrondissements), utilisé pour le cas RGPH 4 et le devoir Q6. Source : https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_3.json. Helper : `fetch_gadm_cameroon(3)`.

### À télécharger manuellement (optionnel, bonus pour le devoir Q6 desktop)

| Fichier | Emplacement attendu | Source | Taille | Comment l'obtenir |
|---|---|---|---|---|
| `cmr_pop_2020_CN_100m_R2025A_v1.tif` (WorldPop, optionnel pour bonus Q6) | `pedagogie/datasets/cameroun/jour_07_population/` ou repo Edith `jour_07_cartographie_population_haute_resolution/data/` | https://hub.worldpop.org/geodata/summary?id=49866 | ~25–30 Mo | Inscription gratuite WorldPop, choisir « Population Counts → Constrained → Cameroon → 2020 » ; helper `fetch_worldpop_constrained_cmr()` (réutilisé en J7). |

**Note** : aucun téléchargement n'est obligatoire pour J3. Toute la journée tourne sur les 5 fichiers embarqués ci-dessus. WorldPop n'est sollicité que pour le bonus Q6 (croisement altitude × population dans les 20 arrondissements les plus bas) ; la branche principale du devoir s'en passe.

Pour régénérer le MNT SRTM (si besoin) : `Rscript pedagogie/_commons/data/cmr_srtm/00_telecharger_srtm.R`.

## Pré-requis

- J1 et J2 validés.
- Q6 du J2 terminé (GeoPackage multi-couches dans `outputs/`).
- Les 5 datasets embarqués listés ci-dessus sont présents dans le repo après `git clone` — aucun téléchargement préalable n'est requis pour la journée.

## Fichiers du jour

`README.md`, `slides.qmd`, `demo.qmd`, `demo.R`, `runtime.qmd`, `exercice.qmd`, `corrige.qmd`, `install_packages_day.R` (installation ciblée des packages introduits ce jour : `terra`, `exactextractr`, `tidyterra`).
