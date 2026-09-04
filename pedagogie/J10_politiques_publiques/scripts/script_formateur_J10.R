## ============================================================================
## PROGRAMME DE FORMATION R -- DONNEES SPATIALES, ANALYSE ET MANIPULATION DANS R
## J10 -- LES DONNEES SPATIALES AU SERVICE DES POLITIQUES PUBLIQUES
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Jeudi 6 aout 2026
## Referents : E. Darin, M. Teda, R. Dzita
##
## CE FICHIER EST LE MIROIR DE demo_formateur_J10.qmd : meme code, meme ordre,
## memes commentaires. Toute correction faite ici doit l'etre aussi dans le
## .qmd, et inversement -- le .qmd est la SOURCE UNIQUE.
##
## Donnees : datasets/ (chemins relatifs). Sorties : outputs/.
## Prealable, une fois : source("install_packages_day.R")
##
## AVERTISSEMENT : cette journee change de pays en cours de route. Parties I et
## II sur le Cameroun (ACLED, ERA5), partie III sur le BENIN (EHCVM 2018-2019).
## La raison est ecrite en tete du Module 5.
## ============================================================================

## --- Se placer dans le dossier de la journee --------------------------------
## Tous les chemins de ce script sont relatifs a CE dossier. Quarto s'y place
## automatiquement au rendu ; Rscript, non. On le fait donc explicitement, que
## le script soit lance depuis le dossier du jour, depuis pedagogie/ ou depuis
## la racine du projet. Ce script vit dans scripts/ : on remonte d'un cran.
.dossier_jour <- "J10_politiques_publiques"
if (!dir.exists("datasets")) {
  for (.p in c("..", .dossier_jour, file.path("pedagogie", .dossier_jour))) {
    if (dir.exists(file.path(.p, "datasets"))) { setwd(.p); break }
  }
}
if (!dir.exists("datasets"))
  stop("Dossier datasets/ introuvable. Ouvrez atelier-r-spatial-iford-2026.Rproj, ",
       "lancez source('outils/distribuer_donnees.R'), puis relancez ce script.")
cat("Dossier de travail :", getwd(), "\n")

for (d in c("outputs"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)


## ##########################################################################
## MODULE 0 — LE DOSSIER, LES PACKAGES, L'INVENTAIRE
## ##########################################################################

## ========================================================================
## 0.1 — L'ARBORESCENCE DE LA JOURNEE
## ========================================================================
# Ce script ne connait qu'un seul repertoire de donnees : "datasets/", a plat,
# a la racine du dossier de la journee. Aucun appel a un localisateur de projet,
# aucune variable de repertoire recomposee, aucun sous-dossier : c'est cette
# convention, et elle seule, que l'outil de distribution des donnees detecte par
# expression reguliere pour remplir datasets/.
cat(paste(
  "",
  "J10_politiques_publiques/",
  "|-- demo_formateur_J10.qmd            <- source unique du materiel",
  "|-- install_packages_day.R            <- packages de la journee (une fois)",
  "|-- README.md",
  "|-- datasets/                         <- donnees, a PLAT",
  "|   |-- acled_cameroon_export.csv     <- evenements ACLED, Cameroun (Modules 1-2)",
  "|   |-- gadm41_CMR.gpkg               <- limites administratives Cameroun, GADM 4.1",
  "|   |-- era5_t2m_mensuel_cameroun.nc  <- ERA5 T2m mensuel, Kelvin (Modules 3-4)",
  "|   |-- ehcvm2018_benin_menages.csv   <- menages geolocalises EHCVM 2018-2019 (Module 5)",
  "|   |-- gadm_ben_communes.gpkg        <- communes du Benin, admin2 (Module 8)",
  "|   |-- benin_grille_3km.gpkg         <- grille de 3 km (Module 9)",
  "|   |-- benin_covariables_admin2.csv  <- covariables par commune (Modules 6-7)",
  "|   |-- benin_covariables_grille.csv  <- covariables par cellule (Modules 5 et 9)",
  "|   `-- LISEZMOI.md                   <- inventaire verifie et pieges chiffres",
  "|-- scripts/",
  "|   |-- script_formateur_J10.R        <- CE fichier",
  "|   |-- script_etudiant_J10.R         <- trame a trous",
  "|   `-- script_etudiant_J10_corrige.R <- corrige, distribue en fin de journee",
  "|-- archive_en/                       <- scripts EN d'origine, archives, non maintenus",
  "`-- outputs/                          <- TOUTES les sorties (cree automatiquement)",
  "",
  sep = "\n"
))

## ----------------------------------------------------------------------
## UNE SORTIE N'ECRIT JAMAIS DANS datasets/
##
## datasets/ est en lecture seule par convention : il contient ce qui a ete
## recu, rien de ce qui a ete calcule. Tout ce que la journee produit va dans
## outputs/, prefixe J10_. On peut ainsi vider outputs/ et tout recalculer
## sans jamais risquer d'effacer une donnee source.
## ----------------------------------------------------------------------

## ========================================================================
## 0.2 — LES PACKAGES, ET UN ORDRE DE CHARGEMENT QUI COMPTE
## ========================================================================
# L'ORDRE DES DEUX PREMIERES LIGNES N'EST PAS INDIFFERENT.
# sae depend de MASS. MASS definit une fonction select(). Si dplyr est charge
# AVANT sae, c'est MASS::select() qui gagne, et tout appel a select() dans la
# suite du script echoue sur un message incomprehensible. En chargeant sae
# d'abord et dplyr ensuite, c'est dplyr::select() qui masque MASS::select(),
# ce que nous voulons. En cas de doute, la parade explicite est dplyr::select().
library(sf)            # donnees vectorielles (Simple Features)
library(sae)           # <- AVANT dplyr : MASS (dont sae depend) masque select()
library(survey)        # plans de sondage, estimation ponderee
library(dplyr)         # verbes de manipulation de tableaux
library(tidyr)         # pivot_longer(), replace_na()
library(ggplot2)       # graphiques
library(readr)         # lecture des CSV
library(tmap)          # cartographie thematique (API version 4)
library(scales)        # mise en forme des axes
library(terra)         # rasters et NetCDF
library(exactextractr) # statistiques zonales exactes raster x polygones

cat("Dossier de travail :", getwd(), "\n")
cat("Fichiers presents dans datasets/ :", length(list.files("datasets")), "\n")

# Verification du conflit annonce : qui fournit select() dans cette session ?
cat("select() vient de :",
    environmentName(environment(get("select"))), "\n")

## ----------------------------------------------------------------------
## LE PIEGE DU MASQUAGE DE select()
##
## Ce que ca code : trois packages du jour definissent select() -- dplyr, MASS
##   (charge silencieusement par sae) et, ailleurs, raster. Le dernier charge
##   gagne.
## Ce que le choix technique fait : charger sae avant dplyr place
##   dplyr::select() au-dessus. Inverser les deux lignes arrete la journee au
##   Module 6, sur une erreur qui ne parle ni de sae, ni de MASS, ni de masquage.
## Ce qui se lit : la ligne "select() vient de :" doit afficher dplyr.
## Ce qui ne se lit pas : les autres masquages de la session (filter() par
##   stats, extract() par terra). Regle generale : qualifier l'appel.
## ----------------------------------------------------------------------

## ========================================================================
## 0.3 — INVENTAIRE : CE QUE LA JOURNEE ATTEND, CE QUE LE DOSSIER CONTIENT
## ========================================================================
# Avant d'ecrire la moindre ligne d'analyse : verifier que les fichiers sont la.
# Un chemin faux ne se voit pas dans un rendu avec error: true -- il produit une
# sortie vide au milieu d'une page qui a l'air complete.
fichiers_attendus <- c(
  "acled_cameroon_export.csv",
  "gadm41_CMR.gpkg",
  "era5_t2m_mensuel_cameroun.nc",
  "ehcvm2018_benin_menages.csv",
  "gadm_ben_communes.gpkg",
  "benin_grille_3km.gpkg",
  "benin_covariables_admin2.csv",
  "benin_covariables_grille.csv"
)

inventaire <- data.frame(
  fichier = fichiers_attendus,
  present = file.exists(file.path("datasets", fichiers_attendus))
)
print(inventaire)

cat("\nFichiers attendus presents :", sum(inventaire$present), "/",
    nrow(inventaire), "\n")
if (any(!inventaire$present)) {
  cat("MANQUANTS :",
      paste(inventaire$fichier[!inventaire$present], collapse = ", "), "\n")
}

# Le Module 10 (accessibilite) repose sur deux fichiers supplementaires, absents
# du poste au moment de l'ecriture : ils sont declares ici pour memoire.
cat("\nModule 10 (conserve de l'ancien materiel, non execute) :\n")
cat("  datasets/DS.geojson       present ?", file.exists("datasets/DS.geojson"), "\n")
cat("  datasets/gadm41_CMR_2.shp present ?", file.exists("datasets/gadm41_CMR_2.shp"), "\n")

## ----------------------------------------------------------------------
## LA QUESTION DE LA JOURNEE
##
## Comment une donnee spatiale devient-elle un argument recevable devant un
## decideur ? Trois familles de donnees, trois facons de repondre :
##
## | Famille       | Fichier                        | Unite d'observation        |
## | Evenementiel  | acled_cameroon_export.csv      | l'evenement RAPPORTE       |
## | Reanalyse     | era5_t2m_mensuel_cameroun.nc   | la cellule de ~31 km, /mois|
## | Enquete       | ehcvm2018_benin_menages.csv    | le menage enquete, en grappe|
##
## Aucune des trois n'est "la realite". Chacune est une construction dont il
## faut connaitre la regle de fabrication avant de la cartographier.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 1 — DONNEES EVENEMENTIELLES : LIRE ACLED SANS LUI FAIRE DIRE PLUS
## ##########################################################################

## ========================================================================
## 1.1 — CE QU'EST ACLED, ET CE QUE N'EST PAS UN "EVENEMENT"
## ========================================================================
## ----------------------------------------------------------------------
## ACLED -- Armed Conflict Location & Event Data Project (acleddata.com)
##
## ACLED code, a partir de sources ouvertes (presse, ONG, communiques, reseaux
## sociaux verifies), des EVENEMENTS de violence politique et de contestation :
## batailles, violences contre les civils, emeutes, manifestations, explosions
## / violences a distance, developpements strategiques.
##
## UN EVENEMENT ACLED N'EST PAS UN FAIT VERIFIE : C'EST UN FAIT RAPPORTE. La
## base mesure conjointement l'activite conflictuelle ET l'activite des sources
## qui la rapportent. Une region ou la presse ne circule pas produit peu
## d'evenements -- ce qui ne veut pas dire qu'il s'y passe peu de choses.
## Toute la journee : ecrire "evenements rapportes", jamais "evenements".
##
## Acces : compte gratuit sur developer.acleddata.com, package acledR. Le
## fichier de ce dossier est un export fige, au format identique a l'API.
## ----------------------------------------------------------------------

# BLOC DE REFERENCE -- NON EXECUTE (necessite un compte myACLED et une connexion).
# Conserve pour montrer que le fichier fourni est un export fige de cette requete.
#
# install.packages("acledR")
#
# acled_brut <- acledR::acled_api(
#   email      = "votre@email.com",
#   password   = "votre_mot_de_passe",
#   country    = "Cameroon",
#   start_date = "2015-01-01",
#   end_date   = as.character(Sys.Date()),
#   monadic    = FALSE
# )
# readr::write_csv(acled_brut, "datasets/acled_cameroon_export.csv")

## ========================================================================
## 1.2 — LECTURE ET STRUCTURE REELLE DU FICHIER
## ========================================================================
# Separateur : virgule (verifie sur l'en-tete du fichier). Les champs "notes"
# contiennent des virgules, mais ils sont proteges par des guillemets : read_csv()
# les gere. La verification qui suit n'est pas decorative -- un mauvais separateur
# renvoie UNE colonne unique, sans lever la moindre erreur.
acled_brut <- read_csv("datasets/acled_cameroon_export.csv", show_col_types = FALSE)

cat("ACLED :", nrow(acled_brut), "lignes x", ncol(acled_brut), "colonnes\n")
cat("Une seule colonne lue ? ", ncol(acled_brut) == 1,
    "  (TRUE = mauvais separateur)\n\n")

cat("Colonnes reellement presentes :\n")
print(names(acled_brut))

# Les annees couvertes par l'export. On ne les suppose pas : on les lit.
annees_disponibles <- sort(unique(acled_brut$year))
cat("Annees disponibles :", paste(annees_disponibles, collapse = ", "), "\n")
cat("Nombre d'annees :", length(annees_disponibles), "\n")

cat("\nEvenements par annee :\n")
print(table(acled_brut$year))

cat("\nTypes d'evenements presents :\n")
print(sort(table(acled_brut$event_type), decreasing = TRUE))

## ----------------------------------------------------------------------
## LES COLONNES QUI SERVENT, ET CELLES QUI PIEGENT
##
## event_date, year ........ date de l'evenement -> series temporelles
## event_type, sub_event_type typologie a deux niveaux -> comptages, couleurs
## admin1, admin2, admin3 .. decoupage TEL QU'ACLED L'ECRIT -> piege du Module 2
## latitude, longitude ..... position du lieu rapporte -> couche sf
## geo_precision ........... 1 lieu precis / 2 ville la plus proche / 3 region
## time_precision .......... 1 jour connu / 2 semaine / 3 mois
## fatalities .............. morts RAPPORTES, pas comptes
## notes ................... resume textuel : jamais agrege, toujours utile a lire
##
## geo_precision et time_precision sont les deux colonnes que tout le monde
## oublie. Un evenement geo_precision = 3 est place au centroide d'une region :
## sur une carte de points il ressemble a un point GPS au metre pres.
## ----------------------------------------------------------------------

## ========================================================================
## 1.3 — CONTROLE DES VALEURS DOUTEUSES AVANT TOUT CALCUL
## ========================================================================
# CONTROLE DES SENTINELLES ET DES VALEURS IMPOSSIBLES.
# Une sentinelle traverse mean() sans un mot. On les cherche AVANT de calculer.

# a) fatalities : des negatifs ? des valeurs aberrantes ?
cat("fatalities -- min :", min(acled_brut$fatalities, na.rm = TRUE),
    "| max :", max(acled_brut$fatalities, na.rm = TRUE),
    "| NA :", sum(is.na(acled_brut$fatalities)), "\n")
cat("fatalities negatifs (sentinelle possible) :",
    sum(acled_brut$fatalities < 0, na.rm = TRUE), "\n")

# b) coordonnees a (0, 0) : le point "null island", au large du golfe de Guinee.
#    C'est LA sentinelle classique des bases d'evenements : une coordonnee
#    manquante remplacee par zero. Sur une carte du Cameroun, ces points
#    tombent dans l'ocean, et personne ne les remarque si on ne les compte pas.
cat("\nCoordonnees exactement (0, 0) :",
    sum(acled_brut$latitude == 0 & acled_brut$longitude == 0, na.rm = TRUE), "\n")
cat("latitude NA :", sum(is.na(acled_brut$latitude)),
    "| longitude NA :", sum(is.na(acled_brut$longitude)), "\n")

# c) l'emprise du Cameroun est approximativement 1.6-13.1 N et 8.4-16.2 E.
#    Tout point hors de cette boite est suspect.
hors_emprise <- with(
  acled_brut,
  latitude < 1 | latitude > 14 | longitude < 8 | longitude > 17
)
cat("Points hors de l'emprise plausible du Cameroun :",
    sum(hors_emprise, na.rm = TRUE), "\n")

# d) qualite de la localisation et de la date
cat("\nRepartition de geo_precision (1 = lieu precis, 3 = region) :\n")
print(table(acled_brut$geo_precision, useNA = "ifany"))
cat("\nRepartition de time_precision (1 = jour connu, 3 = mois) :\n")
print(table(acled_brut$time_precision, useNA = "ifany"))

## ----------------------------------------------------------------------
## CE QUE CE CONTROLE VIENT D'ETABLIR
##
## Ce qu'il code : quatre familles de defauts -- fatalities negatifs
##   (sentinelle d'absence), coordonnees (0,0), points hors emprise, et qualite
##   declaree de la geolocalisation.
## Ce que le choix technique fait : la boite 1-14 N / 8-17 E est un test
##   GROSSIER et volontairement large. Il attrape les erreurs de saisie et les
##   inversions latitude/longitude, pas les erreurs de quelques kilometres. Une
##   inversion c(latitude, longitude) place le Cameroun au large de la Somalie :
##   ce test la detecte, st_as_sf() non -- l'inversion ne leve AUCUNE erreur.
## Ce qui se lit : les compteurs ci-dessus, a relire a voix haute en salle.
## Ce qui ne se lit pas : un geo_precision = 3 n'est pas une erreur, c'est un
##   evenement dont on ne sait que la region. Legitime dans un comptage
##   regional, illegitime dans une carte lue au village pres. Le meme
##   enregistrement est bon ou mauvais SELON LA QUESTION POSEE.
## ----------------------------------------------------------------------

## ========================================================================
## 1.4 — NETTOYAGE ET CHAMP TEMPOREL
## ========================================================================
# Nettoyage minimal et EXPLICITE : chaque ligne retiree est comptee.
n_avant <- nrow(acled_brut)

acled_clean <- acled_brut |>
  mutate(
    event_date = as.Date(event_date),
    annee      = as.integer(year),
    mois       = format(event_date, "%Y-%m"),
    fatalities = as.numeric(fatalities),
    longitude  = as.numeric(longitude),
    latitude   = as.numeric(latitude)
  ) |>
  filter(
    !is.na(longitude), !is.na(latitude),
    !(longitude == 0 & latitude == 0)   # on retire "null island", en le disant
  )

cat("Lignes avant nettoyage :", n_avant, "\n")
cat("Lignes apres nettoyage :", nrow(acled_clean), "\n")
cat("Lignes retirees (coordonnees absentes ou nulles) :",
    n_avant - nrow(acled_clean), "\n")

cat("\nPlage temporelle :",
    format(min(acled_clean$event_date), "%Y-%m-%d"), "a",
    format(max(acled_clean$event_date), "%Y-%m-%d"), "\n")

# Champ d'analyse : les dix dernieres annees couvertes par le fichier. On borne
# a partir de la DERNIERE annee du fichier, pas de la date du jour : le materiel
# doit donner la meme sortie en 2026 et en 2030.
annee_max <- max(acled_clean$annee, na.rm = TRUE)
annee_min <- annee_max - 9

acled_clean <- acled_clean |> filter(annee >= annee_min)

cat("Champ retenu :", annee_min, "-", annee_max, "|",
    nrow(acled_clean), "evenements\n")
cat("Evenements exclus par le bornage temporel :",
    sum(acled_brut$year < annee_min, na.rm = TRUE), "\n")

## ----------------------------------------------------------------------
## POURQUOI BORNER SUR LA DONNEE ET NON SUR Sys.Date()
##
## Le script d'origine calculait le champ temporel a partir de la date du jour.
## Consequence : le meme document, rendu deux ans plus tard, n'affiche plus les
## memes chiffres -- et personne ne comprend pourquoi la carte du support ne
## correspond plus a celle de l'ecran. Un materiel pedagogique doit etre
## REPRODUCTIBLE : on borne sur la derniere annee presente dans le fichier.
## ----------------------------------------------------------------------

## ========================================================================
## 1.5 — DEUX SERIES : LES EVENEMENTS, PUIS LES DECES
## ========================================================================
# a) Comptage par type d'evenement
resume_types <- acled_clean |>
  count(event_type, sort = TRUE, name = "n_evenements") |>
  mutate(part_pct = round(100 * n_evenements / sum(n_evenements), 1))

print(resume_types)

# b) Comptage par region TELLE QU'ACLED L'ECRIT (colonne admin1).
#    Retenez ces libelles : ils sont le sujet du Module 2.
resume_admin1 <- acled_clean |>
  count(admin1, sort = TRUE, name = "n_evenements")

cat("\nLibelles admin1 presents dans ACLED (", nrow(resume_admin1), ") :\n")
print(resume_admin1)
cat("\nadmin1 manquant :", sum(is.na(acled_clean$admin1)), "evenements\n")

resume_annuel <- acled_clean |>
  count(annee, event_type, name = "n_evenements")

graphe_annuel <- ggplot(
  resume_annuel,
  aes(x = annee, y = n_evenements, fill = event_type)
) +
  geom_col() +
  scale_x_continuous(breaks = seq(annee_min, annee_max, by = 1)) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title    = "Evenements rapportes par ACLED, Cameroun",
    subtitle = paste0("Barres empilees par type, ", annee_min, "-", annee_max,
                      ". Source : ACLED (evenements RAPPORTES)."),
    x = "Annee", y = "Nombre d'evenements rapportes", fill = "Type"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(graphe_annuel)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- BARRES EMPILEES ANNUELLES
##
## Ce que la figure code : la hauteur totale d'une barre est le nombre
##   d'evenements RAPPORTES cette annee-la ; chaque couleur est un type. Un
##   evenement compte pour 1, qu'il ait fait zero ou cinquante morts : ce
##   graphique mesure une FREQUENCE, pas une intensite.
## Ce que les choix techniques font : l'empilement rend le TOTAL annuel tres
##   lisible et la comparaison d'un type d'une annee a l'autre difficile (l'oeil
##   compare des segments qui ne partent pas de la meme base). Pour un type
##   precis : facet_wrap(~ event_type) -- meme tableau, lecture inverse. La
##   palette Set2 est QUALITATIVE : aucune couleur n'est "plus" qu'une autre.
## Ce qui se lit : le profil temporel, les annees de pic, la deformation de la
##   composition par type.
## Ce qui ne se lit pas : l'effort de collecte. Une hausse peut venir d'une
##   degradation de la situation, d'une meilleure couverture mediatique, ou
##   d'un changement de methodologie ACLED. Rien ici ne tranche -- et c'est la
##   premiere question qu'un decideur informe posera.
## ----------------------------------------------------------------------

resume_deces <- acled_clean |>
  group_by(annee) |>
  summarise(
    deces        = sum(fatalities, na.rm = TRUE),
    n_evenements = n(),
    .groups = "drop"
  ) |>
  mutate(deces_par_evenement = round(deces / n_evenements, 2))

print(resume_deces)

graphe_deces <- ggplot(resume_deces, aes(x = annee, y = deces)) +
  geom_line(colour = "#CB181D", linewidth = 1.2) +
  geom_point(colour = "#CB181D", size = 2.5) +
  scale_x_continuous(breaks = seq(annee_min, annee_max, by = 1)) +
  scale_y_continuous(labels = label_number(big.mark = " ")) +
  labs(
    title    = "Deces rapportes lies aux conflits, Cameroun",
    subtitle = "Somme annuelle de fatalities. Source : ACLED (deces RAPPORTES).",
    x = "Annee", y = "Nombre de deces rapportes"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(graphe_deces)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- COURBE DES DECES
##
## Ce que la figure code : la somme annuelle de fatalities, c'est-a-dire des
##   deces RAPPORTES par au moins une source et retenus par le codage ACLED.
##   Ni un decompte d'etat civil, ni une estimation de surmortalite.
## Ce que les choix techniques font : relier les points suggere une continuite
##   entre deux annees -- commodite de lecture, pas propriete de la donnee. La
##   colonne deces_par_evenement imprimee au-dessus est le vrai complement :
##   elle separe "plus d'evenements" de "des evenements plus meurtriers".
## Ce qui se lit : les annees de rupture, et leur ecart avec le graphe des
##   frequences. Une annee peut battre un record d'evenements sans battre celui
##   des deces.
## Ce qui ne se lit pas : l'incertitude. Un deces rapporte par une source unique
##   et un deces confirme par trois sources pesent pareil dans cette somme.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 2 — DU POINT AU POLYGONE : LA JOINTURE QUI ECHOUE EN SILENCE
## ##########################################################################

## ========================================================================
## 2.1 — CONVERTIR LES EVENEMENTS EN COUCHE SPATIALE
## ========================================================================
# ORDRE DES COORDONNEES : c(longitude, latitude), et JAMAIS l'inverse.
# sf ne verifie rien : il place les points ou on lui dit. Une inversion ne leve
# aucune erreur, elle deplace simplement tout le Cameroun dans l'ocean Indien.
# Le seul garde-fou est de tracer la couche immediatement apres l'avoir creee.
acled_pts <- st_as_sf(
  acled_clean,
  coords = c("longitude", "latitude"),
  crs    = 4326,          # WGS84 : degres. Toujours POSER le CRS.
  remove = FALSE          # on garde les colonnes lon/lat pour pouvoir verifier
)

cat("Couche de points ACLED :", nrow(acled_pts), "entites\n")
cat("CRS :", st_crs(acled_pts)$input, "\n")
cat("Emprise (bbox) :\n")
print(st_bbox(acled_pts))

# Limites administratives du Cameroun, GADM 4.1, format GeoPackage multicouche.
# On liste d'abord les couches disponibles : on ne suppose pas leur nom.
couches_gadm <- st_layers("datasets/gadm41_CMR.gpkg")
print(couches_gadm)

cmr0 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_0", quiet = TRUE)
cmr1 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_1", quiet = TRUE)

cat("\nADM_ADM_0 (pays)    :", nrow(cmr0), "entite(s) |",
    "CRS :", st_crs(cmr0)$input, "\n")
cat("ADM_ADM_1 (regions) :", nrow(cmr1), "entites |",
    "CRS :", st_crs(cmr1)$input, "\n")

cat("\nChamps de la couche ADM_ADM_1 :\n")
print(names(cmr1))

cat("\nLibelles NAME_1 tels que GADM les ecrit :\n")
print(sort(cmr1$NAME_1))

## ----------------------------------------------------------------------
## DEUX FICHIERS, DEUX LANGUES, AUCUNE ERREUR
##
## ACLED ecrit ses regions en FRANCAIS SANS ACCENTS : Sud, Extreme-Nord,
## Nord-Ouest, Vallee-du-Ntem au niveau admin2.
## GADM ecrit les siennes en ANGLAIS : South, Far North, North-West.
##
## Ce n'est PAS un probleme d'accents, c'est un probleme de LANGUE. Aucune
## translitteration ne transformera Extreme-Nord en Far North. Et pourtant
## left_join() acceptera la jointure sans broncher : il produira des NA,
## c'est-a-dire -- une fois replace_na(0) applique -- des REGIONS A ZERO
## EVENEMENT sur la carte. Une region en guerre affichee en blanc.
##
## C'est le scenario type de "ce qui echoue en silence est plus dangereux que
## ce qui plante". Nous allons donc le PROVOQUER avant de le corriger.
## ----------------------------------------------------------------------

## ========================================================================
## 2.2 — TENTATIVE N.1 : JOINDRE PAR LE LIBELLE (ET COMPTER LES DEGATS)
## ========================================================================
# TENTATIVE DELIBEREMENT FAUSSE -- a executer pour voir ce qu'elle produit.
# Regle : on part TOUJOURS de la couche geographique, jamais du tableau
# (cmr1 |> left_join(stats)), sinon on perd la geometrie.
essai_nom <- cmr1 |>
  st_drop_geometry() |>
  select(NAME_1) |>
  left_join(resume_admin1, by = c("NAME_1" = "admin1"))

cat("Regions GADM :", nrow(essai_nom), "\n")
cat("Regions APPARIEES avec ACLED :", sum(!is.na(essai_nom$n_evenements)), "\n")
cat("Regions NON appariees (NA) :", sum(is.na(essai_nom$n_evenements)), "\n\n")
print(essai_nom)

# Et cote ACLED : combien d'evenements se retrouveraient orphelins ?
libelles_gadm  <- cmr1$NAME_1
evts_orphelins <- acled_clean |> filter(!(admin1 %in% libelles_gadm))
cat("\nEvenements ACLED dont admin1 n'existe pas dans GADM :",
    nrow(evts_orphelins), "sur", nrow(acled_clean),
    sprintf("(%.1f %%)", 100 * nrow(evts_orphelins) / nrow(acled_clean)), "\n")
cat("Libelles ACLED sans correspondant GADM :\n")
print(sort(unique(evts_orphelins$admin1)))

## ----------------------------------------------------------------------
## LE DIAGNOSTIC, CHIFFRE
##
## Seules s'apparient les regions dont le nom s'ecrit pareil dans les deux
## langues -- une poignee (Adamaoua, Centre, Littoral sont les candidates
## evidentes). Toutes les autres deviennent des NA.
##
## En langage de salle : "la carte que nous aurions publiee aurait affiche zero
## evenement pour la majorite des regions du pays, sans le moindre message
## d'erreur". C'est l'accident que le compteur sum(is.na(...)) apres chaque
## jointure est cense empecher -- y compris quand la jointure "ne peut pas
## rater".
## ----------------------------------------------------------------------

## ========================================================================
## 2.3 — TENTATIVE N.2 : NORMALISER LES CHAINES (ET VOIR QUE CA NE SUFFIT PAS)
## ========================================================================
# La parade habituelle : fabriquer une CLE TECHNIQUE en normalisant les libelles
# (sans accents, minuscules, sans ponctuation ni espaces). Le libelle d'origine
# est conserve pour l'affichage : la cle ne sert QU'A joindre.
normaliser <- function(x) {
  y <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")  # accents retires
  y <- tolower(y)
  y <- gsub("[^a-z]", "", y)                             # ponctuation, espaces
  y
}

cle_gadm  <- normaliser(cmr1$NAME_1)
cle_acled <- normaliser(resume_admin1$admin1)

cat("Cles GADM  :", paste(sort(cle_gadm), collapse = ", "), "\n\n")
cat("Cles ACLED :", paste(sort(cle_acled), collapse = ", "), "\n\n")
cat("Cles communes apres normalisation :",
    length(intersect(cle_gadm, cle_acled)), "sur", length(cle_gadm), "\n")

## ----------------------------------------------------------------------
## CE QUE LA NORMALISATION RESOUT -- ET CE QU'ELLE NE RESOUT PAS
##
## Ce qu'elle resout : les differences d'ecriture (accents, casse, tirets,
##   espaces, mots de liaison). Sur un appariement francais <-> francais, elle
##   sauve la mise : au J05, la meme fonction recuperait 11 departements sur 58.
## Ce qu'elle ne resout pas : la traduction. extremenord et farnorth restent
##   deux chaines distinctes, et aucune distance d'edition ne devrait les
##   rapprocher -- si elle le faisait, elle rapprocherait aussi n'importe quoi.
##
## Quand la normalisation echoue : ECRIRE UNE TABLE DE CORRESPONDANCE A LA
## MAIN. Ce n'est pas un bricolage, c'est une DECISION DE METHODE, visible dans
## le code et justifiee dans le texte.
## ----------------------------------------------------------------------

## ========================================================================
## 2.4 — TENTATIVE N.3 : LA TABLE DE CORRESPONDANCE ECRITE A LA MAIN
## ========================================================================
# TABLE DE CORRESPONDANCE FR (ACLED) -> EN (GADM), ecrite a la main, verifiable
# ligne a ligne par un lecteur humain. Dix regions, dix lignes : rien de magique.
corresp_regions <- tibble::tribble(
  ~admin1_acled,    ~NAME_1_gadm,
  "Adamaoua",       "Adamaoua",
  "Centre",         "Centre",
  "Est",            "East",
  "Extreme-Nord",   "Far North",
  "Littoral",       "Littoral",
  "Nord",           "North",
  "Nord-Ouest",     "North-West",
  "Ouest",          "West",
  "Sud",            "South",
  "Sud-Ouest",      "South-West"
)

# CONTROLE : chaque libelle de la table existe-t-il vraiment dans GADM ?
cat("Libelles GADM de la table absents de la couche :",
    paste(setdiff(corresp_regions$NAME_1_gadm, cmr1$NAME_1), collapse = ", "),
    "\n")
cat("Libelles GADM de la couche absents de la table :",
    paste(setdiff(cmr1$NAME_1, corresp_regions$NAME_1_gadm), collapse = ", "),
    "\n")
cat("Libelles ACLED absents de la table :",
    paste(setdiff(unique(acled_clean$admin1), corresp_regions$admin1_acled),
          collapse = ", "),
    "\n")

# Jointure attributaire corrigee
resume_par_table <- resume_admin1 |>
  left_join(corresp_regions, by = c("admin1" = "admin1_acled"))

cat("\nEvenements non rattaches malgre la table :",
    sum(resume_par_table$n_evenements[is.na(resume_par_table$NAME_1_gadm)],
        na.rm = TRUE), "\n")

## ----------------------------------------------------------------------
## LES DEUX CONTROLES A NE JAMAIS OMETTRE SUR UNE TABLE DE CORRESPONDANCE
##
## Une table ecrite a la main a le defaut de sa qualite : elle a l'air juste.
## Les deux setdiff() ci-dessus sont son seul garde-fou.
##  - un libelle de la TABLE absent de la COUCHE = faute de frappe dans la
##    table : la ligne ne s'appariera jamais, silencieusement ;
##  - un libelle de la COUCHE absent de la TABLE = region oubliee : elle
##    restera a NA, puis a zero sur la carte.
## Verifier DANS LES DEUX SENS. Si GADM ecrivait "Far-North" avec un tiret et
## notre table "Far North" sans, le premier setdiff() le dirait immediatement.
## ----------------------------------------------------------------------

## ========================================================================
## 2.5 — LA ROUTE SURE : LA JOINTURE SPATIALE st_within
## ========================================================================
# JOINTURE SPATIALE. Elle n'utilise aucun libelle : elle demande, pour chaque
# point, dans quel polygone il tombe. Une position ne se traduit pas.
#
# Prealable obligatoire : harmoniser les CRS, et l'AFFICHER.
cat("CRS des points  :", st_crs(acled_pts)$input, "\n")
cat("CRS des regions :", st_crs(cmr1)$input, "\n")
cat("CRS identiques ? ", st_crs(acled_pts) == st_crs(cmr1), "\n")

if (st_crs(acled_pts) != st_crs(cmr1)) {
  acled_pts <- st_transform(acled_pts, st_crs(cmr1))
  cat("-> points reprojetes vers", st_crs(cmr1)$input, "\n")
}

n_pts_avant <- nrow(acled_pts)

acled_dans_region <- st_join(
  acled_pts,
  cmr1[c("NAME_1")],
  join = st_within        # le point est-il A L'INTERIEUR du polygone ?
)

# CONTROLE 1 : st_join() peut DUPLIQUER des lignes si deux polygones se
# recouvrent. On compare le nombre de lignes avant et apres.
cat("\nPoints avant st_join :", n_pts_avant, "\n")
cat("Lignes apres st_join :", nrow(acled_dans_region), "\n")
cat("Duplications introduites :", nrow(acled_dans_region) - n_pts_avant, "\n")

# CONTROLE 2 : points tombes hors de toute region (frontiere, mer, coordonnee
# fausse). Ce ne sont PAS des dechets : ce sont une information.
n_hors <- sum(is.na(acled_dans_region$NAME_1))
cat("Points hors de toute region GADM :", n_hors,
    sprintf("(%.2f %%)", 100 * n_hors / nrow(acled_dans_region)), "\n")

if (n_hors > 0) {
  cat("\nCes points, tels qu'ACLED les localise (admin1 declare) :\n")
  print(table(acled_dans_region$admin1[is.na(acled_dans_region$NAME_1)]))
}

# CONFRONTATION : ce que dit le LIBELLE d'ACLED contre ce que dit la POSITION.
# Les deux devraient coincider. Les desaccords sont un diagnostic de qualite.
verif <- acled_dans_region |>
  st_drop_geometry() |>
  filter(!is.na(NAME_1)) |>
  left_join(corresp_regions, by = c("admin1" = "admin1_acled")) |>
  mutate(accord = NAME_1 == NAME_1_gadm)

cat("Evenements ou le libelle ACLED et le polygone GADM concordent :",
    sum(verif$accord, na.rm = TRUE), "\n")
cat("Evenements en DESACCORD :", sum(!verif$accord, na.rm = TRUE),
    sprintf("(%.2f %%)", 100 * mean(!verif$accord, na.rm = TRUE)), "\n")

if (sum(!verif$accord, na.rm = TRUE) > 0) {
  cat("\nDetail des desaccords (admin1 declare -> region du polygone) :\n")
  print(
    verif |>
      filter(!accord) |>
      count(admin1, NAME_1, sort = TRUE, name = "n") |>
      head(15)
  )
}

## ----------------------------------------------------------------------
## CE QUE LE DESACCORD RACONTE
##
## Un desaccord entre le libelle et la position n'est pas necessairement une
## erreur d'ACLED. Trois causes a distinguer devant les participants :
##  1. un evenement pres d'une frontiere regionale, dont la coordonnee (souvent
##     le centroide d'une ville) tombe du mauvais cote du trait. Le trace GADM
##     n'est pas la verite juridique de la limite ;
##  2. un decoupage administratif qui a change : GADM 4.1 est fige, ACLED code
##     selon le decoupage en vigueur a la date de l'evenement ;
##  3. une coordonnee imprecise (geo_precision 2 ou 3).
## Dans les trois cas la position reste la cle la plus sure pour agreger -- mais
## le TAUX DE DESACCORD est un indicateur de qualite a publier a cote de la
## carte, pas a dissimuler.
## ----------------------------------------------------------------------

## ========================================================================
## 2.6 — AGREGATION REGIONALE ET CARTE CHOROPLETHE
## ========================================================================
resume_par_region <- acled_dans_region |>
  st_drop_geometry() |>
  filter(!is.na(NAME_1)) |>
  group_by(NAME_1) |>
  summarise(
    n_evenements = n(),
    deces        = sum(fatalities, na.rm = TRUE),
    n_batailles  = sum(event_type == "Battles", na.rm = TRUE),
    .groups = "drop"
  )

cat("Regions avec au moins un evenement :", nrow(resume_par_region),
    "sur", nrow(cmr1), "\n\n")

# ON PART DE LA COUCHE GEOGRAPHIQUE : cmr1 |> left_join(stats).
cmr1_acled <- cmr1 |>
  left_join(resume_par_region, by = "NAME_1")

cat("Regions sans aucun evenement rapporte (NA apres jointure) :",
    sum(is.na(cmr1_acled$n_evenements)), "\n")
if (any(is.na(cmr1_acled$n_evenements))) {
  cat("Lesquelles :",
      paste(cmr1_acled$NAME_1[is.na(cmr1_acled$n_evenements)], collapse = ", "),
      "\n")
}

# DECISION EXPLICITE : ici, et SEULEMENT ici, remplacer NA par 0 est legitime.
# La jointure est spatiale : une region sans ligne n'est pas une region non
# appariee, c'est une region ou aucun evenement n'a ete rapporte. Le zero est
# une MESURE, pas un trou. Avec la jointure par libelle du 2.2, le meme
# replace_na(0) aurait fabrique de fausses regions pacifiees.
cmr1_acled <- cmr1_acled |>
  mutate(
    n_evenements = replace_na(n_evenements, 0L),
    deces        = replace_na(deces, 0),
    n_batailles  = replace_na(n_batailles, 0L)
  )

print(
  cmr1_acled |>
    st_drop_geometry() |>
    select(NAME_1, n_evenements, deces, n_batailles) |>
    arrange(desc(n_evenements))
)

## ----------------------------------------------------------------------
## replace_na(0) : LA MEME LIGNE DE CODE, DEUX SIGNIFICATIONS OPPOSEES
##
## C'est le point de methode le plus important du module.
## Apres une JOINTURE SPATIALE REUSSIE, une region absente du tableau est une
##   region ou AUCUN evenement n'a ete rapporte. Le zero est une observation.
## Apres une JOINTURE PAR LIBELLE RATEE, une region absente est une region dont
##   le NOM ne s'est pas apparie. Le zero fabrique une information fausse, et
##   lui donne la meme autorite visuelle qu'a une information vraie.
## La ligne de code est identique. Ce qui change, c'est ce qu'on sait de
## l'etape d'avant. D'ou la discipline : on ne remplace un NA qu'apres avoir
## compte les NA et su d'ou ils viennent.
## ----------------------------------------------------------------------

tmap_mode("plot")   # jamais "view" dans un document distribue

carte_types <- tm_shape(cmr1) +
  tm_borders(col = "grey50", lwd = 0.8) +
  tm_shape(acled_pts) +
  tm_dots(
    fill        = "event_type",
    size        = 0.25,
    fill_alpha  = 0.6,
    fill.legend = tm_legend(title = "Type d'evenement")
  ) +
  tm_shape(cmr0) +
  tm_borders(col = "grey20", lwd = 1.8) +
  tm_title("Evenements rapportes par ACLED, Cameroun") +
  tm_layout(legend.outside = TRUE)

print(carte_types)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- CARTE DE POINTS
##
## Ce que la figure code : un point = un evenement RAPPORTE, a la coordonnee
##   fournie par ACLED, colore par type. La taille du point ne code rien.
## Ce que les choix techniques font : la transparence (fill_alpha = 0.6) laisse
##   deviner les superpositions. C'est un pis-aller -- une carte de points
##   SATURE : au-dela de quelques centaines d'evenements au meme endroit, l'oeil
##   ne distingue plus 200 de 2000. Palette qualitative : correcte pour des
##   types non ordonnes.
## Ce qui se lit : la geographie du phenomene -- concentrations, axes, vides. Et
##   surtout l'HETEROGENEITE INTERNE des regions, que la choroplethe effacera.
## Ce qui ne se lit pas : l'intensite, la precision de la position, la
##   population exposee. Trois points en zone desertique et trois points en
##   ville n'ont pas le meme sens.
##
## EN QUOI LE SPATIAL EST UTILE ICI : le tableau resume_admin1 donne un
## classement. La carte montre que les evenements forment des BLOCS CONTIGUS
## qui traversent les limites administratives. Un bloc contigu ne s'explique pas
## par les caracteristiques propres de chaque region, mais par ce que des
## territoires voisins partagent PARCE QU'ILS SONT VOISINS -- une frontiere, un
## corridor, un meme acteur arme mobile. Aucun tri de tableau ne montre cela.
## ----------------------------------------------------------------------

carte_regions <- tm_shape(cmr1_acled) +
  tm_polygons(
    fill        = "n_evenements",
    fill.scale  = tm_scale_intervals(style = "quantile", n = 5,
                                     values = "brewer.reds"),
    fill.legend = tm_legend(title = "Evenements\nrapportes"),
    col         = "white",
    lwd         = 0.6
  ) +
  tm_shape(cmr0) +
  tm_borders(col = "grey20", lwd = 1.5) +
  tm_title("Evenements ACLED par region (agregation spatiale)") +
  tm_layout(legend.outside = TRUE)

print(carte_regions)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- CHOROPLETHE, ET CE QUE L'AGREGATION A DETRUIT
##
## Ce que la figure code : la couleur d'une region est le NOMBRE TOTAL
##   d'evenements rapportes tombes dans son polygone. Pas un taux : un effectif
##   brut. Une grande region peuplee en aura mecaniquement plus qu'une petite.
## Ce que les choix techniques font : la DISCRETISATION est en quantiles (5
##   classes) -- chaque classe contient le meme nombre de regions, ce qui
##   garantit une carte contrastee, y compris quand les ecarts reels sont
##   faibles. Trois discretisations du MEME tableau racontent trois histoires :
##   quantiles (contraste garanti, seuils arbitraires), intervalles egaux
##   (seuils lisibles, classes parfois vides), Jenks (ruptures naturelles,
##   seuils non comparables d'une carte a l'autre). Aucun choix n'est neutre ;
##   un choix DECLARE suffit.
## Ce qui se lit : le classement regional et sa geographie d'ensemble.
## Ce qui ne se lit pas : la position exacte, les concentrations locales, les
##   vides internes. La choroplethe affirme implicitement que la region est
##   HOMOGENE -- c'est faux, et la carte de points le prouve.
##
## EN QUOI LE SPATIAL EST UTILE ICI : une choroplethe ne sert pas a voir OU est
## le phenomene (la carte de points fait mieux). Elle sert a le rendre
## COMPARABLE A UNE DECISION : budgets, affectations et programmes se decident
## par region. C'est la maille de la decision qui commande la maille de la carte.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## MAUP — LE PROBLEME DE L'UNITE SPATIALE MODIFIABLE
##
## Nous venons de faire, en trois lignes, ce que la litterature appelle le MAUP
## (Modifiable Areal Unit Problem, Openshaw 1984). Il a deux faces.
##
## EFFET D'ECHELLE : les memes points agreges par region (10 unites), par
##   departement (58) ou par arrondissement donnent trois cartes, trois
##   classements et trois correlations differents. Plus la maille est fine, plus
##   la variance est forte et plus les correlations faiblissent. Aucun de ces
##   resultats n'est "le vrai".
## EFFET DE ZONAGE : a nombre d'unites constant, deplacer les limites change les
##   resultats. C'est le mecanisme du redecoupage electoral, et il opere aussi
##   sur les cartes statistiques.
## CONSEQUENCE PRATIQUE : aucune maille n'est neutre, donc aucune n'est
##   defendable "en soi". La seule justification recevable : on agrege a la
##   MAILLE DE LA DECISION qu'on eclaire -- en DISANT que la region est
##   heterogene, et en montrant la carte de points a cote.
##
## ERREUR ECOLOGIQUE : conclure de cette carte que "les habitants de telle
## region ont une probabilite elevee d'etre exposes" est un saut illegitime. La
## carte decrit l'agregat, pas les individus : une region peut concentrer tous
## ses evenements sur 2 % de son territoire. La superposition fond agrege +
## points est le meilleur antidote.
## ----------------------------------------------------------------------

## ========================================================================
## 2.7 — EXPORTS DU BLOC ACLED
## ========================================================================
# Toutes les sorties vont dans outputs/, prefixees J10_. Jamais dans datasets/.
st_write(acled_pts, "outputs/J10_acled_points.gpkg",
         delete_dsn = TRUE, quiet = TRUE)
st_write(cmr1_acled, "outputs/J10_acled_regions.gpkg",
         delete_dsn = TRUE, quiet = TRUE)

write_csv(resume_types, "outputs/J10_acled_resume_types.csv")
write_csv(resume_par_region, "outputs/J10_acled_resume_regions.csv")
write_csv(resume_deces, "outputs/J10_acled_deces_annuels.csv")

ggsave("outputs/J10_acled_annuel.png", graphe_annuel,
       width = 10, height = 6, dpi = 180)
ggsave("outputs/J10_acled_deces.png", graphe_deces,
       width = 8, height = 5, dpi = 180)

tmap_save(carte_types, "outputs/J10_acled_carte_types.png",
          width = 1800, height = 1400, dpi = 200)
tmap_save(carte_regions, "outputs/J10_acled_carte_regions.png",
          width = 1400, height = 1600, dpi = 200)

cat("Fichiers presents dans outputs/ :", length(list.files("outputs")), "\n")
print(list.files("outputs"))

## ##########################################################################
## MODULE 3 — REANALYSE CLIMATIQUE : OUVRIR UN NETCDF SANS SE TROMPER D'UNITE
## ##########################################################################

## ========================================================================
## 3.1 — CE QU'EST UNE REANALYSE
## ========================================================================
## ----------------------------------------------------------------------
## ERA5 -- CE QUE MESURE EXACTEMENT CE FICHIER
##
## ERA5 est la REANALYSE atmospherique de l'ECMWF, diffusee par le Copernicus
## Climate Data Store (cds.climate.copernicus.eu, compte gratuit).
##
## Une reanalyse n'est NI une observation, NI une prevision. C'est le resultat
## d'un modele de circulation atmospherique force a rester coherent avec toutes
## les observations disponibles (stations, ballons, satellites, navires). Le
## produit est un champ COMPLET et REGULIER -- une valeur partout, tous les
## mois, depuis 1940 -- la ou les observations reelles sont eparses. C'est son
## interet en Afrique centrale, ou le reseau au sol est clairseme ; c'est aussi
## sa limite : dans les zones sans station, la valeur vient surtout du modele.
##
##   Variable ............ 2m_temperature (temperature de l'air a 2 m)
##   Produit ............. ERA5 Single Levels, moyennes mensuelles
##   Resolution spatiale . ~0,25 degre, soit ~31 km
##   Pas de temps ........ mensuel
##   UNITE ............... KELVIN
##   Format .............. NetCDF (longitude x latitude x temps)
##
## KELVIN : c'est l'unite native, et rien dans le fichier ne l'affiche. Un
## raster non converti donne des valeurs autour de 298 -- personne ne confondra
## 298 K avec des degres Celsius. Mais une ANOMALIE ou une DIFFERENCE calculee
## sans conversion passe, elle, parfaitement inapercue : une difference de 2 K
## vaut 2 C, alors qu'une moyenne de 298 K vaut 24,85 C.
## ----------------------------------------------------------------------

# BLOC DE REFERENCE -- NON EXECUTE (necessite un compte Copernicus CDS).
# Le fichier era5_t2m_mensuel_cameroun.nc de datasets/ est le resultat fige de
# cette requete. Conserve comme trace de provenance.
#
# install.packages("ecmwfr")
# ecmwfr::wf_set_key(user = "123456", key = "xxxxxxxx-xxxx-xxxx", service = "cds")
#
# requete <- list(
#   dataset_short_name = "reanalysis-era5-single-levels-monthly-means",
#   product_type       = "monthly_averaged_reanalysis",
#   variable           = "2m_temperature",
#   year               = as.character(2015:2024),
#   month              = sprintf("%02d", 1:12),
#   time               = "00:00",
#   area               = c(13.1, 8.4, 1.6, 16.2),   # N, W, S, E (Cameroun)
#   data_format        = "netcdf",
#   target             = "era5_t2m_mensuel_cameroun.nc"
# )
#
# ecmwfr::wf_request(request = requete, transfer = TRUE, path = "datasets")

## ========================================================================
## 3.2 — OUVRIR LE NETCDF ET L'INTERROGER
## ========================================================================
# terra::rast() lit un NetCDF comme une PILE de couches : une couche = un mois.
era5_brut <- rast("datasets/era5_t2m_mensuel_cameroun.nc")

cat("Nombre de couches (pas de temps) :", nlyr(era5_brut), "\n")
cat("Dimensions (lignes x colonnes)   :", nrow(era5_brut), "x", ncol(era5_brut), "\n")
cat("Resolution                       :",
    paste(round(res(era5_brut), 4), collapse = " x "), "degres\n")
cat("CRS                              :", crs(era5_brut, describe = TRUE)$name, "\n")
cat("Emprise :\n")
print(ext(era5_brut))

cat("\nNoms des 6 premieres couches :\n")
print(head(names(era5_brut), 6))

# Les dates portees par les couches. Un NetCDF mal ecrit peut n'en porter
# aucune : on verifie avant de s'en servir.
dates_era5 <- as.Date(time(era5_brut))
cat("\nDates lisibles ?", !all(is.na(dates_era5)), "\n")
cat("Premiere couche :", format(min(dates_era5), "%Y-%m"), "\n")
cat("Derniere couche :", format(max(dates_era5), "%Y-%m"), "\n")
cat("Nombre de mois attendus :", nlyr(era5_brut),
    "| mois distincts :", length(unique(format(dates_era5, "%Y-%m"))), "\n")

# CONTROLE D'UNITE : l'ordre de grandeur trahit le Kelvin.
valeurs_couche1 <- values(era5_brut[[1]], na.rm = TRUE)
cat("\nCouche 1 -- min :", round(min(valeurs_couche1), 2),
    "| moyenne :", round(mean(valeurs_couche1), 2),
    "| max :", round(max(valeurs_couche1), 2), "\n")
cat("Ordre de grandeur ~300 => KELVIN. Ordre de grandeur ~25 => Celsius.\n")

## ========================================================================
## 3.3 — CONVERSION EN CELSIUS, DECOUPE NATIONALE
## ========================================================================
# a) KELVIN -> CELSIUS. Une soustraction, ecrite en clair et commentee : c'est
#    la ligne la plus facile a oublier de toute la journee.
era5_celsius <- era5_brut - 273.15

cat("Apres conversion -- couche 1 :\n")
v1 <- values(era5_celsius[[1]], na.rm = TRUE)
cat("  min :", round(min(v1), 2), "C | moyenne :", round(mean(v1), 2),
    "C | max :", round(max(v1), 2), "C\n")
cat("  Plausible pour le Cameroun ? (attendu : ~15 a ~40 C)\n")

# b) Contour national en SpatVector, dans le CRS du raster.
cat("\nCRS du raster :", crs(era5_celsius, describe = TRUE)$name, "\n")
cat("CRS de cmr0   :", st_crs(cmr0)$input, "\n")
cmr0_vect <- vect(st_transform(cmr0, crs(era5_celsius)))

# c) crop() reduit a l'emprise rectangulaire, mask() met a NA hors du polygone.
#    Les deux sont necessaires : crop seul laisserait le Nigeria et le Tchad.
era5_cmr <- mask(crop(era5_celsius, cmr0_vect), cmr0_vect)

cat("\nApres crop + mask :\n")
cat("  dimensions :", nrow(era5_cmr), "x", ncol(era5_cmr),
    "| couches :", nlyr(era5_cmr), "\n")
cat("  cellules non vides (couche 1) :",
    sum(!is.na(values(era5_cmr[[1]]))), "sur", ncell(era5_cmr), "\n")
cat("  -> une cellule ERA5 fait ~31 km de cote : le Cameroun entier tient en",
    sum(!is.na(values(era5_cmr[[1]]))), "cellules.\n")

# CONTROLE VISUEL OBLIGATOIRE apres tout decoupage. Une erreur de CRS ou
# d'emprise ne se voit pas dans les chiffres : elle se voit sur l'image.
plot(
  era5_cmr[[1]],
  main = paste("ERA5 T2m (degres C) --", format(dates_era5[1], "%Y-%m"))
)
plot(st_geometry(cmr1), add = TRUE, border = "grey30", lwd = 0.7)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- CONTROLE VISUEL DU RASTER DECOUPE
##
## Ce que la figure code : une cellule = la temperature moyenne de l'air a 2 m,
##   en degres Celsius, pour le mois affiche, sur une maille de ~31 km. Les
##   cellules blanches sont hors du polygone national (mises a NA par mask()).
## Ce que les choix techniques font : plot() de terra calcule ses bornes sur la
##   SEULE couche affichee. Deux mois traces separement N'ONT PAS la meme
##   echelle et ne se comparent pas a l'oeil. Acceptable pour un controle,
##   jamais pour une figure publiee -- d'ou l'echelle commune du Module 8.
## Ce qui se lit : que le decoupage a fonctionne (la forme du pays est
##   reconnaissable), que les valeurs sont plausibles, et que l'escalier des
##   cellules revele la vraie resolution : GROSSIERE.
## Ce qui ne se lit pas : aucune variation infra-cellulaire. Une cellule couvre
##   ~950 km2, ville et campagne confondues : la chaleur urbaine de Douala ou de
##   Yaounde n'existe pas dans ce fichier. Et une valeur reste une SORTIE DE
##   MODELE, pas un thermometre.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 4 — EXTRACTION ZONALE TEMPORELLE : DU RASTER A LA SERIE STATISTIQUE
## ##########################################################################

## ========================================================================
## 4.1 — exact_extract() SUR UNE PILE DE COUCHES
## ========================================================================
# exact_extract() calcule, pour chaque polygone, une statistique ponderee par la
# FRACTION de chaque cellule reellement couverte par le polygone. C'est ce qui
# le distingue de terra::extract() : une cellule a cheval sur deux regions n'est
# pas attribuee en entier a l'une des deux, elle est partagee. Sur une maille de
# 31 km et des regions de quelques centaines de kilometres, cette difference
# n'est PAS negligeable.

# a) Harmoniser les CRS -- et l'afficher.
cmr1_proj <- st_transform(cmr1, crs(era5_cmr))
cat("CRS du raster  :", crs(era5_cmr, describe = TRUE)$name, "\n")
cat("CRS des regions:", st_crs(cmr1_proj)$input, "\n")

# b) Extraction : une ligne par region, une colonne par couche (= par mois).
t2m_extrait <- exact_extract(era5_cmr, cmr1_proj, "mean", progress = FALSE)

cat("\nMatrice extraite :", nrow(t2m_extrait), "regions x",
    ncol(t2m_extrait), "mois\n")
cat("Coherence : regions attendues =", nrow(cmr1),
    "| couches attendues =", nlyr(era5_cmr), "\n")
cat("Valeurs manquantes dans la matrice :", sum(is.na(t2m_extrait)), "\n")
cat("Noms des 3 premieres colonnes extraites :",
    paste(head(names(t2m_extrait), 3), collapse = ", "), "\n")

## ----------------------------------------------------------------------
## POURQUOI UNE REGION PEUT RESSORTIR VIDE
##
## Une region dont aucune cellule n'est couverte renverrait NaN. Avec des
## cellules de 31 km, une petite region peut n'intersecter que partiellement une
## ou deux cellules : la moyenne existe alors, mais elle repose sur tres peu
## d'information. "Moyenne regionale" signifie ici "moyenne d'une poignee de
## cellules de 950 km2 chacune", pas "moyenne du territoire".
## ----------------------------------------------------------------------

## ========================================================================
## 4.2 — REMISE EN FORME LONGUE : LE PIEGE DES NOMS DE COUCHES
## ========================================================================
# PIEGE. exact_extract() nomme ses colonnes d'apres les couches du raster,
# prefixees "mean." : "mean.t2m_1", "mean.t2m_2"... Le suffixe n'est PAS
# forcement un entier utilisable tel quel, et l'ordre alphabetique des noms
# n'est PAS l'ordre chronologique ("t2m_10" < "t2m_2" en tri texte). On retrouve
# donc l'indice de chaque couche par match() sur names(era5_cmr), et la date par
# dates_era5[idx]. On ne devine jamais un indice a partir d'un nom de colonne.
t2m_long <- cmr1 |>
  st_drop_geometry() |>
  select(NAME_1) |>
  bind_cols(t2m_extrait) |>
  tidyr::pivot_longer(
    cols      = -NAME_1,
    names_to  = "couche",
    values_to = "t2m_celsius"
  ) |>
  mutate(
    idx   = match(couche, paste0("mean.", names(era5_cmr))),
    date  = dates_era5[idx],
    annee = as.integer(format(date, "%Y")),
    mois  = as.integer(format(date, "%m"))
  )

# CONTROLES : le match() a-t-il tout retrouve ?
cat("Lignes en forme longue :", nrow(t2m_long), "\n")
cat("Attendu (regions x mois) :", nrow(cmr1) * nlyr(era5_cmr), "\n")
cat("Couches non appariees par match() (idx = NA) :",
    sum(is.na(t2m_long$idx)), "\n")
cat("Dates manquantes :", sum(is.na(t2m_long$date)), "\n")
cat("Temperatures manquantes :", sum(is.na(t2m_long$t2m_celsius)), "\n")

t2m_long <- t2m_long |> select(-couche, -idx)

cat("\nApercu :\n")
print(head(t2m_long, 8))
cat("\nPlage des temperatures extraites :",
    round(min(t2m_long$t2m_celsius, na.rm = TRUE), 2), "a",
    round(max(t2m_long$t2m_celsius, na.rm = TRUE), 2), "degres C\n")

## ========================================================================
## 4.3 — SERIE NATIONALE ET TENDANCE LISSEE
## ========================================================================
t2m_national <- t2m_long |>
  group_by(date) |>
  summarise(t2m_moy = mean(t2m_celsius, na.rm = TRUE), .groups = "drop")

cat("Points de la serie nationale :", nrow(t2m_national), "mois\n")
cat("Periode :", format(min(t2m_national$date), "%Y-%m"), "a",
    format(max(t2m_national$date), "%Y-%m"), "\n")

graphe_t2m_serie <- ggplot(t2m_national, aes(x = date, y = t2m_moy)) +
  geom_line(colour = "#2171B5", linewidth = 0.7) +
  geom_smooth(method = "loess", se = TRUE, colour = "#CB181D",
              fill = "#FCBBA1", linetype = "dashed", linewidth = 0.9) +
  labs(
    title    = "Temperature de l'air a 2 m, moyenne mensuelle nationale",
    subtitle = paste("Source : ERA5 (reanalyse).",
                     "Ligne rouge : tendance LOESS, bande : intervalle de confiance."),
    x = "Date", y = "Temperature (degres C)"
  ) +
  theme_minimal()

print(graphe_t2m_serie)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- SERIE MENSUELLE ET LOESS
##
## Ce que la figure code : chaque point de la ligne bleue est la moyenne, sur
##   les dix regions, de la moyenne mensuelle de chaque region. C'est une
##   MOYENNE DE MOYENNES NON PONDEREE : chaque region pese pareil, quelle que
##   soit sa superficie ou sa population. Ce n'est ni la temperature moyenne du
##   Cameroun, ni celle que subit un Camerounais moyen.
## Ce que les choix techniques font : la courbe rouge est un LOESS -- une
##   regression polynomiale locale ponderee par la distance. Le parametre span
##   (0,75 par defaut) fixe la largeur du voisinage : grand = courbe lisse qui
##   peut effacer un vrai changement de regime ; petit = courbe qui suit le
##   bruit. LA COURBE N'EST PAS UN MODELE CLIMATIQUE : elle ne predit rien, ne
##   teste rien, elle resume visuellement. La bande rose est l'intervalle de
##   confiance a 95 % DE LA COURBE LISSEE (incertitude sur la position de la
##   moyenne locale), PAS l'etendue des valeurs observees.
## Ce qui se lit : la saisonnalite, tres marquee, qui domine tout le reste ; et
##   eventuellement une inflexion lente de la courbe rouge.
## Ce qui ne se lit pas : une tendance climatique. Dix ans de donnees mensuelles
##   sur un signal saisonnier fort ne permettent pas de conclure au
##   rechauffement : la convention est la NORMALE TRENTENAIRE. Dire "la
##   temperature augmente" a partir de cette figure serait une faute de methode
##   -- et le decideur retiendrait la phrase, pas la nuance.
## ----------------------------------------------------------------------

## ========================================================================
## 4.4 — SAISONNALITE : L'AMPLITUDE PLUTOT QUE LA MOYENNE
## ========================================================================
t2m_saisonnalite <- t2m_long |>
  group_by(mois) |>
  summarise(
    t2m_moy = mean(t2m_celsius, na.rm = TRUE),
    t2m_min = min(t2m_celsius, na.rm = TRUE),
    t2m_max = max(t2m_celsius, na.rm = TRUE),
    n_obs   = sum(!is.na(t2m_celsius)),
    .groups = "drop"
  ) |>
  mutate(amplitude = t2m_max - t2m_min)

print(t2m_saisonnalite)

graphe_saisonnalite <- ggplot(t2m_saisonnalite, aes(x = mois, y = t2m_moy)) +
  geom_ribbon(aes(ymin = t2m_min, ymax = t2m_max),
              fill = "#FDBB84", alpha = 0.4) +
  geom_line(colour = "#D94801", linewidth = 1) +
  geom_point(colour = "#D94801", size = 2) +
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  labs(
    title    = "Saisonnalite de la temperature a 2 m -- Cameroun",
    subtitle = "Ligne : moyenne du mois. Ruban : ETENDUE min-max (regions x annees).",
    x = "Mois", y = "Temperature (degres C)"
  ) +
  theme_minimal()

print(graphe_saisonnalite)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- SAISONNALITE ET RUBAN MIN/MAX
##
## Ce que la figure code : la ligne est la moyenne de toutes les valeurs
##   region x annee pour ce mois. Le ruban va du MINIMUM ABSOLU au MAXIMUM
##   ABSOLU observes pour ce mois, toutes regions et toutes annees confondues.
## Ce que les choix techniques font -- et c'est le point : un ruban min/max
##   n'est PAS un intervalle de confiance et PAS un ecart-type. Il melange deux
##   sources de variation que rien ne distingue a l'oeil : la variation
##   SPATIALE (l'Extreme-Nord n'est pas le Sud forestier) et la variation
##   INTERANNUELLE (2016 n'est pas 2022). Il est donc entierement gouverne par
##   les valeurs extremes : une seule cellule anormalement chaude, une seule
##   fois, elargit le ruban pour toujours. Un ruban interquartile serait
##   robuste ; un ruban +/-1 ecart-type parlerait de dispersion ; celui-ci parle
##   d'ENVELOPPE DES POSSIBLES. Trois rubans, trois questions.
## Ce qui se lit : le calendrier thermique, et surtout le fait que l'AMPLITUDE
##   n'est pas la meme selon les mois (colonne amplitude imprimee au-dessus).
## Ce qui ne se lit pas : quelle region produit le minimum et laquelle le
##   maximum. Le ruban est anonyme.
##
## EN QUOI LE SPATIAL EST UTILE ICI : ce graphique n'a de sens que parce que
## l'extraction zonale a preserve la dimension regionale. C'est l'ecart entre
## regions, mois par mois, qui remplit le ruban. Une moyenne nationale unique
## aurait produit une ligne sans ruban -- et masque que le pays vit, le meme
## mois, deux climats differents.
## ----------------------------------------------------------------------

## ========================================================================
## 4.5 — CARTE DE LA TEMPERATURE MOYENNE, ET EXPORTS
## ========================================================================
# mean() sur une pile terra : moyenne cellule a cellule sur toutes les couches.
t2m_moy_rast <- mean(era5_cmr)

cat("Raster moyen -- couches :", nlyr(t2m_moy_rast), "\n")
vm <- values(t2m_moy_rast, na.rm = TRUE)
cat("Moyenne pluriannuelle -- min :", round(min(vm), 2),
    "| moyenne :", round(mean(vm), 2),
    "| max :", round(max(vm), 2), "degres C\n")

carte_t2m_moy <- tm_shape(t2m_moy_rast) +
  tm_raster(
    col.scale  = tm_scale_continuous(values = "-brewer.rd_yl_bu"),
    col.legend = tm_legend(title = "T (degres C)")
  ) +
  tm_shape(cmr1) +
  tm_borders(col = "grey40", lwd = 0.8) +
  tm_shape(cmr0) +
  tm_borders(col = "grey10", lwd = 1.8) +
  tm_title("Temperature moyenne a 2 m -- Cameroun (ERA5)") +
  tm_layout(legend.outside = TRUE)

print(carte_t2m_moy)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- CARTE DE LA MOYENNE PLURIANNUELLE
##
## Ce que la figure code : la moyenne, sur toute la periode, de la temperature
##   mensuelle de chaque cellule de 31 km. Une seule valeur resume une centaine
##   de mois.
## Ce que les choix techniques font : "-brewer.rd_yl_bu" est une palette
##   DIVERGENTE dont le signe "-" inverse le sens pour que le rouge code le
##   chaud. Une palette divergente suppose un POINT DE REFERENCE au milieu :
##   elle raconte "plus chaud que / plus froid que", et non "beaucoup / peu".
##   Legitime pour une temperature, deplace pour un effectif d'evenements --
##   d'ou la palette sequentielle rouge du Module 2.
## Ce qui se lit : le gradient latitudinal et la marque du relief (l'Adamaoua et
##   l'ouest montagneux ressortent plus frais).
## Ce qui ne se lit pas : la variabilite. Deux cellules a 26 C de moyenne
##   peuvent avoir l'une 4 C et l'autre 14 C d'amplitude annuelle : la carte les
##   peint pareil. Une carte de l'ecart-type, a cote, dirait cela -- et serait
##   souvent plus utile a une politique d'adaptation.
##
## EN QUOI LE SPATIAL EST UTILE ICI : l'interet d'une reanalyse n'est pas la
## precision locale (un thermometre ferait mieux), c'est la COUVERTURE
## COMPLETE. Aucune zone blanche, alors que le reseau de stations au sol en
## laisse d'immenses. C'est cette completude qui permet de croiser le climat
## avec n'importe quelle autre couche sans qu'un territoire disparaisse.
## ----------------------------------------------------------------------

write_csv(t2m_long, "outputs/J10_era5_t2m_mensuel_regions.csv")
write_csv(t2m_national, "outputs/J10_era5_t2m_mensuel_national.csv")
write_csv(t2m_saisonnalite, "outputs/J10_era5_saisonnalite.csv")

writeRaster(t2m_moy_rast, "outputs/J10_era5_t2m_moyenne.tif", overwrite = TRUE)

ggsave("outputs/J10_era5_serie_nationale.png", graphe_t2m_serie,
       width = 10, height = 5, dpi = 180)
ggsave("outputs/J10_era5_saisonnalite.png", graphe_saisonnalite,
       width = 8, height = 5, dpi = 180)
tmap_save(carte_t2m_moy, "outputs/J10_era5_carte_t2m.png",
          width = 1400, height = 1600, dpi = 200)

cat("Exports ERA5 ecrits dans outputs/.\n")

## ##########################################################################
## MODULE 5 — UNE ENQUETE NE SUFFIT PAS : PLAN DE SONDAGE, ESTIMATION DIRECTE
## ##########################################################################

## ----------------------------------------------------------------------
## POURQUOI CETTE PARTIE CHANGE DE PAYS -- ET CE QUE CELA COUTE
##
## A partir d'ici, la journee quitte le Cameroun pour le BENIN. Il faut le dire
## aux participants, et dire pourquoi.
##
## LA RAISON TECHNIQUE. L'estimation sur petits domaines suppose une enquete
## dont on puisse calculer, domaine par domaine, une estimation directe ET sa
## variance d'echantillonnage reelle. Cela exige trois choses ensemble : les
## poids de sondage, l'identifiant de grappe, et une geolocalisation. L'extrait
## camerounais dont l'atelier dispose (ecam5.dta) echoue au controle de
## reference : son taux de pauvrete national colle au chiffre de l'INS (38,6 %
## contre 37,7 %), mais A L'INTERIEUR DES REGIONS il decroche -- l'Est y ressort
## a 7,5 % contre 41,5 % publie. C'est un extrait de formation, non
## representatif au niveau infraregional. Un exercice SAE construit dessus
## produirait des cartes magnifiques et des chiffres qu'il faudrait ensuite
## interdire de citer. Cartographier un chiffre faux lui donne exactement la
## meme autorite visuelle qu'un chiffre juste.
##
## CE QUE LE DEPLACEMENT COUTE, a assumer :
##  1. le fil rouge camerounais se rompt : impossible de relier cette carte aux
##     cartes ACLED et ERA5 du matin ;
##  2. le vocabulaire administratif change (communes beninoises, 77 unites) ;
##  3. les ordres de grandeur ne sont pas transposables. Ce qu'on apprend ici
##     est la METHODE, pas le diagnostic. Aucun chiffre de cette partie ne
##     decrit le Cameroun.
##
## CE QU'IL APPORTE : une chaine complete et EXECUTABLE -- plan de sondage
## reel, variance reelle, covariables disponibles a deux resolutions. Le
## participant repart avec un enchainement rejouable sur les donnees de son pays.
##
## PROVENANCE : donnees et code d'extraction adaptes du depot public
## github.com/JoshMerfeld/saereplication (J. Merfeld). Enquete source : EHCVM
## 2018-2019, Benin, microdonnees Banque mondiale (microdata.worldbank.org,
## catalogue 4291). Aucune licence n'etant indiquee sur le depot d'origine,
## l'usage est strictement pedagogique. METHODE ADAPTEE, NON REPRODUITE : le
## depot d'origine ajuste un modele UNITAIRE (EBP, package povmap, covariables
## selectionnees par Lasso valide croise) ; nous simplifions volontairement vers
## un modele D'AIRE (Fay-Herriot, package sae). Les coefficients et cartes
## obtenus ici ne reproduisent donc pas ceux du depot.
## ----------------------------------------------------------------------

## ========================================================================
## 5.1 — LES DONNEES BENINOISES
## ========================================================================
# a) Les menages enquetes. Une ligne = UN MENAGE (pas un individu).
menages <- read_csv("datasets/ehcvm2018_benin_menages.csv", show_col_types = FALSE)

cat("EHCVM Benin :", nrow(menages), "menages x", ncol(menages), "colonnes\n")
cat("Colonnes reelles :", paste(names(menages), collapse = ", "), "\n\n")

cat("Grappes distinctes (variable grappe) :", n_distinct(menages$grappe), "\n")
cat("Menages par grappe -- min :", min(table(menages$grappe)),
    "| median :", median(table(menages$grappe)),
    "| max :", max(table(menages$grappe)), "\n")
cat("Identifiants de cellule de grille distincts (id) :",
    n_distinct(menages$id), "\n")

# b) La variable d'interet : insecure. C'est une DECLARATION DE MENAGE.
cat("\ninsecure -- valeurs distinctes :",
    paste(sort(unique(menages$insecure)), collapse = ", "), "\n")
cat("insecure manquant :", sum(is.na(menages$insecure)), "\n")
cat("Part BRUTE (non ponderee) de menages en insecurite :",
    sprintf("%.2f %%", 100 * mean(menages$insecure, na.rm = TRUE)), "\n")

# c) Les poids de sondage.
cat("\nhhweight -- min :", round(min(menages$hhweight), 1),
    "| median :", round(median(menages$hhweight), 1),
    "| max :", round(max(menages$hhweight), 1), "\n")
cat("hhweight manquant ou nul :",
    sum(is.na(menages$hhweight) | menages$hhweight <= 0), "\n")
cat("Somme des poids (population de menages representee) :",
    format(round(sum(menages$hhweight)), big.mark = " "), "\n")

# d) Coordonnees des grappes (lat/lon) : presentes, mais DEPLACEES par le
#    producteur pour proteger l'anonymat des enquetes -- comme au DHS.
cat("\nCoordonnees -- lat de", round(min(menages$lat), 3), "a",
    round(max(menages$lat), 3),
    "| lon de", round(min(menages$lon), 3), "a",
    round(max(menages$lon), 3), "\n")
cat("Menages sans coordonnees :",
    sum(is.na(menages$lat) | is.na(menages$lon)), "\n")

# Limites communales et grille de 3 km. On liste les couches avant de les lire.
print(st_layers("datasets/gadm_ben_communes.gpkg"))
print(st_layers("datasets/benin_grille_3km.gpkg"))

ben_communes <- st_read("datasets/gadm_ben_communes.gpkg",
                        layer = "ben_adm2_communes", quiet = TRUE)
ben_grille   <- st_read("datasets/benin_grille_3km.gpkg",
                        layer = "grille_3km", quiet = TRUE)

cat("\nCommunes (admin2)        :", nrow(ben_communes),
    "| CRS :", st_crs(ben_communes)$input, "\n")
cat("Cellules de grille (3 km):", nrow(ben_grille),
    "| CRS :", st_crs(ben_grille)$input, "\n")
cat("\nChamps de ben_communes :", paste(names(ben_communes), collapse = ", "), "\n")
cat("Champs de ben_grille   :", paste(names(ben_grille), collapse = ", "), "\n")

# Cle des communes : admin2Pcod. Est-elle unique ? On verifie AVANT de joindre.
cat("\nadmin2Pcod distincts :", n_distinct(ben_communes$admin2Pcod),
    "sur", nrow(ben_communes), "communes -> cle unique ?",
    n_distinct(ben_communes$admin2Pcod) == nrow(ben_communes), "\n")

# Covariables geospatiales, aux DEUX resolutions : par commune (pour ajuster le
# modele) et par cellule de 3 km (pour la prediction fine du Module 9).
covariables_admin2 <- read_csv("datasets/benin_covariables_admin2.csv",
                               show_col_types = FALSE)
covariables_grille <- read_csv("datasets/benin_covariables_grille.csv",
                               show_col_types = FALSE)

cat("Covariables par commune :", nrow(covariables_admin2), "lignes x",
    ncol(covariables_admin2), "colonnes\n")
print(names(covariables_admin2))

cat("\nCovariables par cellule :", nrow(covariables_grille), "lignes x",
    ncol(covariables_grille), "colonnes\n")
print(names(covariables_grille))

# Les deux fichiers portent LES MEMES variables sous DES NOMS DIFFERENTS :
# suffixe "_adm2" par commune, sans suffixe par cellule. C'est volontaire (on ne
# confond pas les deux resolutions) et c'est un piege au Module 9 : la formule
# ajustee sur lc_13_urbain_adm2 doit etre appliquee a lc_13_urbain.
cat("\nCommunes couvertes par la grille :",
    n_distinct(covariables_grille$admin2Pcod), "\n")
cat("Cellules par commune -- min :", min(table(covariables_grille$admin2Pcod)),
    "| median :", median(table(covariables_grille$admin2Pcod)),
    "| max :", max(table(covariables_grille$admin2Pcod)), "\n")

## ----------------------------------------------------------------------
## CE QUE MESURE insecure, EXACTEMENT
##
## insecure vaut 1 si le menage a DECLARE avoir connu une situation
## d'insecurite alimentaire, 0 sinon. Trois precisions a donner en salle :
##  - c'est une DECLARATION, pas une mesure anthropometrique ni un releve de
##    consommation. Le meme menage, interroge par un autre enqueteur ou a une
##    autre saison, peut repondre autrement ;
##  - l'unite est le MENAGE, pas l'individu. 30 % de menages en insecurite ne
##    fait pas 30 % de la population : les menages touches n'ont pas la meme
##    taille moyenne que les autres. C'est le BIAIS DE TAILLE (au J05 : 6,55
##    personnes par menage calcule sur un fichier d'individus, 4,59 sur un
##    fichier de menages -- les deux exacts, deux questions differentes) ;
##  - la date compte : EHCVM 2018-2019. Cartographier cela en 2026 sans ecrire
##    l'annee sur la carte serait trompeur.
## ----------------------------------------------------------------------

## ========================================================================
## 5.2 — RATTACHER CHAQUE MENAGE A SA COMMUNE
## ========================================================================
# Le fichier menages ne porte PAS admin2Pcod : il porte id, l'identifiant de la
# cellule de grille de 3 km ou tombe la grappe. C'est le fichier des covariables
# de grille qui fait le pont id -> admin2Pcod.
table_id_commune <- covariables_grille |>
  select(id, admin2Pcod) |>
  distinct()

cat("Table de passage id -> commune :", nrow(table_id_commune), "lignes\n")
cat("id en double dans la table de passage :",
    sum(duplicated(table_id_commune$id)),
    " (doit valoir 0, sinon la jointure DUPLIQUE des menages)\n")

n_menages_avant <- nrow(menages)

menages_admin2 <- menages |>
  left_join(table_id_commune, by = "id")

cat("\nMenages avant jointure :", n_menages_avant, "\n")
cat("Menages apres jointure :", nrow(menages_admin2),
    "| duplications :", nrow(menages_admin2) - n_menages_avant, "\n")
cat("Menages sans commune (admin2Pcod NA) :",
    sum(is.na(menages_admin2$admin2Pcod)),
    sprintf("(%.2f %%)", 100 * mean(is.na(menages_admin2$admin2Pcod))), "\n")
cat("Communes representees dans l'enquete :",
    n_distinct(menages_admin2$admin2Pcod, na.rm = TRUE),
    "sur", nrow(ben_communes), "communes du pays\n")

## ----------------------------------------------------------------------
## LES COMMUNES ABSENTES DE L'ENQUETE SE VERRONT SUR LA CARTE
##
## Le compteur ci-dessus est a retenir pour le Module 8 : les communes qu'aucune
## grappe n'a touchees n'auront AUCUNE estimation, ni directe ni modelisee.
## Elles devront apparaitre en GRIS -- jamais a zero, jamais effacees.
## C'est le reperage de ce qui manque : un trou d'echantillonnage se voit sur
## une carte et JAMAIS dans un tableau, ou il se confond avec une ligne absente
## que personne ne cherche.
## ----------------------------------------------------------------------

## ========================================================================
## 5.3 — LE PLAN DE SONDAGE : POURQUOI UN ECHANTILLON N'EST PAS LA POPULATION
## ========================================================================
## ----------------------------------------------------------------------
## TROIS RAISONS DE NE PAS ECRIRE mean(insecure)
##
## 1. LES POIDS. Un menage de l'echantillon ne represente pas un menage du
##    pays, mais hhweight menages. Les plans d'enquete sur-echantillonnent
##    deliberement certaines strates. Sans les poids on decrit L'ECHANTILLON ;
##    avec les poids, LA POPULATION. Au J05 : 40,8 % sans poids, 38,6 % avec.
## 2. LES GRAPPES. L'EHCVM est un sondage A DEUX DEGRES : on tire des grappes,
##    puis des menages dedans. Deux menages de la meme grappe se ressemblent
##    plus que deux menages tires au hasard. Ignorer cette structure ne biaise
##    pas l'estimation ponctuelle, mais DIVISE ARTIFICIELLEMENT l'erreur-type :
##    on publie un intervalle deux fois trop etroit, donc une fausse certitude.
##    Pour le SAE ce serait fatal -- la variance est un INGREDIENT du modele.
## 3. LE BON POIDS A CHAQUE ETAGE : du menage a la grappe le poids de sondage,
##    de la grappe a la commune la somme des poids, de la commune au national la
##    population. Et la regle qui resume tout : LA MOYENNE D'UNE MOYENNE N'EST
##    PAS LA MOYENNE.
##
## svydesign() ne calcule rien. Il DECRIT le plan une fois pour toutes, pour que
## toutes les fonctions survey qui suivent en tiennent compte automatiquement.
## ----------------------------------------------------------------------

# DECLARATION DU PLAN DE SONDAGE.
#   ids     = ~grappe    : unite primaire de tirage (sondage a deux degres)
#   weights = ~hhweight  : poids de sondage du menage
# Aucune strate n'est declaree ici, faute d'identifiant de strate dans le
# fichier : l'erreur-type obtenue est donc legerement CONSERVATRICE.
plan_sondage <- svydesign(
  ids     = ~grappe,
  weights = ~hhweight,
  data    = menages_admin2
)

print(plan_sondage)

# COMPARAISON QUI JUSTIFIE TOUT LE MODULE : national, avec et sans poids.
moy_brute  <- 100 * mean(menages_admin2$insecure, na.rm = TRUE)
est_pondere <- svymean(~insecure, plan_sondage, na.rm = TRUE)

cat("\nInsecurite alimentaire au niveau national :\n")
cat("  moyenne BRUTE (sans poids, decrit l'ECHANTILLON) :",
    sprintf("%.2f %%", moy_brute), "\n")
cat("  moyenne PONDEREE (decrit la POPULATION)          :",
    sprintf("%.2f %%", 100 * coef(est_pondere)), "\n")
cat("  ecart                                            :",
    sprintf("%.2f point(s)", 100 * coef(est_pondere) - moy_brute), "\n")
cat("  erreur-type ponderee, plan pris en compte        :",
    sprintf("%.2f point(s)", 100 * SE(est_pondere)), "\n")

# Le meme calcul EN IGNORANT les grappes, pour mesurer l'effet de grappe.
plan_sans_grappe <- svydesign(ids = ~1, weights = ~hhweight, data = menages_admin2)
est_sans_grappe  <- svymean(~insecure, plan_sans_grappe, na.rm = TRUE)
cat("  erreur-type si l'on IGNORE les grappes           :",
    sprintf("%.2f point(s)", 100 * SE(est_sans_grappe)), "\n")
cat("  -> rapport (effet de grappe approche)            :",
    round(as.numeric(SE(est_pondere) / SE(est_sans_grappe)), 2), "\n")

## ----------------------------------------------------------------------
## LECTURE DES QUATRE CHIFFRES CI-DESSUS
##
## Ce qu'ils codent : le premier decrit les menages PRESENTS DANS LE FICHIER, le
##   deuxieme decrit LES MENAGES DU BENIN. Deux populations differentes ;
##   l'ecart mesure ce que la ponderation corrige.
## Ce que les choix techniques font : les 3e et 4e chiffres encadrent la meme
##   estimation sous deux hypotheses de plan. Leur rapport approche l'EFFET DE
##   GRAPPE : au-dessus de 1, la structure du plan coute de la precision.
## Ce qui se lit : qu'un chiffre d'enquete sans son plan de sondage n'est pas un
##   resultat, c'est une statistique descriptive de fichier.
## Ce qui ne se lit pas : la non-reponse. Les poids corrigent le tirage, pas les
##   menages qui n'ont pas repondu -- et ceux-la ne sont pas un echantillon
##   aleatoire des autres.
## ----------------------------------------------------------------------

## ========================================================================
## 5.4 — ESTIMATION DIRECTE PAR COMMUNE, ET VARIANCE NON ESTIMABLE
## ========================================================================
# svyby() applique svymean() SEPAREMENT a chaque commune, en respectant le plan.
# C'est l'equivalent d'un group_by() |> summarise(mean()) -- sauf que
# group_by()+mean() ignorerait poids ET grappes, et fournirait une erreur-type
# sous-estimee, c'est-a-dire inutilisable comme entree du modele.
direct_svy <- svyby(~insecure, ~admin2Pcod, plan_sondage, svymean, na.rm = TRUE)

cat("Communes avec une estimation directe :", nrow(direct_svy), "\n")

n_menages_admin2 <- menages_admin2 |>
  count(admin2Pcod, name = "n_menages")

n_grappes_admin2 <- menages_admin2 |>
  group_by(admin2Pcod) |>
  summarise(n_grappes = n_distinct(grappe), .groups = "drop")

direct_admin2 <- data.frame(
  admin2Pcod      = direct_svy$admin2Pcod,
  insecure_direct = coef(direct_svy) * 100,   # en POINTS DE POURCENTAGE
  se_direct       = SE(direct_svy) * 100
) |>
  left_join(n_menages_admin2, by = "admin2Pcod") |>
  left_join(n_grappes_admin2, by = "admin2Pcod")

cat("\nTaille d'echantillon par commune -- min :", min(direct_admin2$n_menages),
    "| median :", median(direct_admin2$n_menages),
    "| max :", max(direct_admin2$n_menages), "\n")
cat("Nombre de grappes par commune -- min :", min(direct_admin2$n_grappes),
    "| median :", median(direct_admin2$n_grappes),
    "| max :", max(direct_admin2$n_grappes), "\n")

# LE MOMENT DE METHODE : les communes a une seule grappe.
communes_1_grappe <- direct_admin2 |> filter(n_grappes == 1)
cat("\nCommunes n'ayant qu'UNE SEULE grappe enquetee :",
    nrow(communes_1_grappe), "\n")
cat("Communes dont l'erreur-type est NA ou nulle :",
    sum(is.na(direct_admin2$se_direct) | direct_admin2$se_direct == 0), "\n")

if (nrow(communes_1_grappe) > 0) {
  print(communes_1_grappe)
}

# On MEMORISE les exclues avant de les retirer : elles devront apparaitre en
# gris sur les cartes du Module 8, pas disparaitre.
communes_exclues <- direct_admin2 |>
  filter(is.na(se_direct) | se_direct == 0) |>
  pull(admin2Pcod)

direct_admin2 <- direct_admin2 |>
  filter(!is.na(se_direct), se_direct > 0) |>
  mutate(var_direct = se_direct^2)

cat("\nCommunes CONSERVEES pour le modele :", nrow(direct_admin2), "\n")
cat("Communes EXCLUES (variance non estimable) :", length(communes_exclues),
    ifelse(length(communes_exclues) > 0,
           paste0(" -> ", paste(communes_exclues, collapse = ", ")), ""), "\n")
cat("Communes du pays sans aucune estimation :",
    nrow(ben_communes) - nrow(direct_admin2), "sur", nrow(ben_communes), "\n")

cat("\nEstimation directe -- 10 communes les plus touchees :\n")
print(
  direct_admin2 |>
    arrange(desc(insecure_direct)) |>
    head(10)
)

## ----------------------------------------------------------------------
## POURQUOI UNE COMMUNE A UNE SEULE GRAPPE EST EXCLUE
##
## LE FAIT TECHNIQUE. Avec un sondage en grappes, la variance d'echantillonnage
## s'estime ENTRE LES GRAPPES, pas entre les menages. Avec une seule grappe, il
## n'y a rien entre quoi calculer une variance : survey renvoie NA, ou zero.
## Ce n'est pas un bug, c'est l'arithmetique -- on ne calcule pas une dispersion
## sur un seul point.
##
## POURQUOI CE N'EST PAS UNE COMMODITE. Le modele de Fay-Herriot prend la
## variance directe EN ENTREE (vardir). Une variance a zero declarerait au
## modele que l'estimation directe est PARFAITEMENT PRECISE : il la laisserait
## intacte et lui donnerait un poids infini par rapport aux communes bien
## mesurees. Une variance NA ferait echouer l'ajustement. Le seul traitement
## honnete est l'exclusion DECLAREE.
##
## CE QUE L'EXCLUSION COUTE. Ces communes sont typiquement les moins peuplees,
## les plus rurales, les plus eloignees -- pas un echantillon aleatoire des
## autres. Les retirer du MODELE est une necessite ; les faire disparaitre de la
## CARTE serait un mensonge par omission. Elles restent donc dans
## communes_exclues, et le Module 8 les affichera en gris.
##
## LE SEUIL EST DECLARE DANS LE CODE, pas subi : n_grappes == 1. Un projet
## operationnel pourrait le relever a 2 ou 3 grappes, ou a 30 menages --
## l'important est qu'il soit ecrit, justifie, et visible sur la carte.
## ----------------------------------------------------------------------

# La precision de l'estimation directe depend de la taille de l'echantillon.
# Ce graphe prepare le Module 7 : c'est LA relation que Fay-Herriot exploite.
graphe_precision <- ggplot(direct_admin2, aes(x = n_menages, y = se_direct)) +
  geom_point(colour = "#6A51A3", size = 2.2, alpha = 0.8) +
  scale_x_log10() +
  labs(
    title    = "Moins de menages enquetes, moins de precision",
    subtitle = "Chaque point = une commune. Erreur-type de l'estimation directe.",
    x = "Nombre de menages enquetes (echelle log)",
    y = "Erreur-type (points de pourcentage)"
  ) +
  theme_minimal()

print(graphe_precision)

cat("Correlation (log n_menages, se_direct) :",
    round(cor(log(direct_admin2$n_menages), direct_admin2$se_direct), 3), "\n")

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- PRECISION CONTRE TAILLE D'ECHANTILLON
##
## Ce que la figure code : en abscisse le nombre de menages enquetes dans la
##   commune, en ordonnee l'erreur-type de l'estimation directe. Un point haut =
##   une commune dont le chiffre est BRUITE.
## Ce que les choix techniques font : l'axe des abscisses est LOGARITHMIQUE --
##   le bon choix quand les valeurs s'etalent sur un ordre de grandeur. En
##   echelle lineaire, les communes les plus echantillonnees ecraseraient les
##   autres contre l'axe. Le log rend visible la partie du nuage qui nous
##   interesse au prix d'une deformation a annoncer : des ecarts egaux a l'ecran
##   ne sont pas des ecarts egaux en menages.
## Ce qui se lit : la decroissance attendue en 1/racine(n). C'est le PROBLEME
##   que le SAE vient resoudre : a droite l'enquete suffit, a gauche non.
## Ce qui ne se lit pas : que les communes de gauche seraient "mal enquetees".
##   Elles sont enquetees SELON LE PLAN, dimensionne pour des estimations
##   nationales et regionales. Le probleme n'est pas la qualite de l'enquete :
##   c'est qu'on lui pose une question a une maille pour laquelle elle n'a
##   jamais ete concue.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 6 — CHOISIR UNE COVARIABLE AUXILIAIRE
## ##########################################################################

## ----------------------------------------------------------------------
## CE QU'ON DEMANDE A UNE COVARIABLE
##
## Le modele de Fay-Herriot a besoin d'une information CONNUE PARTOUT -- y
## compris dans les communes mal enquetees -- et CORRELEE a ce qu'on cherche a
## estimer. C'est sa seule exigence, et elle est faible : la covariable n'a pas
## besoin d'etre une cause, elle doit seulement predire.
##
## Nos candidates viennent de Google Earth Engine et existent AUX DEUX
## RESOLUTIONS : par commune (pour ajuster) et par cellule de 3 km (pour
## predire, Module 9).
##
##   ntl_mean_adm2 ............ luminosite nocturne (VIIRS), proxy d'activite
##   population_adm2 .......... population totale estimee
##   ndvi_mean_adm2 ........... indice de vegetation, biomasse photosynthetique
##   precip_2018_adm2 ......... cumul de precipitations 2018
##   no2_adm2 ................. NO2 tropospherique, proxy trafic et industrie
##   lc_13_urbain_adm2 ........ part de sol urbain (MODIS LC_Type1, classe 13)
##   lc_12_cultures_adm2 ...... part de sol cultive (classe 12)
##   lc_8_savane_boisee_adm2 .. part de savane boisee (classe 8)
##   lc_11_zones_humides_adm2 . part de zones humides (classe 11)
##
## Ces covariables ne sont pas recalculees ici, mais leur fabrication ne
## demanderait rien de nouveau : c'est la statistique zonale deja pratiquee ce
## matin (st_join() pour ACLED, exact_extract() pour ERA5).
## ----------------------------------------------------------------------

# Joindre les estimations directes aux covariables communales.
n_avant_cov <- nrow(direct_admin2)

sae_data_candidates <- direct_admin2 |>
  left_join(covariables_admin2, by = "admin2Pcod")

cat("Communes avant jointure des covariables :", n_avant_cov, "\n")
cat("Communes apres :", nrow(sae_data_candidates),
    "| duplications :", nrow(sae_data_candidates) - n_avant_cov, "\n")

candidats <- c(
  "ntl_mean_adm2", "population_adm2", "ndvi_mean_adm2", "precip_2018_adm2",
  "no2_adm2", "lc_13_urbain_adm2", "lc_12_cultures_adm2",
  "lc_8_savane_boisee_adm2", "lc_11_zones_humides_adm2"
)

# CONTROLE : toutes les candidates existent-elles vraiment, et sans NA ?
cat("\nCandidates absentes du fichier :",
    paste(setdiff(candidats, names(sae_data_candidates)), collapse = ", "),
    "(vide = tout va bien)\n")
cat("Valeurs manquantes par covariable :\n")
print(colSums(is.na(sae_data_candidates[candidats])))

# CRIBLAGE : correlation de chaque candidate avec l'estimation directe.
correlations <- sapply(candidats, function(v) {
  cor(sae_data_candidates$insecure_direct, sae_data_candidates[[v]],
      use = "complete.obs")
})
correlations <- correlations[order(-abs(correlations))]

cat("\nCorrelation avec l'insecurite alimentaire directe,\n")
cat("triee par valeur absolue decroissante :\n")
print(round(correlations, 3))

# CONTROLE DE COLINEARITE : deux covariables tres correlees entre elles
# apportent la MEME information deux fois. Le modele les departage mal, leurs
# coefficients deviennent instables et peuvent changer de signe.
matrice_cor <- cor(sae_data_candidates[candidats], use = "complete.obs")

cat("Matrice de correlation entre candidates (arrondie) :\n")
print(round(matrice_cor, 2))

# Les paires problematiques, listees explicitement.
paires <- which(abs(matrice_cor) > 0.7 & upper.tri(matrice_cor), arr.ind = TRUE)
cat("\nPaires de covariables correlees a plus de 0,7 (en valeur absolue) :\n")
if (nrow(paires) == 0) {
  cat("  aucune\n")
} else {
  for (k in seq_len(nrow(paires))) {
    cat("  ", rownames(matrice_cor)[paires[k, 1]], "<->",
        colnames(matrice_cor)[paires[k, 2]], ":",
        round(matrice_cor[paires[k, 1], paires[k, 2]], 2), "\n")
  }
}

# DECISION : deux covariables retenues -- part urbaine et part de savane boisee.
cat("\nCorrelation entre les DEUX covariables retenues :",
    round(cor(sae_data_candidates$lc_13_urbain_adm2,
              sae_data_candidates$lc_8_savane_boisee_adm2,
              use = "complete.obs"), 3), "\n")

sae_data <- sae_data_candidates |>
  select(
    admin2Pcod, n_menages, n_grappes,
    insecure_direct, se_direct, var_direct,
    lc_13_urbain_adm2, lc_8_savane_boisee_adm2
  ) |>
  as.data.frame()

cat("\nTableau pret pour le modele :", nrow(sae_data), "communes x",
    ncol(sae_data), "colonnes\n")
cat("Lignes incompletes (NA sur une variable du modele) :",
    sum(!complete.cases(sae_data)), "\n")

## ----------------------------------------------------------------------
## LECTURE DU CRIBLAGE
##
## Ce qu'il code : une correlation de Pearson entre l'estimation directe et
##   chaque covariable, sur les communes retenues.
## Ce que les choix techniques font : Pearson mesure une association LINEAIRE
##   -- une relation en U parfaite donnerait une correlation nulle. Sur des
##   variables aussi dissymetriques que la luminosite nocturne ou la population,
##   un coefficient de SPEARMAN (sur les rangs) serait souvent plus honnete. Le
##   criblage par correlation est lui-meme une methode FAIBLE : il examine les
##   covariables une par une alors que le modele les utilisera ensemble. Un
##   projet operationnel selectionnerait par Lasso valide croise. Le seuil de
##   colinearite a 0,7 est CONVENTIONNEL, pas theorique : il declenche une
##   discussion, il ne tranche pas.
## Ce qui se lit : l'ordre des candidates, et surtout le SIGNE -- premier
##   element a confronter aux coefficients du modele au Module 7.
## Ce qui ne se lit pas, et c'est capital : aucune causalite. Avec 76 communes
##   et neuf candidates, on trouvera TOUJOURS quelque chose de correle. Que la
##   part de sol urbain predise l'insecurite alimentaire ne signifie pas que
##   l'urbanisation la cause : elle capte un faisceau (densite, prix,
##   dependance au marche, composition des menages). Pour le modele, cela
##   suffit. Pour une politique publique, non. LE MODELE EMPRUNTE DE LA FORCE,
##   IL N'EXPLIQUE RIEN.
## ----------------------------------------------------------------------

## ##########################################################################
## MODULE 7 — FAY-HERRIOT : EMPRUNTER DE LA FORCE AUX AUTRES COMMUNES
## ##########################################################################

## ----------------------------------------------------------------------
## LE MODELE, EN TROIS LIGNES
##
## Pour chaque commune i, l'enquete fournit une estimation directe p_i et sa
## variance d'echantillonnage psi_i, CONNUE. Fay et Herriot (1979) ecrivent :
##
##     p_i = x_i . beta + u_i + e_i,  u_i ~ N(0, sigma2_u), e_i ~ N(0, psi_i)
##
## Deux sources d'ecart y sont SEPAREES : e_i est l'erreur due au fait qu'on a
## enquete un echantillon (connue, c'est var_direct) ; u_i est ce qui, dans la
## commune, echappe aux covariables (estimee).
##
## L'estimateur EBLUP est une moyenne ponderee entre l'estimation directe et la
## prediction du modele, avec un poids qui depend du rapport des deux variances:
##  - variance d'echantillonnage GRANDE (petit echantillon) -> l'estimation est
##    tiree vers le modele : on "emprunte de la force" aux autres communes ;
##  - variance PETITE (grand echantillon) -> l'estimation directe est deja
##    fiable, le modele la corrige a peine.
##
## sae::mseFH() fait les deux en un appel : il ajuste le modele ET calcule
## l'EQM estimee de chaque prediction. C'est cette EQM, et non la seule valeur
## estimee, qui rend le resultat publiable.
## ----------------------------------------------------------------------

# AJUSTEMENT DU MODELE DE FAY-HERRIOT.
#   formula : estimation directe expliquee par les deux covariables retenues
#   vardir  : la variance d'echantillonnage CONNUE de chaque commune
#             (c'est elle qui distingue un modele SAE d'une simple regression)
fh <- mseFH(
  insecure_direct ~ lc_13_urbain_adm2 + lc_8_savane_boisee_adm2,
  vardir = var_direct,
  data   = sae_data
)

cat("Convergence de l'ajustement :", fh$est$fit$convergence, "\n")
cat("Nombre d'iterations :", fh$est$fit$iterations, "\n")
cat("Variance estimee des effets aleatoires (sigma2_u) :",
    round(fh$est$fit$refvar, 4), "\n")
cat("Variance d'echantillonnage moyenne (psi) :",
    round(mean(sae_data$var_direct), 4), "\n")
cat("-> Rapport sigma2_u / psi_moyen :",
    round(fh$est$fit$refvar / mean(sae_data$var_direct), 2), "\n")

cat("\nCoefficients du modele :\n")
print(fh$est$fit$estcoef)

cat("\nMesures d'ajustement (log-vraisemblance, AIC, BIC, KIC) :\n")
print(fh$est$fit$goodness)

## ----------------------------------------------------------------------
## LIRE LE TABLEAU DE COEFFICIENTS, SANS LE SURINTERPRETER
##
## Ce qu'il code : beta, std.error, tvalue, pvalue. beta est l'effet, en points
##   de pourcentage d'insecurite, d'une augmentation d'une unite de la
##   covariable. Ici les covariables sont des PARTS entre 0 et 1 : beta est donc
##   l'ecart attendu entre une commune a 0 % et une commune a 100 % de la classe
##   de sol concernee. Un ecart jamais observe : c'est une extrapolation de la
##   pente, pas une prediction.
## LE CONTROLE IMMEDIAT : le signe de chaque beta doit correspondre au signe de
##   la correlation du Module 6. Une inversion signale une COLINEARITE ou un
##   effet de confusion -- a investiguer, pas a ignorer.
## LE RAPPORT sigma2_u / psi imprime ci-dessus est la cle de tout ce qui suit.
##   Grand : l'heterogeneite reelle entre communes domine le bruit
##   d'echantillonnage, les estimations directes etaient deja bonnes, le modele
##   corrigera peu. Petit : le bruit domine, le lissage sera fort. UN GAIN MOYEN
##   MODESTE N'EST DONC PAS UN ECHEC DU MODELE : c'est une propriete de la
##   donnee, et il faut savoir le dire.
## Ce qui ne se lit pas : les pvalue. Avec 76 communes et deux covariables, la
##   puissance est faible ; une p-valeur negligeable ne fait pas d'une
##   correlation une cause. AIC/BIC/KIC n'ont AUCUN SENS EN VALEUR ABSOLUE : ce
##   sont des instruments de COMPARAISON entre specifications.
## ----------------------------------------------------------------------

# Recuperer l'EBLUP et l'EQM, puis passer en RMSE (racine de l'EQM) pour rester
# dans l'unite de la variable : des POINTS DE POURCENTAGE, comparables a
# l'erreur-type de l'estimation directe.
sae_data <- sae_data |>
  mutate(
    insecure_fh = fh$est$eblup[, 1],
    rmse_direct = sqrt(var_direct),
    rmse_fh     = sqrt(fh$mse),
    gain_rmse   = rmse_direct - rmse_fh,
    gain_pct    = 100 * gain_rmse / rmse_direct,
    deplacement = insecure_fh - insecure_direct
  )

cat("Gain de precision (RMSE direct - RMSE FH), en points :\n")
cat("  moyen  :", round(mean(sae_data$gain_rmse), 3), "\n")
cat("  median :", round(median(sae_data$gain_rmse), 3), "\n")
cat("  min    :", round(min(sae_data$gain_rmse), 3), "\n")
cat("  max    :", round(max(sae_data$gain_rmse), 3), "\n")
cat("Communes ou le gain est NEGATIF (FH moins precis) :",
    sum(sae_data$gain_rmse < 0), "sur", nrow(sae_data), "\n")
cat("Reduction relative moyenne du RMSE :",
    sprintf("%.1f %%", mean(sae_data$gain_pct)), "\n")

cat("\nDeplacement de l'estimation (FH - direct), en points :\n")
cat("  amplitude maximale :", round(max(abs(sae_data$deplacement)), 2), "\n")
cat("  ecart-type         :", round(sd(sae_data$deplacement), 2), "\n")

cat("\nLes 10 communes les plus corrigees par le modele :\n")
print(
  sae_data |>
    arrange(desc(abs(deplacement))) |>
    select(admin2Pcod, n_menages, n_grappes, insecure_direct, rmse_direct,
           insecure_fh, rmse_fh, gain_rmse, deplacement) |>
    head(10)
)

## ========================================================================
## 7.1 — COMPARAISON COMMUNE PAR COMMUNE
## ========================================================================
# Mettre en regard les deux estimations et leurs intervalles, commune par commune.
# pivot_longer avec names_pattern separe la VALEUR (insecure / rmse) de la
# METHODE (direct / fh) en une seule operation.
comparaison_long <- sae_data |>
  left_join(
    st_drop_geometry(ben_communes) |> select(admin2Pcod, adm2_name),
    by = "admin2Pcod"
  ) |>
  select(adm2_name, insecure_direct, rmse_direct, insecure_fh, rmse_fh) |>
  tidyr::pivot_longer(
    cols          = -adm2_name,
    names_to      = c(".value", "methode"),
    names_pattern = "(.*)_(direct|fh)"
  ) |>
  mutate(methode = recode(methode,
                          direct = "Estimation directe",
                          fh     = "Fay-Herriot (EBLUP)"))

cat("Lignes du tableau de comparaison :", nrow(comparaison_long),
    "(attendu : 2 x", nrow(sae_data), "=", 2 * nrow(sae_data), ")\n")
cat("Noms de commune manquants apres jointure :",
    sum(is.na(comparaison_long$adm2_name)), "\n")

graphe_comparaison <- ggplot(
  comparaison_long,
  aes(x = reorder(adm2_name, insecure), y = insecure,
      ymin = insecure - 1.96 * rmse, ymax = insecure + 1.96 * rmse,
      colour = methode)
) +
  geom_pointrange(position = position_dodge(width = 0.5), size = 0.25) +
  coord_flip() +
  scale_colour_manual(values = c("Estimation directe" = "#CB181D",
                                 "Fay-Herriot (EBLUP)" = "#2171B5")) +
  labs(
    title    = "Insecurite alimentaire par commune -- Benin",
    subtitle = "EHCVM 2018-2019. Barres : intervalles a 95 % (estimation +/- 1,96 x RMSE).",
    x = NULL, y = "Menages en insecurite alimentaire (%)", colour = NULL
  ) +
  theme_minimal(base_size = 8) +
  theme(legend.position = "top")

print(graphe_comparaison)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- DEUX ESTIMATIONS ET LEURS INTERVALLES
##
## Ce que la figure code : une ligne par commune, triee par niveau. Deux points
##   par commune (direct en rouge, EBLUP en bleu) ; la barre est l'intervalle a
##   95 %, construit comme estimation +/- 1,96 x RMSE.
## Ce que les choix techniques font : les deux barres NE SONT PAS DE MEME
##   NATURE. Cote direct, le RMSE est l'erreur-type d'echantillonnage --
##   interpretation frequentiste classique. Cote Fay-Herriot, c'est la racine de
##   l'EQM d'un PREDICTEUR, qui mele erreur d'echantillonnage, erreur de modele
##   et erreur d'estimation des parametres. Les superposer est utile et
##   legerement abusif : cela se dit a voix haute. Le facteur 1,96 suppose en
##   outre une normalite approximative, discutable pour une proportion proche de
##   0 ou de 1 (un intervalle sur l'echelle logit serait plus rigoureux). Le tri
##   par niveau fait apparaitre le gradient et empeche de reperer les communes
##   par leur geographie -- c'est ce que la carte du Module 8 ajoutera.
## Ce qui se lit : trois situations. Points confondus = le modele n'a rien
##   corrige. Points eloignes = estimation fortement tiree vers le modele
##   (verifier n_menages). Barre bleue plus courte = gain de precision visible.
## Ce qui ne se lit pas : laquelle des deux valeurs est "la vraie". Nous ne
##   connaissons pas la verite de terrain : nous comparons deux estimateurs,
##   l'un sans biais mais bruite, l'autre plus precis mais legerement biaise
##   vers le modele. C'est l'arbitrage biais-variance, sans solution universelle.
## ----------------------------------------------------------------------

## ========================================================================
## 7.2 — LE VRAI TEST DU MECANISME
## ========================================================================
## ----------------------------------------------------------------------
## LA FIGURE QUI DECIDE SI LE MODELE FONCTIONNE
##
## Le nuage ci-dessous n'est PAS une illustration de plus. C'est le test du
## mecanisme meme du SAE, et il faut le presenter comme tel.
##
## Le raisonnement : Fay-Herriot corrige d'autant plus que la variance
## d'echantillonnage est grande, et elle est grande LA OU L'ECHANTILLON EST
## PETIT. Donc : si le lissage fonctionne comme la theorie le prevoit, le gain
## de precision doit etre MAXIMAL A GAUCHE du nuage et tendre vers zero a droite.
##
## Trois lectures, trois conclusions :
##   courbe nettement DECROISSANTE ... le mecanisme opere : le modele aide la ou
##                                     l'enquete ne suffisait pas ;
##   courbe PLATE .................... les covariables n'apportent presque rien,
##                                     le modele recopie l'estimation directe ;
##   nuage SANS STRUCTURE, beaucoup
##   de points negatifs .............. specification a revoir (covariables mal
##                                     choisies, ou variances mal estimees).
##
## Un point isole sous zero reste possible et acceptable : il signale une
## commune que la covariable predit mal, sans que son echantillon soit assez
## petit pour que le lissage compense. Des points negatifs NOMBREUX ou TRES
## eloignes de zero sont, eux, un signal d'alarme.
## ----------------------------------------------------------------------

graphe_gain_n <- ggplot(sae_data, aes(x = n_menages, y = gain_rmse)) +
  geom_hline(yintercept = 0, colour = "grey40", linetype = "dotted") +
  geom_point(aes(size = n_grappes), colour = "#2171B5", alpha = 0.7) +
  geom_smooth(method = "loess", se = FALSE, colour = "#CB181D",
              linetype = "dashed") +
  scale_x_log10() +
  scale_size_continuous(range = c(1.5, 5), name = "Grappes") +
  labs(
    title    = "Le gain de precision se concentre dans les communes peu enquetees",
    subtitle = "Chaque point = une commune. C'est le test du mecanisme de Fay-Herriot.",
    x = "Nombre de menages enquetes (echelle log)",
    y = "Gain de precision (RMSE direct - RMSE Fay-Herriot), en points"
  ) +
  theme_minimal()

print(graphe_gain_n)

# Le meme test, en chiffres : gain moyen par tiers de taille d'echantillon.
sae_data <- sae_data |>
  mutate(tiers_n = cut(n_menages,
                       breaks = quantile(n_menages, probs = c(0, 1/3, 2/3, 1)),
                       include.lowest = TRUE,
                       labels = c("petit echantillon", "moyen", "grand")))

cat("Gain moyen de precision par tiers de taille d'echantillon :\n")
print(
  sae_data |>
    group_by(tiers_n) |>
    summarise(
      communes      = n(),
      n_menages_med = median(n_menages),
      gain_moyen    = round(mean(gain_rmse), 3),
      gain_pct_moy  = round(mean(gain_pct), 1),
      .groups = "drop"
    )
)

cat("\nCorrelation (log n_menages, gain_rmse) :",
    round(cor(log(sae_data$n_menages), sae_data$gain_rmse), 3),
    " -> NEGATIVE attendue\n")

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- GAIN DE PRECISION CONTRE TAILLE D'ECHANTILLON
##
## Ce que la figure code : en abscisse le nombre de menages enquetes (log), en
##   ordonnee rmse_direct - rmse_fh en points. La taille du point ajoute le
##   nombre de grappes : deux communes a effectif egal mais 2 ou 8 grappes n'ont
##   pas la meme variance directe.
## Ce que les choix techniques font : la ligne pointillee a zero est la
##   FRONTIERE DE DECISION -- au-dessus le modele apporte, en dessous il coute.
##   Le LOESS resume la tendance sans l'imposer, mais avec 76 points il est
##   sensible aux extremites du nuage : ne pas lire ses derniers centimetres. Le
##   tableau par tiers dit LA MEME CHOSE EN CHIFFRES, sans dependre du lissage :
##   c'est lui qui fait foi.
## Ce qui se lit : que le gain n'est pas reparti au hasard, il est STRUCTURE par
##   la taille de l'echantillon. C'est la signature du mecanisme, et la seule
##   preuve empirique que le modele fait ce qu'il pretend faire.
## Ce qui ne se lit pas : que les estimations lissees seraient plus JUSTES.
##   Elles sont plus PRECISES (variance plus faible) au prix d'un biais vers le
##   modele. Precision et justesse sont deux proprietes differentes ; le RMSE
##   les combine, il ne les separe pas. Une validation externe (recensement,
##   enquete independante) serait necessaire pour trancher.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 8 — TROIS CARTES A ECHELLE COMMUNE
## ##########################################################################

## ========================================================================
## 8.1 — JOINDRE LES ESTIMATIONS A LA GEOMETRIE, SANS EFFACER LES ABSENTES
## ========================================================================
# ON PART DE LA COUCHE : ben_communes |> left_join(sae_data).
# Toutes les communes du pays restent presentes, y compris celles qui n'ont
# aucune estimation. Un inner_join() les ferait disparaitre de la carte --
# c'est-a-dire du raisonnement.
communes_sae <- ben_communes |>
  left_join(sae_data, by = "admin2Pcod") |>
  mutate(
    statut = case_when(
      !is.na(insecure_fh)              ~ "Estimee",
      admin2Pcod %in% communes_exclues ~ "Exclue (une seule grappe)",
      TRUE                             ~ "Non enquetee"
    )
  )

cat("Communes de la couche :", nrow(communes_sae), "\n")
cat("Repartition des statuts :\n")
print(table(communes_sae$statut))

cat("\nCommunes SANS estimation Fay-Herriot :",
    sum(is.na(communes_sae$insecure_fh)), "\n")
cat("Elles resteront GRISES sur les cartes -- jamais a zero, jamais effacees.\n")

## ----------------------------------------------------------------------
## GRIS, ZERO, ABSENT : TROIS CHOSES DIFFERENTES
##
## Sur une choroplethe, trois situations sont visuellement confondues si l'on
## n'y prend pas garde :
##  - la commune ESTIMEE A UNE VALEUR FAIBLE : elle est mesuree, et elle va bien;
##  - la commune NON ENQUETEE : nous n'en savons rien ;
##  - la commune EXCLUE DU MODELE faute de variance estimable : l'enquete l'a
##    touchee, mais une seule fois -- nous avons un chiffre sans savoir combien
##    il vaut.
## Les colorer toutes les trois sur la meme echelle, ou remplacer les deux
## dernieres par zero, revient a publier de l'ignorance deguisee en mesure.
## Convention retenue : VALEUR EN COULEUR, ABSENCE EN GRIS, STATUT DANS LA
## LEGENDE. Le lecteur doit pouvoir distinguer "peu d'insecurite" de "pas de
## mesure" sans lire le code.
## ----------------------------------------------------------------------

## ========================================================================
## 8.2 — LES TROIS CARTES
## ========================================================================
# ECHELLE COMMUNE aux deux premieres cartes : sans cela, deux palettes calculees
# separement donneraient au meme niveau d'insecurite deux couleurs differentes,
# et la comparaison visuelle -- qui est TOUT l'objet de la figure -- serait
# fausse. C'est l'erreur la plus frequente des cartes comparatives.
limites_insecurite <- range(
  c(communes_sae$insecure_direct, communes_sae$insecure_fh),
  na.rm = TRUE
)
cat("Echelle commune imposee aux cartes 1 et 2 :",
    round(limites_insecurite[1], 2), "a", round(limites_insecurite[2], 2),
    "points de pourcentage\n")

# value.na / label.na : les communes SANS estimation sont peintes en gris et
# nommees dans la legende. Elles ne sont ni a zero, ni effacees.
carte_direct <- tm_shape(communes_sae) +
  tm_polygons(
    fill        = "insecure_direct",
    fill.scale  = tm_scale_continuous(values   = "brewer.blues",
                                      limits   = limites_insecurite,
                                      value.na = "grey85",
                                      label.na = "Sans estimation"),
    fill.legend = tm_legend(title = "Insecurite (%)"),
    col = "white", lwd = 0.4
  ) +
  tm_title("1. Estimation directe (enquete seule)")

carte_fh <- tm_shape(communes_sae) +
  tm_polygons(
    fill        = "insecure_fh",
    fill.scale  = tm_scale_continuous(values   = "brewer.blues",
                                      limits   = limites_insecurite,
                                      value.na = "grey85",
                                      label.na = "Sans estimation"),
    fill.legend = tm_legend(title = "Insecurite (%)"),
    col = "white", lwd = 0.4
  ) +
  tm_title("2. Estimation Fay-Herriot (EBLUP)")

carte_gain <- tm_shape(communes_sae) +
  tm_polygons(
    fill        = "gain_rmse",
    fill.scale  = tm_scale_continuous(values   = "-brewer.rd_bu",
                                      midpoint = 0,
                                      value.na = "grey85",
                                      label.na = "Non estimable"),
    fill.legend = tm_legend(title = "Gain de precision\n(points)"),
    col = "white", lwd = 0.4
  ) +
  tm_title("3. Gain de precision")

carte_sae <- tmap_arrange(carte_direct, carte_fh, carte_gain, ncol = 3)
print(carte_sae)

## ----------------------------------------------------------------------
## LECTURE DES TROIS CARTES
##
## Ce qu'elles codent : (1) ce que l'enquete dit toute seule, commune par
##   commune ; (2) ce qu'elle dit une fois lissee par le modele ; (3) la
##   reduction du RMSE, c'est-a-dire LE RESULTAT DU TRAVAIL STATISTIQUE, pas le
##   phenomene.
## Ce que les choix techniques font : les cartes 1 et 2 partagent une echelle
##   IMPOSEE (limits) -- c'est ce qui autorise a les comparer du regard.
##   brewer.blues est SEQUENTIELLE : elle code une quantite ordonnee, ce qui
##   convient a un taux. La carte 3 utilise une palette DIVERGENTE centree sur
##   zero (midpoint = 0) : ici zero est un seuil qualitatif (le modele aide / le
##   modele coute), et une divergente est le seul choix correct. Une
##   sequentielle sur la carte 3 masquerait le signe.
## Ce qui se lit : l'ECART entre les cartes 1 et 2 est plus informatif que
##   chacune prise isolement -- c'est la qu'on voit OU le modele est intervenu.
##   Et la carte 3 dit POURQUOI : le gain doit se concentrer sur les memes
##   communes que celles qui bougent entre 1 et 2 (coherence a verifier a voix
##   haute).
## Ce qui ne se lit pas : une carte lisse n'est pas une carte juste. Le lissage
##   rend la carte 2 plus reguliere que la carte 1, et l'oeil interprete
##   spontanement la regularite comme de la qualite. C'est un artefact du
##   modele, pas une propriete du territoire.
##
## EN QUOI LE SPATIAL EST UTILE ICI : le tableau du Module 7 donnait deja les
## valeurs. La carte ajoute deux choses. D'abord la CONTIGUITE : si les communes
## fortement corrigees se touchent, l'echantillonnage a ete deficient sur une
## zone entiere, pas au hasard -- defaut de plan de sondage, pas de commune.
## Ensuite le REPERAGE DES TROUS : les communes grises forment-elles un bloc ?
## Si oui, tout un territoire est absent du diagnostic national, et c'est une
## information de politique publique en soi.
## ----------------------------------------------------------------------

write_csv(sae_data, "outputs/J10_sae_estimations_communes.csv")
write_csv(
  data.frame(admin2Pcod = communes_exclues),
  "outputs/J10_sae_communes_exclues.csv"
)
st_write(communes_sae, "outputs/J10_sae_communes.gpkg",
         delete_dsn = TRUE, quiet = TRUE)

ggsave("outputs/J10_sae_comparaison.png", graphe_comparaison,
       width = 8, height = 12, dpi = 180)
ggsave("outputs/J10_sae_gain_vs_echantillon.png", graphe_gain_n,
       width = 8, height = 5, dpi = 180)
ggsave("outputs/J10_sae_precision_vs_taille.png", graphe_precision,
       width = 8, height = 5, dpi = 180)
tmap_save(carte_sae, "outputs/J10_sae_cartes_communes.png",
          width = 2400, height = 1000, dpi = 200)

cat("Exports SAE ecrits dans outputs/.\n")


## ##########################################################################
## MODULE 9 — PRECISION N'EST PAS RESOLUTION
## ##########################################################################

## ----------------------------------------------------------------------
## DEUX PROBLEMES DISTINCTS, UNE MEME SOLUTION -- ET UNE CONFUSION A EVITER
##
## C'est le meilleur moment pedagogique de la journee. Prendre le temps.
##
## PROBLEME 1 -- LA PRECISION. L'estimation directe est bruitee la ou
## l'echantillon est petit. Fay-Herriot la lisse en empruntant de la force a un
## modele. Resultat : un chiffre plus fiable, mais TOUJOURS UN CHIFFRE PAR
## COMMUNE. La resolution geographique n'a pas bouge d'un metre (Modules 7-8).
##
## PROBLEME 2 -- LA RESOLUTION. Meme parfaitement precis, un chiffre par commune
## reste une moyenne sur toute sa superficie. Une commune de 800 km2 peut
## contenir une ville dense et de vastes zones rurales vides, et l'enquete ne
## dit RIEN de cette variation interne.
##
## LA MEME SOLUTION APPLIQUEE AUX DEUX. La covariable, elle, varie EN CONTINU
## dans l'espace : elle est connue pour chaque cellule de 3 km. On peut donc
## appliquer la relation ajustee a l'echelle communale a chaque cellule, et
## obtenir une surface plus fine que l'enquete elle-meme.
##
## LA CONFUSION A INTERDIRE : ce n'est PAS UNE NOUVELLE MESURE. C'est une
## EXTRAPOLATION DU MODELE a l'interieur de chaque commune. Rien n'a ete observe
## a 3 km. La carte qui suit est la plus impressionnante de la journee, et la
## moins mesuree.
##
## Noter enfin que cette grille de 3 km n'a RIEN A VOIR avec les grilles de
## population a 100 m vues au J08 (WorldPop, GHS-POP) : la-bas, 100 m est la
## resolution d'un produit derive d'imagerie ; ici 3 km est un choix
## d'extraction des covariables sur Google Earth Engine. Deux grilles, deux
## significations.
## ----------------------------------------------------------------------

## ========================================================================
## 9.1 — RECONSTRUIRE L'EFFET ALEATOIRE ET PREDIRE
## ========================================================================
# a) Recuperer les coefficients ajustes au niveau COMMUNE.
betas     <- fh$est$fit$estcoef[, "beta"]
beta0     <- betas["(Intercept)"]
beta_lc13 <- betas["lc_13_urbain_adm2"]
beta_lc8  <- betas["lc_8_savane_boisee_adm2"]

cat("Coefficients ajustes :\n")
cat("  intercept                :", round(beta0, 3), "\n")
cat("  part urbaine (lc_13)     :", round(beta_lc13, 3), "\n")
cat("  savane boisee (lc_8)     :", round(beta_lc8, 3), "\n")

# b) Reconstruire l'effet aleatoire de commune u_hat par difference :
#    u_hat = EBLUP - partie expliquee par les covariables.
#    C'est ce qui, dans la commune, echappe aux covariables : contexte local,
#    marches, histoire, variables omises. Il est CONSTANT dans la commune.
sae_data <- sae_data |>
  mutate(
    partie_fixe = beta0 +
      beta_lc13 * lc_13_urbain_adm2 +
      beta_lc8  * lc_8_savane_boisee_adm2,
    u_hat = insecure_fh - partie_fixe
  )

cat("\nEffet aleatoire u_hat -- moyenne :", round(mean(sae_data$u_hat), 3),
    "| ecart-type :", round(sd(sae_data$u_hat), 3),
    "| etendue :", round(min(sae_data$u_hat), 2), "a",
    round(max(sae_data$u_hat), 2), "\n")
cat("Part de la variation de l'EBLUP portee par u_hat plutot que par les\n")
cat("covariables (ecart-type u_hat / ecart-type EBLUP) :",
    round(sd(sae_data$u_hat) / sd(sae_data$insecure_fh), 2), "\n")

# c) Appliquer la formule a CHAQUE CELLULE.
#    PIEGE DE NOMMAGE : les colonnes de la grille n'ont PAS le suffixe _adm2.
#    lc_13_urbain_adm2 (commune) <-> lc_13_urbain (cellule).
cat("\nColonnes de covariables cote grille :",
    paste(intersect(names(covariables_grille),
                    c("lc_13_urbain", "lc_8_savane_boisee")), collapse = ", "),
    "\n")

n_cellules_total <- nrow(covariables_grille)

grille_pred <- covariables_grille |>
  left_join(sae_data |> select(admin2Pcod, u_hat), by = "admin2Pcod") |>
  mutate(
    insecure_pred = beta0 +
      beta_lc13 * lc_13_urbain +
      beta_lc8  * lc_8_savane_boisee +
      u_hat
  )

cat("\nCellules totales :", n_cellules_total, "\n")
cat("Cellules sans u_hat (commune exclue ou non enquetee) :",
    sum(is.na(grille_pred$u_hat)),
    sprintf("(%.1f %%)", 100 * mean(is.na(grille_pred$u_hat))), "\n")

grille_pred <- grille_pred |> filter(!is.na(u_hat))

cat("Cellules predites :", nrow(grille_pred), "sur", n_cellules_total, "\n")
cat("Prediction -- min :", round(min(grille_pred$insecure_pred), 2),
    "| median :", round(median(grille_pred$insecure_pred), 2),
    "| max :", round(max(grille_pred$insecure_pred), 2), "\n")

# CONTROLE INDISPENSABLE : une proportion predite peut sortir de [0, 100].
# Le modele est lineaire, rien ne l'en empeche. On COMPTE, on ne tronque pas
# en silence.
cat("Cellules predites HORS de l'intervalle [0, 100] :",
    sum(grille_pred$insecure_pred < 0 | grille_pred$insecure_pred > 100), "\n")

## ----------------------------------------------------------------------
## TROIS CONTROLES QUE CETTE PREDICTION IMPOSE
##
## 1. LES CELLULES SANS u_hat. Une commune exclue du modele (une seule grappe)
##    ou jamais enquetee n'a pas d'effet aleatoire : ses cellules ne peuvent pas
##    etre predites. Le compteur dit combien de territoire disparait de la carte
##    finale. Ce chiffre doit figurer dans toute presentation du resultat.
## 2. LES VALEURS HORS BORNES. Le modele est lineaire et la variable est une
##    proportion : rien n'interdit mathematiquement -4 % ou 112 %. Les tronquer
##    silencieusement embellirait la carte tout en dissimulant que le modele est
##    extrapole hors de son domaine de validite. On les compte, on les montre.
## 3. L'EFFET ALEATOIRE EST CONSTANT DANS LA COMMUNE. u_hat ne varie pas d'une
##    cellule a l'autre : TOUTE la variation interne visible sur la carte vient
##    des covariables. Autrement dit, la carte de grille montre exactement la
##    geographie de la part de sol urbain et de savane boisee, translatee et
##    mise a l'echelle. Si les participants ne retiennent qu'une phrase du
##    module, c'est celle-la.
## ----------------------------------------------------------------------

## ========================================================================
## 9.2 — LA CARTE LA PLUS IMPRESSIONNANTE, ET LA MOINS MESUREE
## ========================================================================
n_grille_avant <- nrow(ben_grille)

grille_sae <- ben_grille |>
  inner_join(grille_pred |> select(id, insecure_pred), by = "id")

cat("Cellules de la couche :", n_grille_avant, "\n")
cat("Cellules cartographiees :", nrow(grille_sae),
    sprintf("(%.1f %%)", 100 * nrow(grille_sae) / n_grille_avant), "\n")
cat("Cellules perdues a la jointure geometrique :",
    nrow(grille_pred) - nrow(grille_sae), "\n")

carte_grille <- tm_shape(grille_sae) +
  tm_fill(
    fill        = "insecure_pred",
    fill.scale  = tm_scale_continuous(values = "brewer.blues",
                                      limits = limites_insecurite),
    fill.legend = tm_legend(title = "Insecurite alim.\nPREDITE (%)")
  ) +
  tm_shape(ben_communes) +
  tm_borders(col = "grey20", lwd = 0.6) +
  tm_title("Prediction du modele a l'echelle de la grille de 3 km") +
  tm_layout(legend.outside = TRUE)

print(carte_grille)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- ET L'AVERTISSEMENT QUI DOIT L'ACCOMPAGNER
##
## Ce que la figure code : chaque cellule de 3 km porte une valeur PREDITE par
##   un modele ajuste sur 76 communes, a partir de deux variables d'occupation
##   du sol et d'un effet aleatoire communal constant. Aucune de ces valeurs n'a
##   ete observee. Ce n'est pas une mesure a 3 km : c'est la formule du modele,
##   evaluee en 15 000 points.
## Ce que les choix techniques font : l'echelle de couleurs est LA MEME que
##   celle des cartes communales -- c'est delibere, et c'est ce qui permet de
##   dire "la meme valeur donne la meme couleur". Le rendu fin et continu est
##   esthetiquement superieur a la choroplethe, et c'est precisement le danger :
##   LA FINESSE GRAPHIQUE SE LIT SPONTANEMENT COMME DE LA FINESSE DE MESURE. Le
##   contour des communes est maintenu par-dessus pour rappeler l'unite a
##   laquelle le modele a reellement ete ajuste.
## Ce qui se lit : a l'interieur d'une commune, la geographie des COVARIABLES,
##   traduite en niveaux d'insecurite. Et, entre communes, les sauts brusques
##   aux frontieres : ce sont les u_hat, discontinus par construction. Ces
##   discontinuites sont un aveu du modele -- elles montrent ou il s'arrete.
## Ce qui ne se lit pas : aucune variation infra-communale reellement mesuree ;
##   aucune incertitude (la carte n'affiche pas d'EQM, et il n'en existe pas de
##   simple a ce niveau) ; aucun menage. PRECISION N'EST PAS RESOLUTION : le
##   Module 7 a ameliore la precision, ce module a augmente la resolution, et ce
##   sont deux operations sans rapport. Une carte peut etre tres fine et tres
##   fausse -- c'est meme la combinaison la plus dangereuse, parce que la plus
##   convaincante.
##
## LA PHRASE A FAIRE ECRIRE EN LEGENDE : "Valeurs predites par un modele ajuste
## sur 76 communes -- non mesurees a cette resolution."
## ----------------------------------------------------------------------

write_csv(
  grille_pred |> select(id, admin2Pcod, insecure_pred),
  "outputs/J10_sae_estimations_grille.csv"
)
st_write(grille_sae, "outputs/J10_sae_grille.gpkg",
         delete_dsn = TRUE, quiet = TRUE)
tmap_save(carte_grille, "outputs/J10_sae_carte_grille.png",
          width = 1600, height = 1600, dpi = 200)

cat("Exports de la grille ecrits dans outputs/.\n")
cat("\nTous les fichiers produits par la journee :\n")
print(list.files("outputs"))

## ##########################################################################
## MODULE 10 — ACCESSIBILITE AUX SERVICES : LA JOURNEE REVIENT AU TERRAIN
## ##########################################################################

## ----------------------------------------------------------------------
## MODULE NON EXECUTE -- RAISON TECHNIQUE
##
## TOUT LE CODE DE CE MODULE EST COMMENTE. Ce n'est pas un choix pedagogique,
## c'est un constat materiel : les deux fichiers dont il depend,
## datasets/DS.geojson (200 districts sanitaires) et datasets/gadm41_CMR_2.shp
## (58 departements, avec ses annexes .shx .dbf .prj .cpg), ne font pas partie du
## socle distribue par defaut. Le code redevient executable des que les deux
## fichiers rejoignent datasets/ : il suffit de le decommenter. Point de controle
## consigne dans _A_FAIRE_J10.md.
##
## DEUXIEME RAISON, INDEPENDANTE. Le materiel d'origine construisait ses
## isochrones autour des coordonnees lues dans CMGC72FL.csv. Or ce fichier ne
## contient AUCUNE coordonnee : c'est le fichier des 130 covariables
## contextuelles par grappe DHS. Les positions sont dans CMGE71FL.shp. Le code
## d'origine etait donc faux, et il aurait echoue meme avec toutes les donnees
## presentes. La version ci-dessous est reecrite sur une autre base (10.2).
## ----------------------------------------------------------------------

## ========================================================================
## 10.1 — POURQUOI CE MODULE RESTE DANS LA JOURNEE
## ========================================================================
## ----------------------------------------------------------------------
## DE LA MESURE A LA DECISION
##
## Les neuf modules precedents produisent des DIAGNOSTICS : ou sont les
## evenements, ou il fait chaud, ou l'insecurite alimentaire est forte. Un
## diagnostic n'est pas encore une politique publique. L'accessibilite fait le
## pas suivant : elle transforme une geographie en QUESTION D'ALLOCATION.
## Combien de personnes vivent a plus de 15 km d'un service ? Ou ouvrir la
## prochaine structure ? Quel gain de couverture en attendre ?
##
## C'est le seul module de la journee dont le resultat s'ecrit directement en
## termes de decision -- et c'est pour cela qu'il est conserve alors meme que
## ses donnees manquent.
##
## LE VOCABULAIRE, D'ABORD. Un ISOCHRONE est une courbe reliant les points
## atteignables en un MEME TEMPS de trajet. Ce que nous calculons ci-dessous
## n'en est pas un : ce sont des TAMPONS DE DISTANCE EUCLIDIENNE (5, 10, 15 km a
## vol d'oiseau). La difference n'est pas un detail de langage : un tampon
## ignore le relief, les cours d'eau, l'etat des pistes, la saison des pluies et
## l'absence de pont. En montagne ou en mangrove, deux points a 5 km a vol
## d'oiseau peuvent demander une demi-journee. Un vrai isochrone passe par un
## reseau routier et un moteur de routage (osrm, OpenRouteService).
## ----------------------------------------------------------------------

## ========================================================================
## 10.2 — CHARGEMENT DES COUCHES (BLOC DE REFERENCE, NON EXECUTE)
## ========================================================================
# sf_use_s2(FALSE) : DS.geojson compte 135 geometries invalides sur 200. Le
# moteur spherique s2 refuse ce que le moteur planaire GEOS accepte. On repasse
# donc en planaire ET on repare a la lecture. Cela n'autorise PAS a mesurer sur
# des degres : toute distance ci-dessous passe par une reprojection en UTM.
#
# sf::sf_use_s2(FALSE)
#
# districts <- st_read("datasets/DS.geojson", quiet = TRUE) |>
#   st_make_valid()
#
# cat("Districts sanitaires :", nrow(districts), "\n")
# cat("Champs disponibles :", paste(names(districts), collapse = ", "), "\n")
# cat("CRS :", st_crs(districts)$input, "\n")
# cat("Geometries valides apres reparation :",
#     sum(st_is_valid(districts)), "sur", nrow(districts), "\n")
#
# ATTENTION AUX NOMS DE CHAMPS. Ce fichier ne porte ni NomDS ni CodeDS : ses
# champs sont "name" et "parentName", prefixes. Le code d'origine interrogeait
# nom_ds / code_ds -- des colonnes qui n'existent pas. On adapte donc APRES
# avoir lu names(districts) ci-dessus.
#
# departements <- st_read("datasets/gadm41_CMR_2.shp", quiet = TRUE) |>
#   st_make_valid()
# cat("\nDepartements (GADM niveau 2) :", nrow(departements), "\n")
#
# MESURER EXIGE DE REPROJETER : EPSG:4326 est en degres, une superficie calculee
# dessus n'a aucun sens. UTM 33N (EPSG:32633) pour le Cameroun.
#
# districts_utm <- st_transform(districts, 32633)
# districts_utm <- districts_utm |>
#   mutate(superficie_km2 = as.numeric(st_area(geometry)) / 1e6)
#
# cat("Superficie des districts (km2) :\n")
# print(summary(districts_utm$superficie_km2))
#
# CONTROLE PAR REFERENCE EXTERNE : la somme doit approcher les 475 442 km2
# officiels du Cameroun. Un ecart de plus de quelques pour cent signale une
# mauvaise projection ou des trous dans le decoupage.
#
# cat("\nSuperficie totale calculee :",
#     format(round(sum(districts_utm$superficie_km2)), big.mark = " "), "km2\n")
# cat("Superficie officielle du Cameroun : 475 442 km2\n")
# cat("Ecart relatif :",
#     sprintf("%.1f %%",
#             100 * (sum(districts_utm$superficie_km2) - 475442) / 475442), "\n")

## ========================================================================
## 10.3 — POINTS DE SERVICE ET TAMPONS DE DISTANCE (NON EXECUTE)
## ========================================================================
# HYPOTHESE DE TRAVAIL, A ENONCER EN SALLE. Nous ne disposons pas d'un
# repertoire geolocalise des formations sanitaires. Nous utilisons le CENTROIDE
# de chaque district sanitaire comme point de service approche : le chef-lieu
# presume du district.
#
# Ce n'est PAS un hopital. Un centroide de polygone peut tomber en pleine foret,
# ou hors du polygone lui-meme s'il est concave. La carte produite mesure donc
# "la distance au centre geometrique du district", pas "la distance au service"
# -- approximation acceptable pour enseigner la methode, jamais pour dimensionner
# une politique. Avec un repertoire reel (SNIS, HeRAMS, healthsites.io), la meme
# chaine de code donne un resultat exploitable.
#
# points_service <- st_centroid(districts_utm)
# cat("Points de service (centroides de district) :", nrow(points_service), "\n")
#
# Tampons de 5, 10 et 15 km, unis en une seule geometrie par distance.
# buffer_5km  <- st_union(st_buffer(points_service, dist =  5000))
# buffer_10km <- st_union(st_buffer(points_service, dist = 10000))
# buffer_15km <- st_union(st_buffer(points_service, dist = 15000))
#
# Anneaux EXCLUSIFS : sans le st_difference(), les zones se superposeraient et
# la carte compterait deux fois les memes territoires.
# anneau_5_10  <- st_difference(buffer_10km, buffer_5km)
# anneau_10_15 <- st_difference(buffer_15km, buffer_10km)
#
# pays_utm  <- st_union(districts_utm)
# hors_15km <- st_difference(pays_utm, buffer_15km)
#
# Bilan surfacique, en km2 et en part du territoire.
# surf <- function(g) as.numeric(st_area(g)) / 1e6
# surf_totale <- surf(pays_utm)
#
# bilan_acces <- data.frame(
#   zone = c("moins de 5 km", "5 a 10 km", "10 a 15 km", "plus de 15 km"),
#   km2  = c(surf(buffer_5km), surf(anneau_5_10),
#            surf(anneau_10_15), surf(hors_15km))
# ) |>
#   mutate(part_pct = round(100 * km2 / surf_totale, 1))
#
# print(bilan_acces)
# cat("\nSuperficie de controle :", round(sum(bilan_acces$km2)),
#     "km2 contre", round(surf_totale), "km2 pour le pays entier\n")

## ----------------------------------------------------------------------
## SUPERFICIE COUVERTE N'EST PAS POPULATION COUVERTE
##
## Le tableau ci-dessus mesure des KILOMETRES CARRES. Une politique publique se
## decide sur des HABITANTS. Les deux divergent fortement : les zones eloignees
## de tout service sont generalement les moins peuplees, si bien qu'une
## couverture territoriale mediocre peut correspondre a une couverture
## demographique tres correcte -- ou l'inverse.
##
## Le bloc suivant fait donc la seule chose defendable : il PONDERE PAR LA
## POPULATION. Cas d'ecole de la regle "dire de quoi on prend la moyenne".
## Publier "38 % du territoire est a plus de 15 km d'un service" a la place de
## "12 % de la population est a plus de 15 km d'un service" n'est pas une
## approximation : c'est une autre affirmation, sur un autre sujet.
## ----------------------------------------------------------------------

# Population non couverte, par intersection ponderee par la superficie.
# HYPOTHESE FORTE ET FAUSSE, mais explicite : la population est supposee
# REPARTIE UNIFORMEMENT dans chaque district. Elle ne l'est jamais.
# La bonne methode, vue au J08, est de croiser les tampons avec une GRILLE DE
# POPULATION (WorldPop 100 m) par exact_extract() : la population est alors
# prise la ou elle est reellement. Ce module montre la methode approchee pour
# rendre visible ce qu'elle coute.
#
# districts_pop <- districts_utm |>
#   mutate(
#     zone_non_couverte  = st_difference(geometry, buffer_5km),
#     part_non_couverte  = as.numeric(st_area(zone_non_couverte)) /
#                          as.numeric(st_area(geometry))
#   )
#
# cat("Part moyenne de superficie a plus de 5 km d'un point de service :",
#     sprintf("%.1f %%", 100 * mean(districts_pop$part_non_couverte)), "\n")
# cat("Districts entierement au-dela de 5 km :",
#     sum(districts_pop$part_non_couverte > 0.99), "\n")

## ========================================================================
## 10.4 — CARTE DE COUVERTURE (NON EXECUTEE)
## ========================================================================
# Carte en quatre zones exclusives, du vert (proche) au rouge (eloigne). Les
# couleurs sont ORDONNEES : echelle sequentielle deguisee en categories, ce qui
# est legitime ici puisque les classes de distance sont ordonnees.
# Retour en WGS84 pour l'AFFICHAGE seulement -- les MESURES ont ete faites en UTM.
#
# en_wgs <- function(g) st_sf(geometry = st_transform(g, 4326))
#
# carte_acces <- tm_shape(en_wgs(pays_utm)) +
#   tm_borders(col = "black", lwd = 2) +
#   tm_shape(en_wgs(hors_15km)) +
#   tm_polygons(fill = "#D73027", fill_alpha = 0.75, col = NA) +
#   tm_shape(en_wgs(anneau_10_15)) +
#   tm_polygons(fill = "#FC8D59", fill_alpha = 0.75, col = NA) +
#   tm_shape(en_wgs(anneau_5_10)) +
#   tm_polygons(fill = "#FEE08B", fill_alpha = 0.75, col = NA) +
#   tm_shape(en_wgs(buffer_5km)) +
#   tm_polygons(fill = "#1A9850", fill_alpha = 0.65, col = NA) +
#   tm_shape(st_transform(points_service, 4326)) +
#   tm_dots(fill = "#004529", size = 0.15) +
#   tm_add_legend(
#     type   = "polygons",
#     fill   = c("#1A9850", "#FEE08B", "#FC8D59", "#D73027"),
#     labels = c("moins de 5 km", "5 a 10 km", "10 a 15 km", "plus de 15 km"),
#     title  = "Distance a vol d'oiseau\nau centre du district"
#   ) +
#   tm_title("Couverture theorique des services de sante -- Cameroun") +
#   tm_layout(legend.outside = TRUE)
#
# tmap_save(carte_acces, "outputs/J10_accessibilite_sante.png",
#           width = 1600, height = 1800, dpi = 200)
# print(carte_acces)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- CARTE DE COUVERTURE (a commenter meme non rendue)
##
## Ce que la figure code : quatre classes de distance EUCLIDIENNE a un point de
##   service approche par un centroide de district. Pas un temps de trajet, pas
##   une distance routiere, pas une accessibilite reelle.
## Ce que les choix techniques font : les anneaux sont EXCLUSIFS -- sans
##   st_difference(), les tampons se superposeraient et les surfaces se
##   compteraient plusieurs fois. Les seuils 5/10/15 km sont conventionnels et
##   se justifient par le mode de deplacement (marche, deux-roues, vehicule) :
##   ils doivent etre DECLARES, car deplacer un seuil de 5 a 8 km change
##   entierement le message. La palette vert-jaune-rouge est ordonnee et
##   lisible, mais elle PORTE UN JUGEMENT : le rouge signale un manque -- c'est
##   l'intention ici, ce serait deplace sur une carte descriptive.
## Ce qui se lit : la geographie du manque, et son caractere CONTIGU. Les zones
##   mal couvertes forment des blocs, pas un semis : c'est ce qui les rend
##   actionnables -- on n'ouvre pas un service par commune isolee, on couvre une
##   zone.
## Ce qui ne se lit pas : le relief, la saison, l'etat des pistes, l'existence
##   d'un pont, le cout du transport, les horaires, la disponibilite du
##   personnel et des medicaments. Une structure ouverte sans personnel produit
##   la meme tache verte qu'un hopital de reference. Limite fondamentale de
##   toute carte d'accessibilite geometrique : elle mesure la DISTANCE, pas
##   l'ACCES.
##
## EN QUOI LE SPATIAL EST UTILE ICI : de facon decisive. La question posee --
## "qui est loin de quoi ?" -- n'a AUCUNE formulation tabulaire. Un tableau
## d'effectifs par district ne peut pas repondre, parce que la reponse depend de
## la position relative de deux couches. C'est le cas le plus net de la journee
## ou la carte n'est pas une illustration du resultat : elle EST le calcul.
## ----------------------------------------------------------------------


## ##########################################################################
## FIN DE JOURNEE — RECAPITULATIF, GLOSSAIRE, EXERCICES, PROLONGEMENTS
## ##########################################################################

## ========================================================================
## CE QUE LA JOURNEE A ETABLI, MODULE PAR MODULE
## ========================================================================
recapitulatif <- data.frame(
  module = 1:10,
  titre = c(
    "ACLED : lire une base d'evenements",
    "Du point au polygone : la jointure qui echoue en silence",
    "ERA5 : ouvrir un NetCDF, convertir les Kelvin",
    "Extraction zonale temporelle",
    "Plan de sondage et estimation directe (Benin)",
    "Choisir une covariable auxiliaire",
    "Fay-Herriot : EBLUP, EQM, gain de precision",
    "Trois cartes a echelle commune",
    "Precision n'est pas resolution",
    "Accessibilite aux services (non execute)"
  ),
  piege_enseigne = c(
    "un evenement est un fait RAPPORTE, pas verifie",
    "libelles FR non accentues contre libelles EN : NA silencieux",
    "Kelvin ; une difference de temperature ne trahit pas l'unite",
    "les noms de couches ne se trient pas dans l'ordre chronologique",
    "sans poids on decrit l'echantillon ; une grappe unique = variance nulle",
    "correlation n'est pas causalite ; colinearite",
    "un gain moyen faible n'est pas un echec du modele",
    "deux cartes a echelles differentes ne se comparent pas",
    "une carte fine n'est pas une carte mesuree",
    "distance euclidienne n'est pas accessibilite"
  )
)
print(recapitulatif)

## ----------------------------------------------------------------------
## GLOSSAIRE -- STATISTIQUE D'ENQUETE
##
## PLAN DE SONDAGE : les regles selon lesquelles l'echantillon a ete tire
##   (strates, degres, probabilites d'inclusion). A declarer (svydesign()) avant
##   tout calcul, sinon toutes les erreurs-types sont fausses.
## POIDS DE SONDAGE (hhweight) : nombre d'unites de la population que represente
##   une unite de l'echantillon. Sans lui, on decrit l'echantillon.
## GRAPPE : unite primaire de tirage, typiquement une zone de denombrement. Les
##   unites d'une meme grappe se ressemblent ; l'ignorer donne des erreurs-types
##   artificiellement petites.
## EFFET DE GRAPPE : rapport entre la variance obtenue avec le plan reel et
##   celle d'un tirage aleatoire simple de meme taille.
## ESTIMATION DIRECTE : estimation calculee dans un domaine a partir des seules
##   observations de ce domaine, ponderees. Sans biais, mais bruitee.
## ERREUR-TYPE : ecart-type de l'estimateur -- l'incertitude due au fait qu'on a
##   enquete un echantillon plutot que toute la population.
## BIAIS DE TAILLE : parcourir un fichier d'individus surrepresente les grands
##   menages. Statistiques par individu et par menage : deux questions.
## NON-REPONSE : les poids corrigent le tirage, pas la non-reponse.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## GLOSSAIRE -- ESTIMATION SUR PETITS DOMAINES
##
## PETIT DOMAINE : unite pour laquelle l'enquete n'a pas ete dimensionnee.
##   "Petit" qualifie l'echantillon, pas la superficie.
## MODELE DE FAY-HERRIOT (1979) : modele D'AIRE -- il travaille sur les
##   estimations agregees par domaine et leur variance.
## MODELE UNITAIRE (Battese-Harter-Fuller, EBP) : modele sur les observations
##   individuelles. Plus riche, plus exigeant. C'est celui du depot d'origine.
## EBLUP : le predicteur du modele -- moyenne ponderee entre estimation directe
##   et prediction du modele, avec un poids gouverne par le rapport des
##   variances.
## EMPRUNTER DE LA FORCE : pour un domaine mal enquete, utiliser l'information
##   des autres domaines via le modele.
## EQM / MSE : mesure d'incertitude de l'EBLUP (erreur d'echantillonnage +
##   erreur de modele + erreur d'estimation des parametres). Sa racine, le RMSE,
##   s'exprime dans l'unite de la variable.
## vardir : la variance d'echantillonnage CONNUE de chaque domaine, fournie en
##   entree. C'est elle qui distingue un modele SAE d'une regression ordinaire.
## EFFET ALEATOIRE DE DOMAINE (u_hat) : ce qui, dans un domaine, echappe aux
##   covariables. Constant a l'interieur, discontinu aux frontieres.
## ARBITRAGE BIAIS-VARIANCE : l'EBLUP est plus precis mais legerement biaise
##   vers le modele. Precision et justesse sont deux proprietes distinctes.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## GLOSSAIRE -- DONNEES EVENEMENTIELLES
##
## EVENEMENT (au sens ACLED) : un fait RAPPORTE par au moins une source, code
##   selon une typologie, date et localise. Ni verifie, ni exhaustif.
## geo_precision : 1 lieu precis / 2 ville la plus proche / 3 region. Sur une
##   carte de points, les trois se ressemblent.
## time_precision : 1 jour connu / 2 semaine / 3 mois.
## BIAIS DE COUVERTURE MEDIATIQUE : la base mesure conjointement le phenomene et
##   l'activite des sources. Un territoire sans presse produit peu d'evenements.
## SENTINELLE : valeur conventionnelle codant une absence (-9999, 99, ou des
##   coordonnees (0,0)). A recoder en NA AVANT tout calcul.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## GLOSSAIRE -- REANALYSE CLIMATIQUE
##
## REANALYSE : reconstruction d'un etat atmospherique passe par un modele
##   contraint par les observations disponibles. Ni observation, ni prevision.
## ERA5 : reanalyse de l'ECMWF, ~31 km, depuis 1940, via le Copernicus CDS.
## NetCDF : format de tableau multidimensionnel (lon x lat x temps). Lu par
##   terra::rast() comme une pile de couches ; les dates sont dans time().
## KELVIN : unite native ERA5. T_C = T_K - 273,15. Une DIFFERENCE de
##   temperatures a la meme valeur dans les deux unites -- ce qui rend l'oubli de
##   conversion indetectable sur les anomalies.
## NORMALE CLIMATIQUE : moyenne sur trente ans. Dix ans ne suffisent pas a
##   etablir une tendance.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## GLOSSAIRE -- VOCABULAIRE SPATIAL ET CARTOGRAPHIQUE
##
## CRS : ce qui donne un sens aux nombres d'une geometrie. EPSG:4326 est en
##   DEGRES (aucune mesure de distance ou de superficie n'y est valide) ;
##   EPSG:32633 (UTM 33N) est en metres, adapte au Cameroun.
## st_within : predicat spatial -- le point est-il a l'interieur du polygone ?
##   Une jointure spatiale n'utilise aucun libelle, donc ne souffre ni des
##   accents ni des langues.
## exact_extract() : statistique zonale PONDEREE PAR LA FRACTION de cellule
##   couverte. Sur une maille grossiere, tres different d'une extraction par
##   centroide.
## DISCRETISATION : quantiles (contraste garanti, seuils arbitraires),
##   intervalles egaux (seuils lisibles, classes parfois vides), Jenks (ruptures
##   naturelles, seuils non comparables d'une carte a l'autre).
## PALETTE sequentielle / divergente / qualitative : une quantite ordonnee ; un
##   ecart de part et d'autre d'une reference ; des categories sans ordre.
## MAUP : les resultats dependent de la maille (effet d'echelle) et du trace des
##   limites (effet de zonage). On agrege a la maille de la decision.
## ERREUR ECOLOGIQUE : attribuer a un individu ce qui n'est vrai que de
##   l'agregat. Risque permanent de la choroplethe.
## ISOCHRONE : courbe des points atteignables en un meme temps de trajet. A ne
##   pas confondre avec un TAMPON de distance euclidienne.
## PRECISION (faible variance) n'est pas RESOLUTION (finesse de la maille). Une
##   carte peut etre tres resolue et tres imprecise.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## FONCTIONS CLES DE LA JOURNEE
##
## read_csv() ............ readr ......... verifier le separateur : une colonne
##                                         unique = erreur silencieuse
## st_read/st_layers() ... sf ............ ne jamais deviner le nom d'une couche
## st_as_sf() ............ sf ............ coords = c(longitude, latitude) !
## st_crs/st_transform() . sf ............ mesurer exige de reprojeter
## st_join(st_within) .... sf ............ compter les lignes avant/apres
## st_make_valid() ....... sf ............ reparer a la lecture
## st_buffer/difference() sf ............. anneaux exclusifs, sinon double compte
## left_join() ........... dplyr ......... partir de la couche ; compter les NA
## replace_na() .......... tidyr ......... legitime apres jointure SPATIALE,
##                                         dangereux apres jointure par libelle
## pivot_longer() ........ tidyr ......... names_pattern separe valeur et methode
## rast() ................ terra ......... verifier nlyr, res, time et l'UNITE
## crop() + mask() ....... terra ......... les deux sont necessaires
## exact_extract() ....... exactextractr . harmoniser les CRS d'abord
## svydesign() ........... survey ........ ne calcule rien, conditionne tout
## svymean/svyby() ....... survey ........ erreur-type reelle, entree du SAE
## mseFH() ............... sae ........... charger sae AVANT dplyr
## tm_polygons/tm_scale_* tmap ........... API 4 ; imposer limits pour comparer
## tmap_arrange() ........ tmap .......... inutile si les echelles different
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## EXERCICES -- CHACUN PORTE UN PIEGE NOMME
##
## EX. 1 -- LE PIEGE DE LA JOINTURE PAR LIBELLE (Module 2)
##   Agregez les evenements par admin2 (departements ACLED) et joignez-les a la
##   couche ADM_ADM_2 par le libelle. Comptez les NA, puis les orphelins.
##   QUESTION DE METHODE : le taux d'echec sera-t-il plus eleve ou plus faible
##   qu'au niveau regional ? Formulez l'hypothese AVANT de lancer le code. Les
##   noms de departements sont-ils traduits par GADM, ou repris tels quels ? Un
##   left_join peut echouer pour deux raisons -- la langue et l'orthographe --
##   qui ne se corrigent pas de la meme facon.
##
## EX. 2 -- LE PIEGE DU MAUP (Modules 2 et 6)
##   Refaites l'agregation par st_within sur les DEPARTEMENTS (58 unites).
##   Meme choroplethe, meme discretisation.
##   QUESTION DE METHODE : les 5 unites les plus touchees appartiennent-elles
##   aux 5 regions les plus touchees ? Calculez la correlation entre nombre
##   d'evenements et superficie aux deux mailles. Laquelle des deux cartes
##   presenteriez-vous a un ministre, et avec quelle note de bas de page ?
##
## EX. 3 -- LE PIEGE DE L'UNITE (Module 3)
##   Calculez, par region, l'ANOMALIE de temperature (moyenne de la derniere
##   annee moins moyenne de la periode) une fois sur era5_brut (Kelvin), une
##   fois sur era5_cmr (Celsius).
##   QUESTION DE METHODE : pourquoi les deux resultats sont-ils identiques ?
##   Quelle consequence sur la detectabilite d'un oubli de conversion ?
##   Construisez un calcul ou l'oubli SERAIT visible.
##
## EX. 4 -- LE PIEGE DE LA MOYENNE NON PONDEREE (Modules 4 et 5)
##   Recalculez la serie nationale en ponderant chaque region par sa superficie
##   (st_area() apres reprojection en UTM).
##   QUESTION DE METHODE : de combien les deux series different-elles ? Laquelle
##   repond a "quelle est la temperature moyenne du territoire ?" et laquelle a
##   "quelle est la temperature moyenne d'une region ?" Quelle troisieme
##   ponderation pour "quelle temperature subit un Camerounais moyen ?", et ou
##   trouver la donnee ?
##
## EX. 5 -- LE PIEGE DE LA VARIANCE NON ESTIMABLE (Module 5)
##   Retirez les communes de MOINS DE TROIS grappes au lieu d'une seule.
##   Reajustez le modele.
##   QUESTION DE METHODE : combien de communes perdez-vous ? Le gain moyen
##   augmente-t-il ou diminue-t-il, et pourquoi ? La carte devient-elle plus
##   fiable, ou simplement plus vide ? Redigez en trois lignes la note
##   methodologique qui l'accompagnerait.
##
## EX. 6 -- LE PIEGE DE LA COLINEARITE (Modules 6 et 7)
##   Ajustez un modele a UNE seule covariable (lc_13_urbain_adm2), puis un
##   troisieme avec les deux covariables les plus correlees ENTRE ELLES.
##   QUESTION DE METHODE : comparez AIC et BIC des trois modeles -- et rappelez
##   pourquoi ces valeurs n'ont de sens qu'en comparaison. Les coefficients du
##   troisieme changent-ils de signe ? Que signifierait une telle inversion ?
##
## EX. 7 -- LE PIEGE DE LA RESOLUTION (Module 9)
##   Calculez, pour chaque commune, l'ECART-TYPE des valeurs predites de ses
##   cellules, puis cartographiez-le.
##   QUESTION DE METHODE : que mesure cette carte -- l'heterogeneite interne
##   reelle, ou celle des covariables ? Une commune a ecart-type nul est-elle
##   homogene, ou simplement couverte par une seule classe d'occupation du sol ?
##   Formulez sa legende honnete.
##
## EX. 8 -- LE PIEGE DE LA POPULATION UNIFORME (Module 10)
##   (A faire quand DS.geojson sera disponible, ou en le transposant a un
##   decoupage present dans datasets/.) Refaites le calcul de population non
##   couverte en croisant les tampons avec une GRILLE DE POPULATION (WorldPop
##   100 m, J08) par exact_extract(fun = "sum").
##   QUESTION DE METHODE : de combien les deux estimations different-elles ?
##   Dans quel sens l'hypothese d'uniformite se trompe-t-elle, et pourquoi cette
##   direction n'est-elle pas aleatoire ?
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## PROLONGEMENTS VERS J11
##
## VERS LA RESTITUTION. Les trois familles de donnees du jour se pretent a trois
## registres d'argumentation : l'evenementiel raconte une DYNAMIQUE, la
## reanalyse installe un CONTEXTE, l'enquete modelisee fournit un CIBLAGE. Le
## J11 travaille l'assemblage des trois en un argumentaire chiffre, et la
## maniere de dire l'incertitude sans se faire oublier.
##
## TROIS COMPETENCES REUTILISABLES DANS LES MINI-PROJETS :
##  1. la chaine evenement -> polygone -> carte, applicable a toute base
##     geolocalisee (structures sanitaires, ecoles, incidents, prix de marche,
##     points d'eau). Le piege de la jointure par libelle s'y reproduira ;
##  2. la chaine enquete -> estimation directe -> modele -> carte, ossature
##     d'une carte de pauvrete, de scolarisation ou d'acces a l'eau a maille
##     fine. Trois ingredients : les poids, les grappes, une covariable connue
##     partout ;
##  3. le vocabulaire de l'incertitude (RMSE, EQM, intervalle, taille
##     d'echantillon, commune non estimable) : ce qui distingue une carte
##     defendable en reunion d'une carte a retirer des la premiere question.
##
## TROIS EXTENSIONS TECHNIQUES APRES L'ATELIER :
##  - ISOCHRONES REELS par reseau routier (osrm, OpenRouteService), pour
##    remplacer les tampons euclidiens du Module 10 ;
##  - MODELE UNITAIRE (povmap, EBP) au lieu du modele d'aire, quand on dispose
##    des microdonnees et d'un recensement ;
##  - AUTOCORRELATION SPATIALE : ajouter un effet aleatoire spatialement correle
##    au modele de Fay-Herriot (SFH), pour que deux communes voisines
##    s'informent mutuellement -- prolongement naturel du constat que les cartes
##    du Module 8 montrent des blocs contigus.
##
## UNE QUESTION A EMPORTER. Toutes les cartes de cette journee viennent de
## donnees que quelqu'un d'autre a construites : ACLED code des depeches, ERA5
## fait tourner un modele, l'EHCVM interroge des menages selon un plan. Avant de
## presenter l'une de ces cartes, la question n'est jamais "est-elle jolie ?"
## mais "QU'EST-CE QUI A ETE MESURE, PAR QUI, SUR QUOI, ET QUE RESTE-T-IL NON
## MESURE ?"
## ----------------------------------------------------------------------

cat("=== FIN DE LA JOURNEE J10 ===\n\n")
cat("Sorties produites dans outputs/ :", length(list.files("outputs")), "fichiers\n")
print(list.files("outputs"))
cat("\nSession :\n")
cat("  R          :", R.version.string, "\n")
cat("  sf         :", as.character(packageVersion("sf")), "\n")
cat("  terra      :", as.character(packageVersion("terra")), "\n")
cat("  tmap       :", as.character(packageVersion("tmap")),
    ifelse(packageVersion("tmap") >= "4.0.0", "(API 4, OK)",
           "(ATTENTION : API 3, les cartes echoueront)"), "\n")
cat("  survey     :", as.character(packageVersion("survey")), "\n")
cat("  sae        :", as.character(packageVersion("sae")), "\n")




