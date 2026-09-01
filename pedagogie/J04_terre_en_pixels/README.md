# J04 — La Terre en pixels : les données d'observation continue

**Atelier IFORD × GDSG 2026 · Jeudi 30 juillet 2026 · Yaoundé**

**Référents : M. Teda, R. Dzita · Support : R. Elandi**

> Conforme à l'agenda final du 23/07/2026 (nomenclature J01–J11).

## Objectif

Maîtriser les données en grille (altitude, imagerie satellite) seules, puis en combinaison avec les territoires — jusqu'aux premiers indices et à un cas d'école décisionnel.

## Déroulé (journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00)

**Session 1 (08h30–10h30)**

- Anatomie d'une donnée en grille : étendue, résolution, bandes
- Lecture d'images satellite réelles du Cameroun (juin 2026) et d'un modèle de terrain

**Session 2 (11h00–13h00)**

- Les géotraitements essentiels : découper, masquer, rééchantillonner, agréger
- Croiser grilles et territoires : statistiques par région

**Session 3 (14h00–16h00)**

- Indices de végétation et d'eau : calcul et interprétation
- Cas d'école : zones urbaines exposées aux inondations
- Séquence IA du jour : générer et critiquer une chaîne de géotraitements

**Session 4 (16h15–17h00)**

- La checklist du statisticien spatial ; exercice du soir

## Fichiers de ce jour

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `Jour04_Terre_En_Pixels_Raster.pptx` | support de présentation |
| `script_formateur_J04.R` | script de démonstration du formateur |
| `demo_formateur_J04.qmd` | le même code, en document Quarto par sections (rendu HTML) |
| `script_etudiant_J04.R` | trame à compléter par les participants |
| `script_etudiant_J04_corrige.R` | corrigé complet (distribution en fin de journée) |
| `runtime.qmd` | version WebR exécutable dans le navigateur |
| `install_packages_day.R` | installation des packages du jour, à lancer une fois |
| `datasets/` | données du jour — voir `datasets/LISEZMOI.md` |

## Note pédagogique

Cette journée enseigne le **raster** avec `terra` : lecture, métadonnées, découpe,
masque, rééchantillonnage, agrégation, algèbre de bandes, statistiques zonales.

Deux points méritent l'attention du formateur.

**Le NDVI n'est pas calculé, et c'est délibéré.** Il exigerait la bande B04, dont
nous ne disposons pas. Le calculer à partir de l'image `True_color` — une
composition visuelle 8 bits — produirait une carte plausible et fausse. La section
4.1.1 en fait un point d'enseignement : *ne jamais combiner deux bandes qui n'ont
pas subi le même traitement radiométrique*. L'indice réellement calculé est le
**NDMI**, à partir de B08 et B11, toutes deux en réflectance brute.

**La tuile ne couvre pas tout le pays.** Elle s'étend de 11,5° à 14,9° E et de
2,5° à 5,8° N — l'Est et le Sud. Les exercices ont été adaptés en conséquence, et
le document commence par vérifier l'emprise avant tout découpage.

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier `datasets/` (fichiers à plat), lues en **chemins relatifs** `datasets/<fichier>` par les scripts, et les sorties vont dans `outputs/`.

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus (présents / à fournir) est dans `datasets/LISEZMOI.md`.
