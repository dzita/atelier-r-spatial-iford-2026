# Données du jour — dossier `datasets/`

Ce dossier reçoit **les fichiers de données de ce jour uniquement**, à plat.
Les scripts du jour les lisent en chemin relatif : `datasets/<fichier>`.

## Comment le remplir

Depuis la racine du projet (ouvrir `atelier-r-spatial-iford-2026.Rproj`) :

```r
source("outils/distribuer_donnees.R")
```

## Fichiers de ce jour

Inventaire vérifié : chaque fichier présent est lu par le matériel de la journée.
**Total : environ 175 Mo**, dont 90 Mo d'imagerie satellite.

### Imagerie Sentinel-2 — 26 juin 2026

| Fichier | Poids | Bande | Rôle |
|---|---:|---|---|
| `…Sentinel-2_L2A_B08_(Raw).tiff` | 16,1 Mo | proche infrarouge (NIR) | **calcul** du NDMI |
| `…Sentinel-2_L2A_B11_(Raw).tiff` | 15,7 Mo | infrarouge moyen (SWIR) | **calcul** du NDMI |
| `…Sentinel-2_L2A_True_color.tiff` | 58,2 Mo | composition RVB visible | **affichage** seul |

> **Ce que couvre réellement cette tuile — à savoir avant tout découpage.**
>
> | | Valeur |
> |---|---|
> | Emprise | **11,53° à 14,88° E**, **2,49° à 5,81° N** |
> | Zone | Est et Sud du Cameroun, autour de Yokadouma |
> | CRS | **WGS 84 (EPSG:4326)** — en degrés, *pas* en UTM |
> | Résolution | ≈ 0,0013° soit **environ 150 m** — *pas* les 10 m natifs |
> | Dimensions | 2500 × 2487 pixels |
>
> Elle **ne contient ni Douala, ni l'Adamaoua, ni le Nord, ni l'Ouest**.
> Un `crop` sur ces zones échoue avec `[crop] extents do not overlap`.
> Premier réflexe : `terra::ext(mon_raster)`.

**B08 et B11 ont déjà la même grille** dans cette tuile — ce n'est pas le cas des
produits Sentinel-2 natifs (10 m et 20 m). Le rééchantillonnage de la section 3.3
est donc sans effet ici, mais reste enseigné : il conditionne tout calcul d'indice
sur des bandes brutes.

### Limites administratives — GADM 4.1

| Fichier | Contenu | Sections |
|---|---|---|
| `gadm41_CMR_0.shp` | contour du pays | 2.5, 4.1 |
| `gadm41_CMR_1.shp` | 10 régions | 2.5, 4.1, 4.4 |
| `gadm41_CMR_2.shp` | 58 départements | 2.5, 3.1, 4.2, 4.3 |

Chaque `.shp` s'accompagne obligatoirement de `.shx`, `.dbf`, `.prj`, `.cpg`.

### Données d'enquête et de population

| Fichier | Contenu | Sections |
|---|---|---|
| `CMR_population_v1_0_admin_level2.xlsx` | population WorldPop par département | 4.3 |
| `CMR_household_v1_0_admin_level2.xlsx` | ménages par département | 4.3 |
| `CMGE71FL.shp` | EDS 2018 — positions GPS des grappes | 4.4 |
| `CMIR71FL.SAV` | EDS 2018 — femmes (Individual Recode), 82 Mo | 4.4 |

Les variantes `.csv` de WorldPop sont présentes mais **non utilisées** : le
matériel lit les `.xlsx`. Elles ne pèsent que 3 Ko chacune et servent de
solution de repli, mentionnée en commentaire dans le code.

## Les pièges de cette journée

**Les nombres du `.xlsx` sont du texte.** `total`, `lower` et `upper` sont
stockés en chaînes de caractères — `'181165.54'`. Toute arithmétique dessus
échoue ou coerce en silence. Le matériel convertit explicitement avec
`as.numeric()`.

**Les libellés ne concordent pas avec GADM.** WorldPop écrit sans accents
(`Benoue`, `Nyong et Soo`) là où GADM utilise l'orthographe officielle
(`Bénoué`, `Nyong et So'o`). Une jointure naïve perd **11 départements sur 58**,
sans lever d'erreur. La section 4.3 montre la normalisation qui les récupère tous.

**Le nodata pollue les indices.** Sur les bordures de tuile, une bande peut valoir
zéro : la fraction du NDMI dégénère alors en ±1. Quelques pixels suffisent à
étirer l'échelle de couleurs et à aplatir la carte. Le matériel les écarte avant
le calcul et borne l'affichage sur les centiles 1 et 99.

**Variables DHS en MAJUSCULES.** Dans les fichiers SPSS (`.sav`), les noms sont
en capitales — `V001`, et non `v001` comme dans les `.dta`. Un test insensible à
ce détail échoue silencieusement.

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
