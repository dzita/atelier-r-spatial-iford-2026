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
- `CMGE71FL.shp`
- `CMIR71FL.SAV`
- `CMR_household_v1_0_admin_level2.csv`
- `CMR_household_v1_0_admin_level2.xlsx`
- `CMR_population_v1_0_admin_level2.csv`
- `CMR_population_v1_0_admin_level2.xlsx`
- `gadm41_CMR_0.shp`
- `gadm41_CMR_1.shp`
- `gadm41_CMR_2.shp`


_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
