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

Inventaire vérifié : chaque fichier présent est réellement lu par le matériel de
la journée, et chaque fichier lu est présent. **Total : 92,3 Mo.**

### Limites administratives — GADM 4.1

| Fichier | Poids | Contenu | Sections |
|---|---:|---|---|
| `gadm41_CMR_0.shp` | 0,3 Mo | contour du pays | 3.3 |
| `gadm41_CMR_1.shp` | 0,6 Mo | 10 régions | 3.3, 3.4, 4.2, 4.4 |
| `gadm41_CMR_2.shp` | 1,3 Mo | 58 départements | 3.3, 4.1, 4.2, 4.4 |

Chaque `.shp` s'accompagne obligatoirement de ses fichiers annexes
(`.shx`, `.dbf`, `.prj`, `.cpg`) — `distribuer_donnees.R` les copie ensemble.
Sans eux, `st_read()` échoue ou perd les attributs.

### Données statistiques et d'enquête

| Fichier | Poids | Contenu | Sections |
|---|---:|---|---|
| `CMR_population_v1_0_admin_level2.csv` | 3 Ko | population WorldPop par département — **séparateur `;`** | 2.2 → 4.4 |
| `CMR_household_v1_0_admin_level2.csv` | 3 Ko | ménages par département — **séparateur `,`** | 2.2 → 4.4 |
| `CMGC72FL.csv` | 0,8 Mo | EDS 2018 — **130 covariables** par grappe, sans coordonnées | 3.4, 4.3 |
| `CMGE71FL.shp` | 1,4 Mo | EDS 2018 — **positions GPS des grappes** (la géométrie) | 3.4, 4.2, 4.4 |

Les deux derniers vont par paire : le `.shp` porte la position, le `.csv` porte
les attributs, et la clé qui les relie est `DHSCLUST`.

### Imagerie satellite — Sentinel-2, 26 juin 2026

| Fichier | Poids | Bande | Rôle |
|---|---:|---|---|
| `…Sentinel-2_L2A_B08_(Raw).tiff` | 16,1 Mo | proche infrarouge (NIR) | **calcul** du NDMI |
| `…Sentinel-2_L2A_B11_(Raw).tiff` | 15,7 Mo | infrarouge moyen (SWIR) | **calcul** du NDMI |
| `…Sentinel-2_L2A_True_color.tiff` | 58,2 Mo | composition RVB visible | **affichage** seul |

B08 et B11 portent des réflectances brutes : ils sont indispensables et
irremplaçables pour le NDMI. La True Color, en revanche, ne sert qu'à montrer le
territoire vu du satellite — c'est le seul candidat à un allègement si le poids
du dossier devient gênant.

> **Ne pas y ajouter `sentinel2_cameroun.tif`** (2,2 Mo, dans le magasin
> central). Malgré son nom, c'est une image de visualisation en 8 bits,
> 627 × 885 pixels : elle ne contient aucune mesure de réflectance et ne peut
> pas servir au calcul d'un indice.

### Ce qui ne doit PAS être ici

- **`ACLED_Data.csv`** — données de conflit, relèvent du **J10**. Copié par
  erreur lors de l'arbitrage sur le remplacement du FIES ; aucun fichier de J02
  ne le lit. À supprimer.

## Le piège des valeurs manquantes déguisées

`CMGC72FL.csv` code l'absence de mesure par des **sentinelles négatives**, pas
par `NA`. Elles passent inaperçues dans un `mean()`.

| Variable | Codes rencontrés | Grappes touchées |
|---|---|---|
| `Malaria_Prevalence_2015` | `-9999` | 4 / 430 |
| `Aridity_2015` | `-9999` | 6 / 430 |
| `Growing_Season_Length` | `-9999`, `-997`, `-809`, `-807`, `-801` | **214 / 430** |

`Growing_Season_Length` est **inexploitable en l'état** : la moitié du fichier est
manquante, sous cinq codes différents. Le démo s'en sert comme contre-exemple.

## Deux autres pièges de cette journée

**Séparateurs différents.** Les deux CSV WorldPop portent la même extension mais
l'un est en `;` et l'autre en `,`. `read_csv()` sur le premier renvoie une seule
colonne, sans erreur.

**Libellés non concordants.** Les noms de départements de WorldPop sont sans
accents (`Benoue`, `Nde`, `Nyong et Soo`) là où GADM les écrit correctement
(`Bénoué`, `Ndé`, `Nyong et So'o`). Une jointure naïve perd **11 départements
sur 58**, en silence. La section 4.1 montre la normalisation qui les récupère
tous.

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
