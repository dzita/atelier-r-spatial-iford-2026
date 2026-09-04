# Données du jour — dossier `datasets/` (J09)

Ce dossier reçoit **les fichiers de données de cette journée uniquement**, **à plat**.
Les scripts du jour les lisent en chemin relatif : `datasets/<fichier>`.

Pas de sous-dossier `GHS-BUILT/`, pas de `EMSR772_products/`, pas de dossier
`Open Buildings` (avec un espace dans son nom, qui casse les chemins). L'outil de
distribution repère les littéraux à la **racine** du dossier du jour, sans
récursion : un fichier rangé dans un sous-dossier n'est jamais trouvé.

> **Tailles : n.d.** Elles restent à mesurer côté poste, en particulier pour
> arbitrer contre le budget de 100 Mo par journée. Voir `_A_FAIRE_J09.md`.

## Comment le remplir

Depuis la racine du projet (ouvrir `atelier-r-spatial-iford-2026.Rproj`) :

```r
source("outils/distribuer_donnees.R")
```

⚠️ **Les tuiles GHS-BUILT ne sont pas détectées automatiquement.** Elles sont
chargées par `list.files("datasets", pattern = "^GHS_BUILT_S_E<annee>.*\\.zip$")`,
et non par un littéral `"datasets/<nom>"`. L'outil de distribution, qui travaille
par expression régulière sur les littéraux, ne peut donc pas les voir. Elles
doivent être copiées à la main, ou ajoutées explicitement au manifeste de l'outil.

---

## Inventaire

### Limites administratives

| Fichier | Unité d'observation | Taille | Sections consommatrices |
|---|---|---|---|
| `gadm41_CMR.gpkg` | multicouche : `ADM_ADM_0` = 1 pays, `ADM_ADM_1` = 10 régions, `ADM_ADM_2` = 58 départements, `ADM_ADM_3` = arrondissements | n.d. | modules 3, 4 |

Clés : `GID_1` / `NAME_1` au niveau régional, `GID_2` / `NAME_2` au niveau
départemental. `GID_2` encode la hiérarchie (`CMR.7.3_1` = région 7, département 3).
Les noms `NAME_*` sont en **anglais** dans GADM — ne jamais joindre sur eux avec une
source française sans table de correspondance.

Le fichier est **mutualisé** avec le J08 et le J10 : un seul exemplaire au magasin
central, recopié dans chaque dossier-jour.

### Bâti — GHS-BUILT

| Fichier | Unité d'observation | Taille | Sections |
|---|---|---|---|
| `GHS_BUILT_S_E2015_GLOBE_R2023A_54009_100_V1_0_R7_C20.zip` | cellule de 100 m ; valeur = m² de bâti dans la cellule (0 à 10 000) | n.d. | modules 3, 4 |
| `…_E2015_…_R8_C19.zip` · `_R8_C20.zip` · `_R8_C21.zip` | idem | n.d. | idem |
| `…_E2015_…_R9_C19.zip` · `_R9_C20.zip` · `_R9_C21.zip` | idem | n.d. | idem |
| `GHS_BUILT_S_E2025_GLOBE_R2023A_54009_100_V1_0_R7_C19.zip` | idem | n.d. | idem |
| `…_E2025_…_R7_C20.zip` | idem | n.d. | idem |
| `…_E2025_…_R8_C19.zip` · `_R8_C20.zip` · `_R8_C21.zip` | idem | n.d. | idem |
| `…_E2025_…_R9_C19.zip` · `_R9_C20.zip` · `_R9_C21.zip` | idem | n.d. | idem |

**Total attendu : 15 archives — 7 pour 2015, 8 pour 2025.**

Projection : grille mondiale GHSL, **Mollweide (ESRI:54009)** — projection
*équivalente*, les surfaces y sont justes. Résolution 100 m.

> **Piège chiffré, le plus important du module 3.** Le lot livré est
> **asymétrique** : la tuile `R7_C19` existe pour 2025 et **manque pour 2015**. Là
> où elle manque, le raster 2015 vaut `NA` ; `exact_extract(..., "sum")` traite les
> `NA` comme absents, donc renvoie un bâti 2015 sous-estimé — voire nul. Le « gain
> 2015 → 2025 » y devient égal à **la totalité** du bâti 2025, et la croissance
> relative explose. Aucune erreur n'est levée.
>
> Le `.qmd` détecte l'asymétrie (`setdiff` sur les codes de tuiles), l'affiche, et
> restreint les deux millésimes à l'intersection de leurs emprises valides. Si la
> tuile manquante est récupérée sur le portail GHSL, le contrôle passera de lui-même
> et le module gagnera en couverture.

### Population de référence

| Fichier | Unité d'observation | Taille | Sections |
|---|---|---|---|
| `cmr_pop_2024_CN_100m_R2025A_v1.tif` | cellule de 100 m ; valeur = nombre d'habitants estimé dans la cellule | n.d. | module 7 |

WorldPop *constrained*, millésime 2024, version R2025A. C'est un **modèle**, pas un
recensement : les effectifs par cellule sont produits en désagrégeant un total
administratif à l'aide de covariables — dont **le bâti détecté par télédétection**.

> **Piège chiffré.** Comme WorldPop utilise le bâti comme covariable, les deux
> méthodes comparées au module 7 (bâtiments × 5 et WorldPop) **ne sont pas
> totalement indépendantes**. Leur accord sur la fenêtre entière est un peu moins
> probant qu'il n'y paraît. Il faut le dire en salle.

### Copernicus EMS — activation EMSR772 (Yagoua 2024)

Shapefiles **déjà extraits et renommés à plat**. Chacun voyage avec ses annexes
`.shx`, `.dbf`, `.prj` — un shapefile amputé de son `.shx` ne s'ouvre pas, et
amputé de son `.prj` s'ouvre **sans CRS**, ce qui ne lève aucune erreur.

| Fichier | Unité d'observation | Taille | Sections |
|---|---|---|---|
| `EMSR772_AOI01_areaOfInterestA.shp` (+ `.shx`, `.dbf`, `.prj`) | 1 polygone = le périmètre cartographié par EMS autour de Yagoua (~6 870 km²) | n.d. | modules 5 à 8 |
| `EMSR772_AOI01_floodDepthA.shp` (+ annexes) | 1 polygone = une zone d'une classe de profondeur estimée (colonne `value`, ex. `"0.50 - 1.00"` en mètres) | n.d. | modules 5 à 8 |
| `EMSR772_AOI02_areaOfInterestA.shp` (+ annexes) | 1 polygone = périmètre autour de Makari | n.d. | module 9 |
| `EMSR772_AOI02_floodDepthA.shp` (+ annexes) | idem, classes de profondeur | n.d. | module 9 |
| `EMSR772_AOI03_areaOfInterestA.shp` (+ annexes) | 1 polygone = périmètre autour de Waza | n.d. | module 9 |
| `EMSR772_AOI03_floodDepthA.shp` (+ annexes) | idem, classes de profondeur | n.d. | module 9 |

> **Dépendance à vérifier avant la séance.** Dans le matériel source, l'archive
> `EMSR772_AOI01_DEL_PRODUCT_v2.zip` **n'était pas décompressée**, et le fichier
> `EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.shp` — lu à la **ligne 90** du script
> formateur d'origine — **n'existait nulle part sur disque**. Les AOI02 et AOI03,
> elles, étaient déjà extraites (mais à plat, dans un dossier que le code ne
> cherchait pas). Le module central de la journée dépendait donc d'un fichier
> absent. **Point n° 1 de `_A_FAIRE_J09.md`.**

> **Piège chiffré.** La colonne `value` est lue comme du **texte**. L'ordre
> alphabétique de ses modalités coïncide ici avec l'ordre numérique par chance, pas
> par construction. Sur une autre activation, `"10.00 - 20.00"` se classerait avant
> `"2.00 - 5.00"`. Vérifier systématiquement.

### Bâtiments et infrastructures

| Fichier | Unité d'observation | Taille | Sections |
|---|---|---|---|
| `open_buildings_yagoua.gpkg` | 1 ligne = 1 empreinte de bâtiment détectée (polygone WKT), avec `latitude`, `longitude` du centroïde, `area_in_meters`, `confidence` | n.d. | modules 6, 7, 9 |
| `routes_aoi01_yagoua.gpkg` | 1 ligne = 1 segment de voie OpenStreetMap (`osm_lines`), avec l'étiquette `highway` | n.d. | module 8 |

Ces deux fichiers sont **produits**, pas téléchargés tels quels. Leur provenance est
tracée par `scripts/preparation/preparer_open_buildings_J09.R` et
`scripts/preparation/preparer_routes_osm_J09.R`, non exécutables en salle.

> **Piège chiffré, mis en scène au module 9.** `open_buildings_yagoua.gpkg` ne
> contient **que** les bâtiments situés dans l'AOI01 **plus 5 km de marge**. Or
> Yagoua (AOI01), Makari (AOI02) et Waza (AOI03) sont distants de jusqu'à ~300 km :
> **la couche ne couvre pas AOI02 ni AOI03**. Sans garde-fou, `nrow()` vaut 0, le
> pourcentage devient `NaN` et la population `0` — soit « aucun bâtiment touché »
> affiché pour deux zones réellement inondées en 2024. Le `.qmd` déclare une colonne
> `couverture_batiments` et un seuil minimal de 50 bâtiments pour que ce zéro ne
> puisse pas être lu comme une mesure.

> **Piège chiffré.** Le champ `confidence` d'Open Buildings n'est pas une qualité de
> mesure : c'est une probabilité estimée par le modèle. Le seuil de **0,7** retenu
> par la journée arbitre entre faux positifs (rochers, tas de terre, ombres) et faux
> négatifs (constructions légères, petites, sous couvert végétal). **Le second biais
> n'est pas aléatoire : il frappe systématiquement les habitations les plus
> vulnérables**, c'est-à-dire précisément celles dont on veut mesurer l'exposition.

> **Piège chiffré.** La couverture OpenStreetMap est très hétérogène et corrélée à
> l'histoire des réponses humanitaires (le HOT a beaucoup cartographié
> l'Extrême-Nord camerounais). Une densité de routes OSM peut donc comparer **deux
> intensités de cartographie** plutôt que deux réseaux réels. Une route absente
> d'OSM n'apparaîtra jamais comme coupée : **le non-cartographié est invisible, pas
> nul.**

---

## Ce qui NE doit PAS être dans ce dossier

Chaque suppression a une raison **technique**, pas un souci de poids.

| Fichier | Pourquoi il ne sert plus cette journée |
|---|---|
| les 4 tuiles **Sentinel-2** (`2026-06-26…B03/B04/B08/B11/True_color`) | La tuile ne couvre que 11,5–14,9° E et 2,5–5,8° N (Est et Sud), elle est en WGS84 à ~150 m au lieu d'UTM à 10 m, et **B03 et B04 sont absentes du magasin central** — or B04 est au dénominateur du NDVI et B03 au numérateur du MNDWI. Ces deux indices ne sont donc **pas calculables**. S'y ajoute que l'image « True color » est en 8 bits et ne porte aucune réflectance. Le règlement §3.7 de l'atelier interdit de bâtir un exercice là-dessus : les modules 1 et 2 sont livrés en exposé, avec du code de référence `eval: false`. |
| `DS.geojson` | 200 districts sanitaires. Aucune section de cette journée ne travaille sur la maille sanitaire — le module 4 descend à l'ADM2 de GADM, qui est la maille administrative. Appartient au **J05** et au **J10**. |
| `CMGC72FL.csv` | 430 grappes EDS × 130 covariables contextuelles, **sans aucune coordonnée**. Rien dans cette journée ne s'articule sur les grappes EDS. Appartient au **J05**. |
| `CMR_population_v1_0_admin_level2.csv` et son `.xlsx` | effectifs administratifs par département, séparateurs incohérents (`;` et `,`). La journée n'agrège aucun effectif administratif : sa population de référence est une **grille** (WorldPop 100 m), pas un tableau par département. Appartient au **J08**. |
| `Pays_limitrophes_Cmr.shp` | contours des pays voisins. La mosaïque GHS-BUILT est masquée sur `ADM_ADM_0` du Cameroun ; les pays limitrophes n'entrent dans aucun calcul et alourdiraient les cartes sans rien y ajouter. |
| `gadm41_CMR_0/1/2.shp` (shapefiles séparés) | remplacés par le `.gpkg` multicouche, qui porte les mêmes géométries en un seul fichier, sans annexes éparpillées ni troncature des noms de colonnes. |
| `CMHR71FL.SAV`, `CMIR71FL.SAV`, `ecam5.dta` | fichiers d'enquête. Aucune donnée d'enquête n'est lue ce jour. Appartiennent au **J05**. |
| `EMSR772_AOI0*_DEL_PRODUCT_*.zip` | les shapefiles sont livrés **déjà extraits**. Un `unzip()` en séance écrirait dans `datasets/`, qui est un dossier d'**entrées** ; et livrer à la fois l'archive et son contenu double le poids pour rien. |
| `EMSR772_*_observedEventA.*`, `*_imageFootprintA.*`, `*_source_*`, `*.sld`, `*.lyr`, `*.json`, `*.xml`, `*_summaryTable_*.xlsx`, `Maps/*.pdf` | aucune de ces couches ni de ces annexes de style n'est lue par le matériel de la journée. Les `.sld` et `.lyr` sont des feuilles de style pour QGIS et ArcGIS, sans effet en R. |
| `EMSR772_AOI0*_floodDepthA_v1.tif` | version raster des profondeurs. La journée travaille sur les **polygones** — c'est ce qui rend visible, au module 7, la divergence entre comptage de centroïdes et pondération par fraction de cellule. Livrer aussi le raster brouillerait la démonstration. |
| tuiles Open Buildings `*.csv.gz` | plusieurs Go, couverture bien plus large que Yagoua. Le `.gpkg` restreint les remplace ; leur provenance est tracée dans `scripts/preparation/`. |
| `GHS_POP_*` | grilles de **population** GHSL. Elles appartiennent au **J08**, qui compare WorldPop et GHS-POP. Cette journée n'utilise GHSL que pour le **bâti**. |

---

## Récapitulatif des pièges chiffrés de la journée

| # | Piège | Chiffre à retenir |
|---|---|---|
| 1 | Millésime inexistant | le code source cherchait `E2020` ; les données sont **2015 et 2025** |
| 2 | Asymétrie des tuiles | **8 tuiles en 2025, 7 en 2015** — `R7_C19` manque pour 2015 |
| 3 | Fenêtre d'étude | ~**5 × 5 km** retenus sur une AOI officielle de ~**6 870 km²**, soit moins de **0,4 %** |
| 4 | Hypothèse d'occupation | **× 5 habitants par bâtiment**, non calibrée ; le facteur s'annule dans tout pourcentage |
| 5 | Seuil de confiance | **0,7**, conventionnel ; sensibilité publiée de 0,5 à 0,9 |
| 6 | Seuil de bâti initial | **1 km²** en dessous duquel la croissance relative n'est pas calculée |
| 7 | Seuil de couverture | **50 bâtiments** en dessous desquels une zone est déclarée non interprétable |
| 8 | Zones non couvertes | **AOI02 et AOI03** : leurs zéros ne sont pas des mesures |
| 9 | Superficie de référence | **475 442 km²** — repère de validation du calcul de surface |

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
