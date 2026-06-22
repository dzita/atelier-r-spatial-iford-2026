# J9 — Applications spatiales et sciences sociales

**Atelier IFORD × GDSG · Jeudi 6 août 2026 · Yaoundé · 6 heures**

> Conception pédagogique complète : **Edith Darin** (Senior Researcher, ex-WorldPop/Université d'Oxford, GDSG/IFORD). Intégration convention atelier IFORD + bascule WebR : **Ramesesse Dzita** (Junior Demographer-Statistician, IT Specialist, GDSG). Les 13 exercices et le contenu théorique sont calqués textuellement sur le matériel d'Edith ; le présent document conserve fidèlement ses choix méthodologiques.

## Objectifs pédagogiques

### Partie I — ACLED (conflits armés)

1. Découvrir ACLED comme **source de données géoréférencées sur les conflits armés**.
2. Créer un compte myACLED et télécharger des données via ACLED Explorer.
3. Utiliser le package **`acledR`** pour interroger l'API depuis R.
4. Analyser l'**évolution temporelle** (annuelle, mensuelle) des conflits au Cameroun.
5. Convertir des données tabulaires en couche `sf` et les cartographier avec `tmap`.
6. **Agréger** des événements par région via jointure spatiale (`st_within`).

### Partie II — ERA5 (température)

7. Comprendre ce qu'est une **réanalyse climatique** et la ressource ERA5.
8. Créer un compte CDS (Copernicus) et configurer le package **`ecmwfr`**.
9. Soumettre une requête API pour télécharger des **données mensuelles de température**.
10. Comprendre le format **NetCDF** et le lire avec `terra::rast()`.
11. Convertir les températures de **Kelvin en Celsius**.
12. Extraire des statistiques zonales par région avec `exactextractr`.
13. Visualiser la **série temporelle et la saisonnalité** de la température.
14. Cartographier la **température moyenne** avec `tmap` + carte d'**anomalie** dernière vs première année.

## Déroulé horaire (6 h selon programme officiel)

| Moment | Contenu |
|---|---|
| **Matin 1 (1 h 30)** | ACLED : source, types d'événements, compte myACLED, ACLED Explorer, API + package `acledR` |
| **Matin 2 (1 h 30)** | ERA5 : réanalyse, produits, CDS, NetCDF, package `ecmwfr`, requête API |
| **Après-midi 1 (1 h 30)** | TD R Partie I — exercices 1 à 6 : ACLED chargement, nettoyage, temporel, cartographie, agrégation, export |
| **Après-midi 2 (1 h 30)** | TD R Partie II — exercices 7 à 12 : ERA5 authentification, NetCDF, extraction, série, carte moyenne, anomalie |

## Les 13 exercices (architecture Edith)

### Partie I — ACLED

| Ex | Thème | Notion clé |
|---|---|---|
| 1 | Chargement ACLED Data.csv (ou via API `acledR`) | `read_csv`, `glimpse` |
| 2 | Nettoyage : dates, filtre 10 ans, NA coordonnées | `as.Date`, `filter`, `mutate` |
| 3 | Exploration : types d'événements, régions concernées | `count(sort = TRUE)` |
| 4 | Évolution temporelle (annuelle, mensuelle, décès) | `geom_col`, `geom_line`, `scale_x_continuous` |
| 5 | Cartographie : points par type + choroplèthe par région | `st_as_sf`, `tm_dots`, `st_join + st_within` |
| 6 | Export GPKG + CSV + PNG | `st_write`, `write_csv`, `tmap_save` |

### Partie II — ERA5

| Ex | Thème | Notion clé |
|---|---|---|
| 7 | Authentification CDS + requête API | `ecmwfr::wf_set_key`, `wf_request` |
| 8 | Lecture NetCDF + conversion Kelvin → Celsius | `terra::rast`, `nlyr`, `time`, `- 273.15` |
| 9 | Extraction par région (multi-couches) | `exact_extract`, `pivot_longer`, `mean.X` → `idx → date` |
| 10 | Évolution temporelle (série nationale, par région, saisonnalité) | `geom_line`, `geom_smooth(loess)`, `geom_ribbon` |
| 11 | Carte température moyenne + carte anomalie dernière/première année | `tm_raster`, `tm_scale_continuous` divergent `midpoint=0` |
| 12 | Export CSV + GeoTIFF + PNG | `writeRaster`, `tmap_save` |

## Points de vigilance méthodologiques

### ACLED

- Le CSV fourni ne couvre que **2025** (export de démonstration). Pour 10 ans, télécharger un export multi-années depuis ACLED Explorer ou faire la démo en direct avec `acledR::acled_api()`.
- Montrer l'usage du fichier **`.env`** pour les identifiants (voir `.env.example`). Le fichier `.env` ne doit **JAMAIS** être commité (déjà dans `.gitignore`).
- Couverture **dépend des sources médiatiques** — les zones enclavées sont sous-représentées.
- Le **nombre d'événements ≠ intensité de la violence** : un événement isolé à 100 morts est codé pareillement qu'un événement à 1 mort.
- Certains points proches des frontières peuvent tomber hors des polygones GADM avec `st_within` — mentionner `st_nearest_feature` comme alternative.

### ERA5

- Le fichier NetCDF doit être **téléchargé avant la session** (la requête CDS prend plusieurs minutes). Placer le fichier dans `pedagogie/datasets/cameroun/jour_09_acled_era5/era5_t2m_mensuel_cameroun.nc`.
- La requête couvre : `reanalysis-era5-single-levels-monthly-means`, variable `2m_temperature`, **bounding box Cameroun** (N=13.1, W=8.4, S=1.6, E=16.2), toutes les années sur 10 ans.
- Rappeler systématiquement la **conversion Kelvin → Celsius** (`-273.15`).
- ERA5 est une **réanalyse, pas des observations directes** — les zones sans stations météo dépendent du modèle.
- **Résolution de 31 km** : pas adaptée à l'analyse intra-urbaine.
- `exact_extract()` retourne un `data.frame` avec **autant de colonnes que de couches raster** — la mise en forme longue avec `pivot_longer` est une étape clé à détailler.

## Packages utilisés

- `sf`, `dplyr`, `tidyr`, `readr`, `ggplot2`, `scales` — pipeline standard (recyclage J1-J6)
- `terra` — raster (recyclage J3)
- `tmap` — cartographie statique (recyclage J5)
- `exactextractr` — statistiques zonales multi-couches (recyclage J3, J7)
- **`acledR`** — API ACLED (nouveau du jour, optionnel pour la démo en direct)
- **`ecmwfr`** — API Copernicus CDS pour ERA5 (nouveau du jour, optionnel pour télécharger le NetCDF)
- `ncdf4` (optionnel) — exploration NetCDF avancée

## Données mobilisées (100 % réelles, conçues par Edith Darin)

| Élément | Description | Localisation |
|---|---|---|
| `ACLED_Data.csv` | Export ACLED Explorer Cameroun (~quelques milliers de lignes, ~30 colonnes) — `event_date`, `event_type`, `actor1`, `latitude`, `longitude`, `fatalities`, `admin1`, `admin2`, … | `pedagogie/datasets/cameroun/jour_09_acled_era5/` (commité) |
| `gadm41_CMR.gpkg` | GADM v4.1 unifié (couches ADM_ADM_0/1/2) — réutilisé de J7 | `pedagogie/datasets/cameroun/jour_07_population/` (commité) |
| `era5_t2m_mensuel_cameroun.nc` | Réanalyse ERA5 température 2m mensuelle, 120 couches (10 ans × 12 mois), résolution 0.25° (~31 km) — Copernicus CDS / ECMWF | `pedagogie/datasets/cameroun/jour_09_acled_era5/` (**exclu Git**, à télécharger via `ecmwfr`) |
| `.env.example` | Modèle de configuration des identifiants ACLED + CDS — à copier en `.env` localement et compléter avec ses propres identifiants | `pedagogie/datasets/cameroun/jour_09_acled_era5/` (commité) |

**Stratégie Git** : le NetCDF ERA5 (~quelques Mo, ~3-10 selon période) est **exclu du repo** via `.gitignore` — chaque animateur le télécharge via `ecmwfr` avec son propre token CDS. Le CSV ACLED reste commité (léger). Le fichier `.env` (identifiants personnels) est **strictement exclu** et ne doit jamais quitter la machine de l'animateur.

**Helpers de chargement** dans `pedagogie/_commons/helpers/fetch_data.R` :

- `fetch_acled_cmr()` — résout le CSV ACLED (gère plusieurs noms possibles : `ACLED_Data.csv`, `ACLED Data.csv`, `acled_cmr.csv`)
- `fetch_era5_t2m_cmr()` — résout le NetCDF ERA5 (lève une erreur explicite si absent avec lien de téléchargement)
- `fetch_gadm_cmr_gpkg()` — résout le GeoPackage GADM unifié (déjà existant, J7)

## Configuration des identifiants API (.env)

Avant la session, l'animateur doit :

1. **Créer un compte ACLED** : <https://developer.acleddata.com/> (gratuit, instantané)
2. **Créer un compte CDS** : <https://cds.climate.copernicus.eu/> (gratuit, instantané)
3. **Copier `.env.example`** en `.env` dans `pedagogie/datasets/cameroun/jour_09_acled_era5/`
4. **Remplir les 4 valeurs** : `email_address`, `acled_password`, `cds_user`, `cds_key`
5. Le fichier `.env` est **automatiquement exclu** par `.gitignore` — ne jamais le committer.

Pour la session, soumettre la requête ERA5 quelques jours avant pour avoir le NetCDF en cache local.

## Pré-requis

- J1 à J7 validés (J8 est sur la télédétection, complémentaire mais pas bloquant).
- Pack J9 Edith présent localement (Drive `workshop_material/jour_09_*/`).
- Compte myACLED + compte CDS créés (pour la partie API).

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `README.md` | Ce document |
| `slides.qmd` | Diaporama revealjs (calque du `.qmd` PPTX d'Edith) |
| `demo.qmd` | Démonstration HTML — 13 exercices commentés avec convention « expliquer avant chaque commande » |
| `demo.R` | Script court projeté en salle (miroir condensé du script formateur d'Edith) |
| `runtime.qmd` | Version WebR allégée — Partie I ACLED uniquement (ERA5 nécessite NetCDF + API CDS non portables WebR) |
| `exercice.qmd` | Les 13 exercices d'Edith avec questions de réflexion |
| `corrige.qmd` | Solutions commentées (depuis le script formateur d'Edith) |
| `install_packages_day.R` | Installation ciblée (`acledR`, `ecmwfr`, `ncdf4` + recyclages) |

## Crédits

**Conception pédagogique complète** des 13 exercices, des slides théoriques, des choix méthodologiques et des datasets : **Edith Darin** (Senior Researcher, ex-WorldPop/Université d'Oxford, GDSG/IFORD).

**Intégration convention atelier IFORD + bascule WebR + crédits sur le matériel** : **Ramesesse Dzita** (Junior Demographer-Statistician, IT Specialist, GDSG/IFORD).

**Sources des données** :

- **ACLED** — Armed Conflict Location & Event Data Project — <https://acleddata.com/>
- **ERA5** — ECMWF / Copernicus CDS — <https://cds.climate.copernicus.eu/>
- **GADM v4.1** — <https://gadm.org>

**Citation recommandée ACLED** : *Raleigh, C., Linke, A., Hegre, H., & Karlsen, J. (2010). Introducing ACLED: An armed conflict location and event dataset. Journal of Peace Research, 47(5), 651-660.*

**Citation recommandée ERA5** : *Hersbach, H., Bell, B., Berrisford, P., et al. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999-2049.*

Code et matériel pédagogique diffusés sous **CC-BY 4.0** au nom du GDSG/IFORD. Les datasets restent sous leurs licences respectives (ACLED conditions d'usage académique, ERA5 Copernicus Open Data License, GADM académique libre).
