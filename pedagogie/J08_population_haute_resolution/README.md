# J08 — Compter chaque habitant : la grille de population

**Atelier IFORD × GDSG 2026 · Yaoundé**

**Référents : J.S. Alogo, M. Teda, R. Dzita · Support : R. Elandi**

> Journée bâtie sur le matériel `Tools_day_8\`
> (grilles WorldPop 2015/2025/2030 et tuiles GHS-POP 2025), en
> conservant de l'ancienne version le module conceptuel *bottom-up* /
> *top-down* et la désagrégation dasymétrique.
> Numérotation harmonisée : tous les fichiers et toutes les sorties sont en
> `J08`, jamais en `J8`.

---

## La question de la journée

> **Combien d'habitants dans ce quartier, ce bassin versant, ce rayon de 5 km
> autour de ce centre de santé ?**

Aucun recensement ne répond à cette question. Le recensement livre des effectifs
par **unité administrative**, et ces unités ne coïncident presque jamais avec le
territoire d'une décision : une aire de santé, une emprise d'inondation, un
périmètre de campagne vaccinale, un rayon de marche.

Une **grille de population** y répond : un raster dont chaque cellule de 100 m
porte un effectif estimé d'habitants, donc découpable selon n'importe quelle
forme. Le prix à payer structure toute la journée :

1. **Une grille est un modèle, pas une observation.** Personne n'a compté les
   habitants de la cellule ; un modèle a redistribué un total administratif sur
   des covariables.
2. **Deux grilles sérieuses ne donnent pas le même chiffre.** WorldPop et
   GHS-POP divergent, et le module 7 mesure l'écart région par région.

---

## Progression par module

| # | Module | Ce qu'on y fait | Données |
|---|---|---|---|
| 1 | **Du tableau à la grille** | jointure COD-PS ↔ GADM ADM1, **choix de clé `ADM1_FR` vs `ADM1_EN` démontré et compté**, contre-exemple avec la mauvaise clé | `cmr_admpop_adm1_2025.csv`, `gadm41_CMR.gpkg` |
| 2 | **Structure démographique** | ratio F/H (palette divergente), part des 0-14 ans, deux pyramides des âges comparées en parts | `cmr_admpop_adm1_2025.csv` |
| 3 | **Ouvrir une grille** | WorldPop 100 m : emprise, CRS, résolution, sens d'une cellule ; découpe nationale et discrétisation | `cmr_pop_2025…tif` |
| 4 | **Extraire un effectif** | Mfoundi 2015 / 2025 / 2030 ; `crop` + `mask` + `global` ; trois cartes à breaks communs | 3 rasters WorldPop |
| 5 | **Agréger et confronter** | `exact_extract()` par région, croissance régionale, **écart au total officiel écrit et cartographié**, cinq villes | WorldPop + CSV |
| 6 | **Densité, log et MAUP** | surfaces en UTM 33N, échelle log10, **MAUP et erreur écologique** sur deux mailles ADM1/ADM2 | ADM1 + ADM2 |
| 7 | **Deux grilles, deux réponses** | mosaïque des 7 tuiles GHS-POP, reprojection et son coût mesuré, comparaison WorldPop / GHS-POP / COD-PS | 7 tuiles GHS-POP |
| 8 | **Comment une grille est fabriquée** | *conservé de l'ancienne version* : bottom-up vs top-down, désagrégation dasymétrique — **exposé + code de référence non exécuté** | — |
| 9 | **Atelier** | dessiner sa zone (`mapedit`, non exécuté) ou écrire son emprise (repli exécutable), compter, comparer avec le voisin | WorldPop 2025 |

La journée se termine par un **glossaire par domaine**, un **récapitulatif des
fonctions clés**, **huit exercices** portant chacun un piège nommé, et les
**prolongements** vers le J09 et le J10.

---

## Fichiers de ce dossier

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `demo_formateur_J08.qmd` | **source unique** de la journée : le document Quarto complet, code et prose |
| `install_packages_day.R` | installe les 9 paquets du jour et vérifie `tmap ≥ 4` |
| `scripts/script_formateur_J08.R` | miroir exécutable du `.qmd` : même code, même ordre, mêmes commentaires |
| `scripts/script_etudiant_J08_corrige.R` | le même, en-tête adapté — **distribué en fin de journée** |
| `scripts/script_etudiant_J08.R` | trame à trous — **58 marqueurs `>>> A COMPLETER`** |
| `datasets/LISEZMOI.md` | inventaire vérifié des données du jour |
| `datasets/` | les 12 fichiers de données de la journée, à plat |
| `outputs/` | toutes les sorties (`J08_*.png`, `.csv`, `.gpkg`, `.tif`) — créé au premier lancement |

### Présentations

Les trois présentations sont conservées **dans les deux langues**, seule partie
multilingue maintenue de la journée :

| Fichier | Langue |
|---|---|
| `jour_08_population_haute_resolution.pptx` | français |
| `jour_08_population_haute_resolution_en.pptx` | anglais |
| `jour_08_population_haute_resolution_fr_en.pptx` | bilingue |

> Le suffixe d'origine était `_bilingual` pour cette journée et `_fr_en` pour le
> J09 et le J10 : il est **harmonisé en `_fr_en`**.

### `archive_en/`

Les scripts anglais du matériel source (`jour_07_etudiants_population_haute_resolution_en.R`)
sont **archivés, pas maintenus**. Ils sont déposés dans `archive_en/` pour
mémoire de provenance, et ne sont ni renumérotés, ni corrigés, ni exécutés.

Tout le reste de la journée — `.qmd`, scripts, README, LISEZMOI — est en
**français uniquement**. Les maintenir en deux langues supposerait deux `.qmd`
sources et six scripts dérivés au lieu de trois, pour une journée dont le
matériel change encore.

---

## Comment démarrer

Ce dossier est **autonome** : données dans `datasets/`, sorties dans `outputs/`,
chemins relatifs. On peut l'ouvrir seul, sans rien savoir du reste du dépôt.

1. Remplir `datasets/` une fois, depuis la racine du projet :

   ```r
   source("outils/distribuer_donnees.R")
   ```

2. Installer les paquets du jour, une fois :

   ```r
   source("install_packages_day.R")
   ```

3. Ouvrir `demo_formateur_J08.qmd` et cliquer **Render** — ou lancer
   `scripts/script_formateur_J08.R` section par section.

> **`tmap` doit être en version 4 ou supérieure.** Tout le code cartographique
> emploie l'API tmap 4 (`tm_raster(col.scale = ...)`, `tm_scale_intervals()`,
> `tm_legend()`, `tm_title()`). Avec tmap 3, **tous** les blocs cartographiques
> des modules 3 à 9 échouent. `install_packages_day.R` vérifie la version.

---

## Les pièges mis en scène

Chacun est **provoqué volontairement** dans le matériel, puis nommé et corrigé.

| Piège | Où | Ce qui le rend visible |
|---|---|---|
| **Échec silencieux de jointure** | module 1 | contre-exemple joué sur la mauvaise clé : aucune erreur R, seuls le compteur de `NA` et les polygones gris alertent |
| **Polygone sans donnée pris pour un zéro** | toutes les cartes | `na.value = "grey80"` posé partout, et écrit dans la légende |
| **Résolution lue en degrés pour des mètres** | module 3 | la résolution imprimée est en degrés alors que le nom du fichier annonce 100 m |
| **Reprojeter le raster au lieu du vecteur** | module 4 | la règle est écrite, et le module 7 mesure le coût quand on ne peut pas l'éviter |
| **Comparaison sans breaks communs** | module 4 | trois millésimes discrétisés sur la concaténation des trois, avec l'explication de ce qu'on verrait sinon |
| **Discrétisation qui raconte l'histoire** | modules 3 et 6 | quantiles / intervalles égaux / Jenks comparés explicitement (exercice 2) |
| **Surface calculée en degrés carrés** | module 6 | reprojection en UTM 33N et contrôle contre les 475 442 km² officiels |
| **Moyenne des densités prise pour la densité** | module 6 | les deux chiffres sont imprimés côte à côte — c'est le **biais de taille** |
| **MAUP** | module 6 | la même donnée à deux mailles, bornes de classes identiques |
| **Erreur écologique** | module 6 | énoncée en prose, et le module 2 en donne une application assumée (population scolarisable) |
| **Cellules de bordure comptées entièrement** | modules 5 et 9 | `global()` contre `exact_extract()` (exercice 4) |
| **« Validation » qui ne valide rien** | module 8 | agréger une grille top-down sur ses propres unités de calage est arithmétiquement exact et informativement vide |
| **Sentinelle nodata négative** | module 7 | comptée puis recodée en `NA` **avant** tout calcul |
| **Widget interactif dans un document distribué** | modules 3 et 9 | tous les `tmap_mode("view")` et `mapedit::editMap()` sont en `eval: false`, avec la raison écrite |

---

## Avertissement sur la qualité des chiffres

**Aucun effectif produit dans cette journée n'est un dénombrement.**

- Les grilles **WorldPop** et **GHS-POP** sont des redistributions modélisées de
  totaux administratifs sur des covariables de bâti. Elles n'observent la
  population nulle part.
- Le **COD-PS** lui-même est une **projection** à partir d'un recensement
  antérieur, ventilée administrativement. L'ancienneté du dernier recensement
  général domine toutes les autres sources d'incertitude.
- Le module 5 **calcule et affiche** l'écart entre le total WorldPop agrégé et le
  total officiel, au national et région par région ; le module 7 y ajoute
  GHS-POP. **Ces écarts doivent voyager avec tout chiffre cité.**

Règles à appliquer avant de publier un chiffre issu de cette journée :

1. Citer l'effectif **avec sa source, son millésime et son écart à la référence
   administrative** de la même zone. « 3,1 millions (WorldPop 2025 ; +4 % par
   rapport au COD-PS) » est honnête ; « 3,1 millions » ne l'est pas.
2. **Pour une unité administrative, préférer toujours le chiffre officiel.** Une
   grille ne remplace pas une source administrative là où celle-ci existe.
3. **Un effectif de petite zone est fiable en ordre de grandeur, pas en valeur.**
   Plus la zone est petite, plus le chiffre dépend de la répartition modélisée et
   moins il dépend du total recensé.
4. Si l'écart régional dépasse **10 à 15 %**, **ne pas citer les chiffres
   régionaux concernés** dans un document officiel — les traiter comme un
   résultat sur la qualité des sources, pas sur la population.

Le module 8 est en **exposé et code de référence non exécuté** : les covariables
(GHS-BUILT) et les données d'entraînement géolocalisées nécessaires à une vraie
désagrégation ne sont pas dans le `datasets/` de cette journée. La raison
technique est écrite dans le module lui-même.

---

## Prolongements

- **Vers le J09** — GHS-BUILT, la covariable qui fabrique GHS-POP, y est
  manipulée directement (16 tuiles, 2015 et 2025) ; la chaîne
  tuiles → `sprc()` → `mosaic()` → `project()` → `crop`/`mask` du module 7 y est
  reprise à l'identique ; et `exact_extract()` y devient décisif, sur des
  emprises d'inondation étroites où la pondération par fraction de cellule change
  vraiment le résultat.
- **Vers le J10** — l'estimation en petits domaines (Fay-Herriot) répond au même
  problème que la désagrégation, par l'autre bout ; l'avertissement
  « précision ≠ résolution » y prolonge directement le module 9 ; et le MAUP
  revient sur les données ACLED.
