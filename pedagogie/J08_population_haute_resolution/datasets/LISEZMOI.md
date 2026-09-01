# Données du jour — dossier `datasets/` (J08)

Ce dossier reçoit **les fichiers de données de cette journée uniquement**, à
plat, sans sous-dossier. Les scripts et le `.qmd` les lisent en chemin relatif
`datasets/<fichier>`.

> **Tailles : n.d.** Elles n'ont pas pu être mesurées lors de la rédaction de ce
> fichier et doivent être relevées sur le poste. Les postes les plus lourds sont
> les trois rasters WorldPop et les sept tuiles GHS-POP.

## Comment le remplir

Depuis la racine du projet (ouvrir `atelier-r-spatial-iford-2026.Rproj`) :

```r
source("outils/distribuer_donnees.R")   # copie ici les fichiers voulus
```

---

## Inventaire : les 12 fichiers attendus

### 1. Le tableau administratif

| Fichier | Taille |
|---|---|
| `cmr_admpop_adm1_2025.csv` | n.d. |

- **Source** : *Common Operational Dataset — Population Statistics* (COD-PS) du
  Cameroun, publié sur HDX (`data.humdata.org/dataset/cod-ps-cmr`).
- **Unité d'observation** : **la région administrative** (ADM1). 10 lignes.
- **Séparateur** : virgule, champs entre guillemets.
- **Clés candidates** : `ADM1_EN` (noms anglais), `ADM1_FR` (noms français),
  `ADM1_PCODE` (code p-code). **La journée ne choisit pas la clé à l'avance** :
  le module 1 compte les appariements de chaque candidate contre `NAME_1` de
  GADM et retient celle qui gagne, en imprimant le décompte.
- **Colonnes de mesure attendues** : `T_TL` (total), `F_TL` (femmes), `M_TL`
  (hommes), puis la ventilation par tranche quinquennale `T_00_04`, `T_05_09`,
  … `T_80Plus`, et leurs équivalents `F_*` et `M_*`.
- **Poids de sondage** : aucun. Ce ne sont pas des données d'enquête, mais des
  **projections démographiques** ventilées administrativement.
- **Consommé par** : modules 1 (jointure et choroplèthe), 2 (ratio F/H, part des
  0-14 ans, pyramides), 5 (référence officielle pour l'écart), 7 (troisième
  source de comparaison).

### 2. Les limites administratives

| Fichier | Taille |
|---|---|
| `gadm41_CMR.gpkg` | n.d. |

- **Source** : GADM 4.1, GeoPackage **multicouche**.
- **Couches attendues** : `ADM_ADM_0` (1 entité, le pays), `ADM_ADM_1`
  (10 régions), `ADM_ADM_2` (58 départements), `ADM_ADM_3` (arrondissements).
- **Unité d'observation** : le **polygone administratif**, à quatre niveaux.
- **Clé** : `NAME_1` au niveau ADM1, `NAME_2` au niveau ADM2 ; `GID_1` / `GID_2`
  encodent la hiérarchie.
- **CRS** : EPSG:4326 (degrés) — **aucune surface ne peut y être calculée**. Le
  module 6 reprojette en UTM 33N (EPSG:32633) et contrôle le total contre les
  475 442 km² officiels.
- **Géométries** : réparées à la lecture par `st_make_valid()`, avec
  `sf_use_s2(FALSE)` posé en tête de document.
- **Consommé par** : modules 1 (ADM1), 3 (ADM0 pour la découpe nationale),
  4 et 5 (ADM2, Mfoundi et cinq villes), 6 (ADM1 vs ADM2 pour le MAUP),
  7 (ADM0 et ADM1), exercice 5 (ADM3).

> Un seul exemplaire du `.gpkg` doit exister dans le magasin central : le même
> fichier sert au J08, au J09 et au J10.

### 3. Les trois grilles WorldPop

| Fichier | Taille |
|---|---|
| `cmr_pop_2015_CN_100m_R2025A_v1.tif` | n.d. |
| `cmr_pop_2025_CN_100m_R2025A_v1.tif` | n.d. |
| `cmr_pop_2030_CN_100m_R2025A_v1.tif` | n.d. |

- **Source** : WorldPop, University of Southampton — série **constrained**,
  version **R2025A**, résolution annoncée 100 m.
- **Unité d'observation** : **la cellule**. La valeur est le **nombre estimé
  d'habitants résidant dans la cellule** — grandeur **extensive**, qui
  s'additionne.
- **CRS attendu** : EPSG:4326, donc **résolution exprimée en degrés** (de
  l'ordre de 0,00083°, soit ~92,7 m à l'équateur). Le nom du fichier dit 100 m ;
  le fichier travaille en degrés. Une cellule n'a donc pas la même surface au
  sud et au nord du pays.
- **« constrained »** : aucune population n'est attribuée à une cellule où aucun
  bâti n'a été détecté. Les zones vides ne prouvent pas l'absence d'habitants,
  seulement l'absence de bâti **détecté**.
- **2030 est une projection**, pas une observation : les trois fichiers se
  ressemblent, ils n'ont pas le même statut.
- **Les trois appartiennent à la même version du modèle (`R2025A`)** — condition
  sans laquelle la comparaison temporelle mesurerait un changement de méthode et
  non de population. Le module 4 le vérifie par un `cat()`.
- **Consommé par** : modules 3 (2025), 4 (les trois, sur le Mfoundi et en
  cartes), 5 (2015 et 2025, extraction zonale et cinq villes), 6 (2025, densité
  et MAUP), 7 (2025, comparaison avec GHS-POP), 9 (les trois, sur la zone
  dessinée).

### 4. Les sept tuiles GHS-POP

| Fichier | Taille |
|---|---|
| `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R7_C20.zip` | n.d. |
| `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R8_C19.zip` | n.d. |
| `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R8_C21.zip` | n.d. |
| `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R9_C19.zip` | n.d. |
| `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R9_C20.zip` | n.d. |
| `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R9_C21.zip` | n.d. |
| `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R10_C20.zip` | n.d. |

- **Source** : Commission européenne, Joint Research Centre — GHS-POP R2023A,
  millésime 2025, résolution 100 m.
- **Unité d'observation** : **la cellule**, effectif estimé d'habitants.
- **CRS natif** : **ESRI:54009 (Mollweide)**, projection **équivalente** — donc
  résolution en **mètres**, contrairement à WorldPop. Le module 7 reprojette en
  EPSG:4326 pour comparer, et **mesure le coût de cette reprojection** sur les
  totaux.
- **Livrées en tuiles mondiales `R*_C*`** : elles doivent être assemblées
  (`sprc()` puis `mosaic()`). Les sept ensemble couvrent le Cameroun.
- **Livrées en `.zip`, à plat dans `datasets/`.** Le module 7 les décompresse
  **dans `outputs/ghsl_tuiles/`**, jamais dans `datasets/`.
- **Sentinelles** : des valeurs négatives marquent le nodata. Le module 7 les
  compte puis les recode en `NA` **avant** tout calcul.
- **Consommé par** : module 7 uniquement.

> **Point d'attention pour le script de distribution.** Ces sept fichiers sont
> chargés par `list.files("datasets", pattern = "^GHS_POP_E2025.*\\.zip$")`, et
> non par sept littéraux `"datasets/<nom>"`. Pour que la détection par
> expression régulière du script de copie fonctionne quand même, **les sept noms
> complets sont écrits en commentaire** dans le module 7 du `.qmd` et des trois
> scripts. Vérifier que le script de distribution les reprend bien.

---

## Ce qui NE DOIT PAS se trouver dans ce dossier

Règle : *une journée ne garde que ce qu'elle lit*. Les fichiers suivants étaient
présents ou référencés dans l'ancienne version du J08 et doivent en être
**retirés**, chacun pour une raison technique et non pour une question de poids.

| Fichier | Pourquoi il n'a rien à faire ici |
|---|---|
| `CMHR71FL.SAV` | fichier ménages de l'EDS, 72 Mo et plus de 4 000 colonnes, unité d'observation = le **ménage enquêté**. Aucun module de la journée ne travaille sur des données d'enquête pondérées. Appartient au **J05**. |
| `CMIR71FL.SAV` | fichier femmes de l'EDS, même raison. Appartient au **J05**. |
| `ecam5.dta` | enquête ménages ECAM5, 9 472 individus. Sa clé `hhid` est partiellement anonymisée et son extrait n'est pas représentatif à l'intérieur des régions : inexploitable pour un calage de grille, et hors sujet ici. Appartient au **J05**. |
| `CMGE71FL.shp` (+ annexes) | 430 grappes EDS géolocalisées. Deux obstacles rédhibitoires pour cette journée : elles portent un effectif **d'échantillon** et non de population, et leurs coordonnées sont **volontairement déplacées de 2 à 10 km** par le DHS. Les utiliser comme vérité terrain à 100 m entraînerait un modèle sur du bruit (module 8.4). Appartient au **J05**. |
| `CMGC72FL.csv` | 430 grappes × 130 covariables contextuelles, **sans aucune coordonnée** — donc non cartographiable seul, et indexé sur des grappes absentes d'ici. Appartient au **J05** et au **J10**. |
| `DS.geojson` | 200 districts sanitaires, 20 Mo, **135 géométries invalides sur 200**. Aucun module de la journée n'utilise la maille sanitaire ; le MAUP du module 6 se démontre avec ADM1/ADM2 déjà présents dans le `.gpkg`. Appartient au **J05** et au **J10**. |
| `FIES_Cameroun.csv` | indicateur d'insécurité alimentaire, sans lien avec la grille de population. N'était de toute façon **pas présent** dans le magasin central. |
| `CMR_population_v1_0_admin_level2.csv` · `CMR_household_…csv` | anciens CSV WorldPop par département, aux **séparateurs incohérents** (`;` pour l'un, `,` pour l'autre) et sans ventilation par âge. Remplacés par `cmr_admpop_adm1_2025.csv`, qui apporte la pyramide complète. |
| `gadm41_CMR_0/1/2.shp` (+ annexes) | quatre shapefiles séparés remplacés par le GeoPackage multicouche `gadm41_CMR.gpkg`, qui porte les quatre niveaux dans un seul fichier. Garder les deux ferait diverger les versions. |
| `gadm41_CMR_shp.zip` et `gadm41_CMR_shp/` | doublons décompressés du même contenu, jamais lus par aucun script. |
| Tuiles Sentinel-2 (`…B08…`, `…B11…`, `…True_color…`) | la tuile ne couvre que l'Est et le Sud du pays, elle est en WGS84 à ~150 m et non en UTM à 10 m, et **B03 et B04 sont absentes** — le NDVI n'est pas calculable. Aucun exercice de cette journée ne peut être construit dessus. Appartient au **J09**, à réécrire. |
| `GHS_POP_E1990…CMR.tif` · `GHS_POP_E2020…CMR.tif` | déclarés absents du magasin central, et remplacés par les **sept tuiles E2025** effectivement présentes. |
| `ghsl_pop_2025_cmr_100m.tif` | c'est une **sortie** du module 7, pas une source. Elle est désormais écrite dans `outputs/J08_ghsl_pop_2025_cmr_100m.tif`. Une sortie n'écrit jamais dans `datasets/`. |
| `DATA_ECOLE.zip` | contenu inconnu, référencé par aucun script du matériel source. À ouvrir côté utilisateur avant toute décision. |
| `GHS_POP_GLOBE_R2023A_input_metadata.xlsx` · `GHSL_Data_Package_2023_light.pdf` | documentation, jamais lue par le code. À ranger hors du dossier-jour si on souhaite la conserver. |
| Les `.tif` GHS-POP déjà décompressés | le module 7 **enseigne la décompression** ; livrer les `.tif` à côté des `.zip` doublerait le poids et priverait l'exercice de son objet. Les `.tif` sont produits dans `outputs/ghsl_tuiles/`. |

---

## Les pièges de la journée, du côté des données

1. **Deux colonnes de nom de région, une seule bonne.** `ADM1_EN` et `ADM1_FR`
   coexistent dans le CSV ; GADM n'a que `NAME_1`. Une jointure sur la mauvaise
   ne lève **aucune erreur** — elle remplit de `NA`. Le module 1 compte les
   appariements des deux candidates et affiche le décompte avant de choisir.
   Le contre-exemple est joué exprès, et la carte fautive est produite.
2. **La résolution annoncée n'est pas celle du fichier.** « 100 m » dans le nom,
   degrés dans le fichier. Toute densité calculée en supposant 0,01 km² par
   cellule est fausse, et l'erreur grandit vers le nord.
3. **Deux CRS pour deux produits.** WorldPop en degrés (EPSG:4326), GHS-POP en
   mètres (Mollweide, ESRI:54009). Les comparer exige de reprojeter, et
   reprojeter un raster d'effectifs **ne conserve pas la somme**. Le module 7
   mesure l'écart au lieu de le taire.
4. **Sentinelles négatives dans GHS-POP.** Elles traversent `sum()` sans un mot.
   Comptées puis recodées en `NA` avant tout calcul.
5. **Trois totaux nationaux différents pour la même année.** WorldPop, GHS-POP et
   le COD-PS ne s'accordent pas. Aucun des trois n'est un dénombrement : les deux
   premiers sont des redistributions modélisées, le troisième une projection à
   partir d'un recensement antérieur. Les écarts sont calculés, affichés et
   cartographiés (modules 5 et 7) — **ils doivent voyager avec tout chiffre
   cité**.
6. **Une grille ne connaît ni l'âge ni le sexe.** Seul le CSV les porte. Estimer
   une population scolarisable dans une zone dessinée suppose d'appliquer la
   structure par âge de la région englobante : c'est une **erreur écologique
   assumée**, à écrire à côté du chiffre.
7. **Les cellules de bordure.** `global()` sur un raster masqué les compte
   entièrement ; `exact_extract()` les compte au prorata de la fraction de
   surface. Négligeable sur une région, décisif sur une petite zone ou une forme
   allongée (exercice 4, et journée J09).

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
