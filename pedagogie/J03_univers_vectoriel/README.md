# J3 — L'univers vectoriel : points, lignes et territoires

**Atelier IFORD × GDSG 2026 · Mercredi 29 juillet 2026 · Yaoundé**

**Référents : M. Teda, R. Dzita · Support : R. Elandi**

> Conforme à l'agenda final du 23/07/2026 (nomenclature J1–J11).

## Objectif

Reproduire en pratique tout ce qui a été vu conceptuellement au J2, exclusivement sur données réelles, selon le plan lecture → transformation/analyses → sauvegarde.

## Déroulé (journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00)

**Session 1 (08h30–10h30)**

- Panorama des outils de l'analyse spatiale moderne
- Lire des données géographiques de tous formats

**Session 2 (11h00–13h00)**

- Inspecter systématiquement une couche géographique avant analyse
- Vérifier et transformer les systèmes de coordonnées avant tout calcul métrique

**Session 3 (14h00–16h00)**

- Opérations vectorielles sur les données du Cameroun : superficies, tampons, intersections, jointures spatiales
- Séquence IA du jour : déléguer une sous-tâche de lecture/transformation et vérifier le résultat

**Session 4 (16h15–17h00)**

- Cartographier les résultats, sauvegarder dans le bon format ; exercice du soir

## Fichiers de ce jour

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `slides.qmd / *.pptx` | supports de présentation |
| `script_formateur_J3.R` | script de démonstration du formateur |
| `demo_formateur_J3.qmd` | le même code, en document Quarto par sections |
| `script_etudiant_J3.R` | trame à compléter par les participants (supervision formateur) |
| `script_etudiant_J3_corrige.R` | corrigé complet (distribution en fin de journée) |
| `runtime.qmd` | version WebR exécutable dans le navigateur (site en ligne) |
| `demo.qmd · demo.R · exercice.qmd · corrige.qmd` | matériel v1 conservé (complément) |

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier `datasets/` (fichiers à plat), lues en **chemins relatifs** `datasets/<fichier>` par les scripts, et les sorties vont dans `outputs/`.

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus (présents / à fournir) est dans `datasets/LISEZMOI.md`.
