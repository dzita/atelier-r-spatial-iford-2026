# J02 — Penser l'espace : où, et pourquoi là ?

**Atelier IFORD × GDSG 2026 · Mardi 28 juillet 2026 · Yaoundé**

**Référents : M. Teda, R. Dzita · Support : R. Elandi**

> Conforme à l'agenda final du 23/07/2026 (nomenclature J01–J11).

## Objectif

Comprendre les objets, opérations et formats de l'information géographique avant toute ligne de code, et installer la méthode de travail avec l'IA qui servira toute la formation.

## Déroulé (journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00)

**Session 1 (08h30–10h30)**

- La pensée spatiale : « où ? pourquoi là ? » en démographie et en statistique publique
- Les types de données spatiales — points, lignes, polygones, grilles

**Session 2 (11h00–13h00)**

- Les opérations fondamentales sur ces objets et leurs combinaisons
- Formats de fichiers, géodatabases multi-couches, systèmes de coordonnées ; usages dans les INS

**Session 3 (14h00–16h00)**

- MODULE IA — Bien travailler avec l'intelligence artificielle : méthode en 4 temps, règles d'or, démonstrations sur données réelles, pratique par binômes

**Session 4 (16h15–17h00)**

- Première pratique sur machine : un tableau peut avoir une géométrie ; première carte du Cameroun ; exercice du soir

## Fichiers de ce jour

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `Jour02_Penser_Espace_Geospatial.pptx` | support de présentation |
| `module_IA_geospatial.md` | **module IA de la session 3** — méthode, règles d'or, exercices |
| `script_formateur_J02.R` | script de démonstration du formateur |
| `demo_formateur_J02.qmd` | le même code, en document Quarto par sections (rendu HTML) |
| `script_etudiant_J02.R` | trame à compléter par les participants (supervision formateur) |
| `script_etudiant_J02_corrige.R` | corrigé complet (distribution en fin de journée) |
| `runtime.qmd` | version WebR exécutable dans le navigateur (site en ligne) |
| `install_packages_day.R` | installation des packages du jour, à lancer une fois |
| `datasets/` | données du jour — voir `datasets/LISEZMOI.md` |

## Note pédagogique

Cette journée pose le **vocabulaire** de l'information géographique : vecteur et
raster, systèmes de coordonnées, jointures attributaires et spatiales. Le démo
formateur montre chaque notion **en R sur les données réelles du Cameroun**, pour
faire voir le potentiel de l'outil — mais **les participants ne codent pas
aujourd'hui**, hormis la première carte de la session 4. La pratique commence au
J03.

Les blocs `sf`, `terra` et `tmap` du démo sont donc des démonstrations, pas des
apprentissages techniques : ces trois paquets sont enseignés respectivement aux
J03, J04 et J06.

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier `datasets/` (fichiers à plat), lues en **chemins relatifs** `datasets/<fichier>` par les scripts, et les sorties (cartes, rasters traités) vont dans `outputs/`.

Toutes les données du jour sont disponibles : aucune section n'est en attente d'un fichier externe.

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus (présents / à fournir) est dans `datasets/LISEZMOI.md`.
