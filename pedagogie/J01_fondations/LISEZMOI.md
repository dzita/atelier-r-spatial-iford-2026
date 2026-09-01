# Données du jour — dossier `datasets/`

Ce dossier reçoit **les fichiers de données de ce jour uniquement**, à plat.
Les scripts du jour les lisent en chemin relatif : `datasets/<fichier>`.

## Comment le remplir

Depuis la racine du projet (ouvrir `atelier-r-spatial-iford-2026.Rproj`) :

```r
source("outils/distribuer_donnees.R")   # copie ici les fichiers voulus
```

(Le magasin central `pedagogie/datasets/cameroun/` doit avoir été rempli au
préalable via son `00_telecharger_donnees_drive.R`.)

## Fichiers de ce jour

| Fichier | Contenu | Utilisé par |
|---|---|---|
| `CMHR71FL.SAV` | EDS Cameroun 2018 — **ménages** (Household Recode), 11 710 × 5 741 | sections 5.1 et 6 |
| `CMIR71FL.SAV` | EDS Cameroun 2018 — **femmes** (Individual Recode), 14 677 × 5 102 | sections 5.2 et 6 |

Les deux sont au format **SPSS (`.sav`)** et présents dans le magasin central,
donc copiés automatiquement.

> **Piège à connaître.** DHS nomme ses variables en **minuscules** dans les
> fichiers STATA (`.dta`) mais en **MAJUSCULES** dans les fichiers SPSS (`.sav`).
> Un test `"v201" %in% names(df)` échoue donc silencieusement sur un `.sav`.
> Les scripts du jour utilisent la fonction `trouver_vars()`, qui résout les
> noms sans tenir compte de la casse.

## Variables de démonstration

Un fichier EDS compte plusieurs milliers de colonnes : ne jamais lancer `str()`
ou `summary()` sur l'objet entier. Les scripts explorent ce sous-ensemble :

- **ménages** — `hv001` grappe, `hv002` numéro de ménage, `hv009` taille,
  `hv024` région, `hv025` milieu, `hv206` électricité, `hv270` quintile
- **femmes** — `v012` âge, `v024` région, `v025` milieu, `v106` instruction,
  `v201` nombre d'enfants nés vivants, `v190` quintile

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
