## ============================================================================
## SCRIPT ETUDIANT -- J04 : LA TERRE EN PIXELS
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Jeudi 30 juillet 2026
##
## MODE D'EMPLOI. Les commentaires portent la consigne : lisez-les, puis
## ecrivez votre code aux emplacements marques ">>> A COMPLETER". Avancez
## section par section, en verifiant chaque resultat avant de continuer.
## Le corrige complet est distribue en fin de journee.
##
## Donnees : datasets/ (chemins relatifs). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
## ============================================================================

## --- Se placer dans le dossier de la journee --------------------------------
## Tous les chemins de ce script sont relatifs a CE dossier. Quarto s'y place
## automatiquement au rendu ; Rscript, non. On le fait donc explicitement, que
## le script soit lance depuis le dossier du jour, depuis pedagogie/ ou depuis
## la racine du projet.
.dossier_jour <- "J04_terre_en_pixels"
if (!dir.exists("datasets")) {
  for (.p in c(.dossier_jour,
               file.path("pedagogie", .dossier_jour))) {
    if (dir.exists(file.path(.p, "datasets"))) { setwd(.p); break }
  }
}
if (!dir.exists("datasets"))
  stop("Dossier datasets/ introuvable. Ouvrez atelier-r-spatial-iford-2026.Rproj, ",
       "lancez source('outils/distribuer_donnees.R'), puis relancez ce script.")
cat("Dossier de travail :", getwd(), "

")

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)

## ----------------------------------------------------------------------
## Comment utiliser ce script
##
## Executez-le section par section (Ctrl+Entree sous RStudio), en verifiant
## chaque sortie avant de passer a la suivante. Ce dossier est autonome :
## donnees dans datasets/, sorties dans outputs/, chemins relatifs.
##
## Prealable, une seule fois : source("install_packages_day.R")
## ----------------------------------------------------------------------

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)


## ========================================================================
## 1. MISE EN PLACE
## ========================================================================
## L'installation se fait une seule fois, via install_packages_day.R. Le bloc
## ci-dessous n'est là qu'à titre de référence — il n'est pas exécuté.
##
## --- BLOC DE REFERENCE, NON EXECUTE ---
# # BLOC DE REFERENCE, NON EXECUTE.
# # L'installation reelle : source("install_packages_day.R")
# install.packages(c("terra", "sf", "tidyverse", "haven", "readxl",
#                    "RColorBrewer", "viridis", "classInt",
#                    "exactextractr", "tmap"))


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## POURQUOI PAS library(raster) ?
## Le paquet 'raster' est l'ancetre de 'terra', du meme auteur. Il fonctionne
## encore, mais il masque des dizaines de fonctions de terra portant le meme
## nom -- extract(), crop(), area()... -- et l'on ne sait plus laquelle on
## appelle. On s'en tient a terra, et on ne charge 'raster' nulle part.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Où ce document cherche-t-il ses fichiers ?
##
## Tous les chemins sont relatifs à ce dossier : datasets/ pour les entrées,
## outputs/ pour les sorties. Quarto s'y place automatiquement au rendu.
##
## Nul besoin de setwd() — et c'est même à proscrire : un chemin absolu du
## type C:/Formation_GeoR/… casse dès qu'on change de poste, ce qui est
## précisément ce qu'on cherche à éviter en travaillant par projet RStudio.
##
## ----------------------------------------------------------------------


## ========================================================================
## 2.1 COMPRENDRE LES DONNÉES SENTINEL-2 AVANT DE LES OUVRIR
## ========================================================================
#Sentinel-2 est un satellite de l'Agence Spatiale Européenne (ESA) qui acquiert des images multibandes à haute résolution. Voici les bandes qui nous intéressent aujourd'hui 


## ========================================================================
## 2.2 CHARGEMENT DES RASTERS SENTINEL-2
## ========================================================================
# Données réelles du 26 juin 2026 pour le Cameroun

# --- Chemins vers les fichiers (adaptez à votre dossier) ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Chargement avec terra::rast() ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Vérification immédiate ---


# Exemple de sortie pour b08 :
# class       : SpatRaster
# dimensions  : 2743, 3421, 1  (nrow, ncol, nlyr) — lignes, colonnes, couches
# resolution  : 0.0000899, 0.0000899  (x, y) — en degrés (WGS84)
# extent      : 8.4956, 8.8032, 3.8611, 4.1078  (xmin, xmax, ymin, ymax)
# coord. ref. : WGS 84 (EPSG:4326)
# source      : ...B08_(Raw).tiff
# name        : 2026-06-26..._B08_(Raw)
# min value   : 0
# max value   : 8943

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## Décoder ce que terra vous annonce.
##
## | Ligne affichée | Ce qu'elle signifie |
## | dimensions | lignes × colonnes × couches — le nombre de pixels |
## | resolution | la taille d'un pixel au sol, dans l'unité du CRS |
## | extent | l'emprise : les quatre bords de l'image |
## | coord. ref. | le système de coordonnées |
## | min/max values | la plage des valeurs mesurées |
##
## La résolution est la notion qui change tout. À 10 m, un pixel couvre une
## maison ; à 1 km, il couvre un quartier entier. Elle fixe ce qu'on peut
## voir — et ce qu'on ne verra jamais, quel que soit le traitement appliqué
## ensuite.
##
## Attention à ce que la sortie affiche réellement : notre tuile est en
## degrés, avec une résolution d'environ 0,0013° — soit à peu près 150 m, et
## non les 10 m natifs de Sentinel-2. Elle a été rééchantillonnée au
## téléchargement. Le constater dès l'ouverture évite d'annoncer une
## précision qu'on n'a pas.
##
## Regardez aussi la plage de valeurs. Une bande Sentinel-2 brute monte à
## plusieurs milliers : ce ne sont pas des couleurs, ce sont des mesures de
## réflectance codées en entiers. C'est précisément pour cela qu'on ne peut
## pas les mélanger avec une image visuelle bornée à 255 — le point sur
## lequel bute la section 4.1.
##

## ========================================================================
## 2.3 EXPLORATION COMPLÈTE DES MÉTADONNÉES RASTER
## ========================================================================
# --- Dimensions spatiales ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Résolution spatiale ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Emprise géographique ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Système de coordonnées ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Statistiques des valeurs ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Nombre de pixels sans données ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Comparaison des propriétés B08 vs B11 ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 2.4 VISUALISATION DES IMAGES
## ========================================================================
# --- Visualisation rapide avec terra::plot() ---
# Bande NIR seule — palette de gris par défaut

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Bande B11 avec palette viridis ---

# --- Visualisation rapide avec terra::plot() ---
# Bande NIR seule — palette de gris par défaut

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Bande B11 avec palette viridis ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Image True Color (composition R-G-B) ---
# Pour afficher une image couleur, on indique les numéros de couche (1=R, 2=G, 3=B)

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Alternative : étirement histogramme (souvent meilleur pour Sentinel-2) ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Panneau multi-vues : 1 ligne, 3 colonnes ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 2.5 CHARGEMENT DES DONNÉES VECTORIELLES GADM (FRONTIÈRES CAMEROUN)
## ========================================================================
# GADM v4.1 fournit 4 niveaux pour le Cameroun :
#   Niveau 0 : pays (1 polygone)
#   Niveau 1 : régions (10 polygones)
#   Niveau 2 : départements (58 polygones)

# --- Chargement avec sf ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Inspection rapide ---

# Aperçu des colonnes disponibles
# [1] "GID_0" "NAME_0" "GID_1" "NAME_1" "GID_2" "NAME_2" "VARNAME_2"
#     "NL_NAME_2" "TYPE_2" "ENGTYPE_2" "CC_2" "HASC_2" "geometry"

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Carte rapide de contrôle ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Vérification du CRS ---
# Doit être 4326 (WGS84) — même projection que nos rasters Sentinel-2


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 3.1 DÉCOUPE (CROP) : RÉDUIRE L'EMPRISE SPATIALE
## ========================================================================
#La découpe (crop) réduit l'emprise d'un raster à un rectangle englobant une zone d'intérêt. C'est la première opération à faire pour alléger les fichiers avant tout traitement.

# Objectif : isoler une région spécifique du Cameroun

# --- Exemple 1 : Découpe sur le département du Mfoundi (Yaoundé) ---
# Isolons d'abord le département Mfoundi dans les données GADM

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Crop de la bande B08 sur l'emprise de Mfoundi ---
# terra accepte un objet sf directement !

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Visualisation de la découpe ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Exemple 2 : Découpe de toutes les bandes en une fois ---
# Très utile pour préparer un empilage (stack) cohérent

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Exemple 3 : decoupe par emprise personnalisee --------------------------
# PREMIER REFLEXE : savoir OU se trouve l'image avant de vouloir la decouper.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ne jamais coder une emprise en dur sans la confronter à l'image
##
## Une version antérieure de ce support zoomait sur Douala — emprise ext(9.3,
## 10.2, 3.7, 4.5) — en annonçant reprojeter « dans le CRS de b08, UTM 32N ».
## Deux affirmations fausses, et un plantage à la clé :
##
## | Affirmé | Réalité |
## | CRS du raster : UTM 32N | WGS 84 (EPSG:4326), en degrés |
## | Zone couverte : Littoral, Douala | 11,5° à 14,9° E — le sud-est du pays |
## | Résolution : 10 m | ≈ 0,0013° soit environ 150 m |
##
## L'emprise de Douala ne recoupe tout simplement pas l'image, d'où l'erreur
## [crop] extents do not overlap. La tuile fournie couvre l'Est et le Sud —
## région de Yokadouma, bassin de la Boumba.
##
## La parade : dériver la fenêtre de zoom de l'emprise réelle du raster,
## plutôt que de la saisir à la main. Le code s'adapte alors à n'importe
## quelle tuile.
##
## ----------------------------------------------------------------------

# --- Fenetre de zoom derivee de l'image elle-meme ---------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Et si l'emprise voulue etait dans un AUTRE CRS ? -----------------------
# Le cas general : on dispose de coordonnees en degres, le raster est projete
# (ou l'inverse). On ne compare jamais deux emprises de CRS differents.
#
# La bonne sequence : construire un POLYGONE, le reprojeter, puis decouper.
# terra::ext() seul ne porte aucun CRS -- c'est la source de l'erreur classique.

# Ici les deux CRS coincident, donc oui. Le detour reste la methode sure des
# que les CRS different.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 3.2 MASQUE (MASK) : CONSERVATION DE LA FORME RÉELLE D'UN POLYGONE
## ========================================================================
# Après crop (rectangulaire), mask suit exactement les contours du polygone

# --- Mask de B08 sur le département Mfoundi ---


# Note : terra::mask() attend un SpatVector, pas sf — on convertit avec vect()

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Comparaison visuelle crop vs mask ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Mask sur une région entière (exemple : Centre) ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Statistiques sur zone masquée ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## Pourquoi rééchantillonner. Deux rasters ne se combinent que s'ils
## partagent exactement la même grille : même résolution, même emprise, même
## origine, même CRS. Sentinel-2 fournit B08 à 10 m et B11 à 20 m —
## additionner les deux directement échoue.
##
## resample() reconstruit l'un sur la grille de l'autre. La méthode compte :
##
## - bilinear interpole entre les pixels voisins. C'est le bon choix pour une
## grandeur continue — réflectance, température, altitude. - near (plus
## proche voisin) recopie la valeur du pixel le plus proche. Obligatoire pour
## une variable catégorielle — un code d'occupation du sol : interpoler entre
## « forêt » (3) et « eau » (5) donnerait « 4 », c'est-à-dire rien du tout.
##
## Rééchantillonner n'ajoute jamais d'information. Passer une bande de 20 m à
## 10 m ne révèle aucun détail : cela fabrique quatre pixels là où il y en
## avait un. La précision réelle reste celle de la source la plus grossière —
## et c'est elle qu'il faut annoncer dans une publication.
##
## Le même raisonnement vaut pour notre tuile, déjà ramenée à ~150 m : aucun
## traitement ne lui rendra les 10 m d'origine.
##

## ========================================================================
## 3.3 RÉÉCHANTILLONNAGE (RESAMPLE) : HARMONISER LES RÉSOLUTIONS
## ========================================================================
## Sur les produits Sentinel-2 natifs, B08 est à 10 m et B11 à 20 m : leurs
## grilles sont incompatibles et l'addition échoue.
##
## ----------------------------------------------------------------------
## Dans notre tuile, les deux bandes ont déjà été ramenées à la même grille
## au téléchargement — le code ci-dessous le vérifie et l'affiche. Le
## rééchantillonnage y est donc sans effet, mais le geste reste indispensable
## : sur des bandes brutes, il conditionne tout calcul d'indice. On le
## conserve pour cette raison, et parce qu'il rend la vérification explicite.
##
## ----------------------------------------------------------------------

# Objectif : aligner la grille de B11 sur celle de B08.

# Verification des resolutions AVANT reechantillonnage

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Rééchantillonnage de B11 vers la grille de B08 ---
# Méthode bilinear : appropriée pour les valeurs de réflectance (données continues)

# Vérification APRÈS rééchantillonnage

# Les deux grilles etaient-elles deja identiques AVANT l'operation ?

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Comparaison visuelle avant/après ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 3.4 AGRÉGATION : RÉDUIRE LA RÉSOLUTION SPATIALE
## ========================================================================
#L'agrégation consiste à réduire la résolution d'un raster en regroupant des pixels voisins. Utile pour créer des données moins volumineuses ou pour correspondre à des données de moindre résolution.

# Objectif : reduire volontairement la resolution, pour alleger les calculs

# --- Agrégation par facteur 3 : 10m → ~30m ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Agrégation par facteur 10 : 10m → ~100m ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Agrégation par facteur 50 : 10m → ~500m (résolution MODIS) ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Comparaison multi-résolutions ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Agrégation avec d'autres fonctions statistiques ---
# Utile pour l'analyse d'occupation du sol (max = classe dominante)


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 3.5 EMPILAGE DE COUCHES (STACK) ET ARITHMÉTIQUE RASTER
## ========================================================================
# --- Création d'un stack multi-bandes ---
# On empile B08 et B11_resample (maintenant à la même résolution)

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Accès aux couches individuelles ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Normalisation : rapporter les valeurs entre 0 et 1 ---
# Les valeurs Sentinel-2 L2A varient de 0 à 10000
# Diviser par 10000 donne la réflectance réelle (0-1)


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Sauvegarde du stack ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 4.1 CALCUL DES INDICES SPECTRAUX À PARTIR DES BANDES RÉELLES
## ========================================================================
#Les indices spectraux combinent plusieurs bandes pour mettre en valeur une caractéristique du terrain (végétation, eau, zones brûlées, humidité du sol). Ils sont au cœur de la télédétection appliquée aux statistiques environnementales.


## ========================================================================
## 4.1.1 LE NDVI — ET POURQUOI IL N'EST PAS CALCULABLE ICI
## ========================================================================
## Le NDVI (Normalized Difference Vegetation Index) est l'indice le plus
## connu de la télédétection :
##
## > NDVI = (NIR − Rouge) / (NIR + Rouge) > > soit, pour Sentinel-2 : (B08 −
## B04) / (B08 + B04)
##
## Il repose sur un fait biologique simple : une feuille en bonne santé
## absorbe le rouge pour la photosynthèse et réfléchit massivement le proche
## infrarouge. Plus l'écart entre les deux est grand, plus la végétation est
## dense et active.
##
## ----------------------------------------------------------------------
## Pourquoi ce document ne calcule pas de NDVI
##
## Il faudrait la bande B04 (rouge, en réflectance). Nous ne disposons que de
## B08, B11 et de l'image True_color.
##
## La tentation est d'extraire le rouge de True_color — c'est ce que faisait
## une version antérieure de ce support. C'est faux, et l'erreur mérite
## d'être vue.
##
## | | B08 | True_color |
## | Nature | réflectance mesurée | composition visuelle |
## | Codage | entier 16 bits | entier 8 bits |
## | Plage de valeurs | ≈ 0 à 10 000 | 0 à 255 |
## | Traitement | brut | étiré pour l'œil humain |
##
## Les deux ne sont ni dans la même unité, ni sur la même échelle. Dans la
## fraction, b08 écrase le terme rouge : le résultat vaut presque 1 partout,
## et la grille de lecture habituelle — « au-dessus de 0,6, forêt dense » —
## ne signifie plus rien.
##
## Le calcul ne lèverait aucune erreur. Il produirait une carte plausible et
## fausse, ce qui est pire qu'un plantage.
##
## **Règle générale : ne jamais combiner deux bandes qui n'ont pas subi le
## même traitement radiométrique.** Pour un vrai NDVI, télécharger B04 sur
## Copernicus, même date et même emprise.
##
## ----------------------------------------------------------------------

## Calculons donc l'indice que nos données permettent réellement.
##

## ========================================================================
## 4.1.2 LE NDMI — L'HUMIDITÉ DE LA VÉGÉTATION
## ========================================================================
## B08 et B11 sont toutes deux des bandes de réflectance brute, issues de la
## même chaîne de traitement, dans la même unité et sur la même échelle. Les
## combiner est légitime.
##
## > NDMI = (NIR − SWIR) / (NIR + SWIR) > > soit, pour Sentinel-2 : (B08 −
## B11) / (B08 + B11)
##
## L'eau contenue dans les feuilles absorbe l'infrarouge moyen (B11) et
## laisse passer le proche infrarouge (B08). L'écart mesure donc la teneur en
## eau de la végétation — et non sa densité, que mesurerait le NDVI.
##
# --- Calcul brut -------------------------------------------------------------
# B11 a ete reechantillonne en section 3.3 pour aligner sa grille sur celle de
# B08 : deux rasters ne se combinent que s'ils partagent resolution et emprise.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- PIEGE : les bordures de nodata polluent l'indice ------------------------
# Le calcul brut sort exactement -1 et +1. Ces valeurs ne sont pas des mesures :
# elles apparaissent la ou une bande vaut 0 (bordure de tuile, pixel sans
# donnee). La fraction degenere alors en +/-1.
#
# Consequence pratique : quelques pixels de bord suffisent a etirer l'echelle
# de couleurs sur [-1, 1] et a aplatir toute la carte, ou l'essentiel du signal
# tient en realite entre -0.5 et 0.6.

# On les ecarte AVANT de calculer.


# Ou se situe vraiment la masse des valeurs ?

# Lecture :
#   >  0.3     vegetation bien alimentee en eau, zones humides
#   -0.3 a 0.3 vegetation moderement hydratee
#   < -0.3     vegetation seche, sol nu, bati

# On borne l'echelle sur les centiles, pas sur les extremes : une carte se lit
# sur la masse des valeurs, pas sur ses accidents.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Quatre indices qu'on confond souvent
##
## | Indice | Formule | Ce qu'il mesure | Calculable ici ? |
## | NDMI | (B08 − B11)/(B08 + B11) | eau dans la végétation | oui |
## | NDVI | (B08 − B04)/(B08 + B04) | densité de végétation | non — B04 absente |
## | NDWI (McFeeters) | (B03 − B08)/(B03 + B08) | surfaces en eau | non — B03 absente |
## | NBR | (B08 − B12)/(B08 + B12) | zones brûlées | non — B12 absente |
##
## Une version antérieure de ce support calculait « NDWI » et « NBR » avec
## exactement la même formule que le NDMI, en n'annonçant que des seuils
## différents. Trois noms pour un seul calcul : ce sont bien trois indices
## distincts, qui exigent des bandes différentes.
##
## Le J09, journée télédétection, reprendra ces indices avec un jeu de bandes
## complet.
##
## ----------------------------------------------------------------------


## --- Classer un indice continu ---------------------------------------
## Une carte en dégradé se lit mal quand il faut compter ou comparer.
## Découper l'indice en classes donne une carte catégorielle, plus directe à
## interpréter — au prix d'une perte d'information, et de seuils qu'il faut
## assumer.
##
# terra::classify() prend une matrice a 3 colonnes : de, a, valeur affectee.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 4.2 COMBINAISON RASTER-VECTEUR : EXTRACTION DE STATISTIQUES ZONALES
## ========================================================================
#L'extraction zonale permet de calculer des statistiques raster (moyenne NDMI, somme population) pour chaque unité administrative (polygones). C'est l'opération la plus utile pour les statisticiens des INS : on obtient des indicateurs environnementaux par département ou région.

## Les statistiques zonales, ou comment un raster devient un tableau. C'est
## l'opération qui relie la télédétection à la statistique publique : une
## image de plusieurs millions de pixels se résume en 58 lignes, une par
## département, prêtes à rejoindre n'importe quelle base d'indicateurs.
##
## Les deux méthodes ne donnent pas le même résultat, et c'est normal.
## terra::extract() retient un pixel si son centre tombe dans le polygone :
## un pixel est dedans ou dehors. exact_extract() calcule la fraction de
## chaque pixel réellement couverte et pondère en conséquence.
##
## L'écart est négligeable sur un grand département, sensible sur un petit,
## et important dès que la taille du pixel approche celle de l'unité mesurée.
## Règle pratique : plus les unités sont petites au regard de la résolution,
## plus il faut préférer exact_extract().
##
## La moyenne seule ne suffit d'ailleurs pas. stdev, min et max sont extraits
## en même temps ici, et c'est délibéré : un département à la moyenne modérée
## mais à l'écart-type élevé mélange des zones très sèches et très humides.
## Un chiffre unique l'aurait masqué.
##
# terra::extract() + exactextractr::exact_extract() — deux approches

# --- Méthode 1 : terra::extract() (simple et intégré) ---

# Renommer et joindre aux données GADM


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Méthode 2 : exactextractr::exact_extract() (plus précis pour les bords) ---
# Prend en compte les pixels partiellement couverts par le polygone
                 # de convertir vers l'ancien paquet raster

# Jointure avec les informations départementales


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 4.3 INTÉGRATION DES DONNÉES DE POPULATION — WORLDPOP
## ========================================================================
# Objectif : calculer NDMI moyen pondéré par la population

# --- Chargement des données de population ---
#pop_data <- readr::read_csv("datasets/CMR_population_v1_0_admin_level2.csv")
#menage_data <- readr::read_csv("datasets/CMR_household_v1_0_admin_level2.csv")


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- PIEGE 1 : les nombres sont stockes en TEXTE dans le fichier Excel -------
# glimpse() ci-dessus le montre : total, lower et upper sont des <chr>, pas des
# <dbl>. Toute arithmetique dessus echouerait ou coercerait en silence.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- PIEGE 2 : les libelles ne concordent pas entre WorldPop et GADM --------
# WorldPop ecrit sans accents ("Benoue", "Nyong et Soo"), GADM avec l'ortho-
# graphe officielle ("Bénoué", "Nyong et So'o"). Une jointure naive perd
# 11 departements sur 58, SANS lever la moindre erreur : left_join() remplit
# avec NA. C'est le meme piege qu'aux J02 et J03.

# Verifions d'abord l'ampleur du probleme

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Jointure sur cle normalisee -------------------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- NDMI pondere par la population -----------------------------------------
# La moyenne simple traite un departement de 50 000 habitants comme un
# departement d'un million. Ponderer par la population repond a une autre
# question : quelle humidite pour l'habitant MOYEN du pays ?

# L'ecart entre les deux mesure la correlation entre humidite et peuplement.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Carte thematique : NDMI moyen par departement ---------------------------

# plot.sf attend soit UNE couleur, soit autant de couleurs que d'entites.
# Passer 5 couleurs pour 58 departements declenche un avertissement et un
# rendu incoherent : on fournit une fonction de palette, et sf s'en debrouille.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## 4.4 INTÉGRATION DES DONNÉES DHS GÉOLOCALISÉES
## ========================================================================
# Objectif : associer les valeurs NDMI aux clusters d'enquête DHS

# --- Chargement du shapefile des clusters DHS ---

# Aperçu des colonnes

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Alignement des CRS ---

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Extraction du NDMI au niveau des clusters DHS ---
# terra::extract() pour données ponctuelles : renvoie la valeur du pixel

# Jointure avec les données DHS


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Chargement des données SPSS DHS ---

# Variable cluster pour la jointure (v001 = numéro de cluster dans les données DHS)


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Jointure DHS géo + NDMI + données femmes ---
# La variable DHSCLUST dans CMGE71FL.shp correspond à v001 dans CMIR71FL.SAV


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

# --- Visualisation : carte des clusters DHS colorés par NDMI ---


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J04_corrige.R)
# ......................................................................

## ========================================================================
## VOCABULAIRE DE LA JOURNÉE
## ========================================================================

## --- L'objet raster --------------------------------------------------
## | Terme | Ce que c'est |
## | Raster | une grille régulière de pixels, chacun portant une valeur mesurée |
## | SpatRaster | l'objet raster de terra — l'équivalent de sf pour le vecteur |
## | Résolution | la taille d'un pixel au sol ; fixe ce qu'on peut voir |
## | Emprise (extent) | les quatre bords de l'image |
## | Bande (layer) | une couche de mesure ; une image multispectrale en empile plusieurs |
## | Réflectance | la part de lumière renvoyée par le sol — une mesure, pas une couleur |
##

## --- Les opérations --------------------------------------------------
## | Terme | Ce qu'elle fait | À savoir |
## | crop | découpe sur une emprise rectangulaire | rapide — toujours en premier |
## | mask | met à NA hors d'un polygone | lent — toujours après crop |
## | resample | reconstruit un raster sur la grille d'un autre | bilinear si continu, near si catégoriel |
## | aggregate | regroupe n × n pixels en un seul | réduit la résolution, allège les calculs |
## | classify | découpe une variable continue en classes | les seuils sont un choix, à documenter |
## | extract | statistiques zonales par polygone | pixel dedans/dehors selon son centre |
## | exact_extract | idem, en pondérant les pixels de bord | préférable sur les petites unités |
##

## --- Les indices spectraux -------------------------------------------
## Un indice combine deux bandes sous la forme (A − B) / (A + B). La
## normalisation rend deux images comparables même prises sous des
## éclairements différents.
##
## La condition absolue : les deux bandes doivent avoir subi **le même
## traitement radiométrique**. Mélanger une réflectance brute et une image
## visuelle étirée produit un nombre, jamais un indice.
##

## --- À quoi sert le raster -------------------------------------------
## Le vecteur décrit des objets aux contours nets ; le raster décrit un champ
## continu. D'où quatre usages que le vecteur ne couvre pas :
##
## 1. Mesurer là où personne n'est allé. Une enquête ne couvre que ses
## grappes ; un satellite couvre tout le territoire, y compris les zones
## inaccessibles. 2. Remonter dans le temps. Les archives Sentinel et Landsat
## permettent de comparer deux dates sur la même emprise — impossible avec
## des enquêtes ponctuelles. 3. Produire des covariables environnementales.
## Humidité, température, végétation, altitude : autant de variables
## explicatives disponibles partout, à croiser avec les indicateurs
## démographiques. 4. Descendre sous l'unité administrative. Un raster de
## population à 100 m ne s'arrête pas aux frontières des départements — c'est
## le sujet du J08.
##
## Et la leçon transversale de la journée : **un raster est une mesure, pas
## une image**. Le confondre avec une illustration conduit exactement à
## l'erreur du NDVI de la section 4.1.
##

## ========================================================================
## 5.1 EXERCICES GUIDÉS
## ========================================================================
## À faire en binômes, sur les données réelles de la formation. Chaque binôme
## présente ses résultats en cinq minutes. Comptez dix à quinze minutes par
## exercice.
##
## ----------------------------------------------------------------------
## Avant de choisir une zone d'étude, vérifiez ce que l'image couvre
##
## Notre tuile s'étend de 11,5° à 14,9° de longitude et de **2,5° à 5,8° de
## latitude : elle couvre l'Est et une partie du Sud**, autour de Yokadouma.
##
## Elle ne contient pas l'Adamaoua (au nord de 6°), ni le Littoral, ni le
## Nord, ni l'Ouest. Un crop sur ces régions échouera avec [crop] extents do
## not overlap.
##
## C'est la première vérification de tout travail raster :
## terra::ext(mon_raster), et comparer avec la zone visée.
##
## ----------------------------------------------------------------------

## --- BLOC DE REFERENCE, NON EXECUTE ---
# # ============================================================================
# # EXERCICE 1 -- Humidite de la vegetation dans la region de l'EST
# # ============================================================================
# # a) Isoler la region de l'Est dans cam_regions
# # b) Calculer le NDMI moyen et son ecart-type sur cette region
# # c) Quelle part de la superficie depasse un NDMI de 0.2 ?
# # d) Produire une carte zoomee, frontieres departementales superposees
# 
# # a) Isoler la region  (indice : NAME_1 == "Est")
# # est <- cam_regions[cam_regions$NAME_1 == ___, ]
# 
# # b) Decouper PUIS masquer -- crop d'abord, c'est bien plus rapide
# # ndmi_est <- terra::crop(ndmi, terra::vect(est)) |>
# #             terra::mask(terra::vect(est))
# # stats_est <- terra::global(ndmi_est, fun = c("mean", "sd"), na.rm = TRUE)
# # print(stats_est)
# 
# # c) Proportion de pixels au-dessus du seuil
# # humide     <- ndmi_est > 0.2
# # prop       <- terra::global(humide, "sum", na.rm = TRUE) /
# #               terra::global(!is.na(ndmi_est), "sum")
# # cat("Part de surface humide :", round(prop * 100, 1), "%\n")
# 
# # d) Carte
# # terra::plot(ndmi_est, main = "NDMI — region de l'Est",
# #             col = colorRampPalette(c("#A0522D","#F5DEB3","#006994"))(256))
# # plot(sf::st_geometry(cam_depts[cam_depts$NAME_1 == "Est", ]),
# #      add = TRUE, border = "grey20")
# 
# # ============================================================================
# # EXERCICE 2 -- Comparer plusieurs departements
# # ============================================================================
# # Les regions entierement couvertes par la tuile sont rares : on descend donc
# # au departement. Choisissez-en trois dans l'Est ou le Sud, et produisez :
# #   | Departement | NDMI_moyen | NDMI_sd | Surface_km2 |
# #
# # Verifiez d'abord lesquels sont couverts :
# # couverts <- cam_depts[!is.na(
# #   terra::extract(ndmi, terra::vect(cam_depts), fun = mean, na.rm = TRUE)[, 2]
# # ), c("NAME_1", "NAME_2")]
# # print(sf::st_drop_geometry(couverts))
# #
# # Puis iterez -- boucle for() ou purrr::map_dfr().
# # Attention : mesurer une surface exige un CRS metrique. Projetez avant
# # st_area(), sinon le resultat est en degres carres, sans signification.
# 
# # ============================================================================
# # EXERCICE 3 -- Carte de synthese avec tmap
# # ============================================================================
# # Carte du NDMI moyen par departement, avec titre, legende, echelle, flèche
# # nord, frontieres regionales superposees et grappes EDS en surimpression.

## --- BLOC DE REFERENCE, NON EXECUTE ---
# library(tmap)
# tmap_mode("plot")  # mode statique, pour export
# 
# # Données : carte_ndmi (objet sf avec NDMI_moy, créé en section 4.3)
# 
# # Squelette a completer -- syntaxe tmap 4.
# # Rappel des differences avec tmap 3, que vous croiserez dans du code ancien :
# #   tm_fill("var", palette=, style=, n=)  ->  tm_polygons(fill = "var",
# #       fill.scale = tm_scale_intervals(style =, n =, values =))
# #   tm_layout(title = )                   ->  tm_title()
# #   tm_scale_bar()                        ->  tm_scalebar()
# #
# # ma_carte <-
# #   tm_shape(carte_ndmi) +
# #     tm_polygons(
# #       fill        = "NDMI_moy",
# #       fill.scale  = tm_scale_intervals(style = "quantile", n = 5,
# #                                        values = "brewer.br_bg"),
# #       fill.legend = tm_legend(title = "NDMI moyen"),
# #       col = "white", lwd = 0.3
# #     ) +
# #   tm_shape(cam_regions) +
# #     tm_borders(col = "grey30", lwd = 0.8) +
# #   tm_shape(dhs_geo) +
# #     tm_dots(fill = "#C00000", size = 0.2) +
# #     tm_title("NDMI moyen par departement -- Cameroun") +
# #     tm_scalebar(position = c("left", "bottom")) +
# #     tm_compass(type = "4star", position = c("right", "top")) +
# #     tm_layout(frame = FALSE, legend.outside = TRUE)
# #
# # tmap_save(ma_carte, "outputs/carte_NDMI_Cameroun.png",
# #           dpi = 300, width = 8, height = 10)

