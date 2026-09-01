## ============================================================================
## SCRIPT ETUDIANT -- J02 : PENSER L'ESPACE : OU, ET POURQUOI LA ?
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Mardi 28 juillet 2026
##
## MODE D'EMPLOI. Les commentaires portent la consigne : lisez-les, puis
## ecrivez votre code aux emplacements marques ">>> A COMPLETER". Avancez
## section par section, en verifiant chaque resultat avant de continuer.
## Le corrige complet est distribue en fin de journee.
##
## Donnees : datasets/ (chemins relatifs). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
## ============================================================================

for (d in c("outputs/cartes", "outputs/processed"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)

## ----------------------------------------------------------------------
## Comment utiliser ce script
##
## Executez-le section par section (Ctrl+Entree sous RStudio), en verifiant
## chaque sortie avant de passer a la suivante. Ce dossier est autonome :
## les donnees sont dans datasets/, les sorties vont dans outputs/, et tous
## les chemins sont relatifs a ce dossier.
##
## Prealable, une seule fois : source("install_packages_day.R")
## ----------------------------------------------------------------------

for (d in c("outputs/cartes", "outputs/processed"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)


## ========================================================================
## 1.1 POURQUOI R POUR LES STATISTIQUES GÉOSPATIALES ?
## ========================================================================
## Un tableur sépare la donnée et la carte : on calcule d'un côté, on dessine
## de l'autre, et les deux divergent dès la première mise à jour. Un logiciel
## SIG classique réunit les deux, mais par des clics qu'on ne peut ni relire
## ni rejouer.
##
## R tient les deux bouts. Le même script importe l'enquête, la joint aux
## limites administratives, calcule l'indicateur et produit la carte — et il
## se relance à l'identique l'an prochain sur les nouvelles données. C'est
## cette reproductibilité qui intéresse un institut national de statistique.
##
## Aujourd'hui, vous n'avez rien à taper. Cette journée pose le vocabulaire
## de l'information géographique ; le formateur montre à quoi chaque notion
## ressemble en R. La pratique commence au J03.
##

## ========================================================================
## 1.2 LES PAQUETS DE LA FORMATION
## ========================================================================
## --- BLOC DE REFERENCE, NON EXECUTE ---
# # BLOC DE REFERENCE -- NON EXECUTE AU RENDU.
# # L'installation reelle se fait via install_packages_day.R, qui n'installe
# # que ce qui manque. Ce bloc sert a montrer le paysage des paquets du
# # geospatial en R, regroupes par usage.
# 
# # Verifier la version de R (>= 4.4.0 recommande)
# R.version.string
# 
# # --- Paquets de manipulation et visualisation des données ---------------
# install.packages(c(
#   "tidyverse",   # dplyr, ggplot2, tidyr, readr, forcats, lubridate...
#   "haven",       # Lire les fichiers SPSS (.sav) — données EDS/DHS
#   "readxl",      # Lire les fichiers Excel
#   "janitor",     # Nettoyage des noms de colonnes et données
#   "skimr",       # Résumés statistiques rapides
#   "gt",          # Tableaux de présentation professionnels
#   "patchwork"    # Composer plusieurs graphiques ggplot2
# ))
# 
# # --- Paquets géospatiaux -------------------------------------------------
# install.packages(c(
#   "sf",          # Simple Features : données vectorielles (polygones, points)
#   "terra",       # Rasters : images satellite, modèles d'élévation
#   "stars",       # Rasters spatio-temporels (séries Sentinel-2)
#   "tmap",        # Cartographie thématique (style SIG)
#   "leaflet",     # Cartes interactives web
#   "mapview",     # Visualisation rapide d'objets spatiaux
#   "ggmap",       # Fonds de carte dans ggplot2
#   "mapsf",       # Cartographie statistique (style INSEE/INED)
#   "rnaturalearth", # Limites administratives mondiales
#   "osmdata"      # Données OpenStreetMap
# ))
# 
# # --- Paquets d'analyse spatiale avancée (J07 et suivants) --------------
# install.packages(c(
#   "spdep",       # Dépendance spatiale, matrices de voisinage
#   "spatialreg",  # Modèles de régression spatiale
#   "gstat",       # Interpolation spatiale (krigeage)
#   "automap",     # Krigeage automatique
#   "exactextractr", # Extraction de statistiques raster/vecteur
#   "tidyterra"    # terra + tidyverse
# ))
# 
# # --- Vérification : lister les paquets chargés --------------------------
# paquets <- c("sf", "terra", "tmap", "tidyverse", "haven", "leaflet")
# sapply(paquets, requireNamespace, quietly = TRUE)
# # Résultat attendu : tous TRUE


## ========================================================================
## 1.3 STRUCTURE DE RSTUDIO ET ORGANISATION DU PROJET
## ========================================================================
## RStudio se divise en quatre panneaux : le script en haut à gauche, la
## console en bas à gauche, l'Environment en haut à droite, les fichiers et
## graphiques en bas à droite. Le réflexe à retenir : travailler par projet,
## pour que les chemins restent relatifs et que le dossier reste
## transportable d'un poste à l'autre.
##

## ========================================================================
## 2.1 LES TYPES D'OBJETS ESSENTIELS EN R
## ========================================================================
## En R, tout est un objet. Les types de base — vecteur, facteur, data.frame
## — sont le socle : **une donnée spatiale n'est rien d'autre qu'un
## data.frame avec une colonne en plus**, celle qui contient la géométrie.
## C'est l'idée centrale de la journée, et elle se voit dès la section 3.3.
##

## ========================================================================
## 2.2 IMPORT DES DONNÉES RÉELLES : LIRE UN CSV SANS SE FAIRE PIÉGER
## ========================================================================
## Les données de la formation sont réelles : estimations WorldPop de
## population et de ménages, par département. On les importe d'abord comme de
## **simples tableaux, sans géométrie** — pour voir précisément ce qui leur
## manque.
##
## Premier piège, et il est classique : les deux fichiers portent la même
## extension .csv mais n'utilisent pas le même séparateur. La population est
## en points-virgules, les ménages en virgules. read_csv() sur le premier
## renvoie une unique colonne, sans la moindre erreur.
##

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Population par departement (WorldPop, admin level 2) --------------
# ATTENTION : ce fichier est separe par des POINTS-VIRGULES, pas des virgules.
# read_csv() aurait renvoye une seule colonne. Toujours ouvrir un CSV
# inconnu dans un editeur de texte avant de l'importer.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Menages par departement (meme source, separateur VIRGULE) --------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Ce que ces tableaux contiennent -- et ce qui leur manque ----------
# names1 : le nom du departement. total : l'estimation.
# lower / median / upper / uncertainty : l'intervalle de credibilite,
#   car ces chiffres sont MODELISES, pas recenses.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Ce que skim() affiche. Une ligne par variable, et pour chacune : n_missing
## le nombre de valeurs absentes, mean et sd la moyenne et l'écart-type, p0 à
## p100 les quantiles — p50 étant la médiane — et un mini-histogramme en
## caractères. C'est le premier réflexe après tout import : en un coup d'œil,
## on repère une variable vide, une unité aberrante ou une distribution
## inattendue.
##
## Ce que ces chiffres sont vraiment. WorldPop ne recense pas : il modélise.
## D'où les colonnes lower et upper, qui encadrent l'estimation. Un chiffre
## de population n'est pas un fait, c'est une fourchette — et la section
## suivante montre que cette fourchette n'est pas la même partout.
##

## ========================================================================
## 2.3 MANIPULATION AVEC DPLYR : LA GRAMMAIRE DES DONNÉES
## ========================================================================
## dplyr propose six verbes qui couvrent l'essentiel du travail sur tableaux
## : filter (garder des lignes), select (garder des colonnes), mutate
## (créer), group_by et summarise (agréger), arrange (trier). L'opérateur |>
## les enchaîne, et le code se lit comme une phrase.
##
## Ces verbes fonctionneront à l'identique sur des données spatiales : c'est
## tout l'intérêt de sf.
##
# --- Joindre population et menages -------------------------------------
# Les deux tables partagent la cle 'id' ET le nom du departement.
    # largeur de l'intervalle, en % de l'estimation centrale

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Les 10 departements les plus peuples ------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Ces estimations sont-elles fiables ? ------------------------------
# Plus la marge est large, plus l'estimation est incertaine.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- La limite de ce tableau -------------------------------------------
# On sait CLASSER les departements, mais pas les SITUER : aucune colonne
# ne dit ou ils sont, ni meme a quelle region ils appartiennent.
# C'est precisement ce que la geometrie va apporter en section 4.1.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Ce que ce tableau dit — et ce qu'il ne peut pas dire. On classe les
## départements, on calcule des tailles de ménage, on repère les estimations
## les plus fragiles. Tout cela sans jamais savoir où se trouve un
## département, ni même à quelle région il appartient : aucune colonne ne le
## dit.
##
## C'est la limite propre aux données tabulaires. Elles répondent à « combien
## ? » et « lequel ? », jamais à « où ? » ni à « à côté de quoi ? ». Les deux
## dernières questions sont pourtant celles du démographe : un département
## dense entouré de départements denses ne raconte pas la même histoire qu'un
## îlot isolé. **La géométrie n'est pas un ornement ; c'est l'information
## manquante.**
##

## ========================================================================
## 2.4 VISUALISATION AVEC GGPLOT2
## ========================================================================
## ggplot2 construit un graphique par couches : les données, puis les
## correspondances entre variables et propriétés visuelles (aesthetics), puis
## la géométrie, l'échelle et le thème. Une carte n'est qu'un cas particulier
## de ce système — d'où la continuité avec la cartographie thématique de la
## section 4.
##

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Graphique 1 : les 15 departements les plus peuples ----------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Graphique 2 : l'incertitude croit quand la population baisse ------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Graphique 3 : taille moyenne des menages --------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Comment lire ces deux graphiques.
##
## Le premier est un simple classement : les quinze départements les plus
## peuplés, en milliers d'habitants. coord_flip() bascule les barres à
## l'horizontale, ce qui rend les noms lisibles — un réflexe de présentation,
## pas un choix statistique.
##
## Le second est plus intéressant. Chaque point est un département : sa
## population en abscisse, la marge d'incertitude de l'estimation en ordonnée
## — c'est-à-dire la largeur de l'intervalle lower–upper, exprimée en
## pourcentage de l'estimation centrale. Deux éléments techniques méritent un
## mot :
##
## - L'échelle logarithmique (scale_x_log10()) écrase les grands écarts. Sans
## elle, quelques départements très peuplés tasseraient tous les autres
## contre l'axe. Une graduation ne représente plus une addition mais une
## multiplication : de 100 à 1 000, puis de 1 000 à 10 000. - La courbe
## lissée (geom_smooth, méthode loess) ne teste aucune hypothèse et ne prédit
## rien. Elle suit le nuage localement pour rendre visible une tendance que
## l'œil peine à extraire d'un semis de points.
##
## La lecture est nette : **plus un département est peu peuplé, plus son
## estimation est incertaine.** C'est mécanique — un modèle dispose de moins
## de signal sur les zones rurales peu denses. Conséquence pratique pour un
## institut de statistique : une carte de population est plus fiable au sud
## qu'à l'est, et il faut le dire.
##
## Le troisième graphique, l'histogramme, compte les départements par taille
## moyenne de ménage. Le trait orange marque la médiane nationale. Un
## histogramme sert à voir la forme d'une distribution : une bosse unique,
## deux bosses — signe de deux populations distinctes — ou une longue traîne.
##

## ========================================================================
## 3.1 VECTEUR ET RASTER : LES DEUX FAMILLES DU GÉOSPATIAL
## ========================================================================
## Toute information géographique relève de l'une des deux familles. Le choix
## n'est pas esthétique : il détermine les outils, les opérations possibles
## et la façon de poser la question.
##
## | | Vecteur | Raster |
## | Forme | points, lignes, polygones | grille de pixels |
## | Exemples | grappes d'enquête, routes, limites administratives | image satellite, densité de population, altitude |
## | Ce qu'on y lit | des objets aux frontières nettes | un champ continu dans l'espace |
## | Attributs | une table, une ligne par objet | une valeur par pixel, par bande |
## | Paquet R | sf | terra |
## | Question type | « quelle est la population de ce département ? » | « quelle est l'humidité en ce point ? » |
##
## Un même phénomène change de famille selon l'usage : la population est un
## raster chez WorldPop (grille de 100 m) et un vecteur une fois agrégée par
## département.
##

## ========================================================================
## 3.2 SYSTÈMES DE RÉFÉRENCE DE COORDONNÉES (CRS)
## ========================================================================
## Un CRS définit comment un point de la Terre — une surface courbe — devient
## un couple de nombres sur un plan. C'est la notion critique du géospatial :
## deux couches dans des CRS différents ne se superposent pas, et tout calcul
## de distance ou de surface les mélangeant est faux, silencieusement.
##
## ----------------------------------------------------------------------
## Règle d'or des SIG
##
## Avant toute opération impliquant plusieurs couches :
##
## 1. Vérifier que toutes sont dans le même CRS — st_crs() pour lire,
## st_transform() pour convertir. 2. Pour le Cameroun : WGS84 (EPSG:4326)
## pour les données brutes et l'affichage ; UTM 32N (EPSG:32632) ou 33N
## (EPSG:32633) pour tout calcul de surface ou de distance.
##
## Un degré n'est pas une unité de longueur : calculer une superficie en
## EPSG:4326 donne un nombre sans signification.
##
## ----------------------------------------------------------------------


## ========================================================================
## 3.3 CHARGER ET EXPLORER DES DONNÉES VECTORIELLES : GADM
## ========================================================================

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Charger les limites administratives GADM 4.1 ----------------------
# GADM fournit 4 niveaux : 0=pays, 1=région, 2=département, 3=arrondissement


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Inspecter la structure d'un objet sf -----------------------------

# Nombre de régions

# Afficher les noms des régions

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Calcul de surfaces et centroïdes -----------------------------------
# Projeter en UTM zone 33N (EPSG:32633) pour des calculs précis en km2

# Centroïdes des régions (utiles pour placer des étiquettes)

# Tableau des régions et superficies

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Vérification des géométries ----------------------------------------

# Réparer si nécessaire
# cmr1 <- st_make_valid(cmr1)

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Le vocabulaire qui vient d'apparaître à l'écran.
##
## class(cmr1) renvoie "sf" "data.frame" — et c'est la révélation de la
## journée. Un objet spatial est un tableau ordinaire, avec une colonne
## supplémentaire nommée geometry. Tous les verbes dplyr appris en section
## 2.3 continuent d'y fonctionner.
##
## st_bbox() donne la boîte englobante : les quatre coordonnées du plus petit
## rectangle contenant la couche. Utile pour vérifier d'un coup d'œil qu'une
## donnée est bien là où on l'attend — un xmin négatif pour le Cameroun
## signalerait une erreur de signe sur la longitude.
##
## st_transform(cmr1, 32633) reprojette : les mêmes lieux, exprimés dans un
## autre système. On passe de degrés à des mètres, ce qui rend la surface
## calculable. st_area() sur des degrés aurait produit un nombre sans unité
## interprétable.
##
## st_centroid() réduit chaque polygone à son point d'équilibre, comme le
## centre de gravité d'une plaque découpée à sa forme. On s'en sert pour
## poser une étiquette ou pour mesurer des distances entre régions. Attention
## : le centroïde d'un territoire en croissant peut tomber en dehors de ce
## territoire.
##

## ========================================================================
## 3.4 LES DONNÉES GPS DE L'EDS : D'UN TABLEAU À DES POINTS
## ========================================================================
## L'EDS fournit les coordonnées de ses grappes dans un fichier séparé. Les
## rattacher à leur région administrative demande une jointure spatiale — la
## clé n'est pas un code partagé mais la position elle-même.
##
# Les fichiers DHS separent la GEOMETRIE et les ATTRIBUTS :
#   CMGE71FL.shp  -> les points (coordonnees des grappes)
#   CMGC72FL.csv  -> 130 covariables contextuelles, sans coordonnees
# La cle commune est le numero de grappe, DHSCLUST.
# ATTENTION : les coordonnees GPS EDS sont deplacees aleatoirement
#   (+/- 2 km en urbain, +/- 5 km en rural) pour proteger l'anonymat.

# --- 1. La geometrie : lire le shapefile -------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- 2. Les attributs : lire le CSV de covariables ---------------------

# Ce fichier n'a AUCUNE colonne de coordonnees : c'est le shapefile qui
# porte la position. Verifions-le :

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- 3. Recoller geometrie et attributs, par DHSCLUST ------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- 4. Jointure SPATIALE : dans quelle region tombe chaque grappe ? ---
# La cle n'est plus un identifiant, c'est la position elle-meme.

# Nombre de grappes par region et par milieu

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Premiere carte rapide avec tmap -----------------------------------

# Syntaxe tmap 4 : le remplissage est 'fill', le contour est 'col'.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Ce que cette carte apporte, qu'aucun tableau ne donnait. Les points ne
## sont pas répartis au hasard : ils se concentrent là où vivent les gens. On
## lit d'un regard l'armature urbaine du pays, le vide relatif de l'est
## forestier, la densité de l'ouest. Un tableau de 430 lignes ne montre rien
## de cela.
##
## La jointure spatiale, en une phrase. st_join(..., join = st_within) pose à
## chaque point la question « dans quel polygone suis-je ? » et rapatrie les
## colonnes du polygone gagnant. La clé n'est ni un code ni un nom : c'est la
## position. C'est l'opération que les logiciels statistiques classiques ne
## savent pas faire, et c'est pour elle qu'on vient au géospatial.
##
## Sa force pratique apparaîtra en section 4.3 : DHS découpe le pays en douze
## régions, GADM en dix. Aucune table de correspondance n'a été nécessaire —
## la géographie a tranché.
##

## ========================================================================
## 3.5  INTRODUCTION AUX DONNÉES RASTER : IMAGES SENTINEL-2
## ========================================================================
## Les images Sentinel-2 fournies couvrent le Cameroun au 26 juin 2026, en
## trois bandes : B08 (proche infrarouge, NIR), B11 (infrarouge moyen, SWIR)
## et True Color (composition RVB visible).
##
## Combiner deux bandes donne un indice. Le NDMI utilisé ici mesure
## l'humidité de la végétation : (NIR - SWIR)/(NIR + SWIR). Proche de 1, la
## végétation est bien alimentée en eau ; négatif, on est sur du sol nu ou du
## bâti. Ce type de calcul est repris en détail au J09, journée
## télédétection.
##

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Charger les 3 images Sentinel-2 -----------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Explorer les propriétés du raster ----------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Vérification d'alignement : les rasters doivent avoir le même CRS --

# Si différents CRS, reprojeter : b11 <- project(b11, crs(b08))

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Calcul de l'indice NDMI (Normalized Difference Moisture Index) ----
# NDMI = (NIR - SWIR) / (NIR + SWIR)
# Valeurs proches de 1 : végétation bien humidifiée
# Valeurs négatives : sol nu ou zones bâties

# Statistiques globales

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Visualisation rapide -----------------------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Rogner sur une région d'intérêt : masquer sur l'emprise GADM ------
# Reprojeter le shapefile dans le CRS du raster si nécessaire

# Rogner et masquer


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Sauvegarder le résultat -------------------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Décoder ce qui vient de s'afficher.
##
## Un raster est une grille de pixels ; chaque pixel porte une valeur
## mesurée. res() donne la taille d'un pixel au sol — la résolution. ext()
## donne l'emprise, nlyr() le nombre de couches, une par bande spectrale.
##
## Le satellite Sentinel-2 mesure la lumière renvoyée par le sol dans
## plusieurs longueurs d'onde, dont certaines invisibles à l'œil. B08 capte
## le proche infrarouge, que la végétation en bonne santé réfléchit
## massivement ; B11 capte l'infrarouge moyen, absorbé par l'eau contenue
## dans les feuilles.
##
## Le NDMI combine les deux : (B08 - B11)/(B08 + B11). Le résultat va de −1 à
## +1. Proche de +1, la végétation est bien alimentée en eau ; négatif, on
## est sur du sol nu, de la roche ou du bâti. La division normalise le
## rapport, ce qui rend deux images comparables même prises sous des
## éclairements différents — c'est tout l'intérêt de cette forme d'indice.
##
## crop() découpe sur une emprise rectangulaire, mask() met à NA tout ce qui
## tombe hors des frontières. Les deux vont ensemble : sans mask(), les pays
## voisins resteraient visibles dans les coins.
##
## Pourquoi cela compte pour un démographe. Le NDMI est une variable
## d'environnement disponible partout, y compris là où aucune enquête n'a été
## menée. C'est ainsi qu'on relie conditions de vie et milieu physique sur
## l'ensemble du territoire, et non sur les seuls points enquêtés.
##

## ========================================================================
## 4.1  JOINTURE DONNÉES STATISTIQUES × DONNÉES GÉOSPATIALES
## ========================================================================
## Voici le geste central du statisticien géospatial : rattacher une table
## d'indicateurs à des géométries pour en faire une carte.
##
## Attention à la distinction :
##
## - jointure attributaire — la clé est un identifiant partagé, ici un code
## administratif. C'est un left_join() ordinaire, la géométrie ne sert pas ;
## - jointure spatiale — la clé est la position elle-même (« quel département
## contient ce point ? »). C'est st_join(), vu au J03.
##
## La section 3.4 a déjà utilisé la seconde pour rattacher les grappes EDS à
## leur région. Ici, on utilise la première.
##

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Le probleme : la cle est un NOM, et les noms ne concordent pas ----
# La table de population n'a ni code ni coordonnees : seulement 'names1'.
# GADM ecrit les memes departements avec accents et orthographe officielle.

# Jointure naive, sur le nom brut :

# 11 departements perdus. Silencieusement : left_join ne previent pas.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- La solution : normaliser les libelles avant de joindre -----------
# On enleve les accents, la casse, la ponctuation et les mots de liaison
# ("et", "de", "du", "la", "le") qui varient d'une source a l'autre.

# Verification cote a cote sur les cas qui echouaient

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Jointure attributaire, sur la cle normalisee ---------------------
    # Projeter en UTM 32N AVANT de mesurer : une surface calculee en
    # degres n'a aucun sens (cf. regle d'or, section 3.2).


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Ce que la geometrie apporte au tableau ---------------------------
# La region etait absente du CSV : elle vient de GADM.

# Les 5 departements les plus denses


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Ce que la jointure vient de produire. Le tableau de population, aveugle
## jusqu'ici, dispose maintenant d'une géométrie. Trois choses en découlent
## immédiatement, et aucune n'était possible avant :
##
## - la superficie, mesurée sur la forme réelle du département — donnée qui
## ne figure dans aucun fichier ; - la densité, rapport de la population à
## cette superficie. C'est un indicateur spatial par construction : il
## n'existe pas sans géométrie ; - la région d'appartenance, héritée de GADM,
## qui permet enfin d'agréger.
##
## Densité et population ne racontent pas la même histoire. Un département
## vaste et peuplé peut être moins dense qu'un petit département moyennement
## peuplé. Le classement par densité que vous venez de voir n'est pas celui
## par population — et c'est la densité qui pilote les besoins en écoles, en
## centres de santé, en réseaux.
##
## Et la leçon de méthode. La jointure naïve a perdu 11 départements sur 58
## sans lever la moindre erreur. left_join() ne signale pas les non-
## appariements : il remplit avec NA. Compter les NA après chaque jointure
## est un réflexe qui sauve des analyses entières.
##

## ========================================================================
## 4.2 CARTOGRAPHIE THÉMATIQUE AVEC TMAP
## ========================================================================
## tmap est le paquet de référence pour produire des cartes publiables. Sa
## logique est celle de ggplot2 — des couches qu'on additionne — mais pensée
## pour les objets sf : tm_shape() désigne la couche, puis tm_polygons(),
## tm_dots() ou tm_borders() décrivent comment la dessiner.
##
## ----------------------------------------------------------------------
## Le code de cette section suit l'API de tmap 4. Si vous rencontrez du code
## plus ancien, les différences les plus visibles sont tm_scale_bar() devenu
## tm_scalebar(), l'argument col = de remplissage devenu fill =, et les
## palettes qui passent par tm_scale_intervals() ou tm_scale_categorical().
##
## ----------------------------------------------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Carte 1 : Densité de population par département ------------------
    # tm_scale_intervals remplace le couple style=/n=/palette= de tmap 3.
    # "brewer.yl_or_rd" : palette ColorBrewer, sure pour les daltonismes.

# Afficher la carte

# Sauvegarder en haute résolution

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Carte 2 : Taille des ménages par département ----------------------
    # le prefixe "-" inverse toujours la palette en tmap 4


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## --- La carte interactive — à exécuter en salle, pas dans ce document ---
## --- BLOC DE REFERENCE, NON EXECUTE ---
# # BLOC NON EXECUTE AU RENDU -- A LANCER EN DIRECT DANS RSTUDIO.
# #
# # tmap sait basculer la MEME carte en mode interactif : fond de plan,
# # zoom, et infobulle au clic sur chaque departement.
# #
# #   tmap_mode("view")
# #   carte_densite        # cliquer sur un departement affiche sa valeur
# #   tmap_mode("plot")    # repasser en statique
# #
# # POURQUOI CE BLOC N'EST PAS EXECUTE ICI.
# # Le mode "view" produit un widget leaflet autonome : il embarque dans le
# # HTML les 58 polygones GADM en pleine resolution, plus les bibliotheques
# # javascript de rendu (leaflet, georaster, geoblaze, mathjs, protomaps).
# # Le document passe alors de 0,4 Mo a plus de 17 Mo -- lourd a ouvrir, lourd
# # a diffuser, pour un interactif qui n'a d'interet qu'en direct.
# #
# # Si vous voulez malgre tout l'inclure dans un document diffuse, simplifiez
# # d'abord les geometries -- ce qui allege le widget sans rien changer a la
# # demonstration :
# #
# #   cmr2_leger <- sf::st_simplify(cmr2_pop, dTolerance = 500,
# #                                 preserveTopology = TRUE)
# 
# **Comment se lit une carte choroplèthe.** *Choroplèthe* — du grec *khōra*, le
# territoire, et *plēthos*, la quantité — désigne une carte où chaque unité
# administrative est coloriée selon la valeur d'un indicateur. Trois précautions
# s'imposent.
# 
# **Cartographier une densité, jamais un effectif brut.** Colorier un département
# selon sa population totale ne dit rien : les grands départements ressortent parce
# qu'ils sont grands. Il faut rapporter à la surface — ou à la population de
# référence pour un taux.
# 
# **Le découpage en classes change le message.** Deux méthodes sont employées ici :
# 
# | Méthode | Principe | Effet |
# |---|---|---|
# | `"jenks"` | cherche les **ruptures naturelles** du nuage de valeurs | fait ressortir les groupes réellement distincts |
# | `"quantile"` | met le **même nombre d'unités** dans chaque classe | garantit une carte contrastée, même sans contraste réel |
# 
# Les quantiles produisent toujours une belle carte — y compris quand les écarts
# sont dérisoires. Jenks respecte mieux la structure des données mais peut donner des
# classes très inégales. **Aucun des deux n'est neutre** : le choix des seuils est un
# acte d'interprétation, à assumer et à documenter en légende.
# 
# **La palette n'est pas décorative.** `brewer.yl_or_rd` est une palette
# *séquentielle* : elle va du clair au foncé dans une seule direction, pour une
# quantité qui croît. Elle reste lisible en niveaux de gris et pour les huit pour
# cent d'hommes atteints de daltonisme. Une palette à teintes multiples suggérerait à
# tort des catégories sans ordre.
# 
# **La carte interactive** superpose les mêmes données à un fond cartographique :
# on zoome, et cliquer sur un département affiche sa valeur. C'est un excellent
# outil d'exploration en salle — mais il n'a aucun intérêt figé dans un document,
# et il l'alourdit considérablement. Le bloc correspondant est donc fourni sans
# être exécuté : à lancer en direct dans RStudio.
# 
# 
# ## 4.3 Où, et pourquoi là ? Le paludisme chez l'enfant
# 
# Le fichier `CMGC72FL.csv` chargé en section 3.4 ne contient pas que des
# coordonnées : DHS y joint **130 covariables contextuelles** mesurées autour de
# chaque grappe — climat, végétation, densité de population, accès aux services,
# santé. Chaque grappe devient ainsi un point porteur d'un petit dossier
# géographique.
# 
# Prenons-en une que tout le monde comprend : la **prévalence du paludisme chez
# l'enfant**. La carte va poser une question ; c'est le titre de la journée.
# 
# ::: {.callout-warning}
# ## Le piège des valeurs manquantes déguisées
# 
# DHS code l'absence de mesure par des **valeurs sentinelles négatives** —
# `-9999` le plus souvent. Elles ressemblent à des données : `mean()` les avale
# sans broncher et renvoie un résultat parfaitement faux.
# 
# Le cas de `growing_season_length` est exemplaire : **cinq codes différents**
# (`-9999`, `-997`, `-809`, `-807`, `-801`) touchant **214 grappes sur 430**, soit
# la moitié du fichier. Une moyenne naïve donnerait une saison agricole de
# *moins 300 mois*.
# 
# **Règle** : après tout import, regarder le minimum de chaque variable. Une valeur
# aberrante y saute aux yeux.
# :::
# 
# ```{r}
# # --- Le piege, montre plutot que raconte -------------------------------
# covariables <- grappes_avec_region |> st_drop_geometry()
# 
# cat("Moyenne NAIVE de la saison agricole :",
#     round(mean(covariables$growing_season_length, na.rm = TRUE), 1), "mois\n")
# cat("Grappes concernees par un code sentinelle :",
#     sum(covariables$growing_season_length < 0, na.rm = TRUE), "sur",
#     nrow(covariables), "\n\n")
# 
# # --- Nettoyage : tout negatif est un code manquant ---------------------
# nettoyer <- function(x) ifelse(x < 0, NA, x)
# 
# paludisme_region <- covariables |>
#   filter(!is.na(NAME_1)) |>              # grappes hors polygone : ecartees
#   mutate(
#     prevalence = nettoyer(malaria_prevalence_2015),
#     aridite    = nettoyer(aridity_2015)
#   ) |>
#   group_by(NAME_1) |>
#   summarise(
#     n_grappes      = n(),
#     prevalence_moy = round(mean(prevalence, na.rm = TRUE) * 100, 1),
#     aridite_moy    = round(mean(aridite,    na.rm = TRUE), 1),
#     .groups = "drop"
#   ) |>
#   arrange(desc(prevalence_moy))
# 
# print(paludisme_region)

## Remarquez qu'aucune harmonisation de libellés n'a été nécessaire. C'est le
## bénéfice de la jointure spatiale de la section 3.4 : DHS découpe le pays
## en douze régions — il isole Douala et Yaoundé — là où GADM n'en compte que
## dix. Une jointure par nom aurait perdu les deux capitales économique et
## politique ; la jointure par position les a rattachées d'elles-mêmes au
## Littoral et au Centre.
##
# --- Carte choropleque : la question ----------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Le "pourquoi la ?" : croiser avec l'aridite -----------------------

# ggrepel ecarte les etiquettes qui se chevauchent ; sinon repli simple.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Ce que la carte dit, et ce qu'elle ne dit pas. Le Centre, l'Est et le Sud
## — forestiers, humides — dépassent 30 % de prévalence ; le Littoral et
## l'Extrême-Nord tombent sous 20 %. La relation avec l'humidité est nette,
## et l'explication est biologique : le moustique a besoin d'eau stagnante.
##
## Mais l'Ouest et le Nord-Ouest cassent la règle : humides, et pourtant les
## moins touchés du pays, sous 10 %. Une troisième variable manque à la carte
## — l'altitude. Au-dessus de 1 500 mètres, le parasite ne complète plus son
## cycle.
##
## C'est la leçon de la journée. **Une carte pose une question ; elle ne la
## résout pas.** Elle rend un motif visible, et c'est au statisticien d'aller
## chercher la variable qui l'explique — ce que nous ferons au J07 avec les
## statistiques spatiales.
##

## ========================================================================
## 4.4 SYNTHÈSE : UN TABLEAU DE BORD STATISTIQUE NATIONAL
## ========================================================================
## Dernière étape : réunir démographie, ménages, EDS et spatial dans une vue
## unique. C'est la démonstration de ce que R permet une fois les briques en
## place — et le point d'arrivée que la formation vise pour le J10.
##

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Resume national consolide -----------------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

# --- Carte finale annotee pour rapport ---------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J02_corrige.R)
# ......................................................................

## Ce que ce tableau de bord démontre. Quatre sources hétérogènes — limites
## administratives GADM, estimations WorldPop, grappes d'enquête EDS,
## imagerie Sentinel-2 — tiennent dans une seule vue, reliées par un unique
## fil : **la position**. Aucune n'a de clé commune avec les autres ; toutes
## se rejoignent dans l'espace.
##
## C'est la réponse à la question posée en ouverture, « pourquoi R pour le
## géospatial ». Ce tableau de bord n'est pas une image : c'est un script.
## L'an prochain, avec les données actualisées, la même commande le régénère
## à l'identique. Un montage fait à la main dans un logiciel de dessin serait
## à refaire entièrement.
##

## ========================================================================
## VOCABULAIRE DE LA JOURNÉE
## ========================================================================
## Les termes croisés aujourd'hui, en une ligne chacun. À garder sous les
## yeux pour les dix journées suivantes.
##

## --- Les objets ------------------------------------------------------
## | Terme | Ce que c'est |
## | Vecteur | des objets aux contours nets — points, lignes, polygones |
## | Raster | une grille de pixels, chacun portant une valeur mesurée |
## | Géométrie | la colonne d'un tableau qui contient la forme et la position |
## | Objet sf | un data.frame ordinaire plus une colonne geometry |
## | Centroïde | le point d'équilibre d'un polygone ; peut tomber hors de celui-ci |
## | Emprise (bounding box) | le plus petit rectangle contenant une couche |
## | Résolution | la taille au sol d'un pixel d'un raster |
##

## --- Le positionnement -----------------------------------------------
## | Terme | Ce que c'est |
## | CRS | la convention qui traduit un lieu de la Terre en deux nombres |
## | EPSG:4326 (WGS84) | coordonnées en degrés — le standard du GPS, pour afficher |
## | EPSG:32632 / 32633 | UTM 32N / 33N, coordonnées en mètres — pour mesurer |
## | Reprojeter | changer de CRS : mêmes lieux, autres nombres |
##

## --- Les opérations --------------------------------------------------
## | Terme | Ce que c'est |
## | Jointure attributaire | assembler deux tables par un identifiant partagé |
## | Jointure spatiale | assembler deux couches par leur position |
## | st_within | le critère « cet objet est à l'intérieur de celui-là » |
## | Découper / masquer | restreindre un raster à une emprise, puis à des frontières |
## | Indice normalisé | un rapport du type (A-B)/(A+B), comparable d'une image à l'autre |
##

## --- La représentation -----------------------------------------------
## | Terme | Ce que c'est |
## | Choroplèthe | carte où chaque unité est coloriée selon une valeur |
## | Palette séquentielle | dégradé à sens unique, pour une quantité croissante |
## | Jenks | découpage en classes suivant les ruptures naturelles des données |
## | Quantiles | découpage à effectifs égaux ; contraste garanti, parfois trompeur |
## | Densité | population rapportée à la surface — le premier indicateur spatial |
##

## --- À quoi sert l'espace, au fond -----------------------------------
## Trois choses qu'un tableau seul ne permet pas, et qui justifient toute la
## formation :
##
## 1. Situer — passer de « quel département » à « où, et à côté de quoi ». Le
## voisinage porte de l'information : un îlot de forte densité ne
## s'interprète pas comme une tache continue. 2. Rapporter à la surface —
## densités, taux par kilomètre carré, accessibilité. Ces indicateurs
## n'existent tout simplement pas sans géométrie. 3. Relier des sources sans
## clé commune — une enquête, une image satellite et un registre
## administratif n'ont aucun identifiant partagé. Ils ont la position.
##
## Et une quatrième, plus discrète : la carte fait apparaître des questions.
## Le paludisme de la section 4.3 ne s'explique pas par l'humidité seule ;
## c'est en regardant la carte qu'on s'aperçoit qu'il manque l'altitude. Un
## tableau de corrélations ne l'aurait pas suggéré.
##

## ========================================================================
## EXERCICE DU SOIR
## ========================================================================
## À faire chez soi, en reprenant le code de la journée — la correction est
## dans script_etudiant_J02_corrige.R.
##
## 1. Calculer la superficie exacte de chaque département en km², avec
## st_area(). Attention au CRS : projeter en UTM avant de mesurer. 2. Joindre
## ces superficies à depts et en déduire la densité de population. 3.
## Produire une carte choroplèthe de la taille des ménages par arrondissement
## — niveau administratif 3, gadm41_CMR_3.shp. 4. Exporter la carte en PNG
## haute résolution dans outputs/cartes/ — indice : tmap_save(..., dpi =
## 300).
##

## ========================================================================
## POUR ALLER PLUS LOIN
## ========================================================================
## Le module « Bien travailler avec l'intelligence artificielle » de la
## session 3 est détaillé dans module_IA_geospatial.md : méthode en quatre
## temps, règles d'or et exercices en binômes. Il s'applique à toutes les
## journées suivantes.
##
## Demain (J03) : l'univers vectoriel — sf en profondeur, jointures
## spatiales, et les premières cartes construites par les participants eux-
## mêmes.
##
