# Atelier IFORD × GDSG 2026 — Données spatiales dans R

Matériel pédagogique de l'atelier régional **« Données spatiales, analyse et manipulation dans R »**, organisé par :

- l'**Institut de Formation et de Recherche Démographiques (IFORD)** — Yaoundé, Cameroun.
- le **Geospatial Data Science Group (GDSG)** de l'IFORD.

**Dates :** 27 juillet – 7 août 2026 · **Lieu :** Yaoundé · **Niveau :** débutant en R et SIG · **Public :** statisticiens, démographes, techniciens d'INS / BUCREP / ministères / ONG d'Afrique francophone et anglophone.

## Statut

✅ **Matériel livré et prêt pour relecture / pull collègues** (juin 2026). Les 10 modules sont complets côté code, données embarquées, exercices et corrigés. Itérations mineures possibles d'ici le 27 juillet.

🌐 **Site live (lecture immédiate dans le navigateur, exécution WebR)** : <https://dzita.github.io/atelier-r-spatial-iford-2026/>

## Programme — 10 jours

| Jour | Date 2026 | Module | Outils clés |
|---|---|---|---|
| **J1** | lun. 27 juil. | Introduction R + pensée spatiale | base R, `tibble`, `sf`, `ggplot2` |
| **J2** | mar. 28 juil. | Données vectorielles `sf` + CRS | `sf`, EPSG, Lambert Cameroun |
| **J3** | mer. 29 juil. | Données raster avec `terra` | `terra`, SRTM, crop / mask / extract |
| **J4** | jeu. 30 juil. | Gestion des données + DHS Cameroun 2018 | `dplyr`, `tidyr`, `srvyr`, microfichiers DHS |
| **J5** | ven. 31 juil. | Visualisation et cartographie | `ggplot2 + geom_sf`, `tmap` v4 |
| **J6** | sam. 1ᵉʳ août | Statistiques spatiales (Moran's I, LISA, KDE) | `spdep`, OSM healthcare, Monte Carlo |
| **J7** | lun. 3 août | Population haute résolution + bottom-up GDSG | WorldPop R2025A, GHS-POP, `exactextractr`, méthode Darin & Leasure 2023 |
| **J8** | mar. 4 août | Télédétection et observation de la Terre | GHSL Built-Up, Copernicus EMSR772 Yagoua, Google Open Buildings |
| **J9** | mer. 5 août | Applications sciences sociales | ACLED (conflits), ERA5 (climat) |
| **J10** | ven. 7 août | Flux reproductibles + mini-projet + clôture | Quarto multi-format, Git, `purrr`, FAIR, métadonnées |

Le jeudi 6 août est libre (rédaction mini-projet par les participants).

## Démarrage rapide

### Pour parcourir le matériel dans le navigateur

Aucune installation nécessaire — ouvrir le site live ci-dessus. WebR charge R et les packages dans la page (~30 s au premier accès, en cache ensuite).

### Pour utiliser le matériel en local (formateurs / collègues GDSG / participants après l'atelier)

```bash
git clone https://github.com/dzita/atelier-r-spatial-iford-2026.git
cd atelier-r-spatial-iford-2026
```

Ouvrir `atelier-r-spatial-iford-2026.Rproj` dans **RStudio** puis, dans la console R :

```r
source("environnement_technique/install_packages.R")
```

(Compter 15-30 min pour la première installation des ~30 packages spatiaux. À faire une seule fois.)

Pour prévisualiser le site complet :

```bash
quarto preview pedagogie/INDEX.md
```

Pour ouvrir un jour spécifique en démo formateur :

```bash
quarto render pedagogie/J05_visualisation_cartographie/demo.qmd --to html
```

## Structure du dépôt

```
atelier-r-spatial-iford-2026/
├── README.md                              # Ce fichier
├── MANUEL_SUPPORT_TECHNIQUE.md            # Manuel formateur (architecture, datasets, troubleshooting)
├── atelier-r-spatial-iford-2026.Rproj     # Projet RStudio
├── LICENSE                                # CC BY 4.0 sur le matériel pédagogique
│
├── environnement_technique/               # Installation globale tous packages atelier
│   └── install_packages.R
│
├── datasets/cameroun/                     # Datasets canoniques (gros volumes .gitignored)
│   ├── admin_boundaries/                  # GADM JSON ADM0-3
│   ├── population_grids/                  # WorldPop, GHS-POP, Meta HRSL
│   ├── dhs_mics/                          # DHS Cameroun 2018
│   ├── elevation/                         # SRTM
│   ├── cmr_sante/                         # OSM healthcare
│   ├── jour_07_population/                # WorldPop R2025A + GHS-POP tuiles
│   ├── jour_08_teledetection/             # GHSL + EMSR772 + Open Buildings
│   ├── jour_09_acled_era5/                # ACLED CSV + ERA5 NetCDF
│   └── jour_10/                           # Dataset fil rouge J10 (Edith Darin)
│
└── pedagogie/                             # Coeur pédagogique (projet Quarto)
    ├── _quarto.yml                        # Config site + navbar
    ├── _extensions/r-wasm/live/           # Extension WebR
    ├── _commons/
    │   ├── data/                          # Extraits LÉGERS embarqués WebR
    │   ├── helpers/fetch_data.R           # Tous les fetch_*() (résolution chemins)
    │   ├── styles/                        # SCSS revealjs + iford_reference.pptx
    │   └── img/                           # Logo IFORD
    ├── INDEX.md                           # Accueil du site
    ├── J01_intro_R_pensee_spatiale/       # Chaque jour suit le même schéma :
    │   ├── README.md                      #   - synthèse jour
    │   ├── slides.qmd                     #   - support revealjs
    │   ├── demo.qmd                       #   - rapport RStudio complet
    │   ├── demo.R                         #   - miroir condensé (salle)
    │   ├── runtime.qmd                    #   - WebR navigateur
    │   ├── exercice.qmd                   #   - devoirs
    │   ├── corrige.qmd                    #   - solutions
    │   └── install_packages_day.R
    ├── J02_sf_CRS_vecteurs/
    ├── J03_donnees_raster_terra/
    ├── J04_gestion_donnees_tidyverse/
    ├── J05_visualisation_cartographie/
    ├── J06_statistiques_spatiales/
    ├── J07_population_haute_resolution/
    ├── J08_teledetection_observation_terre/
    ├── J09_applications_spatiales_sciences_sociales/
    └── J10_workflows_reproductibles/
```

Convention : noms de dossiers et fichiers en **snake_case minuscule**. Les fichiers spéciaux universels (`README.md`, `LICENSE`) gardent leur convention.

## Manuel technique

Le fichier **`MANUEL_SUPPORT_TECHNIQUE.md`** à la racine est destiné au support technique pendant les sessions. Il couvre :

- Architecture du dépôt et flux de rendu Quarto / WebR.
- Stack technique requise (R 4.4+, Quarto 1.4+, Git, TinyTeX).
- **Fonctionnement WebR détaillé** (mécanique `webr.resources`, limites connues).
- **Fiche détaillée par dataset** (17 sources documentées : GADM, WorldPop, GHS-POP, DHS, SRTM, OSM, ACLED, ERA5, GHSL Built-Up, EMSR772, Open Buildings, etc.) avec origine, URL, taille, licence, emplacement local, helper R, jour qui l'utilise.
- Procédures d'installation participant.
- Déploiement GitHub Pages.
- **Troubleshooting des 11 pannes déjà rencontrées** pendant la construction (XHR Invalid URL, `Edge 0 is degenerate`, terra non utilisable WebR 0.6, etc.).
- FAQ pédagogique par jour.
- Procédures d'urgence pendant l'atelier (wifi en panne, poste cassé, etc.).
- Maintenance post-atelier.

À garder ouvert pendant l'animation.

## Données

Le détail dataset par dataset est dans **`MANUEL_SUPPORT_TECHNIQUE.md` section 4**. Chaque jour a aussi sa section « Données utilisées » dans son `pedagogie/JXX_*/README.md` (embarqué WebR vs à télécharger manuellement).

Règles d'or :

- **Embarqué dans le repo** : extraits légers (< 5 Mo) sous `pedagogie/_commons/data/` — utilisés par les runtimes WebR. Versionnés.
- **À télécharger localement** : datasets lourds (WorldPop TIF ~150 Mo, GHSL tuiles ZIP, DHS Stata `.DTA` ~500 Mo) sous `datasets/cameroun/...`. `.gitignored`. Les scripts `00_*.R` automatisent la copie / le téléchargement quand possible ; sinon les helpers `fetch_*()` de `pedagogie/_commons/helpers/fetch_data.R` retournent un message clair indiquant **où télécharger** et **où poser le fichier**.
- **Données sensibles** : aucune donnée individuelle non anonyme dans ce dépôt. Les microfichiers EDS-MICS Cameroun 2018 nécessitent une inscription sur <https://dhsprogram.com/>.

## Équipe

**Lead Coordinator GDSG** : Pr Mathias Kuépié (études socioéconomiques et géospatial)
**Co-Lead GDSG** : Pr Franklin Bouba Djourdebbé (études de population)
**Co-formateurs GDSG** :
- Edith Darin — Senior Researcher, ex-WorldPop/Oxford (conception J7, J8, J10 + référente bottom-up)
- Jean Saturnin Alogo Samba — Statistician + GIS (architecture J4, J5, J6)
- Marcial Teda Soh Fossi — Junior Demographer-Statistician
- **Ramesesse Dzita** — Junior Demographer-Statistician + IT Specialist (animation unique, lead IT/infrastructure, intégration finale du matériel)

Crédits détaillés par jour dans chaque `pedagogie/JXX_*/README.md` (section Crédits).

## Licence

- **Code R, scripts, slides, documents pédagogiques** : Creative Commons Attribution 4.0 International (**CC BY 4.0**). Voir `LICENSE`. Utilisation libre avec attribution `IFORD × GDSG 2026 · Ramesesse Dzita`.
- **Datasets externes** : licences d'origine respectées (GADM libre académique, WorldPop CC-BY 4.0, GHSL CC-BY 4.0, OSM ODbL, DHS Program inscription requise, ACLED Terms of Use). Détails dans le `MANUEL_SUPPORT_TECHNIQUE.md`.

## Contribuer

Pour signaler un bug ou proposer une amélioration : ouvrir une **issue** sur GitHub ou une **pull request**.

Pour suivre l'évolution post-atelier (community GDSG, slack des anciens, sessions mensuelles) : contacter ramondzita@gmail.com.

## Contact

**Ramesesse Dzita** · `ramondzita@gmail.com` · Geospatial Data Science Group, IFORD.
