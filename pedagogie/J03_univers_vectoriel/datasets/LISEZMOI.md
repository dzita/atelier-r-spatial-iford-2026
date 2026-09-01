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

- `CMGC72FL.csv`
- `CMGE71FL.shp`
- `CMR_household_v1_0_admin_level2.csv`
- `CMR_population_v1_0_admin_level2.csv`
- `DS.geojson`
- `Pays_limitrophes_Cmr.shp`
- `gadm41_CMR_0.shp`
- `gadm41_CMR_1.shp`
- `gadm41_CMR_2.shp`

**Référencés mais à fournir / renommer** (absents du magasin central au 25/07/2026) :

- `CMBR71FR.sav`
- `CMWF71FR.sav`

> Voir `pedagogie/datasets/cameroun/README.md` pour l'état de ces fichiers
> (ex. noms EDS à harmoniser, FIES, Sentinel B03/B04, GHS-POP, ACLED…).

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
