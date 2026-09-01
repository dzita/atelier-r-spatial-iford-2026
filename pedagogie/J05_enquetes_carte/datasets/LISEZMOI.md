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

- `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B08_(Raw).tiff`
- `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B11_(Raw).tiff`
- `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_True_color.tiff`
- `CMGC72FL.csv`
- `CMR_household_v1_0_admin_level2.csv`
- `CMR_population_v1_0_admin_level2.csv`
- `DS.geojson`
- `Pays_limitrophes_Cmr.shp`
- `ecam5.dta`
- `gadm41_CMR_2.shp`

**Référencés mais à fournir / renommer** (absents du magasin central au 25/07/2026) :

- `CMBR71FR.sav`
- `CMWF71FR.sav`
- `FIES_Cameroun.csv`
- `FIES_Cameroun.xlsx`

> Voir `pedagogie/datasets/cameroun/README.md` pour l'état de ces fichiers
> (ex. noms EDS à harmoniser, FIES, Sentinel B03/B04, GHS-POP, ACLED…).

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
