# J1 — Introduction à R et à la pensée spatiale

**Atelier IFORD × GDSG · Lundi 27 juillet 2026 · Yaoundé · 8 heures**

## Objectifs

À la fin de la journée, chaque participant doit pouvoir :

1. Naviguer dans RStudio et créer un projet reproductible avec `here`.
2. Manipuler un `data.frame` issu d'une enquête démographique camerounaise (vecteurs, indexation, filtres, agrégats).
3. Comprendre ce qui distingue un `data.frame` d'un objet spatial `sf`.
4. Charger les limites administratives du Cameroun et produire une première carte propre.
5. Énoncer ce qu'est un **système de coordonnées de référence** (CRS) et pourquoi le confondre cause des erreurs de plusieurs kilomètres.

## Public cible

Statisticiens d'INS, démographes IFORD, techniciens de ministères, ONG. Manipulent déjà Excel et Stata/SPSS — on les fait basculer vers la grammaire R, puis on leur montre qu'**un tableau peut avoir une géométrie**.

## Déroulé (8h)

| Bloc | Durée | Contenu |
|---|---|---|
| 1. R comme calculatrice statistique | 1h30 | Vecteurs, tibble, dplyr basics. Exemple : 10 régions CMR + populations 2019. |
| 2. Projet RStudio + `here` + reproductibilité | 1h00 | Lecture enquête EDS-MICS 2018 (simulée), `skim()`, indicateurs régionaux. |
| 3. Qu'est-ce qu'un objet spatial ? | 1h30 | Anatomie `sf`, GADM CMR ADM0–ADM3. |
| 4. Premier coup d'œil cartographique | 1h00 | `plot()` base R, `ggplot + geom_sf`, `tmap` minimal. |
| 5. CRS — la séance qui sauve des kilomètres | 1h30 | EPSG:4326 vs 32632 vs 3857, démo distance Yaoundé–Douala, `st_transform`, calcul superficie. |
| 6. Première vraie carte | 1h00 | Choroplèthe densité régionale CMR. |
| 7. Wrap-up + devoirs | 0h30 | Récap, exercice à faire en autonomie. |

## Fichiers de ce jour

| Fichier | Pour qui | Description |
|---|---|---|
| `README.md` | tous | Ce que tu lis. |
| `demo.qmd` | participants | Animation pédagogique complète (rendu HTML/PDF). Distribuée en fin de journée. |
| `demo.R` | animateur | Version exécutable rapide, à projeter ligne par ligne en salle. |
| `slides.qmd` | animateur | Deck revealjs de projection (~35 slides). |
| `runtime.qmd` | participants | Version WebR — code exécutable dans le navigateur, zéro install. |
| `exercice.qmd` | participants | TP individuel à faire le soir (30 min). |
| `corrige.qmd` | participants | Corrigé du TP, distribué le lendemain matin. |

## Données mobilisées

- **GADM v4.1 Cameroun ADM0–ADM3** — <https://gadm.org/download_country.html> · libre académique.
- **Estimations population régionale BUCREP 2019** — ordres de grandeur pédagogiques, à actualiser dès la diffusion du RGPH 4.
- **EDS-MICS Cameroun 2018** — <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm> · DHS Program (inscription requise).
- Coordonnées chefs-lieux (compilation pédagogique).

## Packages R utilisés

`here`, `fs`, `tidyverse` (dplyr, tibble, ggplot2, readr), `janitor`, `skimr`, `haven`, `sf`, `tmap`, `rnaturalearth`.

Tous installés via `environnement_technique/install_packages.R` et vérifiés par `verification_setup.R`.

## Sources méthodologiques

- Pebesma 2018 — *Simple Features for R*.
- Burgert et al. 2013 — *DHS Geographic displacement procedure* (rappelé J5).
- BUCREP RGPH 4 — communications officielles.

Bibliographie complète : `../_commons/helpers/citations.bib`.

## Notes pour l'animateur

- Tester `demo.R` la veille au soir : les téléchargements GADM passent par `_commons/helpers/fetch_data.R` qui essaie l'URL puis bascule sur le fichier local de secours s'il existe.
- En cas de pépin réseau salle : la clé USB de secours contient les GeoPackages GADM. Voir `manuel_animateur.md` (racine de `pedagogie/`).
- La séance CRS (bloc 5) est la plus haute densité conceptuelle de la journée — prévoir 5-10 min de pause juste avant.
