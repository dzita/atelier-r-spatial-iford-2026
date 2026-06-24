# J10 — Flux reproductibles, mini-projet et clôture

**Atelier IFORD × GDSG · Vendredi 7 août 2026 · Yaoundé · 6 heures**

> Dernier jour. On consolide tout : un rapport reproductible Quarto multi-format, du versioning Git, de l'automatisation par boucle régionale, un mini-projet en groupe, et la session de clôture FAIR + métadonnées + feuille de route INS/BUCREP.

## Objectifs pédagogiques

À la fin de J10, chaque participant doit pouvoir :

1. Organiser un **projet R portable** avec `here::here()` et chemins relatifs.
2. Construire un **rapport Quarto multi-format** (HTML, PPTX, PDF, Word) combinant code R, narration, cartes et métadonnées.
3. Distinguer `tmap_mode("plot")` (carte statique pour rapport) et `tmap_mode("view")` (carte interactive HTML).
4. Utiliser les **bases de Git** (init, add, commit, push) pour versionner un projet R-spatial.
5. **Automatiser** un calcul d'indicateur par boucle régionale avec `purrr::map_dfr`.
6. Énoncer les **principes FAIR** et lister les **métadonnées minimales** d'un livrable géospatial.
7. Présenter un mini-projet en 5 minutes selon la grille **question → décision possible**.

## Déroulé horaire (6 h selon programme officiel)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J1–J9 + intro J10 | 30 min | Slides |
| Matin 1 — Structure projet + chemins relatifs | 30 min | Slides + demo |
| Matin 2 — Quarto multi-format + tmap plot vs view | 1 h 30 | Slides + demo |
| Pause | 15 min | — |
| Théorie Git + démo init/commit/push | 45 min | Slides + demo |
| Automatisation par boucle régionale | 30 min | Slides + demo |
| **Après-midi 1 — Mini-projet en groupe** | 1 h 30 | Atelier |
| **Après-midi 2 — Présentations courtes** | 1 h | Restitutions |
| Session clôture : FAIR + métadonnées + feuille route INS | 30 min | Slides |
| Q&A + cérémonie + remise des certificats | 30 min | Cérémonie |

## Fil rouge pédagogique : un dataset régional unique

Toute la journée travaille sur **`regions_indicateurs_demo.gpkg`** (dataset IFORD préparé par Edith Darin) — 10 régions du Cameroun avec indicateurs démographiques et sociaux. Le même dataset sert :

- À la démo formateur (Quarto + Git + automatisation).
- Au mini-projet en groupe (chaque équipe choisit un indicateur).
- Au runtime WebR pour s'entraîner en autonomie.

## Format des présentations courtes

Inspiré directement de la grille d'Edith Darin. Chaque groupe (3-4 personnes) prépare et présente **5 minutes** :

1. **Question** — quelle question statistique pose-t-on ?
2. **Données** — quelles sources, quelle licence, quelle date ?
3. **Méthode** — quel traitement, quelle hypothèse ?
4. **Résultat** — un graphique ou une carte unique.
5. **Limite** — qu'est-ce qui n'est pas garanti par cette analyse ?
6. **Décision possible** — qu'est-ce qu'un décideur pourrait en faire ?

L'objectif n'est pas une production exhaustive mais une **démonstration de maîtrise** d'un outil acquis dans l'atelier.

## Mini-projet — six éléments à livrer

Chaque groupe construit un livrable comportant exactement :

- Une **question** statistique précise.
- Un **indicateur** principal calculé.
- Un **graphique** ou une **carte**.
- Une **interprétation** en 3 phrases.
- Une **limite méthodologique** assumée.
- Une **recommandation** de suite (collecte, analyse, décision).

## Packages utilisés

- **Reproductibilité projet** : `usethis`, `here`, `fs`, `renv`
- **Versioning** : `gert` (Git pur R), `gh` (API GitHub)
- **Rendu Quarto** : `quarto` (CLI), `knitr`, `rmarkdown`
- **Manipulation spatiale** : `sf`, `dplyr`, `tibble`, `readr`
- **Cartographie** : `tmap` (modes plot + view), `ggplot2`
- **Automatisation** : `purrr::map_dfr`, `purrr::possibly`

## Pré-requis

- Avoir suivi les 9 jours précédents (ou avoir parcouru les runtimes WebR).
- R + RStudio + Quarto + Git installés (cf. `guide_installation.md`).
- Un compte GitHub (créé en J1 ou avant).

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `slides.qmd` | Cadrage en 7 parties (reproductibilité → Quarto → tmap → Git → automatisation → mini-projet → FAIR/clôture) |
| `demo.qmd` | Rapport Quarto multi-format complet sur `regions_indicateurs_demo.gpkg` |
| `demo.R` | Script formateur condensé (miroir de demo.qmd pour la salle) |
| `runtime.qmd` | WebR — calcul d'indicateur + carte tmap interactif |
| `exercice.qmd` | Q1-Q5 atelier R + Q-final mini-projet en groupe + grille présentation |
| `corrige.qmd` | Solutions Q1-Q5 + exemple de présentation réussie (modèle INS) |
| `install_packages_day.R` | Packages J10 + vérification Quarto + Git |

## Données utilisées

### Embarqué dans le repo (chargé automatiquement par le runtime WebR)

- `pedagogie/_commons/data/jour_10_extraits/regions_indicateurs_demo.gpkg` — extrait léger des 10 régions avec indicateurs démographiques et sociaux (population, ménages, eau améliorée, alphabétisation, écoles, formations sanitaires), CRS WGS84, < 200 ko. Source : dataset pédagogique préparé par Edith Darin (GDSG/IFORD) à partir de chiffres d'entraînement (à ne pas citer comme statistique officielle ; pour usage réel, mobiliser ECAM 4, MICS, EDS-MICS 2018 ou RGPH).

### Embarqué dans le repo pour la version desktop (commités, légers)

Le même dataset fil rouge est aussi disponible en plusieurs formats dans `pedagogie/datasets/cameroun/jour_10/`, accessible via `fetch_indicateurs_regions_demo(format = ...)` :

- `regions_indicateurs_demo.gpkg` — GeoPackage WGS84, 10 features (format par défaut).
- `regions_indicateurs_demo_shp/regions_indicateurs_demo.{shp,shx,dbf,prj,cpg}` — équivalent shapefile, pour illustrer la portabilité multi-format.
- `projet_final_indicateurs_demo.csv` — variante tabulaire (sans géométrie), pour démontrer la jointure attribut.

Source : matériel formateur Edith Darin (GDSG/IFORD), copié depuis son repo Drive vers ce repo via le script bootstrap.

### Script bootstrap

Si les fichiers ne sont pas présents en local (par exemple sur une machine fraîchement clonée du repo formateur d'Edith), lancer : `Rscript pedagogie/J10_workflows_reproductibles/00_copier_datasets_edith_j10.R`.

Ce script copie les trois variantes (gpkg + shp + csv) depuis le repo source d'Edith vers `pedagogie/datasets/cameroun/jour_10/`. Les fichiers sont volontairement commités (légers) pour rendre le mini-projet exécutable sans configuration externe.

## Crédits

Conception pédagogique (trame Quarto multi-format + tmap + atelier R + mini-projet + grille présentation + métadonnées minimales) : **Edith Darin** (Geospatial Data Science Group, ex-WorldPop/Oxford).

Intégration convention IFORD + parties Git, automatisation, FAIR avancée et cérémonie de clôture : **Ramesesse Dzita** (GDSG IFORD).

## Après l'atelier

Les participants conservent leur projet GitHub cloné. Le matériel reste disponible en ligne sur GitHub Pages (<https://dzita.github.io/atelier-r-spatial-iford-2026/>) pour révision et autoformation.

Une **communauté GDSG** (Slack / WhatsApp) est proposée pour le suivi post-formation, le partage d'expériences et de futures co-publications scientifiques autour du RGPH 4.

## Ressources pour continuer

- **Geocomputation with R** (Lovelace, Nowosad, Muenchow) : <https://r.geocompx.org/>
- **Spatial Data Science** (Pebesma, Bivand) : <https://r-spatial.org/book/>
- **R Packages** (Wickham, Bryan) : <https://r-pkgs.org/>
- **Happy Git and GitHub for the useR** (Bryan) : <https://happygitwithr.com/>
- **Quarto guide** : <https://quarto.org/docs/guide/>
- **FAIR principles** : <https://www.go-fair.org/fair-principles/>
- **ISO 19115 métadonnées géospatiales** : <https://www.iso.org/standard/53798.html>
- **Afrimapr** (communauté R-spatial Afrique) : <https://afrimapr.github.io/>
