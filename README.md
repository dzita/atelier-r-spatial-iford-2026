# Atelier IFORD × GDSG 2026 — Données spatiales dans R

Matériel pédagogique de l'atelier régional **« Données spatiales, analyse et manipulation dans R »**, organisé par :

- l'**Institut de Formation et de Recherche Démographiques (IFORD)** — Yaoundé, Cameroun
- le **Geospatial Data Science Group (GDSG)** de l'IFORD

**Dates :** 27 juillet – 7 août 2026 · **Lieu :** Yaoundé · **Niveau :** Débutant en R et SIG.

## Statut

🚧 Dépôt en construction — alimenté **module par module** à partir de juin 2026. Le contenu sera finalisé pour le 20 juillet 2026.

## Public cible

Statisticiens et démographes des Instituts Nationaux de Statistique (INS), bureaux de recensement, ministères sectoriels, ONG et organisations internationales d'Afrique. Particulièrement pertinent pour les pays avec un recensement en cours ou planifié.

## Programme synthétique

| Jour | Thème |
|---|---|
| J1 (27 juil.) | Introduction R et pensée spatiale |
| J2 (28 juil.) | Données vectorielles `sf` et CRS |
| J3 (29 juil.) | Cartographie thématique (`tmap`, `ggplot2`) |
| J4 (30 juil.) | Données raster avec `terra` |
| J5 (31 juil.) | Jointures spatiales et démographie EDS-MICS |
| J6 (1ᵉʳ août) | Autocorrélation spatiale (Moran, LISA) |
| J7 (3 août) | KDE, dasymétrie, télédétection |
| J8 (4 août) | Population top-down (WorldPop, GHS-POP) |
| J9 (5 août) | Population bottom-up |
| J10 (6-7 août) | Mini-projet et bilan |

## Structure du dépôt *(en cours de construction)*

```
.
├── 00_PROJET/             # Cadrage, calendrier, équipe
├── 01_PEDAGOGIE/          # Slides, démos, runtime WebR
├── 02_DATASETS_CAMEROUN/  # Provenance + licences (datasets non versionnés)
├── 03_ENVIRONNEMENT_TECHNIQUE/  # Installation, packages, Docker
├── 04_LIVRABLES_FORMATEURS/
├── 05_LIVRABLES_PARTICIPANTS/
├── 06_COMMUNICATION/
├── 07_RESSOURCES_EXTERNES/
└── 08_POST_ATELIER/
```

## Données

Aucune donnée sensible n'est versionnée dans ce dépôt. En particulier :

- Les microfichiers **EDS-MICS Cameroun 2018** (clusters GPS, fichiers individuels) sont distribués sous licence DHS Program et nécessitent une inscription préalable sur <https://dhsprogram.com/>.
- Les gros rasters (WorldPop 100 m, GHS-POP, Meta HRSL, Sentinel-2) sont téléchargés à la volée par `01_PEDAGOGIE/demos/_helpers/fetch_data.R`.
- Seuls les fichiers de **provenance et de citation** (`README*.md`, `DATA_PROVENANCE.md`) sont versionnés.

## Licence

Code et matériel pédagogique : **Creative Commons Attribution 4.0 International (CC BY 4.0)**. Voir `LICENSE`.

Les datasets gardent leur licence d'origine — voir `02_DATASETS_CAMEROUN/README_donnees.md` (à venir).

## Contact

Animation : **Ramesesse Dzita** — `ramondzita@gmail.com`
