# `dhs_cmr/` — Indicateurs DHS Cameroun 2018 (calculés en local)

Données dérivées du microfichier EDS-MICS Cameroun 2018 (DHS Program) pour les besoins pédagogiques de **J4** (Gestion des données) et **J5** (Visualisation et cartographie).

## Fichiers présents (commités dans le repo)

| Fichier | Origine | Description |
|---|---|---|
| `00_telecharger_dhs_indicateurs.R` | Script de l'atelier | Calcule 5 indicateurs agrégés par région à partir du microfichier DHS local (HR + IR + MR) via `srvyr`. Produit `indicateurs_dhs_cmr_2018.csv`. |
| `00_extraire_dhs_pour_webr.R` | Script de l'atelier | Extrait deux CSV légers (HR 24 vars, PR 12 vars) du microfichier pour le runtime WebR de J4. Produit `dhs_cmr_2018_menages_extrait.csv` et `dhs_cmr_2018_personnes_extrait.csv`. |
| `indicateurs_dhs_cmr_2018.csv` | Sortie du script | Format long : 50 lignes = 10 régions × 5 indicateurs (eau améliorée, électricité, taille ménage, alphabétisation femmes 15-49, alphabétisation hommes 15-59). |
| `dhs_cmr_2018_menages_extrait.csv` | Sortie du script | 11 710 ménages × 24 variables pédagogiques (HR). |
| `dhs_cmr_2018_personnes_extrait.csv` | Sortie du script | 60 699 personnes × 12 variables pédagogiques (PR). |
| `dhs_cmr_2018_README.csv` | Sortie du script | Documentation tabulaire des extraits CSV ci-dessus. |

## Reproduire

Les deux scripts supposent que le **microfichier DHS Cameroun 2018** est présent dans `pedagogie/datasets/cameroun/CM_2018_DHS/` (voir `pedagogie/_commons/helpers/fetch_data.R` et `fetch_dhs_recode_cmr_2018()`).

```r
install.packages(c("haven","dplyr","tidyr","readr","srvyr","survey"),
                 repos = "https://packagemanager.posit.co/cran/latest")

source("pedagogie/_commons/data/dhs_cmr/00_extraire_dhs_pour_webr.R")
source("pedagogie/_commons/data/dhs_cmr/00_telecharger_dhs_indicateurs.R")
```

## Stratégie de calcul des indicateurs agrégés

Plutôt que d'interroger l'API DHS StatCompiler en ligne (via `rdhs`), on **calcule nous-mêmes les indicateurs** à partir du microfichier local avec `srvyr` :

- Plan de sondage stratifié à deux degrés (PSU = `HV001/V001/MV001`, strates = `HV022/V022/MV022`)
- Poids ménage / femme / homme divisés par 10⁶
- `nest = TRUE` pour PSU emboîtées dans strates

**Avantages** : pas de dépendance réseau ni de token DHS, parfaite cohérence avec ce que les participants calculent en J4 (Module 4 `srvyr`), reproductibilité offline.

**Petite différence avec StatCompiler** : nos valeurs peuvent différer de 0.3 à 1 point des valeurs publiées par DHS sur certains indicateurs (notamment l'alphabétisation, dont la définition DHS officielle combine plusieurs variables `V155 + V149` de façon nuancée). Notre définition simplifiée est documentée dans le CSV (`indicateur_libelle`).

## Indicateurs publiés

| Code DHS | Indicateur | Population | Recode |
|---|---|---|---|
| `WS_SRCE_H_IMP` | % ménages avec source d'eau améliorée (def JMP) | ménages | HR |
| `HC_ELEC_H_ELC` | % ménages avec électricité | ménages | HR |
| `HC_HHSZ_H_AVG` | Taille moyenne ménage | ménages | HR |
| `ED_LITR_W_LIT` | % femmes 15-49 alphabétisées | femmes | IR |
| `ED_LITR_M_LIT` | % hommes 15-59 alphabétisés | hommes | MR |

## Licence

- **Microfichier DHS** : licence DHS Program — redistribution interdite (`.gitignore` bloque `**/CM_2018_DHS/`).
- **Indicateurs agrégés calculés** : pas de restriction de redistribution (DHS Program permet la publication d'estimations dérivées) — d'où le commit dans le repo.
- **Extraits CSV pédagogiques** : usage formation IFORD/GDSG, redistribution restreinte au cadre de l'atelier.

## Citation recommandée

> Institut National de la Statistique (INS) et ICF. 2020.
> *Enquête Démographique et de Santé à Indicateurs Multiples du Cameroun 2018*.
> Yaoundé, Cameroun et Rockville, Maryland, USA : INS et ICF.

Pour la page de référence officielle du dataset : <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm>.
