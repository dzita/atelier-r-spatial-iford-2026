# Données du jour — dossier `datasets/` (J10)

Ce dossier reçoit **les fichiers de données de cette journée uniquement**, **à
plat** : aucun sous-répertoire. Le `.qmd` et les trois scripts les lisent en
chemin relatif `datasets/<fichier>`, et c'est cette forme littérale que
`outils/distribuer_donnees.R` détecte par expression régulière.

**Les sorties ne s'écrivent jamais ici.** Tout ce que la journée produit va dans
`outputs/`, préfixé `J10_`.

## Comment le remplir

Depuis la racine du projet (ouvrir `atelier-r-spatial-iford-2026.Rproj`) :

```r
source("outils/distribuer_donnees.R")
```

---

## Inventaire — les 8 fichiers que la journée lit

*Les tailles ne sont pas renseignées : l'outil de rédaction ne les a pas
retournées. À relever côté poste (voir `_A_FAIRE_J10.md`).*

### 1. `acled_cameroon_export.csv` — **Cameroun**

| | |
|---|---|
| **Unité d'observation** | **un événement rapporté** (une ligne = un fait signalé par au moins une source et codé par ACLED) |
| **Format** | CSV, séparateur **virgule**, champs texte protégés par guillemets |
| **Colonnes (31, vérifiées sur l'en-tête)** | `event_id_cnty`, `event_date`, `year`, `time_precision`, `disorder_type`, `event_type`, `sub_event_type`, `actor1`, `assoc_actor_1`, `inter1`, `actor2`, `assoc_actor_2`, `inter2`, `interaction`, `civilian_targeting`, `iso`, `region`, `country`, `admin1`, `admin2`, `admin3`, `location`, `latitude`, `longitude`, `geo_precision`, `source`, `source_scale`, `notes`, `fatalities`, `tags`, `timestamp` |
| **Clé** | `event_id_cnty` (identifiant ACLED) — non utilisée pour joindre : le rattachement territorial se fait **par la position** |
| **Poids de sondage** | aucun (ce n'est pas une enquête) |
| **Sections consommatrices** | modules 1 et 2 |
| **Taille** | n.d. |

**Ce qu'il ne faut pas lui faire dire.** Un événement ACLED est un fait
**rapporté**, pas un fait vérifié ni un recensement exhaustif. Une zone sans
presse produit peu d'événements.

### 2. `gadm41_CMR.gpkg` — **Cameroun**

| | |
|---|---|
| **Unité d'observation** | **un polygone administratif**, à quatre niveaux |
| **Format** | GeoPackage multicouche. Couches attendues : `ADM_ADM_0` (pays), `ADM_ADM_1` (10 régions), `ADM_ADM_2` (58 départements), `ADM_ADM_3` |
| **Champs utilisés** | `NAME_1` (nom de région, **en anglais**), `NAME_2` |
| **Clé** | `GID_1` / `GID_2` encodent la hiérarchie ; `NAME_1` sert à joindre **après** agrégation spatiale, jamais à apparier ACLED |
| **Sections consommatrices** | modules 2, 3 et 4 |
| **Taille** | n.d. |

Le script liste les couches par `st_layers()` avant de lire : les noms exacts ne
sont pas supposés. Mutualisé avec les journées J08 et J09 (même fichier).

### 3. `era5_t2m_mensuel_cameroun.nc` — **Cameroun**

| | |
|---|---|
| **Unité d'observation** | **une cellule de ~0,25° (≈ 31 km) × un mois** |
| **Format** | NetCDF (longitude × latitude × temps), lu par `terra::rast()` comme une pile de couches |
| **Variable** | `2m_temperature` (ERA5 Single Levels, moyennes mensuelles) |
| **UNITÉ** | **KELVIN** — conversion `T_C = T_K − 273,15` obligatoire et visible dans le code |
| **Emprise de la requête** | N 13,1 · O 8,4 · S 1,6 · E 16,2 |
| **Sections consommatrices** | modules 3 et 4 |
| **Taille** | n.d. |

**Ce que le fichier n'est pas.** Ni une observation, ni une prévision : une
**réanalyse**, c'est-à-dire la sortie d'un modèle atmosphérique contraint par
les observations disponibles. Complet et régulier là où le réseau de stations
est clairsemé — au prix d'une valeur qui, dans les zones sans station, vient
surtout du modèle.

### 4. `ehcvm2018_benin_menages.csv` — **Bénin**

| | |
|---|---|
| **Unité d'observation** | **un ménage enquêté** (pas un individu) |
| **Format** | CSV, séparateur **virgule** |
| **Colonnes (10, vérifiées sur l'en-tête)** | `hhid`, `id`, `grappe`, `menage`, `vague`, `hhweight`, `hhsize`, `lat`, `lon`, `insecure` |
| **Clé** | `hhid` (ménage) ; `grappe` est l'**unité primaire de sondage** ; `id` est l'identifiant de la **cellule de grille de 3 km** — c'est lui qui fait le pont vers la commune |
| **Poids de sondage** | **`hhweight`**, obligatoire |
| **Variable d'intérêt** | `insecure` (0/1) — **déclaration de ménage** d'insécurité alimentaire |
| **Sections consommatrices** | module 5 |
| **Taille** | n.d. |

**Attention.** Le fichier ne porte **pas** `admin2Pcod`. Le rattachement à la
commune passe par `benin_covariables_grille.csv` (`id` → `admin2Pcod`). Les
coordonnées `lat`/`lon` sont celles de la grappe et sont **déplacées** par le
producteur pour protéger l'anonymat, comme au DHS.

### 5. `gadm_ben_communes.gpkg` — **Bénin**

| | |
|---|---|
| **Unité d'observation** | **une commune** (admin2 béninois) |
| **Format** | GeoPackage, couche `ben_adm2_communes` |
| **Champs utilisés** | `admin2Pcod` (clé), `adm2_name` (libellé d'affichage) |
| **Clé** | `admin2Pcod` — unicité **vérifiée dans le code** avant toute jointure |
| **Sections consommatrices** | modules 5, 8 et 9 |
| **Taille** | n.d. |

### 6. `benin_grille_3km.gpkg` — **Bénin**

| | |
|---|---|
| **Unité d'observation** | **une cellule de 3 km × 3 km** (~15 400 cellules pour le pays) |
| **Format** | GeoPackage, couche `grille_3km` |
| **Champ utilisé** | `id` (clé de jointure avec les covariables de grille) |
| **Sections consommatrices** | module 9 |
| **Taille** | n.d. |

**À ne pas confondre** avec les grilles de population à 100 m du J08 (WorldPop,
GHS-POP). Ici, 3 km est un choix d'extraction des covariables sur Google Earth
Engine — un compromis entre finesse spatiale et temps de calcul —, pas la
résolution d'un produit d'imagerie.

### 7. `benin_covariables_admin2.csv` — **Bénin**

| | |
|---|---|
| **Unité d'observation** | **une commune** |
| **Colonnes (10, vérifiées sur l'en-tête)** | `admin2Pcod`, `ntl_mean_adm2`, `population_adm2`, `ndvi_mean_adm2`, `precip_2018_adm2`, `no2_adm2`, `lc_13_urbain_adm2`, `lc_12_cultures_adm2`, `lc_8_savane_boisee_adm2`, `lc_11_zones_humides_adm2` |
| **Clé** | `admin2Pcod` |
| **Sections consommatrices** | modules 6 et 7 |
| **Taille** | n.d. |

### 8. `benin_covariables_grille.csv` — **Bénin**

| | |
|---|---|
| **Unité d'observation** | **une cellule de grille de 3 km** |
| **Colonnes (11, vérifiées sur l'en-tête)** | `id`, `admin2Pcod`, `ntl_mean`, `population`, `ndvi_mean`, `precip_2018`, `no2`, `lc_13_urbain`, `lc_12_cultures`, `lc_8_savane_boisee`, `lc_11_zones_humides` |
| **Clé** | `id` ; `admin2Pcod` rattache la cellule à sa commune |
| **Double rôle** | (a) **table de passage** `id` → `admin2Pcod` pour rattacher les ménages à leur commune (module 5) ; (b) covariables de prédiction fine (module 9) |
| **Sections consommatrices** | modules 5 et 9 |
| **Taille** | n.d. |

**Piège de nommage à enseigner.** Les mêmes variables portent **des noms
différents** dans les fichiers 7 et 8 : suffixe `_adm2` par commune, sans suffixe
par cellule. C'est volontaire (on ne confond pas les deux résolutions) et c'est
exactement là que le module 9 se trompe si l'on copie la formule sans la lire :
le modèle est ajusté sur `lc_13_urbain_adm2` et doit être appliqué à
`lc_13_urbain`.

---

## Les deux fichiers du module 10 — **actuellement absents**

Le module 10 (accessibilité aux services) est livré en `eval: false`. Il
redeviendra exécutable quand ces fichiers rejoindront `datasets/` :

| Fichier | Ce qu'il porte | État |
|---|---|---|
| `DS.geojson` | 200 districts sanitaires du Cameroun. Champs `name` et `parentName` — **ni `NomDS` ni `CodeDS`**. **135 géométries invalides sur 200** → `sf_use_s2(FALSE)` + `st_make_valid()` | **absent du poste** |
| `gadm41_CMR_2.shp` (+ `.shx`, `.dbf`, `.prj`, `.cpg`) | 58 départements — un shapefile voyage avec ses annexes | **absent du poste** |

---

## Ce qui ne doit **pas** se trouver ici, et pourquoi

Chaque exclusion a une raison **technique**, pas un souci de poids.

| Fichier | Raison de l'exclusion |
|---|---|
| `ecam5.dta` | **Ne sert plus.** La partie III de la journée a été transposée au Bénin, précisément parce que cet extrait ECAM5 n'est **pas représentatif à l'intérieur des régions** : l'Est y ressort à 7,5 % de pauvreté contre 41,5 % publié par l'INS. Un exercice d'estimation sur petits domaines construit dessus produirait des chiffres qu'il faudrait interdire de citer. Le fichier appartient au J05. |
| `eesi3.dta` | **Ne sert plus.** Il alimentait, dans l'ancien matériel, un module de covariables pour la SAE camerounaise, désormais remplacé par les covariables béninoises. Aucun module de la journée ne le lit. |
| `CMHR71FL.SAV` | **Ne sert plus.** 72 Mo, plus de 4 000 colonnes, noms de variables en MAJUSCULES. Il alimentait l'ancienne section « accès à l'éducation », supprimée : elle doublonnait le travail d'enquête du J05 sans rien apporter au fil « politiques publiques ». |
| `CMIR71FL.SAV` | **Ne sert plus.** Même raison (recode individuel du DHS). |
| `CMGC72FL.csv` | **Ne sert plus, et l'ancien code s'en servait à tort.** Ce fichier ressemble à un fichier de coordonnées ; il n'en contient **aucune** : ce sont les 130 covariables contextuelles par grappe DHS. L'ancien module d'accessibilité construisait ses isochrones autour de coordonnées lues dans ce fichier — le code était donc faux et aurait échoué même avec toutes les données présentes. Les positions des grappes DHS sont dans `CMGE71FL.shp` (J05). |
| Tuiles Sentinel-2 (`…B08…`, `…B11…`, `…True_color…`) | **Ne servent plus.** Aucun module de la journée n'ouvre de raster optique. Et la tuile disponible ne couvre qu'une fraction du pays (11,5–14,9° E / 2,5–5,8° N), en WGS84 à ~150 m, sans les bandes B03 et B04 : elle ne permet aucun indice spectral. |
| `Pays_limitrophes_Cmr.shp` | **Ne sert plus.** Il servait à la carte de contexte régional de l'ancienne section « déplacements forcés », supprimée faute de données (`HCR_Cameroun_deplaces.csv` n'a jamais existé sur le poste). |
| `CMR_population_v1_0_admin_level2.csv`, `CMR_household_…csv` | Ne servent plus dans cette journée : les effectifs par département n'entrent dans aucun module. Ils appartiennent au J05 et au J08. |
| `ACLED_Data.csv`, `ACLED Data.csv`, `ACLED_Cameroun_2017_2024.csv` | **Trois anciens noms pour une seule et même donnée.** Le fichier livré s'appelle **`acled_cameroon_export.csv`**, et c'est le seul nom employé dans tout le matériel J10. Si l'un de ces trois noms traîne encore dans `datasets/`, le supprimer (voir `_A_FAIRE_J10.md`). |
| `benin_covariables_brutes_gee/` | Dossier de 12 CSV bruts (ntl, population, ndvi, precip, buildings, rivers, distancecities, landclass, pollution). Le matériel source les qualifie lui-même de « covariables GEE brutes, **non utilisées en exemple** » : les fichiers 7 et 8 en sont l'agrégation prête à l'emploi. Livrer les deux dupliquerait l'information et ajouterait un sous-répertoire, que la convention « à plat » interdit. |

---

## Les pièges de la journée, chiffrés

À lire avant d'animer la séance : ce sont les chiffres à faire apparaître à
l'écran.

1. **Jointure ACLED ↔ GADM par libellé.** Les `admin1` d'ACLED sont en français
   non accentué, les `NAME_1` de GADM en **anglais**. Seules s'apparient les
   régions dont le nom s'écrit pareil dans les deux langues — en pratique une
   poignée (`Adamaoua`, `Centre`, `Littoral` sont les candidates évidentes) sur
   **10**. Le module 2 imprime le nombre exact de régions `NA` et la **part des
   événements orphelins**. Attendez-vous à une majorité.

2. **`replace_na(0)`, la même ligne pour deux choses opposées.** Après jointure
   **spatiale**, une région absente est une région sans événement rapporté : le
   zéro est une mesure. Après jointure **par libellé ratée**, le zéro fabrique
   une région pacifiée qui n'existe pas.

3. **Kelvin.** Une couche ERA5 non convertie affiche une moyenne autour de
   **298** ; convertie, autour de **25**. Une **différence** de températures, en
   revanche, a exactement la même valeur dans les deux unités : l'oubli de
   conversion y est **indétectable**. C'est l'objet de l'exercice 3.

4. **Résolution ERA5.** ~0,25°, soit **≈ 31 km de côté** et **≈ 950 km² par
   cellule**. Le Cameroun entier tient en quelques centaines de cellules — le
   code imprime le nombre exact. Aucune chaleur urbaine n'existe dans ce fichier.

5. **Pondération.** Le module 5 imprime côte à côte la moyenne **brute** et la
   moyenne **pondérée** d'`insecure`, puis l'erreur-type avec et sans prise en
   compte des grappes. Repère de comparaison, mesuré au J05 sur ECAM5 :
   **40,8 % sans poids contre 38,6 % avec**.

6. **Communes non estimables.** Les communes à **une seule grappe** enquêtée
   n'ont pas de variance calculable (la variance s'estime *entre* grappes). Elles
   sont exclues du modèle — seuil déclaré dans le code, `n_grappes == 1` — et
   restent **grises sur les trois cartes**, nommées dans la légende.

7. **Taille d'échantillon par commune.** Entre quelques dizaines et plusieurs
   centaines de ménages selon la commune ; le code imprime min, médiane et max.
   C'est cette dispersion qui rend l'estimation sur petits domaines nécessaire.

8. **Le test du mécanisme.** Le nuage `gain_rmse` contre `n_menages` (échelle
   log) doit **décroître** : le gain de précision doit être maximal là où
   l'échantillon est le plus petit. Le tableau par tiers imprimé sous la figure
   dit la même chose sans dépendre du lissage — **c'est lui qui fait foi**.

9. **Prédiction hors bornes.** Le modèle est linéaire et la variable est une
   proportion : des cellules peuvent être prédites en dehors de `[0, 100]`. Le
   code **les compte** et ne les tronque pas en silence.

10. **Effet aléatoire constant.** `u_hat` ne varie pas à l'intérieur d'une
    commune. Toute la variation visible sur la carte de grille de 3 km vient donc
    **des covariables**, et d'elles seules : la carte montre la géographie de la
    part de sol urbain et de savane boisée, translatée et mise à l'échelle.

11. **Référence de contrôle du module 10** (quand ses données seront présentes) :
    la somme des superficies des districts sanitaires, calculée **après
    reprojection en UTM 33N**, doit approcher les **475 442 km²** officiels du
    Cameroun. Un écart de plus de quelques pour cent signale une mauvaise
    projection ou un trou dans le découpage.

---

_Les fichiers de données sont volumineux et exclus de Git (`.gitignore`)._
