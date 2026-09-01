# J09 — Voir le territoire depuis l'espace : télédétection, bâti et inondations

**Atelier IFORD × GDSG 2026 · Mercredi 5 août 2026 · Yaoundé**

**Référents : E. Darin, M. Teda, R. Dzita · Support : R. Elandi**

> Numérotation conforme à l'agenda final du 23/07/2026 (J01 → J11, sur deux chiffres).

---

## La question de la journée

**Que peut-on mesurer d'un territoire quand on ne peut pas y aller ?**

Trois réponses, dans cet ordre, et elles ne se valent pas :

1. On mesure un **rayonnement** — c'est la physique du capteur (modules 1 et 2).
2. On mesure un **produit dérivé** que quelqu'un d'autre a fabriqué à partir de ce
   rayonnement — GHS-BUILT, Open Buildings, Copernicus EMS (modules 3 à 9). C'est
   confortable, et c'est là que se cachent les hypothèses qu'on n'a pas prises.
3. On **croise** deux produits indépendants et on regarde où ils divergent. C'est
   le module 7, et c'est le cœur de la journée : deux méthodes défendables donnent
   deux réponses différentes, et il faut savoir dire laquelle répond à quelle
   question.

La journée sort ainsi de la démonstration technique : elle enseigne comment lire un
produit satellitaire **avec ses hypothèses**, et comment publier un chiffre
d'exposition sans lui donner une autorité qu'il n'a pas.

---

## Progression par module

| # | Module | Ce qu'on y apprend | Données |
|---|---|---|---|
| 0 | Mise en place | `sf_use_s2(FALSE)`, CRS de mesure UTM 33N, inventaire des données avant tout calcul | — |
| 1 | Ce qu'un satellite mesure réellement | chaîne émission → fichier ; les **quatre** résolutions (spatiale, spectrale, temporelle, **radiométrique**) ; signatures spectrales ; où trouver les images | exposé + schéma |
| 2 | Les indices de différence normalisée | NDVI, NDBI, MNDWI : forme générale, ce qu'ils détectent, ce qu'ils confondent ; masquer le nodata avant de calculer | exposé + code `eval: false` |
| 3 | Du pixel au produit : GHS-BUILT | ce que « surface bâtie » veut dire exactement ; mosaïque des tuiles ; découpe nationale ; **contrôle de symétrie des millésimes** | 15 tuiles GHS-BUILT, `gadm41_CMR.gpkg` |
| 4 | Mesurer le bâti | national / ADM1 / ADM2 ; gain absolu contre croissance relative ; typologie en 4 profils ; **MAUP** et erreur écologique | idem |
| 5 | Cas réel : Yagoua 2024 | Copernicus EMS, `floodDepth`, ce qu'est une « classe de profondeur » ; fenêtre d'étude assumée | EMSR772 AOI01 |
| 6 | Compter les exposés | Open Buildings, **seuil de confiance 0,7 et sa sensibilité** ; hypothèse × 5 habitants ; ventilation par classe | `open_buildings_yagoua.gpkg` |
| 7 | **Deux méthodes, deux réponses** | bâtiments × 5 contre WorldPop 2024 ; pourquoi elles divergent en zone inondée ; une troisième méthode plus robuste | `cmr_pop_2024…tif` |
| 8 | Infrastructures | routes OSM (Overpass + repli local), `st_intersection` contre `st_filter`, longueur inondée par type | `routes_aoi01_yagoua.gpkg` |
| 9 | Généraliser | fonction `analyser_inondation()` (principe DRY) appliquée à AOI02 et AOI03 — et ce qui se passe quand la donnée ne suit pas | EMSR772 AOI02, AOI03 |
| — | Fin de journée | glossaire par domaine, récapitulatif des fonctions, 8 exercices, prolongements | — |

---

## Fichiers de ce dossier

| Fichier | Rôle |
|---|---|
| `README.md` | synthèse de la journée (ce fichier) |
| `demo_formateur_J09.qmd` | **source unique** de la journée : le code, ses sorties et toutes les interprétations |
| `install_packages_day.R` | installation des 9 paquets du jour, avec contrôle de version tmap ≥ 4 |
| `scripts/script_formateur_J09.R` | miroir exécutable du `.qmd` : même code, même ordre |
| `scripts/script_etudiant_J09.R` | trame à trous (66 marqueurs `>>> A COMPLETER`) |
| `scripts/script_etudiant_J09_corrige.R` | corrigé complet, distribué en fin de journée |
| `scripts/preparation/preparer_open_buildings_J09.R` | **non exécutable en salle** — trace de provenance du `.gpkg` des bâtiments |
| `scripts/preparation/preparer_routes_osm_J09.R` | **non exécutable en salle** — trace de provenance du `.gpkg` des routes |
| `datasets/LISEZMOI.md` | inventaire des données du jour, unité d'observation, pièges chiffrés |
| `_A_FAIRE_J09.md` | ce qui reste à vérifier côté poste avant la séance |
| `jour_08_teledetection.pptx` | présentation, **français** |
| `jour_08_teledetection_en.pptx` | présentation, **anglais** |
| `jour_08_teledetection_fr_en.pptx` | présentation, **bilingue** |
| `archive_en/` | scripts sources en anglais, **archivés, non maintenus** (voir ci-dessous) |
| `outputs/` | sorties produites par le code — se remplit à l'exécution |

### Multilingue : ce qui est maintenu et ce qui ne l'est pas

- Les **trois `.pptx` sont conservés** en français, anglais et bilingue. Ils
  restent nommés `jour_08_…` : ce sont des fichiers binaires reçus tels quels,
  et les renommer casserait le lien avec le matériel source.
- **Tout le reste de la journée est en français uniquement.** Les scripts `_en.R`
  du matériel source sont **archivés dans `archive_en/`** : ils ne sont ni
  maintenus, ni corrigés, ni alignés sur le `.qmd`. Les corrections décrites dans
  `_A_FAIRE_J09.md` n'y ont **pas** été portées. Ne pas les distribuer en salle.

### Comment remplir `datasets/`

Depuis la racine du projet (ouvrir `atelier-r-spatial-iford-2026.Rproj`) :

```r
source("outils/distribuer_donnees.R")
```

La liste exacte des fichiers attendus, avec leur unité d'observation, est dans
`datasets/LISEZMOI.md`. **Attention** : les archives GHS-BUILT sont chargées par
`list.files()` avec un motif, et non par un littéral `"datasets/<nom>"` — l'outil
de distribution ne peut donc pas les détecter automatiquement. Elles doivent être
copiées à la main ou ajoutées explicitement au manifeste. Voir `_A_FAIRE_J09.md`.

---

## Les pièges mis en scène

La journée n'illustre pas des bonnes pratiques dans l'abstrait : chaque piège est
un vrai défaut, présent dans le matériel ou dans les données, mis en scène avec son
garde-fou.

| Piège | Où | Ce qu'il produit si on ne le voit pas |
|---|---|---|
| **Millésime inexistant** | module 0 | le matériel source cherchait `GHS_BUILT_S_E2020` ; les données sont 2015 et 2025. `list.files()` renvoie un vecteur vide **sans erreur**, et l'échec apparaît dix lignes plus loin. |
| **Asymétrie de couverture des tuiles** | module 3 | 8 tuiles pour 2025, 7 pour 2015 dans le lot livré. Le bâti 2015 vaut `NA` là où la tuile manque, le « gain » y devient la totalité du bâti 2025, et la région ressort comme la plus dynamique du pays. |
| **Mesurer en degrés** | module 3 | `st_area()` sur EPSG:4326 renvoie des « degrés carrés ». Le tableau des trois projections rend la chose visible. |
| **Confondre gain et croissance** | module 4 | la croissance relative met mécaniquement les plus petites unités en tête de classement. |
| **MAUP** | module 4 | le même bâti agrégé à l'ADM1 ou à l'ADM2 ne donne pas la même dispersion — et la carte ne dit jamais laquelle on regarde. |
| **Discrétisation** | modules 4 et 7 | quantiles, intervalles égaux et Jenks racontent trois histoires du **même** tableau. |
| **« Surface bâtie » ≠ « surface urbanisée »** | module 3 | 3 % de part bâtie ne veut pas dire 3 % de population urbaine. |
| **« Classe de profondeur » ≠ relevé** | module 5 | les tranches EMS sont estimées par croisement avec un modèle de terrain, à une date donnée. |
| **Seuil de confiance** | module 6 | à 0,9 on perd les constructions légères — donc les plus vulnérables. Le biais n'est pas aléatoire. |
| **`st_join()` duplique** | module 6 | un bâtiment à cheval sur deux polygones compte deux fois ; tout ce qui est calculé ensuite se décale. |
| **Deux méthodes, deux réponses** | module 7 | comptage de centroïdes et pondération par fraction de cellule divergent sur des polygones étroits — dans des sens opposés. |
| **`st_filter` sur une ligne** | module 8 | une route de 8 km comptée entière pour 200 m d'inondation. |
| **Le zéro qui n'en est pas un** | module 9 | la couche Open Buildings ne couvre pas AOI02 ni AOI03 ; sans garde-fou, le tableau afficherait « 0 bâtiment touché » pour deux zones réellement inondées. |
| **Widgets interactifs** | modules 5 et 7 | `tmap_mode("view")` embarque les géométries dans le HTML : plusieurs dizaines de Mo. Passés en `eval: false`. |

---

## Avertissements sur la qualité des chiffres

**À lire avant de citer quoi que ce soit produit par cette journée.**

### La fenêtre de 5 × 5 km sur AOI01

L'AOI01 officielle de l'activation EMSR772 couvre environ **6 870 km²** et contient
plus de 400 000 bâtiments Open Buildings à confiance ≥ 0,7. Toutes les opérations
spatiales de la journée y deviendraient trop lentes pour une séance.

Le matériel travaille donc sur une **fenêtre ad hoc d'environ 5 × 5 km**, centrée
sur le secteur le plus densément inondé près de Yagoua — soit moins de **0,4 %** de
la zone officielle.

**Conséquence, à répéter en salle** : tous les chiffres des modules 5 à 8
(bâtiments, population, routes) portent sur cette fenêtre. Ils ne constituent
**pas** un bilan de l'inondation de Yagoua 2024, et ne doivent jamais être présentés
comme tels.

### L'hypothèse de 5 habitants par bâtiment

C'est un **paramètre**, pas une mesure. Trois raisons de s'en méfier :

- tous les bâtiments ne sont pas habités — dans une concession sahélienne, greniers,
  hangars et enclos comptent chacun pour un « bâtiment » ;
- la taille des ménages varie du simple au triple selon la région ;
- surtout, le facteur étant **constant**, la *part* de population touchée est
  rigoureusement égale à la *part* de bâtiments touchés : le facteur s'annule et
  n'apporte **aucune information** au pourcentage. Il ne fait qu'habiller un
  comptage de toits en langage démographique.

Le `.qmd` produit un tableau de sensibilité pour 3, 4, 5, 6 et 7 personnes par
bâtiment. C'est ce tableau qu'il faut montrer, pas le seul chiffre.

### Le seuil de confiance 0,7

Conventionnel, aligné sur la pratique des analyses humanitaires sur Open Buildings.
Ce n'est pas une propriété des données. Le `.qmd` publie la sensibilité du comptage
entre 0,5 et 0,9. Un résultat qui bascule entre 0,65 et 0,75 n'est pas un résultat.

### Les autres chiffres à ne pas citer hors contexte

| Chiffre | Pourquoi il ne se cite pas seul |
|---|---|
| gain de bâti 2015-2025 | dépend de la symétrie de couverture des tuiles (voir `_A_FAIRE_J09.md`) |
| croissance relative par unité | un seuil de 1 km² de bâti initial est déclaré ; sous ce seuil, le taux est un artefact du dénominateur |
| longueur de route inondée | dépend de la complétude d'OpenStreetMap sur la zone, elle-même corrélée à l'histoire des crises |
| part de bâtiments touchés | dépend du seuil **et** du prédicat spatial (centroïde ou empreinte) |
| AOI02 et AOI03 | non couvertes par la couche de bâtiments : leurs zéros ne sont pas des mesures |
| accord entre bâtiments × 5 et WorldPop | WorldPop utilise le bâti détecté comme covariable de désagrégation : les deux méthodes ne sont pas totalement indépendantes |

---

## Prolongements

**Vers le J10 — les données spatiales au service des politiques publiques.**
Cette journée produit des indicateurs d'exposition ; le J10 les met en face de
décisions. On y retrouve `exact_extract()` sur des rasters climatiques ERA5, la
jointure spatiale de points d'événements (ACLED) vers des polygones administratifs —
avec le même piège de MAUP —, et l'estimation en petits domaines, qui répond
précisément à la question laissée ouverte ici : que faire quand une unité
territoriale repose sur trop peu d'observations ?

**Vers le J11 — restitution et communication.**
Les cartes de cette journée sont des cartes de travail. Le J11 traite de leur mise
en forme pour un public non technique, et de la mention obligatoire des hypothèses
sous la carte : le seuil de 0,7, l'hypothèse × 5, la fenêtre de 5 × 5 km, la
définition GHS-BUILT de « bâti ». Une carte publiée sans ces mentions transporte
l'autorité visuelle du produit sans son incertitude.

**Au-delà de l'atelier.** Séries temporelles GHS-BUILT sur six millésimes (1975 à
2030) ; analyse de graphe sur le réseau routier pour mesurer la perte de
connectivité plutôt que la longueur inondée ; délimitation d'une inondation
directement sur du radar Sentinel-1 plutôt que consommation du produit EMS ;
calibrage du taux d'occupation sur le RGPH ou l'EDS, ventilé par région — c'est là
que cette journée rejoint le cœur du métier des participants.
