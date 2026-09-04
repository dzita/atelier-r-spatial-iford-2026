# À restaurer — sources lourdes absentes du poste

> Liste **exacte** des fichiers que le code de J01 → J07 (et le module 10 du
> J10) réclame par un littéral `"datasets/<nom>"`, et qui sont **introuvables**
> — ni dans `pedagogie/all_data/` (le magasin central), ni dans un `datasets/`
> de journée, ni sous un nom approchant.
>
> Sources : le croisement références ↔ magasin, les fiches de données du
> référentiel (§7) et la cartographie du module 10 du J10. Les noms ci-dessous
> sont recopiés **tels qu'écrits dans les `.qmd`** : c'est le nom que
> `outils/distribuer_donnees.R` ira chercher par correspondance exacte de
> `basename()`. Une copie sous un nom approchant ne sera **pas** trouvée.
>
> Les poids sont indicatifs, repris des fiches de données : aucun n'a été
> mesuré sur les binaires eux-mêmes.
>
> **Parti pris** : ces données ne sont pas contournées. Elles se restaurent
> dans `pedagogie/all_data/`, puis `source("outils/distribuer_donnees.R")` les
> répartit vers les onze journées.

---

## 1. Où déposer les fichiers

**Tout dans `pedagogie/all_data/`, à plat.** Ne pas créer de sous-dossier :
`distribuer_donnees.R` indexe récursivement le magasin, mais les `LISEZMOI.md`
et le reste de l'outillage raisonnent sur un magasin plat.

Ne pas renommer, ne pas « nettoyer » les noms : les parenthèses de
`…B08_(Raw).tiff` et les tirets bas de l'horodatage font partie du nom attendu
par le code.

---

## 2. Les cinq blocs manquants

### 2.1 `CMHR71FL.SAV` — recode ménage, EDS-MICS Cameroun 2018

| | |
|---|---|
| **Nom exact attendu** | `CMHR71FL.SAV` (extension en MAJUSCULES) |
| **Poids indicatif** | ~72 Mo |
| **Journées qui le réclament** | J01, J03, J05, J06, J07 |
| **Nature** | SPSS, *Household Recode* du DHS : une ligne par ménage, > 4 000 colonnes, noms de variables en MAJUSCULES |

**Ce qui casse sans lui.**

- **J01** — les chunks 09-10 (première lecture d'un fichier d'enquête, `haven`,
  `col_select`, libellés `labelled`) n'ont plus d'objet : c'est le fichier sur
  lequel toute la journée « fondations » apprend à lire des données.
- **J03** — le volet « attacher un tableau d'enquête à une couche
  géographique » perd sa table d'attributs ménage.
- **J05** — journée entière compromise : c'est la source des variables
  `hv001` (grappe, clé de jointure vers `CMGE71FL.shp`), `hv005` (poids de
  sondage, sans lequel on décrit l'échantillon et non la population, §3.5),
  `hv024`/`hv025` (région, milieu), `hv201`/`hv205`/`hv206` (eau, sanitaires,
  électricité), `hv270` (quintile de richesse). Sans ces colonnes, ni
  l'agrégation pondérée par grappe, ni la confrontation à la référence INS
  (§3.8) ne peuvent tourner.
- **J06, J07** — mêmes variables, réutilisées pour la cartographie thématique
  et l'autocorrélation spatiale.

**Attention à la lecture** (§3.1) : ne jamais l'ouvrir en entier. Toujours
`col_select`, et faire correspondre les noms en majuscules avant de les
demander.

### 2.2 `CMIR71FL.SAV` — recode individuel (femmes), EDS-MICS Cameroun 2018

| | |
|---|---|
| **Nom exact attendu** | `CMIR71FL.SAV` |
| **Poids indicatif** | ~83 Mo |
| **Journées qui le réclament** | J01, J03, J04, J06, J07 |
| **Nature** | SPSS, *Individual Recode* du DHS : une ligne par femme de 15-49 ans interrogée |

**Ce qui casse sans lui.**

- **J01** — la démonstration « deux recodes, deux unités d'observation » (le
  ménage contre l'individu) n'a plus qu'un seul terme de comparaison.
- **J03, J06, J07** — les indicateurs individuels (fécondité, scolarisation,
  santé maternelle) rattachés aux grappes disparaissent.
- **J04** — c'est le seul tableau d'enquête de la journée raster : sans lui,
  l'exercice « croiser une valeur extraite d'un raster avec une caractéristique
  d'enquête » n'a plus de second membre.

**Aucun candidat de substitution n'existe sur le poste** — voir §4 sur
`CMFW71FL.SAV`, qui n'en est pas un.

### 2.3 `DS.geojson` — 200 districts sanitaires du Cameroun

| | |
|---|---|
| **Nom exact attendu** | `DS.geojson` |
| **Poids indicatif** | ~20 Mo |
| **Journées qui le réclament** | J03, J05, J06, J07 — **et le module 10 du nouveau J10** (accessibilité aux services, isochrones 5/10/15 km) |
| **Nature** | GeoJSON, 200 polygones. Champs `name` et `parentName` (préfixés) — **ni `NomDS` ni `CodeDS`**. **135 géométries invalides sur 200** : lecture obligatoire en `st_read() |> st_make_valid()`, avec `sf_use_s2(FALSE)` en tête de document (§3.6) |

**Ce qui casse sans lui.**

- **J03** — c'est la couche de démonstration de la journée « univers
  vectoriel » : validité des géométries, `st_make_valid()`, différence entre
  découpage administratif et découpage fonctionnel.
- **J05** — le fil rouge « 430 grappes pour 200 districts, donc la moitié des
  districts sans aucune observation » (§4.4) est **construit sur ce fichier**.
  La démonstration pédagogique la plus forte de la journée disparaît avec lui.
- **J06, J07** — maille alternative pour le MAUP et pour les statistiques
  spatiales.
- **J10 (nouveau, module 10)** — le seul module « conservé de l'ancien »
  reliant la journée aux politiques publiques concrètes (distances aux
  districts sanitaires) ne démarre pas. Le reste du J10 (ACLED, ERA5,
  Fay-Herriot Bénin) tourne sans lui : le manque est **circonscrit au
  module 10**, pas bloquant pour la journée entière.

### 2.4 Les trois tuiles Sentinel-2

| Nom exact attendu | Journées |
|---|---|
| `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B08_(Raw).tiff` | J02, J04, J05, J06, J07 |
| `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B11_(Raw).tiff` | J02, J04, J05, J06, J07 |
| `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_True_color.tiff` | J02, J04, J05, J06, J07 |

Poids indicatif : quelques dizaines de Mo chacune (~90 Mo pour le jeu, d'après
la note de suppression du J05).

**Le nom compte** : horodatage complet, parenthèses autour de `Raw`, extension
`.tiff` sur quatre lettres. Ces trois littéraux ont été relevés tels quels dans
les `.qmd` de J02, J04, J06, J07 (et dans les anciens `demo_formateur_J8.qmd` /
`_J9.qmd` / `_J10.qmd`, en cours de réécriture).

**Ce qui casse sans elles.**

- **J04 (« la terre en pixels »)** — c'est la donnée de la journée. Sans elle,
  ni `rast()`, ni `crop`/`mask`, ni le NDBI (B08/B11), ni la composition
  colorée. La journée n'a pas d'autre raster.
- **J02** — la section « du vecteur au raster » perd son illustration.
- **J06, J07** — fonds d'image et covariable de texture.
- **J05** — sans objet : la section Sentinel-2 y a été **volontairement
  supprimée** (décision actée), pour une raison technique et non de poids : la
  tuile ne couvre qu'une fraction du pays, donc une extraction zonale par
  district renverrait `NA` pour ~199 districts sur 200.

**Deux limites connues à ne pas oublier en les restaurant** (§3.7) : la tuile
couvre seulement 11,5-14,9° E / 2,5-5,8° N (Est et Sud du Cameroun), est en
**WGS84** et non UTM, à **~150 m** et non 10 m. Et `True_color` est une image
de visualisation **8 bits** : elle ne porte aucune réflectance, on ne calcule
jamais d'indice dessus.

### 2.5 Les deux tuiles Sentinel-2 jamais capturées — B03 et B04

| Nom exact attendu | Journées |
|---|---|
| `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B03_(Raw).tiff` | J07 (et anciens J09/J10) |
| `2026-06-26-00_00_2026-06-26-23_59_Sentinel-2_L2A_B04_(Raw).tiff` | J07 (et anciens J09/J10) |

**Statut différent des trois précédentes** : ces deux bandes n'ont **jamais été
acquises** — elles ne sont pas « perdues », elles n'ont jamais existé sur ce
poste (§7 des règles).

**Conséquence directe** : sans B04 (rouge), **le NDVI n'est pas calculable**.
Toute section qui l'annonce doit soit être réécrite sur B08/B11 (NDBI, MNDWI),
soit passer en `eval: false` avec la raison écrite. Un nouveau téléchargement
doit porter sur **la même emprise, la même date et le même niveau L2A** que les
trois autres, faute de quoi les bandes ne s'empileront pas.

---

## 3. `FIES_Cameroun.csv` — n'a jamais existé, substitut déjà décidé

| | |
|---|---|
| **Nom attendu par le code** | `FIES_Cameroun.csv` |
| **Journées qui le réclament** | J06, J07 (et l'ancien `demo_formateur_J8.qmd`) |
| **Statut** | **Confirmé absent partout** — grep dédié sur `all_data/` : 0 résultat. Ce fichier n'a jamais été fourni, il n'y a rien à restaurer. |

Le FIES (*Food Insecurity Experience Scale*, FAO) est une échelle d'insécurité
alimentaire fondée sur huit questions. Aucun extrait camerounais n'a été livré
avec le matériel.

**Substitut retenu — deux voies, toutes deux sur des fichiers présents :**

1. **Covariables de `CMGC72FL.csv`** (430 grappes × 130 variables
   contextuelles, présent dans `all_data/`). Les prédicteurs de vulnérabilité
   utilisables : `Travel_Times_2015` et `Nightlights_Composite` (excellents
   indicateurs d'accessibilité et d'intensité économique), l'aridité et la
   pluviométrie. **Attention aux sentinelles négatives** (§3.4) : aridité 6
   grappes sur 430, pluie 6, paludisme 4 — et surtout `Drought_Episodes` 125 et
   `Growing_Season_Length` 214, qui sont **inexploitables** et ne servent que de
   contre-exemples.
2. **`s09q13a` d'ECAM5** (`ecam5.dta`, présent) : la question de privation
   alimentaire du questionnaire ménage. Avantage : c'est une déclaration de
   ménage, donc plus proche conceptuellement du FIES qu'une covariable
   satellitaire. Limite à ne pas taire : **ce n'est pas la même mesure** — une
   question unique de privation alimentaire ne reconstitue pas une échelle à
   huit items. Contraintes : pondérer par `coefextr`, et respecter
   l'avertissement — **l'extrait ECAM5 n'est pas représentatif à l'intérieur
   des régions**, donc aucun chiffre régional produit ne doit être cité comme
   statistique officielle.

Dans les deux cas, la substitution est une **décision de méthode** : elle doit
être écrite dans le texte de la journée, pas seulement dans le code (§3.3).

---

## 4. `CMFW71FL.SAV` — présent, mais ce n'est PAS un des deux manquants

**Ne pas le renommer.** `all_data/` contient un unique fichier `.SAV`, nommé
`CMFW71FL.SAV`. La tentation est grande d'y voir `CMHR71FL.SAV` ou
`CMIR71FL.SAV` mal nommé. **C'est très probablement faux.**

Dans la nomenclature DHS, les deux lettres qui suivent le code pays et
précèdent le numéro de phase désignent le *recode* :

| Code | Recode | Unité d'observation |
|---|---|---|
| `HR` | Household Recode | le ménage |
| `IR` | Individual Recode | la femme de 15-49 ans |
| `FW` | **Fieldworker** | **l'enquêteur / l'agent de terrain** |

`CMFW71FL.SAV` est donc le **fichier enquêteurs** de l'EDS-MICS Cameroun 2018 :
quelques centaines de lignes décrivant les agents de collecte (âge, sexe,
formation, expérience), et non des ménages ou des femmes. Il sert aux études de
qualité de collecte (effet enquêteur), pas à l'analyse démographique.

**Aucune journée J01 → J11 ne le réclame** : il n'apparaît dans aucun littéral
`"datasets/…"` du dépôt.

**Vérification à passer avant toute décision** (une minute dans R) :

```r
noms <- names(haven::read_sav("pedagogie/all_data/CMFW71FL.SAV", n_max = 0))
length(noms)
head(noms, 30)
nrow(haven::read_sav("pedagogie/all_data/CMFW71FL.SAV", col_select = 1))
```

Lecture du résultat :

- des variables en `fw1…fwNN` et quelques centaines de lignes → **c'est bien le
  fichier enquêteurs**, il ne remplace rien, le laisser où il est ;
- des variables en `hv0xx` et > 4 000 colonnes → contre toute attente, c'est
  `CMHR71FL.SAV` mal nommé ;
- des variables en `v0xx`/`b0xx` → c'est `CMIR71FL.SAV` mal nommé.

Dans les deux derniers cas seulement, la commande de renommage serait
`ren "CMFW71FL.SAV" "CMHR71FL.SAV"` (ou `CMIR71FL.SAV`) dans
`pedagogie\all_data\`. **Ne pas la passer avant d'avoir lu la sortie ci-dessus**
— un renommage aveugle donnerait à un fichier d'enquêteurs l'autorité d'un
fichier de ménages, exactement le type d'échec silencieux que les règles
interdisent (§1.2).

---

## 5. Récapitulatif — 8 fichiers à restaurer

| Fichier | Poids ind. | Journées | Sans lui |
|---|---|---|---|
| `CMHR71FL.SAV` | ~72 Mo | J01, J03, J05, J06, J07 | J05 entièrement bloquée (poids, grappes, richesse) ; J01 sans support de lecture |
| `CMIR71FL.SAV` | ~83 Mo | J01, J03, J04, J06, J07 | plus de comparaison ménage/individu ; J04 sans tableau d'enquête |
| `DS.geojson` | ~20 Mo | J03, J05, J06, J07, **J10 mod. 10** | perte de la démonstration « 430 grappes / 200 districts » et du module accessibilité |
| `…Sentinel-2_L2A_B08_(Raw).tiff` | ~30 Mo | J02, J04, J06, J07 | J04 sans raster ; NDBI impossible |
| `…Sentinel-2_L2A_B11_(Raw).tiff` | ~30 Mo | J02, J04, J06, J07 | idem (B11 = SWIR, second terme du NDBI) |
| `…Sentinel-2_L2A_True_color.tiff` | ~30 Mo | J02, J04, J06, J07 | plus de composition colorée de référence |
| `…Sentinel-2_L2A_B03_(Raw).tiff` | ~30 Mo | J07 | jamais capturée ; MNDWI impossible |
| `…Sentinel-2_L2A_B04_(Raw).tiff` | ~30 Mo | J07 | jamais capturée ; **NDVI impossible** |

Pas à restaurer, mais à traiter : `FIES_Cameroun.csv` (§3, substitut décidé) et
`CMFW71FL.SAV` (§4, à vérifier, ne rien renommer).

---

## 6. Deux corrections de nom à passer dans `all_data/`, indépendantes

Relevées au manifeste §0 : deux fichiers présents portent une **espace
parasite** que le code ne référence jamais. Une copie « nom à nom » échouera
dessus même une fois `distribuer_donnees.R` corrigé. Les commandes sont dans
`outils/menage_poste.md`.

- `CMR_ household_v1_0_admin_level2.csv` → `CMR_household_v1_0_admin_level2.csv`
- `CMR_ household_v1_0_admin_level2.xlsx` → `CMR_household_v1_0_admin_level2.xlsx`
