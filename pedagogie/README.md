# Matériel pédagogique — Atelier IFORD × GDSG 2026

> Données spatiales, analyse et manipulation dans R · 10 jours · Yaoundé, 27 juillet – 7 août 2026.

Ce dossier contient **tout le matériel pédagogique** des 10 jours de l'atelier : démos exécutables, slides revealjs, runtime WebR pour le navigateur, exercices et corrigés.

## Comment c'est organisé

L'arborescence est **par jour** : chaque dossier `JXX_…/` est **autoportant** (tout ce qu'il faut pour ce jour-là).

```
pedagogie/
├── INDEX.md                              # navigation rapide entre les 10 jours
├── README.md                             # ce fichier
├── manuel_animateur.md                   # mode d'emploi pour l'animateur
├── _quarto.yml                           # config Quarto Live racine (pour le runtime WebR)
│
├── _commons/                             # ressources PARTAGÉES J1-J10
│   ├── helpers/
│   │   ├── fetch_data.R                  # téléchargement auto + fallback
│   │   ├── theme_iford.R                 # palette + thème ggplot/tmap
│   │   └── citations.bib                 # bibliographie commune
│   └── styles/
│       ├── slides_revealjs.scss          # thème slides revealjs
│       └── runtime_quartolive.scss       # thème runtime WebR
│
├── J01_intro_R_pensee_spatiale/
├── J02_sf_CRS_vecteurs/
├── J03_cartographie_tmap_ggplot/
├── J04_terra_raster/
├── J05_jointures_spatiales_demo/
├── J06_autocorrelation_moran_lisa/
├── J07_KDE_dasymetrie_teledetection/
├── J08_population_top_down/
├── J09_population_bottom_up/
└── J10_mini_projet_synthese/
```

## Contenu d'un dossier de jour

Chaque dossier `JXX_…/` contient :

| Fichier | Pour qui | Description |
|---|---|---|
| `README.md` | tous | Objectifs, déroulé horaire, données mobilisées, packages utilisés. |
| `demo.qmd` | participants | Version animation pédagogique complète, rendue en HTML/PDF. |
| `demo.R` | animateur | Version exécutable rapide, à projeter ligne par ligne en salle. |
| `slides.qmd` | animateur | Deck revealjs (~30-40 slides) pour la projection. |
| `runtime.qmd` | participants | Version WebR — code R exécutable dans le navigateur, zéro install. |
| `exercice.qmd` | participants | TP individuel de fin de journée (~30 min). |
| `corrige.qmd` | participants | Corrigé du TP, distribué le lendemain matin. |

## Workflow type d'animation d'une journée

1. **La veille** : tester `demo.R` du jour J en bout-en-bout sur ta machine. Vérifier les téléchargements (GADM, etc.).
2. **Matin du jour J** : ouvrir RStudio sur le projet `atelier-r-spatial-iford-2026`. Ouvrir `slides.qmd` côté gauche, `demo.R` côté droit.
3. **Pendant l'animation** : suivre les sessions du `README.md`. Projeter les slides, exécuter le code du `.R` à la demande, montrer le `demo.qmd` pour les explications longues.
4. **Fin de journée** : rendre `demo.qmd` en HTML, distribuer aux participants avec `exercice.qmd`.
5. **Le lendemain matin** : distribuer `corrige.qmd` du jour J-1.

## Workflow type pour un participant à domicile (post-atelier)

1. Cloner le dépôt : `git clone https://github.com/dzita/atelier-r-spatial-iford-2026.git`.
2. Ouvrir `atelier-r-spatial-iford-2026.Rproj` dans RStudio.
3. Lancer `source("environnement_technique/install_packages.R")` puis `verification_setup.R`.
4. Pour rejouer le jour J : ouvrir `pedagogie/JXX_…/demo.qmd` → cliquer **Render**.
5. Pour s'entraîner sans tout télécharger : ouvrir le runtime WebR en ligne sur <https://dzita.github.io/atelier-r-spatial-iford-2026/> — R s'exécute directement dans le navigateur (WebR), aucune installation requise. Premier chargement ~30-60 secondes (téléchargement des packages mis en cache ensuite).

## Conventions

- **Snake_case minuscule** pour les noms de fichiers et dossiers (sauf `README.md`, `LICENSE`, et le préfixe `JXX_` pour le tri).
- **Tri alphabétique** assuré par le préfixe `J01_`, `J02_`, …, `J10_` (utiliser deux chiffres pour que J10 vienne après J09 et pas après J1).
- **Helpers partagés** dans `_commons/helpers/`, sourcés explicitement par les démos via `here()`.
- **Bibliographie partagée** dans `_commons/helpers/citations.bib`.

## Licence

Tout le contenu pédagogique est diffusé sous **CC-BY 4.0** (Creative Commons Attribution 4.0 International). La LICENSE sera ajoutée au dépôt avant le 27 juillet 2026.

## Contact

Animation : **Ramesesse Dzita** — `ramondzita@gmail.com` — IFORD × GDSG.
