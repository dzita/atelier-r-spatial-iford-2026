# Données du jour — dossier `datasets/`

Ce dossier reçoit **les fichiers de données de ce jour uniquement**, à plat.
Le matériel du jour les lit en chemin relatif : `datasets/<fichier>`.

## Comment le remplir

Depuis la racine du projet (ouvrir `atelier-r-spatial-iford-2026.Rproj`) :

```r
source("outils/distribuer_donnees.R")   # copie ici les fichiers voulus
```

(Le magasin central `pedagogie/datasets/cameroun/` doit avoir été rempli au
préalable via son `00_telecharger_donnees_drive.R`.)

## Fichiers de ce jour

Inventaire vérifié : chaque fichier présent est réellement lu par le matériel
de la journée, et chaque fichier lu est présent. **Total : ≈ 100 Mo**, dont
72 Mo pour le seul recode ménage de l'EDS.

### Microdonnées d'enquête

| Fichier | Poids | Unité | Sections |
|---|---:|---|---|
| `ecam5.dta` | 0,8 Mo | l'**individu** (9 472 lignes, 2 065 ménages, 70 variables) | 1.2 → 5.3 |
| `CMHR71FL.SAV` | 72 Mo | le **ménage** EDS-MICS 2018 (recode ménage) | 1.2, 4.2, 5.x |
| `CMGC72FL.csv` | 0,8 Mo | la **grappe** — 130 covariables contextuelles, **sans coordonnées** | 1.2, 5.1 |
| `CMGE71FL.shp` | 1,4 Mo | la **grappe** — 430 positions GPS (la géométrie) | 1.2, 2.3 → 5.3 |

Les deux derniers vont par paire : le `.shp` porte la position, le `.csv` les
attributs, et la clé qui les relie est `DHSCLUST`.

**`CMHR71FL.SAV` n'est jamais lu en entier.** Le fichier compte plus de
4 000 colonnes ; le matériel n'en demande que neuf, via `col_select`. La
lecture prend alors quelques secondes au lieu d'une minute.

### Découpages territoriaux

| Fichier | Poids | Contenu | Sections |
|---|---:|---|---|
| `gadm41_CMR_1.shp` | 0,6 Mo | 10 **régions** administratives | 2.1 → 5.3 |
| `gadm41_CMR_2.shp` | 1,3 Mo | 58 **départements** | 2.1, 2.2, 3.3 |
| `DS.geojson` | 20 Mo | 200 **districts sanitaires** (export DHIS2) | 2.1, 4.x, 5.3 |
| `Pays_limitrophes_Cmr.shp` | 0,1 Mo | contours des pays voisins (habillage) | 2.2 → 5.3 |

Chaque `.shp` s'accompagne obligatoirement de ses fichiers annexes
(`.shx`, `.dbf`, `.prj`, `.cpg`) — `distribuer_donnees.R` les copie ensemble.
Sans eux, `st_read()` échoue ou perd les attributs.

### Population modélisée

| Fichier | Poids | Contenu | Sections |
|---|---:|---|---|
| `CMR_population_v1_0_admin_level2.csv` | 3 Ko | population WorldPop par département — **séparateur `;`** | 1.2, 2.2 |
| `CMR_household_v1_0_admin_level2.csv` | 3 Ko | ménages par département — **séparateur `,`** | 1.2, 2.2 |

### Ce qui ne doit PAS être ici

- **Les images Sentinel-2** (B08, B11, True color — 90 Mo). La tuile
  disponible ne couvre qu'une fraction du territoire : une extraction zonale
  par district sanitaire renverrait `NA` pour la quasi-totalité des 200
  districts. Le contexte environnemental de la journée passe donc par les
  covariables déjà extraites de `CMGC72FL.csv`. Le travail direct sur raster
  est celui du **J04** et du **J09**.
- **`CMIR71FL.SAV`** (recode femmes, 83 Mo) — aucune section du J05 ne le lit.
- **`FIES_Cameroun.csv`** — absent du magasin central, et remplacé ici par la
  variable de satisfaction alimentaire d'ECAM5 (`s09q13a`).

## Les cinq pièges de cette journée

**1. `hhid` n'est pas une clé de ménage.** L'identifiant a été anonymisé pour
1 769 des 9 472 lignes, réduites à sept codes `10***` … `70***`.
`n_distinct(hhid)` renvoie 1 613 au lieu de 2 065. Le repère fiable est
`s01q3 == 1` (le chef de ménage), ou une clé composée des variables
constantes au sein du ménage. Section 1.3.

**2. Douze régions d'enquête, dix régions administratives.** ECAM5 comme
l'EDS isolent Douala et Yaoundé. La carte, non. Aucune normalisation de
chaîne ne comble cet écart : il faut une table de correspondance écrite à la
main. Section 2.2.

**3. Trois orthographes de la même région.** `extrême-nord` (ECAM5),
`EXTREME-NORD` (EDS), `Extrême-Nord` (GADM). Toutes les jointures du document
passent par une clé normalisée — accents translittérés, casse et ponctuation
retirées.

**4. Les noms de variables des `.SAV` DHS sont en MAJUSCULES.** `HV001`, pas
`hv001`. Un `col_select = c(hv001, …)` échoue. Le matériel lit l'en-tête,
apparie sans tenir compte de la casse, puis relit.

**5. Sentinelles négatives dans `CMGC72FL.csv`.** L'absence de mesure est
codée `-9999`, pas `NA` : invisible pour `is.na()`, dévastatrice dans un
`mean()`. Concerne `Aridity_2015` (6 grappes), `Annual_Precipitation_2015`
(6), `Malaria_Prevalence_2015` (4) et surtout `Drought_Episodes` (125 sur
430 — inexploitable en l'état). Section 5.1.

## Un avertissement sur les chiffres

`ecam5.dta` est un **extrait de formation**. Le taux de pauvreté national
qu'on en tire (38,6 %) est cohérent avec le chiffre publié par l'INS (37,7 %),
mais **certains taux régionaux s'en écartent fortement** — l'Est en
particulier. Aucun chiffre régional produit par ce matériel ne doit être cité
comme statistique officielle. Le document intègre cette confrontation à la
référence publiée comme un exercice à part entière (section 1.4).

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
