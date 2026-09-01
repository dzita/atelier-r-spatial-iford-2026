# J05 — Des enquêtes à la carte : relier données et territoires

**Atelier IFORD × GDSG 2026** · Référent : J.S. Alogo

Ce dossier est **autonome** : ouvrez-le dans RStudio, les données sont dans
`datasets/`, les sorties vont dans `outputs/`, et tous les chemins sont
relatifs à ce dossier.

## Démarrage

```r
source("install_packages_day.R")   # une seule fois
```

Puis ouvrir `demo_formateur_J05.qmd` et cliquer **Render**, ou exécuter
`scripts/script_formateur_J05.R` section par section.

Si `datasets/` est vide, revenir à la racine du projet
(`atelier-r-spatial-iford-2026.Rproj`) et lancer
`source("outils/distribuer_donnees.R")`.

## La question de la journée

Une enquête produit des lignes : un ménage, un individu, une réponse. Une
carte demande des polygones. **Comment passe-t-on des unes aux autres, et que
perd-on en route ?**

Deux ponts existent, et la journée les construit l'un après l'autre :

- une **clé commune** — un nom, un code — c'est la jointure attributaire ;
- une **position** — des coordonnées qui tombent dans un polygone — c'est la
  jointure spatiale.

Le fil conducteur est l'**accès à l'eau potable**, croisé avec la pauvreté
monétaire, du niveau national jusqu'au district sanitaire.

## Progression

| Module | Contenu | Ce qu'on en retire |
|---|---|---|
| **1** | Tidyverse, lecture des sources, verbes dplyr, tidyr | savoir ce que contient un fichier avant d'écrire une ligne ; pondérer |
| **2** | Objets `sf`, jointures par clé, points depuis coordonnées GPS | la première carte, et pourquoi une jointure échoue en silence |
| **3** | Valeurs manquantes, imputation, incohérences géographiques | distinguer hors champ et non-réponse ; réparer une géométrie |
| **4** | Prédicats spatiaux, agrégation pondérée, cartographie | descendre du ménage au district, et assumer le non-mesuré |
| **5** | Pipeline complet, contexte géographique, croisements, livrables | produire une carte défendable et l'exporter |

## Fichiers du dossier

| Fichier | Rôle |
|---|---|
| `demo_formateur_J05.qmd` | le document de référence — code **et** sorties, avec les interprétations |
| `scripts/script_formateur_J05.R` | miroir exécutable du `.qmd` |
| `scripts/script_etudiant_J05.R` | trame à compléter par les participants |
| `scripts/script_etudiant_J05_corrige.R` | corrigé, distribué en fin de journée |
| `slides.qmd` | support de projection |
| `runtime.qmd` | page WebR — exécution dans le navigateur, sans installation |
| `install_packages_day.R` | packages de la journée (9, pas 24) |
| `datasets/LISEZMOI.md` | inventaire des données, pièges documentés |

## Les cinq pièges que la journée met en scène

Ils sont réels, présents dans les fichiers, et chacun échoue **sans lever
d'erreur** :

1. `hhid` est partiellement anonymisé — ce n'est pas une clé de ménage.
2. Les enquêtes ont 12 régions, la carte en a 10.
3. La même région s'écrit de trois façons selon le fichier.
4. Les variables des `.SAV` du DHS sont en majuscules.
5. Les covariables contextuelles codent l'absence par `-9999`.

Le détail est dans `datasets/LISEZMOI.md`.

## Avertissement sur les chiffres

`ecam5.dta` est un extrait de formation. Le total national est cohérent avec
la publication de l'INS, **certains taux régionaux ne le sont pas**. Les
cartes de ce dossier démontrent une méthode ; elles ne publient pas une
statistique. La section 1.4 fait de cette confrontation à la référence un
exercice à part entière.

## Prolongements

- **J06** — l'art de la carte : sémiologie, palettes, mise en page.
- **J07** — tester l'hypothèse spatiale : autocorrélation, indice de Moran,
  estimation sur petits domaines.
- **J09** — travailler directement sur les rasters, plutôt que sur des
  covariables déjà extraites.
