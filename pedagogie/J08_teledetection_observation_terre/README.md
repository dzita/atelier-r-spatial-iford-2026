# J8 — Télédétection et observation de la Terre

**Atelier IFORD × GDSG · Mercredi 5 août 2026 · Yaoundé · 6 heures**

> Conception pédagogique complète : **Edith Darin** (Senior Researcher, ex-WorldPop/Université d'Oxford, GDSG/IFORD). Intégration convention atelier IFORD + bascule WebR : **Ramesesse Dzita** (Junior Demographer-Statistician, IT Specialist, GDSG). Les **12 exercices** et le contenu théorique sont calqués textuellement sur le matériel d'Edith — qui propose ici une architecture en **deux scripts complémentaires** : télédétection GHSL bâti (2015 vs 2025) et inondations EMSR772 Yagoua 2024 + Open Buildings.

## Objectifs pédagogiques

À l'issue de cette journée, chaque participant doit pouvoir :

1. Distinguer **résolution spatiale, spectrale et temporelle** d'une image satellite.
2. Identifier les principales sources ouvertes : **Sentinel, Landsat, MODIS, SRTM, GHSL, Copernicus EMS, Google Open Buildings**.
3. Charger et **mosaïquer des tuiles raster GHSL** avec `terra`.
4. Extraire et **comparer des indicateurs de surface bâtie** (GHSL Built-Up) sur deux dates (2015 et 2025) par unité administrative.
5. Produire des cartes de **gain de bâti** et de **croissance relative** entre deux dates.
6. Construire une **fonction R réutilisable** pour calculer des indicateurs de bâti par territoire.
7. Décrire ce qu'est le **Copernicus Emergency Management Service (EMS)** et son activation **EMSR772** (Yagoua 2024).
8. Charger et explorer les **couches EMS** (`areaOfInterest`, `floodDepth`) et en interpréter les attributs.
9. Charger des fichiers **Google Open Buildings** (CSV.GZ), les convertir en objet spatial et filtrer par niveau de confiance.
10. Calculer le **nombre de bâtiments exposés à une inondation** dans une zone de référence.
11. **Estimer la population exposée** à partir des bâtiments et d'un taux d'occupation.
12. Encapsuler l'analyse en une fonction et la **répliquer sur plusieurs zones** d'activation.
13. Discuter les **limites des données satellite** pour des usages statistiques officiels.

## Déroulé horaire (6 h selon programme officiel)

| Moment | Contenu |
|---|---|
| **Matin 1 (1 h 30)** | Présentation : pixels, bandes, résolutions et revisite ; principales sources ouvertes |
| **Matin 2 (1 h 30)** | Présentation : GHSL bâti et population ; Copernicus EMS ; Open Buildings |
| **Après-midi 1 (1 h 30)** | **Partie I — GHSL** : bâti au Cameroun 2015–2025 (mosaïque, indicateurs, cartes) |
| **Après-midi 2 (1 h 30)** | **Partie II — Inondations EMSR772** : bâtiments et population exposés (Open Buildings) |

## Les 12 exercices (architecture Edith)

### Partie I — GHSL télédétection (`teledetection.R`)

| Section | Thème | Notion clé |
|---|---|---|
| 0 | Inspection des données (GHSL, GADM) | `st_crs`, `print`, `rast` |
| 1 | Indicateurs nationaux 2015 vs 2025 | `exact_extract`, `sum` / 1e6 (en km²) |
| 2 | Indicateurs régionaux ADM1 | fonction `resumer_bati()`, `left_join`, `arrange` |
| 3 | Cartes et graphiques (carte bâti, nuage 2015 vs 2025, top régions) | `ggplot2`, `scale_fill_viridis_c`, `scale_fill_gradient2` |
| 4 | Typologie simple de croissance (faible/modérée/forte) | `case_when`, `median` |
| 5 | Zoom ADM2 — top 10 départements en gain | extraction à niveau fin |
| 6 | Exports CSV + GPKG + PNG | `write_csv`, `st_write`, `ggsave` |

### Partie II — Inondations EMSR772 (`inondations.R`)

| Ex | Thème | Notion clé |
|---|---|---|
| 1 | Explorer les couches Copernicus EMS (AOI, floodDepth) | `st_read`, attribut `value` (tranche profondeur), `st_area` |
| 2 | Charger Open Buildings depuis CSV.GZ | `read_csv` sur `.gz`, `st_as_sf`, filtre `confidence >= 0.7` |
| 3 | Bâtiments dans la zone AOI01 (Yagoua) | `st_filter`, cartographie `tmap` v4 |
| 4 | Estimation de la population dans AOI01 | taux d'occupation (5 pers./bât. par défaut, à documenter) |
| 5 | Bâtiments et population **touchés par l'inondation** | `st_filter` sur couche flood, calcul part (%) |
| 6 | Encapsuler en fonction + reproduire sur AOI02 et AOI03 | `unzip`, `list.files`, `lapply`, `bind_rows` |

## Points de vigilance méthodologiques

- Les rasters **GHSL** sont en projection mondiale equal-area (`ESRI:54009`) — **toujours reprojeter** les limites administratives dans le CRS du raster avant l'extraction zonale.
- Le **gain de bâti absolu** (km²) et la **croissance relative** (%) donnent des lectures très différentes ; présenter les deux.
- Le produit GHSL mesure la **surface bâtie**, pas le nombre de bâtiments ni la population.
- Les inondations EMSR772 sont cartographiées par **télédétection à date fixe** ; des bâtiments construits après la date d'image ne sont pas visibles.
- La colonne `value` de `floodDepthA_v2.shp` donne la **tranche de profondeur en mètres** (ex. « 0.50 - 1.00 »).
- Le **taux d'occupation par bâtiment** (5 pers./bât. par défaut) est une hypothèse grossière ; la calibrer avec des données de recensement locales si disponibles.
- Le filtre **`confidence >= 0.7`** sur Open Buildings élimine les détections incertaines ; **documenter le seuil retenu**.
- Les fichiers **AOI02 et AOI03** de EMSR772 sont distribués compressés (ZIP) — les décompresser avant de lancer l'analyse.

## Cas central : EMSR772 — Yagoua (Mayo-Danay) octobre 2024

| Information | Valeur |
|---|---|
| Code Copernicus | **EMSR772** |
| GLIDE number | FL-2024-000162-CMR |
| Zone | Nord Cameroun, région de Yagoua, bassin du Logone |
| Date d'activation | 25 octobre 2024 |
| Bilan humain (UNICEF/DG ECHO) | 30 morts, 155 000 déplacés, 365 000 affectés |
| Bâti et cultures détruits | 56 084 maisons, 82 500 ha de cultures, 262 écoles |
| Surface inondée AOI01 | 22 987 ha |
| Population estimée affectée (AOI01) | ~8 300 habitants (sur ~870 000 dans le département) |
| Données pré/post | Sentinel-2A/B (23/01/2024 vs 24/10/2024, résolution 10 m) |
| DEM utilisé | FABDEM (Copernicus GLO-30 corrigé bâtiments+arbres) |
| 3 zones AOI | AOI01 (Yagoua), AOI02, AOI03 |

## Packages utilisés

- `sf`, `terra` — vecteurs et rasters (recyclage J2, J3)
- `dplyr`, `tidyr`, `readr` — manipulation tabulaire (recyclage J4)
- `ggplot2`, `tmap` v4 — cartographie statique (recyclage J5)
- `exactextractr` — statistiques zonales multi-couches (recyclage J3, J7)
- `scales` — formatage des étiquettes
- **`R.utils`** — décompression GZ pour Open Buildings (nouveau du jour)

## Données utilisées

### Embarqué dans le repo (chargé automatiquement par le runtime WebR)

Extraits Yagoua produits une fois pour toutes depuis le poste formateur par `00_construire_extraits_webr_yagoua.R` (filtrage de la bbox AOI01 + buffer 1 km, reprojection EPSG:4326, validation des géométries) :

- `pedagogie/_commons/data/jour_08_extraits/aoi01_yagoua.geojson` — polygone Copernicus EMSR772 AOI01 (zone d'intérêt Yagoua), ~50 ko, source [Copernicus EMSR772](https://emergency.copernicus.eu/mapping/list-of-components/EMSR772).
- `pedagogie/_commons/data/jour_08_extraits/flood01_yagoua.geojson` — polygones d'inondation `floodDepthA_v2` ventilés par classe de profondeur, ~200 ko, même source.
- `pedagogie/_commons/data/jour_08_extraits/batiments_yagoua.geojson` — empreintes Google Open Buildings sur la zone (filtrage `confidence >= 0.7`), ~2-5 Mo (~10 000 bâtiments), source [Google Open Buildings](https://sites.research.google/open-buildings/).

Réutilisé de J7 (déjà embarqué) pour la carte de cadrage régional :

- `pedagogie/_commons/data/jour_07_extraits/gadm41_CMR_adm1.geojson` — 10 régions du Cameroun, source [GADM v4.1](https://gadm.org).

### À télécharger manuellement (utilisé par `demo.qmd` desktop, trop lourd pour le repo)

Tous ces fichiers sont en `.gitignore` (volume total ~500 Mo). Chemins attendus résolus par les helpers `fetch_*()` dans `pedagogie/_commons/helpers/fetch_data.R`.

| Fichier / Dossier | Emplacement attendu | Source officielle | Taille | Comment l'obtenir |
|---|---|---|---|---|
| `gadm41_CMR.gpkg` | `pedagogie/datasets/cameroun/jour_07_population/` | <https://gadm.org/download_country.html> (Cameroun, GeoPackage) | ~30 Mo | Téléchargement direct (réutilisé depuis J7) — helper `fetch_gadm_cmr_gpkg()`. |
| `cmr_pop_2024_CN_100m_R2025A_v1.tif` | `pedagogie/datasets/cameroun/jour_08_teledetection/` | WorldPop constrained 100m R2025A — <https://hub.worldpop.org/> | ~25 Mo | Hub WorldPop, filtre Cameroun + année 2024 — helper `fetch_worldpop_2024_cmr()`. |
| `GHS-BUILT/` (15 tuiles ZIP) | `pedagogie/datasets/cameroun/jour_08_teledetection/GHS-BUILT/` | JRC Copernicus GHSL Built-Up Surface R2023A — <https://human-settlement.emergency.copernicus.eu/download.php?ds=bu> | ~300 Mo | 8 tuiles 2025 + 7 tuiles 2015 couvrant le Cameroun (Mollweide, 100 m) — helper `fetch_ghs_built_dir()`. |
| `EMSR772_products/` (3 ZIP AOI01-03) | `pedagogie/datasets/cameroun/jour_08_teledetection/EMSR772_products/` | Copernicus Emergency Management Service — <https://emergency.copernicus.eu/mapping/list-of-components/EMSR772> | ~50 Mo | Téléchargement direct libre (3 AOI : Yagoua + 2 zones voisines) — helper `fetch_emsr772_dir()`. |
| `Open Buildings/` (CSV.GZ tuiles S2) | `pedagogie/datasets/cameroun/jour_08_teledetection/Open Buildings/` | Google Open Buildings — <https://sites.research.google/open-buildings/> | ~100 Mo | Téléchargement des tuiles S2 couvrant le nord Cameroun (colonnes `latitude`, `longitude`, `area_in_meters`, `confidence`) — helper `fetch_open_buildings_dir()`. |

Pour régénérer les extraits WebR à partir des datasets lourds après mise à jour : `Rscript pedagogie/J08_teledetection_observation_terre/00_construire_extraits_webr_yagoua.R`.

## Pré-requis

- J1 à J7 validés.
- Pack J8 Edith présent localement (Drive `workshop_material/jour_08_*/`).

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `README.md` | Ce document |
| `slides.qmd` | Diaporama revealjs (calque du `.qmd` PPTX d'Edith) |
| `demo.qmd` | Démonstration HTML — 12 exercices commentés (Partie I GHSL + Partie II Inondations) |
| `demo.R` | Script court projeté en salle (miroir condensé des 2 scripts formateur d'Edith) |
| `runtime.qmd` | Version WebR allégée — extraits Yagoua (GHSL pas portable, on illustre les bâtiments + inondation seulement) |
| `exercice.qmd` | Les 12 exercices d'Edith avec questions de réflexion |
| `corrige.qmd` | Solutions commentées |
| `install_packages_day.R` | Installation ciblée (`R.utils` pour GZ, terra, tmap, exactextractr) |

## Crédits

**Conception pédagogique complète** des 12 exercices, des slides théoriques, des choix méthodologiques et des datasets : **Edith Darin** (Senior Researcher, ex-WorldPop/Université d'Oxford, GDSG/IFORD).

**Intégration convention atelier IFORD + bascule WebR + crédits sur le matériel** : **Ramesesse Dzita** (Junior Demographer-Statistician, IT Specialist, GDSG/IFORD).

**Sources des données** :

- **GHS-BUILT** — Global Human Settlement Layer Built-Up Surface, Commission européenne (JRC) — <https://human-settlement.emergency.copernicus.eu/>
- **Copernicus EMSR772** — Copernicus Emergency Management Service — <https://mapping.emergency.copernicus.eu/>
- **Google Open Buildings** — Google Research — <https://sites.research.google/open-buildings/>
- **WorldPop** — Univ. Southampton — <https://hub.worldpop.org/>
- **GADM v4.1** — <https://gadm.org/>

**Citation recommandée** :

- *Schiavina, M., Melchiorri, M., Pesaresi, M., et al. (2023). GHSL Data Package 2023, Publications Office of the European Union, JRC.*
- *Copernicus Emergency Management Service (2024). EMSR772 Activation report — Floods in Cameroon. European Commission.*

Code et matériel pédagogique diffusés sous **CC-BY 4.0** au nom du GDSG/IFORD. Les datasets restent sous leurs licences respectives (GHSL CC-BY 4.0, Copernicus EMS open data, Open Buildings CC-BY 4.0, WorldPop CC-BY 4.0).
