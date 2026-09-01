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

## Fichiers attendus par ce jour

**Disponibles dans le magasin central (copiés automatiquement) :**

- `CMGE71FL.shp`
- `DS.geojson`
- `ecam5.dta`
- `eesi3.dta`
- `gadm41_CMR_1.shp`

**Référencés mais à fournir / renommer** (absents du magasin central au 25/07/2026) :

- `CMWF71FR.sav`
- `FIES_Cameroun.csv`

> Voir `pedagogie/datasets/cameroun/README.md` pour l'état de ces fichiers
> (ex. noms EDS à harmoniser, FIES, Sentinel B03/B04, GHS-POP, ACLED…).

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
