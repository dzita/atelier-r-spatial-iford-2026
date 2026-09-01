## ============================================================================
## SCRIPT ETUDIANT -- J08 : COMPTER CHAQUE HABITANT, LA GRILLE DE POPULATION
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Yaounde
##
## MODE D'EMPLOI. Les commentaires portent la consigne : lisez-les, puis
## ecrivez votre code aux emplacements marques ">>> A COMPLETER". Avancez
## section par section, en verifiant chaque resultat avant de continuer.
## Le corrige complet est distribue en fin de journee.
##
## CE FICHIER COMPTE 58 EMPLACEMENTS marques ">>> A COMPLETER".
## Si vous en trouvez moins, c'est que votre copie est incomplete.
##
## Les sections de CHARGEMENT DES PACKAGES et de LECTURE DES DONNEES sont
## deja completes : sans elles, rien ne tourne. Les trous commencent au
## premier calcul.
##
## Donnees : datasets/ (chemins relatifs). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
## ============================================================================

## --- Se placer dans le dossier de la journee --------------------------------
## Tous les chemins de ce script sont relatifs a CE dossier. Quarto s'y place
## automatiquement au rendu ; Rscript, non. On le fait donc explicitement, que
## le script soit lance depuis scripts/, depuis le dossier du jour, depuis
## pedagogie/ ou depuis la racine du projet.
.dossier_jour <- "J08_population_haute_resolution"
if (!dir.exists("datasets")) {
  for (.p in c("..",
               .dossier_jour,
               file.path("pedagogie", .dossier_jour))) {
    if (dir.exists(file.path(.p, "datasets"))) { setwd(.p); break }
  }
}
if (!dir.exists("datasets"))
  stop("Dossier datasets/ introuvable. Ouvrez atelier-r-spatial-iford-2026.Rproj, ",
       "lancez source('outils/distribuer_donnees.R'), puis relancez ce script.")
cat("Dossier de travail :", getwd(), "\n")

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)

## ----------------------------------------------------------------------
## LA QUESTION DE LA JOURNEE
##
## Combien d'habitants dans ce quartier, ce bassin versant, ce rayon de 5 km
## autour de ce centre de sante ?
##
## Aucun recensement ne repond a cette question : il livre des effectifs par
## UNITE ADMINISTRATIVE, et ces unites ne coincident presque jamais avec le
## territoire d'une decision.
##
## Une GRILLE DE POPULATION y repond : un raster dont chaque cellule (100 m)
## porte un effectif estime. Comme c'est une grille reguliere, on peut la
## decouper selon n'importe quelle forme.
##
## Le prix a payer, et le coeur de la journee :
##   1. Une grille est un MODELE, pas une observation.
##   2. Deux grilles serieuses ne donnent pas le meme chiffre (module 7).
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## ATTENTION -- tmap doit etre en version 4 ou superieure. Tout le code
## cartographique emploie l'API tmap 4 (tm_raster(col.scale = , col.legend = ),
## tm_scale_intervals(), tm_legend(), tm_title()). Avec tmap 3, TOUS les blocs
## cartographiques echouent ("unused argument (col.scale)").
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## sf::sf_use_s2(FALSE) : on repasse du moteur spherique (s2, exigeant sur la
## proprete des geometries) au moteur planaire (GEOS, tolerant). Cela
## N'AUTORISE PAS a mesurer sur des degres : toute superficie de ce script est
## calculee APRES reprojection en UTM 33N (EPSG:32633).
## ----------------------------------------------------------------------

suppressPackageStartupMessages(library(sf))
sf::sf_use_s2(FALSE)

################################################################################
# ATELIER IFORD x GDSG 2026 - DONNEES SPATIALES, ANALYSE ET MANIPULATION DANS R
# J08 : Compter chaque habitant - la grille de population (TRAME ETUDIANT)
################################################################################

## --- CHARGEMENT DES PACKAGES : SECTION COMPLETE, NE RIEN MODIFIER ----------
suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(ggplot2)
  library(tidyr)
  library(readr)
  library(terra)
  library(tmap)
  library(exactextractr)
  library(scales)
})

tmap_mode("plot")

cat("Version de tmap :", as.character(packageVersion("tmap")), "\n")
cat("Version de terra :", as.character(packageVersion("terra")), "\n")
cat("Repertoire de travail :", getwd(), "\n")


## ============================================================================
## MODULE 1 -- DU TABLEAU A LA GRILLE : CE QU'UN CHOROPLETHE NE DIT PAS
## ============================================================================
##
## Deux sources, deux natures :
##  - cmr_admpop_adm1_2025.csv : le COD-PS. Unite d'observation = LA REGION.
##    Dix lignes : total, par sexe, ventilation par tranche d'age. Un TABLEAU.
##  - gadm41_CMR.gpkg : les limites GADM 4.1, GeoPackage MULTICOUCHE
##    (ADM_ADM_0 pays, ADM_ADM_1 10 regions, ADM_ADM_2 58 departements,
##    ADM_ADM_3). Une GEOMETRIE.
##
## Le premier geste de toute cartographie thematique est de les joindre. C'est
## aussi le geste ou l'on perd silencieusement des lignes.

## --- LECTURE DES DONNEES : SECTION COMPLETE, NE RIEN MODIFIER --------------

pop_adm1 <- read_csv("datasets/cmr_admpop_adm1_2025.csv", show_col_types = FALSE)

cat("cmr_admpop_adm1_2025.csv\n")
cat("  lignes   :", nrow(pop_adm1), "\n")
cat("  colonnes :", ncol(pop_adm1), "\n")
cat("  noms     :", paste(names(pop_adm1), collapse = " | "), "\n")
cat("  NA total :", sum(is.na(pop_adm1)), "\n")

print(st_layers("datasets/gadm41_CMR.gpkg"))

cmr1 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_1", quiet = TRUE) |>
  st_make_valid()

cat("\nCouche ADM_ADM_1\n")
cat("  entites            :", nrow(cmr1), "\n")
cat("  colonnes           :", paste(names(cmr1), collapse = " | "), "\n")
cat("  CRS                :", st_crs(cmr1)$input, "\n")
cat("  geometries valides :", sum(st_is_valid(cmr1)), "/", nrow(cmr1), "\n")
print(cmr1 |> st_drop_geometry() |> select(any_of(c("GID_1", "NAME_1"))))

## --- FIN DE LA SECTION DE LECTURE. LES TROUS COMMENCENT ICI. ---------------


## ------------------------------------------------------------------------
## 1.2 CHOISIR LA CLE DE JOINTURE : ADM1_FR OU ADM1_EN ?
##
## Le CSV porte DEUX colonnes de nom de region. GADM n'en porte qu'une,
## NAME_1. Le Cameroun est bilingue et les nomenclatures different :
## Adamaoua / Adamawa, Extreme-Nord / Far North. Un left_join() sur la
## mauvaise colonne NE LEVE AUCUNE ERREUR : il remplit la colonne de
## population de NA. On ne devine pas : ON COMPTE.
## ------------------------------------------------------------------------

# Afficher les trois listes de noms, triees, pour les comparer a l'oeil.
cat("GADM NAME_1 :\n"); print(sort(cmr1$NAME_1))
cat("\nCSV ADM1_EN :\n"); print(sort(pop_adm1$ADM1_EN))
cat("\nCSV ADM1_FR :\n"); print(sort(pop_adm1$ADM1_FR))

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J08_corrige.R)
# ......................................................................
# Compter, pour chaque colonne candidate, combien de noms GADM trouvent
# preneur : n_match_en et n_match_fr (indice : sum(x %in% y)).
# Afficher les deux comptes ET les noms non apparies (indice : setdiff()).
# Puis choisir la cle PAR LES DONNEES, sans l'ecrire en dur :
#   cle_retenue <- if (n_match_en >= n_match_fr) "ADM1_EN" else "ADM1_FR"
#   cle_ecartee <- setdiff(c("ADM1_EN", "ADM1_FR"), cle_retenue)
# et imprimer le choix.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Ajouter a pop_adm1 une colonne cle_region qui recopie la colonne retenue.
# Indice : mutate(cle_region = .data[[cle_retenue]])


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Joindre. PARTIR DE LA COUCHE GEOGRAPHIQUE (cmr1) et lui adjoindre le
# tableau : l'inverse perd la classe sf et la geometrie.
# Objet resultat : cmr1_pop
# Colonnes a rapatrier : ADM1_PCODE, T_TL, F_TL, M_TL (via any_of()).
# Cle : by = c("NAME_1" = "cle_region")


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# INSTRUMENTATION OBLIGATOIRE apres jointure. Imprimer QUATRE compteurs :
#   - lignes avant / lignes apres (si elles different, la jointure a DUPLIQUE
#     des polygones : la cle n'est pas unique du cote du tableau) ;
#   - nombre de regions sans effectif : sum(is.na(cmr1_pop$T_TL))
#     (elles apparaitront en GRIS sur la carte, jamais a zero) ;
#   - nombre de lignes du CSV jamais appariees ;
#   - population totale jointe.


## ------------------------------------------------------------------------
## 1.3 LE CHOROPLETHE DE LA POPULATION TOTALE
## ------------------------------------------------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire carte_choropleth : ggplot(cmr1_pop) + geom_sf(aes(fill = T_TL)).
# Trois exigences non negociables :
#   - palette SEQUENTIELLE (scale_fill_viridis_c, option = "plasma") : la
#     population n'a qu'un sens de lecture, donc pas de divergente ;
#   - labels = label_comma(big.mark = " ") pour les separateurs de milliers ;
#   - na.value = "grey80" : UN POLYGONE SANS DONNEE EST GRIS, JAMAIS A ZERO.
# Titre, sous-titre (source COD-PS) et caption ("gris = sans effectif").
# Puis print() la carte.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Exporter : ggsave("outputs/J08_choropleth_population_adm1.png", ...,
#                   width = 7, height = 6, dpi = 180)
# Rappel : les sorties vont TOUJOURS dans outputs/, jamais dans datasets/.


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- carte choroplethe de la population regionale
##
## Repondez aux quatre questions, dans cet ordre :
## 1. CE QUE LA FIGURE CODE. Quelle est la definition exacte de T_TL ?
##    Est-ce un volume, une densite ou un taux ? Que signifie le gris ?
## 2. CE QUE LES CHOIX TECHNIQUES FONT. Pourquoi une palette sequentielle et
##    non divergente ? Qu'apporte et que coute une echelle continue plutot
##    qu'une discretisation ?
## 3. CE QUI SE LIT. Quelle hierarchie ? Les regions les plus peuplees se
##    touchent-elles ?
## 4. CE QUI NE SE LIT PAS. Que ne dit PAS cette carte sur la repartition A
##    L'INTERIEUR d'une region ?
##
## Puis : EN QUOI LE SPATIAL EST-IL UTILE ICI ? Que voit-on sur la carte que
## les dix lignes du tableau, triees, ne donnent pas ?
## ------------------------------------------------------------------------


## ------------------------------------------------------------------------
## 1.4 LE CONTRE-EXEMPLE : LA MEME CARTE AVEC LA MAUVAISE CLE
## Pour rendre la panne visible, on refait deliberement la jointure avec la
## cle ECARTEE. Le code ne change pas d'une virgule ; seul le nom de la
## colonne change.
## ------------------------------------------------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire cmr1_faux : meme left_join que plus haut, mais en joignant sur
# cle_ecartee. Puis imprimer le nombre de regions sans effectif et le total
# obtenu, COMPARE au total juste.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer carte_fausse (meme code que carte_choropleth, sur cmr1_faux), avec un
# titre qui annonce le contre-exemple, et l'exporter dans
# "outputs/J08_cle_jointure_contre_exemple.png".
#
# Question : R a-t-il leve une erreur ? Qu'est-ce qui, sur la carte, est le
# SEUL signal d'alerte ? Et si na.value n'avait pas ete pose ?


## ============================================================================
## MODULE 2 -- LIRE LA STRUCTURE DEMOGRAPHIQUE
## ============================================================================
##
## Le COD-PS ne donne pas qu'un total : il donne la ventilation par SEXE et par
## TRANCHE D'AGE quinquennale. C'est ce qui distingue une source demographique
## d'un denombrement -- et c'est precisement ce que les grilles de population
## des modules suivants NE SAVENT PAS FAIRE.

## --- 2.1 Le ratio femmes / hommes -------------------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Ajouter a cmr1_pop une colonne ratio_fm = F_TL / M_TL.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# INSTRUMENTATION : la variable derivee est-elle plausible ? Imprimer min,
# mediane, max du ratio, le nombre de valeurs manquantes, et le RATIO NATIONAL
# (somme des F / somme des M -- attention : ce n'est PAS la moyenne des ratios
# regionaux).


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer carte_ratio. Ici la palette doit etre DIVERGENTE :
#   scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
#                        midpoint = ???, labels = label_number(accuracy = 0.01),
#                        na.value = "grey80")
# Quelle valeur donner a midpoint pour un ratio F/H ? Pourquoi celle-la et
# non la moyenne nationale ? (Les deux sont defendables : dire ce qu'on
# raconte dans chaque cas.)
# Exporter dans "outputs/J08_ratio_femmes_hommes_adm1.png".


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- ratio femmes / hommes
## 1. Definition exacte : en quoi ce ratio differe-t-il du RAPPORT DE
##    MASCULINITE des demographes ?
## 2. Pourquoi une palette divergente change-t-elle la lecture ? Que
##    represente exactement le blanc ?
## 3. Que lit-on ? (indice : migration de travail)
## 4. Que ne lit-on pas ? (indice : l'age ; l'ampleur demographique ;
##    l'incertitude)
## ------------------------------------------------------------------------


## --- 2.2 La part des moins de 15 ans ----------------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Les colonnes d'age s'appellent T_00_04, T_05_09, ... T_80Plus. NE PAS les
# ecrire en dur sans verifier : construire cols_jeunes par intersect() avec
# names(pop_adm1), et imprimer combien des trois ont ete trouvees.
# Puis construire un tableau 'jeunes' contenant cle_region, jeunes_0_14
# (somme des trois tranches, indice : rowSums(across(all_of(cols_jeunes)))) et
# part_jeunes_pct (100 * jeunes_0_14 / T_TL).


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Joindre 'jeunes' a cmr1_pop, puis INSTRUMENTER : nombre de regions sans part
# de jeunes, part NATIONALE des 0-14 ans, et le tableau trie par
# part_jeunes_pct decroissante.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer carte_jeunes : palette sequentielle (option = "magma"),
# na.value = "grey80". Exporter dans
# "outputs/J08_part_population_jeune_adm1.png".


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- part des moins de 15 ans
## 1. Definition exacte : en quoi cette proportion differe-t-elle du TAUX DE
##    DEPENDANCE DES JEUNES (denominateur 15-64 ans) ?
## 2. Que fait la normalisation par T_TL ? Pourquoi une echelle continue
##    plutot qu'une discretisation en quantiles sur dix unites seulement ?
## 3. Que lit-on ?
## 4. Que ne lit-on pas ? (indice : la cause -- fecondite, mortalite adulte ou
##    emigration se ressemblent ici ; et l'EFFECTIF)
##
## Puis : EN QUOI LE SPATIAL EST-IL UTILE ICI ? Trois arguments a instancier :
## la CONTIGUITE, l'ECART ENTRE DEUX CARTES (celle-ci et le ratio F/H), et le
## REPERAGE DE CE QUI MANQUE.
## ------------------------------------------------------------------------


## --- 2.3 Deux pyramides des ages comparees ----------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Ne PAS ecrire les deux regions en dur : construire 'classement' (cmr1_pop
# sans geometrie, filtre sur part_jeunes_pct non manquante, trie decroissant)
# puis regions_a_comparer = la premiere et la derniere. Imprimer le choix.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire cols_age : toutes les colonnes commencant par "T_", SAUF T_TL
# (indice : setdiff(grep("^T_", names(pop_adm1), value = TRUE), "T_TL")).
# Imprimer combien de tranches ont ete trouvees.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire pop_age : filtrer sur les deux regions, selectionner cle_region
# et cols_age, puis pivot_longer() vers (groupe_age, population).
# Nettoyer les etiquettes : retirer le prefixe "T_", remplacer "_" par "-",
# "Plus" par "+", et FIXER L'ORDRE avec factor(levels = unique(...)) -- sans
# quoi ggplot rangera les tranches par ordre alphabetique.
# Enfin, par region (group_by), calculer part_pct = 100 * population / somme
# de la region.
# INSTRUMENTER : nombre de lignes apres pivot_longer, compare a l'attendu
# (2 regions x nombre de tranches).


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer graphique_pyramide : barres GROUPEES (position = "dodge"), en
# PART (%) et non en effectif, palette QUALITATIVE (scale_fill_brewer,
# palette = "Set1"), axe des x incline a 45 degres.
# Pourquoi la part et non l'effectif ? Pourquoi "dodge" et non "stack" ?
# Exporter dans "outputs/J08_pyramide_deux_regions.png".


## ------------------------------------------------------------------------
## A RETENIR -- CE QUE LES GRILLES NE SAURONT PAS FAIRE
##
## A partir du module 3, les rasters donnent un EFFECTIF TOTAL PAR CELLULE et
## RIEN D'AUTRE : ni sexe, ni age, ni menage.
##
## Consequence : pour estimer une POPULATION SCOLARISABLE dans une zone
## dessinee, on ne peut pas lire l'age dans la grille. On applique a l'effectif
## total la PART DES 0-14 ANS DE L'UNITE ADMINISTRATIVE ENGLOBANTE, calculee
## ici. Hypothese forte -- structure par age homogene dans la region -- et cas
## d'ecole d'ERREUR ECOLOGIQUE (module 6). A ECRIRE A COTE DU CHIFFRE.
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 3 -- OUVRIR UNE GRILLE : WORLDPOP 100 M
## ============================================================================
##
## Trois proprietes decrivent un raster, et il faut LES VERIFIER AVANT TOUT
## CALCUL : l'EMPRISE, le CRS (qui dit ce que MESURENT les coordonnees :
## degres ? metres ?), et la RESOLUTION (dans l'unite du CRS).
##
## La quatrieme est SEMANTIQUE et n'est ecrite nulle part : QUE REPRESENTE LA
## VALEUR D'UNE CELLULE ? Pour WorldPop constrained, le NOMBRE ESTIME DE
## PERSONNES RESIDANT DANS LA CELLULE -- grandeur EXTENSIVE, qui s'additionne.
## Pour une densite ou une temperature, la valeur est INTENSIVE et se MOYENNE.
## Confondre les deux est l'erreur la plus frequente sur les rasters.

## --- LECTURE DES DONNEES : SECTION COMPLETE, NE RIEN MODIFIER --------------
pop_2025 <- rast("datasets/cmr_pop_2025_CN_100m_R2025A_v1.tif")
print(pop_2025)

cmr0 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_0", quiet = TRUE) |>
  st_make_valid()
cat("Couche ADM_ADM_0 : ", nrow(cmr0), " entite(s), CRS ",
    st_crs(cmr0)$input, "\n", sep = "")
## --------------------------------------------------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# INSTRUMENTATION OBLIGATOIRE apres chaque lecture de raster. Imprimer :
# dimensions, nombre de cellules, resolution, nom du CRS, code EPSG, emprise
# (xmin/xmax, ymin/ymax), valeur minimale et maximale.
# Indices : dim(), ncell(), res(), crs(x, describe = TRUE)$name et $code,
# xmin/xmax/ymin/ymax(), minmax().
#
# QUESTION : la resolution s'affiche-t-elle en metres ou en degres ? Le nom du
# fichier annonce 100 m -- que vaut reellement une cellule ? Et pourquoi une
# cellule n'a-t-elle PAS la meme surface au sud et au nord du Cameroun ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Decouper le raster sur le pays. Deux etapes, toujours dans cet ordre :
#   1. amener le POLYGONE dans le CRS du raster : st_transform() puis vect() ;
#   2. crop() (emprise rectangulaire) PUIS mask() (NA hors du polygone).
# Pourquoi les deux ? Que resterait-il si l'on faisait crop() seul ?
# Objet resultat : pop_2025_cmr


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# INSTRUMENTER apres le decoupage : nombre de cellules, nombre de cellules NON
# VIDES (indice : global(!is.na(x), "sum")), et TOTAL NATIONAL 2025
# (global(x, "sum", na.rm = TRUE)$sum).


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer carte_grille avec tmap 4 :
#   tm_shape(pop_2025_cmr) +
#     tm_raster(col.scale  = tm_scale_intervals(n = 7, style = "quantile",
#                                               values = "brewer.yl_or_rd"),
#               col.legend = tm_legend(title = "Habitants par cellule")) +
#   tm_shape(cmr1) + tm_borders(...) + tm_title(...)
# Exporter avec tmap_save() dans "outputs/J08_grille_population_2025.png".
#
# QUESTION DE METHODE : pourquoi "quantile" et non "equal" ? Essayez
# style = "equal" et decrivez ce que vous obtenez. Puis style = "jenks" :
# pourquoi deux cartes Jenks ne sont-elles PAS comparables entre elles ?


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- la grille WorldPop 2025
## 1. Que code un pixel ? Effectif ou densite ? Que sont les zones blanches ?
##    (indice : le mot "constrained" dans le nom du fichier)
## 2. Ce que la discretisation en quantiles fait -- et ce que feraient
##    "equal" et "jenks" sur la meme donnee.
## 3. Ce qui se lit : l'armature urbaine, les axes.
## 4. Ce qui ne se lit pas : le reechantillonnage d'affichage, la qualite
##    locale de l'estimation, et le fait qu'une cellule vide prouve l'absence
##    de BATI DETECTE et non l'absence d'habitants.
##
## Puis : EN QUOI LE SPATIAL EST-IL UTILE ICI ? C'est la rupture de la journee.
## Trois arguments : decoupable a volonte, heterogeneite interne visible, et
## "ou il n'y a personne".
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## CODE DE REFERENCE - NON EXECUTE (a essayer en direct, pas au rendu)
## Raison : tmap_mode("view") produit un widget leaflet qui embarque le raster
## dans le HTML -- plusieurs dizaines de Mo sur une grille nationale.
## ------------------------------------------------------------------------
# tmap_mode("view")
# tm_shape(pop_2025_cmr) +
#   tm_raster(col.scale = tm_scale_intervals(n = 7, style = "quantile",
#                                            values = "brewer.yl_or_rd"),
#             col.legend = tm_legend(title = "hab/cellule"), col_alpha = 0.8) +
#   tm_shape(cmr1) + tm_borders(col = "grey30", lwd = 0.5)
# tmap_mode("plot")


## ============================================================================
## MODULE 4 -- EXTRAIRE UN EFFECTIF : LE MFOUNDI EN 2015, 2025 ET 2030
## ============================================================================

## --- LECTURE DES DONNEES : SECTION COMPLETE, NE RIEN MODIFIER --------------
cmr2 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_2", quiet = TRUE) |>
  st_make_valid()
cat("Couche ADM_ADM_2 : ", nrow(cmr2), " departements, CRS ",
    st_crs(cmr2)$input, "\n", sep = "")
cat("Colonnes : ", paste(names(cmr2), collapse = " | "), "\n")

pop_2015 <- rast("datasets/cmr_pop_2015_CN_100m_R2025A_v1.tif")
pop_2030 <- rast("datasets/cmr_pop_2030_CN_100m_R2025A_v1.tif")
## --------------------------------------------------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Yaounde correspond au departement du Mfoundi (region du Centre).
# Filtrer cmr2 pour obtenir l'objet 'yaounde', puis VERIFIER que le filtre a
# bien retenu une entite (et une seule) avec un cat().
# Piege : si NAME_2 s'orthographie autrement, filter() renvoie 0 ligne SANS
# lever d'erreur, et tout ce qui suit renvoie NA.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Ecrire la fonction effectif_zone(raster, zone, etiquette) qui :
#   1. amene le POLYGONE dans le CRS du raster (st_transform puis vect) --
#      JAMAIS l'inverse : reprojeter un raster reechantillonne les valeurs et
#      MODIFIE LE TOTAL ;
#   2. applique crop() puis mask() ;
#   3. somme avec global(..., "sum", na.rm = TRUE)$sum ;
#   4. imprime l'effectif ET le nombre de cellules retenues (un nombre absurde
#      signale immediatement un probleme de CRS) ;
#   5. renvoie list(raster = ..., total = ...).
# Ecrire trois fois cette sequence, c'est trois occasions de se tromper de
# CRS : on l'enferme une fois pour toutes.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# INSTRUMENTER la comparabilite des trois millesimes : pour 2015, 2025 et
# 2030, imprimer resolution, dimensions et code EPSG ; puis verifier que les
# trois grilles ont les MEMES dimensions (identical(dim(...), dim(...))).
# Pourquoi est-ce la condition pour que la difference entre elles soit
# interpretable ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Appeler effectif_zone() pour les trois millesimes sur le Mfoundi :
# yde_2015, yde_2025, yde_2030.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire evol_yaounde : un tibble (annee, population) pour 2015, 2025,
# 2030, puis ajouter croissance_vs_2015_pct et croissance_annuelle_pct (taux
# annuel moyen : 100 * ((pop/pop[1])^(1/(annee-2015)) - 1)).
# Imprimer le tableau, puis les croissances 2015-2025 et 2025-2030.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer graphique_evolution : ligne + points + etiquettes de valeur, axe y
# avec separateurs de milliers, breaks x = c(2015, 2025, 2030).
# Sous-titre : preciser que 2015 et 2025 sont OBSERVES et 2030 PROJETE.
# Exporter dans "outputs/J08_evolution_population_yaounde_2015_2030.png".
#
# QUESTION : l'axe des ordonnees commence-t-il a zero ? Est-ce acceptable ici,
# et le serait-ce sur un graphique en barres ?


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- trajectoire du Mfoundi
## 1. Definition exacte : "Mfoundi" ou "Yaounde" ? Quelle difference ?
## 2. Pourquoi les trois grilles doivent-elles appartenir a la MEME version du
##    modele (R2025A) ? Que mesurerait-on sinon ?
## 3. Que lit-on ?
## 4. Que ne lit-on pas ? Qu'est-ce qui distingue les deux premiers points du
##    troisieme, et quelles hypotheses porte une projection ?
## ------------------------------------------------------------------------


## --- 4.3 La comparaison cartographique 2015 / 2025 / 2030 -------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Decouper pop_2015 et pop_2030 sur le pays (meme methode qu'au module 3) ->
# pop_2015_cmr et pop_2030_cmr. Puis imprimer les trois totaux nationaux.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Calculer des BREAKS COMMUNS aux trois cartes : quantiles calcules sur la
# CONCATENATION des valeurs des trois rasters (indice : c(values(r1),
# values(r2), values(r3)), puis quantile(probs = seq(0, 1, length.out = 8))).
# Envelopper dans unique() : des bornes dupliquees feraient echouer
# tm_scale_intervals(). Imprimer les bornes obtenues.
#
# QUESTION : que se passerait-il si chaque panneau etait discretise sur SA
# PROPRE distribution ? (C'est la faute la plus frequente des comparaisons
# temporelles cartographiques.)


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Ecrire une petite fonction carte_millesime(r, titre) qui produit un panneau
# tmap avec les breaks communs, puis assembler les trois avec tmap_arrange(...,
# ncol = 3). Exporter dans
# "outputs/J08_comparaison_pop_2015_2025_2030.png" (width = 16, height = 5).


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- trois millesimes a echelle commune
## 1. Que codent les trois panneaux ?
## 2. Que font les breaks communs ? Que verrait-on sans eux ?
## 3. Que lit-on ? (indice : a echelle commune, le changement se lit en
##    SURFACE COLOREE, pas en intensite)
## 4. Que ne lit-on pas ?
##
## Puis : EN QUOI LE SPATIAL EST-IL UTILE ICI ? L'ECART ENTRE DEUX CARTES.
## DENSIFICATION et ETALEMENT donnent le meme chiffre regional et deux cartes
## differentes -- et ce sont deux problemes de politique publique opposes.
## Lesquels ?
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 5 -- AGREGER PAR REGION ET CONFRONTER AU CHIFFRE OFFICIEL
## ============================================================================

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# exact_extract() attend le VECTEUR DANS LE CRS DU RASTER. Reprojeter cmr1,
# imprimer les deux CRS pour verifier qu'ils coincident, puis calculer :
#   pop_2025_par_region et pop_2015_par_region
# avec exact_extract(raster, vecteur, "sum", progress = FALSE).


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# INSTRUMENTATION OBLIGATOIRE apres extraction zonale : nombre de polygones
# traites, nombre de regions sans valeur, somme des zonales, total national
# brut, et L'ECART ENTRE LES DEUX (il mesure la population qui tombe hors des
# polygones ADM1 : iles, zones frontalieres, defauts de decoupage).
#
# QUESTION DE METHODE : qu'est-ce que "exact" veut dire dans exact_extract ?
# Comparez trois strategies pour une cellule qui chevauche une frontiere :
# par centroide, tout-ou-rien par intersection, et ponderation par FRACTION DE
# CELLULE. Sur quel type de polygone l'ecart devient-il decisif ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire regions_pop : NAME_1, pop_worldpop_2015, pop_worldpop_2025,
# variation, croissance_pct ; trie par population 2025 decroissante.
# Imprimer le tableau.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer graphique_croissance : barres horizontales de croissance_pct, regions
# triees par reorder(), ligne verticale en pointille a 0, etiquettes de valeur.
# L'axe DOIT partir de zero : sur des barres, la longueur EST la quantite.
# Exporter dans "outputs/J08_croissance_population_2015_2025.png".


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- croissance regionale 2015-2025
## 1. Croissance RELATIVE ou gain ABSOLU ? Quelle difference de classement ?
## 2. Que fait reorder() ? Pourquoi l'axe ne doit-il pas etre tronque ?
## 3. Que lit-on ?
## 4. Que ne lit-on pas ? Quelle part de la "croissance" mesuree pourrait
##    n'etre qu'un PROGRES DE LA DETECTION DU BATI entre 2015 et 2025 ?
## ------------------------------------------------------------------------


## --- 5.2 Confronter au total officiel : l'ecart, ecrit et non masque --------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Calculer total_worldpop (somme de regions_pop$pop_worldpop_2025) et
# total_officiel (somme de pop_adm1$T_TL), puis l'ecart absolu, l'ecart relatif
# en %, et LE SENS de l'ecart (WorldPop surestime ou sous-estime ?).
# TOUT IMPRIMER. Un ecart qu'on ne publie pas est un ecart qu'on masque.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire comparaison_officiel : joindre regions_pop et l'effectif officiel
# par region, calculer ecart_abs et ecart_pct, et trier par VALEUR ABSOLUE de
# l'ecart decroissante. Imprimer le tableau, le nombre de regions sans chiffre
# officiel, l'ecart median et l'amplitude des ecarts.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer carte_ecart : palette DIVERGENTE centree sur 0 (pourquoi zero et non
# la mediane ?), na.value = "grey80". Titre : "Ecart WorldPop 2025 - COD-PS
# 2025". Exporter dans "outputs/J08_ecart_worldpop_officiel_adm1.png".


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- la carte des ecarts
## 1. Ce n'est PAS une carte de population. Que code-t-elle exactement ?
## 2. Pourquoi une divergente centree sur zero ? Que detruirait une palette
##    sequentielle ici ?
## 3. Que lit-on ? Un ecart CONTIGU (bloc de regions voisines du meme cote)
##    est-il du bruit ?
## 4. Que ne lit-on pas ? La carte dit-elle LAQUELLE des deux sources a raison ?
##
## ET SURTOUT : QUE FAIRE DE CET ECART ? Redigez la phrase-type qui doit
## accompagner tout effectif tire d'une grille. A partir de quel seuil
## faut-il INTERDIRE de citer les chiffres regionaux concernes ?
## ------------------------------------------------------------------------


## --- 5.3 Cinq villes comparees ----------------------------------------------

villes_dept <- c(
  "Douala (Wouri)"    = "Wouri",
  "Yaounde (Mfoundi)" = "Mfoundi",
  "Bafoussam (Mifi)"  = "Mifi",
  "Bamenda (Mezam)"   = "Mezam",
  "Garoua (Benoue)"   = "Benoue"
)

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire pop_villes : pour chaque departement du vecteur ci-dessus,
# extraire l'effectif 2015 et 2025 (meme methode qu'au module 4), puis
# calculer croissance_pct et gain_absolu, et trier par pop_2025.
# PREVOIR LE CAS OU LE DEPARTEMENT EST INTROUVABLE : imprimer un avertissement
# et renvoyer des NA plutot que de laisser la boucle echouer.
# Imprimer le tableau, le nombre de villes sans effectif, et la part des cinq
# departements dans la population nationale.


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- les cinq departements urbains
## 1. Ce sont des DEPARTEMENTS, pas des villes. Lequel des cinq est le plus
##    eloigne de son agglomeration ? Dans quel sens ?
## 2. Croissance relative et gain absolu classent-ils pareil ? Lequel publier ?
## 3. Que lit-on ?
## 4. Que ne lit-on pas ? Nommez le biais qui affecte la comparaison entre un
##    departement compact et un departement etendu. Comment definir une VILLE
##    a partir de la grille elle-meme ?
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 6 -- DENSITE, ECHELLE LOGARITHMIQUE ET MAUP
## ============================================================================

## --- 6.1 Mesurer une surface : reprojeter d'abord ---------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# EPSG:4326 est en DEGRES : st_area() y renverrait des degres carres, grandeur
# sans signification physique et variable avec la latitude.
# Reprojeter cmr1_pop en UTM 33N (EPSG:32633), puis calculer surface_km2 et
# densite_hab_km2 = T_TL / surface_km2. Objet : cmr1_densite


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# INSTRUMENTER : comparer la surface totale calculee au chiffre officiel
# (475 442 km2) et imprimer l'ecart en %. Puis imprimer le tableau des
# densites triees, le rapport max/min, ET DEUX CHIFFRES A NE PAS CONFONDRE :
#   - la DENSITE NATIONALE (population totale / surface totale) ;
#   - la MOYENNE NON PONDEREE des densites regionales.
# Pourquoi different-ils ? Lequel citer, et pour repondre a quelle question ?
# (Meme mecanisme que le BIAIS DE TAILLE du J05.)


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer carte_densite avec une ECHELLE LOGARITHMIQUE :
#   scale_fill_viridis_c(option = "inferno", trans = "log10",
#                        labels = label_comma(big.mark = " "),
#                        na.value = "grey80", name = "hab/km2 (log10)")
# Exporter dans "outputs/J08_densite_population_adm1.png".
#
# QUESTION : essayez d'abord SANS trans = "log10". Que voyez-vous ? Combien de
# regions se retrouvent dans la meme nuance ? Puis avec. Que coute l'echelle
# log (indice : les ecarts ABSOLUS, et le comportement en zero) ?


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- densite regionale en echelle log
## 1. Definition exacte : densite BRUTE ou PHYSIOLOGIQUE ? Sur quelle surface ?
## 2. DEUX choix a expliquer : la normalisation par la surface (que gagne-t-on,
##    que perd-on ?) et l'echelle logarithmique (elle represente des RAPPORTS,
##    pas des differences -- consequence sur la lecture ?).
## 3. Que lit-on ?
## 4. Que ne lit-on pas ? (indice : l'heterogeneite interne, massivement)
## ------------------------------------------------------------------------


## --- 6.3 Le MAUP : la meme population, deux mailles, deux cartes ------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Extraire la population WorldPop 2025 par DEPARTEMENT (exact_extract sur
# cmr2), puis INSTRUMENTER : nombre de polygones, valeurs manquantes, somme
# ADM2 comparee a la somme ADM1 (elles doivent coincider).


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire dens_adm2 et dens_adm1 : population WorldPop, surface_km2 (en UTM
# 33N) et densite_hab_km2, pour chacune des deux mailles.
# Puis imprimer, POUR CHAQUE MAILLE : min, mediane, max et RAPPORT MAX/MIN des
# densites. Que fait le rapport max/min quand on passe a la maille fine ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer les DEUX cartes de densite cote a cote, avec des BORNES DE CLASSES
# FIXEES A LA MAIN ET IDENTIQUES :
#   breaks_dens <- c(0, 10, 25, 50, 100, 250, 1000, 1e6)
# Utiliser tm_polygons(fill = , fill.scale = tm_scale_intervals(breaks = ...),
# fill.legend = ...) et tmap_arrange(ncol = 2).
# Exporter dans "outputs/J08_densite_maup_adm1_adm2.png".
#
# POURQUOI DES BORNES FIXEES A LA MAIN ? Que se passerait-il avec une
# discretisation en quantiles calculee separement sur 10 puis sur 58 unites ?
# (Indice : le MAUP deviendrait invisible.)
# Et pourquoi ces bornes-la progressent-elles de facon quasi geometrique ?


## ------------------------------------------------------------------------
## A REDIGER -- LE MAUP (Modifiable Areal Unit Problem)
##
## Les deux cartes reposent sur EXACTEMENT la meme donnee. Seule la MAILLE
## change. Redigez, en vous appuyant sur les chiffres que vous venez
## d'imprimer :
##
## a) L'EFFET D'ECHELLE. Que fait une maille grossiere a la variance ? Aux
##    extremes ? Et -- consequence moins connue -- aux CORRELATIONS entre
##    variables ? Le coefficient mesure est-il une propriete du phenomene ?
##
## b) L'EFFET DE ZONAGE. A nombre d'unites CONSTANT, le TRACE des limites
##    change-t-il le resultat ? Citez un mecanisme connu.
##
## c) LA REGLE OPERATOIRE. Il n'existe pas de maille neutre. Quelle maille
##    choisir pour : allouer un budget regional ? implanter un centre de
##    sante ? dimensionner une campagne vaccinale ?
##    Et quand on ne peut pas choisir : quel est le reflexe minimal ?
##
## d) En quoi une GRILLE aide-t-elle -- et pourquoi n'elimine-t-elle PAS le
##    MAUP ?
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## A REDIGER -- L'ERREUR ECOLOGIQUE
##
## Definition : attribuer a un individu ce qui n'est vrai que de l'AGREGAT
## auquel il appartient.
##
## a) Une region affiche 60 hab/km2. L'enonce "les habitants de cette region
##    vivent a 60 hab/km2" est-il vrai pour la plupart d'entre eux ? Pourquoi ?
## b) Donnez les trois formes courantes : de l'agregat a l'individu ; de
##    l'agregat a l'agregat plus fin ; la correlation ecologique (comment
##    s'appelle le cas ou le signe s'inverse ?).
## c) Quelle des trois avez-vous DEJA commise dans ce script, au module 2 ?
## d) Qu'est-ce qui protege ? (indice : superposer les echelles)
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 7 -- DEUX GRILLES NE DISENT PAS LA MEME CHOSE : GHS-POP
## ============================================================================
##
## GHS-POP (JRC, Commission europeenne) differe de WorldPop sur cinq points :
## producteur, projection native (Mollweide ESRI:54009, METRIQUE, contre
## EPSG:4326 en degres), decoupage de livraison (TUILES mondiales contre un
## fichier par pays), covariable dominante, et calibrage.
##
## Deux consequences pratiques : il faut ASSEMBLER les sept tuiles, et il faut
## REPROJETER -- ce qui a un cout mesurable sur les totaux.

## --- LECTURE DES DONNEES : SECTION COMPLETE, NE RIEN MODIFIER --------------
# Les 7 tuiles sont livrees A PLAT dans datasets/, en .zip :
#   "datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R7_C20.zip"
#   "datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R8_C19.zip"
#   "datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R8_C21.zip"
#   "datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R9_C19.zip"
#   "datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R9_C20.zip"
#   "datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R9_C21.zip"
#   "datasets/GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R10_C20.zip"
zips <- list.files("datasets", pattern = "^GHS_POP_E2025.*\\.zip$",
                   full.names = TRUE)
cat("Tuiles GHS-POP ZIP trouvees :", length(zips), "\n")
if (length(zips) > 0) cat(paste("  ", basename(zips)), sep = "\n")

# Decompression dans outputs/ : une sortie n'ecrit JAMAIS dans datasets/.
dir.create("outputs/ghsl_tuiles", recursive = TRUE, showWarnings = FALSE)
for (z in zips) unzip(z, exdir = "outputs/ghsl_tuiles")
tifs <- list.files("outputs/ghsl_tuiles", pattern = "\\.tif$", full.names = TRUE)
cat("Fichiers TIF disponibles :", length(tifs), "\n")
## --------------------------------------------------------------------------

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Inspecter UNE tuile temoin (tifs[1]) : dimensions, cellules, nom du CRS,
# resolution, emprise, min/max.
# QUESTION : la resolution est-elle en metres ou en degres, ici ? Pourquoi
# n'est-ce pas la meme reponse que pour WorldPop ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# ASSEMBLER les tuiles :
#   - sprc(lapply(tifs, rast)) cree une SpatRasterCollection (attention :
#     sprc() prend une LISTE, pas un vecteur de chemins) ;
#   - mosaic(..., fun = "mean") les assemble ; fun traite les recouvrements
#     de bord.
# Puis INSTRUMENTER : nombre de tuiles assemblees, dimensions, CRS,
# resolution, emprise, et TOTAL AVANT DECOUPE (il couvre plus que le Cameroun).


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# REPROJETER la mosaique en EPSG:4326 avec method = "bilinear" (interpolation
# adaptee a une variable continue). Imprimer le CRS, la resolution en degres,
# et LE TOTAL APRES REPROJECTION.
#
# QUESTION CENTRALE : comparez le total avant et apres. Sont-ils identiques ?
# Pourquoi une reprojection de raster NE CONSERVE PAS LES SOMMES ? Que fait
# method = "near" a la place ? Et pourquoi ne peut-on pas, ici, appliquer la
# regle du module 4 (reprojeter le vecteur plutot que le raster) ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Decouper sur le Cameroun (crop + mask), COMPTER les cellules a valeur
# NEGATIVE (sentinelles nodata) et les recoder en NA -- AVANT tout calcul.
# Imprimer le total GHS-POP national.
# Enfin, sauvegarder : writeRaster(..., "outputs/J08_ghsl_pop_2025_cmr_100m.tif",
#                                  overwrite = TRUE, datatype = "FLT4S")
# Rappel : JAMAIS dans datasets/.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Extraire GHS-POP par region (exact_extract) et instrumenter.
# Puis imprimer LES TROIS TOTAUX NATIONAUX 2025 (WorldPop, GHS-POP, COD-PS) et
# LES TROIS ECARTS RELATIFS entre eux.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire regions_comparaison : NAME_1, pop_worldpop_2025, pop_ghsl_2025,
# pop_officielle, et les trois ecarts relatifs. Trier par valeur absolue de
# l'ecart GHSL - WorldPop. Imprimer le tableau, puis le nombre de regions ou
# GHSL > WorldPop, le nombre ou GHSL < WorldPop, et l'ecart median.
# Exporter en CSV dans "outputs/J08_comparaison_worldpop_ghsl_officiel.csv".
#
# QUESTION : l'ecart est-il SYSTEMATIQUE (une source toujours au-dessus) ou
# ERRATIQUE ? Lequel des deux est corrigeable, et lequel interdit d'utiliser
# les grilles pour comparer les regions entre elles ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer graphique_comparaison : trois barres par region (pivot_longer puis
# position = "dodge"), palette QUALITATIVE, legende en bas.
# Pourquoi "dodge" et surtout PAS "stack" ici ?
# Exporter dans "outputs/J08_comparaison_worldpop_ghsl_adm1.png".


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- trois sources cote a cote
## 1. Que sont exactement les trois barres ? Laquelle est un denombrement ?
##    (Piege : aucune.)
## 2. Pourquoi juxtaposer et non empiler ? Pourquoi une palette qualitative ?
## 3. Que lit-on ?
## 4. Que ne lit-on pas ? (indice : l'incertitude, qu'aucun des trois
##    producteurs ne publie sous forme cartographiable)
##
## Puis REDIGEZ UNE REGLE DE DECISION : dans quels cas preferer WorldPop, dans
## quels cas GHS-POP, et dans quel cas faut-il ABSOLUMENT les deux ?
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 8 -- COMMENT UNE GRILLE EST FABRIQUEE : BOTTOM-UP ET TOP-DOWN
## ============================================================================
##
## CE MODULE EST UN EXPOSE, PAS UN ATELIER. Il n'y a rien a coder : les
## covariables (GHS-BUILT, lumieres nocturnes, distance aux routes) et les
## donnees d'entrainement geolocalisees ne sont PAS dans le datasets/ de cette
## journee -- elles relevent du J09, du J10 et du J05. Le code de reference
## complet, commente, est dans script_etudiant_J08_corrige.R et dans
## demo_formateur_J08.qmd, en blocs non executes.
##
## CE QU'IL FAUT RETENIR, ET QUE VOUS DEVEZ POUVOIR REDIGER :
##
## TOP-DOWN (descendante) : on part du TOTAL CONNU et on le REDISTRIBUE sur
## les cellules proportionnellement a un poids construit sur des covariables.
##   pop(c) = P(u) * w(c) / somme des w dans u
## PROPRIETE : la somme est EXACTE PAR CONSTRUCTION. Force (coherence avec la
## source officielle) et limite (elle n'apporte RIEN que le recensement ne
## contenait deja au niveau administratif). C'est la methode de WorldPop
## constrained et de GHS-POP.
##
## BOTTOM-UP (ascendante) : on part d'OBSERVATIONS LOCALES, on modelise
## P ~ f(covariables), et on predit partout.
## PROPRIETE : la somme n'est PAS garantie -- et c'est parfois le resultat
## interessant. Seule famille utilisable quand le recensement est ancien,
## incomplet ou inexistant. Le prix : des observations de terrain couteuses, et
## une qualite qui depend de la REPRESENTATIVITE des zones observees.
##
## HYBRIDE : bottom-up pour la surface de densite, puis CALIBRAGE top-down.
##
## DESAGREGATION DASYMETRIQUE (grec dasys = dense, metron = mesure) : trois
## niveaux -- masque binaire (zones inhabitables a poids nul, deja le plus
## rentable), poids continus (surface batie, lumieres), poids modelises.
## "constrained" = le niveau 1 applique avec rigueur.
##
## ------------------------------------------------------------------------
## A REDIGER -- LE PIEGE DE LA "VALIDATION"
##
## a) Une grille dasymetrique top-down cree-t-elle de l'INFORMATION nouvelle a
##    l'interieur de l'unite administrative ?
## b) Si l'on agrege la grille sur les unites qui ont servi a la construire,
##    que vaut le total ? Qu'est-ce que cela prouve sur la qualite des
##    covariables ? (Refaites le raisonnement avec des poids TOTALEMENT
##    ALEATOIRES.)
## c) Quelle est alors la SEULE validation qui a du sens ? Quel module de cette
##    journee en donne un exemple ?
## d) RMSE et MAE : que penalise chacun ? Sur des effectifs tres asymetriques,
##    lequel est le plus grand, et que mesure l'ecart entre les deux ?
##    Pourquoi faut-il publier les deux ?
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 9 -- ATELIER : DESSINER SA ZONE ET COMPTER SES HABITANTS
## ============================================================================
##
## Aucune des zones que vous allez dessiner n'existe dans un fichier
## administratif. Et pourtant, en trois lignes, la grille donne un effectif.
##
## La version interactive (mapedit::editMap) est en bloc de reference
## ci-dessous : elle ATTEND qu'un humain dessine un polygone, donc elle ne peut
## pas s'executer dans un rendu automatique. A lancer en salle, en direct.

## ------------------------------------------------------------------------
## CODE DE REFERENCE - NON EXECUTE (a lancer en salle, console RStudio)
## Paquets requis : mapedit, leaflet.
## ------------------------------------------------------------------------
# tmap_mode("view")
# tm_basemap(c("Esri.WorldImagery", "OpenStreetMap")) +
#   tm_shape(pop_2025_cmr) +
#   tm_raster(col.scale = tm_scale_intervals(style = "quantile",
#                                            values = "brewer.yl_or_rd"),
#             col.legend = tm_legend(title = "hab/cellule"), col_alpha = 0.5) +
#   tm_title("Explorer et choisir une zone a analyser")
#
# ma_zone <- mapedit::editMap(
#   leaflet::leaflet() |>
#     leaflet::addProviderTiles("Esri.WorldImagery") |>
#     leaflet::setView(lng = 11.52, lat = 3.86, zoom = 12)
# )$finished
#
# res_zone <- effectif_zone(pop_2025, ma_zone, "Ma zone")

## --- 9.2 Le repli executable : une emprise definie par ses coordonnees ------

# Emprise rectangulaire centree sur le centre-ville de Yaounde.
# SECTION COMPLETE : modifier les quatre coordonnees pour deplacer la zone.
bbox_zone <- st_bbox(
  c(xmin = 11.48, ymin = 3.82, xmax = 11.58, ymax = 3.93),
  crs = st_crs(4326)
) |>
  st_as_sfc() |>
  st_as_sf()
cat("Zone d'etude : emprise ", paste(round(as.numeric(st_bbox(bbox_zone)), 4),
                                     collapse = " | "), "\n")

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Extraire l'effectif 2025 de la zone avec effectif_zone(), puis calculer sa
# SURFACE (en UTM 33N, jamais en degres) et sa DENSITE.
# Comparer cette densite a celle du Mfoundi entier. Que constatez-vous, et
# qu'est-ce que cela illustre du module 6 ?


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Refaire l'extraction pour 2015 et 2030 sur la MEME zone, et calculer la
# croissance 2015-2025 du quartier.


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Tracer carte_zone : le raster de la zone, la bordure de l'emprise en noir,
# et un titre qui affiche l'effectif. Exporter dans
# "outputs/J08_zone_personnalisee.png".
#
# ATTENTION : la discretisation en quantiles est recalculee SUR CETTE ZONE
# SEULEMENT. Ces couleurs sont-elles comparables a celles de la carte
# nationale du module 3 ?


## ------------------------------------------------------------------------
## INTERPRETATION A REDIGER -- l'effectif d'une zone dessinee
## 1. Que code exactement le chiffre du titre ?
## 2. crop + mask + global() compte-t-il les cellules de bordure ENTIEREMENT
##    ou AU PRORATA ? Et exact_extract() ? Sur une zone de quelques km2, la
##    difference est-elle negligeable ?
## 3. Que lit-on ?
## 4. Que ne lit-on pas ? Pourquoi l'incertitude d'un effectif de ZONE est-elle
##    plus grande que celle d'un effectif REGIONAL ? Un effectif de zone est
##    fiable en ordre de grandeur ou en valeur ?
##
## Puis : EN QUOI LE SPATIAL EST-IL UTILE ICI ? C'est la seule section de la
## journee qu'AUCUN tableau ne peut remplacer. Pourquoi ?
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## CONSIGNE D'ATELIER
## 1. Choisir une zone qui a un sens pour votre institution : aire de sante,
##    zone d'enquete, quartier d'intervention, perimetre urbain.
## 2. La dessiner (mapedit en direct) ou en ecrire l'emprise.
## 3. Calculer son effectif 2025, sa surface, sa densite.
## 4. COMPARER AVEC LA PERSONNE ASSISE A COTE qui a dessine "la meme" zone.
## 5. Ecrire en trois phrases : de combien vos deux chiffres different,
##    pourquoi, et quelle information supplementaire serait necessaire pour
##    trancher.
##
## La question 4 est la plus importante de la journee : deux traces "du meme
## quartier" donnent regulierement des effectifs qui different de 10 a 30 %.
## ------------------------------------------------------------------------


## ============================================================================
## EXPORTS
## ============================================================================

# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Exporter les trois tableaux de la journee en CSV dans outputs/ :
#   regions_pop          -> "outputs/J08_population_regions_worldpop_2015_2025.csv"
#   pop_villes           -> "outputs/J08_population_grandes_villes_2015_2025.csv"
#   comparaison_officiel -> "outputs/J08_ecart_worldpop_officiel_adm1.csv"


# ......................................................................
# >>> A COMPLETER
# ......................................................................
# Construire couche_finale : cmr1_pop enrichi des colonnes de regions_pop
# (pop_worldpop_2015, pop_worldpop_2025, variation, croissance_pct), puis
# l'ecrire en GeoPackage :
#   st_write(couche_finale, "outputs/J08_regions_population_complete.gpkg",
#            delete_dsn = TRUE)
# Instrumenter : nombre d'entites et de colonnes de la couche finale, et liste
# des fichiers ecrits dans outputs/.


## ============================================================================
## POUR FINIR -- LES QUATRE PIEGES DE RAISONNEMENT DE LA JOURNEE
## ============================================================================
## Vous devez pouvoir les definir et donner, pour chacun, un exemple pris dans
## ce script :
##
##   - MAUP : les resultats dependent de la maille (effet d'echelle + effet de
##     zonage). Aucune maille n'est neutre ; choisir celle de la DECISION.
##   - ERREUR ECOLOGIQUE : attribuer a un individu ce qui n'est vrai que de
##     l'agregat.
##   - PARADOXE DE SIMPSON : une correlation agregee peut etre de signe oppose
##     a la correlation individuelle.
##   - BIAIS DE TAILLE : la moyenne des densites regionales n'est pas la
##     densite nationale.
##
## Le glossaire complet, le recapitulatif des fonctions cles, les huit
## exercices et les prolongements vers le J09 et le J10 sont dans
## demo_formateur_J08.qmd.

## ============================================================================
## FIN DE LA TRAME J08
## ============================================================================
