# J5 — Visualisation et cartographie : `tmap` et `ggplot2`

**Atelier IFORD × GDSG · Vendredi 31 juillet 2026 · Yaoundé · 6 heures**

## Objectifs pédagogiques

À la fin de J5, chaque participant doit pouvoir :

1. Construire une carte choroplèthe propre avec `tmap` v4 — choisir une classification, une palette, un découpage adapté à la donnée.
2. Basculer entre le mode statique (`tmap_mode("plot")`) pour la publication et le mode interactif (`tmap_mode("view")`) pour l'exploration.
3. Produire la même carte en `ggplot2 + geom_sf` quand l'intégration à un rapport scientifique le justifie.
4. Décorer une carte de production : titre, sous-titre, légende, flèche du nord, échelle, crédits.
5. Empiler plusieurs cartes côte à côte avec `tmap_arrange()` pour comparer deux indicateurs.
6. Exporter en PNG haute résolution, en PDF vectoriel et en HTML interactif.

## Déroulé horaire (6 h selon programme officiel)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J4 + intro J5 | 30 min | Slides |
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

## Données utilisées

### Embarqué dans le repo (chargé automatiquement par le runtime WebR)

- `pedagogie/_commons/data/gadm41_CMR_1.json` — polygones GADM v4.1 des 10 régions du Cameroun (ADM1), format GeoJSON, ~150 Ko. Source officielle : <https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_CMR_1.json> (helper `fetch_gadm_cameroon(1)` dans `pedagogie/_commons/helpers/fetch_data.R`).
- `pedagogie/_commons/data/dhs_cmr/indicateurs_dhs_cmr_2018.csv` — 5 indicateurs EDS-MICS Cameroun 2018 calculés localement depuis les microfichiers HR + IR + MR via `srvyr` (plan de sondage stratifié à deux degrés). Format long CSV (50 lignes = 10 régions × 5 indicateurs), < 5 Ko. Indicateurs : eau améliorée (JMP), électricité, taille moyenne du ménage, alphabétisation femmes 15-49, alphabétisation hommes 15-59. Source : DHS Program — Cameroon Standard DHS 2018 (<https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm>).

### À télécharger manuellement (utilisé uniquement pour régénérer le CSV)

| Fichier | Emplacement attendu | Source | Taille | Comment l'obtenir |
|---|---|---|---|---|
| Microfichiers DHS Cameroun 2018 (`CMHR71DT/`, `CMIR71DT/`, `CMMR71DT/` au format Stata `.DTA`) | `pedagogie/datasets/cameroun/CM_2018_DHS/` | DHS Program | ~300-500 Mo total | Inscription gratuite sur <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm>, accepter le projet, télécharger les recodes Household, Individual, Men en Stata. |

Pour régénérer le CSV embarqué (rare, déjà commité) : `Rscript pedagogie/_commons/data/dhs_cmr/00_telecharger_dhs_indicateurs.R`. Aucune simulation : les valeurs sont calculées avec le même plan de sondage que les indicateurs officiels ICF.

## Pré-requis

- J1 à J4 validés
- Q6 du J4 terminé (table d'indicateurs jointe à un fond ADM)

## Fichiers du jour

`README.md`, `slides.qmd`, `demo.qmd`, `demo.R`, `runtime.qmd`, `exercice.qmd`, `corrige.qmd`, `install_packages_day.R` (installation ciblée des packages introduits ce jour : `tmap`, `classInt`, `RColorBrewer`, `viridisLite`, `leaflet`, `ggspatial`).
