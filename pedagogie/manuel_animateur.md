# Manuel de l'animateur — Atelier IFORD × GDSG 2026

> Document interne, à l'usage exclusif de l'animateur (Ramesesse Dzita) et des co-formateurs du GDSG. Non distribué aux participants.

Ce manuel rassemble les conventions pédagogiques, les workflows d'animation et la check-list jour par jour pour les 10 journées de l'atelier régional R-Spatial (27 juillet – 7 août 2026, Yaoundé).

## 1. Public et posture

L'auditoire est constitué de **professionnels** — statisticiens d'Instituts Nationaux de Statistique, démographes IFORD, techniciens de ministères sectoriels (Santé, Éducation, Agriculture), chargés d'études d'ONG et d'organisations internationales. La majorité a une expérience confortable d'Excel et de Stata/SPSS ; presque aucun n'a manipulé R ni d'outil SIG.

La posture d'animation correspondante :

- Pas de condescendance. Le public sait déjà raisonner statistiquement, son apprentissage est **technique**, pas conceptuel.
- Référence systématique à des sources scientifiques (Pebesma 2018, Stevens 2015, Wickham 2014, etc.). Le matériel doit pouvoir être cité en bibliographie d'un rapport officiel.
- Exemples ancrés dans le réel camerounais (BUCREP, ECAM, EDS-MICS, RGPH 4). Aucun tutoriel générique copié d'un blog.
- Lecture critique des méthodes (top-down vs bottom-up, Mercator vs Gall-Peters) — ce sont des choix méthodologiques, pas des évidences.

## 2. Les trois acteurs en salle

| Acteur | Posture | Outils ouverts simultanément |
|---|---|---|
| **Animateur** (toi) | Projette, commente, exécute en live, anime la discussion | Deux écrans : (1) `slides.html` plein écran, (2) RStudio avec `demo.R` + console |
| **Participant équipé** | R + RStudio installés via `guide_installation.md`. Code en parallèle sur sa machine | RStudio sur le `.Rproj` cloné + `demo.qmd` HTML en référence |
| **Participant non équipé** | Wifi local, navigateur, rien d'autre. Cas systématique pour les participants venus en dernière minute ou bloqués par Windows | Runtime WebR en ligne : <https://dzita.github.io/atelier-r-spatial-iford-2026/> |

Le runtime WebR est le **filet de sécurité** non négociable. Aucun participant ne doit rester spectateur à cause d'un problème d'installation locale.

## 3. Convention « cinq fichiers par jour »

Chaque dossier `JXX_…/` est **autoportant** et contient les artefacts pédagogiques ci-dessous. Aucun jour ne déroge.

| Fichier | Format de sortie | Cible | Rôle |
|---|---|---|---|
| `slides.qmd` | revealjs HTML | animateur | Projeté en salle. Plan + théorie + références. **Zéro code R à taper.** |
| `demo.qmd` | HTML statique | participant équipé | Démonstration linéaire, explication courte avant chaque bloc R, distribuée rendue en HTML en fin de séance |
| `demo.R` | script R exécutable | animateur | Version courte du `demo.qmd`, projetée à droite et exécutée ligne par ligne en salle |
| `runtime.qmd` | live-html WebR | participant non équipé | Code R exécutable directement dans le navigateur, zéro install |
| `exercice.qmd` | HTML statique | participant | Énoncés Q1 à Q5 (micro-exercices en séance, 5–10 min chacun) + Q6 (devoir individuel du soir, ~30 min). Pas de solutions |
| `corrige.qmd` | HTML statique | participant | Solutions commentées Q1 à Q6. Distribué le **matin du jour suivant**, jamais le jour même |
| `install_packages_day.R` | script R | participant | Installation des packages **strictement nécessaires pour ce jour**. Utile pour les retardataires ou les participants qui n'ont pas exécuté `environnement_technique/install_packages.R` en amont |
| `README.md` | markdown | tous | Index local du jour : objectifs, déroulé horaire, données mobilisées, packages utilisés |

## 4. Conventions de rédaction du code

**Snake_case minuscule** pour tous les noms de variables R, de fichiers et de dossiers. Le préfixe `JXX_` (deux chiffres) est l'unique exception majuscule, pour garantir le tri alphabétique correct entre J09 et J10.

**Commentaires en français** pour les exemples camerounais et les explications pédagogiques. En anglais pour les concepts génériques réutilisables (typiquement les fonctions de `_commons/helpers/`).

**Convention « expliquer chaque commande »** : tout bloc R dans `demo.qmd` est précédé d'un paragraphe court (1 à 3 phrases) qui décrit ce que la commande fait, ce qu'elle attend en entrée, ce qu'elle produit en sortie. Cette convention ne s'applique pas à `demo.R` (script animation) ni à `runtime.qmd` (où la cellule WebR autorun est elle-même la démonstration).

**Citations bibliographiques** systématiques quand on touche aux méthodologies : `[@pebesma2018simple]` pour `sf`, `[@stevens2015disaggregating]` pour WorldPop top-down, `[@darin2023bottomup]` pour WorldPop bottom-up, etc. Toutes les clés sont dans `_commons/helpers/citations.bib`.

## 5. Préparation matérielle avant l'atelier (J-30 à J-1)

### 5.1 Logiciels sur la machine de l'animateur

| Logiciel | Version cible | Source | Pourquoi |
|---|---|---|---|
| R | ≥ 4.6.0 | <https://cran.r-project.org/> | Moteur d'exécution |
| RStudio Desktop | ≥ 2026.05 | <https://posit.co/download/rstudio-desktop/> | IDE |
| Quarto CLI | ≥ 1.9.38 | <https://quarto.org/docs/get-started/> | Rendu des `.qmd` + preview live |
| Git | ≥ 2.50 | <https://git-scm.com/downloads> | Versioning + déploiement |
| TinyTeX | dernière | `quarto install tinytex` | Rendu PDF des `demo.qmd` |
| QGIS LTR | ≥ 3.44 | <https://qgis.org/fr/site/forusers/download.html> | Inspection visuelle de données SIG |
| Docker Desktop (optionnel) | dernière | <https://www.docker.com/products/docker-desktop/> | Plan B environnement participants |

Sur la machine projecteur, installer en plus **un navigateur récent** (Firefox ou Chrome) pour ouvrir `slides.html` en plein écran et tester le runtime WebR.

### 5.2 Packages R à pré-installer

Lancer une fois depuis RStudio sur le projet ouvert :

```r
source("environnement_technique/install_packages.R")
source("environnement_technique/verification_setup.R")
```

`verification_setup.R` te dit ce qui manque. Refaire tourner jusqu'à ce que tout soit vert.

### 5.3 Datasets à pré-télécharger

Le wifi de l'IFORD peut être lent ou intermittent. Télécharger **avant** J1 :

| Dataset | Taille | Source | Destination locale |
|---|---|---|---|
| GADM Cameroun ADM0-3 | ~10 Mo | <https://gadm.org/download_country.html> (choisir Cameroon, GeoJSON) | `datasets/cameroun/admin_boundaries/gadm41_CMR_*.json` |
| BUCREP RGPH4 ADM officiel | ? | Contact direct via Pr Kuépié | `datasets/cameroun/admin_boundaries/CMR_adm3_BUCREP_*.gpkg` |
| WorldPop 2020 100m CMR unconstrained | ~150 Mo | <https://hub.worldpop.org/geodata/summary?id=49866> | `datasets/cameroun/population_grids/CMR_pop_WorldPop_top-down_100m_2020.tif` |
| WorldPop 2020 100m CMR constrained | ~30 Mo | <https://hub.worldpop.org/geodata/summary?id=24784> | `datasets/cameroun/population_grids/CMR_pop_WorldPop_top-down_constrained_100m_2020.tif` |
| GHS-POP 2020 R2023A 3" | ~3 Go (global) | <https://human-settlement.emergency.copernicus.eu/download.php?ds=pop> | Découper sur CMR avec `gdal_translate -projwin xmin ymax xmax ymin` |
| Meta HRSL CMR 2018 | ~50 Mo | <https://data.humdata.org/dataset/cameroon-high-resolution-population-density-maps-demographic-estimates> | `datasets/cameroun/population_grids/CMR_HRSL_Meta_30m_2018.tif` |
| EDS-MICS CMR 2018 clusters GPS | ~5 Mo | <https://dhsprogram.com/data/dataset/Cameroon_Standard-DHS_2018.cfm> (inscription + projet 24-48 h) | `datasets/cameroun/dhs_mics/CMGE71FL.shp` |
| EDS-MICS CMR 2018 KR/HR/IR | ~30 Mo | idem | `datasets/cameroun/dhs_mics/` |
| Google Open Buildings v3 (Cameroun) | ~1 Go | <https://sites.research.google/open-buildings/> | `datasets/cameroun/batiments/` |
| Sentinel-2 L2A sur zones pilotes | ~500 Mo / tuile | <https://browser.dataspace.copernicus.eu/> | `datasets/cameroun/teledetection/` |

**Astuce** : préparer une clé USB avec tous les datasets pour les distribuer en salle aux participants équipés — évite que 25 personnes téléchargent simultanément 150 Mo sur le wifi.

### 5.4 Tests J-7 (la semaine avant)

Exécuter chaque `demo.R` de J01 à J10 dans l'ordre, bout-en-bout. Noter warnings et durées. Cela donne une référence pour détecter une dégradation en salle (wifi, machine, version d'un package).

Re-rendre `quarto render` sur tout le projet `pedagogie/` pour s'assurer que toutes les compilations passent.

## 6. Workflow chronologique d'une journée

### 6.1 La veille (J − 1, au soir)

1. Ouvrir RStudio sur `atelier-r-spatial-iford-2026.Rproj`.
2. Exécuter `demo.R` du jour J ligne par ligne, vérifier qu'aucun téléchargement n'échoue, aucun package manquant.
3. Re-rendre `slides.html` et `demo.html` — test rapide d'ouverture dans le navigateur.
4. Vérifier que le runtime en ligne est à jour : <https://dzita.github.io/atelier-r-spatial-iford-2026/J0X_…/runtime.html>.

### 6.2 Matin du jour J (avant le démarrage)

1. Arriver 30 min en avance pour les vérifications matérielles.
2. Brancher le projecteur. Configurer deux fenêtres : `slides.html` en plein écran à gauche (touche `F`), RStudio à droite avec `demo.R` ouvert et la console agrandie en bas.
3. Tester le wifi de la salle — si insuffisant pour 25 participants, prévoir un point d'accès secondaire.
4. Distribuer aux participants l'URL du runtime en ligne et le chemin vers leur RStudio si équipés.

### 6.3 Pendant les phases théoriques

Tu projettes `slides.html`, tu commentes à voix haute. La touche `B` de revealjs active le tableau noir pour griffonner en direct. La touche `S` ouvre la vue speaker (notes + minuteur) sur ton écran personnel. La touche `?` liste tous les raccourcis. Aucun participant ne tape de code — c'est le moment de discuter les méthodologies.

### 6.4 Pendant les phases démo

Tu bascules sur RStudio à droite. Tu commentes **avant** chaque commande : ce qu'elle fait, ce qu'elle attend, ce qu'elle produit. Puis tu l'exécutes (Ctrl+Entrée). Tu laisses le résultat afficher pendant 5 à 10 secondes pour que tout le monde le voie.

Les participants équipés tapent en parallèle dans leur propre console. Les non équipés cliquent sur **Run code** dans la cellule correspondante du `runtime.qmd` en ligne.

À chaque carte produite, fais une pause de 30 secondes pour laisser les participants vérifier que leur sortie correspond à la tienne.

### 6.5 Pendant les micro-exercices (Q1 à Q5)

Tu projettes l'énoncé depuis `exercice.qmd` (HTML rendu ou via la slide qui pointe vers le numéro de question). Tu donnes 5 à 10 minutes en autonomie. Tu circules en salle, tu réponds aux questions individuelles.

Les solutions ne sont **pas** distribuées à ce stade. Si plusieurs participants bloquent au même endroit, fais une mini-correction en live au tableau plutôt que de pointer vers le corrigé.

### 6.6 Fin de journée

Tu projettes la slide « synthèse 5 idées-clés » de la partie 8 du diaporama. Tu distribues `exercice.qmd` Q6 (devoir individuel). Tu n'envoies **pas** `corrige.qmd` ce soir-là.

Re-render `demo.qmd` du jour si modifié en salle, distribuer le HTML aux participants par mail ou clé USB pour qu'ils puissent re-jouer le soir.

Remplir un mini-rapport quotidien dans `livrables_formateurs/rapports_quotidiens/J0X.md` (5 lignes : ce qui a marché, ce qui a coincé, ce qu'on garde pour demain).

### 6.7 Soir J chez les participants

Q6 à faire chez eux, ∼30 minutes. Les participants équipés utilisent RStudio + `demo.qmd` rendu en référence. Les non équipés utilisent le runtime WebR.

### 6.8 Matin J + 1 en salle

Avant d'attaquer la nouvelle journée, tu distribues le `corrige.qmd` de la veille (lien HTML). 10 minutes de discussion sur les solutions, focus sur les pièges fréquents. Puis enchaîner sur J + 1.

## 7. Raccourcis RStudio à connaître par cœur

| Raccourci | Action |
|---|---|
| `Ctrl + Entrée` | Exécuter la ligne courante |
| `Ctrl + Shift + Entrée` | Exécuter tout le chunk Quarto |
| `Ctrl + Shift + K` | Render le document courant |
| `Ctrl + Shift + N` | Nouveau script R |
| `Ctrl + Alt + I` | Insérer un chunk de code (dans `.qmd`) |
| `Alt + -` | Insérer `<-` |
| `Ctrl + Shift + M` | Insérer le pipe `|>` (R ≥ 4.1) |
| `Ctrl + L` | Nettoyer la console |
| `F1` sur une fonction | Aide |
| `F2` sur une fonction | Aller au code source |
| `Ctrl + Shift + F10` | Redémarrer R (utile entre deux modules) |

## 8. Comment ajouter une nouvelle journée (prototype J2)

1. Créer le dossier `pedagogie/J02_sf_CRS_vecteurs/`.
2. Y placer les sept artefacts obligatoires : `README.md`, `demo.qmd`, `demo.R`, `slides.qmd`, `runtime.qmd`, `exercice.qmd`, `corrige.qmd`.
3. **YAML standard à respecter** dans chaque fichier (modèles dans `J01_intro_R_pensee_spatiale/`) — notamment `toc-location: left` pour les `format: html`, et le format `revealjs` complet pour `slides.qmd`.
4. Ajouter l'entrée du module au menu navbar dans `pedagogie/_quarto.yml` :

   ```yaml
   - href: J02_sf_CRS_vecteurs/runtime.qmd
     text: "J2 · sf + CRS"
   ```

5. Dans `pedagogie/INDEX.md`, remplacer la ligne `_à venir_` du jour concerné par un vrai lien.
6. Si J2 introduit de nouveaux packages WebR (par ex. `lwgeom`, `s2`), les ajouter dans `webr.packages:` de `_quarto.yml`. Vérifier qu'ils sont disponibles sur <https://repo.r-wasm.org/> — sinon prévoir un substitut (cf. `tmap` exclu, remplacé par `ggplot2 + geom_sf`).
7. Si J2 introduit de nouvelles données légères (Shapefile, GeoJSON, CSV < 10 Mo), les déposer dans `_commons/data/` et les charger dans le runtime via `download.file("/_commons/data/<nom>", "<nom>", mode = "wb")`. Les données lourdes (WorldPop GeoTIFF ~150 Mo) restent **côté desktop uniquement**.
8. Commit + push. La GitHub Action redéploie automatiquement le runtime en ligne en 5 à 7 minutes.

## 9. Vocabulaire imposé

Cette terminologie doit être utilisée systématiquement dans les slides et la démo. Pas de variantes synonymes en cours d'atelier.

| Acronyme | Signification | Note |
|---|---|---|
| **RGPH** | Recensement Général de la Population et de l'Habitat | Pour le Cameroun = RGPH 4 (2026-2027) |
| **RGAE** | Recensement Général de l'Agriculture et de l'Élevage | À ne **jamais** confondre avec RGPH |
| **BUCREP** | Bureau Central des Recensements et des Études de Population | Producteur officiel du RGPH au Cameroun |
| **INS** | Institut National de la Statistique | Au Cameroun = INS Cameroun |
| **IFORD** | Institut de Formation et de Recherche Démographiques | Notre hôte |
| **GDSG** | Geospatial Data Science Group | Notre équipe |
| **CRS** | Coordinate Reference System | Système de coordonnées de référence |
| **EDS / DHS** | Enquête Démographique et de Santé | EDS-MICS = version DHS + MICS combinée |
| **MICS** | Multiple Indicator Cluster Survey | Programme UNICEF |
| **ECAM** | Enquête Camerounaise Auprès des Ménages | ECAM 4 est la dernière vague disponible |
| **WorldPop** | — | Université de Southampton, producteur des grilles 100 m mondiales |
| **GHSL** | Global Human Settlement Layer | Producteur : Joint Research Centre (Commission européenne) |
| **HRSL** | High Resolution Settlement Layer | Producteur : Meta + CIESIN |
| **NDVI** | Normalized Difference Vegetation Index | Co-variable raster pour les modèles bottom-up |
| **KDE** | Kernel Density Estimation | Pour J7 |
| **SAE** | Small Area Estimation | Pour J9 |
| **LISA** | Local Indicators of Spatial Association | Statistique de Moran locale (Anselin 1995) |
| **FAIR** | Findable, Accessible, Interoperable, Reusable | Principe d'ouverture des données scientifiques |

## 10. Top-down et bottom-up : complémentaires, pas concurrents

Convention non négociable : ne jamais présenter le bottom-up comme « mieux » que le top-down ou inversement.

| Critère | Top-down (WorldPop classique) | Bottom-up (méthode GDSG) |
|---|---|---|
| Référence méthodologique | Stevens et al. 2015, Tatem 2017 | Darin & Leasure 2023 |
| Hypothèse de départ | Un total connu à l'échelle nationale | Des micro-recensements géolocalisés |
| Opération centrale | Désagrégation par random forest | Agrégation bayésienne hiérarchique |
| Quantification incertitude | Faible (intervalle indirect) | Native (postérieures par pixel) |
| Cas d'usage | Pays disposant d'un recensement récent fiable | Pays sans recensement récent ou avec biais |
| Couverture mondiale | Oui, grille globale 100 m disponible | Non, à monter pays par pays |

## 11. Sécurités à respecter

**Licence DHS Program.** Le microfichier individuel DHS Cameroun 2018 est sous licence stricte : inscription + projet 24-48 h avant. On le simule en J1 (`hh_sim` via `set.seed(2026)`) pour ne dépendre d'aucune inscription externe. Si un participant a sa propre licence, il peut substituer le vrai fichier pour ses exercices personnels.

**Pas de redistribution GADM massive.** GADM v4.1 est gratuit pour usage académique mais sa licence interdit la redistribution. Les fichiers JSON dans `_commons/data/` sont sur le repo public — tolérable pour un usage pédagogique, à documenter dans le README si publié plus largement.

**Données BUCREP.** Les estimations de population régionale 2019 utilisées dans les exemples sont des **ordres de grandeur pédagogiques**, à actualiser dès que les premiers chiffres officiels du RGPH 4 seront publiés (probablement 2027). Mentionner systématiquement cette précision en salle.

## 12. Gestion du wifi en salle

- Tous les `.R` utilisent `_commons/helpers/fetch_data.R` qui s'arrête avec un message explicite si un fichier local manque — pas de téléchargement à l'aveugle pendant l'animation.
- En cas de coupure totale du wifi : tous les datasets sont déjà sur la clé USB préparée à l'étape 5.3. Distribuer la clé.
- Pour un participant avec un souci d'environnement persistant : le rediriger vers le **Posit Cloud** template (lien donné en J1) — contourne 80 % des problèmes locaux.
- Si le runtime en ligne ne charge pas : le rendu statique des `demo.qmd` permet quand même de lire le matériel ; les exercices peuvent être faits sur papier puis tapés plus tard.

## 13. Quand ça plante en live

| Symptôme | Cause probable | Réaction immédiate |
|---|---|---|
| Un package manque sur la machine d'un participant | Installation incomplète la veille | `install.packages("pkg")` dans la console + continuer. Si plus de 5 personnes : pause pour réinstallation collective. |
| Le projecteur perd le signal RStudio | Câble HDMI lâche | Rebrancher, continuer à voix haute. |
| Le wifi devient inutilisable pour le runtime en ligne | Saturation | Demander aux équipés de se passer du runtime, pool d'aide entre participants. |
| `sf` refuse d'ouvrir un Shapefile | Un des 4 fichiers (.shp/.shx/.dbf/.prj) manque | Vérifier le dossier source |
| `terra` crash sur un gros raster | Mémoire insuffisante | `terra::terraOptions(memfrac = 0.8)` ou découper l'emprise |
| Un téléchargement GADM échoue (404 sur le miroir UC Davis) | Serveur indisponible | Utiliser les fichiers locaux placés dans `datasets/cameroun/admin_boundaries/` via `fetch_gadm_cameroon()` qui les détecte automatiquement |
| `quarto preview` ne démarre pas après modif | Cache `.quarto/` corrompu | Supprimer `pedagogie/.quarto/`, relancer |
| Une carte `tmap` apparaît vide | Filtrage trop strict en amont | `nrow()` sur l'objet avant le plot, lire ensemble |
| Reproductibilité long terme | Versions de packages incertaines | `renv::snapshot()` à la fin du J10 — voir `environnement_technique/renv.lock` |

## 14. Ressources transverses dans le repo

- `_commons/helpers/fetch_data.R` — chargement systématique des datasets avec fallback local et messages d'erreur explicites.
- `_commons/helpers/theme_iford.R` — thème ggplot2 + tmap commun, palette IFORD (bleu primaire #0F4C81, or #C9A227, accent rouge #A8201A).
- `_commons/helpers/citations.bib` — bibliographie commune. Toute citation utilisée doit y être référencée.
- `_commons/styles/slides_revealjs.scss` — thème slides revealjs.
- `_commons/styles/runtime_quartolive.scss` — thème runtime WebR (navbar logo + filigrane).
- `_commons/img/logo-iford.jpg` — logo officiel IFORD utilisé partout.
- `_commons/data/` — datasets servis par le runtime WebR (GADM JSON ADM0–3 du Cameroun).

Pour la documentation technique détaillée de la stack Quarto (runtime local, déploiement en ligne, gotchas), voir [`environnement_technique/architecture_quarto.md`](../environnement_technique/architecture_quarto.md).

## 15. Mention de paternité et licences

Tout le code dans `pedagogie/` est diffusé sous **CC-BY 4.0** au nom du Geospatial Data Science Group de l'IFORD. Les datasets gardent leur licence propre (voir `datasets/README_donnees.md`). Les citations méthodologiques sont dans `_commons/helpers/citations.bib`.

## 16. Contact et co-formateurs

| Rôle | Nom | Contact |
|---|---|---|
| Lead technique IT, animateur principal J1–J10 | **Ramesesse Dzita** | ramondzita@gmail.com |
| Lead Coordinator | Dr Mathias Kuépié | — |
| Co-Lead études population | Pr Franklin Bouba Djourdebbé | — |
| Senior Researcher bottom-up | Edith Darin | — |
| Statistician IT & GIS | Jean Saturnin Alogo Samba | — |
| Junior Demographer-Statistician | Marcial Teda Soh Fossi | — |
