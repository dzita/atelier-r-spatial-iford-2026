# J10 — Flux de travail reproductibles et renforcement des capacités

**Atelier IFORD × GDSG · Jeudi 6 août 2026 · Yaoundé · 6 heures**

> Contenu aligné sur le programme officiel IFORD : flux de travail reproductibles + présentations courtes des participants + session de clôture (FAIR, métadonnées, feuille de route INS/BUCREP).

## Objectifs pédagogiques

À la fin de J10, chaque participant doit pouvoir :

1. Construire un rapport **Quarto reproductible** combinant code R, cartes et narration scientifique.
2. Utiliser les **bases de Git** pour versionner un projet R-spatial.
3. **Automatiser** un traitement spatial répétitif via une fonction R et une boucle.
4. Énoncer les **principes FAIR** (Findable, Accessible, Interoperable, Reusable) et leurs implications pour les sorties d'analyse spatiale.
5. Connaître les **normes de métadonnées géospatiales** (ISO 19115, Dublin Core étendu) et leur application aux livrables d'un INS.

## Déroulé horaire (6 h selon programme officiel)

| Bloc | Durée | Format |
|---|---|---|
| Wrap-up J1–J9 + intro J10 | 30 min | Slides |
| Théorie 1 — Pourquoi la reproductibilité ? | 30 min | Slides |
| Démo 1 — Construire un rapport Quarto | 1 h | demo |
| Théorie 2 — Versioning avec Git | 30 min | Slides |
| Démo 2 — Init repo, commit, push | 45 min | demo + Q1 |
| Théorie 3 — Automatisation et scripts | 30 min | Slides |
| Démo 3 — Fonction et boucle pour batch processing | 30 min | demo + Q2 |
| **Présentations courtes des participants** | 1 h | Restitutions |
| Session de clôture : FAIR + métadonnées + feuille de route INS | 30 min | Slides |
| Q&A + remise des certificats | 30 min | Cérémonie |

## Format des présentations

À l'inverse du « mini-projet de 1.5 jour » initialement envisagé, les présentations de J10 sont **courtes (5–8 min)** et portent sur **un livrable construit pendant les 9 jours précédents** :

- Une carte produite en J3 ou J5.
- Une analyse top-down ou bottom-up de J7.
- Un croisement raster × vecteur de J3 ou J6.
- Un script automatisé construit en démo J10.

L'objectif n'est pas une production exhaustive mais une **démonstration de maîtrise** d'un outil acquis dans l'atelier.

## Packages utilisés

- `quarto` (CLI) — moteur de rendu
- `usethis` — création de projets, init Git
- `gert` ou `git2r` — opérations Git depuis R
- `here` — chemins relatifs reproductibles
- `renv` — gestion des versions de packages
- `purrr::map_*` — automatisation fonctionnelle

## Pré-requis

- Avoir suivi les 9 jours précédents.
- R + RStudio + Quarto + Git installés (cf. `guide_installation.md`).
- Avoir un compte GitHub (créé en J1 ou avant).

## Fichiers du jour

| Fichier | Rôle |
|---|---|
| `slides.qmd` | Cadrage de la journée (reproductibilité + présentations + clôture) |
| `demo.qmd` | Exemple complet d'un projet reproductible Quarto + Git |
| `demo.R` | Script automatisé (boucle batch processing) |
| `runtime.qmd` | Pas de runtime spécifique — voir liens vers runtimes J1–J9 |
| `exercice.qmd` | Activités du jour (Q1 : init Git + commit ; Q2 : Quarto rapport ; Q3 : automatisation) + cahier des charges présentation |
| `corrige.qmd` | Solutions commentées + exemple de présentation réussie |
| `install_packages_day.R` | Installation des packages pour J10 (`usethis`, `renv`, `quarto`, `bookdown`…) |

## Après l'atelier

Les participants conservent leur projet GitHub cloné. Le matériel reste disponible en ligne sur GitHub Pages (<https://dzita.github.io/atelier-r-spatial-iford-2026/>) pour révision et autoformation.

Une **communauté Slack / WhatsApp** des anciens de l'atelier est proposée pour le suivi post-formation et le partage d'expériences.

## Ressources pour continuer

- **Geocomputation with R** (Lovelace et al.) : <https://r.geocompx.org/>
- **Spatial Data Science** (Pebesma, Bivand) : <https://r-spatial.org/book/>
- **WorldPop documentation** : <https://www.worldpop.org/>
- **R Packages** (Wickham, Bryan) : <https://r-pkgs.org/>
- **Happy Git and GitHub for the useR** (Bryan) : <https://happygitwithr.com/>
