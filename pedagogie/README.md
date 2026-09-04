# Matériel pédagogique — Atelier IFORD × GDSG 2026

> Données spatiales, analyse et manipulation dans R · **11 journées (J01 à J11)** ·
> Yaoundé, **27 juillet – 7 août 2026**. Dimanche 2 août : repos.

Ce dossier contient **tout le matériel pédagogique** des onze journées de
l'atelier : documents formateur Quarto, scripts dérivés, slides, runtime WebR
pour le navigateur, données et inventaires.

> **Les noms ci-dessous sont ceux du disque.** L'ancienne arborescence de dix
> jours (`J03_cartographie_tmap_ggplot`, `J08_population_top_down`, …) et
> l'ancienne convention de fichiers (`demo.qmd`, `demo.R`, `exercice.qmd`,
> `corrige.qmd`) n'ont plus cours : si une page les cite encore, c'est un
> reliquat du matériel v1.

## Comment c'est organisé

L'arborescence est **par jour** : chaque dossier `J0X_…/` est **autoportant** —
tout ce qu'il faut pour ce jour-là, données comprises, en chemins relatifs.

```
pedagogie/
├── INDEX.md                              # page d'accueil du site : calendrier, état, programme
├── README.md                             # ce fichier
├── _SITE_ETAT.md                         # journal des corrections du squelette du site
├── manuel_animateur.md                   # mode d'emploi pour l'animateur
├── _quarto.yml                           # config Quarto Live racine (runtime WebR)
│
├── _commons/                             # ressources PARTAGÉES J01-J11
│   ├── helpers/
│   │   ├── fetch_data.R                  # résolution de chemins + fallback
│   │   ├── theme_iford.R                 # palette + thème ggplot/tmap
│   │   └── citations.bib                 # bibliographie commune
│   ├── styles/
│   │   ├── slides_revealjs.scss          # thème slides revealjs
│   │   └── runtime_quartolive.scss       # thème runtime WebR
│   ├── img/logo-iford.jpg
│   └── data/                             # extraits légers servis aux runtimes WebR
│
├── J01_fondations/                       # lundi 27 juillet
├── J02_penser_espace/                    # mardi 28 juillet
├── J03_univers_vectoriel/                # mercredi 29 juillet
├── J04_terre_en_pixels/                  # jeudi 30 juillet
├── J05_enquetes_carte/                   # vendredi 31 juillet
├── J06_art_cartographie/                 # samedi 1ᵉʳ août
├── J07_statistiques_spatiales/           # lundi 3 août
├── J08_population_haute_resolution/      # mardi 4 août
├── J09_teledetection/                    # mercredi 5 août
├── J10_politiques_publiques/             # jeudi 6 août
└── J11_perenniser_transmettre/           # vendredi 7 août
```

> Les sous-dossiers `_commons/data/jour_0X_extraits/` portent encore l'ancienne
> numérotation, décalée d'une unité (`jour_07_extraits` alimente le **J08**,
> `jour_08_extraits` le **J09**, `jour_09_extraits` le **J10**,
> `jour_10_extraits` le **J11**). La renumérotation est listée dans
> `../REPRISE_J06_J11.md` §3 et n'a pas encore été faite.

## Contenu d'un dossier de jour

| Fichier | Pour qui | Description |
|---|---|---|
| `README.md` | tous | Question de la journée, modules, données mobilisées, pièges mis en scène. |
| `demo_formateur_J0X.qmd` | tous | **Source unique** de la journée : tout le code, ses sorties et la prose. |
| `script_formateur_J0X.R` | animateur | Miroir exécutable du `.qmd` — même code, même ordre, à projeter section par section. |
| `script_etudiant_J0X.R` | participants | Trame à trous (`>>> A COMPLETER`), remplie en séance. |
| `script_etudiant_J0X_corrige.R` | participants | Corrigé, distribué en fin de journée. |
| `slides.qmd` et/ou `*.pptx` | animateur | Support de projection. |
| `runtime.qmd` | participants | Version WebR — code R exécutable dans le navigateur, zéro installation. |
| `install_packages_day.R` | animateur | Packages spécifiques du jour, à lancer **une fois**. |
| `datasets/` + `datasets/LISEZMOI.md` | tous | Données du jour, **à plat**, avec leur inventaire vérifié. |
| `outputs/` | — | Sorties du code, préfixées `J0X_`. Créé au premier lancement. |

**Deux écarts subsistent, relevés sur le disque :**

- **Emplacement des trois scripts.** J08, J09 et J10 les rangent dans
  `scripts/`, avec un doublon resté à la racine du dossier-jour. Les huit autres
  journées les gardent à la racine. L'harmonisation vers `scripts/` reste à
  faire.
- **Numérotation à un chiffre.** J06 et J07 nomment encore leurs fichiers
  `demo_formateur_J6.qmd`, `script_formateur_J7.R`, etc. Le passage en `J06` /
  `J07` est prévu (`../REPRISE_J06_J11.md` §3).

Les noms `demo.qmd`, `demo.R`, `exercice.qmd` et `corrige.qmd` appartiennent au
**matériel v1**. Certains `README.md` de journée les citent encore comme
« complément conservé » ; ils ne sont plus la convention.

## État d'avancement

Le tableau de référence est dans `INDEX.md`, repris de `../REPRISE_J06_J11.md`
§1. En résumé : **J01 à J04** terminées et rendues sans erreur ; **J05**
reconstruite mais non rendue ; **J08, J09, J10** réécrites mais non exécutées ;
**J06, J07, J11** non commencées. Aucune journée n'a encore été
animée avec ce matériel.

## Workflow type d'animation d'une journée

1. **La veille** : rendre `demo_formateur_J0X.qmd` de bout en bout sur ta
   machine et lire le HTML. Vérifier que `datasets/` est complet
   (`datasets/LISEZMOI.md`).
2. **Matin du jour J** : ouvrir RStudio sur le projet
   `atelier-r-spatial-iford-2026`. Slides à gauche, `script_formateur_J0X.R` à
   droite.
3. **Pendant l'animation** : suivre le déroulé du `README.md` du jour. Projeter
   les slides, exécuter le `.R` section par section, montrer le HTML du `.qmd`
   pour les explications longues.
4. **Fin de journée** : distribuer le HTML rendu et
   `script_etudiant_J0X_corrige.R`.

## Workflow type pour un participant à domicile (post-atelier)

1. Cloner le dépôt : `git clone https://github.com/dzita/atelier-r-spatial-iford-2026.git`.
2. Ouvrir `atelier-r-spatial-iford-2026.Rproj` dans RStudio.
3. Lancer `source("environnement_technique/install_packages.R")`, puis
   `source("outils/distribuer_donnees.R")` pour remplir les `datasets/`.
4. Pour rejouer le jour J : ouvrir `pedagogie/J0X_…/demo_formateur_J0X.qmd`,
   lancer `source("install_packages_day.R")` une fois, puis **Render**.
5. Pour s'entraîner sans rien télécharger : ouvrir le runtime WebR en ligne sur
   <https://dzita.github.io/atelier-r-spatial-iford-2026/> — R s'exécute dans le
   navigateur, aucune installation. Premier chargement ~30-60 secondes, mis en
   cache ensuite.

## Conventions

- **Snake_case minuscule** pour les noms de fichiers et dossiers (sauf
  `README.md`, `LISEZMOI.md`, `LICENSE`, et le préfixe `J0X_` de tri).
- **Numérotation sur deux chiffres**, `J01` à `J11`, pour que `J10` vienne après
  `J09` et non après `J01`. Cette règle vaut aussi pour les **noms de fichiers
  internes** et pour les **sorties** (`outputs/J08_*.png`).
- **Un dossier-jour est autoportant** : données dans `datasets/` à plat, sorties
  dans `outputs/`, chemins relatifs uniquement. Une sortie n'écrit jamais dans
  `datasets/`.
- **Helpers partagés** dans `_commons/helpers/`, bibliographie dans
  `_commons/helpers/citations.bib`.
- **Français uniquement** pour les `.qmd`, scripts, README et LISEZMOI. Seules
  certaines présentations `.pptx` existent en FR / EN / bilingue ; les scripts
  anglais du matériel source sont archivés dans `archive_en/` et **ne sont pas
  maintenus**.

## Licence

Tout le contenu pédagogique est diffusé sous **CC-BY 4.0** (Creative Commons
Attribution 4.0 International).

## Contact

Animation : **Ramesesse Dzita** — `ramondzita@gmail.com` — IFORD × GDSG.
