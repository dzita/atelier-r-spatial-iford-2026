# À faire sur le poste — J08

> Rédigé le 31/08/2026 par la session de réécriture du J08.
> **Le shell Linux du conteneur ne démarrait pas** : aucune exécution de R,
> aucun rendu Quarto, aucune ouverture de fichier binaire n'a été possible.
> Tout ce qui suit demande la machine de l'utilisateur.

---

## 1. Contrôles déjà passés (par expression régulière, sans exécution)

| Contrôle | Résultat |
|---|---|
| Ouvertures de chunk ` ```{r ` dans `demo_formateur_J08.qmd` | **38** |
| Fermetures ` ``` ` (trois accents graves seuls sur leur ligne) | **38** |
| **Équilibre** | **OK — 38 / 38** |
| `setwd(` dans le `.qmd` | aucun |
| `install.packages(` dans le `.qmd` | aucun |
| `here(` dans le `.qmd` et dans les 3 scripts | aucun |
| `file.path(data_dir` / variable `data_dir` | aucun |
| Chemin absolu `C:\` | aucun |
| Préfixe `jour07_` / `jour_07` résiduel | aucun |
| `J8` nu (hors `J08`) | aucun |
| Littéraux `"datasets/…"` pointant vers un sous-dossier | aucun — les 9 littéraux sont à plat |
| Marqueurs `>>> A COMPLETER` dans `scripts/script_etudiant_J08.R` | **58** |

Longueurs des fichiers écrits :
`demo_formateur_J08.qmd` 2 986 l. · `scripts/script_formateur_J08.R` 2 803 l. ·
`scripts/script_etudiant_J08_corrige.R` 2 276 l. ·
`scripts/script_etudiant_J08.R` 1 241 l. · `install_packages_day.R` 130 l. ·
`README.md` 195 l. · `datasets/LISEZMOI.md` 194 l.

> Le `.qmd` dépasse la fourchette de 1 500 à 2 200 lignes qui avait été
> indiquée : 2 986 lignes. L'excédent vient des encadrés d'interprétation en
> quatre temps (§4.1), qui sont longs par construction, et des sections de fin
> de journée (glossaire, fonctions clés, huit exercices, prolongements). Rien
> n'a été ajouté hors cahier des charges ; si la longueur pose problème, la
> coupe la moins coûteuse serait de renvoyer le glossaire vers un fichier
> `GLOSSAIRE_J08.md` séparé.

---

## 2. Ce qui reste à vérifier **par exécution**

Rien de ce qui suit n'a pu être testé. Ordre recommandé.

1. **Contrôle de syntaxe des trois scripts**, avant toute autre chose :

   ```r
   parse("pedagogie/J08_population_haute_resolution/scripts/script_formateur_J08.R")
   parse("pedagogie/J08_population_haute_resolution/scripts/script_etudiant_J08_corrige.R")
   parse("pedagogie/J08_population_haute_resolution/scripts/script_etudiant_J08.R")
   ```

   Pour la trame, des **erreurs d'exécution** sont attendues (le code est
   retiré) ; c'est seulement la syntaxe qui doit passer.

2. **Rendu Quarto** de `demo_formateur_J08.qmd`, puis relecture du HTML :
   - erreurs (`<div class="cell-output cell-output-error">`) ;
   - avertissements ;
   - **les compteurs `cat()`** — ils sont le principal outil de diagnostic de
     cette journée, et plusieurs conclusions du texte dépendent de leur valeur
     réelle (voir §3) ;
   - la table des matières : vérifier qu'aucun faux titre n'apparaît.

3. **Vérifier la version de `tmap`.** Si elle est < 4.0.0, tous les blocs
   cartographiques des modules 3 à 9 échouent. `install_packages_day.R`
   avertit, mais ne met pas à jour d'office.

4. **`scale_fill_viridis_c(trans = "log10")`** (module 6). Depuis ggplot2 3.5,
   `trans` est déprécié au profit de `transform` : le code fonctionne mais émet
   un avertissement de dépréciation, visible parce que `warning: true`. Si le
   parc de machines est homogène en ggplot2 ≥ 3.5, remplacer `trans` par
   `transform` dans le `.qmd` **et** dans les trois scripts. Sinon, laisser
   `trans` (compatible avec les deux) et ne rien changer.

5. **Temps de calcul du module 7.** L'assemblage des sept tuiles GHS-POP, la
   reprojection Mollweide → WGS84 et le `writeRaster` sont les opérations les
   plus lourdes de la journée. Chronométrer sur le poste de salle : si le rendu
   dépasse ce qui est tolérable, envisager de livrer une **découpe nationale
   préalable en un seul `.tif`** et de garder la chaîne de mosaïque en
   `eval: false`, avec la raison technique écrite.

6. **Poids du HTML rendu.** Tous les widgets interactifs sont en `eval: false`,
   donc le document ne devrait pas exploser ; le vérifier quand même.

---

## 3. Hypothèses faites faute de pouvoir ouvrir les données

Aucun fichier binaire ni CSV n'a pu être lu. Chaque hypothèse ci-dessous est
**protégée dans le code** (par `any_of()`, `intersect()`, un test `if`, ou un
`cat()` de contrôle), mais elle doit être confirmée au premier rendu.

### 3.1 `cmr_admpop_adm1_2025.csv`

| Hypothèse | Protection dans le code | À vérifier |
|---|---|---|
| Le séparateur est la **virgule** | `read_csv()` ; un `cat()` imprime `ncol` | si `ncol == 1`, le séparateur est `;` → passer à `read_csv2()` |
| Colonnes `ADM1_EN`, `ADM1_FR` présentes | aucune : elles sont invoquées directement au module 1 | **le point le plus fragile de la journée.** Si l'une manque, le module 1 échoue à la première ligne |
| Colonnes `T_TL`, `F_TL`, `M_TL` | `any_of()` dans le `select()` de la jointure | si `T_TL` manque, tout le reste tombe en `NA` — le compteur de NA après jointure le montrera |
| Colonne `ADM1_PCODE` | `any_of()` — facultative | rien à faire si absente |
| Tranches d'âge nommées `T_00_04`, `T_05_09`, `T_10_14`, … `T_80Plus` | `intersect()` pour les 0-14 ; `grep("^T_")` pour la pyramide, avec `cat()` du nombre trouvé | si la convention de nommage diffère, `cols_jeunes` sera vide et `part_jeunes_pct` vaudra 0 — le `cat()` « colonnes trouvées : 0/3 » l'annonce |
| 10 lignes, une par région | `cat()` de `nrow` | si 12 lignes (Douala et Yaoundé en entités séparées, comme dans ECAM5 et l'EDS), il faudra une table de correspondance manuelle |

**Quelle colonne apparie GADM ?** Le script source d'origine joignait sur
`ADM1_FR`, mais utilisait `ADM1_EN` (« Centre », « Adamawa ») pour filtrer les
régions du module « structure par âge » — les deux usages sont contradictoires.
Faute de pouvoir trancher, **le code ne choisit pas** : il compte les
appariements des deux candidates contre `NAME_1` et retient celle qui gagne, en
imprimant le décompte. C'est plus robuste que l'original, mais **il faut lire ce
décompte au premier rendu** : si les deux valent 0, ni l'une ni l'autre
n'apparie et une table de correspondance manuelle devient nécessaire.

### 3.2 `gadm41_CMR.gpkg`

| Hypothèse | Protection | À vérifier |
|---|---|---|
| Couches nommées **`ADM_ADM_0`, `ADM_ADM_1`, `ADM_ADM_2`, `ADM_ADM_3`** | `st_layers()` est imprimé avant la première lecture | si les noms diffèrent (`gadm41_CMR_1`, `ADM1`…), corriger les 4 appels `layer =` du `.qmd` et des 3 scripts |
| `NAME_1` au niveau ADM1, `NAME_2` au niveau ADM2 | `cat()` de `names()` ; test `nrow(yaounde) == 0` avec message | si `NAME_2` s'appelle autrement, le filtre Mfoundi renvoie 0 ligne et le message le dit |
| Un département nommé exactement **`Mfoundi`**, et `Wouri`, `Mifi`, `Mezam`, `Benoue` | test explicite + avertissement, `NA` renvoyés plutôt qu'une erreur | orthographes accentuées possibles (`Bénoué`) → adapter le vecteur `villes_dept` |
| 10 régions et 58 départements | `cat()` de `nrow` | — |
| CRS EPSG:4326 | `cat()` du CRS | si le `.gpkg` était déjà projeté, les reprojections restent correctes (elles sont toutes explicites) |
| La couche `ADM_ADM_3` existe (exercice 5 seulement) | non utilisée par le code exécuté | vérifier avant de donner l'exercice 5 |

### 3.3 Les trois rasters WorldPop

| Hypothèse | Protection | À vérifier |
|---|---|---|
| CRS = **EPSG:4326**, résolution **en degrés** (~0,00083) | `cat()` de `res()`, `crs(describe = TRUE)$code` | tout l'encadré « lire la résolution » du module 3 repose là-dessus. Si le CRS était projeté, **réécrire l'encadré** |
| Les trois grilles ont la **même emprise et les mêmes dimensions** | test `identical(dim(...), dim(...))` imprimé | si elles diffèrent, les breaks communs restent valides mais le texte sur la comparabilité doit être nuancé |
| Emprise = le Cameroun entier | `cat()` de xmin/xmax/ymin/ymax + nombre de cellules non vides après `mask()` | si l'emprise est partielle, tous les totaux nationaux sont faux — c'est exactement le piège de la tuile Sentinel-2 du J05 |
| Valeurs = effectifs positifs, pas de sentinelle négative | `cat()` de `minmax()` | si des valeurs négatives apparaissent, ajouter le recodage en `NA` fait au module 7 pour GHS-POP |
| `R2025A` est bien la version des trois | lu dans le nom de fichier | rien à vérifier par exécution |

### 3.4 Les sept tuiles GHS-POP

| Hypothèse | Protection | À vérifier |
|---|---|---|
| Les **7** `.zip` sont présents et nommés `GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R*_C*.zip` | `list.files()` + `cat()` du nombre trouvé + message si 0 | la cartographie du matériel source signalait une **incohérence entre les 7 zip et les 7 tif** (un `R10_C20` sans zip correspondant côté tif) : **inventaire à revérifier tuile par tuile** |
| Chaque `.zip` contient **un** `.tif` | `cat()` du nombre de `.tif` après décompression | si un zip contient plusieurs `.tif` (métadonnées, aperçus), filtrer le motif de `list.files()` |
| CRS = **ESRI:54009 (Mollweide)**, résolution **100 m métriques** | `cat()` sur la tuile témoin | tout l'encadré « coût de la reprojection » en dépend |
| Les 7 tuiles ensemble **couvrent le Cameroun entier** | `cat()` de l'emprise de la mosaïque + total après découpe | si une tuile manque, le total national GHS-POP sera sous-estimé sans qu'aucune erreur ne soit levée |
| Sentinelle nodata **négative** | comptage explicite avant recodage | si la sentinelle est positive (par ex. `65535`), le recodage `< 0` ne l'attrape pas |

### 3.5 Deux choix de méthode à valider en salle

- **UTM 33N (EPSG:32633)** est retenu pour toutes les surfaces, conformément au
  référentiel de qualité. Le Cameroun s'étend d'environ 8,5° à 16,2° E, donc à
  cheval sur les zones 32 et 33. Le contrôle contre les **475 442 km²** officiels
  est imprimé au module 6 : si l'écart dépasse ~1 %, essayer EPSG:32632 (UTM 32N)
  et retenir celui qui colle le mieux — puis mettre à jour le glossaire, le
  `.qmd` et les trois scripts.
- **L'emprise bbox du module 9** (11,48–11,58 E / 3,82–3,93 N) est reprise du
  script source. Elle n'a pas pu être vérifiée sur fond satellite : contrôler
  qu'elle tombe bien sur un secteur bâti de Yaoundé, et l'ajuster sinon.

---

## 4. Commandes Windows à passer sur le poste

À exécuter depuis
`C:\Users\PROLOG\OneDrive\MES BUSINESS\atelier-r-spatial-iford-2026\pedagogie\J08_population_haute_resolution\`.

**Faire une branche Git avant toute suppression.**

### 4.1 Supprimer les anciens fichiers `*_J8.*`

Ils sont remplacés en totalité. Le nouveau matériel ne les lit pas et ne les
référence pas.

```bat
del "demo_formateur_J8.qmd"
del "script_formateur_J8.R"
del "script_etudiant_J8.R"
del "script_etudiant_J8_corrige.R"
```

### 4.2 `slides.qmd`

`slides.qmd` (374 lignes) est le support de présentation de l'ancienne version.
Il n'a **pas** été réécrit : la décision retenue est que les présentations
restent les trois `.pptx` FR / EN / bilingue. Deux options, au choix de
l'utilisateur :

```bat
rem  option A -- le supprimer, les .pptx font foi
del "slides.qmd"

rem  option B -- le garder comme trace, hors du chemin de travail
mkdir archive_fr
move "slides.qmd" "archive_fr\slides_J8_ancienne_version.qmd"
```

### 4.3 Créer les dossiers attendus

```bat
mkdir outputs
mkdir archive_en
```

`archive_en\` reçoit les scripts anglais du matériel source, **archivés et non
maintenus** (voir le README) :

```
archive_en\jour_07_etudiants_population_haute_resolution_en.R
```

### 4.4 Renommer les présentations

Les trois `.pptx` du matériel source portent le préfixe `jour_07_` (décalage de
numérotation du dossier `Tools_day_8\`) et le suffixe `_bilingual`, incohérent
avec le `_fr_en` du J09 et du J10 :

```bat
ren "jour_07_population_haute_resolution.pptx"           "jour_08_population_haute_resolution.pptx"
ren "jour_07_population_haute_resolution_en.pptx"        "jour_08_population_haute_resolution_en.pptx"
ren "jour_07_population_haute_resolution_bilingual.pptx" "jour_08_population_haute_resolution_fr_en.pptx"
```

Ne **pas** reprendre le fichier verrou `~$jour_07_…_bilingual.pptx` (fichier
temporaire PowerPoint).

---

## 5. Point à transmettre à l'agent qui écrit le script de copie

Les sept tuiles GHS-POP sont chargées par
`list.files("datasets", pattern = "^GHS_POP_E2025.*\\.zip$", full.names = TRUE)`
et **non** par sept littéraux `"datasets/<nom>"`. La détection par expression
régulière du script de distribution ne les verrait donc pas.

Pour compenser, **les sept noms complets sont écrits en commentaire** dans le
module 7 du `.qmd` et des trois scripts, sous la forme exacte
`"datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R7_C20.zip"` etc. Vérifier
que le script de copie les reprend bien — et que les noms correspondent à ceux
réellement présents dans le magasin central (voir §3.4 : l'inventaire des tuiles
est à revérifier).

Les autres fichiers sont détectables normalement, dans l'ordre où ils
apparaissent dans le `.qmd` :

```
datasets/cmr_admpop_adm1_2025.csv
datasets/gadm41_CMR.gpkg
datasets/cmr_pop_2025_CN_100m_R2025A_v1.tif
datasets/cmr_pop_2015_CN_100m_R2025A_v1.tif
datasets/cmr_pop_2030_CN_100m_R2025A_v1.tif
```

Le littéral `"datasets/ghs_built_2025_cmr_100m.tif"` apparaît une fois, dans le
**bloc de référence non exécuté** du module 8.3 : c'est une donnée du **J09**,
elle ne doit **pas** être copiée dans le `datasets/` du J08. Prévoir de
l'exclure du script de copie (elle est à l'intérieur d'un commentaire R, ce qui
peut suffire à l'écarter selon la précision de l'expression régulière — à
vérifier).
