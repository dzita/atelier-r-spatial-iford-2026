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

## Données utilisées

### Embarqué dans le repo (chargé automatiquement par le runtime WebR)

- `pedagogie/_commons/data/dhs_cmr/dhs_cmr_2018_menages_extrait.csv` — Extrait pédagogique HR de l'EDS-MICS Cameroun 2018, 11 710 ménages × 24 variables (CSV ~1-2 Mo). Produit par le script `pedagogie/_commons/data/dhs_cmr/00_extraire_dhs_pour_webr.R` à partir du microfichier `.DTA` DHS officiel. Utilisé par `runtime.qmd`, `demo.qmd` (option B), `exercice.qmd`, `corrige.qmd`.
- `pedagogie/_commons/data/dhs_cmr/dhs_cmr_2018_personnes_extrait.csv` — Extrait pédagogique PR (Person Recode), 60 699 personnes × 12 variables (CSV ~3-4 Mo). Même origine et même script que l'extrait HR. Utilisé par les mêmes fichiers.
- `pedagogie/_commons/data/dhs_cmr/dhs_cmr_2018_README.csv` — Documentation tabulaire des deux extraits CSV ci-dessus (variables, types, libellés, provenance `.DTA`).
- `pedagogie/_commons/data/dhs_cmr/indicateurs_dhs_cmr_2018.csv` — Indicateurs nationaux agrégés (50 lignes = 10 régions × 5 indicateurs : eau améliorée, électricité, taille ménage, alphabétisation F/H). Calculés en local depuis HR/IR/MR avec `srvyr` par `00_telecharger_dhs_indicateurs.R`. Utilisé par `exercice.qmd` Q7 et `corrige.qmd` Q7 (confrontation pipeline microdonnées ↔ indicateurs publiés DHS StatCompiler).
- `pedagogie/_commons/data/gadm41_CMR_1.json` — Polygones GADM v4.1 ADM1 du Cameroun (10 régions), GeoJSON, ~1-2 Mo. Source : <https://gadm.org/download_country.html> (libre académique). Récupéré via le helper `fetch_gadm_cameroon(1)` (cache local). Utilisé par `demo.qmd` Module 6, `runtime.qmd` Module 6, `corrige.qmd` Q6.

### À télécharger manuellement (utilisé par demo.qmd / demo.R desktop, trop lourd pour le repo)

| Fichier | Emplacement attendu | Source | Taille | Comment l'obtenir |
|---|---|---|---|---|
| `CMHR71FL.DTA` (Household Recode, ~14 000 ménages × 5 741 vars) | `pedagogie/datasets/cameroun/CM_2018_DHS/CMHR71DT/` | <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm> | ~40-80 Mo | Inscription compte DHS Program + soumission d'un projet (validation 24-48 h) + téléchargement du pack `CMHR71DT.ZIP` (format Stata) + extraction dans le dossier cible |
| `CMPR71FL.DTA` (Person Recode, ~70 000 personnes × 394 vars) | `pedagogie/datasets/cameroun/CM_2018_DHS/CMPR71DT/` | Idem URL DHS Program ci-dessus | ~20-50 Mo | Idem (pack `CMPR71DT.ZIP`) |
| `CMIR71FL.DTA`, `CMMR71FL.DTA`, `CMKR71FL.DTA`, `CMBR71FL.DTA`, `CMCR71FL.DTA`, `CMFW71FL.DTA` (autres recodes utilisés par `00_telecharger_dhs_indicateurs.R` et préparation J7/J9) | `pedagogie/datasets/cameroun/CM_2018_DHS/CM<RC>71DT/` | Idem URL DHS Program | ~10-50 Mo chacun | Idem (un pack ZIP par recode) |
| `Guide_to_DHS_Statistics_DHS-7.pdf` | `pedagogie/datasets/cameroun/CM_2018_DHS/` | <https://dhsprogram.com/publications/publication-DHSG1-DHS-Questionnaires-and-Manuals.cfm> | ~10 Mo | Téléchargement direct (compte DHS requis) |
| `rapport finalEds2018.pdf` (rapport final EDS-MICS 2018, valeurs officielles de référence) | `pedagogie/datasets/cameroun/CM_2018_DHS/` | <https://dhsprogram.com/publications/publication-FR360-DHS-Final-Reports.cfm> | ~15 Mo | Téléchargement direct |

Le helper `fetch_dhs_recode_cmr_2018("HR")` (et autres codes `"PR"`, `"IR"`, etc.) défini dans `pedagogie/_commons/helpers/fetch_data.R` résout automatiquement le chemin `pedagogie/datasets/cameroun/CM_2018_DHS/CM<RC>71DT/CM<RC>71FL.DTA` une fois les `.DTA` extraits.

Pour automatiser la production des extraits CSV embarqués à partir des `.DTA` téléchargés :

```sh
Rscript pedagogie/_commons/data/dhs_cmr/00_extraire_dhs_pour_webr.R
Rscript pedagogie/_commons/data/dhs_cmr/00_telecharger_dhs_indicateurs.R
```

**Licence DHS** : usage formation IFORD/GDSG. Les `.DTA` bruts sont **exclus du repo** par `.gitignore` (redistribution interdite par le DHS Program). Les CSV extraits et indicateurs agrégés sont commités (le DHS Program autorise la publication d'estimations dérivées) pour permettre le runtime WebR — voir `pedagogie/_commons/data/dhs_cmr/README.md` et `dhs_cmr_2018_README.csv` pour les détails de provenance et de jointure.

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
