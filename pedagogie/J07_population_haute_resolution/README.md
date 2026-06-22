# J7 — Cartographie de la population à haute résolution

**Atelier IFORD × GDSG · Mardi 4 août 2026 · Yaoundé · 6 heures**

> Conception pédagogique complète : **Edith Darin** (Senior Researcher, ex-WorldPop/Université d'Oxford, GDSG/IFORD). Intégration convention atelier IFORD + bascule WebR : **Ramesesse Dzita** (Junior Demographer-Statistician, IT Specialist, GDSG). Les 9 exercices et le contenu théorique sont calqués textuellement sur le matériel d'Edith ; le présent document conserve fidèlement ses choix méthodologiques.

## Objectifs pédagogiques

À l'issue de cette journée, chaque participant doit pouvoir :

1. Distinguer les approches **top-down** (WorldPop, GPW, LandScan) et **bottom-up** (GHSL) de la cartographie de la population à haute résolution.
2. Expliquer ce qu'est une projection démographique WorldPop et ses limites.
3. Relier une table de population à des limites administratives et produire un choropleth.
4. Charger et explorer un raster de population (WorldPop 100 m) avec `terra` et `tmap`.
5. Utiliser `tmap` en mode interactif (`view`) et statique (`plot`) pour communiquer des résultats.
6. Extraire un effectif de population sur une zone définie (limite administrative, zone dessinée manuellement) via `crop` + `mask` + `global`.
7. Agréger une grille de population par unité administrative avec `exactextractr`.
8. Comparer trois grilles temporelles (2015, 2025, 2030) sur une échelle commune et tracer l'évolution.
9. Assembler des tuiles GHSL avec `mosaic`, rogner au pays et comparer les effectifs avec WorldPop.
10. Calculer et interpréter des indicateurs dérivés : ratio F/H, part des jeunes, densité, croissance.

## Déroulé horaire (6 h selon programme officiel)

| Moment | Contenu | Format |
|---|---|---|
| Matin 1 (1 h 30) | Approches top-down / bottom-up, projections, produits mondiaux (WorldPop, GHSL, GPW, LandScan) | Slides |
| Matin 2 (1 h 30) | Sources de données, résolution spatiale, comparaison WorldPop vs GHSL, mosaïque, `tmap` | Slides |
| Après-midi 1 (1 h 30) | Atelier R — exercices 0, 0b, 0c, 1 (choropleth, ratio F/H, jeunes, grille) | demo + exercice |
| Après-midi 2 (1 h 30) | Atelier R — exercices 2 à 8 (Yaoundé 2015/2025/2030, zones, densité, âges, GHSL) | demo + exercice |

## Les 12 exercices (architecture Edith)

| Exercice | Thème | Notion clé |
|---|---|---|
| 0 | Choropleth population totale | `left_join`, `setdiff`, `ggplot2` |
| 0b | Ratio femmes/hommes | variable dérivée, `scale_fill_gradient2(midpoint = 1)` |
| 0c | Part de la population jeune (0-14 ans) | agrégation de colonnes d'âge, jointure enrichie |
| 1 | Grille WorldPop 2025 avec tmap | `rast`, `tmap_mode`, `tm_scale_intervals` |
| 2 | Population à Yaoundé (Mfoundi) en 2025 | `crop`, `mask`, `global`, mode satellite |
| 3 | Population à Yaoundé en 2015 *(à compléter par les étudiants)* | réutilisation du code de l'exercice 2 |
| 4 | Comparaison 2015-2025, agrégation par région | `exactextractr`, breaks communs, `tmap_arrange` |
| 4b | Projection WorldPop 2030 — évolution sur 15 ans | `tibble`, `geom_line`, carte 3 panels |
| 5 | Zone personnalisée dessinée à la main | `mapedit::editMap`, sensibilité au contour |
| 5b | Comparer plusieurs villes (Douala, Yaoundé, Bafoussam, Bamenda, Garoua) | `lapply`, `bind_rows` |
| 6 | Densité de population (hab/km²) | `st_area`, échelle log |
| 7 | Distribution par âge entre deux régions | `pivot_longer`, `geom_col` |
| 8 | GHSL-POP — mosaïque, reprojection, rognage, comparaison | `sprc`, `mosaic`, `project`, comparaison WorldPop vs GHSL |

## Points de vigilance méthodologiques

- Toujours comparer `ADM1_EN` et `ADM1_FR` avant de choisir la clé de jointure GADM/COD.
- WorldPop est un **modèle**, pas une observation directe — les totaux diffèrent du recensement officiel.
- Une comparaison temporelle nécessite des **breaks communs** pour éviter un biais visuel.
- Les projections 2030 reposent sur des hypothèses de fécondité et de migration — les présenter avec prudence.
- GHSL (bottom-up) et WorldPop constrained (top-down) produisent des totaux différents ; expliquer pourquoi avant de conclure.
- `editMap()` requiert une session R interactive (ne fonctionne pas en mode non-interactif).

## Packages utilisés

- `sf`, `terra` — vecteurs et rasters (recyclage J2, J3)
- `dplyr`, `tidyr`, `readr` — manipulation tabulaire (recyclage J4)
- `ggplot2`, **`tmap`** — cartographie statique et interactive (recyclage J5)
- **`exactextractr`** — statistiques zonales rapides sur gros rasters (recyclage J3)
- `scales` — formatage des étiquettes (recyclage J5)
- **`mapedit`** + `leaflet` — édition interactive de polygones (nouveau du jour)

## Données mobilisées (100 % réelles, conçues par Edith Darin)

| Élément | Description | Localisation |
|---|---|---|
| `cmr_admpop_adm1_2025.csv` | Population administrative par région — source : OCHA COD-PS Cameroun (T_TL, F_TL, M_TL, T_00_04, …, T_80Plus, ADM1_EN, ADM1_FR, ADM1_PCODE) | `pedagogie/datasets/cameroun/jour_07_population/` (commité) |
| `gadm41_CMR.gpkg` | GADM v4.1 unifié en GeoPackage (couches `ADM_ADM_0`, `ADM_ADM_1`, `ADM_ADM_2`) | idem |
| `gadm41_CMR_shp.zip` | Variante Shapefile (fallback) | idem |
| `cmr_pop_2015_CN_100m_R2025A_v1.tif` | WorldPop constrained 2015, 100 m, Release 2025A v1 — Univ. Southampton | idem (raster `.tif`, **exclu Git**) |
| `cmr_pop_2025_CN_100m_R2025A_v1.tif` | WorldPop constrained 2025 | idem |
| `cmr_pop_2030_CN_100m_R2025A_v1.tif` | Projection WorldPop 2030 | idem |
| `GHS-POP/*.zip` | 7 tuiles GHS-POP R2023A Mollweide (R7_C20, R8_C19, R8_C21, R9_C19/20/21, R10_C20) couvrant le Cameroun — JRC Commission européenne | idem (sous-dossier **exclu Git**) |
| `DATA_ECOLE.zip` | Bonus pédagogique d'Edith (à explorer dans le module 8 ou en autonomie) | idem (commité) |

**Stratégie Git** : les rasters TIF + ZIP GHS-POP totalisent ~225 Mo et sont **exclus du repo** via `.gitignore` (resteront en local sur la machine de l'animateur). Les CSV, GeoPackage et `DATA_ECOLE.zip` (< 8 Mo total) sont commités. Le runtime WebR consomme des extraits Mfoundi/Yaoundé produits par `pedagogie/_commons/data/jour_07_extraits/00_extraire_pop_pour_webr.R`.

**Helpers de chargement** dans `pedagogie/_commons/helpers/fetch_data.R` :

- `fetch_worldpop_constrained_cmr(year)` — résout les TIF WorldPop pour 2015, 2025, 2030
- `fetch_gadm_cmr_gpkg()` — résout le GeoPackage GADM unifié
- `fetch_admpop_adm1_cmr_2025()` — résout le CSV de population administrative
- `fetch_ghspop_tuiles_dir()` — résout le dossier des tuiles GHS-POP
- `fetch_data_ecole_cmr()` — résout le bonus DATA_ECOLE

## Pré-requis

- J1 à J6 validés.
- Q6 du J6 terminé.
- Pack J7 Edith présent localement (déposé sur le Google Drive partagé, ou téléchargé via la procédure README de `_commons/data/jour_07_extraits/`).

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `README.md` | Ce document |
| `slides.qmd` | Diaporama revealjs (calque du `.qmd` PPTX d'Edith) |
| `demo.qmd` | Démonstration HTML — 9 exercices commentés avec convention « expliquer avant chaque commande » |
| `demo.R` | Script court projeté en salle (miroir condensé du script formateur d'Edith) |
| `runtime.qmd` | Version WebR allégée — extraits Mfoundi/Yaoundé uniquement (raster complet trop lourd pour WebR) |
| `exercice.qmd` | Les 9 exercices d'Edith avec leurs 14 questions, format Quarto HTML |
| `corrige.qmd` | Solutions commentées (depuis le script formateur d'Edith) |
| `install_packages_day.R` | Installation ciblée (`mapedit`, `exactextractr`, `scales` + recyclages) |

## Crédits

**Conception pédagogique complète des 9 exercices, des slides théoriques, des choix méthodologiques et des datasets** : Edith Darin (Senior Researcher, ex-WorldPop/Université d'Oxford, GDSG/IFORD).

**Intégration dans la convention atelier IFORD, bascule WebR + crédits sur le matériel** : Ramesesse Dzita (Junior Demographer-Statistician, IT Specialist, GDSG/IFORD).

**Sources des données** :
- WorldPop, University of Southampton — <https://hub.worldpop.org>
- GHS-POP / GHSL, Commission européenne (JRC) — <https://human-settlement.emergency.copernicus.eu>
- COD-PS Cameroun, OCHA — <https://data.humdata.org/dataset/cod-ps-cmr>
- GADM v4.1 — <https://gadm.org>

Code et matériel pédagogique diffusés sous **CC-BY 4.0** au nom du GDSG/IFORD. Les datasets restent sous leurs licences respectives (WorldPop CC-BY 4.0, GHSL CC-BY 4.0, GADM académique libre, COD-PS OCHA).
