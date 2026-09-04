# Points de contrôle au rendu — J09 (télédétection, bâti, inondations)

> Procédure de recette de la journée J09, à dérouler sur le poste de salle avant
> la séance : préparation des données, contrôles par exécution, hypothèses à
> confirmer.
>
> Le matériel est écrit défensivement : les colonnes sont testées avant usage,
> les lectures protégées par `file.exists()`, `error: true` est actif dans le YAML.
> Un fichier absent ou une colonne manquante produira un message explicite plutôt
> qu'un plantage. Cela ne dispense pas des vérifications ci-dessous.

---

## 1. Bloquant — à faire avant toute chose

### 1.1 `floodDepthA` pour l'AOI01 : le fichier existe-t-il ?

**C'est le point le plus important de cette liste.**

Dans le matériel source (`materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\
data\EMSR772_products\`), un inventaire par nom de fichier montre que :

- `EMSR772_AOI01_DEL_PRODUCT_v2.zip` est présent mais **non décompressé** ;
- les AOI02 et AOI03 sont décompressées, **à plat**, dans `EMSR772_products\` ;
- le fichier `EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.shp` — **lu à la ligne 90
  du script formateur d'origine** `jour_08_formateur_inondations.R` — **n'existe
  nulle part sur disque**.

Autrement dit : le module central de la journée, le cas réel de Yagoua, dépendait
d'un fichier absent. Le script d'origine n'aurait pas démarré.

**À faire :**

1. décompresser `EMSR772_AOI01_DEL_PRODUCT_v2.zip` ;
2. vérifier qu'il en sort bien un `floodDepthA`, quel que soit son suffixe de
   version (`_v1`, `_v2`…) ;
3. le renommer, avec ses annexes, en `EMSR772_AOI01_floodDepthA.shp` / `.shx` /
   `.dbf` / `.prj` ;
4. faire de même pour `areaOfInterestA` → `EMSR772_AOI01_areaOfInterestA.*`.

**Si `floodDepthA` n'est pas dans l'archive AOI01 :** le télécharger depuis
<https://mapping.emergency.copernicus.eu/activations/EMSR772> (accès libre, sans
compte). Sans lui, les modules 5 à 8 ne peuvent pas tourner, et il faut basculer la
séance sur AOI02 ou AOI03 — au prix de perdre la fenêtre de 5 × 5 km et la couche
Open Buildings, qui ne couvre que Yagoua (voir §2.2).

### 1.2 Renommage à plat des shapefiles EMSR772

Les six shapefiles doivent être copiés dans `datasets/` sous ces noms exacts, **avec
leurs trois annexes chacun** :

| Source (matériel d'origine) | Nom cible dans `datasets/` |
|---|---|
| `EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.*` | `EMSR772_AOI01_areaOfInterestA.*` |
| `EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.*` (à extraire) | `EMSR772_AOI01_floodDepthA.*` |
| `EMSR772_AOI02_DEL_PRODUCT_areaOfInterestA_v1.*` | `EMSR772_AOI02_areaOfInterestA.*` |
| `EMSR772_AOI02_DEL_PRODUCT_floodDepthA_v1.*` | `EMSR772_AOI02_floodDepthA.*` |
| `EMSR772_AOI03_DEL_PRODUCT_areaOfInterestA_v1.*` | `EMSR772_AOI03_areaOfInterestA.*` |
| `EMSR772_AOI03_DEL_PRODUCT_floodDepthA_v1.*` | `EMSR772_AOI03_floodDepthA.*` |

Extensions à recopier pour chacun : **`.shp`, `.shx`, `.dbf`, `.prj`**. Aucun `.cpg`
n'a été repéré dans le matériel source — si l'encodage des attributs pose problème
à la lecture (accents cassés), en créer un contenant `UTF-8`.

Ne **pas** recopier : `.sld`, `.lyr`, `.json`, `.xml` (styles et métadonnées, sans
usage en R), ni les couches `observedEventA`, `imageFootprintA`, `source`, ni les
`summaryTable_*.xlsx`, ni le dossier `Maps\`, ni les `floodDepthA_*.tif`.

---

## 2. Hypothèses sur les données, à confirmer par exécution

### 2.1 Contenu réel des archives GHS-BUILT

**À contrôler en ouvrant une archive.**

Le code suppose que chaque archive contient **un seul `.tif`**, trouvé par
`list.files(tmp_dir, pattern = "\\.tif$", recursive = TRUE)[1]`. Si une archive en
contient plusieurs (par exemple un `.tif` de données et un `.tif` de masque), c'est
le premier par ordre alphabétique qui sera pris — potentiellement le mauvais.

**À vérifier** : ouvrir une archive, confirmer qu'elle contient bien un `.tif`
unique, et relever son nom. Si plusieurs `.tif` cohabitent, resserrer le motif dans
`charger_ghsl()`.

**À vérifier également** : que les valeurs sont bien en **m² de bâti par cellule**
(0 à 10 000) et non en pourcentage (0 à 100). Le contrôle est immédiat :
`terra::minmax()` sur la mosaïque. Si le maximum vaut 100, toute la chaîne de
conversion en km² (`/ 1e6`) est fausse d'un facteur 100.

### 2.2 Asymétrie de couverture des tuiles — **confirmée par inventaire**

L'inventaire par nom de fichier donne :

- **2015** : `R7_C20`, `R8_C19`, `R8_C20`, `R8_C21`, `R9_C19`, `R9_C20`, `R9_C21`
  → **7 tuiles**
- **2025** : `R7_C19`, `R7_C20`, `R8_C19`, `R8_C20`, `R8_C21`, `R9_C19`, `R9_C20`,
  `R9_C21` → **8 tuiles**

**`GHS_BUILT_S_E2015_..._R7_C19.zip` est absente.** La cartographie préparatoire
annonçait 16 archives ; il y en a **15**.

Conséquence si on ne la traite pas : le bâti 2015 vaut `NA` sur l'emprise de cette
tuile, le « gain » y devient la totalité du bâti 2025, et la région concernée
ressort en tête de toutes les cartes de croissance. Aucune erreur n'est levée.

**Traitement déjà en place dans le `.qmd`** : la section 3.4 compare les codes de
tuiles des deux millésimes et affiche une alerte ; la section 3.5
(`aligner_millesimes()`) restreint les deux rasters à leur intersection valide.

**À faire quand même** : télécharger `GHS_BUILT_S_E2015_GLOBE_R2023A_54009_100_V1_0_R7_C19.zip`
depuis <https://human-settlement.emergency.copernicus.eu/download.php> et le
déposer dans `datasets/`. Le contrôle passera alors de lui-même, sans modifier une
ligne de code, et la journée gagnera la couverture du nord-ouest de l'emprise.

### 2.3 Champs de `open_buildings_yagoua.gpkg`

**À contrôler à l'ouverture de la couche.**

Le matériel suppose les colonnes `latitude`, `longitude`, `area_in_meters`,
`confidence`, et une géométrie **polygonale** (empreintes). Chacune est testée avant
usage dans le `.qmd`, mais trois cas doivent être tranchés côté poste :

- **`confidence` absente** → tout le module 6.2 (distribution, seuil, sensibilité)
  tombe, et le module 7 perd sa comparaison. C'est la colonne la plus critique.
- **`latitude` / `longitude` absentes** → le `.qmd` bascule sur `st_centroid()`.
  Vérifier alors que les centroïdes tombent bien dans la fenêtre : le contrôle est
  déjà écrit (comptage des points intersectant `aoi01`, alerte sous 90 %).
- **Géométries ponctuelles au lieu de polygonales** → la troisième méthode du
  module 7 (part de surface bâtie inondée) n'est pas calculable. Le `.qmd` teste
  `st_geometry_type()` et affiche un message. Ce serait une perte réelle : c'est
  l'estimateur le plus robuste des trois.

Contrôle rapide : `sf::st_layers("datasets/open_buildings_yagoua.gpkg")` puis
`names(sf::st_read(..., query = "SELECT * FROM <couche> LIMIT 1"))`.

### 2.4 Emprise, CRS et résolution de `cmr_pop_2024_CN_100m_R2025A_v1.tif`

**À contrôler au premier rendu.**

Hypothèses du matériel : couverture nationale complète, EPSG:4326, résolution
d'environ 0,00083° (≈ 100 m à l'équateur). Le `.qmd` vérifie explicitement que la
fenêtre d'étude est **contenue** dans l'emprise du raster et lève une alerte sinon —
une extraction hors emprise ne renvoie pas d'erreur, elle renvoie `NA` ou `0`.

**À faire** : lancer le chunk `chunk-worldpop` et lire trois choses — le drapeau
`couvre` doit valoir `TRUE`, la population nationale sommée doit être de l'ordre de
**28 à 30 millions** (WorldPop 2024), et la résolution doit être en degrés.

Si le total national est absurde (quelques milliers, ou plusieurs milliards), c'est
que le raster n'est pas une grille d'effectifs mais une grille de densité, et toute
la comparaison du module 7 est à revoir.

### 2.5 Couches de `gadm41_CMR.gpkg`

**À contrôler au premier rendu.**

Le code lit `ADM_ADM_0`, `ADM_ADM_1` et `ADM_ADM_2`. Ces noms viennent du matériel
source du J08, qui les utilise aussi. Le `.qmd` affiche `sf::st_layers()` avant toute
lecture : si les noms diffèrent (`gadm41_CMR_0`, par exemple), la sortie du chunk
`chunk-lecture-gadm` le montrera immédiatement.

Effectifs attendus : **1** pays, **10** régions, **58** départements. Un autre chiffre
signale un fichier différent de celui documenté.

Contrôle croisé : le tableau des trois projections doit donner une superficie proche
de **475 442 km²** en Mollweide.

### 2.6 Les couches EMSR772 elles-mêmes

**À contrôler au premier rendu.** Le matériel suppose une colonne `value` (classe de profondeur) dans
`floodDepthA` et une colonne `locality` dans `areaOfInterestA`. Les deux sont testées
avant usage (`intersect()` sur les noms, `%in% names()`), mais si `value` porte un
autre nom (`obj_type`, `depth_class`…), toute la ventilation du module 6.3 et la
palette de la carte du module 5 sont à réécrire.

Contrôle : la sortie du chunk `chunk-lecture-emsr` affiche la liste complète des
colonnes.

---

## 3. Budget de poids — arbitrage à faire

Toutes les tailles du `LISEZMOI.md` sont notées « n.d. » tant qu'elles n'ont pas été
relevées sur le magasin central. C'est la première mesure à faire côté poste : sans
elle, l'arbitrage ci-dessous ne peut pas être tranché.

### Le problème

Le budget de l'atelier est de **100 Mo par journée, extensible**, avec pour consigne
de ne pas sacrifier la richesse démonstrative au poids. Mais cette journée demande
**15 archives GHS-BUILT**, chacune couvrant une tuile de la grille mondiale GHSL —
soit une emprise de **100 × 100 km au minimum**, très largement au-delà du Cameroun.
Le J08, traité en parallèle, demande en plus **7 tuiles GHS-POP**. Les deux journées
cohabitent dans le même magasin central.

### La solution technique à envisager

Livrer, à la place des 15 archives, **un seul `.tif` par millésime, déjà découpé sur
le Cameroun** :

```
GHS_BUILT_S_E2015_CMR_100m.tif
GHS_BUILT_S_E2025_CMR_100m.tif
```

**La raison est technique, pas budgétaire.** Chaque tuile GHSL couvre une emprise
mondiale standardisée dont l'immense majorité tombe hors du Cameroun. Après
`preparer_raster()`, ces cellules sont mises à `NA` et ne servent plus à rien : elles
sont chargées, décompressées dans un répertoire temporaire, mosaïquées, puis jetées.
Le coût est payé **à chaque exécution, sur chaque poste**, pour un résultat identique.
Une découpe nationale préalable supprime ce coût une fois pour toutes.

### Ce que cela coûterait, et pourquoi ce n'est pas gratuit

- **Le module 3 perdrait la mosaïque.** Or `mosaic()` sur une liste de tuiles est un
  geste que les participants doivent avoir vu au moins une fois : c'est ainsi que se
  consomme n'importe quel produit global.
- **Le contrôle de symétrie des tuiles disparaîtrait** — c'est-à-dire le meilleur
  piège du module (§2.2).

**Recommandation** : garder les 15 archives **si le budget le permet une fois les
tailles relevées**. Sinon, livrer les deux `.tif` découpés **et** conserver la
séquence de mosaïque en bloc `eval: false`, avec la raison technique écrite dans le
document. Dans ce second cas, il faut aussi remplacer le contrôle de symétrie par
une note expliquant ce qu'il détectait — ne pas le supprimer en silence.

**À décider avant de figer le manifeste de distribution.**

### Détection par l'outil de distribution

⚠️ Les tuiles GHS-BUILT sont chargées par
`list.files("datasets", pattern = "^GHS_BUILT_S_E<annee>.*\\.zip$")`, **et non par
un littéral `"datasets/<nom>"`**. L'outil `distribuer_donnees.R`, qui travaille par
expression régulière sur les littéraux, **ne peut pas les détecter**. Elles doivent
être copiées à la main ou ajoutées explicitement au manifeste. Même remarque pour le
J08 et ses tuiles GHS-POP.

---

## 4. Contrôles effectués sur le matériel produit

### 4.1 Équilibre des chunks du `.qmd` — **vérifié**

Une ouverture de chunk manquante transforme tout le code suivant en markdown et
fabrique des dizaines de faux titres. L'erreur s'est déjà produite sur ce projet
(J04, 30 faux titres). Comptage par expression régulière sur
`demo_formateur_J09.qmd` :

| Motif | Occurrences |
|---|---|
| Ouvertures — lignes commençant par ```` ```{r ```` | **58** |
| Fermetures — lignes valant exactement ```` ``` ```` | **58** |

**Équilibre confirmé.** Aucune autre clôture de bloc de code n'existe dans le
document (aucun bloc ```` ```r ```` ni ```` ```bash ```` en prose), donc les 58
fermetures correspondent bien aux 58 ouvertures.

**À refaire après toute réécriture longue.**

### 4.2 Motifs interdits — **vérifié sur le `.qmd`**

| Motif recherché | Résultat |
|---|---|
| `setwd(` | aucune occurrence de code (une seule mention, en prose, pour l'interdire) |
| `here(` | aucune |
| `file.path(data_dir` | aucune |
| chemin absolu `C:\` | aucune |
| `install.packages(` hors `eval: false` | aucune — la seule occurrence est dans le chunk `chunk-ref-install`, marqué `eval: false` |
| `"datasets/` suivi d'un sous-dossier | aucune — les 10 littéraux pointent tous vers un fichier à plat |

**Exception assumée, à connaître.** Les trois scripts `.R` de `scripts/` contiennent
**un `setwd()` chacun**, dans le bloc d'en-tête qui replace le script dans le dossier
de la journée. C'est le format validé sur J01 à J05 (voir `script_formateur_J04.R`,
ligne 25) et il est requis par le §6.2 des règles : Quarto se place automatiquement
dans le dossier du `.qmd`, `Rscript` non. Ce `setwd()` est **conditionnel et
relatif** — il ne s'exécute que si `datasets/` n'est pas déjà visible, et il ne
contient aucun chemin absolu. Il n'y en a aucun dans le `.qmd`, qui est la source.

### 4.3 Littéraux `"datasets/…"` du `.qmd` — les 10 fichiers à distribuer

```
datasets/gadm41_CMR.gpkg
datasets/cmr_pop_2024_CN_100m_R2025A_v1.tif
datasets/open_buildings_yagoua.gpkg
datasets/routes_aoi01_yagoua.gpkg
datasets/EMSR772_AOI01_areaOfInterestA.shp
datasets/EMSR772_AOI01_floodDepthA.shp
datasets/EMSR772_AOI02_areaOfInterestA.shp
datasets/EMSR772_AOI02_floodDepthA.shp
datasets/EMSR772_AOI03_areaOfInterestA.shp
datasets/EMSR772_AOI03_floodDepthA.shp
```

Plus, **hors détection automatique**, les **15 archives GHS-BUILT**.

Les blocs de référence `eval: false` des modules 1 et 2 utilisent délibérément
`file.path("datasets", "...")` plutôt qu'un littéral, pour que l'outil de
distribution ne cherche pas à copier des fichiers d'illustration inexistants.

### 4.4 Ce qui demande une exécution réelle

- **La syntaxe R des chunks** : passer `parse()` sur les trois scripts.
- **Le rendu du `.qmd`** : comparer le nombre de callouts et de tableaux du HTML à
  ce qui est écrit dans la source.
- **L'affichage** : table des matières, images, entrées parasites — à regarder dans
  un navigateur.
- **L'exécution des trois scripts `.R`**.
- **L'API tmap 4** : les appels `tm_raster(col.scale = tm_scale_intervals(...))` et
  `tm_scale_categorical()` suivent la documentation de tmap 4. C'est le point le plus
  fragile du matériel après les données elles-mêmes, parce qu'un changement d'API s'y
  traduit par une erreur au rendu et non par un avertissement. Repli si l'API a
  changé : remplacer la carte du module 7 par un `ggplot` +
  `tidyterra::geom_spatraster()`, ou par `terra::plot()`.

---

## 5. Commandes Windows — retirer l'ancien matériel `*_J9.*`

À exécuter depuis `pedagogie\J09_teledetection\`, dans une invite de commandes
(`cmd.exe`), **après avoir vérifié que le nouveau matériel rend correctement** et
**après un commit Git de sauvegarde**.

### 5.1 Sauvegarde préalable

```
git checkout -b reecriture-J09
git add -A
git commit -m "J09 : sauvegarde avant retrait de l'ancien materiel"
```

### 5.2 Archiver les scripts anglais du matériel source

```
mkdir archive_en
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\Correction_Workshop_\jour_08_formateur_teledetection_en.R" archive_en\
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\Correction_Workshop_\jour_08_formateur_inondations_en.R" archive_en\
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\Correction_Workshop_\jour_08_formateur_prepare_open_buildings_en.R" archive_en\
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\Correction_Workshop_\jour_08_formateur_prepare_osm_routes_en.R" archive_en\
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\scripts_etudiants\jour_08_etudiants_teledetection_en.R" archive_en\
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\scripts_etudiants\jour_08_etudiants_inondations_en.R" archive_en\
```

Adapter les chemins relatifs si l'arborescence des dépôts diffère. Ajouter ensuite
un `archive_en\LISEZMOI.md` d'une ligne : *« scripts sources en anglais, archivés,
non maintenus, non alignés sur le `.qmd` — ne pas distribuer en salle »*.

### 5.3 Copier les trois présentations

```
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\jour_08_teledetection.pptx" .
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\jour_08_teledetection_en.pptx" .
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_9\jour_08_teledetection_fr_en.pptx" .
```

**Ne pas copier** `~$jour_08_teledetection_fr_en.pptx` : c'est un fichier verrou
PowerPoint, pas un document.

### 5.4 Retirer l'ancien matériel remplacé

```
del demo_formateur_J9.qmd
del script_formateur_J9.R
del script_etudiant_J9.R
del script_etudiant_J9_corrige.R
```

`slides.qmd` : **à examiner avant de supprimer.** Il date de l'ancienne version de la
journée. S'il contient de la matière non reprise dans les `.pptx`, le conserver ;
sinon le retirer, les trois présentations le remplaçant.

```
rem     del slides.qmd     <-- seulement apres examen
```

### 5.5 Vérifier qu'aucun `J9` nu ne subsiste

```
findstr /S /I /C:"J9" *.qmd *.R *.md
```

La sortie doit être **vide**. Tout ce qui reste doit être en `J09`, sur deux
chiffres. Attention : la commande remontera aussi les `J09`, puisque `J9` n'en est
pas un sous-motif — vérifier visuellement chaque ligne retournée.

### 5.6 Créer l'arborescence si elle n'existe pas

```
mkdir scripts
mkdir scripts\preparation
mkdir outputs
```

---

## 6. Ordre de vérification recommandé avant la séance

1. **§1.1 et §1.2** — extraire et renommer les shapefiles EMSR772. Sans cela, rien
   d'autre ne sert.
2. Remplir `datasets/` (outil de distribution + **copie manuelle des 15 archives
   GHS-BUILT**).
3. `source("install_packages_day.R")` — vérifier que tmap ≥ 4 et terra ≥ 1.7.
4. **Rendre le `.qmd`.** Lire, dans l'ordre, les sorties `cat()` des chunks
   `chunk-inventaire`, `chunk-controle-tuiles`, `chunk-controle-surface`,
   `chunk-lecture-ob`, `chunk-worldpop`. Ces cinq compteurs valident les cinq
   hypothèses de données de la journée.
5. Comparer le nombre de callouts et de tableaux du HTML à ce qui a été écrit (§4.4).
6. Exécuter `scripts/script_etudiant_J09_corrige.R` : c'est lui qu'on teste, pas la
   trame — les erreurs d'exécution de `script_etudiant_J09.R` sont attendues.
7. **§5** — retirer l'ancien matériel `*_J9.*` seulement une fois les points 1 à 6
   validés.
