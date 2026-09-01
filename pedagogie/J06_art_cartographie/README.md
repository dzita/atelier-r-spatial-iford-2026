# J6 — Faire parler les cartes : l'art de la visualisation

**Atelier IFORD × GDSG 2026 · Samedi 1er août 2026 · Yaoundé**

**Référents : J.S. Alogo, M. Teda, R. Dzita · Support : R. Elandi**

> Conforme à l'agenda final du 23/07/2026 (nomenclature J1–J11).

## Objectif

Produire des cartes de qualité publication, statiques et interactives, en citant la source des données sur chaque carte.

## Déroulé (journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00)

**Session 1 (08h30–10h30)**

- La grammaire des cartes thématiques : choroplèthes, cartes à points, facettes
- Les principes d'une bonne conception cartographique — et les pièges classiques

**Session 2 (11h00–13h00)**

- Cartes officielles sur données réelles : population et densité par département
- Palettes, classes, légendes, habillage

**Session 3 (14h00–16h00)**

- Cartes interactives et petits tableaux de bord
- Séquence IA du jour : améliorer l'habillage d'une carte par itérations guidées

**Session 4 (16h15–17h00)**

- Atelier : la carte de synthèse d'un rapport officiel ; exercice du soir

## Fichiers de ce jour

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `slides.qmd / *.pptx` | supports de présentation |
| `script_formateur_J6.R` | script de démonstration du formateur |
| `demo_formateur_J6.qmd` | le même code, en document Quarto par sections |
| `script_etudiant_J6.R` | trame à compléter par les participants (supervision formateur) |
| `script_etudiant_J6_corrige.R` | corrigé complet (distribution en fin de journée) |
| `runtime.qmd` | version WebR exécutable dans le navigateur (site en ligne) |
| `demo.qmd · demo.R · exercice.qmd · corrige.qmd` | matériel v1 conservé (complément) |

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier `datasets/` (fichiers à plat), lues en **chemins relatifs** `datasets/<fichier>` par les scripts, et les sorties vont dans `outputs/`.

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus (présents / à fournir) est dans `datasets/LISEZMOI.md`.
