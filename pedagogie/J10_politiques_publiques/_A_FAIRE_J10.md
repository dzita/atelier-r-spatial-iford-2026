# Points de contrôle au rendu — J10

> Procédure de recette de la journée J10. Elle distingue ce qui a déjà été
> contrôlé statiquement de ce qui demande R et Quarto sur le poste de salle.
> Les vérifications ci-dessous ne sont **pas des formalités** : elles portent sur
> les points où le code repose sur une hypothèse de structure de fichier plutôt
> que sur une lecture confirmée.

---

## 1. Contrôles statiques déjà passés

| Contrôle | Résultat |
|---|---|
| Ouvertures de chunk ```` ```{r ```` dans `demo_formateur_J10.qmd` | **59** |
| Fermetures ```` ``` ```` en début de ligne | **59** |
| **Équilibre** | **OK — 59 / 59.** Aucun chunk non fermé, donc aucun risque de faux titres dans la table des matières |
| `setwd(` | absent du `.qmd` ; présent uniquement dans le bloc d'en-tête des trois `.R`, comme le prévoit la règle §6.2 |
| `install.packages(` en `eval: true` | **aucun**. Deux occurrences, toutes deux **commentées**, dans les blocs de référence API (`acledR`, `ecmwfr`) qui sont en `eval: false` |
| `here(` | aucun |
| `file.path(data_dir` | aucun |
| Chemin absolu `C:\` | aucun |
| `"datasets/` suivi d'un sous-dossier | aucun — les 10 littéraux sont **à plat** |
| `ACLED Data.csv` / `ACLED_Data.csv` / `ACLED_Cameroun_2017_2024.csv` | **aucune occurrence résiduelle**. Le seul nom employé est `acled_cameroon_export.csv` |
| Marqueurs `>>> A COMPLETER` dans la trame étudiante | **60**, correspondant à 60 blocs « TRAVAIL n » numérotés |

**Contrôles qui demandent une exécution réelle :**

- `Rscript -e 'parse("scripts/script_formateur_J10.R")'` — et de même pour les
  deux autres scripts et pour `install_packages_day.R`. Les erreurs
  d'*exécution* de la trame à trous sont attendues ; c'est le `_corrige.R` qu'il
  faut tester.
- Le **Render** du `.qmd`, puis la lecture du HTML : erreurs
  (`cell-output-error`), avertissements, et surtout **relecture des compteurs
  `cat()`**, qui sont le principal outil de diagnostic du document.
- La **vérification d'affichage** : table des matières sans entrée parasite,
  images non cassées, nombre de callouts conforme.

---

## 2. Hypothèses de structure — à confirmer au premier rendu

Ce sont les endroits où le code peut échouer parce qu'il suppose une structure de
fichier plutôt que de la constater.

### 2.1 Couches et champs des quatre `.gpkg`

Le code suppose :

| Fichier | Couche supposée | Champs supposés |
|---|---|---|
| `gadm41_CMR.gpkg` | `ADM_ADM_0`, `ADM_ADM_1` | `NAME_1` |
| `gadm_ben_communes.gpkg` | `ben_adm2_communes` | `admin2Pcod`, `adm2_name` |
| `benin_grille_3km.gpkg` | `grille_3km` | `id` |

Ces noms viennent du script source (`…CORRIGE.R`, lignes 256-265, 813-822) et de
la cartographie J08-J10 : ce sont des noms repris, pas des noms constatés.

**Parade déjà en place :** le `.qmd` appelle `st_layers()` **avant** chaque
`st_read()` et imprime `names()` de chaque couche. Si un nom diffère, la sortie
le dit immédiatement — il suffit alors de corriger l'argument `layer =` et le
nom de champ correspondant. Ce sont les seules lignes à toucher.

### 2.2 Nombre de couches et pas de temps du NetCDF

Sur ce fichier, le code **ne suppose rien** : il imprime `nlyr()`, `res()`, `ext()`, `time()` et la plage de dates, et compare
le nombre de couches au nombre de mois distincts.

**Deux points à surveiller au rendu :**

- si `time(era5_brut)` renvoie des `NA` (NetCDF sans axe temporel exploitable),
  tout le module 4 tombe : le `match()` sur `paste0("mean.", names(era5_cmr))`
  produira des `idx` valides mais `dates_era5[idx]` sera `NA`. Le compteur
  « Dates manquantes » l'affichera. Repli possible : reconstruire les dates par
  `seq.Date()` en partant de la première année de la requête.
- le **préfixe des noms de couches** (`t2m_1`, `t2m_2`… ou autre chose selon la
  version de GDAL) : la construction `paste0("mean.", names(era5_cmr))` s'adapte
  automatiquement, mais si `exact_extract()` change son préfixe, le compteur
  « Couches non appariées par `match()` » le signalera.

### 2.3 Valeurs réelles de `admin1` dans ACLED, et de `NAME_1` dans GADM

L'en-tête du CSV ACLED donne `Sud` et `Extreme-Nord` : français, sans accents.
C'est ce qui fonde tout le module 2. **La liste complète des `admin1` reste à
inventorier sur le fichier livré.**

La table de correspondance `corresp_regions` (module 2.4) est écrite à
partir des dix régions administratives connues du Cameroun, en supposant que
GADM 4.1 les écrit en anglais (`East`, `Far North`, `North-West`, `South`,
`South-West`, `West`, `North`, plus `Adamaoua`, `Centre`, `Littoral`).

**À vérifier au premier rendu** — le code imprime tout ce qu'il faut :

- les trois `setdiff()` du module 2.4 doivent renvoyer des listes **vides**. Si
  l'un d'eux liste un libellé, corriger la table sur cette seule ligne.
- attention à la ponctuation exacte de GADM : `Far North` ou `Far-North` ?
  `North-West` ou `Northwest` ? Le `setdiff()` tranche.
- ACLED peut aussi coder des `admin1` que GADM ne connaît pas (découpage
  postérieur, orthographe alternative). Le compteur des orphelins l'affiche.

### 2.4 `scripts_formateurs.zip` — archive à inventorier

Le script source renvoie, à ses lignes 111, 114, 385 et 745, à trois fichiers :
`jour_09_formateur_acled_api.R`, `jour_09_formateur_ecmwf_api.R` et
`jour_09_formateur_gee_api.R`. **Aucun des trois n'est sur le disque** : ils sont
vraisemblablement dans `Tools_day_10_\scripts_formateurs.zip`, qui reste à
inventorier.

**Traitement retenu :** les renvois ont été **retirés** du matériel J10. Le
contenu utile (requête `acledR`, requête `ecmwfr`) a été conservé sous forme de
**blocs de référence `eval: false`** directement dans le `.qmd`, en tant que
trace de provenance — le participant voit d'où vient le fichier livré, sans
dépendre d'un script absent. La chaîne d'extraction Google Earth Engine, elle,
n'est plus référencée du tout : elle est simplement décrite en prose au module 6.

**À faire :** ouvrir `scripts_formateurs.zip` et arbitrer. Si les trois scripts
existent et sont exploitables, les placer dans `scripts/preparation/` avec un
en-tête « non exécutable en salle — trace de provenance », et rétablir les
renvois. Sinon, l'état actuel est le bon.

### 2.5 Autres hypothèses ponctuelles

- **`sae::mseFH()` sur un `data.frame`.** Le code convertit `sae_data` en
  `data.frame` (`as.data.frame()`) : `sae` n'accepte pas toujours un tibble.
  Repris du script source ; à confirmer à la première exécution.
- **`fh$est$fit$convergence` / `$iterations` / `$refvar`.** Ces trois champs sont
  supposés présents dans l'objet renvoyé par `mseFH()`. Le script source
  n'utilisait que `estcoef` et `goodness`. Si l'un des trois est absent, la ligne
  `cat()` correspondante échoue seule (le chunk est en `error: true`) : la
  supprimer suffit.
- **API tmap 4.** `tm_scale_continuous(value.na = , label.na = )`,
  `tm_dots(fill_alpha = )`, `tm_add_legend(type = "polygons")` : ce sont les
  formes de l'API 4. Avec tmap 3, **tous** les blocs cartographiques échouent —
  `install_packages_day.R` contrôle la version et avertit.
- **Séparateur des CSV.** Vérifié sur l'en-tête des quatre fichiers CSV : c'est
  la **virgule** pour les quatre. Le `.qmd` conserve malgré tout le contrôle
  `ncol(...) == 1`.

---

## 3. Le module 10 dépend de deux fichiers à contrôler

Le module 10 (accessibilité aux services : tampons 5/10/15 km, distances aux
districts sanitaires) est **conservé de l'ancien matériel** — c'est le seul
module qui relie la journée aux politiques publiques concrètes. Il repose sur
deux couches dont la présence dans `datasets/` conditionne son exécution :

| Fichier | Emplacement attendu |
|---|---|
| `DS.geojson` | `datasets/DS.geojson` |
| `gadm41_CMR_2.shp` + `.shx` + `.dbf` + `.prj` + `.cpg` | `datasets/` |

**Point de contrôle.** Vérifier la présence des deux couches avant la séance.
Si l'une manque, les cinq chunks `chunk-acces-*` de `demo_formateur_J10.qmd`
doivent repasser en `eval: false` et les blocs correspondants des scripts `.R`
redevenir des blocs de référence commentés, conformément à la règle §6.1 — et
la raison technique doit rester écrite dans le document. C'est aussi le module
le moins éprouvé de la journée : lire ses compteurs avec attention (nombre de
géométries réparées, effectifs après jointure, districts sans appariement).

**Deux corrections intégrées au code, à ne pas perdre :**

1. L'ancien code lisait les coordonnées des formations sanitaires dans
   `CMGC72FL.csv`. **Ce fichier ne contient aucune coordonnée** : ce sont les 130
   covariables contextuelles par grappe DHS. Le code d'origine était donc faux et
   aurait échoué même avec toutes les données présentes. La version réécrite
   utilise, faute de répertoire géolocalisé des structures de santé, le
   **centroïde de chaque district sanitaire** comme point de service approché —
   hypothèse explicitement énoncée et critiquée dans le texte.
2. L'ancien code interrogeait les champs `nom_ds` et `code_ds` de `DS.geojson`.
   Ces colonnes **n'existent pas** : le fichier porte `name` et `parentName`,
   préfixés. Le code réécrit imprime `names(districts)` avant tout usage et
   commente le piège.

**Décision alternative possible**, si les fichiers restent introuvables :
transposer le module à un découpage présent dans `datasets/` — par exemple les
départements `ADM_ADM_2` de `gadm41_CMR.gpkg`, déjà livré. La chaîne de code est
identique ; seul le nom de la couche change. C'est aussi le repli proposé dans
l'exercice 8.

---

## 4. Ménage sur le poste — commandes Windows

Commandes à passer depuis une invite de commandes placée dans le dossier de la
journée. **Faire un commit Git de sauvegarde avant toute suppression.**

```bat
cd "C:\Users\PROLOG\OneDrive\MES BUSINESS\atelier-r-spatial-iford-2026\pedagogie\J10_politiques_publiques"
```

### 4.1 Les trois anciens scripts de la racine — remplacés par `scripts\`

Les nouveaux scripts vivent dans `scripts\`. Les trois anciens, à la racine,
sont périmés : ils lisent `datasets/ecam5.dta`, `datasets/DS.geojson`,
`datasets/ACLED_Data.csv` et cinq fichiers déclarés absents.

```bat
del "script_formateur_J10.R"
del "script_etudiant_J10.R"
del "script_etudiant_J10_corrige.R"
```

*(Pour les archiver plutôt que les supprimer :)*

```bat
mkdir archive_ancien
move "script_formateur_J10.R"         archive_ancien\
move "script_etudiant_J10.R"          archive_ancien\
move "script_etudiant_J10_corrige.R"  archive_ancien\
```

### 4.2 Le `.Rhistory` versionné à tort

Un `.Rhistory` traîne dans ce dossier. C'est un artefact de session RStudio :
il n'a rien à faire dans le dépôt, et il fuite l'historique de commandes de la
machine qui l'a produit.

```bat
del ".Rhistory"
```

Puis ajouter, une fois pour toutes, dans le `.gitignore` de la racine du projet :

```
.Rhistory
.RData
.Rproj.user/
```

Et, s'il a déjà été committé :

```bat
git rm --cached "pedagogie/J10_politiques_publiques/.Rhistory"
```

### 4.3 Les fichiers ACLED aux anciens noms, s'ils traînent dans `datasets\`

Trois noms circulaient pour la même donnée. Un seul est désormais valable :
`acled_cameroon_export.csv`.

```bat
del "datasets\ACLED_Data.csv"
del "datasets\ACLED Data.csv"
del "datasets\ACLED_Cameroun_2017_2024.csv"
```

*(Si l'un de ces fichiers est en réalité l'export ACLED et que
`acled_cameroon_export.csv` manque, renommer plutôt que supprimer :)*

```bat
ren "datasets\ACLED_Data.csv" "acled_cameroon_export.csv"
```

### 4.4 Les données qui n'appartiennent plus à cette journée

Raisons techniques détaillées dans `datasets\LISEZMOI.md`, section « Ce qui ne
doit pas se trouver ici ». **Ne pas supprimer du magasin central** — ces
fichiers servent à d'autres journées : les retirer seulement de `datasets\`.

```bat
del "datasets\ecam5.dta"
del "datasets\eesi3.dta"
del "datasets\CMHR71FL.SAV"
del "datasets\CMIR71FL.SAV"
del "datasets\CMGC72FL.csv"
del "datasets\Pays_limitrophes_Cmr.*"
del "datasets\CMR_population_v1_0_admin_level2.csv"
del "datasets\CMR_household_v1_0_admin_level2.csv"
del "datasets\*Sentinel-2*"
```

### 4.5 Créer le dossier des scripts anglais archivés

Le multilingue est conservé pour les seules présentations. Les scripts `_en.R`
d'origine sont archivés, non maintenus.

```bat
mkdir archive_en
```

Puis y copier, depuis le dossier source, les deux scripts anglais du jour 09 :

```bat
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_10_\jour_09_shared\scripts_etudiants\jour_09_etudiants_applications_sociales_en.R" archive_en\
```

Y déposer également un `LISEZMOI.md` d'une ligne : *« Scripts anglais du
matériel d'origine (jour 09). Archivés, non maintenus, non alignés sur le
matériel J10 réécrit. »*

### 4.6 Les trois présentations

Elles existent en trois exemplaires chacune dans le matériel source
(`Tools_day_10_\`, `jour_09_shared\`, `jour_10_shared\jour_10_shared\`). N'en
copier **qu'un jeu** dans ce dossier :

```bat
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_10_\jour_09_shared\jour_09_applications_sociales.pptx" .
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_10_\jour_09_shared\jour_09_applications_sociales_en.pptx" .
copy "..\..\..\materiel-atelier-r-spatial-iford-2026-j08-j10\Tools_day_10_\jour_09_shared\jour_09_applications_sociales_fr_en.pptx" .
```

Ne **jamais** reprendre les fichiers commençant par `~$` : ce sont des verrous
PowerPoint.

---

## 5. Décisions restées ouvertes

1. **`slides.qmd`** (386 lignes) est resté à la racine. Il décrit l'ancien plan
   de journée (pauvreté multidimensionnelle ECAM5, déplacements forcés HCR) et
   ne correspond plus au contenu réécrit. À trancher : le réécrire sur les dix
   modules actuels, ou le supprimer au profit des trois `.pptx`. Il est laissé
   en l'état tant que l'arbitrage n'est pas rendu.
2. **Renommage des `.pptx`.** Ils s'appellent encore `jour_09_…` alors que la
   journée est J10. La cartographie recommande un renommage systématique en
   deux chiffres. Non fait : renommer un `.pptx` casse les liens éventuels dans
   l'agenda et les supports imprimés — à arbitrer avec l'équipe pédagogique.
   Si renommage il y a, harmoniser aussi le suffixe bilingue (`_fr_en` partout,
   le J08 disant `_bilingual`).
3. **Longueur du `.qmd`.** 3 450 lignes, au-delà de la fourchette de 2 000 à
   2 600 initialement visée. Le dépassement vient entièrement de la prose
   pédagogique exigée : un encadré d'interprétation en quatre temps après chaque
   figure, un glossaire en cinq domaines, huit exercices portant chacun un piège
   nommé. Aucune coupe n'a été faite pour tenir la cible, la règle §8 interdisant
   de supprimer du contenu sans raison technique. Si une réduction est souhaitée,
   la piste la moins coûteuse est de déplacer le glossaire dans un fichier
   `GLOSSAIRE_J10.md` séparé (environ 200 lignes).
4. **Tailles des fichiers de données.** Toutes marquées « n.d. » dans
   `datasets\LISEZMOI.md`. À relever côté poste et à arbitrer contre le budget de
   100 Mo par journée (règle §0.6). Le poste le plus lourd est probablement
   `era5_t2m_mensuel_cameroun.nc`, puis `benin_grille_3km.gpkg` (~15 400
   polygones).

---

## 6. Ordre recommandé des opérations

1. Ménage §4.1 à §4.4 (suppressions et `.Rhistory`).
2. `source("install_packages_day.R")` — prévoir du temps pour `sae` et `survey`.
3. `source("outils/distribuer_donnees.R")` depuis la racine du projet, puis
   vérifier que le chunk `chunk-inventaire` affiche **8/8**.
4. Contrôle de syntaxe des quatre `.R` par `parse()`.
5. Render du `.qmd`. Lire les compteurs, en particulier ceux listés au §2.
6. Corriger les noms de couches / de champs si les `st_layers()` le demandent —
   ce sont les seules lignes susceptibles d'échouer pour cause d'hypothèse.
7. Vérifier l'affichage du HTML (§5.3 des règles).
8. Décisions du §5.
