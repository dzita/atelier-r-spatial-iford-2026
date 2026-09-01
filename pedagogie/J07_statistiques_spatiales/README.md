# J7 — Le hasard a-t-il une géographie ? Statistiques spatiales

**Atelier IFORD × GDSG 2026 · Lundi 3 août 2026 · Yaoundé**

**Référents : J.S. Alogo, M. Teda, R. Dzita · Support : R. Elandi**

> Conforme à l'agenda final du 23/07/2026 (nomenclature J1–J11).

## Objectif

Partir de problèmes concrets (épidémies, incidence du paludisme, accès aux services) pour introduire chacun des outils d'analyse statistique spatiale.

## Déroulé (journée type : accueil 08h00, pauses 10h30 et 16h00, déjeuner 13h00)

**Session 1 (08h30–10h30)**

- Qu'est-ce qu'un motif spatial ? Aléatoire, agrégé, régulier
- L'autocorrélation spatiale : mesurer la ressemblance entre territoires voisins

**Session 2 (11h00–13h00)**

- Détecter les concentrations locales : points chauds et points froids
- Estimer des densités : où les services se concentrent-ils réellement ?

**Session 3 (14h00–16h00)**

- Pratique : la répartition des établissements de santé et des écoles
- Séquence IA du jour : interpréter des sorties statistiques sans déléguer le jugement

**Session 4 (16h15–17h00)**

- Ce que ces méthodes disent — et ne disent pas — aux décideurs ; exercice du soir

## Fichiers de ce jour

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `slides.qmd / *.pptx` | supports de présentation |
| `script_formateur_J7.R` | script de démonstration du formateur |
| `demo_formateur_J7.qmd` | le même code, en document Quarto par sections |
| `script_etudiant_J7.R` | trame à compléter par les participants (supervision formateur) |
| `script_etudiant_J7_corrige.R` | corrigé complet (distribution en fin de journée) |
| `runtime.qmd` | version WebR exécutable dans le navigateur (site en ligne) |
| `demo.qmd · demo.R · exercice.qmd · corrige.qmd` | matériel v1 conservé (complément) |

## Données

Ce dossier est **autonome** : les données du jour sont dans le sous-dossier `datasets/` (fichiers à plat), lues en **chemins relatifs** `datasets/<fichier>` par les scripts, et les sorties vont dans `outputs/`.

Remplir `datasets/` une fois, depuis la racine du projet :

```r
source("outils/distribuer_donnees.R")
```

La liste précise des fichiers attendus (présents / à fournir) est dans `datasets/LISEZMOI.md`.
