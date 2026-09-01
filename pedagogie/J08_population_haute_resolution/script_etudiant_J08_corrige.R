## ============================================================================
## CORRIGE COMPLET -- J08 : COMPTER CHAQUE HABITANT, LA GRILLE DE POPULATION
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Yaounde
## Referents : J.S. Alogo, M. Teda, R. Dzita -- Support : R. Elandi
##
## CE FICHIER EST LE CORRIGE de script_etudiant_J08.R : il contient le code
## complet de tous les emplacements ">>> A COMPLETER" de la trame, dans le
## meme ordre et avec les memes commentaires.
##
## Il est DISTRIBUE EN FIN DE JOURNEE. Le lire avant d'avoir cherche fait
## perdre l'essentiel du benefice de l'atelier : ce qui s'apprend ici, c'est
## le reflexe de verifier une jointure, un CRS et une resolution AVANT de
## cartographier -- pas la syntaxe, qui est dans la documentation.
##
## Ce corrige est le miroir de demo_formateur_J08.qmd. Toute correction faite
## ici doit l'etre aussi dans le .qmd, qui est la SOURCE UNIQUE.
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
## Aucun recensement ne repond a cette question. Le recensement livre des
## effectifs par UNITE ADMINISTRATIVE, et ces unites ne coincident presque
## jamais avec le territoire d'une decision.
##
## Une GRILLE DE POPULATION y repond : un raster dont chaque cellule (ici
## 100 m x 100 m) porte un effectif estime d'habitants. Comme c'est une grille
## reguliere, on peut la decouper selon n'importe quelle forme.
##
## Le prix a payer est double, et c'est le coeur de la journee :
##   1. Une grille est un MODELE, pas une observation.
##   2. Deux grilles serieuses ne donnent pas le meme chiffre. Le module 7
##      mesure l'ecart, region par region.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## LES PAQUETS DE LA JOURNEE
##
## | Paquet        | Role                | A quoi il sert ici                  |
## | terra         | rasters             | rast, crop, mask, global, mosaic, project |
## | sf            | vecteurs            | GeoPackage GADM, reprojections, surfaces  |
## | exactextractr | statistiques zonales| exact_extract : somme ponderee par fraction de cellule |
## | dplyr         | tableaux            | filter, mutate, left_join, arrange   |
## | tidyr         | remise en forme     | pivot_longer (structure par age)     |
## | readr         | import CSV          | read_csv, write_csv                  |
## | ggplot2       | visualisation       | choropletes geom_sf, barres, series  |
## | tmap          | cartographie        | cartes raster classees -- API 4 obligatoire |
## | scales        | mise en forme       | separateurs de milliers, echelle log |
## | mapedit       | dessin interactif   | module 9 seulement, bloc non execute |
## | leaflet       | fond de carte       | idem                                 |
##
## ATTENTION -- tmap doit etre en version 4 ou superieure. Avec tmap 3, TOUS
## les blocs cartographiques echouent ("unused argument (col.scale)").
## install_packages_day.R le verifie.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Un reglage technique, pose une fois pour toutes
##
## Ce script commence par sf::sf_use_s2(FALSE). Par defaut, sf traite les
## coordonnees en degres sur une SPHERE (bibliotheque s2), plus juste mais
## beaucoup plus exigeant sur la proprete des geometries. GADM comporte
## regulierement des sommets dupliques et des micro-auto-intersections. On
## repasse au moteur PLANAIRE (GEOS), plus tolerant, et on repare a la lecture
## avec st_make_valid().
##
## Ce que cela n'autorise pas : mesurer sur des degres. Toute superficie de ce
## script est calculee APRES reprojection en UTM 33N (EPSG:32633).
## ----------------------------------------------------------------------

suppressPackageStartupMessages(library(sf))
sf::sf_use_s2(FALSE)

################################################################################
# ATELIER IFORD x GDSG 2026 - DONNEES SPATIALES, ANALYSE ET MANIPULATION DANS R
# J08 : Compter chaque habitant - la grille de population (CORRIGE)
################################################################################

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

# tmap : mode statique. Le mode "view" produit un widget leaflet qui embarque
# les geometries dans le HTML (plusieurs dizaines de Mo). Reserve aux blocs non
# executes, en salle et en direct.
tmap_mode("plot")

cat("Version de tmap :", as.character(packageVersion("tmap")), "\n")
cat("Version de terra :", as.character(packageVersion("terra")), "\n")
cat("Repertoire de travail :", getwd(), "\n")


## ============================================================================
## MODULE 1 -- DU TABLEAU A LA GRILLE : CE QU'UN CHOROPLETHE NE DIT PAS
## ============================================================================

## 1.1 Les deux sources et leur unite d'observation
##
## cmr_admpop_adm1_2025.csv -- COD-PS du Cameroun (HDX). Unite d'observation :
##   LA REGION ADMINISTRATIVE (ADM1). Dix lignes : effectif total, par sexe, et
##   ventilation par tranche d'age quinquennale. Un TABLEAU, sans geometrie.
##
## gadm41_CMR.gpkg -- limites GADM 4.1, GeoPackage MULTICOUCHE : ADM_ADM_0
##   (pays), ADM_ADM_1 (10 regions), ADM_ADM_2 (58 departements), ADM_ADM_3.
##   Une GEOMETRIE, sans demographie.
##
## Le premier geste de toute cartographie thematique est de les joindre. C'est
## aussi le geste ou l'on perd silencieusement des lignes.

# --- Lecture du tableau administratif ---------------------------------------
# Source : https://data.humdata.org/dataset/cod-ps-cmr
pop_adm1 <- read_csv("datasets/cmr_admpop_adm1_2025.csv", show_col_types = FALSE)

# INSTRUMENTATION : ce que le fichier contient reellement.
# Regle : le fichier de donnees fait autorite, jamais le code.
cat("cmr_admpop_adm1_2025.csv\n")
cat("  lignes   :", nrow(pop_adm1), "\n")
cat("  colonnes :", ncol(pop_adm1), "\n")
cat("  noms     :", paste(names(pop_adm1), collapse = " | "), "\n")
cat("  NA total :", sum(is.na(pop_adm1)), "\n")

# --- Lecture des limites administratives ------------------------------------
# Le GeoPackage est MULTICOUCHE : on inspecte avant de lire.
print(st_layers("datasets/gadm41_CMR.gpkg"))

cmr1 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_1", quiet = TRUE) |>
  st_make_valid()

cat("\nCouche ADM_ADM_1\n")
cat("  entites          :", nrow(cmr1), "\n")
cat("  colonnes         :", paste(names(cmr1), collapse = " | "), "\n")
cat("  CRS              :", st_crs(cmr1)$input, "\n")
cat("  geometries valides :", sum(st_is_valid(cmr1)), "/", nrow(cmr1), "\n")
cat("  emprise          :", paste(round(as.numeric(st_bbox(cmr1)), 3),
                                  collapse = " | "), "\n")
print(cmr1 |> st_drop_geometry() |> select(any_of(c("GID_1", "NAME_1"))))


## ------------------------------------------------------------------------
## 1.2 CHOISIR LA CLE DE JOINTURE : ADM1_FR OU ADM1_EN ?
##
## Le CSV porte DEUX colonnes de nom de region. GADM n'en porte qu'une,
## NAME_1. Le Cameroun est bilingue et les deux nomenclatures different
## reellement : Adamaoua / Adamawa, Extreme-Nord / Far North. Un left_join()
## sur la mauvaise colonne NE LEVE AUCUNE ERREUR : il remplit la colonne de
## population de NA, et la carte qui suit affiche dix polygones vides -- ou
## pire, quelques polygones renseignes et le reste en blanc, ce qui passe pour
## un resultat.
##
## On ne devine pas : on compte.
## ------------------------------------------------------------------------

# --- Comparer les deux nomenclatures AVANT de joindre -----------------------
cat("GADM NAME_1 :\n"); print(sort(cmr1$NAME_1))
cat("\nCSV ADM1_EN :\n"); print(sort(pop_adm1$ADM1_EN))
cat("\nCSV ADM1_FR :\n"); print(sort(pop_adm1$ADM1_FR))

# Combien de noms GADM trouvent preneur dans chaque colonne candidate ?
n_match_en <- sum(cmr1$NAME_1 %in% pop_adm1$ADM1_EN)
n_match_fr <- sum(cmr1$NAME_1 %in% pop_adm1$ADM1_FR)

cat("\nAppariements NAME_1 -> ADM1_EN :", n_match_en, "/", nrow(cmr1), "\n")
cat("Appariements NAME_1 -> ADM1_FR :", n_match_fr, "/", nrow(cmr1), "\n")
cat("\nNoms GADM absents de ADM1_EN :",
    paste(setdiff(cmr1$NAME_1, pop_adm1$ADM1_EN), collapse = ", "), "\n")
cat("Noms GADM absents de ADM1_FR :",
    paste(setdiff(cmr1$NAME_1, pop_adm1$ADM1_FR), collapse = ", "), "\n")

# La cle n'est PAS ecrite en dur : elle est choisie par les donnees.
cle_retenue <- if (n_match_en >= n_match_fr) "ADM1_EN" else "ADM1_FR"
cle_ecartee <- setdiff(c("ADM1_EN", "ADM1_FR"), cle_retenue)
cat("\n>>> Cle de jointure retenue :", cle_retenue,
    "  (cle ecartee :", cle_ecartee, ")\n")

## ------------------------------------------------------------------------
## POURQUOI NE PAS ECRIRE LA CLE EN DUR ?
##
## Ecrire by = c("NAME_1" = "ADM1_FR") est une AFFIRMATION, pas une
## verification. Si GADM change de nomenclature ou si le COD-PS est republie
## avec des libelles revises, la jointure tombe en silence et la carte devient
## fausse sans que rien ne previenne.
##
## Le code ci-dessus MESURE le nombre d'appariements de chaque candidate et
## choisit celle qui gagne, en affichant le decompte. Trois lignes de plus, et
## la jointure devient auto-diagnostique.
##
## Regle generale : ne jamais joindre sur un libelle sans avoir compte les
## non-appariements. Et si aucune des deux colonnes n'apparie tout, la solution
## n'est pas de bricoler la casse ou les accents, mais d'ecrire une TABLE DE
## CORRESPONDANCE A LA MAIN : c'est une decision de methode, elle doit etre
## visible.
## ------------------------------------------------------------------------

# --- Jointure --------------------------------------------------------------
# On part de la COUCHE GEOGRAPHIQUE et on lui adjoint le tableau.
# L'inverse (tableau |> left_join(couche)) perd la classe sf et la geometrie.
pop_adm1 <- pop_adm1 |> mutate(cle_region = .data[[cle_retenue]])

cmr1_pop <- cmr1 |>
  left_join(
    pop_adm1 |> select(cle_region, any_of(c("ADM1_PCODE", "T_TL", "F_TL", "M_TL"))),
    by = c("NAME_1" = "cle_region")
  )

# INSTRUMENTATION OBLIGATOIRE apres jointure : effectifs et NA.
cat("Lignes avant jointure :", nrow(cmr1), "\n")
cat("Lignes apres jointure :", nrow(cmr1_pop), "\n")
cat("Regions sans effectif (NA dans T_TL) :", sum(is.na(cmr1_pop$T_TL)), "\n")
cat("Lignes du CSV jamais appariees :",
    sum(!pop_adm1$cle_region %in% cmr1$NAME_1), "\n")
cat("Population totale jointe :",
    format(sum(cmr1_pop$T_TL, na.rm = TRUE), big.mark = " "), "\n")

## ------------------------------------------------------------------------
## TROIS COMPTEURS, TROIS PATHOLOGIES DIFFERENTES
##
## - Lignes avant != lignes apres -> la jointure a DUPLIQUE des polygones : la
##   cle n'est pas unique du cote du tableau. Toute somme double-compte.
## - NA dans T_TL -> des polygones n'ont PAS trouve leur ligne. Ils
##   apparaitront en GRIS sur la carte, jamais a zero.
## - Lignes du CSV jamais appariees -> le tableau contient des unites que la
##   carte ignore (cas classique : 12 "regions d'enquete" pour 10 regions
##   administratives). Aucun traitement de chaine ne devine cela.
##
## Les trois se lisent en trois cat(). Aucun ne leve d'erreur si on ne les
## ecrit pas.
## ------------------------------------------------------------------------


## --- 1.3 Le choropleth de la population totale ------------------------------

carte_choropleth <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = T_TL), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(
    option   = "plasma",
    labels   = label_comma(big.mark = " "),
    na.value = "grey80"          # regle : pas de donnee = GRIS, pas zero
  ) +
  labs(
    title    = "Population par region, Cameroun 2025",
    subtitle = "Common Operational Dataset - Population Statistics (COD-PS)",
    fill     = "Habitants",
    caption  = "Gris = region sans effectif apparie"
  ) +
  theme_minimal()

print(carte_choropleth)

ggsave("outputs/J08_choropleth_population_adm1.png", carte_choropleth,
       width = 7, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- CARTE CHOROPLETHE DE LA POPULATION REGIONALE
##
## CE QUE LA FIGURE CODE. La couleur code T_TL, l'EFFECTIF TOTAL de population
## residente projete pour 2025, pour la region entiere. Ni une densite, ni un
## taux : un VOLUME. Une region grande et peu peuplee peut afficher la meme
## couleur qu'une region petite et dense. Les polygones gris n'ont PAS
## d'effectif apparie : ils ne sont pas a zero, ils sont NON RENSEIGNES.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Palette viridis/plasma SEQUENTIELLE : une
## seule direction, adaptee a une grandeur qui n'a qu'un sens de lecture. Une
## palette DIVERGENTE ne s'emploierait que si la variable avait un point
## d'equilibre naturel (le ratio F/H au module 2). Echelle CONTINUE, sans
## discretisation : honnete sur le continuum, mais rend la lecture de valeurs
## precises difficile. na.value = "grey80" empeche ggplot2 de faire disparaitre
## un polygone sans donnee dans le fond blanc.
##
## CE QUI SE LIT. La hierarchie des poids demographiques regionaux, et le
## regroupement visuel des regions les plus peuplees quand il existe.
##
## CE QUI NE SE LIT PAS. RIEN de la repartition A L'INTERIEUR d'une region. Une
## region dont 80 % des habitants vivent dans une seule agglomeration et une
## region uniformement peuplee recoivent la meme couleur. C'est la limite que
## la grille, a partir du module 3, va lever. Ne se lit pas non plus la
## DENSITE : la surface du polygone n'est pas neutralisee.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI -- ET CE QU'IL NE FAIT PAS ENCORE
##
## A ce stade, la carte n'apporte presque RIEN que le tableau ne contienne.
## Ce qu'elle ajoute est la CONTIGUITE -- voir que les regions les plus
## peuplees se touchent, ou s'opposent d'un bout a l'autre du pays. Un bloc
## contigu de fortes valeurs n'est pas explicable par les caracteristiques
## propres de chaque region : il signale quelque chose que les regions
## partagent PARCE QU'ELLES SONT VOISINES.
##
## C'est peu. Le vrai apport du spatial commence au module 3.
## ------------------------------------------------------------------------


## --- 1.4 Le contre-exemple : la meme carte avec la mauvaise cle -------------

cmr1_faux <- cmr1 |>
  left_join(
    pop_adm1 |>
      mutate(cle_fausse = .data[[cle_ecartee]]) |>
      select(cle_fausse, T_TL),
    by = c("NAME_1" = "cle_fausse")
  )

cat("Jointure sur", cle_ecartee, ":", sum(is.na(cmr1_faux$T_TL)),
    "regions sur", nrow(cmr1_faux), "sans effectif\n")
cat("Population totale obtenue :",
    format(sum(cmr1_faux$T_TL, na.rm = TRUE), big.mark = " "),
    "  (au lieu de ", format(sum(cmr1_pop$T_TL, na.rm = TRUE), big.mark = " "),
    ")\n", sep = "")

carte_fausse <- ggplot(cmr1_faux) +
  geom_sf(aes(fill = T_TL), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "plasma", labels = label_comma(big.mark = " "),
                       na.value = "grey80") +
  labs(
    title    = paste0("CONTRE-EXEMPLE : jointure sur ", cle_ecartee),
    subtitle = "Aucune erreur R n'a ete levee. Le gris est la seule alerte.",
    fill     = "Habitants"
  ) +
  theme_minimal()

print(carte_fausse)

ggsave("outputs/J08_cle_jointure_contre_exemple.png", carte_fausse,
       width = 7, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- LE CONTRE-EXEMPLE
##
## CE QUE LA FIGURE CODE. La meme variable, jointe sur la colonne de nom qui NE
## CORRESPOND PAS a la nomenclature GADM.
##
## CE QUE LES CHOIX TECHNIQUES FONT. left_join() conserve TOUTES les lignes de
## gauche -- sur pour une couche geographique (on ne perd jamais un polygone),
## dangereux pour l'analyste (rien ne signale l'echec). Un inner_join() aurait
## fait disparaitre les regions non appariees : plus visible, mais la surface
## du pays aurait ete fausse. na.value = "grey80" est ici le dispositif
## d'alerte.
##
## CE QUI SE LIT. Le nombre de regions grises, et l'effondrement du total
## imprime juste au-dessus.
##
## CE QUI NE SE LIT PAS. Le fait que ce soit une ERREUR, si l'on n'a pas le
## total de reference. Une carte partiellement grise ressemble a une carte
## "donnees manquantes dans certaines regions", situation banale. D'ou la regle
## : imprimer sum(is.na(...)) AVANT de tracer, pas apres.
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 2 -- LIRE LA STRUCTURE DEMOGRAPHIQUE
## ============================================================================
##
## Le COD-PS ne donne pas qu'un total : il donne la ventilation par SEXE et par
## TRANCHE D'AGE quinquennale. C'est ce qui distingue une source demographique
## d'un simple denombrement, et c'est precisement ce que les grilles de
## population des modules suivants NE SAVENT PAS FAIRE.

## --- 2.1 Le ratio femmes / hommes -------------------------------------------

cmr1_pop <- cmr1_pop |>
  mutate(ratio_fm = F_TL / M_TL)

# INSTRUMENTATION : la variable derivee est-elle plausible ?
cat("Ratio F/H : min =", round(min(cmr1_pop$ratio_fm, na.rm = TRUE), 3),
    "| median =", round(median(cmr1_pop$ratio_fm, na.rm = TRUE), 3),
    "| max =", round(max(cmr1_pop$ratio_fm, na.rm = TRUE), 3), "\n")
cat("Regions avec ratio manquant :", sum(is.na(cmr1_pop$ratio_fm)), "\n")
cat("Ratio national :",
    round(sum(cmr1_pop$F_TL, na.rm = TRUE) / sum(cmr1_pop$M_TL, na.rm = TRUE), 3),
    "\n")

carte_ratio <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = ratio_fm), colour = "white", linewidth = 0.3) +
  scale_fill_gradient2(
    low      = "#2166AC",
    mid      = "white",
    high     = "#B2182B",
    midpoint = 1,                # valeur d'equilibre d'un ratio F/H
    labels   = label_number(accuracy = 0.01),
    na.value = "grey80"
  ) +
  labs(
    title    = "Ratio femmes / hommes par region, Cameroun 2025",
    subtitle = "Blanc = parite exacte (1,00) ; bleu = moins de femmes ; rouge = plus de femmes",
    fill     = "F / H"
  ) +
  theme_minimal()

print(carte_ratio)

ggsave("outputs/J08_ratio_femmes_hommes_adm1.png", carte_ratio,
       width = 7, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- RATIO FEMMES / HOMMES
##
## CE QUE LA FIGURE CODE. Le rapport F_TL / M_TL : nombre de femmes RESIDENTES
## pour un homme resident, tous ages confondus. Ce n'est PAS le rapport de
## masculinite des demographes (hommes pour 100 femmes, souvent a la
## naissance) ; c'est son inverse, sur l'ensemble de la population. Deux
## indicateurs voisins, deux lectures opposees.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Palette DIVERGENTE, scale_fill_gradient2()
## avec midpoint = 1. Choix decisif : une palette sequentielle aurait range les
## regions du "moins" au "plus" sans marquer le seuil ; la divergente pose la
## PARITE COMME REFERENCE et fait apparaitre de quel cote et de combien chaque
## region s'en ecarte. Le blanc n'est pas "peu de femmes" : c'est "autant de
## femmes que d'hommes". Le midpoint est un CHOIX EDITORIAL.
##
## CE QUI SE LIT. Les desequilibres de sexe entre regions, et leur sens. Un
## excedent feminin regional s'interprete le plus souvent comme la trace d'une
## MIGRATION DE TRAVAIL MASCULINE sortante ; un excedent masculin, comme une
## zone d'arrivee.
##
## CE QUI NE SE LIT PAS. L'AGE : un desequilibre concentre sur les 20-40 ans
## (migration) et un desequilibre etale sur tous les ages (surmortalite
## masculine) donnent le meme ratio global. Ni l'ampleur demographique du
## phenomene, ni l'incertitude de deux estimations projetees.
## ------------------------------------------------------------------------


## --- 2.2 La part des moins de 15 ans ----------------------------------------

# Les colonnes d'age sont T_00_04, T_05_09, ... T_80Plus. On ne les ecrit pas
# en dur : on verifie leur presence avant de sommer.
cols_jeunes <- intersect(c("T_00_04", "T_05_09", "T_10_14"), names(pop_adm1))
cat("Colonnes d'age 0-14 trouvees :", paste(cols_jeunes, collapse = ", "),
    "  (", length(cols_jeunes), "/3 )\n", sep = "")

jeunes <- pop_adm1 |>
  mutate(
    jeunes_0_14     = rowSums(across(all_of(cols_jeunes)), na.rm = TRUE),
    part_jeunes_pct = 100 * jeunes_0_14 / T_TL
  ) |>
  select(cle_region, jeunes_0_14, part_jeunes_pct)

cmr1_pop <- cmr1_pop |>
  left_join(jeunes, by = c("NAME_1" = "cle_region"))

cat("Regions sans part de jeunes :", sum(is.na(cmr1_pop$part_jeunes_pct)), "\n")
cat("Part nationale des 0-14 ans :",
    round(100 * sum(cmr1_pop$jeunes_0_14, na.rm = TRUE) /
                sum(cmr1_pop$T_TL, na.rm = TRUE), 1), "%\n")
print(cmr1_pop |> st_drop_geometry() |>
        select(NAME_1, T_TL, jeunes_0_14, part_jeunes_pct) |>
        arrange(desc(part_jeunes_pct)))

carte_jeunes <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = part_jeunes_pct), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "magma", na.value = "grey80") +
  labs(
    title    = "Part de la population de moins de 15 ans",
    subtitle = "Cameroun, 2025 - COD-PS",
    fill     = "% 0-14 ans"
  ) +
  theme_minimal()

print(carte_jeunes)

ggsave("outputs/J08_part_population_jeune_adm1.png", carte_jeunes,
       width = 7, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- PART DES MOINS DE 15 ANS
##
## CE QUE LA FIGURE CODE. (T_00_04 + T_05_09 + T_10_14) / T_TL, en %.
## Definition exacte : PROPORTION D'ENFANTS DE 0 A 14 ANS REVOLUS dans la
## population residente totale de la region. Ce n'est ni le taux de natalite,
## ni le taux de dependance des jeunes (denominateur 15-64 ans, valeurs plus
## elevees).
##
## CE QUE LES CHOIX TECHNIQUES FONT. Palette SEQUENTIELLE magma (pas de point
## d'equilibre naturel). Echelle CONTINUE : sur dix unites, une discretisation
## en quantiles creerait des classes d'une ou deux regions, donnant l'apparence
## de seuils la ou il n'y a qu'un continuum. La normalisation par T_TL
## transforme un VOLUME en PROPORTION, ce qui rend les regions comparables
## independamment de leur taille.
##
## CE QUI SE LIT. Le gradient de jeunesse demographique entre regions ; les
## regions concernees se touchent generalement, indice d'un regime
## demographique regional et non d'une particularite locale.
##
## CE QUI NE SE LIT PAS. La CAUSE : fecondite elevee, mortalite adulte elevee
## ou emigration des adultes se ressemblent ici. Ni l'EFFECTIF : 40 % de jeunes
## dans une region de 500 000 habitants et 30 % dans une region de 4 millions
## ne representent pas le meme nombre d'ecoles a construire.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI
##
## Le tableau imprime au-dessus donne le classement exact -- la carte est moins
## precise que lui. Ce qu'elle apporte :
## - LA CONTIGUITE : si les regions les plus jeunes forment un bloc, la
##   variable a expliquer n'est plus "pourquoi cette region ?" mais "pourquoi
##   cette ZONE ?" ;
## - L'ECART ENTRE DEUX CARTES : superposer celle-ci et celle du ratio F/H
##   revele les regions a la fois jeunes et deficitaires en hommes, profil
##   typique d'un espace d'emigration de travail ;
## - LE REPERAGE DE CE QUI MANQUE : un polygone gris se voit immediatement sur
##   une carte, jamais dans un tri decroissant.
## ------------------------------------------------------------------------


## --- 2.3 Deux pyramides des ages comparees ----------------------------------

# Les deux regions comparees ne sont pas ecrites en dur : on prend celle qui a
# la plus forte part de jeunes et celle qui a la plus faible.
classement <- cmr1_pop |>
  st_drop_geometry() |>
  filter(!is.na(part_jeunes_pct)) |>
  arrange(desc(part_jeunes_pct))

regions_a_comparer <- c(classement$NAME_1[1],
                        classement$NAME_1[nrow(classement)])
cat("Regions comparees :", paste(regions_a_comparer, collapse = " vs "), "\n")

cols_age <- setdiff(grep("^T_", names(pop_adm1), value = TRUE), "T_TL")
cat("Tranches d'age disponibles :", length(cols_age), "->",
    paste(cols_age, collapse = ", "), "\n")

pop_age <- pop_adm1 |>
  filter(cle_region %in% regions_a_comparer) |>
  select(cle_region, all_of(cols_age)) |>
  pivot_longer(cols = all_of(cols_age),
               names_to = "groupe_age", values_to = "population") |>
  mutate(
    groupe_age = sub("^T_", "", groupe_age),
    groupe_age = gsub("_", "-", groupe_age),
    groupe_age = sub("Plus", "+", groupe_age),
    groupe_age = factor(groupe_age, levels = unique(groupe_age))
  ) |>
  group_by(cle_region) |>
  mutate(part_pct = 100 * population / sum(population, na.rm = TRUE)) |>
  ungroup()

cat("Lignes apres pivot_longer :", nrow(pop_age),
    "( attendu :", length(regions_a_comparer) * length(cols_age), ")\n")

graphique_pyramide <- ggplot(pop_age,
                             aes(x = groupe_age, y = part_pct, fill = cle_region)) +
  geom_col(position = "dodge") +
  scale_fill_brewer(palette = "Set1") +
  labs(
    title    = "Structure par age : deux regions aux profils opposes",
    subtitle = "Part de chaque tranche quinquennale dans la population regionale, 2025",
    x        = "Groupe d'age",
    y        = "% de la population regionale",
    fill     = "Region"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(graphique_pyramide)

ggsave("outputs/J08_pyramide_deux_regions.png", graphique_pyramide,
       width = 8, height = 5, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- STRUCTURE PAR AGE COMPAREE
##
## CE QUE LA FIGURE CODE. La hauteur de chaque barre code la PART (en %) de la
## tranche quinquennale dans la population DE SA PROPRE REGION, et non
## l'effectif. Difference decisive : entre une region de 4 millions et une de
## 1 million, la comparaison des effectifs ne montre que la taille des regions,
## jamais leur structure.
##
## CE QUE LES CHOIX TECHNIQUES FONT. pivot_longer() transforme le tableau LARGE
## en tableau LONG, seule forme que ggplot2 sait cartographier en barres
## groupees. La normalisation par le total regional rend les deux profils
## superposables. position = "dodge" juxtapose au lieu d'empiler : empiler
## additionnerait deux regions, ce qui n'a aucun sens. Palette QUALITATIVE
## (Set1) : deux regions ne sont pas ordonnees entre elles.
##
## CE QUI SE LIT. La forme du regime demographique : base large et decroissance
## rapide = fecondite elevee ; profil plus rectangulaire dans les ages actifs =
## region de destination migratoire ou transition plus avancee.
##
## CE QUI NE SE LIT PAS. Le SEXE (c'est le total T_ ; une vraie pyramide
## opposerait F_ et M_ dos a dos). Ni la source : ce sont des PROJECTIONS 2025
## issues d'un modele de composants, pas un denombrement. Enfin, un profil
## regional moyen ecrase l'ecart entre chef-lieu urbain et arrondissements
## ruraux.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## CE QUE LES GRILLES DE POPULATION NE SAURONT PAS FAIRE
##
## A partir du module 3, on travaille sur des rasters qui donnent un EFFECTIF
## TOTAL PAR CELLULE et RIEN D'AUTRE. Ni sexe, ni age, ni menage.
##
## Consequence pratique : pour estimer une POPULATION SCOLARISABLE dans une
## zone dessinee a la main, on ne peut pas lire l'age dans la grille. La
## methode est d'appliquer a l'effectif total la PART DES 0-14 ANS DE L'UNITE
## ADMINISTRATIVE ENGLOBANTE, calculee ici. Hypothese forte -- structure par
## age homogene a l'interieur de la region -- et cas d'ecole d'ERREUR
## ECOLOGIQUE (module 6). Il faut l'ecrire a cote du chiffre, pas la taire.
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 3 -- OUVRIR UNE GRILLE : WORLDPOP 100 M
## ============================================================================

## 3.1 Ce qu'est un raster de population
##
## Trois proprietes suffisent a decrire un raster, et il faut LES VERIFIER
## AVANT TOUT CALCUL : l'EMPRISE, le CRS (qui dit ce que MESURENT les
## coordonnees : degres ? metres ?), et la RESOLUTION (dans l'unite du CRS).
##
## La quatrieme propriete est SEMANTIQUE et n'est ecrite nulle part : que
## represente la valeur d'une cellule ? Pour WorldPop constrained, c'est le
## NOMBRE ESTIME DE PERSONNES RESIDANT DANS LA CELLULE -- grandeur EXTENSIVE,
## qui s'additionne. Pour un raster de densite ou de temperature, la valeur est
## INTENSIVE et se MOYENNE. Confondre les deux est l'erreur la plus frequente.

pop_2025 <- rast("datasets/cmr_pop_2025_CN_100m_R2025A_v1.tif")

# INSTRUMENTATION OBLIGATOIRE apres chaque lecture de raster.
cat("cmr_pop_2025_CN_100m_R2025A_v1.tif\n")
cat("  dimensions (lignes, colonnes, couches) :", paste(dim(pop_2025), collapse = " x "), "\n")
cat("  nombre de cellules                      :", format(ncell(pop_2025), big.mark = " "), "\n")
cat("  resolution (unites du CRS)              :", paste(res(pop_2025), collapse = " x "), "\n")
cat("  CRS                                     :", crs(pop_2025, describe = TRUE)$name, "\n")
cat("  code EPSG                               :", crs(pop_2025, describe = TRUE)$code, "\n")
cat("  emprise xmin/xmax                       :", xmin(pop_2025), "/", xmax(pop_2025), "\n")
cat("  emprise ymin/ymax                       :", ymin(pop_2025), "/", ymax(pop_2025), "\n")
cat("  valeur minimale                         :", round(minmax(pop_2025)[1], 4), "\n")
cat("  valeur maximale                         :", round(minmax(pop_2025)[2], 2), "\n")
print(pop_2025)

## ------------------------------------------------------------------------
## LIRE LA RESOLUTION : "100 M" N'APPARAIT NULLE PART
##
## Si le CRS est EPSG:4326, la resolution s'affiche en DEGRES -- typiquement
## 0,00083333, soit 1/1200 de degre, soit environ 92,7 m a l'equateur. Le nom
## du fichier annonce 100 m ; le fichier travaille en degres.
##
## Consequence : UNE CELLULE N'A PAS LA MEME SURFACE AU SUD ET AU NORD DU
## CAMEROUN. En latitude, le degre vaut toujours ~111 km ; en longitude,
## 111 km x cos(latitude), donc ~110,9 km a 2 N et ~108,2 km a 13 N.
##
## Cela ne gene pas la SOMME des effectifs, mais cela interdit de calculer une
## densite en divisant par "nombre de cellules x 0,01 km2". Pour toute surface,
## on reprojette -- c'est ce que fait le module 6.
## ------------------------------------------------------------------------


## --- 3.2 Decouper le raster sur le pays et le cartographier -----------------

cmr0 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_0", quiet = TRUE) |>
  st_make_valid()
cat("Couche ADM_ADM_0 : ", nrow(cmr0), " entite(s), CRS ", st_crs(cmr0)$input, "\n", sep = "")

# crop() reduit a l'emprise rectangulaire ; mask() met a NA hors du polygone.
# Les deux sont necessaires : crop seul laisserait les coins du rectangle.
cmr0_v       <- vect(st_transform(cmr0, crs(pop_2025)))
pop_2025_cmr <- mask(crop(pop_2025, cmr0_v), cmr0_v)

cat("Apres crop + mask :\n")
cat("  cellules            :", format(ncell(pop_2025_cmr), big.mark = " "), "\n")
cat("  cellules non vides  :",
    format(as.integer(global(!is.na(pop_2025_cmr), "sum", na.rm = TRUE)[[1]]),
           big.mark = " "), "\n")
cat("  total national 2025 :",
    format(round(global(pop_2025_cmr, "sum", na.rm = TRUE)$sum), big.mark = " "),
    "habitants\n")

carte_grille <- tm_shape(pop_2025_cmr) +
  tm_raster(
    col.scale  = tm_scale_intervals(n = 7, style = "quantile",
                                    values = "brewer.yl_or_rd"),
    col.legend = tm_legend(title = "Habitants par cellule")
  ) +
  tm_shape(cmr1) +
  tm_borders(col = "grey40", lwd = 0.4) +
  tm_title("Population carroyee WorldPop constrained 2025 - Cameroun")

print(carte_grille)

tmap_save(carte_grille, "outputs/J08_grille_population_2025.png",
          width = 8, height = 7, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- LA GRILLE WORLDPOP 2025
##
## CE QUE LA FIGURE CODE. Le NOMBRE ESTIME D'HABITANTS RESIDANT DANS UNE
## CELLULE DE ~100 M DE COTE. Pas une densite : un effectif. Les zones blanches
## sont des cellules a NA ou a zero : WorldPop constrained n'attribue de
## population QU'AUX CELLULES OU UN BATI A ETE DETECTE -- c'est ce que signifie
## "constrained".
##
## CE QUE LES CHOIX TECHNIQUES FONT. Discretisation en QUANTILES (7 classes) :
## chaque classe contient a peu pres le meme nombre de cellules. Seul choix
## lisible sur une distribution aussi dissymetrique. Comparons :
##   - INTERVALLES EGAUX : 7 tranches de largeur identique ; plus de 99 % des
##     cellules dans la premiere. Carte EXACTE et ILLISIBLE ;
##   - JENKS / FISHER : seuils minimisant la variance intra-classe ; meilleur
##     compromis local, mais DEUX CARTES JENKS NE SONT PAS COMPARABLES ;
##   - QUANTILES : lisibilite garantie, mais les seuils n'ont AUCUNE
##     signification substantielle.
## Palette brewer.yl_or_rd SEQUENTIELLE en teinte ET en luminosite, donc
## lisible en niveaux de gris et par la plupart des daltonismes.
##
## CE QUI SE LIT. La geographie reelle du peuplement : agglomerations en taches
## compactes, axes routiers en lignes, vides. L'armature urbaine du pays, ce
## qu'aucune carte administrative ne montre.
##
## CE QUI NE SE LIT PAS. A l'echelle nationale, un pixel AFFICHE agrege des
## centaines de cellules : c'est un REECHANTILLONNAGE D'AFFICHAGE, pas la
## donnee. Ni la QUALITE LOCALE de l'estimation. Et l'absence de valeur ne
## prouve pas l'absence d'habitants : elle prouve l'absence de bati DETECTE.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI -- LA RUPTURE DU MODULE 3
##
## Le choropleth du module 1 etait une carte D'UNITES. La grille est une carte
## DU PHENOMENE : le peuplement y apparait avec sa forme propre.
##
## Ce que la grille apporte, et qu'AUCUN tableau administratif ne contient :
##   - elle est DECOUPABLE A VOLONTE (module 4, trois lignes) ;
##   - elle rend visible l'HETEROGENEITE INTERNE des unites administratives,
##     donc elle protege de l'erreur ecologique ;
##   - elle montre OU IL N'Y A PERSONNE.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## CODE DE REFERENCE - NON EXECUTE
## Raison technique : tmap_mode("view") produit un widget leaflet qui embarque
## le raster et les geometries dans le HTML. Sur une grille nationale a 100 m,
## le document depasserait plusieurs dizaines de Mo. A executer en direct dans
## la console RStudio, pas au rendu.
## ------------------------------------------------------------------------
# tmap_mode("view")
#
# tm_shape(pop_2025_cmr) +
#   tm_raster(
#     col.scale  = tm_scale_intervals(n = 7, style = "quantile",
#                                     values = "brewer.yl_or_rd"),
#     col.legend = tm_legend(title = "Habitants par cellule"),
#     col_alpha  = 0.8
#   ) +
#   tm_shape(cmr1) +
#   tm_borders(col = "grey30", lwd = 0.5)
#
# tmap_mode("plot")


## ============================================================================
## MODULE 4 -- EXTRAIRE UN EFFECTIF : LE MFOUNDI EN 2015, 2025 ET 2030
## ============================================================================

## 4.1 La sequence crop -> mask -> global

cmr2 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_2", quiet = TRUE) |>
  st_make_valid()

cat("Couche ADM_ADM_2\n")
cat("  departements :", nrow(cmr2), "\n")
cat("  colonnes     :", paste(names(cmr2), collapse = " | "), "\n")
cat("  CRS          :", st_crs(cmr2)$input, "\n")

# Yaounde correspond au departement du Mfoundi (region du Centre).
yaounde <- cmr2 |> filter(NAME_2 == "Mfoundi")
cat("  Entites 'Mfoundi' trouvees :", nrow(yaounde), "\n")
if (nrow(yaounde) == 0)
  cat("  ATTENTION : verifier l'orthographe dans cmr2$NAME_2\n")

# --- Une fonction, appelee pour les trois millesimes ------------------------
# Ecrire trois fois la meme sequence, c'est trois occasions de se tromper de
# CRS. On l'enferme une fois pour toutes.
effectif_zone <- function(raster, zone, etiquette = "") {
  # 1) Harmoniser les CRS : le polygone va AU raster, jamais l'inverse
  #    (reprojeter un raster resample les valeurs et modifie les totaux).
  zone_v <- vect(st_transform(zone, crs(raster)))
  # 2) crop() puis mask()
  r      <- mask(crop(raster, zone_v), zone_v)
  # 3) global() somme les cellules retenues
  total  <- global(r, "sum", na.rm = TRUE)$sum
  cat(etiquette, ": ", format(round(total), big.mark = " "), " habitants",
      "  | cellules retenues : ",
      format(as.integer(global(!is.na(r), "sum", na.rm = TRUE)[[1]]), big.mark = " "),
      "\n", sep = "")
  list(raster = r, total = total)
}

pop_2015 <- rast("datasets/cmr_pop_2015_CN_100m_R2025A_v1.tif")
pop_2030 <- rast("datasets/cmr_pop_2030_CN_100m_R2025A_v1.tif")

# INSTRUMENTATION : les trois millesimes sont-ils comparables ?
cat("Comparabilite des trois grilles\n")
for (nm in c("2015", "2025", "2030")) {
  r <- get(paste0("pop_", nm))
  cat("  ", nm, " : res =", paste(round(res(r), 8), collapse = " x "),
      "| dim =", paste(dim(r), collapse = " x "),
      "| EPSG =", crs(r, describe = TRUE)$code, "\n")
}
cat("  Grilles alignees (memes dimensions) :",
    identical(dim(pop_2015), dim(pop_2025)) && identical(dim(pop_2025), dim(pop_2030)),
    "\n\n")

yde_2015 <- effectif_zone(pop_2015, yaounde, "Mfoundi 2015")
yde_2025 <- effectif_zone(pop_2025, yaounde, "Mfoundi 2025")
yde_2030 <- effectif_zone(pop_2030, yaounde, "Mfoundi 2030 (projection)")

## ------------------------------------------------------------------------
## POURQUOI REPROJETER LE POLYGONE ET NON LE RASTER
##
## st_transform(zone, crs(raster)) deplace le VECTEUR vers le CRS du raster.
## L'inverse -- project(raster, crs(zone)) -- est couteux et DESTRUCTEUR :
## reprojeter un raster impose de reechantillonner, donc de recalculer chaque
## valeur par interpolation. Sur une grille d'effectifs, cela MODIFIE LE TOTAL
## (le module 7 le fera, faute d'alternative, et en mesurera le prix).
##
## Regle : quand on peut choisir, on reprojette le vecteur, jamais le raster.
##
## Et si l'on oublie d'harmoniser les CRS ? crop() renvoie generalement
## "extents do not overlap". Mais dans le cas pernicieux ou les deux emprises
## se recouvrent par hasard, crop() reussit et renvoie un morceau de territoire
## qui n'a rien a voir. D'ou le cat() du nombre de cellules retenues.
## ------------------------------------------------------------------------


## --- 4.2 La trajectoire sur quinze ans --------------------------------------

evol_yaounde <- tibble(
  annee      = c(2015, 2025, 2030),
  population = c(round(yde_2015$total), round(yde_2025$total), round(yde_2030$total))
) |>
  mutate(
    croissance_vs_2015_pct = round(100 * (population - population[1]) / population[1], 1),
    croissance_annuelle_pct = round(
      100 * ((population / population[1])^(1 / pmax(annee - 2015, 1)) - 1), 2)
  )

print(evol_yaounde)

cat("\nCroissance 2015-2025 :",
    round(100 * (yde_2025$total - yde_2015$total) / yde_2015$total, 1), "%\n")
cat("Croissance 2025-2030 :",
    round(100 * (yde_2030$total - yde_2025$total) / yde_2025$total, 1), "%\n")

graphique_evolution <- ggplot(evol_yaounde, aes(x = annee, y = population)) +
  geom_line(colour = "#2C7FB8", linewidth = 1) +
  geom_point(colour = "#2C7FB8", size = 3) +
  geom_text(aes(label = label_comma(big.mark = " ")(population)),
            vjust = -1, size = 3.2) +
  scale_y_continuous(labels = label_comma(big.mark = " "),
                     expand = expansion(mult = c(0.05, 0.15))) +
  scale_x_continuous(breaks = c(2015, 2025, 2030)) +
  labs(
    title    = "Evolution de la population du Mfoundi (Yaounde)",
    subtitle = "WorldPop constrained 100 m - 2015 et 2025 observes, 2030 projete",
    x        = "Annee",
    y        = "Population estimee"
  ) +
  theme_minimal()

print(graphique_evolution)

ggsave("outputs/J08_evolution_population_yaounde_2015_2030.png",
       graphique_evolution, width = 7, height = 5, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- TRAJECTOIRE DU MFOUNDI
##
## CE QUE LA FIGURE CODE. Trois effectifs, sommes des cellules WorldPop
## tombant dans le polygone du DEPARTEMENT du Mfoundi. POPULATION RESIDENTE
## ESTIMEE DANS LES LIMITES ADMINISTRATIVES DU MFOUNDI, pas "population de
## Yaounde" -- l'agglomeration deborde largement du departement.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Les trois grilles appartiennent a la MEME
## VERSION DU MODELE (R2025A), condition pour que la difference soit
## interpretable. Comparer un WorldPop 2015 version 2020 a un WorldPop 2025
## version 2025 mesurerait un changement de METHODE, pas de POPULATION. L'axe
## des ordonnees ne commence pas a zero : acceptable pour lire une pente, mais
## cela AMPLIFIE VISUELLEMENT la croissance. Sur des barres, ce serait une
## faute.
##
## CE QUI SE LIT. L'ordre de grandeur de la croissance urbaine sur dix ans, et
## la comparaison entre croissance observee et croissance projetee ramenees au
## meme rythme annuel.
##
## CE QUI NE SE LIT PAS. Ce qui distingue les deux premiers points du
## troisieme. 2015 et 2025 sont des REDISTRIBUTIONS de totaux administratifs ;
## 2030 est une PROJECTION qui suppose (i) un total national projete juste,
## (ii) une repartition du bati conforme au modele, (iii) aucun choc. Un point
## de projection ressemble a un point d'observation : le sous-titre doit faire
## la difference, et un pointille serait encore mieux.
## ------------------------------------------------------------------------


## --- 4.3 La comparaison cartographique 2015 / 2025 / 2030 -------------------

pop_2015_cmr <- mask(crop(pop_2015, vect(st_transform(cmr0, crs(pop_2015)))),
                     vect(st_transform(cmr0, crs(pop_2015))))
pop_2030_cmr <- mask(crop(pop_2030, vect(st_transform(cmr0, crs(pop_2030)))),
                     vect(st_transform(cmr0, crs(pop_2030))))

cat("Totaux nationaux WorldPop\n")
cat("  2015 :", format(round(global(pop_2015_cmr, "sum", na.rm = TRUE)$sum),
                       big.mark = " "), "\n")
cat("  2025 :", format(round(global(pop_2025_cmr, "sum", na.rm = TRUE)$sum),
                       big.mark = " "), "\n")
cat("  2030 :", format(round(global(pop_2030_cmr, "sum", na.rm = TRUE)$sum),
                       big.mark = " "), "\n")

# --- Des BREAKS COMMUNS aux trois cartes ------------------------------------
# Sans cela, chaque carte est discretisee sur SA propre distribution : trois
# cartes qui se ressemblent alors que les valeurs different. C'est la faute la
# plus frequente des comparaisons temporelles cartographiques.
echantillon <- c(
  values(pop_2015_cmr), values(pop_2025_cmr), values(pop_2030_cmr)
)
breaks_3ans <- unique(quantile(echantillon, probs = seq(0, 1, length.out = 8),
                               na.rm = TRUE))
cat("Breaks communs :", paste(round(breaks_3ans, 3), collapse = " | "), "\n")

carte_millesime <- function(r, titre) {
  tm_shape(r) +
    tm_raster(
      col.scale  = tm_scale_intervals(breaks = breaks_3ans,
                                      values = "brewer.yl_or_rd"),
      col.legend = tm_legend(title = "hab/cellule")
    ) +
    tm_shape(cmr1) +
    tm_borders(col = "grey40", lwd = 0.3) +
    tm_title(titre)
}

carte_3ans <- tmap_arrange(
  carte_millesime(pop_2015_cmr, "2015"),
  carte_millesime(pop_2025_cmr, "2025"),
  carte_millesime(pop_2030_cmr, "2030 (projection)"),
  ncol = 3
)

print(carte_3ans)

tmap_save(carte_3ans, "outputs/J08_comparaison_pop_2015_2025_2030.png",
          width = 16, height = 5, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- TROIS MILLESIMES A ECHELLE COMMUNE
##
## CE QUE LA FIGURE CODE. Trois fois la meme grandeur, a trois dates, avec
## EXACTEMENT LES MEMES BORNES DE CLASSES.
##
## CE QUE LES CHOIX TECHNIQUES FONT. breaks_3ans est calcule sur la
## CONCATENATION des valeurs des trois rasters, puis impose aux trois cartes.
## Seule facon de rendre trois cartes comparables : si chaque panneau etait
## discretise sur sa propre distribution, les trois seraient quasi identiques
## -- chacune ayant un huitieme de ses cellules dans sa classe la plus foncee
## -- et la croissance disparaitrait. Le unique() protege contre des bornes
## dupliquees, qui feraient echouer tm_scale_intervals().
##
## CE QUI SE LIT. L'extension spatiale du bati peuple : les taches urbaines
## grossissent, les couronnes periurbaines s'allument. A echelle commune, le
## changement se lit en SURFACE COLOREE, pas en intensite.
##
## CE QUI NE SE LIT PAS. La croissance de la valeur d'une cellule deja peuplee
## est invisible : seule l'apparition de nouvelles cellules se voit. Un tableau
## regional (module 5) est indispensable : la carte montre OU, le tableau dit
## COMBIEN.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI : L'ECART ENTRE DEUX CARTES
##
## La difference entre la carte 2015 et la carte 2025 n'est pas seulement "plus
## de gens" : c'est une FORME. Une croissance qui epaissit les taches
## existantes (DENSIFICATION) et une croissance qui allume des cellules
## nouvelles en peripherie (ETALEMENT) donnent le meme chiffre regional et deux
## cartes completement differentes.
##
## Or ce sont deux problemes de politique publique opposes : la densification
## pose des questions d'assainissement et de transport ; l'etalement pose des
## questions de raccordement, de foncier et de cout unitaire des reseaux. Le
## tableau ne permet pas de choisir. La paire de cartes, oui.
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 5 -- AGREGER PAR REGION ET CONFRONTER AU CHIFFRE OFFICIEL
## ============================================================================

## --- 5.1 exact_extract() : la statistique zonale ponderee -------------------

# exact_extract() attend le vecteur DANS le CRS du raster.
cmr1_r <- st_transform(cmr1, crs(pop_2025))
cat("CRS harmonises pour l'extraction zonale :\n")
cat("  raster :", crs(pop_2025, describe = TRUE)$code, "\n")
cat("  vecteur:", st_crs(cmr1_r)$epsg, "\n")

pop_2025_par_region <- exact_extract(pop_2025, cmr1_r, "sum", progress = FALSE)
pop_2015_par_region <- exact_extract(pop_2015, st_transform(cmr1, crs(pop_2015)),
                                     "sum", progress = FALSE)

# INSTRUMENTATION OBLIGATOIRE apres extraction zonale.
cat("\nExtraction zonale par region\n")
cat("  polygones traites   :", length(pop_2025_par_region), "\n")
cat("  regions sans valeur :", sum(is.na(pop_2025_par_region)), "\n")
cat("  somme des zonales   :", format(round(sum(pop_2025_par_region, na.rm = TRUE)),
                                      big.mark = " "), "\n")
cat("  total national brut :", format(round(global(pop_2025_cmr, "sum", na.rm = TRUE)$sum),
                                      big.mark = " "), "\n")
cat("  ecart zonales - brut:",
    format(round(sum(pop_2025_par_region, na.rm = TRUE) -
                 global(pop_2025_cmr, "sum", na.rm = TRUE)$sum), big.mark = " "),
    "  (mesure la population hors polygones ADM1, arrondis compris)\n")

## ------------------------------------------------------------------------
## CE QUE "EXACT" VEUT DIRE DANS exact_extract
##
## Une cellule qui chevauche une frontiere appartient un peu a chaque region.
## Trois strategies :
##
## - PAR CENTROIDE (terra::extract() par defaut) : la cellule va entierement a
##   la region qui contient son centre. Simple, rapide, BIAISE : sur un
##   polygone etroit et allonge -- bande cotiere, vallee, emprise d'inondation
##   -- la majorite des cellules ont leur centre a l'exterieur et sont perdues ;
## - TOUT OU RIEN PAR INTERSECTION : double-compte ;
## - PONDERATION PAR FRACTION DE CELLULE (exact_extract) : la cellule est
##   attribuee AU PRORATA DE LA FRACTION DE SA SURFACE contenue dans le
##   polygone. Une cellule de 12 habitants coupee a 30 % / 70 % contribue pour
##   3,6 et 8,4.
##
## Sur des regions vastes et compactes, les trois methodes donnent presque le
## meme resultat. L'ecart devient decisif sur les PETITS POLYGONES et les
## FORMES ALLONGEES -- le cas d'usage du module 9 et de la journee J09.
##
## Le compteur "ecart zonales - brut" verifie que la somme des dix regions
## retombe sur le total national.
## ------------------------------------------------------------------------

regions_pop <- cmr1 |>
  st_drop_geometry() |>
  select(NAME_1) |>
  mutate(
    pop_worldpop_2015 = round(pop_2015_par_region),
    pop_worldpop_2025 = round(pop_2025_par_region),
    variation         = pop_worldpop_2025 - pop_worldpop_2015,
    croissance_pct    = round(100 * variation / pop_worldpop_2015, 1)
  ) |>
  arrange(desc(pop_worldpop_2025))

print(regions_pop)

graphique_croissance <- ggplot(
  regions_pop,
  aes(x = croissance_pct, y = reorder(NAME_1, croissance_pct))
) +
  geom_col(fill = "#2C7FB8") +
  geom_vline(xintercept = 0, colour = "grey40", linetype = 2) +
  geom_text(aes(label = paste0(croissance_pct, " %")), hjust = -0.15, size = 3) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.15))) +
  labs(
    title    = "Croissance de la population WorldPop par region, 2015-2025",
    subtitle = "Somme des cellules WorldPop constrained, ponderee par fraction de cellule",
    x        = "Croissance (%)",
    y        = NULL
  ) +
  theme_minimal()

print(graphique_croissance)

ggsave("outputs/J08_croissance_population_2015_2025.png", graphique_croissance,
       width = 8, height = 5, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- CROISSANCE REGIONALE 2015-2025
##
## CE QUE LA FIGURE CODE. La VARIATION RELATIVE de la population WorldPop :
## 100 x (pop2025 - pop2015) / pop2015. Pas un gain absolu : une petite region
## qui gagne 100 000 habitants peut afficher une barre plus longue qu'une
## grande qui en gagne 500 000.
##
## CE QUE LES CHOIX TECHNIQUES FONT. reorder() trie par la valeur representee.
## Les barres partent de zero et l'axe n'est pas tronque -- obligatoire pour
## des barres : la longueur EST la quantite. La ligne verticale a 0 rend
## lisible un eventuel recul.
##
## CE QUI SE LIT. Le classement des dynamiques regionales sur dix ans, tel que
## le modele WorldPop le restitue.
##
## CE QUI NE SE LIT PAS. Le gain en EFFECTIF (lire le tableau au-dessus). Ni la
## part de cette croissance qui vient d'une MEILLEURE DETECTION DU BATI :
## l'imagerie et les modeles de detection ont beaucoup progresse entre 2015 et
## 2025. Une partie de la "croissance" mesuree est un progres de la mesure.
## Enfin, une barre regionale ecrase l'opposition urbain/rural interne, qui est
## le vrai lieu de la croissance.
## ------------------------------------------------------------------------


## --- 5.2 Confronter au total officiel : l'ecart, ecrit et non masque --------

total_worldpop <- sum(regions_pop$pop_worldpop_2025, na.rm = TRUE)
total_officiel <- sum(pop_adm1$T_TL, na.rm = TRUE)
ecart_abs      <- total_worldpop - total_officiel
ecart_pct      <- 100 * ecart_abs / total_officiel

cat("=== CONFRONTATION A LA REFERENCE (regle 3.8) ===\n")
cat("Total WorldPop 2025 agrege  :", format(total_worldpop, big.mark = " "), "\n")
cat("Total officiel COD-PS 2025  :", format(total_officiel, big.mark = " "), "\n")
cat("Ecart absolu                :", format(ecart_abs, big.mark = " "), "habitants\n")
cat("Ecart relatif               :", round(ecart_pct, 2), "%\n")
cat("Sens de l'ecart             :",
    if (ecart_abs > 0) "WorldPop SURESTIME par rapport au COD-PS"
    else "WorldPop SOUS-ESTIME par rapport au COD-PS", "\n\n")

# Ecart region par region : c'est la que l'information est.
comparaison_officiel <- regions_pop |>
  left_join(
    pop_adm1 |> select(cle_region, T_TL) |> rename(NAME_1 = cle_region,
                                                   pop_officielle = T_TL),
    by = "NAME_1"
  ) |>
  mutate(
    ecart_abs = pop_worldpop_2025 - pop_officielle,
    ecart_pct = round(100 * ecart_abs / pop_officielle, 1)
  ) |>
  arrange(desc(abs(ecart_pct)))

print(comparaison_officiel)
cat("\nRegions sans chiffre officiel apparie :",
    sum(is.na(comparaison_officiel$pop_officielle)), "\n")
cat("Ecart regional median (%) :",
    round(median(comparaison_officiel$ecart_pct, na.rm = TRUE), 1), "\n")
cat("Amplitude des ecarts (%)  : de ",
    round(min(comparaison_officiel$ecart_pct, na.rm = TRUE), 1), " a ",
    round(max(comparaison_officiel$ecart_pct, na.rm = TRUE), 1), "\n", sep = "")

carte_ecart <- cmr1 |>
  left_join(comparaison_officiel |> select(NAME_1, ecart_pct), by = "NAME_1") |>
  ggplot() +
  geom_sf(aes(fill = ecart_pct), colour = "white", linewidth = 0.3) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0, na.value = "grey80") +
  labs(
    title    = "Ecart WorldPop 2025 - COD-PS 2025, par region",
    subtitle = "Rouge = WorldPop au-dessus du chiffre officiel ; bleu = en dessous",
    fill     = "Ecart (%)",
    caption  = "Gris = region sans chiffre officiel apparie"
  ) +
  theme_minimal()

print(carte_ecart)

ggsave("outputs/J08_ecart_worldpop_officiel_adm1.png", carte_ecart,
       width = 7, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- LA CARTE DES ECARTS
##
## CE QUE LA FIGURE CODE. 100 x (WorldPop - officiel) / officiel, region par
## region. Ce N'EST PAS une carte de population : c'est une carte de DESACCORD
## ENTRE DEUX SOURCES.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Palette DIVERGENTE centree sur zero,
## parce que la grandeur a un point neutre parfaitement defini : l'accord. Une
## palette sequentielle aurait range les regions du plus petit au plus grand
## ecart sans distinguer les excedents des deficits, ce qui detruirait toute
## l'information. Le tri du tableau se fait sur la VALEUR ABSOLUE de l'ecart.
##
## CE QUI SE LIT. Ou les deux sources divergent, et dans quel sens. Un ecart
## positif concentre sur les regions urbaines suggere une sur-attribution au
## bati dense ; un ecart negatif sur les regions rurales suggere du bati non
## detecte. Un ecart CONTIGU n'est pas du bruit : il signale une cause commune.
##
## CE QUI NE SE LIT PAS. LAQUELLE DES DEUX SOURCES A RAISON. La carte mesure un
## desaccord, pas une erreur. Le COD-PS est lui-meme une projection a partir
## d'un recensement ancien, et cette anciennete domine tous les autres
## facteurs. Si les totaux nationaux collent presque mais que les regions
## divergent, c'est le signe d'un CALIBRAGE NATIONAL avec une REDISTRIBUTION
## INTERNE differente.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## CE QU'IL FAUT FAIRE DE CET ECART
##
## Ne pas le masquer. Trois conduites, dans cet ordre :
##
## 1. LE PUBLIER A COTE DU CHIFFRE. "3,1 millions d'habitants (WorldPop 2025 ;
##    +4 % par rapport au COD-PS)" est une phrase honnete ; "3,1 millions
##    d'habitants" ne l'est pas.
## 2. CHERCHER LA STRUCTURE DE L'ECART. Un ecart homogene est un probleme de
##    calibrage global, corrigeable par un facteur. Un ecart heterogene est un
##    probleme de REPARTITION, non corrigeable -- et il interdit d'utiliser la
##    grille pour comparer des regions entre elles.
## 3. EN FAIRE UN EXERCICE (exercice 3).
##
## Si l'ecart depasse 10-15 % sur certaines regions, INTERDIRE EXPLICITEMENT DE
## CITER CES CHIFFRES REGIONAUX dans un document officiel. Une carte donne a un
## chiffre faux exactement la meme autorite visuelle qu'a un chiffre juste.
## ------------------------------------------------------------------------


## --- 5.3 Cinq villes comparees ----------------------------------------------

villes_dept <- c(
  "Douala (Wouri)"    = "Wouri",
  "Yaounde (Mfoundi)" = "Mfoundi",
  "Bafoussam (Mifi)"  = "Mifi",
  "Bamenda (Mezam)"   = "Mezam",
  "Garoua (Benoue)"   = "Benoue"
)

pop_villes <- lapply(names(villes_dept), function(nom) {
  dept <- cmr2 |> filter(NAME_2 == villes_dept[[nom]])
  if (nrow(dept) == 0) {
    cat("ATTENTION : departement introuvable dans NAME_2 ->", villes_dept[[nom]], "\n")
    return(tibble(ville = nom, pop_2015 = NA_real_, pop_2025 = NA_real_))
  }
  dept_v <- vect(st_transform(dept, crs(pop_2025)))
  tibble(
    ville    = nom,
    pop_2015 = round(global(mask(crop(pop_2015, dept_v), dept_v), "sum",
                            na.rm = TRUE)$sum),
    pop_2025 = round(global(mask(crop(pop_2025, dept_v), dept_v), "sum",
                            na.rm = TRUE)$sum)
  )
}) |>
  bind_rows() |>
  mutate(
    croissance_pct = round(100 * (pop_2025 - pop_2015) / pop_2015, 1),
    gain_absolu    = pop_2025 - pop_2015
  ) |>
  arrange(desc(pop_2025))

print(pop_villes)
cat("\nVilles sans effectif :", sum(is.na(pop_villes$pop_2025)), "/",
    nrow(pop_villes), "\n")
cat("Part des 5 departements dans la population nationale WorldPop 2025 :",
    round(100 * sum(pop_villes$pop_2025, na.rm = TRUE) / total_worldpop, 1), "%\n")

## ------------------------------------------------------------------------
## INTERPRETATION -- LES CINQ DEPARTEMENTS URBAINS
##
## CE QUE LE TABLEAU CODE. Effectif WorldPop 2015 et 2025, gain absolu et
## croissance relative. Ce sont des DEPARTEMENTS, pas des villes. Le Wouri
## correspond assez bien a Douala ; le Mfoundi est PLUS PETIT que
## l'agglomeration de Yaounde ; la Benoue est BEAUCOUP PLUS GRANDE que Garoua.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Le decoupage administratif est la MAILLE
## IMPOSEE -- deja le probleme du module 6. Croissance relative et gain absolu
## classent differemment : le premier favorise les petites unites, le second
## les grandes. Publier les deux est la seule facon honnete.
##
## CE QUI SE LIT. La hierarchie urbaine et son evolution.
##
## CE QUI NE SE LIT PAS. La VILLE au sens morphologique. C'est un BIAIS DE
## TAILLE DE L'UNITE : la Benoue, plus etendue, capte plus de population
## rurale, donc dilue sa croissance urbaine. La solution rigoureuse serait de
## definir les villes par un seuil de densite sur la grille elle-meme -- c'est
## ce que fait GHS-SMOD (degre d'urbanisation), aborde au J09.
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 6 -- DENSITE, ECHELLE LOGARITHMIQUE ET MAUP
## ============================================================================

## --- 6.1 Mesurer une surface : reprojeter d'abord ---------------------------

# EPSG:4326 est en DEGRES. st_area() y renverrait des degres carres, une
# grandeur sans signification physique et qui varie avec la latitude.
# On reprojette en UTM 33N (EPSG:32633), metrique, adapte au Cameroun.
cmr1_utm <- st_transform(cmr1_pop, 32633)

cmr1_densite <- cmr1_utm |>
  mutate(
    surface_km2     = as.numeric(st_area(cmr1_utm)) / 1e6,
    densite_hab_km2 = T_TL / surface_km2
  )

# INSTRUMENTATION : controler la surface totale contre le chiffre officiel.
surface_totale <- sum(cmr1_densite$surface_km2, na.rm = TRUE)
cat("Surface totale calculee :", format(round(surface_totale), big.mark = " "), "km2\n")
cat("Surface officielle      : 475 442 km2\n")
cat("Ecart                   :", round(100 * (surface_totale - 475442) / 475442, 2), "%\n\n")

cat("Densite regionale (hab/km2)\n")
print(cmr1_densite |> st_drop_geometry() |>
        select(NAME_1, T_TL, surface_km2, densite_hab_km2) |>
        mutate(surface_km2 = round(surface_km2),
               densite_hab_km2 = round(densite_hab_km2, 1)) |>
        arrange(desc(densite_hab_km2)))

cat("\nRapport max/min des densites :",
    round(max(cmr1_densite$densite_hab_km2, na.rm = TRUE) /
          min(cmr1_densite$densite_hab_km2, na.rm = TRUE), 1), "\n")
cat("Densite nationale (total / surface totale) :",
    round(sum(cmr1_densite$T_TL, na.rm = TRUE) / surface_totale, 1), "hab/km2\n")
cat("Moyenne NON PONDEREE des densites regionales :",
    round(mean(cmr1_densite$densite_hab_km2, na.rm = TRUE), 1), "hab/km2\n")

## ------------------------------------------------------------------------
## LA MOYENNE DES DENSITES N'EST PAS LA DENSITE
##
## Les deux dernieres lignes imprimees sont differentes, et il faut savoir
## laquelle citer.
##
## - DENSITE NATIONALE = population totale / surface totale. C'est la densite
##   du pays. Elle pondere implicitement chaque region par sa SURFACE.
## - MOYENNE DES DENSITES REGIONALES = moyenne arithmetique des dix densites.
##   Elle donne le meme poids a une region de 10 000 km2 et a une region de
##   110 000 km2. Elle decrit "la densite de la region moyenne", question que
##   personne ne se pose.
##
## Meme mecanisme que le BIAIS DE TAILLE du J05 : parcourir des lignes
## d'individus surrepresente les grands menages ; moyenner des densites
## regionales surrepresente les petites regions. La question a se poser avant
## de calculer : DE QUOI PREND-ON LA MOYENNE ?
##
## Et une MOYENNE DE MOYENNES N'EST JAMAIS LA MOYENNE, sauf si tous les
## denominateurs sont egaux.
## ------------------------------------------------------------------------


## --- 6.2 La carte de densite et l'echelle logarithmique ---------------------

# Note : trans = "log10" est deprecie au profit de transform = "log10" dans les
# versions recentes de ggplot2 ; il reste fonctionnel et emet un avertissement.
carte_densite <- ggplot(cmr1_densite) +
  geom_sf(aes(fill = densite_hab_km2), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(
    option   = "inferno",
    trans    = "log10",
    labels   = label_comma(big.mark = " "),
    na.value = "grey80",
    name     = "hab/km2\n(echelle log10)"
  ) +
  labs(
    title    = "Densite de population par region, Cameroun 2025",
    subtitle = "Effectif COD-PS rapporte a la surface calculee en UTM 33N",
    caption  = "Gris = region sans effectif apparie"
  ) +
  theme_minimal()

print(carte_densite)

ggsave("outputs/J08_densite_population_adm1.png", carte_densite,
       width = 7, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- DENSITE REGIONALE EN ECHELLE LOGARITHMIQUE
##
## CE QUE LA FIGURE CODE. T_TL / surface_km2 : le NOMBRE MOYEN D'HABITANTS PAR
## KILOMETRE CARRE. Densite BRUTE (arithmetique), rapportee a la surface TOTALE
## de la region, y compris forets, lacs et zones inhabitables. Ce n'est pas la
## densite PHYSIOLOGIQUE (rapportee a la surface habitable), qui serait bien
## plus elevee dans les regions a fort relief ou fortement forestieres.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Deux choix majeurs.
##
## PREMIER CHOIX : LA NORMALISATION PAR LA SURFACE. Elle transforme un volume
## en intensite et neutralise l'effet de taille du polygone. Le prix : une
## region tres peuplee mais tres etendue perd son poids demographique. Densite
## et volume repondent a deux questions differentes ; les deux cartes doivent
## etre lues ensemble.
##
## DEUXIEME CHOIX : L'ECHELLE LOGARITHMIQUE. La densite est fortement
## ASYMETRIQUE A DROITE. Sur une echelle LINEAIRE, la seule region tres dense
## occuperait l'essentiel de l'amplitude de la palette et les neuf autres
## seraient dans la meme nuance : la carte ne montrerait plus qu'un point.
## L'echelle LOG10 represente les RAPPORTS et non les differences : un meme
## ecart de couleur correspond partout a un meme FACTEUR MULTIPLICATIF.
##
## Le prix est reel : elle ECRASE VISUELLEMENT les ecarts absolus, et elle est
## indefinie en zero ou en negatif.
##
## CE QUI SE LIT. L'opposition structurelle entre espaces densement occupes et
## espaces de faible occupation, et le fait que ces espaces forment des blocs.
##
## CE QUI NE SE LIT PAS. L'heterogeneite interne, massivement. La densite d'une
## region est une moyenne sur un territoire ou l'ecart entre le centre-ville et
## la brousse atteint un facteur mille. C'est le sujet de la section suivante.
## ------------------------------------------------------------------------


## --- 6.3 Le MAUP : la meme population, deux mailles, deux cartes ------------

cmr2_utm <- st_transform(cmr2, 32633)
pop_adm2 <- exact_extract(pop_2025, st_transform(cmr2, crs(pop_2025)),
                          "sum", progress = FALSE)

cat("Extraction zonale ADM2\n")
cat("  polygones          :", length(pop_adm2), "\n")
cat("  sans valeur        :", sum(is.na(pop_adm2)), "\n")
cat("  somme ADM2         :", format(round(sum(pop_adm2, na.rm = TRUE)), big.mark = " "), "\n")
cat("  somme ADM1         :", format(round(sum(pop_2025_par_region, na.rm = TRUE)),
                                     big.mark = " "), "\n")

dens_adm2 <- cmr2_utm |>
  mutate(
    pop_wp          = pop_adm2,
    surface_km2     = as.numeric(st_area(cmr2_utm)) / 1e6,
    densite_hab_km2 = pop_wp / surface_km2
  )

dens_adm1 <- cmr1 |>
  st_transform(32633) |>
  mutate(
    pop_wp          = pop_2025_par_region,
    surface_km2     = as.numeric(st_area(st_transform(cmr1, 32633))) / 1e6,
    densite_hab_km2 = pop_wp / surface_km2
  )

cat("\nStatistiques de densite selon la maille (hab/km2)\n")
cat("  ADM1 (10 unites)  : min =", round(min(dens_adm1$densite_hab_km2, na.rm = TRUE), 1),
    "| median =", round(median(dens_adm1$densite_hab_km2, na.rm = TRUE), 1),
    "| max =", round(max(dens_adm1$densite_hab_km2, na.rm = TRUE), 1),
    "| rapport max/min =", round(max(dens_adm1$densite_hab_km2, na.rm = TRUE) /
                                 min(dens_adm1$densite_hab_km2, na.rm = TRUE), 1), "\n")
cat("  ADM2 (", nrow(dens_adm2), " unites) : min =",
    round(min(dens_adm2$densite_hab_km2, na.rm = TRUE), 1),
    "| median =", round(median(dens_adm2$densite_hab_km2, na.rm = TRUE), 1),
    "| max =", round(max(dens_adm2$densite_hab_km2, na.rm = TRUE), 1),
    "| rapport max/min =", round(max(dens_adm2$densite_hab_km2, na.rm = TRUE) /
                                 min(dens_adm2$densite_hab_km2, na.rm = TRUE), 1), "\n")

breaks_dens <- c(0, 10, 25, 50, 100, 250, 1000, 1e6)

carte_maup <- tmap_arrange(
  tm_shape(dens_adm1) +
    tm_polygons(fill = "densite_hab_km2",
                fill.scale = tm_scale_intervals(breaks = breaks_dens,
                                                values = "brewer.yl_or_rd"),
                fill.legend = tm_legend(title = "hab/km2"),
                col = "white", lwd = 0.4) +
    tm_title("Maille ADM1 - 10 regions"),
  tm_shape(dens_adm2) +
    tm_polygons(fill = "densite_hab_km2",
                fill.scale = tm_scale_intervals(breaks = breaks_dens,
                                                values = "brewer.yl_or_rd"),
                fill.legend = tm_legend(title = "hab/km2"),
                col = "white", lwd = 0.2) +
    tm_title(paste0("Maille ADM2 - ", nrow(dens_adm2), " departements")),
  ncol = 2
)

print(carte_maup)

tmap_save(carte_maup, "outputs/J08_densite_maup_adm1_adm2.png",
          width = 12, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## LE MAUP -- MODIFIABLE AREAL UNIT PROBLEM
##
## Les deux cartes reposent sur EXACTEMENT LA MEME DONNEE : la grille WorldPop
## 2025. Aucune information n'a ete ajoutee ni retiree. Seule la MAILLE
## D'AGREGATION change. Les bornes de classes et la palette sont identiques.
##
## Et pourtant les deux cartes ne racontent pas la meme histoire. La carte ADM2
## fait apparaitre des poches de tres forte densite que la carte ADM1 avait
## fondues dans la moyenne, et des espaces de tres faible densite que la meme
## moyenne avait remontes. Les statistiques imprimees le chiffrent : le rapport
## max/min explose en passant a la maille fine.
##
## Deux effets distincts :
##
## L'EFFET D'ECHELLE. Plus la maille est grossiere, plus la moyenne lisse : la
## variance baisse, les extremes s'attenuent, et -- consequence moins connue --
## LES CORRELATIONS SONT ARTIFICIELLEMENT RENFORCEES. Une correlation entre
## densite et pauvrete sur 10 regions sera presque toujours plus forte que sur
## 58 departements. Le coefficient mesure n'est pas une propriete du
## phenomene : c'est une propriete conjointe du phenomene ET de la maille.
##
## L'EFFET DE ZONAGE. A nombre d'unites constant, LE TRACE des limites change
## le resultat. Deux decoupages en 58 unites donnent deux cartes, deux
## correlations et deux classements differents. C'est le mecanisme du
## gerrymandering, et il opere aussi dans les decoupages sanitaires, scolaires
## ou statistiques, sans intention.
##
## LA REGLE OPERATOIRE. Il n'existe pas de maille neutre, donc pas de "bonne"
## maille dans l'absolu. Il existe une maille PERTINENTE POUR LA DECISION
## QU'ON ECLAIRE :
##   - allouer un budget regional -> la maille de l'allocation, ADM1 ;
##   - implanter un centre de sante -> la maille de l'aire de recrutement, soit
##     un rayon de marche, pas un polygone administratif ;
##   - dimensionner une campagne vaccinale -> la maille de l'equipe mobile.
##
## Reflexe minimal quand on ne peut pas choisir : REFAIRE L'ANALYSE A UNE
## SECONDE MAILLE et verifier que la conclusion tient. Si elle ne tient pas,
## c'est la conclusion qu'il faut changer, pas la maille.
##
## C'est aussi le meilleur argument en faveur de la grille : elle n'elimine pas
## le MAUP -- la cellule de 100 m est une maille -- mais elle REPOUSSE LA
## DECISION D'AGREGATION A LA FIN DE LA CHAINE.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## L'ERREUR ECOLOGIQUE
##
## Corollaire direct du MAUP, risque permanent de toute choroplethe.
##
## L'ERREUR ECOLOGIQUE CONSISTE A ATTRIBUER A UN INDIVIDU CE QUI N'EST VRAI QUE
## DE L'AGREGAT AUQUEL IL APPARTIENT.
##
## Une region affiche 60 hab/km2. L'enonce "les habitants de cette region
## vivent a 60 hab/km2" est FAUX pour la quasi-totalite d'entre eux : la
## plupart vivent soit dans une agglomeration a plusieurs milliers d'habitants
## au km2, soit dans un espace rural a moins de 10. Presque personne ne vit a
## la densite moyenne. La moyenne decrit le polygone, pas ses habitants.
##
## Trois formes courantes :
## - DE L'AGREGAT A L'INDIVIDU. "Cette region est pauvre, donc cette personne
##   est pauvre." Faux.
## - DE L'AGREGAT A L'AGREGAT PLUS FIN. "La region a 42 % de moins de 15 ans,
##   donc ce quartier aussi." C'est l'hypothese du module 2 -- necessaire faute
##   de mieux, et a ECRIRE A COTE DU CHIFFRE.
## - LA CORRELATION ECOLOGIQUE. Une correlation entre variables agregees peut
##   etre de SIGNE OPPOSE a la correlation individuelle : paradoxe de Simpson.
##
## CE QUI PROTEGE. Superposer les echelles : un fond agrege PLUS les points ou
## la grille sous-jacente. C'est ce que fait le module 3 par rapport au
## module 1.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## INTERPRETATION -- LES DEUX CARTES DE DENSITE
##
## CE QUE LES FIGURES CODENT. La meme grandeur : population WorldPop 2025
## divisee par la surface du polygone. A gauche une region, a droite un
## departement.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Les bornes sont FIXEES A LA MAIN
## (breaks_dens) et identiques sur les deux panneaux. Indispensable : une
## discretisation en quantiles calculee separement produirait deux cartes
## visuellement semblables et le MAUP deviendrait invisible. Les bornes
## progressent de facon quasi geometrique (10, 25, 50, 100, 250, 1000),
## equivalent discret de l'echelle logarithmique.
##
## CE QUI SE LIT. L'effet de la maille, et lui seul. Toute difference entre les
## deux cartes est un artefact d'agregation, pas un fait demographique.
##
## CE QUI NE SE LIT PAS. Laquelle est "la bonne carte". Aucune : les deux sont
## exactes et repondent a deux questions differentes.
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 7 -- DEUX GRILLES NE DISENT PAS LA MEME CHOSE : GHS-POP
## ============================================================================

## 7.1 Ce qu'est GHS-POP et en quoi il differe de WorldPop
##
## |                     | WorldPop constrained        | GHS-POP R2023A          |
## | Producteur          | University of Southampton   | Commission europeenne, JRC |
## | Resolution native   | 3 secondes d'arc (~100 m)   | 100 m METRIQUES         |
## | Projection native   | EPSG:4326 (degres)          | ESRI:54009 (Mollweide)  |
## | Decoupage livraison | un fichier PAR PAYS         | TUILES mondiales (RxC)  |
## | Covariable dominante| bati detecte + covariables  | GHS-BUILT               |
## | Calibrage           | totaux administratifs nationaux | totaux ONU/recensements |
##
## Deux consequences pratiques :
##   1. GHS-POP arrive en TUILES, a decompresser puis ASSEMBLER. Le Cameroun
##      est couvert par sept tuiles.
##   2. GHS-POP est en MOLLWEIDE, projection EQUIVALENTE mais peu commode pour
##      croiser avec WorldPop en degres. Il faut REPROJETER, et cette
##      reprojection a un cout mesurable sur les totaux.

## --- 7.2 Decompresser et inventorier les tuiles -----------------------------

# Les 7 tuiles sont livrees A PLAT dans datasets/, en .zip. On les retrouve par
# motif, et non par sept chemins ecrits en dur.
#
# Les sept noms attendus, ecrits ici pour l'inventaire et pour le script de
# distribution des donnees (qui detecte les litteraux "datasets/...") :
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
if (length(zips) == 0)
  cat("  ATTENTION : aucune tuile. Verifier datasets/ et LISEZMOI.md.\n")

# Decompression dans outputs/ghsl_tuiles/ : une sortie n'ecrit JAMAIS dans
# datasets/, qui doit rester le reflet exact de ce que distribue le magasin.
dir.create("outputs/ghsl_tuiles", recursive = TRUE, showWarnings = FALSE)
for (z in zips) unzip(z, exdir = "outputs/ghsl_tuiles")

tifs <- list.files("outputs/ghsl_tuiles", pattern = "\\.tif$", full.names = TRUE)
cat("\nFichiers TIF disponibles apres decompression :", length(tifs), "\n")
if (length(tifs) > 0) cat(paste("  ", basename(tifs)), sep = "\n")

if (length(tifs) > 0) {
  tuile_exemple <- rast(tifs[1])
  cat("Tuile temoin :", basename(tifs[1]), "\n")
  cat("  dimensions  :", paste(dim(tuile_exemple), collapse = " x "), "\n")
  cat("  cellules    :", format(ncell(tuile_exemple), big.mark = " "), "\n")
  cat("  CRS         :", crs(tuile_exemple, describe = TRUE)$name, "\n")
  cat("  resolution  :", paste(res(tuile_exemple), collapse = " x "),
      "(unites du CRS)\n")
  cat("  emprise x   :", xmin(tuile_exemple), "/", xmax(tuile_exemple), "\n")
  cat("  emprise y   :", ymin(tuile_exemple), "/", ymax(tuile_exemple), "\n")
  cat("  min / max   :", paste(round(minmax(tuile_exemple), 3), collapse = " / "), "\n")
} else {
  cat("Pas de tuile a inspecter.\n")
}


## --- 7.3 Mosaiquer, reprojeter, decouper ------------------------------------

if (length(tifs) > 0) {

  # sprc() : SpatRasterCollection, une liste de rasters d'emprises differentes.
  tuiles      <- sprc(lapply(tifs, rast))
  # mosaic() : les assemble. fun = "mean" traite les recouvrements de bord.
  ghsl_mosaic <- mosaic(tuiles, fun = "mean")

  cat("Mosaique GHS-POP\n")
  cat("  tuiles assemblees :", length(tifs), "\n")
  cat("  dimensions        :", paste(dim(ghsl_mosaic), collapse = " x "), "\n")
  cat("  CRS               :", crs(ghsl_mosaic, describe = TRUE)$name, "\n")
  cat("  resolution        :", paste(res(ghsl_mosaic), collapse = " x "), "\n")
  cat("  emprise           :", as.character(ext(ghsl_mosaic)), "\n")
  cat("  total avant decoupe:",
      format(round(global(ghsl_mosaic, "sum", na.rm = TRUE)$sum), big.mark = " "),
      "(couvre plus que le Cameroun)\n")

  # Reprojection en WGS84 pour comparer avec WorldPop.
  # method = "bilinear" : interpolation adaptee a une variable continue.
  ghsl_wgs84 <- project(ghsl_mosaic, "EPSG:4326", method = "bilinear")

  cat("\nApres reprojection en EPSG:4326\n")
  cat("  CRS                :", crs(ghsl_wgs84, describe = TRUE)$name, "\n")
  cat("  resolution (degres):", paste(round(res(ghsl_wgs84), 8), collapse = " x "), "\n")
  cat("  total apres reproj :",
      format(round(global(ghsl_wgs84, "sum", na.rm = TRUE)$sum), big.mark = " "), "\n")

  # Decoupe nationale + nettoyage des valeurs sentinelles negatives.
  cmr0_v_ghsl <- vect(st_transform(cmr0, crs(ghsl_wgs84)))
  ghsl_cmr    <- mask(crop(ghsl_wgs84, cmr0_v_ghsl), cmr0_v_ghsl)

  n_neg <- as.integer(global(ghsl_cmr < 0, "sum", na.rm = TRUE)[[1]])
  cat("\nCellules a valeur negative (sentinelle nodata) :",
      format(n_neg, big.mark = " "), "-> recodees en NA\n")
  ghsl_cmr[ghsl_cmr < 0] <- NA

  cat("Total GHS-POP sur le Cameroun :",
      format(round(global(ghsl_cmr, "sum", na.rm = TRUE)$sum), big.mark = " "), "\n")

  # SORTIE : dans outputs/, jamais dans datasets/.
  writeRaster(ghsl_cmr, "outputs/J08_ghsl_pop_2025_cmr_100m.tif",
              overwrite = TRUE, datatype = "FLT4S")
  cat("Ecrit : outputs/J08_ghsl_pop_2025_cmr_100m.tif\n")

} else {
  cat("Tuiles absentes : module 7 non executable.\n")
  ghsl_cmr <- NULL
}

## ------------------------------------------------------------------------
## LE COUT DE LA REPROJECTION, MESURE
##
## Les deux totaux imprimes -- avant et apres project() -- ne sont PAS
## identiques. C'est normal.
##
## Reprojeter un raster construit une NOUVELLE GRILLE dans le CRS cible, puis
## calcule la valeur de chaque nouvelle cellule par interpolation. Avec
## method = "bilinear", chaque nouvelle cellule recoit une moyenne ponderee de
## ses quatre voisines. Deux consequences :
##   - la somme n'est PAS CONSERVEE (Mollweide est equivalente, EPSG:4326 ne
##     l'est pas : les cellules source et cible n'ont pas la meme surface) ;
##   - les valeurs sont LISSEES : les maxima locaux s'abaissent, les zeros
##     bordant une zone peuplee remontent.
##
## L'alternative method = "near" preserve les valeurs exactes mais cree des
## artefacts en damier et ne conserve pas mieux la somme.
##
## La methode rigoureuse pour un raster d'effectifs serait de reprojeter LA
## ZONE D'INTERET (comme au module 4). Impossible ici, puisqu'on veut COMPARER
## DEUX RASTERS entre eux. Le prix est donc assume, et il est MESURE -- c'est
## tout ce qu'on demande. L'ordre de grandeur de l'ecart borne la precision de
## toute comparaison qui suit.
## ------------------------------------------------------------------------


## --- 7.4 Comparer les deux grilles, region par region -----------------------

if (!is.null(ghsl_cmr)) {

  pop_ghsl_par_region <- exact_extract(ghsl_cmr, st_transform(cmr1, crs(ghsl_cmr)),
                                       "sum", progress = FALSE)

  cat("Extraction zonale GHS-POP par region\n")
  cat("  polygones     :", length(pop_ghsl_par_region), "\n")
  cat("  sans valeur   :", sum(is.na(pop_ghsl_par_region)), "\n")

  total_ghsl <- round(sum(pop_ghsl_par_region, na.rm = TRUE))

  cat("\n=== TROIS SOURCES, TROIS TOTAUX NATIONAUX 2025 ===\n")
  cat("  WorldPop constrained :", format(total_worldpop, big.mark = " "), "\n")
  cat("  GHS-POP R2023A       :", format(total_ghsl,     big.mark = " "), "\n")
  cat("  COD-PS (officiel)    :", format(total_officiel, big.mark = " "), "\n")
  cat("  Ecart GHSL / WorldPop:",
      round(100 * (total_ghsl - total_worldpop) / total_worldpop, 1), "%\n")
  cat("  Ecart GHSL / officiel:",
      round(100 * (total_ghsl - total_officiel) / total_officiel, 1), "%\n")
  cat("  Ecart WP   / officiel:", round(ecart_pct, 1), "%\n")

  regions_comparaison <- cmr1 |>
    st_drop_geometry() |>
    select(NAME_1) |>
    mutate(
      pop_worldpop_2025 = round(pop_2025_par_region),
      pop_ghsl_2025     = round(pop_ghsl_par_region)
    ) |>
    left_join(
      pop_adm1 |> select(cle_region, T_TL) |>
        rename(NAME_1 = cle_region, pop_officielle = T_TL),
      by = "NAME_1"
    ) |>
    mutate(
      ecart_ghsl_wp_pct  = round(100 * (pop_ghsl_2025 - pop_worldpop_2025) /
                                   pop_worldpop_2025, 1),
      ecart_ghsl_off_pct = round(100 * (pop_ghsl_2025 - pop_officielle) /
                                   pop_officielle, 1),
      ecart_wp_off_pct   = round(100 * (pop_worldpop_2025 - pop_officielle) /
                                   pop_officielle, 1)
    ) |>
    arrange(desc(abs(ecart_ghsl_wp_pct)))

  print(regions_comparaison)

  cat("\nSens de l'ecart GHSL - WorldPop :\n")
  cat("  regions ou GHSL > WorldPop :",
      sum(regions_comparaison$ecart_ghsl_wp_pct > 0, na.rm = TRUE), "\n")
  cat("  regions ou GHSL < WorldPop :",
      sum(regions_comparaison$ecart_ghsl_wp_pct < 0, na.rm = TRUE), "\n")
  cat("  ecart median (%)           :",
      round(median(regions_comparaison$ecart_ghsl_wp_pct, na.rm = TRUE), 1), "\n")

  write_csv(regions_comparaison,
            "outputs/J08_comparaison_worldpop_ghsl_officiel.csv")

} else {
  regions_comparaison <- NULL
  cat("Comparaison impossible : GHS-POP indisponible.\n")
}

if (!is.null(regions_comparaison)) {
  comp_long <- regions_comparaison |>
    select(NAME_1, pop_worldpop_2025, pop_ghsl_2025, pop_officielle) |>
    pivot_longer(-NAME_1, names_to = "source", values_to = "population") |>
    mutate(source = recode(source,
      pop_worldpop_2025 = "WorldPop constrained",
      pop_ghsl_2025     = "GHS-POP R2023A",
      pop_officielle    = "COD-PS officiel"))

  graphique_comparaison <- ggplot(
    comp_long,
    aes(x = population, y = reorder(NAME_1, population), fill = source)
  ) +
    geom_col(position = "dodge") +
    scale_x_continuous(labels = label_comma(big.mark = " ")) +
    scale_fill_brewer(palette = "Dark2", na.value = "grey80") +
    labs(
      title    = "Trois estimations de la population regionale, Cameroun 2025",
      subtitle = "Deux grilles modelisees et un chiffre administratif projete",
      x        = "Population estimee",
      y        = NULL,
      fill     = "Source"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")

  print(graphique_comparaison)

  ggsave("outputs/J08_comparaison_worldpop_ghsl_adm1.png", graphique_comparaison,
         width = 9, height = 6, dpi = 180)
}

## ------------------------------------------------------------------------
## INTERPRETATION -- TROIS SOURCES COTE A COTE
##
## CE QUE LA FIGURE CODE. Pour chaque region, trois barres : somme WorldPop,
## somme GHS-POP, effectif COD-PS. Les deux premieres sont des AGREGATIONS DE
## MODELES DE REDISTRIBUTION calibres sur des totaux nationaux ; la troisieme
## est une PROJECTION DEMOGRAPHIQUE ventilee administrativement. Aucune n'est
## un denombrement de 2025.
##
## CE QUE LES CHOIX TECHNIQUES FONT. Barres JUXTAPOSEES (dodge) : empiler
## additionnerait trois estimations de la meme quantite, ce qui n'aurait aucun
## sens. Palette QUALITATIVE (Dark2). Tri par population. L'axe des abscisses
## part de zero, obligatoire pour des barres.
##
## CE QUI SE LIT. Ou les trois sources s'accordent et ou elles divergent, et si
## les divergences sont systematiques ou erratiques. Un desaccord systematique
## est un probleme de NIVEAU, corrigeable ; un desaccord erratique est un
## probleme de REPARTITION, qui interdit d'utiliser les grilles pour comparer
## les regions.
##
## CE QUI NE SE LIT PAS. L'INCERTITUDE de chaque estimation, qu'aucun des trois
## producteurs ne livre sous forme cartographiable. Trois barres de hauteurs
## differentes ressemblent a trois mesures precises en desaccord ; ce sont
## trois estimations dont les intervalles de confiance -- non publies -- se
## recouvrent peut-etre largement. Ni la part de l'ecart imputable a la
## reprojection de la section 7.3.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## LAQUELLE CHOISIR ? UNE REGLE DE DECISION
##
## - EFFECTIF A PUBLIER AU NIVEAU ADMINISTRATIF : le chiffre officiel. Une
##   grille ne remplace jamais une source administrative la ou elle existe.
## - EFFECTIF DANS UNE ZONE NON ADMINISTRATIVE : la grille, avec son ecart
##   regional publie a cote.
## - WORLDPOP PLUTOT QUE GHS-POP quand on veut coller aux totaux nationaux,
##   quand on a besoin de plusieurs millesimes coherents, ou quand la zone
##   d'etude est un pays precis.
## - GHS-POP PLUTOT QUE WORLDPOP quand on travaille sur plusieurs pays et qu'on
##   a besoin d'une METHODE STRICTEMENT IDENTIQUE de part et d'autre d'une
##   frontiere, ou quand on veut une projection equivalente pour des calculs de
##   surface.
## - JAMAIS L'UNE SANS L'AUTRE pour un chiffre qui engage : l'ecart entre les
##   deux est la seule estimation d'incertitude disponible gratuitement.
## ------------------------------------------------------------------------


## ============================================================================
## MODULE 8 -- COMMENT UNE GRILLE EST FABRIQUEE : BOTTOM-UP ET TOP-DOWN
## ============================================================================

## ------------------------------------------------------------------------
## CE MODULE EST UN EXPOSE, PAS UN ATELIER
##
## Les modules 1 a 7 ont UTILISE des grilles. Celui-ci explique COMMENT ON LES
## FABRIQUE. Coeur conceptuel de la journee : sans lui, on repart en croyant
## que WorldPop est une observation.
##
## Le code de ce module est livre en BLOCS DE REFERENCE NON EXECUTES. Raison
## technique : la chaine de desagregation demande des COVARIABLES SPATIALES
## CONTINUES (surface batie, occupation du sol, distance aux routes, lumieres
## nocturnes) et des DONNEES D'ENTRAINEMENT GEOLOCALISEES. Ni les unes ni les
## autres ne sont dans le datasets/ de cette journee : les covariables relevent
## du J09 (GHS-BUILT) et du J10 (covariables GEE), les grappes geolocalisees du
## J05 (EDS). Les livrer ici violerait la regle "une journee ne garde que ce
## qu'elle lit", et alourdirait le dossier de centaines de Mo pour un expose.
## ------------------------------------------------------------------------

## 8.1 Les deux familles de methodes
##
## Toute grille de population resulte de la meme question : ON CONNAIT UN TOTAL
## POUR UNE ZONE, COMMENT LE REPARTIR A L'INTERIEUR ? Deux reponses.
##
## APPROCHE DESCENDANTE -- TOP-DOWN
##   1. Pour chaque unite administrative u, on dispose de sa population P(u).
##   2. Pour chaque cellule c de u, un poids w(c) : surface batie, indice
##      d'urbanisation, intensite lumineuse, proximite aux routes...
##   3. On attribue : pop(c) = P(u) * w(c) / somme des w(c') pour c' dans u.
##
## PROPRIETE FONDAMENTALE : LA SOMME EST EXACTE PAR CONSTRUCTION. Force
## (coherence garantie avec la source officielle) et limite : elle ne peut RIEN
## apporter que le recensement ne contenait deja au niveau administratif ; elle
## ne fait que REPARTIR. C'est la methode de WorldPop constrained et de
## GHS-POP -- et c'est ce qui explique le module 5 : si les totaux nationaux
## collent presque, c'est parce qu'ils sont CONTRAINTS a coller.
##
## APPROCHE ASCENDANTE -- BOTTOM-UP
##   1. Sur n zones observees, on connait la population P(z) et les
##      covariables X(z).
##   2. On ajuste P ~ f(X) : regression, modele hierarchique bayesien, ou foret
##      aleatoire.
##   3. On predit f sur TOUTES les cellules.
##
## PROPRIETE FONDAMENTALE : LA SOMME N'EST PAS GARANTIE. Le modele peut predire
## un total different du total officiel -- et c'est parfois LE RESULTAT
## INTERESSANT. Seule famille utilisable quand le recensement est ancien,
## incomplet, ou inexistant sur une partie du territoire.
##
## Le prix : des observations de terrain couteuses, et une qualite qui depend
## entierement de la REPRESENTATIVITE des zones observees.
##
## EN PRATIQUE : L'HYBRIDE. Un modele bottom-up produit une surface de densite,
## puis un CALIBRAGE top-down la contraint a retrouver les totaux
## administratifs.

## 8.2 La desagregation dasymetrique -- le principe
##
## Du grec dasys (dense) et metron (mesure) : UNE CARTOGRAPHIE QUI MESURE LA
## DENSITE EN TENANT COMPTE DE CE QUI EST REELLEMENT OCCUPE.
##
## La desagregation naive repartit uniformement sur la surface : elle peuple
## les forets, les lacs et les montagnes comme les quartiers. Trois niveaux de
## raffinement dasymetrique :
##   1. MASQUE BINAIRE -- zones inhabitables a poids zero. Le plus simple, et
##      de loin le plus rentable : il elimine l'erreur la plus grossiere.
##   2. POIDS CONTINUS -- surface batie, intensite lumineuse, indice
##      d'impermeabilisation.
##   3. POIDS MODELISES -- un modele apprend la relation covariables/densite
##      sur des zones connues, puis produit une surface de poids predite.
##      C'est l'approche de WorldPop.
##
## Le mot "constrained" des fichiers WorldPop signale le niveau 1 applique avec
## rigueur : AUCUNE POPULATION N'EST ATTRIBUEE A UNE CELLULE SANS BATI DETECTE.

## ------------------------------------------------------------------------
## CE QUE LA DESAGREGATION NE CREE JAMAIS
##
## DE L'INFORMATION. Une grille dasymetrique top-down contient exactement
## l'information du recensement, plus celle des covariables. AUCUNE observation
## de population a l'interieur de l'unite administrative.
##
## Consequence souvent oubliee : AGREGER UNE GRILLE DASYMETRIQUE SUR LES UNITES
## QUI ONT SERVI A LA CONSTRUIRE NE VALIDE RIEN. Le total est exact par
## construction, meme avec des poids totalement aleatoires. Une "validation"
## qui montre que la somme retombe sur le recensement ne teste que
## l'arithmetique du code.
##
## La seule validation qui a du sens est EXTERNE : comparer aux effectifs de
## zones qui n'ont PAS servi au calage. C'est ce que fait le module 7.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## 8.3 CODE DE REFERENCE - NON EXECUTE
## Raison technique : ce bloc exige un raster de covariable de surface batie
## (GHS-BUILT) qui n'est PAS livre dans le datasets/ de cette journee. Il
## appartient au J09. Le code est complet et directement transposable : il
## suffit de remplacer le chemin de la covariable.
## ------------------------------------------------------------------------

# --- 1. La grille cible et la covariable ------------------------------------
# grille_cible <- pop_2025_cmr
# batie <- rast("datasets/ghs_built_2025_cmr_100m.tif")
# batie <- resample(batie, grille_cible, method = "bilinear")

# --- 2. Le poids ------------------------------------------------------------
# Un poids nul EXCLUT definitivement la cellule : voulu pour les zones
# inhabitables, dangereux ailleurs. On pose un plancher DECLARE, pas subi.
# plancher <- 0
# poids <- ifel(batie <= plancher, 0, batie)
# cat("Cellules a poids nul :",
#     as.integer(global(poids == 0, "sum", na.rm = TRUE)[[1]]), "\n")

# --- 3. La redistribution, unite par unite ----------------------------------
# pop_desagregee <- poids * 0
#
# for (i in seq_len(nrow(cmr2))) {
#   unite   <- cmr2[i, ]
#   p_unite <- unite$pop_officielle
#   if (is.na(p_unite) || p_unite == 0) next
#
#   uv          <- vect(st_transform(unite, crs(poids)))
#   poids_unite <- mask(crop(poids, uv), uv)
#   somme_poids <- global(poids_unite, "sum", na.rm = TRUE)[[1]]
#
#   # Cas limite a NE PAS ignorer : aucune covariable dans l'unite.
#   if (is.na(somme_poids) || somme_poids == 0) {
#     cat("Unite sans covariable :", unite$NAME_2, "- population non repartie\n")
#     next
#   }
#
#   # LA formule dasymetrique : pop(c) = P(u) * w(c) / somme des w dans u
#   pop_unite      <- poids_unite * (p_unite / somme_poids)
#   pop_desagregee <- mosaic(pop_desagregee, pop_unite, fun = "sum")
# }
# names(pop_desagregee) <- "population"

# --- 4. Le controle qui ne valide RIEN (mais qui detecte les bugs) ----------
# total_grille <- global(pop_desagregee, "sum", na.rm = TRUE)[[1]]
# total_source <- sum(cmr2$pop_officielle, na.rm = TRUE)
# cat("Ecart (%) :",
#     round(100 * (total_grille - total_source) / total_source, 4), "\n")
# Cet ecart DOIT etre proche de zero. S'il ne l'est pas, il y a un bug. S'il
# l'est, cela ne prouve que l'arithmetique : voir l'encadre 8.2.

# --- 5. La validation qui, elle, a du sens ---------------------------------
# ecart <- pop_desagregee - grille_cible
# cat("Ecart cellule a cellule - moyenne :",
#     round(global(ecart, "mean", na.rm = TRUE)[[1]], 4), "\n")
# writeRaster(pop_desagregee, "outputs/J08_population_desagregee_100m.tif",
#             overwrite = TRUE, datatype = "FLT4S")

## ------------------------------------------------------------------------
## 8.4 CODE DE REFERENCE - NON EXECUTE : VARIANTE BOTTOM-UP PAR FORET
## Raison technique DOUBLE : (a) les covariables ne sont pas dans le datasets/
## de cette journee ; (b) les donnees d'entrainement -- des zones ou la
## population est REELLEMENT observee -- n'existent pas non plus. Les grappes
## EDS du J05 ne conviennent pas : effectif d'ECHANTILLON et non de population,
## et coordonnees volontairement DEPLACEES de 2 a 10 km par le DHS. Les
## utiliser comme verite terrain a 100 m produirait un modele entraine sur du
## bruit. Paquets requis, NON installes : ranger, Metrics.
## ------------------------------------------------------------------------

# library(ranger); library(Metrics)
#
# entrainement <- zones_observees |>
#   mutate(
#     batie_moy   = exact_extract(batie,   zones_observees, "mean"),
#     lumiere_moy = exact_extract(lumiere, zones_observees, "mean"),
#     dist_route  = exact_extract(routes,  zones_observees, "mean")
#   ) |>
#   st_drop_geometry() |>
#   filter(!is.na(population_observee), !is.na(batie_moy))
#
# Point de methode : une separation ALEATOIRE surestime la performance sur des
# donnees spatiales (autocorrelation : deux zones voisines se ressemblent). La
# bonne pratique est une validation croisee SPATIALE, par blocs geographiques.
# set.seed(2026)
# i_train <- sample(seq_len(nrow(entrainement)), 0.8 * nrow(entrainement))
# app <- entrainement[i_train, ]; test <- entrainement[-i_train, ]
#
# modele <- ranger(population_observee ~ batie_moy + lumiere_moy + dist_route,
#                  data = app, num.trees = 500, importance = "impurity",
#                  seed = 2026)
# cat("R2 hors-sac :", round(modele$r.squared, 3), "\n")
#
# pred <- predict(modele, data = test)$predictions
# cat("RMSE :", round(Metrics::rmse(test$population_observee, pred), 1), "\n")
# cat("MAE  :", round(Metrics::mae(test$population_observee, pred), 1), "\n")
# RMSE penalise les grosses erreurs, MAE les traite toutes a egalite. Sur des
# effectifs asymetriques, RMSE >> MAE. Publier les deux, jamais l'un seul.
#
# Le modele bottom-up ne retombe PAS sur les totaux officiels. On le contraint
# unite par unite, comme au 8.3 : c'est l'hybride, et c'est ce qui distingue
# une grille de recherche d'une grille operationnelle.


## ============================================================================
## MODULE 9 -- ATELIER : DESSINER SA ZONE ET COMPTER SES HABITANTS
## ============================================================================

## ------------------------------------------------------------------------
## CODE DE REFERENCE - NON EXECUTE
## Raison technique : editMap() est INTERACTIF. Il ouvre un widget leaflet et
## bloque jusqu'a ce qu'un humain dessine un polygone et clique "Done". Au
## rendu Quarto, personne ne clique : le document ne se rendrait jamais. De
## plus, le widget embarque le fond de carte dans le HTML.
## A LANCER EN SALLE, dans la console RStudio.
## ------------------------------------------------------------------------

# tmap_mode("view")
# tm_basemap(c("Esri.WorldImagery", "OpenStreetMap")) +
#   tm_shape(pop_2025_cmr) +
#   tm_raster(
#     col.scale  = tm_scale_intervals(style = "quantile",
#                                     values = "brewer.yl_or_rd"),
#     col.legend = tm_legend(title = "hab/cellule"),
#     col_alpha  = 0.5
#   ) +
#   tm_title("Explorer et choisir une zone a analyser")
#
# ma_zone <- mapedit::editMap(
#   leaflet::leaflet() |>
#     leaflet::addProviderTiles("Esri.WorldImagery") |>
#     leaflet::setView(lng = 11.52, lat = 3.86, zoom = 12)
# )$finished
#
# res_zone <- effectif_zone(pop_2025, ma_zone, "Ma zone")
# surface <- as.numeric(st_area(st_transform(ma_zone, 32633))) / 1e6
# cat("Surface :", round(surface, 2), "km2\n")
# cat("Densite :", round(res_zone$total / surface), "hab/km2\n")


## --- 9.2 Le repli executable : une emprise definie par ses coordonnees ------

# Emprise rectangulaire centree sur le centre-ville de Yaounde.
# Modifier les quatre coordonnees pour deplacer la zone d'etude.
bbox_zone <- st_bbox(
  c(xmin = 11.48, ymin = 3.82, xmax = 11.58, ymax = 3.93),
  crs = st_crs(4326)
) |>
  st_as_sfc() |>
  st_as_sf()

cat("Zone d'etude definie par bbox\n")
cat("  CRS      :", st_crs(bbox_zone)$input, "\n")
cat("  emprise  :", paste(round(as.numeric(st_bbox(bbox_zone)), 4),
                          collapse = " | "), "\n")

res_zone <- effectif_zone(pop_2025, bbox_zone, "Zone bbox Yaounde 2025")

surface_zone <- as.numeric(st_area(st_transform(bbox_zone, 32633))) / 1e6
cat("Surface de la zone :", round(surface_zone, 2), "km2\n")
cat("Densite dans la zone :", format(round(res_zone$total / surface_zone),
                                     big.mark = " "), "hab/km2\n")
cat("A comparer a la densite du Mfoundi entier :",
    format(round(yde_2025$total /
      (as.numeric(st_area(st_transform(yaounde, 32633))) / 1e6)), big.mark = " "),
    "hab/km2\n")

# Meme zone, autres millesimes : la trajectoire d'un quartier.
res_zone_2015 <- effectif_zone(pop_2015, bbox_zone, "Zone bbox Yaounde 2015")
res_zone_2030 <- effectif_zone(pop_2030, bbox_zone, "Zone bbox Yaounde 2030")
cat("Croissance de la zone 2015-2025 :",
    round(100 * (res_zone$total - res_zone_2015$total) / res_zone_2015$total, 1),
    "%\n")

carte_zone <- tm_shape(res_zone$raster) +
  tm_raster(
    col.scale  = tm_scale_intervals(n = 7, style = "quantile",
                                    values = "brewer.yl_or_rd"),
    col.legend = tm_legend(title = "hab/cellule")
  ) +
  tm_shape(bbox_zone) +
  tm_borders(col = "black", lwd = 2) +
  tm_title(paste0("Zone d'etude - ",
                  format(round(res_zone$total), big.mark = " "), " habitants"))

print(carte_zone)

tmap_save(carte_zone, "outputs/J08_zone_personnalisee.png",
          width = 7, height = 6, dpi = 180)

## ------------------------------------------------------------------------
## INTERPRETATION -- L'EFFECTIF D'UNE ZONE DESSINEE
##
## CE QUE LA FIGURE CODE. Les cellules WorldPop 2025 retenues a l'interieur de
## l'emprise. Le titre porte la somme de leurs effectifs : population residente
## estimee dans l'emprise, selon le modele WorldPop constrained R2025A.
##
## CE QUE LES CHOIX TECHNIQUES FONT. crop + mask retient une cellule des
## qu'elle intersecte l'emprise. global() compte donc ENTIEREMENT les cellules
## de bordure, alors que exact_extract() les compterait AU PRORATA. Sur une
## zone de quelques km2, la difference est reelle : c'est l'exercice 4. La
## discretisation en quantiles est recalculee SUR CETTE ZONE SEULEMENT -- ces
## couleurs ne sont PAS comparables a celles de la carte nationale du module 3.
##
## CE QUI SE LIT. La structure interne du peuplement dans la zone, et un
## effectif immediatement utilisable pour dimensionner une intervention.
##
## CE QUI NE SE LIT PAS. L'INCERTITUDE, bien plus grande que celle d'un
## effectif regional. Plus la zone est petite, plus le chiffre depend de la
## repartition modelisee et moins il depend du total recense, qui est solide.
## Un effectif de zone est FIABLE EN ORDRE DE GRANDEUR, PAS EN VALEUR. Ni la
## composition : ni ages, ni sexes, ni menages.
## ------------------------------------------------------------------------

## ------------------------------------------------------------------------
## EN QUOI LE SPATIAL EST UTILE ICI -- LA REPONSE FINALE
##
## Cette section est la seule qui ne peut ABSOLUMENT PAS etre remplacee par un
## tableau. Aucune ligne d'aucun fichier administratif ne contient l'effectif
## de cette emprise, parce que cette emprise n'existait pas avant qu'on la
## dessine.
##
## C'est ce qu'une grille apporte : elle DECOUPLE LA MAILLE DE LA MESURE DE LA
## MAILLE DE LA DECISION. Les recensements comptent dans des unites
## administratives ; les decisions se prennent dans des rayons, des bassins
## versants, des emprises d'inondation, des aires de recrutement.
##
## Le prix : ce pont est un MODELE. L'effectif de la zone est une estimation
## dont on connait, grace au module 5, l'ecart typique a la reference
## regionale, et grace au module 7, l'ecart typique a une grille concurrente.
## Ces deux nombres doivent voyager avec le chiffre.
## ------------------------------------------------------------------------

## 9.3 Consigne d'atelier
##
## 1. Choisir une zone qui a un sens pour votre institution.
## 2. La dessiner (mapedit en direct) ou en ecrire l'emprise (bloc bbox).
## 3. Calculer son effectif 2025, sa surface, sa densite.
## 4. COMPARER AVEC LA PERSONNE ASSISE A COTE qui a dessine "la meme" zone.
## 5. Ecrire, en trois phrases : de combien vos deux chiffres different,
##    pourquoi, et quelle information supplementaire serait necessaire pour
##    trancher.
##
## La question 4 est la plus importante de la journee. Deux traces "du meme
## quartier" donnent regulierement des effectifs qui different de 10 a 30 %. La
## lecon n'est pas que la grille est mauvaise : c'est que LA DEFINITION DE LA
## ZONE EST UNE DECISION D'ANALYSTE, et qu'elle pese souvent plus lourd que le
## choix de la grille.


## ============================================================================
## EXPORTS
## ============================================================================

write_csv(regions_pop, "outputs/J08_population_regions_worldpop_2015_2025.csv")
write_csv(pop_villes,  "outputs/J08_population_grandes_villes_2015_2025.csv")
write_csv(comparaison_officiel,
          "outputs/J08_ecart_worldpop_officiel_adm1.csv")

couche_finale <- cmr1_pop |>
  left_join(
    regions_pop |> select(NAME_1, pop_worldpop_2015, pop_worldpop_2025,
                          variation, croissance_pct),
    by = "NAME_1"
  )

cat("Couche finale : ", nrow(couche_finale), " entites, ",
    ncol(couche_finale), " colonnes\n", sep = "")

st_write(couche_finale, "outputs/J08_regions_population_complete.gpkg",
         delete_dsn = TRUE, quiet = TRUE)

cat("\nFichiers ecrits dans outputs/ :\n")
cat(paste("  ", sort(list.files("outputs", pattern = "^J08_"))), sep = "\n")


## ============================================================================
## GLOSSAIRE, FONCTIONS CLES, EXERCICES ET PROLONGEMENTS
## ============================================================================
## Ces quatre sections sont identiques a celles de script_formateur_J08.R et de
## demo_formateur_J08.qmd. Elles y sont reproduites integralement ; on renvoie
## ici au document de la journee (demo_formateur_J08.qmd, sections "Glossaire",
## "Recapitulatif des fonctions cles", "Exercices", "Prolongements") pour ne
## pas dupliquer une troisieme fois soixante lignes de texte dans un fichier
## deja long.
##
## RAPPEL DES HUIT EXERCICES ET DE LEUR PIEGE :
##   1. La jointure qui ne previent pas .......... echec silencieux de jointure
##   2. Trois discretisations du meme tableau .... la discretisation raconte
##                                                 l'histoire
##   3. L'ecart aux chiffres officiels ........... une carte donne a un chiffre
##                                                 faux la meme autorite qu'a un
##                                                 chiffre juste
##   4. Bordure : global() vs exact_extract() .... traitement des cellules de
##                                                 bordure
##   5. MAUP a trois mailles ..................... MAUP, effet d'echelle
##   6. L'erreur ecologique, mise en nombre ...... erreur ecologique
##   7. Un millesime, une methode ................ comparer deux produits
##                                                 construits differemment
##   8. Population scolarisable dans une zone .... erreur ecologique appliquee ;
##                                                 ce qu'une grille ne contient
##                                                 pas
##
## RAPPEL DES QUATRE PIEGES DE RAISONNEMENT DE LA JOURNEE :
##   - MAUP : les resultats dependent de la maille (effet d'echelle + effet de
##     zonage). Aucune maille n'est neutre ; choisir celle de la DECISION.
##   - ERREUR ECOLOGIQUE : attribuer a un individu ce qui n'est vrai que de
##     l'agregat.
##   - PARADOXE DE SIMPSON : une correlation agregee peut etre de signe oppose
##     a la correlation individuelle.
##   - BIAIS DE TAILLE : la moyenne des densites regionales n'est pas la
##     densite nationale.

## ============================================================================
## FIN DU CORRIGE J08
## ============================================================================
