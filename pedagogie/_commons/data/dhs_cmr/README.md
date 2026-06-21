# `dhs_cmr/` — Indicateurs DHS Cameroun 2018 (StatCompiler)

Données utilisées dans le **bonus du J4** (Gestion des données pour l'analyse spatiale), section « comparaison avec les vrais indicateurs EDS-MICS Cameroun 2018 ».

## Fichiers

| Fichier | Origine | Description |
|---|---|---|
| `00_telecharger_dhs_indicateurs.R` | Script de l'atelier | Télécharge les indicateurs agrégés par région de l'EDS-MICS Cameroun 2018 depuis l'API DHS StatCompiler via le package `rdhs`. À exécuter UNE SEULE FOIS sur la machine de l'animateur. |
| `indicateurs_dhs_cmr_2018.csv` | Sortie du script | 5 indicateurs × 10 régions : alphabétisation femmes/hommes, accès eau améliorée, accès électricité, taille moyenne ménage. |

## Reproduire

```r
install.packages(c("rdhs", "dplyr", "readr"))
source("pedagogie/_commons/data/dhs_cmr/00_telecharger_dhs_indicateurs.R")
```

L'API StatCompiler est **publique et sans authentification** pour les indicateurs agrégés (différent de la microdata DHS qui exige inscription + projet). Temps de réponse : 5 à 20 secondes.

## Pourquoi des indicateurs agrégés et non la microdata

La microdata DHS (fichiers KR/HR/IR) exige une inscription DHS Program + soumission d'un projet (validation 24-48 h). C'est incompatible avec un atelier en flux tendu et avec le runtime WebR public.

Les indicateurs agrégés par région donnent en revanche un **comparatif réel** au matériel pédagogique simulé de Saturnin — c'est exactement ce qu'il fallait pour le bonus du J4.

## Licence et citation

Source : ICF International / DHS Program. Citation recommandée :

> Institut National de la Statistique (INS) et ICF. 2020.
> *Enquête Démographique et de Santé à Indicateurs Multiples du Cameroun 2018*.
> Yaoundé, Cameroun et Rockville, Maryland, USA : INS et ICF.

Les **indicateurs agrégés** publiés par StatCompiler sont en accès libre. Pour la microdata, voir <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm>.
