# J4 — Gestion des données pour l'analyse spatiale

**Atelier IFORD × GDSG · Jeudi 30 juillet 2026 · Yaoundé · 6 heures**

> Architecture pédagogique modulaire : **Jean Saturnin Alogo Samba** (Statistician, IT & GIS, GDSG / IFORD). Bascule sur le microfichier DHS Cameroun 2018 réel : **Ramesesse Dzita** (Junior Demographer-Statistician, IT Specialist, GDSG). Les six modules conçus par Saturnin sont préservés intégralement ; seule la source de données change, des CSV simulés vers l'EDS-MICS Cameroun 2018 officiel.

## Objectifs pédagogiques

À la fin de J4, chaque participant doit pouvoir :

1. Maîtriser le pipe `|>` et l'enchaînement des verbes `dplyr` (`select`, `filter`, `mutate`, `arrange`, `group_by`, `summarise`, `count`).
2. Pratiquer les **cinq jointures** de `dplyr` (`left_join`, `inner_join`, `full_join`, `semi_join`, `anti_join`) sur une structure hiérarchique réelle (HR ménages ↔ PR personnes avec double clé `(cluster_id, menage_id)`).
3. Détecter, localiser et traiter les **valeurs manquantes** selon leur mécanisme (MCAR / MAR / MNAR) — suppression, imputation par médiane de groupe, mode statistique, gestion des NA structurels.
4. Comprendre le **plan de sondage stratifié à deux degrés** d'une EDS-MICS et appliquer les **pondérations** correctement avec `survey` + `srvyr`, intervalles de confiance compris.
5. Construire une table d'indicateurs **par région ADM1** (taux d'électrification, d'alphabétisation, etc.) qui servira d'entrée à la cartographie de J5.
6. Joindre cette table aux polygones GADM ADM1 via une fonction de normalisation des noms régions (DHS minuscules anglais ↔ GADM majuscules françaises).

## Déroulé horaire (6 h selon programme officiel)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J3 + intro J4 | 30 min | Slides |
| **Module 1** — Rappel Tidyverse (pipe, verbes dplyr, pivot) | 1 h | demo + Q1 |
| **Module 2** — Jointures HR ↔ PR (5 verbes + 3 pièges) | 1 h | demo + Q2 |
| **Module 3** — Détection et gestion des valeurs manquantes | 1 h 15 | demo + Q3 |
| **Module 4** — Plan de sondage et pondération (`srvyr`) | 45 min | demo + Q4 |
| **Module 5** — Indicateurs par région ADM1 (table de sortie) | 45 min | demo + Q5 |
| **Module 6** — Jointure spatiale GADM ADM1 + premier aperçu carte | 30 min | demo |
| Synthèse + Q6 + Q&A | 15 min | Slides |

## Packages utilisés

- `dplyr`, `tidyr`, `readr` — manipulation tabulaire (recyclage J1)
- `ggplot2`, `sf` — aperçu cartographique de fin de journée
- **`haven`** — lecture des microfichiers Stata `.DTA` (nouveau du jour)
- **`survey` + `srvyr`** — plan de sondage stratifié à deux degrés, pondération, intervalles de confiance (nouveau du jour)
- **`naniar`** — exploration visuelle des NA (`vis_miss`, `gg_miss_var`, `gg_miss_upset`)

## Données mobilisées (100 % réelles)

| Fichier | Volume | Description | Localisation |
|---|---|---|---|
| `CMHR71FL.DTA` | ~14 000 ménages × 5 741 vars | Household Recode (HR) EDS-MICS Cameroun 2018 — fichier maître | `pedagogie/datasets/cameroun/CM_2018_DHS/CMHR71DT/` |
| `CMPR71FL.DTA` | ~70 000 personnes × 394 vars | Person Recode (PR) EDS-MICS Cameroun 2018 — un membre par ligne | `pedagogie/datasets/cameroun/CM_2018_DHS/CMPR71DT/` |
| `dhs_cmr_2018_menages_extrait.csv` | 11 710 ménages × 24 vars | Extrait pédagogique HR pour le runtime WebR | `pedagogie/_commons/data/dhs_cmr/` |
| `dhs_cmr_2018_personnes_extrait.csv` | 60 699 personnes × 12 vars | Extrait pédagogique PR pour le runtime WebR | `pedagogie/_commons/data/dhs_cmr/` |
| `gadm41_CMR_1.json` | 10 régions | Polygones GADM ADM1 du Cameroun (jointure spatiale fin de journée) | `pedagogie/_commons/data/` |

**Pipeline de production des extraits CSV** : `pedagogie/_commons/data/dhs_cmr/00_extraire_dhs_pour_webr.R` (à exécuter UNE seule fois sur la machine de l'animateur, après extraction du pack DHS).

**Licence DHS** : usage formation IFORD/GDSG. Les `.DTA` bruts sont **exclus du repo** par `.gitignore` (redistribution interdite par le DHS Program). Les CSV extraits pédagogiques sont commités pour permettre le runtime WebR — voir `dhs_cmr_2018_README.csv` pour les détails de provenance et de jointure.

## Pré-requis

- J1, J2, J3 validés.
- Q6 du J3 terminé.
- Pack DHS Cameroun 2018 extrait localement dans `pedagogie/datasets/cameroun/CM_2018_DHS/` (pour la démo desktop).

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `README.md` | Ce document |
| `slides.qmd` | Diaporama revealjs : plan + théorie + méthodologie ODD |
| `demo.qmd` | Démonstration HTML — 6 modules sur DHS réel avec explication avant chaque bloc R |
| `demo.R` | Script court projeté en salle, structure miroir des 6 modules |
| `runtime.qmd` | Version WebR — charge les extraits CSV en direct depuis le site, modules simplifiés (pas de `srvyr` portable WebR) |
| `exercice.qmd` | Q1 à Q6 (Q1–Q5 en séance, Q6 devoir individuel) |
| `corrige.qmd` | Solutions commentées |
| `install_packages_day.R` | Installation ciblée (`haven`, `survey`, `srvyr`, `naniar`, `sf`) |

## Crédits

Architecture pédagogique modulaire des 6 modules : **Jean Saturnin Alogo Samba** (GDSG / IFORD).

Bascule sur DHS Cameroun 2018 réel + intégration convention atelier + tests Quarto : **Ramesesse Dzita** (GDSG / IFORD).

Source des données : **EDS-MICS Cameroun 2018** — BUCREP / INS Cameroun / MINSANTÉ / ICF International (DHS Program / USAID).

Diffusion du code et du matériel pédagogique : **CC-BY 4.0** au nom du GDSG / IFORD. Les microfichiers DHS sont régis par la licence du DHS Program (redistribution interdite).
