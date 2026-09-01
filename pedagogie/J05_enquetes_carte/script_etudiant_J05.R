## ============================================================================
## SCRIPT ETUDIANT -- J05 : DES ENQUETES A LA CARTE
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Vendredi 31 juillet 2026
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
.dossier_jour <- "J05_enquetes_carte"
if (!dir.exists("datasets")) {
  for (.p in c(.dossier_jour, file.path("pedagogie", .dossier_jour))) {
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
## Comment utiliser ce script
##
## Executez-le section par section (Ctrl+Entree sous RStudio), en verifiant
## chaque sortie avant de passer a la suivante. Ce dossier est autonome :
## les donnees sont dans datasets/, les sorties vont dans outputs/, et tous
## les chemins sont relatifs a ce dossier.
##
## Prealable, une seule fois : source("install_packages_day.R")
## Les imports proteges par file.exists() n'interrompent pas l'execution
## si une donnee manque : ils affichent un message.
## ----------------------------------------------------------------------

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
suppressPackageStartupMessages(library(sf))
sf::sf_use_s2(FALSE)

## ----------------------------------------------------------------------
## Un réglage posé une fois pour toutes
##
## Ce document commence par sf::sf_use_s2(FALSE). Par défaut, sf traite les
## coordonnées en degrés sur une sphère (bibliothèque s2), plus juste
## mathématiquement mais bien plus exigeant sur la propreté des géométries :
## la moindre auto-intersection fait échouer le calcul.
##
## DS.geojson en compte 135 sur 200. On repasse donc au moteur planaire
## (GEOS), plus tolérant. Cela n'autorise pas à mesurer sur des degrés :
## toute superficie de ce document passe par une reprojection en UTM.
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## MODULE 1 — LE TIDYVERSE AU SERVICE DE L'ENQUÊTE
## ##########################################################################
## ##########################################################################

## ========================================================================
## 1.1 — LE TIDYVERSE, ET POURQUOI « TIDY » PRÉCÈDE « SPATIAL »
## ========================================================================
# LA PHILOSOPHIE "TIDY DATA" (Wickham, 2014)
#   - chaque variable occupe une colonne ;
#   - chaque observation occupe une ligne ;
#   - chaque valeur occupe une cellule.
#
# Ce n'est pas une coquetterie de style. Une jointure -- attributaire ou
# spatiale -- suppose exactement cette forme : une ligne = une unite a relier,
# une colonne = la cle. Un tableau "large" (une colonne par annee, une colonne
# par indicateur) ne se joint pas a une couche geographique sans etre remis
# a plat d'abord. D'ou l'importance de tidyr, vu en 1.4.

# === CHARGEMENT DES PACKAGES ================================================
# La liste est volontairement courte : elle correspond aux library() reellement
# utilises par cette journee. L'installation se fait une fois, par
# source("install_packages_day.R").
library(tidyverse)   # dplyr, tidyr, ggplot2, readr, stringr, forcats...
library(sf)          # donnees vectorielles (Simple Features)
library(haven)       # lecture .sav (SPSS) et .dta (Stata) + etiquettes
library(janitor)     # clean_names(), tabyl()
library(naniar)      # visualisation des valeurs manquantes
library(tmap)        # cartographie thematique (API version 4)
library(stringi)     # translitteration des accents pour les jointures

# Pas de setwd() ici : le dossier de la journee est autonome et tous les
# chemins sont relatifs a lui. Quarto s'y place tout seul au rendu ; le script
# .R equivalent le fait explicitement dans son en-tete.
cat("Dossier de travail :", getwd(), "\n")
cat("Fichiers de donnees :", length(list.files("datasets")), "\n")

## ----------------------------------------------------------------------
## Les trois familles de données de la journée
##
## | Famille | Fichier | Unité d'observation | Ce qu'elle porte |
## | Enquête ménages | ecam5.dta | l'individu | pauvreté, revenu, conditions de logement |
## | Enquête EDS | CMHR71FL.SAV + CMGE71FL.shp | le ménage, rattaché à une grappe géolocalisée | eau, électricité, assainissement |
## | Territoire | gadm41_CMR_*.shp, DS.geojson | le polygone administratif ou sanitaire | la géométrie, rien d'autre |
##
## Toute la journée consiste à faire descendre l'information de la première
## colonne vers la troisième. Les deux ponts possibles sont : une **clé
## commune** (un nom, un code — jointure attributaire, section 2.2) ou une
## position (des coordonnées tombant dans un polygone — jointure spatiale,
## section 4.1).
##
## ----------------------------------------------------------------------


## ========================================================================
## 1.2 — LECTURE DES DONNÉES RÉELLES
## ========================================================================
# Chaque lecture ci-dessous est precedee de ce que le fichier contient
# REELLEMENT -- verifie, pas suppose. C'est la premiere discipline du metier :
# on ne code pas contre un nom de colonne qu'on imagine.

# --- 1.2.1 ECAM5 2021-2022 (INS Cameroun) ------------------------------------
# Format Stata. haven conserve les etiquettes de variables ET de valeurs.
ecam5 <- read_dta("datasets/ecam5.dta")
cat("ECAM5 :", nrow(ecam5), "lignes x", ncol(ecam5), "colonnes\n")
cat("Chefs de menage (s01q3 == 1) :",
    sum(ecam5$s01q3 == 1, na.rm = TRUE), "menages\n")

# --- 1.2.2 EDS-MICS 2018 : le recode MENAGE ----------------------------------
# CMHR71FL.SAV pese ~72 Mo et compte plus de 4 000 colonnes. En lire
# l'integralite prend une minute et sature la memoire pour rien : on ne
# demande QUE les variables dont la journee a besoin (col_select).
#
#   hv001  numero de grappe  <- LA CLE VERS LA GEOMETRIE
#   hv005  poids de sondage menage (a diviser par 1 000 000)
#   hv009  nombre de membres du menage
#   hv024  region d'enquete (12 modalites, comme ECAM5)
#   hv025  milieu : 1 = urbain, 2 = rural
#   hv201  source d'eau de boisson
#   hv205  type de toilettes
#   hv206  le menage a-t-il l'electricite
#   hv270  indice de richesse en quintiles
#
# SECOND PIEGE, decouvert au J01 : les fichiers SPSS du DHS ecrivent leurs
# noms de variables en MAJUSCULES (HV001), alors que la documentation et tous
# les manuels les citent en minuscules. Un col_select = c(hv001, ...) echoue.
# On lit donc d'abord l'en-tete seul, on apparie sans tenir compte de la
# casse, puis on relit en ne demandant que ces colonnes.
vars_voulues <- c("hv001", "hv005", "hv009", "hv024", "hv025",
                  "hv201", "hv205", "hv206", "hv270")
noms_sav <- names(read_sav("datasets/CMHR71FL.SAV", n_max = 0))
vars_reelles <- noms_sav[match(toupper(vars_voulues), toupper(noms_sav))]

cat("Variables demandees / retrouvees :", length(vars_voulues), "/",
    sum(!is.na(vars_reelles)), "\n")
cat("Telles qu'elles sont ecrites dans le .SAV :",
    paste(na.omit(vars_reelles), collapse = ", "), "\n")

dhs_men <- read_sav("datasets/CMHR71FL.SAV",
                    col_select = all_of(na.omit(vars_reelles))) |>
  clean_names()   # on repasse tout en minuscules, une fois pour toutes

cat("EDS menages :", nrow(dhs_men), "menages x", ncol(dhs_men), "variables\n")

# --- 1.2.3 EDS-MICS 2018 : la GEOMETRIE des grappes --------------------------
# PIEGE DE NOMMAGE. CMGC72FL.csv ressemble a un fichier de coordonnees ; il
# n'en contient aucune. C'est le fichier des COVARIABLES contextuelles :
# 130 variables par grappe, deja extraites de rasters (pluie, aridite,
# prevalence du paludisme, nuit lumineuse...). La position, elle, est dans le
# shapefile CMGE71FL.shp. La cle qui relie les trois fichiers est DHSCLUST.
dhs_geo <- st_read("datasets/CMGE71FL.shp", quiet = TRUE)
dhs_covar <- read_csv("datasets/CMGC72FL.csv", show_col_types = FALSE)

cat("Grappes geolocalisees :", nrow(dhs_geo), "\n")
cat("Covariables contextuelles :", ncol(dhs_covar), "colonnes\n")
cat("CMGC72FL contient-il des coordonnees ? ",
    any(grepl("^LAT|^LON", names(dhs_covar))), "\n")
cat("CMGE71FL, lui, en contient :",
    paste(grep("^LAT|^LON", names(dhs_geo), value = TRUE), collapse = ", "), "\n")

# --- 1.2.4 Population et menages par departement (WorldPop) ------------------
# PIEGE DE SEPARATEUR. Les deux fichiers portent la meme extension mais pas
# le meme delimiteur : la population est en POINTS-VIRGULES, les menages en
# virgules. read_csv() sur le premier renvoie UNE colonne unique, sans lever
# la moindre erreur -- l'erreur n'apparaitrait que 200 lignes plus loin.
pop_adm2 <- read_delim("datasets/CMR_population_v1_0_admin_level2.csv",
                       delim = ";", show_col_types = FALSE)
men_adm2 <- read_csv("datasets/CMR_household_v1_0_admin_level2.csv",
                     show_col_types = FALSE)

# Colonnes reelles des deux : id, names1 (nom du departement), total, lower,
# median, upper, uncertainty. Ces effectifs sont MODELISES a partir d'imagerie
# et de recensements, d'ou l'intervalle lower-upper et l'indice d'incertitude.
cat("\nColonnes de pop_adm2 :", paste(names(pop_adm2), collapse = ", "), "\n")
cat("Departements couverts :", nrow(pop_adm2), "|", nrow(men_adm2), "\n")

# --- 1.2.5 Les couches geographiques -----------------------------------------
# GADM 4.1 : le decoupage administratif officiel.
cmr_l1 <- st_read("datasets/gadm41_CMR_1.shp", quiet = TRUE)  # 10 regions
cmr_l2 <- st_read("datasets/gadm41_CMR_2.shp", quiet = TRUE)  # 58 departements

# DS.geojson : export DHIS2 du ministere de la Sante. 200 districts, des noms
# de champs techniques -- il n'existe NI "NomDS", NI "CodeDS", NI "NomRegion".
# Le nom est dans 'name' (prefixe "District "), la region dans 'parentName'
# (prefixe "Region "). Et 135 geometries sur 200 sont invalides : on repare
# des la lecture, avant toute operation spatiale.
ds_sante <- st_read("datasets/DS.geojson", quiet = TRUE) |>
  st_make_valid() |>
  mutate(
    ds_nom    = sub("^District\\s+", "", name),
    ds_region = sub("^Region\\s+",   "", parentName)
  )

pays_lim <- st_read("datasets/Pays_limitrophes_Cmr.shp", quiet = TRUE) |>
  filter(!is.na(COUNTRY), COUNTRY != "")

cat("\nRegions GADM      :", nrow(cmr_l1), "\n")
cat("Departements GADM :", nrow(cmr_l2), "\n")
cat("Districts sanitaires :", nrow(ds_sante),
    "reparties en", dplyr::n_distinct(ds_sante$ds_region), "regions\n")
cat("Geometries valides apres reparation :",
    sum(st_is_valid(ds_sante)), "/", nrow(ds_sante), "\n")
cat("CRS des couches :", st_crs(cmr_l2)$epsg, st_crs(ds_sante)$epsg,
    st_crs(dhs_geo)$epsg, st_crs(pays_lim)$epsg, "\n")

## ----------------------------------------------------------------------
## Trois fichiers, trois orthographes de la même région
##
## C'est le problème central de la journée, et il apparaît dès la lecture :
##
## | Source | Écriture de la même région | Nombre de modalités |
## | ECAM5 (s0q1) | extrême-nord, douala, yaounde | 12 |
## | EDS (ADM1NAME) | EXTREME-NORD, DOUALA, YAOUNDE | 12 |
## | GADM (NAME_1) | Extrême-Nord | 10 |
##
## Deux écarts, de nature différente :
##
## - un écart typographique (casse, accents) — il se règle par normalisation
## des chaînes, section 2.2 ; - un écart de découpage — les deux enquêtes
## isolent Douala et Yaoundé comme « régions d'enquête » à part entière,
## alors que la carte administrative les range dans le Littoral et le Centre.
## Ce second écart ne se règle pas par du nettoyage de texte : il demande une
## **table de correspondance** explicite, une décision de méthode.
##
## Une jointure naïve by = "region" renverrait ici 0 appariement, sans
## erreur.
##
## ----------------------------------------------------------------------


## ========================================================================
## 1.3 — LES VERBES FONDAMENTAUX DE DPLYR
## ========================================================================
#dplyr propose six verbes essentiels qui constituent la grammaire de la manipulation de données.

#Verbe dplyr	Action	Équivalent SQL
#filter()	Filtrer les lignes selon des conditions	WHERE
#select()	Sélectionner des colonnes	SELECT
#mutate()	Créer ou modifier des colonnes	SELECT ... AS
#summarise()	Calculer des statistiques résumées	GROUP BY + agrégats
#arrange()	Trier les lignes	ORDER BY
#group_by()	Grouper avant summarise()	GROUP BY

#L'opérateur pipe |> (ou %>%)
#Le pipe enchaîne les opérations de gauche à droite, comme une chaîne de traitement.

# L'operateur pipe  |>  signifie "puis".
# ecam5 |> filter(...) se lit : "prends ecam5, puis filtre..."

# --- LES VRAIES VARIABLES D'ECAM5 -------------------------------------------
# Avant d'ecrire la moindre ligne, on regarde ce que le fichier contient.
# Les noms sont ceux du questionnaire, pas des libelles parlants.
ecam5 |>
  select(hhid, s0q1, milieu, tailm, nivie, revactp, coefextr) |>
  head(5) |>
  print()

# Correspondance, a garder sous les yeux :
#   hhid      identifiant du menage
#   s0q1      region d'enquete   (12 modalites, etiquetees)
#   milieu    1 = urbain, 2 = rural
#   tailm     taille du menage
#   nivie     statut de pauvrete : 0 = non pauvre, 1 = pauvre
#   revactp   revenu de l'activite principale, en francs CFA
#   coefextr  coefficient d'extrapolation = LE POIDS DE SONDAGE

# Les etiquettes de valeur sont dans le fichier : haven les conserve.
cat("\nRegions codees dans s0q1 :\n")
print(haven::as_factor(ecam5$s0q1) |> levels())
cat("\nMilieu :", levels(haven::as_factor(ecam5$milieu)),
    "| Pauvrete :", levels(haven::as_factor(ecam5$nivie)), "\n")

# --- On se donne des noms lisibles -------------------------------------------
# Renommer une fois evite de manipuler s0q1 et revactp pendant tout le document.
ecam5 <- ecam5 |>
  mutate(
    region       = haven::as_factor(s0q1),      # etiquettes -> facteur lisible
    milieu_lib   = haven::as_factor(milieu),
    est_pauvre   = as.integer(nivie),           # 1 = pauvre
    taille_men   = as.numeric(tailm),
    revenu       = as.numeric(revactp),
    poids        = as.numeric(coefextr)
  )

# --- 1.3.1 filter() : selectionner des lignes selon des criteres -------------

# Plusieurs conditions combinees

# Filtrer par region, en clair plutot qu'en code numerique


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 1.3.2 select() : choisir les colonnes -----------------------------------

# Selection par motif de nom -- utile sur un fichier a 70 colonnes


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 1.3.3 mutate() : creer de nouvelles variables ---------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ce fichier décrit des personnes, et son hhid est partiellement masqué
##
## ecam5.dta compte 9 472 lignes pour 2 065 ménages : chaque ligne est un
## individu, et les variables de ménage — milieu, tailm, nivie, coefextr —
## sont répétées pour chacun de ses membres.
##
## Le réflexe serait de compter les ménages par n_distinct(hhid). Il donne 1
## 613, et il est faux. L'identifiant a été anonymisé pour une partie des
## ménages : 1 769 lignes portent l'un des sept codes masqués 10 … 70. hhid
## n'est donc pas une clé de ménage utilisable.
##
## Deux repères fiables existent dans le fichier :
##
## - s01q3 == 1 — le chef de ménage. Il y en a exactement un par ménage, soit
## 2 065. C'est le compteur à utiliser. - une clé composée des variables
## constantes au sein d'un ménage (hhid, région, milieu, taille, statut de
## pauvreté, poids). Elle isole 2 065 groupes, et la taille de chaque groupe
## coïncide avec tailm pour les 2 065 — la vérification qui valide la clé.
##
## Ce n'est pas une curiosité : **une clé qu'on n'a pas vérifiée est une
## source d'erreurs silencieuses**. Ici, elle aurait sous-estimé de 22 % le
## nombre de ménages, et faussé tous les taux calculés par ménage.
##
## ----------------------------------------------------------------------

# --- Construire une cle de menage FIABLE -------------------------------------
# Les variables ci-dessous sont constantes a l'interieur d'un menage : leur
# combinaison identifie le menage meme quand hhid est masque.

# VERIFICATION de la cle : la taille de chaque groupe doit valoir tailm.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- Individu ou menage ? Les deux taux ne sont pas les memes ----------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- Le meme biais sur la taille des menages --------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- Et sans ponderation ? ---------------------------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Trois chiffres différents pour « la » taille moyenne d'un ménage
##
## Le bloc ci-dessus affiche deux moyennes très écartées à partir de la même
## colonne tailm. Ce n'est pas une erreur de calcul, c'est un **biais de
## taille* (length-biased sampling*), et il est fondamental.
##
## En parcourant les lignes du fichier, on parcourt des individus. Un ménage
## de 10 personnes apparaît dix fois, un ménage d'une personne une seule fois
## : les grands ménages sont mécaniquement surreprésentés. La moyenne
## calculée sur les individus répond donc à la question « quelle est la
## taille du ménage d'une personne prise au hasard ? », pas « quelle est la
## taille **d'un ménage** pris au hasard ? ».
##
## Le même mécanisme joue sur la pauvreté, et dans le même sens : les ménages
## pauvres étant plus grands, le taux par individu dépasse le taux **par
## ménage**. Les deux sont exacts ; ils ne répondent simplement pas à la même
## question. La statistique officielle de pauvreté au Cameroun est un taux
## par individu — c'est la convention internationale, parce que c'est la
## personne, pas le ménage, qui est pauvre.
##
## La règle à retenir : **avant de calculer une moyenne, dire de quoi on
## prend la moyenne**. Et sur ces données, filter(s01q3 == 1) est le geste
## qui fait passer de l'un à l'autre.
##
## ----------------------------------------------------------------------


## ========================================================================
## 1.4 — TIDYR : RESTRUCTURER POUR POUVOIR JOINDRE
## ========================================================================
# tidyr fait passer un tableau du format LARGE (un indicateur par colonne) au
# format LONG (une ligne par couple unite x indicateur), et inversement.
#
# Pourquoi cela compte ici : une couche geographique se joint a UN tableau
# ayant UNE ligne par polygone. Le format long sert a calculer, comparer,
# empiler des indicateurs ; le format large sert a joindre et a cartographier.
# On navigue constamment entre les deux.

# --- 1.4.1 Construire d'abord le tableau regional a plat ---------------------
# Une ligne par region d'enquete, plusieurs indicateurs en colonnes.
# Tous les taux sont PONDERES : sans coefextr on decrit l'echantillon, pas
# le pays (cf. 1.3.4).


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 1.4.2 pivot_longer() : large -> long ------------------------------------
# Utile pour tracer plusieurs indicateurs sur une meme figure a facettes.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 1.4.3 pivot_wider() : long -> large -------------------------------------
# Le chemin inverse. C'est CETTE forme qu'on joindra a la couche GADM.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 1.4.4 separate() : decomposer un code hierarchique ----------------------
# GADM encode la hierarchie dans GID_2 : "CMR.1.3_1" = pays CMR, region 1,
# departement 3. Le separer donne les cles des niveaux superieurs sans avoir
# a ouvrir un autre fichier.


# unite() recompose : utile pour fabriquer une cle unique quand aucune
# n'existe (ici region + departement, deux departements pouvant etre homonymes
# dans deux regions differentes).

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Lire le tableau régional produit ci-dessus
##
## Trois colonnes, trois choses différentes :
##
## - n_individus vs n_menages — l'écart entre les deux rappelle qu'ECAM5 est
## un fichier d'individus. Une région peut avoir beaucoup de lignes et peu de
## ménages : les ménages y sont grands. - taux_pauvrete — proportion pondérée
## d'individus vivant sous le seuil national. Pondérée signifie que chaque
## individu compte pour le nombre de Camerounais qu'il représente (coefextr),
## pas pour un. - pct_urbain — part de la population régionale en milieu
## urbain. Il vaut 100 % pour Douala et Yaoundé, par construction : ce sont
## des régions d'enquête entièrement urbaines. C'est le premier signe visible
## du problème de découpage.
##
## ----------------------------------------------------------------------

# --- Une cle de jointure qui resiste aux accents ----------------------------
# Les libelles de region s'ecrivent differemment selon les fichiers ET selon
# l'encodage de la machine. Joindre sur "extrême-nord" tel quel echoue des
# qu'un accent est encode autrement. On fabrique donc une cle TECHNIQUE :
# sans accent, sans casse, sans ponctuation, sans espaces. Cette fonction
# resservira tout au long de la journee ; la section 2.2 la detaille.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- CONFRONTER LE RESULTAT A UNE REFERENCE PUBLIEE -------------------------
# Geste obligatoire avant toute carte : comparer ce qu'on vient de calculer a
# un chiffre publie. Si les deux divergent, c'est le calcul OU la donnee qui
# est en cause -- jamais "le hasard".
# Source : INS Cameroun, resultats ECAM5 publies (taux national : 37,7 %).


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ce que dit ce contrôle : un extrait pédagogique, pas la statistique
## officielle
##
## Le taux national calculé sur ce fichier tombe à moins d'un point du
## chiffre publié par l'INS : la pondération fonctionne, la somme des poids
## reconstitue bien la population du pays.
##
## Les taux régionaux, eux, ne suivent pas tous. Quatre régions restent dans
## un écart plausible, mais l'Est ressort ici très en dessous du taux publié.
## Un écart de cette ampleur n'est pas un aléa d'échantillonnage : c'est le
## signal que le fichier utilisé est un extrait de formation, un sous-
## échantillon qui n'est pas représentatif à l'intérieur de chaque région.
##
## Trois conséquences, à énoncer maintenant plutôt qu'après la carte :
##
## - aucun chiffre régional de ce document ne doit être cité comme
## statistique officielle. Les cartes qui suivent sont des démonstrations de
## méthode ; - le classement général reste exploitable pour l'exercice — les
## trois régions septentrionales dominent, les deux métropoles ferment la
## marche — mais l'Est est à traiter comme une valeur suspecte, pas comme un
## résultat ; - surtout, le geste lui-même est la leçon : **confronter
## systématiquement un résultat à une référence externe avant de le
## cartographier**. Une carte ne contient aucun avertissement ; elle donne à
## un chiffre faux exactement la même autorité visuelle qu'à un chiffre
## juste.
##
## ----------------------------------------------------------------------

# Le format long se prete directement a une figure a facettes : trois
# indicateurs, trois panneaux, la meme grammaire ggplot2.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ce que montre — et ne montre pas — cette figure
##
## Chaque barre est une région d'enquête, triée par valeur croissante à
## l'intérieur de son panneau. scales = "free_x" autorise une échelle
## différente par panneau : indispensable ici, un taux en pourcentage et une
## taille de ménage en personnes n'ont aucune raison de partager un axe.
##
## Le rapprochement des trois panneaux suggère une corrélation : les régions
## les plus pauvres sont aussi celles où les ménages sont les plus grands et
## où l'urbanisation est la plus faible. Suggère, seulement. Le graphique
## aligne des barres, il ne teste rien, et il ne dit surtout pas dans quel
## sens joue la causalité — un ménage devient-il pauvre parce qu'il est
## grand, ou grand parce qu'il est pauvre ?
##
## Ce que ce graphique ne peut pas montrer non plus : le voisinage. Adamaoua
## et Nord sont côte à côte sur la carte et devraient se ressembler ; Sud et
## Sud-Ouest aussi. Ici ils sont dispersés dans l'ordre alphabétique de leurs
## valeurs, et toute information de contiguïté est perdue. C'est précisément
## ce que la carte restitue, et c'est la raison d'être de la journée.
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## MODULE 2 — DE LA TABLE À LA COUCHE : LES JOINTURES ATTRIBUTAIRES
## ##########################################################################
## ##########################################################################
# OBJECTIFS DU MODULE
#  - lire un objet sf comme ce qu'il est : un data.frame + une colonne
#    geometry, sur lequel tous les verbes dplyr fonctionnent ;
#  - relier un tableau de statistiques a une couche geographique par une cle
#    commune, et mesurer ce que la jointure a perdu ;
#  - fabriquer des points spatiaux a partir de coordonnees GPS d'enquete.


## ========================================================================
## 2.1 — ANATOMIE D'UN OBJET SF
## ========================================================================
# Un objet sf est un data.frame ORDINAIRE auquel s'ajoute une colonne
# 'geometry' (liste de coordonnees) et deux attributs : le CRS et l'emprise.
# Consequence pratique : filter(), select(), mutate(), group_by() marchent
# tels quels. La geometrie suit automatiquement les lignes conservees.


# La geometrie est "collante" : elle suit le filtre sans qu'on la mentionne.

# st_drop_geometry() fait l'operation inverse : on revient a un data.frame
# ordinaire. A utiliser des qu'on n'a plus besoin de la carte -- les calculs
# sur un sf trainent la geometrie a chaque etape et sont bien plus lents.

# Trois couches, trois granularites, une seule figure de reperage.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Pourquoi trois découpages, et lequel choisir
##
## Les trois cartes couvrent le même pays et ne se superposent pas. Le
## découpage sanitaire n'est pas un sous-découpage de l'administratif : il
## suit l'implantation des formations sanitaires et la population desservie,
## pas les frontières de préfecture. Un district sanitaire peut chevaucher
## deux départements.
##
## La conséquence est méthodologique, pas décorative : **le choix du maillage
## change le résultat**. Le même semis de grappes agrégé par région, par
## département ou par district sanitaire ne donne pas les mêmes cartes ni les
## mêmes extrêmes. C'est le problème de l'unité spatiale modifiable (MAUP,
## Modifiable Areal Unit Problem) : les statistiques d'agrégats dépendent de
## la maille choisie, sans qu'aucune maille ne soit « la vraie ».
##
## La règle pratique : choisir la maille de la décision qu'on éclaire. Pour
## un plan de déploiement de forages, le district sanitaire est le bon niveau
## — c'est lui qui a un budget et un chef. Pour un débat budgétaire national,
## la région. Le maillage n'est pas un détail technique : c'est déjà une
## position.
##
## ----------------------------------------------------------------------


## ========================================================================
## 2.2 — JOINDRE PAR UNE CLÉ COMMUNE
## ========================================================================
# Une jointure attributaire relie deux tableaux par une colonne partagee.
# Le piege n'est jamais la syntaxe de left_join() : c'est que la cle des deux
# cotes ne s'ecrit pas pareil. Et une jointure qui echoue ne leve AUCUNE
# erreur : elle remplit de NA.

# --- 2.2.1 La tentative naive ------------------------------------------------
# WorldPop nomme les departements dans 'names1', GADM dans 'NAME_2'.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 2.2.2 Normaliser les deux cotes AVANT de joindre ------------------------
# On fabrique une cle technique : sans accents, sans casse, sans ponctuation,
# sans mots de liaison, sans espaces. Elle ne sert qu'a joindre -- on garde
# toujours le libelle d'origine pour l'affichage.
# (fonction deja posee en 1.4 ; on la redonne ici, c'est le coeur du sujet)


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 2.2.3 La jointure proprement dite ---------------------------------------
# left_join en partant de la COUCHE : on garde les 58 polygones, quitte a
# avoir des NA. L'inverse (partir du tableau) perdrait la geometrie.

# CONTROLE SYSTEMATIQUE apres toute jointure : compter les NA.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 2.2.4 Le pont ECAM5 -> carte : 12 regions d'enquete, 10 regions GADM ----
# Ici la normalisation ne suffit pas. Douala et Yaounde n'existent pas comme
# regions administratives : ce sont les capitales du Littoral et du Centre,
# que les enquetes isolent pour des raisons d'echantillonnage.
#
# Aucune manipulation de chaine ne peut deviner cela. Il faut une table de
# correspondance ECRITE A LA MAIN -- et donc une decision documentee.

# On joint sur les CLES NORMALISEES, jamais sur les libelles : les accents
# ne s'ecrivent pas de la meme facon d'un fichier -- et d'une machine -- a
# l'autre.


# On agrege ECAM5 AU NIVEAU ADMINISTRATIF, en repassant par les poids : la
# fusion de deux regions d'enquete n'est pas la moyenne de leurs deux taux,
# c'est la moyenne ponderee de leurs individus.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- La premiere carte de la journee : le tableau devient territoire ---------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Lire cette carte : ce que le tableau ne disait pas
##
## Le vocabulaire d'abord. Une carte choroplèthe colore chaque unité
## administrative selon la valeur d'un indicateur. La discrétisation est la
## règle qui découpe les valeurs continues en classes de couleur. Ici, style
## = "jenks" applique la méthode des seuils naturels (Jenks) : l'algorithme
## cherche les coupures qui minimisent la variance à l'intérieur de chaque
## classe et la maximisent entre classes. Autrement dit, il coupe là où les
## données elles-mêmes présentent un décrochement. C'est le choix adapté
## quand la distribution est irrégulière — le cas ici, où trois régions
## décrochent nettement du reste.
##
## Deux alternatives, à connaître car elles racontent une autre histoire du
## même tableau : "quantile" met le même nombre de régions par classe
## (lisible, mais fabrique du contraste là où il n'y en a pas) et "equal"
## découpe l'échelle en tranches de largeur égale (fidèle aux écarts réels,
## mais peut laisser une classe vide).
##
## Ce qu'on voit ensuite. Le tableau trié de la section 1.4 donnait un
## classement ; la carte ajoute ce qu'aucun classement ne contient : la
## contiguïté. Les quatre régions les plus pauvres ne sont pas dispersées au
## hasard — Extrême-Nord, Nord et Adamaoua forment un **bloc septentrional
## continu**, prolongé à l'ouest par le Nord-Ouest. La pauvreté n'est pas un
## attribut individuel de chaque région : elle a une forme géographique.
##
## L'Est fait exception sur cette carte, en clair alors que la statistique
## publiée le place parmi les régions les plus pauvres. Le contrôle de la
## section 1.4 a déjà identifié la cause : c'est un artefact de l'extrait de
## formation. Le mentionner ici n'est pas une digression — c'est ce qu'il
## faudrait écrire en note sous la carte si on la diffusait.
##
## Pourquoi c'est décisif pour l'analyse. Un bloc contigu ne s'explique pas
## par les caractéristiques propres de chaque région, mais par ce qu'elles
## partagent parce qu'elles sont voisines : climat sahélien, éloignement des
## ports de Douala et Kribi, faible densité du réseau routier bitumé,
## insécurité transfrontalière. La carte ne démontre aucun de ces mécanismes
## — elle rend l'hypothèse spatiale visible et testable. Le J07 y reviendra
## avec les outils qui la testent (autocorrélation spatiale, indice de
## Moran).
##
## C'est là toute la valeur ajoutée du spatial pour analyser un phénomène
## social : il fait passer d'une liste d'unités indépendantes à un **système
## de voisinages**. Tant qu'on raisonne sur un tableau, chaque région est une
## observation isolée et les seules explications disponibles sont ses propres
## caractéristiques. Dès qu'on cartographie, on voit que les valeurs se
## ressemblent d'autant plus que les unités sont proches — et cette
## ressemblance devient elle-même l'objet à expliquer.
##
## Ce qu'elle ne dit pas. Une couleur uniforme sur l'Extrême-Nord ne signifie
## pas que la pauvreté y est uniforme : c'est une **moyenne régionale**, qui
## écrase l'écart entre Maroua et les campagnes du Logone. En tirer une
## conclusion sur un ménage particulier serait une *erreur écologique* —
## attribuer à l'individu ce qui n'est vrai que de l'agrégat. C'est le prix
## de toute carte choroplèthe, et la raison pour laquelle la section 4
## descendra au district sanitaire.
##
## ----------------------------------------------------------------------


## ========================================================================
## 2.3 — DES COORDONNÉES GPS AUX POINTS CARTOGRAPHIABLES
## ========================================================================
# Les enquetes geolocalisees livrent la position sous deux formes possibles :
# soit deux colonnes numeriques dans un tableau plat (latitude, longitude),
# soit un shapefile deja spatialise. L'EDS Cameroun offre les deux -- ce qui
# permet de montrer la conversion, puis de la verifier.

# --- 2.3.1 Ce que contient le fichier des grappes ----------------------------

# Controle qualite obligatoire sur des coordonnees d'enquete : le DHS code
# une position manquante par le couple (0, 0) -- un point au large du golfe
# de Guinee, pas un NA. Sans ce filtre, la carte affiche des grappes en mer.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 2.3.2 Refaire la geometrie a partir des colonnes ------------------------
# On repart des attributs comme si l'on n'avait qu'un CSV : c'est le cas le
# plus frequent en pratique.


# Controle : la geometrie reconstruite doit coincider avec celle du shapefile.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## L'ordre c(longitude, latitude) — l'erreur la plus fréquente
##
## st_as_sf() attend coords = c(x, y), donc longitude d'abord. On dit
## pourtant « latitude-longitude » dans la langue courante, et les colonnes
## sont souvent rangées dans cet ordre-là dans les fichiers.
##
## L'inversion ne produit aucune erreur : elle produit des points. Ils
## tombent simplement ailleurs — pour le Cameroun (lat ≈ 4, lon ≈ 12),
## inverser place les grappes vers 12°N 4°E, c'est-à-dire au Niger. Le seul
## garde-fou est de tracer la couche immédiatement après l'avoir créée et de
## vérifier qu'elle tombe sur le pays.
##
## Et crs = 4326 n'est pas décoratif : sans lui, sf a des nombres mais ne
## sait pas ce qu'ils mesurent, et refusera toute jointure spatiale avec une
## autre couche.
##
## ----------------------------------------------------------------------

# --- 2.3.3 Verifier en tracant -----------------------------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ces points ne sont pas exactement là où l'enquête a eu lieu
##
## Le DHS applique un déplacement aléatoire (random displacement) aux
## coordonnées avant diffusion : jusqu'à 2 km en milieu urbain, 5 km en
## milieu rural, et 10 km pour 1 % des grappes rurales tirées au sort. C'est
## une mesure de confidentialité : sans elle, on pourrait remonter au
## village, puis au ménage, puis à la personne interrogée sur sa
## séropositivité.
##
## Trois conséquences opérationnelles, à énoncer avant toute analyse :
##
## - une grappe peut basculer dans le polygone voisin. Sur des districts
## sanitaires qui font souvent moins de 30 km de large, le déplacement est du
## même ordre que l'erreur d'affectation. Les effectifs par district sont
## donc approximatifs, et d'autant plus que le district est petit. - les
## extractions de valeurs raster au point exact sont fragiles. Extraire le
## NDVI « au village » n'a pas de sens à 5 km près ; il faut travailler sur
## un tampon (buffer) au moins aussi large que le déplacement. - c'est
## irréversible. Aucun traitement ne restitue la position vraie.
##
## Ce n'est pas un défaut du fichier : c'est le prix, assumé et documenté, de
## la diffusion de microdonnées géolocalisées. Le savoir change la façon
## d'écrire les conclusions — « la région du Logone » plutôt que « le village
## de X ».
##
## ----------------------------------------------------------------------

# --- 2.3.4 Premiere jointure spatiale : chaque grappe dans sa region ---------
# st_join() n'utilise aucune cle textuelle : il regarde OU tombe le point.
# C'est le second pont entre enquete et territoire, et il ne demande aucune
# table de correspondance.

# Controle croise : la region trouvee geometriquement doit correspondre a la
# region declaree par l'enquete (ADM1NAME) -- aux deux exceptions connues pres.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ce que révèle le contrôle croisé
##
## Le tableau confronte deux réponses à la même question : *dans quelle
## région est cette grappe ?*  L'une vient du questionnaire (ADM1NAME, saisi
## par l'enquêteur), l'autre de la géométrie (NAME_1, calculé par st_within).
##
## Trois cas de figure y apparaissent, et il faut savoir les distinguer :
##
## 1. DOUALA → Littoral et YAOUNDE → Centre — ce n'est pas une erreur, c'est
## la traduction automatique du découpage à 12 vers le découpage à 10. La
## géométrie fait gratuitement ce que la table de correspondance de la
## section 2.2.4 faisait à la main. 2. quelques grappes qui basculent chez le
## voisin — effet du déplacement aléatoire décrit plus haut, surtout près des
## limites régionales. 3. des grappes sans région du tout (NA) — un point
## tombé juste en dehors du polygone, à cause du déplacement ou d'une
## frontière légèrement généralisée dans GADM.
##
## Comparer les deux sources n'est pas une vérification de routine : c'est ce
## qui permet de chiffrer l'incertitude d'affectation avant de publier une
## carte. Un district où 3 grappes sur 4 sont litigieuses ne mérite pas la
## même confiance qu'un district où elles sont toutes franches.
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## MODULE 3 — LA QUALITÉ DES DONNÉES AVANT LA CARTE
## ##########################################################################
## ##########################################################################
# OBJECTIFS DU MODULE
#  - quantifier les valeurs manquantes et, surtout, comprendre POURQUOI elles
#    manquent : toutes les absences ne se traitent pas de la meme facon ;
#  - distinguer le "hors champ" (la question ne se posait pas) de la
#    non-reponse (elle se posait et personne n'a repondu) ;
#  - detecter les incoherences geographiques : geometries invalides, CRS
#    discordants, polygones aberrants, points hors du territoire.
#
# Une carte fausse est plus dangereuse qu'un tableau faux : elle est jolie,
# elle circule, et personne ne relit le code qui l'a produite.


## ========================================================================
## 3.1 — DIAGNOSTIQUER LES VALEURS MANQUANTES
## ========================================================================
# --- 3.1.1 Panorama : quelles variables manquent, et combien ? ---------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 3.1.2 Le cas revactp : 64 % de NA, et pourtant aucun probleme -----------
# Avant d'imputer quoi que ce soit, on croise l'absence avec la variable qui
# conditionne la question. Ici : la situation d'activite.


# Part des NA de revenu expliquee par le fait de ne PAS etre actif occupe

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## « Manquant » ne veut pas dire « perdu »
##
## revactp — le revenu de l'activité principale — est absent pour 6 102
## lignes sur 9 472, soit 64 %. Un réflexe répandu consiste à imputer. Ce
## serait ici une faute.
##
## Le croisement ci-dessus montre que la variable est renseignée pour
## exactement les personnes déclarées actif occupé, et pour elles seules :
## enfants, élèves, retraités, chômeurs et inactifs n'ont pas de revenu
## d'activité principale parce qu'ils n'ont pas d'activité principale. La
## question ne leur a pas été posée. Ce n'est pas une non-réponse, c'est un
## hors champ (skip pattern du questionnaire).
##
## La distinction commande le traitement :
##
## | Nature de l'absence | Ce qu'elle signifie | Traitement |
## | Hors champ | la question ne s'appliquait pas | restreindre la population d'analyse, jamais imputer |
## | Non-réponse | la question s'appliquait, pas de réponse | imputer, ou pondérer pour la non-réponse |
## | Valeur sentinelle | codée 99, -9999, 9998… | recoder en NA avant tout calcul |
##
## Imputer un revenu médian à un enfant de six ans produirait un chiffre : un
## chiffre faux, invisible dans les sorties, et qui ferait ensuite baisser le
## revenu moyen de sa région sur la carte finale. **La carte hérite de toutes
## les décisions prises en amont, sans jamais les afficher.**
##
## Le classement de Rubin (1976) — MCAR, MAR, MNAR — décrit le mécanisme
## statistique de l'absence. Le hors champ, lui, est en amont : ce n'est pas
## un mécanisme aléatoire, c'est la structure du questionnaire.
##
## ----------------------------------------------------------------------

# --- 3.1.3 La bonne facon de traiter revactp : restreindre le champ ----------
# On ne calcule un revenu moyen QUE sur la population concernee, et on le dit.


# Distribution des revenus : l'echelle logarithmique est ici indispensable.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Pourquoi l'échelle logarithmique, et ce qu'elle change
##
## Sur l'axe brut, les revenus vont de quelques milliers à 1 666 667 F CFA.
## Le graphique serait une barre unique collée à gauche et une plage vide sur
## 95 % de la largeur : la distribution est fortement asymétrique à droite
## (right-skewed), quelques valeurs très élevées écrasant tout le reste.
##
## Une échelle logarithmique remplace la distance « +100 000 F CFA » par la
## distance « ×10 ». Chaque pas égal sur l'axe correspond à une
## multiplication, pas à une addition. Deux effets :
##
## - la masse des revenus modestes se déploie et devient lisible ; -
## l'asymétrie se résorbe — la distribution des revenus est approximativement
## log-normale, ce qui est une régularité empirique bien établie.
##
## Conséquence directe pour la suite : quand on résumera le revenu par région
## pour le cartographier, la médiane sera plus honnête que la moyenne. La
## moyenne d'une distribution log-normale est tirée vers le haut par quelques
## très hauts revenus, et une carte de moyennes colorerait en « riche » une
## région où la quasi-totalité des gens sont pauvres mais où résident dix
## cadres supérieurs. Le choix moyenne/médiane n'est pas cosmétique : il
## change la carte.
##
## ----------------------------------------------------------------------

# --- 3.1.4 naniar : visualiser la STRUCTURE des absences ---------------------
# Un taux de NA par variable ne dit pas si les absences vont ENSEMBLE.
# vis_miss() dessine le tableau : une ligne = un individu, une colonne = une
# variable, noir = manquant.
# haven laisse les variables "labelled" : naniar prefere des types simples,
# on convertit donc les modalites en facteurs avant de tracer.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Lire une carte de chaleur des manquants
##
## Chaque colonne est une variable, chaque ligne un individu ; le noir marque
## une absence. Ce qui compte n'est pas la quantité de noir mais sa forme.
##
## - Des bandes noires alignées horizontalement sur plusieurs colonnes
## signalent que les mêmes individus manquent partout : une sous-population
## entière est hors champ. C'est le motif visible ici entre revenu,
## situation_activite et niveau_etude — les enfants. - Du noir dispersé au
## hasard, sans structure verticale ni horizontale, évoque du MCAR : de la
## non-réponse accidentelle, la seule situation où l'imputation simple est
## vraiment inoffensive. - Une colonne entièrement noire est une variable
## vide : ECAM5 en compte deux (s01q12, s01q13, sur le handicap — module non
## administré). Elles ne s'imputent pas, elles se suppriment.
##
## L'intérêt de la figure est de faire apparaître d'un coup d'œil des motifs
## qu'aucune liste de pourcentages ne révèle.
##
## ----------------------------------------------------------------------


## ========================================================================
## 3.2 — IMPUTER : QUAND, COMMENT, ET À QUEL PRIX
## ========================================================================
# --- 3.2.1 Imputation par la mediane du groupe -------------------------------
# Legitime UNIQUEMENT sur une non-reponse, jamais sur un hors champ. On la
# demontre donc sur le bon champ : les actifs occupes dont le revenu serait
# manquant. Comme il n'y en a qu'un seul reellement, on simule une
# non-reponse de 15 % pour rendre l'effet observable.


# Imputation par la mediane du couple (region, milieu) : on impute par le
# groupe le plus proche disponible, pas par la mediane nationale.


# Diagnostic : comparer aux VRAIES valeurs, qu'on connait puisqu'on les a
# effacees nous-memes. C'est le seul cas ou l'on peut noter une imputation.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ce que l'imputation par la médiane coûte réellement
##
## Comparez les deux écarts-types affichés par le bloc précédent : celui des
## valeurs imputées est très inférieur à celui des valeurs réelles. C'est
## mécanique — on a remplacé une distribution par une constante par groupe.
##
## Sur la courbe de densité, cela se voit sous forme de pics artificiels : la
## courbe rouge présente des pointes là où la bleue est lisse. Chaque pointe
## est une médiane de groupe, répétée des dizaines de fois.
##
## Ce que cela implique :
##
## - la moyenne est à peu près préservée — c'est ce que l'imputation par un
## centre garantit ; - la variance est sous-estimée, donc les intervalles de
## confiance sont trop étroits et les tests trop faciles à passer. On croit
## savoir plus précisément qu'on ne sait ; - les corrélations sont diluées :
## les valeurs imputées n'ont, par construction, aucun lien avec les autres
## variables de l'individu.
##
## Les méthodes qui préservent la variance existent — imputation par tirage
## dans le groupe (hot deck), par les k plus proches voisins (VIM::kNN()),
## imputation multiple (mice). Elles sont plus coûteuses et supposent toutes
## que l'absence est bien une non-réponse. La règle qui prime sur toutes les
## autres reste : **documenter ce qui a été imputé, et publier le taux
## d'imputation à côté du résultat.**
##
## ----------------------------------------------------------------------


## ========================================================================
## 3.3 — LES INCOHÉRENCES PROPREMENT GÉOGRAPHIQUES
## ========================================================================
# --- 3.3.1 Validite des geometries -------------------------------------------
# Une geometrie "invalide" au sens OGC : contour qui se recoupe, anneau mal
# oriente, sommets dupliques. La lecture ne signale rien ; la premiere
# intersection echoue.

# Rappel : ds_sante a deja ete repare par st_make_valid() a la lecture.
# Sans cette reparation, 135 des 200 districts etaient invalides.

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 3.3.2 Concordance des systemes de coordonnees ---------------------------

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 3.3.3 Mesurer exige de reprojeter ---------------------------------------
# EPSG:4326 est en DEGRES. Un degre de longitude ne vaut pas la meme distance
# a l'equateur et a 12 degres nord : toute superficie calculee dessus est
# fausse. On projette en UTM zone 33N (EPSG:32633), en METRES.


# Les extremes : utiles pour reperer un polygone aberrant (ilot orphelin,
# fragment issu d'une numerisation).

# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 3.3.4 Des points hors du territoire -------------------------------------
# Consequence directe du deplacement aleatoire du DHS : une grappe cotiere ou
# frontaliere peut se retrouver hors des limites du pays.


# On NE SUPPRIME PAS ces grappes : elles portent de vrais menages enquetes.
# On les MARQUE, et le module 4 les rattachera au polygone le plus proche
# (st_nearest_feature) plutot que de les laisser sans affectation.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Supprimer ou recaler ? Une décision qui se justifie
##
## Trois options se présentent devant un point qui tombe hors du polygone :
##
## 1. le supprimer — simple, mais on jette des ménages réellement enquêtés,
## et l'on introduit un biais : ces grappes sont majoritairement côtières ou
## frontalières, donc pas un échantillon aléatoire du pays ; 2. le recaler
## sur l'unité la plus proche (st_nearest_feature) — on conserve
## l'information, au prix d'une affectation approximative ; 3. le garder tel
## quel, avec une affectation NA — le plus honnête si l'on ne travaille qu'au
## niveau national.
##
## L'option 2 est retenue ici parce que le décalage est connu et borné : il
## vient du déplacement DHS, plafonné à 5 km. Recaler sur le polygone le plus
## proche revient à annuler un déplacement dont on connaît l'origine. La
## colonne recale garde la trace de chaque cas : quelle que soit l'option
## choisie, c'est le fait de pouvoir la retrouver plus tard qui compte.
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## MODULE 4 — JOINTURES SPATIALES ET AGRÉGATION TERRITORIALE
## ##########################################################################
## ##########################################################################
# OBJECTIFS DU MODULE
#  - choisir le bon predicat spatial (st_within, st_intersects,
#    st_nearest_feature) selon la question posee ;
#  - descendre les indicateurs d'enquete du menage a la grappe, puis de la
#    grappe au district sanitaire, en ponderant a chaque etape ;
#  - cartographier le resultat et savoir de quoi la couleur est faite.


## ========================================================================
## 4.1 — CHOISIR LE PRÉDICAT SPATIAL
## ========================================================================
# Une jointure spatiale ne compare aucune chaine de caracteres : elle teste
# une RELATION GEOMETRIQUE entre deux couches.
#
#   st_within(x, y)           x est entierement DANS y   points -> polygones
#   st_intersects(x, y)       x touche ou recoupe y      polygones qui se chevauchent
#   st_contains(x, y)         x contient y               l'inverse de within
#   st_nearest_feature(x, y)  y le plus proche de x      rattrapage des cas limites
#   st_is_within_distance()   y a moins de d de x        zones d'influence
#
# Regle de lecture : st_join(x, y) renvoie TOUJOURS un objet ayant la
# geometrie de x, enrichi des attributs de y. On part donc de ce qu'on veut
# garder.

# PREALABLE ABSOLU : le meme CRS des deux cotes, sinon sf refuse (ou pire,
# accepte et donne n'importe quoi si les CRS sont absents).


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 4.1.1 Rattacher chaque grappe a son district sanitaire ------------------

# PIEGE : si deux polygones se recouvrent, le point apparait DEUX fois et le
# tableau grossit sans prevenir. On verifie, puis on ne garde qu'une ligne
# par grappe -- l'ordre d'origine est conserve.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 4.1.2 Rattraper les cas limites : le district LE PLUS PROCHE ------------
# Une grappe non rattachee n'est pas une donnee invalide : c'est un point
# tombe dans un interstice de la couche (limites generalisees) ou hors du
# pays (deplacement DHS). st_nearest_feature lui donne son plus proche voisin.

  # La DISTANCE au district rattrape se mesure en metres : on reprojette.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## 430 grappes pour 200 districts : ce que cela impose
##
## Le décompte ci-dessus est la contrainte majeure de la journée. L'EDS 2018
## a été échantillonnée pour être représentative au niveau régional, pas au
## niveau du district sanitaire. Résultat : une bonne moitié des districts ne
## contient aucune grappe, et parmi ceux qui en contiennent, beaucoup n'en
## ont qu'une ou deux.
##
## Un taux d'accès à l'eau calculé sur une seule grappe (≈ 25 ménages) a un
## intervalle de confiance de l'ordre de ±20 points. La carte, elle,
## affichera une couleur franche, aussi affirmative que celle d'un district
## reposant sur huit grappes.
##
## C'est le piège le plus courant de la cartographie d'enquête : **la carte
## ne transporte pas l'incertitude**. Les parades, dans l'ordre de préférence
## :
##
## 1. agréger à un niveau où l'échantillon est représentatif — ici la région
## ; 2. afficher l'effectif à côté de la valeur (nombre de grappes en
## étiquette, ou épaisseur du contour) ; 3. masquer les unités sous un seuil
## — ne pas colorer un district à moins de trois grappes ; 4. passer à
## l'estimation sur petits domaines (small area estimation), qui emprunte de
## l'information aux unités voisines. C'est le sujet du J07.
##
## La section 4.3 applique les parades 2 et 3.
##
## ----------------------------------------------------------------------


## ========================================================================
## 4.2 — AGRÉGER : DU MÉNAGE À LA GRAPPE, DE LA GRAPPE AU DISTRICT
## ========================================================================
# --- 4.2.1 Construire les indicateurs au niveau MENAGE -----------------------
# On part des codes standard du recode menage EDS. Ils sont documentes dans
# le "Recode Manual" du programme DHS -- on ne les invente pas.
#
# Avant de recoder, on REGARDE ce que le fichier contient reellement.

# Definition JMP (OMS/UNICEF) d'une source AMELIOREE : reseau, borne-fontaine,
# forage, puits ou source protegee, eau de pluie, eau en bouteille.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 4.2.2 Premier niveau d'agregation : la GRAPPE ---------------------------
# La grappe est la plus petite unite geolocalisee disponible. Toute la chaine
# spatiale passe par elle.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 4.2.3 Coller les indicateurs sur les points -----------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 4.2.4 Second niveau : le DISTRICT SANITAIRE -----------------------------
# On repondere par le poids total de chaque grappe : une grappe de 30 menages
# representatifs de 40 000 personnes ne pese pas comme une grappe de 20.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 4.2.5 Recoller a la couche geographique --------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Pourquoi pondérer à chaque étage
##
## Trois pondérations différentes interviennent dans la chaîne ci-dessus, et
## les confondre fausse le résultat :
##
## - du ménage à la grappe : hv005 / 10⁶, le poids d'échantillonnage DHS. Il
## corrige le plan de sondage — certaines strates sont surreprésentées à
## dessein, pour obtenir assez d'observations dans les régions peu peuplées.
## - de la grappe au district : la somme des poids de la grappe. Sans elle,
## une grappe de 20 ménages pèserait autant qu'une grappe de 32. - du
## district à un total national : il faudrait la population du district, pas
## le nombre de ménages enquêtés.
##
## La règle générale : la moyenne d'une moyenne n'est pas la moyenne. Une
## moyenne non pondérée de moyennes de grappes donne à chaque grappe le même
## poids, quel que soit le nombre de personnes derrière. Sur des données
## d'enquête à plan de sondage complexe, l'écart entre les deux calculs
## atteint couramment plusieurs points de pourcentage — assez pour inverser
## le classement de deux régions.
##
## ----------------------------------------------------------------------


## ========================================================================
## 4.3 — CARTOGRAPHIER CE QUI A ÉTÉ AGRÉGÉ
## ========================================================================
# --- Carte 1 : acces a l'eau amelioree, avec le non-mesure assume -----------
# Choix explicites :
#  - les districts sans grappe restent GRIS, ils ne sont pas "a zero" ;
#  - les districts a moins de 3 grappes sont soulignes en pointille ;
#  - la discretisation est en quantiles : ici la distribution est etalee,
#    on cherche a comparer des rangs plutot qu'a isoler des decrochements.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Lire la carte de l'eau : trois couches d'information, trois précautions
##
## Ce que la couleur code. Le pourcentage pondéré de ménages dont la source
## principale d'eau de boisson est améliorée au sens du JMP (OMS/UNICEF) :
## réseau, borne-fontaine, forage, puits ou source protégée, eau de pluie,
## eau en bouteille. « Améliorée » qualifie la **protection de la source
## contre la contamination extérieure** — pas la potabilité de l'eau au
## robinet, ni la distance à parcourir, ni la régularité du service. Un
## forage à 40 minutes de marche compte comme amélioré.
##
## Ce que la discrétisation fait. style = "quantile" place le même nombre de
## districts dans chaque classe. Avantage : toutes les couleurs sont
## utilisées, la carte est contrastée et les rangs se lisent bien. Prix à
## payer : elle fabrique du contraste — deux districts séparés par un point
## de pourcentage peuvent tomber dans deux classes différentes si la coupure
## passe entre eux. La comparer à la carte en seuils naturels de la section
## 2.2 est un exercice utile : mêmes données, deux récits.
##
## Ce que le gris et le pointillé disent. Le gris n'est pas un zéro, c'est
## une absence de mesure — la moitié des districts sanitaires n'a pas été
## enquêtée. Le pointillé signale les districts reposant sur une ou deux
## grappes, où la couleur est une estimation fragile. Une carte qui
## masquerait ces deux nuances serait plus belle et moins vraie.
##
## Ce que l'espace apporte ici. Deux structures apparaissent, qu'aucun
## tableau ne donne :
##
## - un gradient nord-sud cohérent avec la carte de pauvreté de la section
## 2.2, mais pas superposable : certains districts du Grand Nord affichent un
## bon accès à l'eau grâce aux programmes de forages, tout en restant très
## pauvres. L'écart entre les deux cartes est plus informatif que chacune
## isolément — il indique où l'investissement en eau a déjà eu lieu ; - un
## effet urbain ponctuel : les districts de Douala et Yaoundé ressortent en
## îlots, discontinus du reste. L'accès à l'eau n'est pas qu'un gradient
## géographique, c'est aussi un fait d'infrastructure de réseau.
##
## Ce qu'elle ne dit pas. Rien sur la qualité bactériologique, rien sur le
## temps d'accès, rien sur l'intérieur des districts — un district côtier
## peut mêler une ville branchée au réseau et des villages riverains sans
## rien. La maille lisse ce qu'elle agrège.
##
## ----------------------------------------------------------------------

# --- Carte 2 : trois indicateurs cote a cote --------------------------------
# tmap_arrange met les cartes sur la meme page ; chacune garde SA propre
# echelle, ce qui interdit de comparer les couleurs d'une carte a l'autre --
# on compare des GEOGRAPHIES, pas des niveaux.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Comparer trois cartes : ce qu'on cherche vraiment
##
## Trois indicateurs, trois échelles indépendantes. On ne compare donc **pas
## les intensités** — un bleu foncé et un rouge foncé ne valent pas le même
## pourcentage. Ce qu'on compare, ce sont les formes.
##
## - Eau et électricité se ressemblent partiellement : deux réseaux, deux
## logiques d'investissement public, mais l'eau a bénéficié de programmes de
## forages ruraux que l'électricité n'a pas connus. Là où les deux cartes
## divergent, c'est qu'une politique sectorielle est passée. - La défécation
## à l'air libre dessine autre chose : elle ne suit pas le réseau, elle suit
## la densité et l'habitat. C'est un indicateur de comportement et de
## foncier, pas d'infrastructure — d'où sa géographie plus concentrée. -
## Aucune des trois n'est le simple négatif d'une autre. Si elles l'étaient,
## un seul indicateur suffirait. Leur non-superposition est exactement
## l'information utile pour un arbitrage budgétaire : elle indique qu'on ne
## peut pas traiter les trois problèmes au même endroit avec le même levier.
##
## Cette lecture — chercher les écarts entre cartes plutôt que la valeur de
## chacune — est le geste analytique central de la cartographie thématique
## comparée.
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## MODULE 5 — LE PIPELINE COMPLET, DE LA DONNÉE BRUTE À LA DÉCISION
## ##########################################################################
## ##########################################################################
# OBJECTIFS DU MODULE
#  - assembler en une seule chaine tout ce qui precede ;
#  - enrichir les grappes de variables de CONTEXTE deja extraites de rasters ;
#  - croiser deux enquetes independantes au niveau regional ;
#  - produire les livrables : tableau, couche geographique, cartes.


## ========================================================================
## 5.1 — ENRICHIR LES GRAPPES PAR LEUR CONTEXTE GÉOGRAPHIQUE
## ========================================================================
# CMGC72FL.csv contient, pour chacune des 430 grappes, 130 variables de
# contexte DEJA EXTRAITES de rasters par le programme DHS : pluviometrie,
# aridite, temperature, vegetation, prevalence du paludisme, lumiere nocturne,
# temps de trajet vers la ville la plus proche...
#
# C'est exactement le resultat de l'operation vue au J04 (extraction zonale),
# livree toute faite. On evite ainsi de manipuler 90 Mo d'images pour
# retrouver ce que le DHS a deja calcule proprement.


# PIEGE DES SENTINELLES. L'absence de mesure n'est pas codee NA mais par des
# valeurs negatives (-9999 et quelques autres). Elles passeraient inapercues
# dans un mean() et tireraient toute la moyenne vers l'abime.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- Table maitresse : une ligne par grappe, tout ce qu'on sait d'elle -------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ========================================================================
## 5.2 — CROISER : L'ESPACE COMME VARIABLE EXPLICATIVE
## ========================================================================
# --- 5.2.1 L'eloignement explique-t-il l'acces a l'eau ? --------------------
# temps_trajet mesure le temps de parcours, en minutes, jusqu'a la ville de
# plus de 50 000 habitants la plus proche. C'est une mesure d'ACCESSIBILITE,
# et non de distance a vol d'oiseau : elle integre le reseau routier.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Décoder ce nuage de points
##
## Chaque point est une grappe — environ 25 ménages enquêtés au même endroit.
## L'axe vertical est le pourcentage de ces ménages ayant une source d'eau
## améliorée ; l'axe horizontal, le temps de trajet vers la ville la plus
## proche.
##
## Pourquoi +1 et une échelle log. Le temps de trajet va de 0 à 836 minutes,
## avec un quart des grappes à moins de 15 secondes (elles sont en ville). Le
## logarithme de 0 n'existant pas, on décale de 1 avant de passer en log.
## L'échelle log étale la masse des grappes proches et comprime la queue des
## très isolées : sans elle, 75 % des points seraient collés à gauche.
##
## La courbe grise est un lissage LOESS (*locally estimated scatterplot
## smoothing*) : une régression locale, ajustée par petits voisinages
## glissants le long de l'axe horizontal. Contrairement à une droite, elle
## n'impose aucune forme a priori — elle suit ce que les données font, y
## compris si la relation change de sens. La bande grise autour est
## l'intervalle de confiance à 95 % : là où elle s'élargit, c'est qu'il y a
## peu de points, et la courbe n'y signifie plus grand-chose.
##
## Le rho de Spearman mesure la corrélation des rangs, pas des valeurs. On le
## préfère ici au coefficient de Pearson parce que la relation n'a aucune
## raison d'être linéaire et que les deux variables sont très asymétriques.
## Spearman répond à « quand l'une monte, l'autre descend-elle ? », sans
## supposer comment.
##
## Ce qui se lit. La pente est nettement négative : plus une grappe est
## éloignée d'une ville, moins ses ménages ont accès à une source améliorée.
## La séparation par couleur montre que ce n'est pas un simple effet
## urbain/rural — à l'intérieur même du monde rural, les points verts
## s'échelonnent, et l'éloignement continue d'ordonner l'accès. C'est
## l'apport propre de la variable spatiale : elle gradue ce qu'une variable
## binaire urbain/rural se contente de dichotomiser.
##
## Ce qui ne se lit pas. Aucune causalité. Le temps de trajet est corrélé à
## presque tout — richesse, densité, présence de l'État, réseau électrique.
## Il capte l'ensemble de ces phénomènes plutôt qu'il ne les distingue. Et la
## dispersion verticale reste large : à 100 minutes de la ville, on trouve
## des grappes à 20 % comme à 90 % d'accès. **L'éloignement ordonne une
## tendance ; il ne détermine aucune grappe en particulier.**
##
## ----------------------------------------------------------------------

# --- 5.2.2 Croiser DEUX enquetes independantes ------------------------------
# ECAM5 (INS, 2021-2022) et EDS-MICS (DHS, 2018) n'ont ni le meme
# echantillon, ni le meme questionnaire, ni la meme annee. Le seul niveau ou
# on peut honnetement les rapprocher est la region -- et encore faut-il les
# ramener au meme decoupage.
# L'EDS ecrit ses regions en majuscules non accentuees ("EXTREME-NORD"),
# ECAM5 en minuscules accentuees ("extrême-nord"). On reutilise la fonction
# normaliser() de la section 2.2 : c'est exactement le meme probleme.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## Ce que vaut — et ne vaut pas — ce rapprochement
##
## La construction. Chaque point est une région administrative. Son abscisse
## vient d'ECAM5 (INS, 2021-2022), son ordonnée de l'EDS-MICS (DHS, 2018). La
## taille du point rappelle l'effectif ECAM5 : un gros point est un chiffre
## plus solide.
##
## La droite en pointillé est une régression linéaire simple, avec son
## intervalle de confiance. Sur dix points, elle est indicative, pas
## démonstrative — un seul point extrême suffirait à la faire pivoter.
##
## La lecture. L'alignement général est négatif, comme attendu : les régions
## les plus pauvres ont le moins accès à l'eau améliorée. Ce qui intéresse
## l'analyste n'est pourtant pas la droite, ce sont les résidus — les régions
## qui s'en écartent :
##
## - une région au-dessus de la droite fait mieux que ne le laisserait
## prévoir son niveau de pauvreté : quelque chose y a fonctionné, programme
## de forages, hydraulique villageoise, densité qui rentabilise un réseau ; -
## une région en dessous fait moins bien : à niveau de pauvreté comparable,
## ses ménages sont moins bien servis. C'est là que se situe le gisement
## d'action publique.
##
## Les réserves, qui sont sérieuses. Quatre ans séparent les deux enquêtes,
## sur une période où le réseau a évolué. Les échantillons sont indépendants,
## donc les deux chiffres d'une même région comportent chacun leur aléa
## d'échantillonnage. Enfin, l'agrégation de 12 régions d'enquête vers 10
## régions administratives dilue Douala dans le Littoral et Yaoundé dans le
## Centre — deux régions dont le profil urbain tire mécaniquement les
## moyennes vers le haut.
##
## Ce graphique sert donc à **formuler une hypothèse et repérer des cas à
## examiner**, pas à conclure. C'est un usage parfaitement légitime, à
## condition de l'annoncer.
##
## ----------------------------------------------------------------------


## ========================================================================
## 5.3 — LES LIVRABLES
## ========================================================================
# --- 5.3.1 Le tableau de synthese -------------------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 5.3.2 La couche geographique ------------------------------------------
# Le GeoPackage (.gpkg) est preferable au shapefile : un seul fichier, pas de
# limite a 10 caracteres sur les noms de colonnes, pas de sidecars a perdre,
# encodage UTF-8 garanti.


# Meme chose pour les regions, avec les indicateurs des deux enquetes.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

# --- 5.3.3 La carte de synthese ---------------------------------------------
# Trois niveaux d'information superposes, du plus general au plus fin :
#   fond    : la pauvrete regionale (ECAM5) -- le contexte ;
#   points  : les grappes EDS, taille = nombre de menages, couleur = acces
#             a l'eau -- la mesure locale ;
#   limites : regions et pays voisins -- le repere.


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................

## ----------------------------------------------------------------------
## La carte de synthèse : pourquoi superposer deux échelles
##
## Cette carte fait délibérément ce que les précédentes évitaient : elle
## place sur le même fond une information agrégée (le fond régional) et une
## information ponctuelle (les grappes). Les deux ne se lisent pas de la même
## manière, et c'est justement l'intérêt.
##
## Le fond raconte la structure : trois régions du Nord et l'Est en teinte
## chaude, le Sud et les métropoles en teinte claire. Une couleur = une
## moyenne sur des centaines de milliers de personnes.
##
## Les points racontent la dispersion à l'intérieur de cette structure. Là où
## le fond est uniforme, les points ne le sont pas : on trouve des grappes
## bien desservies au cœur de régions pauvres, et l'inverse. **La
## superposition est ce qui rend l'hétérogénéité intra-régionale visible**,
## et elle constitue la meilleure protection contre l'erreur écologique
## évoquée en 2.2 — on voit, sur la même image, que la couleur du fond ne
## s'applique pas à chaque point qu'elle contient.
##
## Trois précautions de lecture, à énoncer en légende de toute carte de ce
## type :
##
## - les deux sources ont des dates différentes (2018 et 2022) ; - les points
## sont déplacés jusqu'à 5 km — leur position est indicative ; - l'absence de
## point ne signifie pas l'absence de population, mais l'absence d'enquête.
## Le vide du Nord-Ouest et du Sud-Ouest reflète les conditions de collecte
## de 2018, pas un désert humain.
##
## Pourquoi le spatial est ici indispensable et non décoratif. Les mêmes
## chiffres en tableau donneraient les mêmes moyennes régionales et les mêmes
## pourcentages par grappe. Ce que seule la carte fournit, c'est le voisinage
## — la continuité du bloc septentrional, la discontinuité des îlots urbains,
## les trous d'échantillonnage. Or c'est le voisinage qui oriente la décision
## : on n'implante pas un programme sur une liste triée, on l'implante sur un
## territoire, avec des routes, des frontières et des voisins.
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## EXERCICES DE LA JOURNÉE
## ##########################################################################
## ##########################################################################
## ----------------------------------------------------------------------
## Exercice 1 (20 min) — Le taux de pauvreté urbain/rural par région
##
## À partir d'ecam5, calculez le taux de pauvreté pondéré pour chaque couple
## région × milieu. Triez par région puis par taux décroissant, et
## représentez le résultat en barres groupées avec ggplot2.
##
## Piège à éviter : Douala et Yaoundé n'ont pas de milieu rural. Que fait
## votre code de ces cellules vides, et que doit afficher le graphique ?
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Exercice 2 (20 min) — Densité de population par département
##
## Joignez pop_adm2 à cmr_l2 (section 2.2), calculez la superficie de chaque
## département en UTM 33N, puis la densité en habitants/km². Cartographiez-la
## avec une discrétisation en seuils naturels.
##
## Question : pourquoi la superficie doit-elle être calculée après
## reprojection, et de combien vous trompez-vous si vous l'oubliez ?
## (Comparez.)
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Exercice 3 (20 min) — Le mécanisme des valeurs manquantes
##
## Dans ecam5, la variable s01q5 (statut matrimonial) compte 2 981 NA.
## Croisez cette absence avec l'âge (s01q4). S'agit-il d'un hors champ ou
## d'une non-réponse ? Justifiez, puis dites si vous imputeriez — et par
## quoi.
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Exercice 4 (25 min) — Changer de maille
##
## Reprenez le pipeline de la section 4.2 en agrégeant les grappes par
## département GADM au lieu du district sanitaire. Comparez les deux cartes.
## Combien de départements sont documentés, contre combien de districts ? Que
## devient l'écart entre le minimum et le maximum ?
##
## C'est une illustration directe du MAUP : la même donnée, deux mailles,
## deux messages.
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Exercice final (40 min) — Une carte défendable
##
## Produisez une carte thématique combinant au moins deux sources parmi
## ECAM5, EDS, WorldPop et les covariables contextuelles. Elle doit comporter
## un titre, une légende, une échelle, une orientation et les sources.
##
## Puis rédigez cinq lignes répondant à : **que montre cette carte, que ne
## montre-t-elle pas, et quelle décision permettrait-elle d'éclairer ?**
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## ANNEXE A — GLOSSAIRE DES TERMES DE LA JOURNÉE
## ##########################################################################
## ##########################################################################
## ----------------------------------------------------------------------
## Statistique d'enquête
##
## Poids de sondage (coefextr, hv005) — nombre d'individus de la population
## que représente une ligne du fichier. Sans lui, on décrit l'échantillon,
## pas le pays. hv005 du DHS se divise par 10⁶.
##
## Plan de sondage complexe — tirage à plusieurs degrés (grappes, puis
## ménages) avec stratification. Il rend les erreurs-types classiques trop
## optimistes.
##
## Grappe (cluster) — unité primaire de tirage : un village ou un quartier où
## l'on enquête ~25 ménages. C'est la plus petite unité géolocalisée d'une
## EDS.
##
## Hors champ (skip pattern) — absence due au fait que la question n'était
## pas posée à cette personne. Ne s'impute pas.
##
## MCAR / MAR / MNAR (Rubin, 1976) — mécanismes d'absence : complètement
## aléatoire, aléatoire conditionnellement à des variables observées, non
## aléatoire. Seul le premier autorise l'imputation simple sans biais.
##
## Valeur sentinelle — code numérique signifiant « pas de mesure » (-9999,
## 99, 9998). Invisible pour is.na() : à recoder avant tout calcul.
##
## Déplacement aléatoire (random displacement) — décalage volontaire des
## coordonnées DHS (2 km urbain, 5 km rural, 10 km pour 1 % des grappes
## rurales) pour protéger l'anonymat.
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Vocabulaire spatial
##
## CRS (Coordinate Reference System) — système qui donne un sens aux nombres
## de coordonnées. EPSG:4326 (WGS84) est en degrés : bon pour afficher, faux
## pour mesurer. EPSG:32633 (UTM zone 33N) est en mètres : bon pour mesurer,
## déformant loin de son méridien central.
##
## Projection — passage de la sphère au plan. Toute projection déforme au
## moins une chose parmi surface, angle et distance.
##
## Géométrie valide — au sens OGC : contour qui ne se recoupe pas, anneaux
## correctement orientés. st_is_valid() teste, st_make_valid() répare.
##
## s2 / GEOS — les deux moteurs géométriques de sf. s2 calcule sur la sphère
## (exact, exigeant) ; GEOS sur le plan (tolérant). sf_use_s2(FALSE) bascule
## vers GEOS.
##
## Jointure attributaire — relier deux tables par une clé commune
## (left_join). Jointure spatiale — les relier par leur position (st_join),
## sans clé.
##
## Prédicat spatial — la relation testée : st_within (dedans), st_intersects
## (croise), st_contains (contient), st_nearest_feature (le plus proche).
##
## Centroïde — point moyen d'un polygone. Il peut tomber hors du polygone si
## celui-ci est concave ou en croissant.
##
## Tampon (buffer) — zone à distance constante d'un objet. Se calcule en
## mètres, donc après reprojection.
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Cartographie
##
## Choroplèthe — carte où chaque unité est colorée selon la valeur d'un
## indicateur. Suppose un indicateur relatif (taux, densité) : colorer un
## effectif brut ne fait que dessiner la taille des unités.
##
## Discrétisation — règle de découpage des valeurs en classes. quantile (même
## effectif par classe, contraste maximal, peut exagérer), jenks / seuils
## naturels (coupe aux décrochements, respecte la distribution), equal
## (largeurs égales, fidèle aux écarts, peut laisser des classes vides),
## pretty (bornes rondes, lisible).
##
## Palette séquentielle / divergente / qualitative — pour un ordre croissant,
## pour un écart de part et d'autre d'un seuil, pour des catégories sans
## ordre. Se tromper de famille rend la carte illisible.
##
## MAUP (Modifiable Areal Unit Problem) — les résultats dépendent de la
## maille d'agrégation choisie. Il n'existe pas de maille neutre.
##
## Erreur écologique — attribuer à un individu ce qui n'est vrai que de
## l'agrégat auquel il appartient. Risque permanent de la choroplèthe.
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Statistique et graphique
##
## Échelle logarithmique — un pas égal = une multiplication. Rend lisible une
## distribution asymétrique, et linéarise les relations multiplicatives.
##
## LOESS — lissage par régressions locales successives. N'impose aucune forme
## a priori ; la bande grise est son intervalle de confiance à 95 %.
##
## Spearman vs Pearson — Spearman corrèle les rangs (robuste, ne suppose pas
## la linéarité) ; Pearson corrèle les valeurs (suppose une relation linéaire
## et des queues raisonnables).
##
## Résidu — écart d'un point à la droite ajustée. En analyse territoriale,
## c'est souvent l'information la plus intéressante : elle désigne les unités
## qui font mieux ou moins bien que « prévu ».
##
## ----------------------------------------------------------------------


## ##########################################################################
## ##########################################################################
## ANNEXE B — FONCTIONS CLÉS DU J05
## ##########################################################################
## ##########################################################################
## ----------------------------------------------------------------------
## Manipulation de données
##
## | Fonction | Package | Rôle |
## | read_dta() / read_sav() | haven | lire Stata / SPSS avec les étiquettes |
## | col_select = | haven | ne lire que les colonnes utiles d'un gros fichier |
## | as_factor() | haven | transformer les codes en modalités lisibles |
## | read_delim(delim = ";") | readr | lire un CSV à séparateur non standard |
## | filter(), select(), mutate() | dplyr | les verbes de base |
## | group_by() + summarise() | dplyr | statistiques par groupe |
## | weighted.mean() | base | moyenne pondérée — indispensable en enquête |
## | left_join() | dplyr | jointure attributaire |
## | pivot_longer() / pivot_wider() | tidyr | long ↔ large |
## | separate() / unite() | tidyr | décomposer / composer une clé |
## | vis_miss() | naniar | carte de chaleur des valeurs manquantes |
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Manipulation spatiale et carte
##
## | Fonction | Rôle |
## | st_read() / st_write() | lire / écrire une couche (.shp, .geojson, .gpkg) |
## | st_as_sf(coords = c("lon", "lat"), crs = 4326) | fabriquer des points depuis deux colonnes |
## | st_crs() / st_transform() | lire / changer le système de coordonnées |
## | st_drop_geometry() | revenir à un tableau ordinaire |
## | st_is_valid() / st_make_valid() | diagnostiquer / réparer les géométries |
## | st_join(x, y, join = st_within) | jointure spatiale points → polygones |
## | st_nearest_feature() | rattraper les cas non appariés |
## | st_area() / st_distance() | mesurer — après reprojection en mètres |
## | st_union() | fusionner en une seule géométrie |
## | tm_shape() + tm_polygons(fill = …) | couche + habillage (tmap 4) |
## | tm_scale_intervals(style = …) | choix de la discrétisation |
## | tm_dots(), tm_borders() | points, contours |
## | tm_title(), tm_scalebar(), tm_compass(), tm_credits() | habillage obligatoire |
## | tmap_arrange() / tmap_save() | composer / exporter |
##
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## Pour aller plus loin
##
## - Geocomputation with R, Lovelace, Nowosad & Muenchow —
## <https://r.geocompx.org/> - Spatial Data Science, Pebesma & Bivand —
## <https://r-spatial.org/book/> - Documentation sf —
## <https://r-spatial.github.io/sf/> - Documentation tmap v4 —
## <https://r-tmap.github.io/tmap/> - DHS Program, Recode Manual et GPS Data
## Collection — <https://dhsprogram.com/> - Institut National de la
## Statistique du Cameroun — <https://ins-cameroun.cm/> - GADM 4.1 —
## <https://gadm.org/>
##
## ----------------------------------------------------------------------

# --- Bilan d'execution de la journee ----------------------------------------


# ......................................................................
# >>> A COMPLETER  (corrige : script_etudiant_J05_corrige.R)
# ......................................................................