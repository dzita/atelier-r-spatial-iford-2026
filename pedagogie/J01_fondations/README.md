# J01 — Changer d'outil sans changer de métier : les fondations

**Atelier IFORD × GDSG 2026 · Lundi 27 juillet 2026 · Yaoundé**

**Référents : M. Teda, R. Dzita · Support : R. Elandi**

> Conforme à l'agenda final du 23/07/2026 (nomenclature J01–J11).

## Objectif

Amener tout le groupe au même point de départ : un public habitué aux logiciels statistiques classiques, capable en fin de journée d'installer son environnement, d'écrire ses premières analyses, d'importer des données d'enquêtes réelles et de les explorer.

## Déroulé (journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00)

**Session 1 (08h30–10h30)**

- Mot de bienvenue (Directeur IFORD, coordonnateur GDSG)
- Pourquoi changer d'outil ? Le tableau de correspondance permanent avec STATA/SPSS
- Installation guidée de l'environnement et vérifications poste par poste

**Session 2 (11h00–13h00)**

- Prise en main de l'interface, premier script, organisation en projet
- Les objets de base et leur manipulation : vecteurs, tableaux de données, valeurs manquantes

**Session 3 (14h00–16h00)**

- Les extensions de l'outil : installation, chargement, désambiguïsation
- Import de données d'enquêtes nationales réelles (STATA, SPSS, tableur) et premiers réflexes d'exploration

**Session 4 (16h15–17h00)**

- Checklist de sortie poste par poste ; feuille de route des journées J02 à J11 ; exercice du soir

## Fichiers de ce jour

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `Jour01_Fondations_R_RStudio.pptx` | support de présentation |
| `script_formateur_J01.R` | script de démonstration du formateur |
| `demo_formateur_J01.qmd` | le même code, en document Quarto par sections (rendu HTML) |
| `script_etudiant_J01.R` | trame à compléter par les participants (supervision formateur) |
| `script_etudiant_J01_corrige.R` | corrigé complet (distribution en fin de journée) |
| `runtime.qmd` | version WebR exécutable dans le navigateur (site en ligne) |
| `install_packages_day.R` | installation des packages du jour, à lancer une fois |
| `datasets/` | données du jour — voir `datasets/LISEZMOI.md` |

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier `datasets/` (fichiers à plat), lues en **chemins relatifs** `datasets/<fichier>` par les scripts.

Deux fichiers EDS Cameroun 2018 au format SPSS : `CMHR71FL.SAV` (ménages) et `CMIR71FL.SAV` (femmes). Les scripts détectent automatiquement s'ils sont lancés depuis ce dossier ou depuis la racine du projet.

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus (présents / à fournir) est dans `datasets/LISEZMOI.md`.
