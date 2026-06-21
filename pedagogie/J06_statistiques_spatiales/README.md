# J6 — Statistiques spatiales et analyse

**Atelier IFORD × GDSG · Samedi 1ᵉʳ août 2026 · Yaoundé · 6 heures**

> Co-auteur du contenu pédagogique : **Jean Saturnin Alogo Samba** (Statistician, IT & GIS, GDSG / IFORD). Le matériel reprend son cas d'étude des 80 établissements de santé du Cameroun et son pipeline complet (motifs ponctuels → KDE → Moran's I → LISA).

## Objectifs pédagogiques

À la fin de J6, chaque participant doit pouvoir :

1. Décider si une distribution de points est **regroupée**, **dispersée** ou **aléatoire** via la distance moyenne au plus proche voisin (ratio R).
2. Produire une **estimation de densité par noyau** (KDE) avec un bandwidth justifié (règle de Scott).
3. Calculer et interpréter l'**indice de Moran's I global** (autocorrélation spatiale) avec son test de significativité.
4. Identifier des **points chauds et points froids** via les indicateurs locaux LISA et leur classification HH / LL / HL / LH.
5. Mobiliser ces statistiques sur un cas réel camerounais : la répartition des établissements de santé.

## Déroulé horaire (6 h)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J5 + intro J6 | 30 min | Slides |
| **Théorie 1** — Pourquoi mesurer l'autocorrélation spatiale ? | 30 min | Slides |
| **Démo 1** — Motifs ponctuels (distance au plus proche voisin) | 45 min | demo + Q1 |
| **Théorie 2** — Estimation de densité par noyau (KDE) | 30 min | Slides |
| **Démo 2** — KDE sur les établissements de santé | 45 min | demo + Q2 |
| **Théorie 3** — Moran's I et autocorrélation | 45 min | Slides |
| **Démo 3** — Moran's I global + diagramme de Moran | 45 min | demo + Q3 |
| **Théorie 4** — LISA et points chauds | 30 min | Slides |
| **Démo 4** — LISA local + cartographie HH/LL/HL/LH | 45 min | demo + Q4–Q5 |
| Synthèse + Q6 + Q&A | 15 min | Slides |

## Packages utilisés

- `sf` — données spatiales (hérité)
- `dplyr`, `tibble` — manipulation
- `ggplot2` — cartes et graphiques
- `spdep` — autocorrélation spatiale (`knearneigh`, `nb2listw`, `moran.test`, `localmoran`, `lag.listw`)

## Données mobilisées (100 % réelles)

| Élément | Description |
|---|---|
| `etablissements_sante_osm.csv` | Facilités de santé OpenStreetMap du Cameroun (téléchargement Overpass : `amenity ∈ {hospital, clinic, doctors, pharmacy}` + `healthcare = *`). Colonnes : `osm_id`, `nom`, `type`, `operateur`, `ville`, `region_osm`, `longitude`, `latitude`, `categorie ∈ {Hopital, Centre/Clinique, Pharmacie, Autre}`. |
| `gadm41_CMR_2.json` | Polygones GADM v4.1 des départements (ADM2) du Cameroun, utilisés pour l'agrégation spatiale. |

**Pipeline de production** : `00_telecharger_osm_sante.R` (à exécuter UNE
fois sur la machine de l'animateur, puis commit du CSV produit). Aucune
variable simulée : la variable d'analyse statistique (Moran, LISA) est
`n_facilites` par département, **comptée par jointure spatiale** entre les
points OSM et les polygones ADM2. Le runtime WebR charge directement le
CSV et le JSON (osmdata et spdep n'étant pas portables sur WebR, la
matrice de contiguïté est recodée à la main avec `st_touches()`).

## Pré-requis

- J1 à J5 validés.
- Q6 du J5 terminé.

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `README.md` | Ce document |
| `slides.qmd` | Diaporama revealjs : motifs, KDE, Moran, LISA |
| `demo.qmd` | Démonstration HTML avec explication avant chaque bloc R |
| `demo.R` | Script de Saturnin condensé, projection en salle |
| `runtime.qmd` | Version WebR — génère les données inline + analyses |
| `exercice.qmd` | Q1 à Q6 |
| `corrige.qmd` | Solutions commentées |
| `install_packages_day.R` | Installation ciblée (`spdep` est le nouveau du jour) |

## Crédits

Conception pédagogique de l'étude de cas : **Jean Saturnin Alogo Samba** (GDSG / IFORD).
Intégration convention atelier : **Ramesesse Dzita**.
Diffusion sous **CC-BY 4.0**.
