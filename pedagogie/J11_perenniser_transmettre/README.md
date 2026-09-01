# J11 — Pérenniser et transmettre : la formation ne s'arrête pas ici

**Atelier IFORD × GDSG 2026 · Vendredi 7 août 2026 · Yaoundé**

**Référents : R. Dzita, E. Darin, M. Teda · Support : R. Elandi**

> Conforme à l'agenda final du 23/07/2026 (nomenclature J1–J11).

## Objectif

Installer les réflexes de reproductibilité, montrer comment pérenniser l'investissement de la formation (plateforme en ligne, WebR), et clôturer par la restitution des mini-projets et la feuille de route institutionnelle.

## Déroulé (journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00)

**Session 1 (08h30–10h30)**

- Les analyses reproductibles : un même document → rapport Word, page web, présentation
- Le travail collaboratif versionné

**Session 2 (11h00–13h00)**

- Présentation (R. Dzita) : la plateforme de formation en ligne — WebR, construction du site, bénéfices (formation, communication, qualité/mémoire institutionnelle, pérennisation/réplication)

**Session 3 (14h00–16h00)**

- Restitution des mini-projets de groupe
- Principes FAIR et métadonnées

**Session 4 (16h15–17h00)**

- Feuille de route INS/BUCREP ; communauté GDSG ; clôture officielle et remise des attestations

## Fichiers de ce jour

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `slides.qmd / *.pptx` | supports de présentation |
| `script_formateur_J11.R` | script de démonstration du formateur |
| `demo_formateur_J11.qmd` | le même code, en document Quarto par sections |
| `script_etudiant_J11.R` | trame à compléter par les participants (supervision formateur) |
| `script_etudiant_J11_corrige.R` | corrigé complet (distribution en fin de journée) |
| `runtime.qmd` | version WebR exécutable dans le navigateur (site en ligne) |
| `demo.qmd · demo.R · exercice.qmd · corrige.qmd` | matériel v1 conservé (complément) |

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier `datasets/` (fichiers à plat), lues en **chemins relatifs** `datasets/<fichier>` par les scripts, et les sorties vont dans `outputs/`.

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus (présents / à fournir) est dans `datasets/LISEZMOI.md`.
