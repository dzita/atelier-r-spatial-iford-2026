## ============================================================================
## SCRIPT ETUDIANT -- CORRIGE COMPLET
## J10 -- LES DONNEES SPATIALES AU SERVICE DES POLITIQUES PUBLIQUES
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Jeudi 6 aout 2026
##
## CE FICHIER EST LE CORRIGE de script_etudiant_J10.R : il contient le code
## complet des emplacements marques ">>> A COMPLETER" dans la trame, dans le
## meme ordre et avec les memes commentaires. Il est distribue EN FIN DE
## JOURNEE. Son contenu est identique a celui de script_formateur_J10.R.
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
# aucune variable de repertoire recomposee, aucun sous-dossier.
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
  "|   |-- script_formateur_J10.R",
  "|   |-- script_etudiant_J10.R         <- trame a trous",
  "|   `-- script_etudiant_J10_corrige.R <- CE fichier",
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
## outputs/, prefixe J10_.
## ----------------------------------------------------------------------

## ========================================================================
## 0.2 — LES PACKAGES, ET UN ORDRE DE CHARGEMENT QUI COMPTE
## ========================================================================
# L'ORDRE DES DEUX PREMIERES LIGNES N'EST PAS INDIFFERENT.
# sae depend de MASS. MASS definit une fonction select(). Si dplyr est charge
# AVANT sae, c'est MASS::select() qui gagne, et tout appel a select() dans la
# suite du script echoue sur un message incomprehensible. En chargeant sae
# d'abord et dplyr ensuite, c'est dplyr::select() qui masque MASS::select().
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
cat("select() vient de :",
    environmentName(environment(get("select"))), "\n")

## ----------------------------------------------------------------------
## LE PIEGE DU MASQUAGE DE select()
##
## Ce que ca code : trois packages du jour definissent select() -- dplyr, MASS
##   (charge par sae) et, ailleurs, raster. Le dernier charge gagne.
## Ce que le choix technique fait : charger sae avant dplyr place
##   dplyr::select() au-dessus. Inverser arrete la journee au Module 6.
## Ce qui se lit : la ligne "select() vient de :" doit afficher dplyr.
## Ce qui ne se lit pas : les autres masquages (filter() par stats, extract()
##   par terra). Regle generale : qualifier l'appel.
## ----------------------------------------------------------------------

## ========================================================================
## 0.3 — INVENTAIRE
## ========================================================================
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

cat("\nModule 10 (conserve de l'ancien materiel, non execute) :\n")
cat("  datasets/DS.geojson       present ?", file.exists("datasets/DS.geojson"), "\n")
cat("  datasets/gadm41_CMR_2.shp present ?", file.exists("datasets/gadm41_CMR_2.shp"), "\n")

## ----------------------------------------------------------------------
## LA QUESTION DE LA JOURNEE
##
## Comment une donnee spatiale devient-elle un argument recevable devant un
## decideur ? Trois familles, trois facons de repondre :
##   Evenementiel  acled_cameroon_export.csv     l'evenement RAPPORTE
##   Reanalyse     era5_t2m_mensuel_cameroun.nc  la cellule de ~31 km, par mois
##   Enquete       ehcvm2018_benin_menages.csv   le menage enquete, en grappe
## Aucune n'est "la realite" : chacune est une construction dont il faut
## connaitre la regle de fabrication avant de la cartographier.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 1 — DONNEES EVENEMENTIELLES : LIRE ACLED SANS LUI FAIRE DIRE PLUS
## ##########################################################################

## ----------------------------------------------------------------------
## ACLED -- Armed Conflict Location & Event Data Project (acleddata.com)
##
## ACLED code, a partir de sources ouvertes, des EVENEMENTS de violence
## politique et de contestation. UN EVENEMENT ACLED N'EST PAS UN FAIT VERIFIE :
## C'EST UN FAIT RAPPORTE. La base mesure conjointement l'activite
## conflictuelle ET l'activite des sources qui la rapportent. Toute la journee :
## ecrire "evenements rapportes", jamais "evenements".
## ----------------------------------------------------------------------

# BLOC DE REFERENCE -- NON EXECUTE (compte myACLED et connexion requis).
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
# Separateur : virgule. Les champs "notes" contiennent des virgules mais sont
# proteges par des guillemets. La verification qui suit n'est pas decorative --
# un mauvais separateur renvoie UNE colonne unique, sans erreur.
acled_brut <- read_csv("datasets/acled_cameroon_export.csv", show_col_types = FALSE)

cat("ACLED :", nrow(acled_brut), "lignes x", ncol(acled_brut), "colonnes\n")
cat("Une seule colonne lue ? ", ncol(acled_brut) == 1,
    "  (TRUE = mauvais separateur)\n\n")

cat("Colonnes reellement presentes :\n")
print(names(acled_brut))

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
## event_date, year ........ date -> series temporelles
## event_type, sub_event_type typologie a deux niveaux -> comptages, couleurs
## admin1, admin2, admin3 .. decoupage TEL QU'ACLED L'ECRIT -> piege du Module 2
## latitude, longitude ..... position -> couche sf
## geo_precision ........... 1 lieu precis / 2 ville / 3 region
## time_precision .......... 1 jour / 2 semaine / 3 mois
## fatalities .............. morts RAPPORTES, pas comptes
## notes ................... resume textuel, jamais agrege
## ----------------------------------------------------------------------

## ========================================================================
## 1.3 — CONTROLE DES VALEURS DOUTEUSES AVANT TOUT CALCUL
## ========================================================================
# a) fatalities : des negatifs ? des valeurs aberrantes ?
cat("fatalities -- min :", min(acled_brut$fatalities, na.rm = TRUE),
    "| max :", max(acled_brut$fatalities, na.rm = TRUE),
    "| NA :", sum(is.na(acled_brut$fatalities)), "\n")
cat("fatalities negatifs (sentinelle possible) :",
    sum(acled_brut$fatalities < 0, na.rm = TRUE), "\n")

# b) coordonnees a (0, 0) : "null island". LA sentinelle classique des bases
#    d'evenements. Sur une carte du Cameroun, ces points tombent dans l'ocean.
cat("\nCoordonnees exactement (0, 0) :",
    sum(acled_brut$latitude == 0 & acled_brut$longitude == 0, na.rm = TRUE), "\n")
cat("latitude NA :", sum(is.na(acled_brut$latitude)),
    "| longitude NA :", sum(is.na(acled_brut$longitude)), "\n")

# c) emprise plausible du Cameroun : 1.6-13.1 N et 8.4-16.2 E.
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
## Ce qu'il code : quatre familles de defauts.
## Ce que le choix technique fait : la boite 1-14 N / 8-17 E est un test
##   GROSSIER, volontairement large. Il attrape les inversions
##   latitude/longitude (qui placeraient le Cameroun au large de la Somalie),
##   pas les erreurs de quelques kilometres. st_as_sf() ne leve AUCUNE erreur
##   sur une inversion.
## Ce qui se lit : les compteurs ci-dessus.
## Ce qui ne se lit pas : un geo_precision = 3 n'est pas une erreur. Le meme
##   enregistrement est bon ou mauvais SELON LA QUESTION POSEE.
## ----------------------------------------------------------------------

## ========================================================================
## 1.4 — NETTOYAGE ET CHAMP TEMPOREL
## ========================================================================
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

# On borne sur la DERNIERE ANNEE DU FICHIER, pas sur la date du jour : le
# materiel doit donner la meme sortie en 2026 et en 2030.
annee_max <- max(acled_clean$annee, na.rm = TRUE)
annee_min <- annee_max - 9

acled_clean <- acled_clean |> filter(annee >= annee_min)

cat("Champ retenu :", annee_min, "-", annee_max, "|",
    nrow(acled_clean), "evenements\n")
cat("Evenements exclus par le bornage temporel :",
    sum(acled_brut$year < annee_min, na.rm = TRUE), "\n")

## ========================================================================
## 1.5 — DEUX SERIES : LES EVENEMENTS, PUIS LES DECES
## ========================================================================
resume_types <- acled_clean |>
  count(event_type, sort = TRUE, name = "n_evenements") |>
  mutate(part_pct = round(100 * n_evenements / sum(n_evenements), 1))

print(resume_types)

# Comptage par region TELLE QU'ACLED L'ECRIT. Retenez ces libelles : ils sont
# le sujet du Module 2.
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
## Ce que la figure code : la hauteur totale est le nombre d'evenements
##   RAPPORTES ; chaque couleur est un type. Un evenement compte pour 1 : ce
##   graphique mesure une FREQUENCE, pas une intensite.
## Ce que les choix techniques font : l'empilement rend le TOTAL lisible et la
##   comparaison d'un type d'une annee a l'autre difficile. Pour un type
##   precis : facet_wrap(~ event_type). Palette Set2 = QUALITATIVE.
## Ce qui se lit : le profil temporel, les pics, la deformation de la
##   composition par type.
## Ce qui ne se lit pas : l'effort de collecte. Une hausse peut venir d'une
##   degradation, d'une meilleure couverture mediatique, ou d'un changement de
##   methodologie ACLED. Rien ici ne tranche.
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
## Ce que la figure code : la somme annuelle des deces RAPPORTES. Ni un
##   decompte d'etat civil, ni une estimation de surmortalite.
## Ce que les choix techniques font : relier les points suggere une continuite
##   entre deux annees -- commodite de lecture. La colonne deces_par_evenement
##   separe "plus d'evenements" de "des evenements plus meurtriers".
## Ce qui se lit : les annees de rupture, et leur ecart avec le graphe des
##   frequences.
## Ce qui ne se lit pas : l'incertitude. Un deces rapporte par une source unique
##   pese autant qu'un deces confirme par trois sources.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 2 — DU POINT AU POLYGONE : LA JOINTURE QUI ECHOUE EN SILENCE
## ##########################################################################

## ========================================================================
## 2.1 — CONVERTIR LES EVENEMENTS EN COUCHE SPATIALE
## ========================================================================
# ORDRE DES COORDONNEES : c(longitude, latitude), et JAMAIS l'inverse.
# sf ne verifie rien. Le seul garde-fou est de tracer la couche aussitot.
acled_pts <- st_as_sf(
  acled_clean,
  coords = c("longitude", "latitude"),
  crs    = 4326,          # WGS84 : degres. Toujours POSER le CRS.
  remove = FALSE
)

cat("Couche de points ACLED :", nrow(acled_pts), "entites\n")
cat("CRS :", st_crs(acled_pts)$input, "\n")
cat("Emprise (bbox) :\n")
print(st_bbox(acled_pts))

# On liste d'abord les couches du GeoPackage : on ne suppose pas leur nom.
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
## ACLED ecrit ses regions en FRANCAIS SANS ACCENTS (Sud, Extreme-Nord,
## Nord-Ouest) ; GADM les siennes en ANGLAIS (South, Far North, North-West).
## Ce n'est PAS un probleme d'accents, c'est un probleme de LANGUE. Aucune
## translitteration ne transformera Extreme-Nord en Far North. Et pourtant
## left_join() acceptera la jointure sans broncher : des NA, puis -- apres
## replace_na(0) -- des REGIONS A ZERO EVENEMENT. Une region en guerre affichee
## en blanc. Nous allons donc PROVOQUER l'accident avant de le corriger.
## ----------------------------------------------------------------------

## ========================================================================
## 2.2 — TENTATIVE N.1 : JOINDRE PAR LE LIBELLE (ET COMPTER LES DEGATS)
## ========================================================================
# On part TOUJOURS de la couche geographique, jamais du tableau.
essai_nom <- cmr1 |>
  st_drop_geometry() |>
  select(NAME_1) |>
  left_join(resume_admin1, by = c("NAME_1" = "admin1"))

cat("Regions GADM :", nrow(essai_nom), "\n")
cat("Regions APPARIEES avec ACLED :", sum(!is.na(essai_nom$n_evenements)), "\n")
cat("Regions NON appariees (NA) :", sum(is.na(essai_nom$n_evenements)), "\n\n")
print(essai_nom)

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
## langues. En langage de salle : "la carte que nous aurions publiee aurait
## affiche zero evenement pour la majorite des regions du pays, sans le moindre
## message d'erreur". C'est l'accident que le compteur sum(is.na(...)) apres
## chaque jointure est cense empecher.
## ----------------------------------------------------------------------

## ========================================================================
## 2.3 — TENTATIVE N.2 : NORMALISER LES CHAINES
## ========================================================================
# Fabriquer une CLE TECHNIQUE : sans accents, minuscules, sans ponctuation. Le
# libelle d'origine est conserve pour l'affichage : la cle ne sert QU'A joindre.
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
## Elle resout les differences d'ECRITURE (accents, casse, tirets, mots de
## liaison) : au J05 elle recuperait 11 departements sur 58. Elle ne resout pas
## la TRADUCTION : extremenord et farnorth restent deux chaines distinctes, et
## aucune distance d'edition ne devrait les rapprocher.
## Quand elle echoue : ECRIRE UNE TABLE DE CORRESPONDANCE A LA MAIN. Ce n'est
## pas un bricolage, c'est une DECISION DE METHODE.
## ----------------------------------------------------------------------

## ========================================================================
## 2.4 — TENTATIVE N.3 : LA TABLE DE CORRESPONDANCE ECRITE A LA MAIN
## ========================================================================
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

# CONTROLE dans les DEUX SENS.
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

resume_par_table <- resume_admin1 |>
  left_join(corresp_regions, by = c("admin1" = "admin1_acled"))

cat("\nEvenements non rattaches malgre la table :",
    sum(resume_par_table$n_evenements[is.na(resume_par_table$NAME_1_gadm)],
        na.rm = TRUE), "\n")

## ----------------------------------------------------------------------
## LES DEUX CONTROLES A NE JAMAIS OMETTRE SUR UNE TABLE DE CORRESPONDANCE
##
##  - un libelle de la TABLE absent de la COUCHE = faute de frappe : la ligne ne
##    s'appariera jamais, silencieusement ;
##  - un libelle de la COUCHE absent de la TABLE = region oubliee : elle restera
##    a NA, puis a zero sur la carte.
## Verifier DANS LES DEUX SENS.
## ----------------------------------------------------------------------

## ========================================================================
## 2.5 — LA ROUTE SURE : LA JOINTURE SPATIALE st_within
## ========================================================================
# Elle n'utilise aucun libelle : elle demande dans quel polygone tombe chaque
# point. Une position ne se traduit pas. Prealable : harmoniser les CRS.
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
  join = st_within
)

# CONTROLE 1 : st_join() peut DUPLIQUER des lignes.
cat("\nPoints avant st_join :", n_pts_avant, "\n")
cat("Lignes apres st_join :", nrow(acled_dans_region), "\n")
cat("Duplications introduites :", nrow(acled_dans_region) - n_pts_avant, "\n")

# CONTROLE 2 : points hors de toute region. Ce ne sont PAS des dechets.
n_hors <- sum(is.na(acled_dans_region$NAME_1))
cat("Points hors de toute region GADM :", n_hors,
    sprintf("(%.2f %%)", 100 * n_hors / nrow(acled_dans_region)), "\n")

if (n_hors > 0) {
  cat("\nCes points, tels qu'ACLED les localise (admin1 declare) :\n")
  print(table(acled_dans_region$admin1[is.na(acled_dans_region$NAME_1)]))
}

# CONFRONTATION : le LIBELLE d'ACLED contre la POSITION.
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
## Trois causes possibles : (1) un evenement pres d'une frontiere regionale --
## le trace GADM n'est pas la verite juridique de la limite ; (2) un decoupage
## administratif qui a change -- GADM 4.1 est fige ; (3) une coordonnee
## imprecise (geo_precision 2 ou 3). Dans les trois cas la position reste la
## cle la plus sure, mais le TAUX DE DESACCORD est un indicateur de qualite a
## publier a cote de la carte.
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
# La jointure est spatiale : une region sans ligne est une region ou AUCUN
# evenement n'a ete rapporte. Le zero est une MESURE, pas un trou.
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
## Apres une JOINTURE SPATIALE REUSSIE, le zero est une observation.
## Apres une JOINTURE PAR LIBELLE RATEE, il fabrique une information fausse et
## lui donne la meme autorite visuelle qu'a une information vraie.
## La ligne de code est identique ; ce qui change, c'est ce qu'on sait de
## l'etape d'avant. On ne remplace un NA qu'apres avoir compte les NA et su
## d'ou ils viennent.
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
## Ce que la figure code : un point = un evenement RAPPORTE, colore par type.
##   La taille du point ne code rien.
## Ce que les choix techniques font : la transparence laisse deviner les
##   superpositions. Une carte de points SATURE : au-dela de quelques centaines
##   d'evenements au meme endroit, l'oeil ne distingue plus 200 de 2000.
## Ce qui se lit : la geographie du phenomene, et l'HETEROGENEITE INTERNE des
##   regions, que la choroplethe effacera.
## Ce qui ne se lit pas : l'intensite, la precision de la position, la
##   population exposee.
##
## EN QUOI LE SPATIAL EST UTILE ICI : la carte montre que les evenements
## forment des BLOCS CONTIGUS qui traversent les limites administratives. Un
## bloc contigu ne s'explique pas par les caracteristiques propres de chaque
## region, mais par ce que des territoires voisins partagent PARCE QU'ILS SONT
## VOISINS. Aucun tri de tableau ne montre cela.
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
## Ce que la figure code : un EFFECTIF BRUT par region, pas un taux. Une grande
##   region peuplee en aura mecaniquement plus.
## Ce que les choix techniques font : discretisation en QUANTILES (5 classes) --
##   contraste garanti, seuils arbitraires. Intervalles egaux : seuils lisibles,
##   classes parfois vides. Jenks : ruptures naturelles, seuils non comparables
##   d'une carte a l'autre. Aucun choix n'est neutre ; un choix DECLARE suffit.
## Ce qui se lit : le classement regional et sa geographie d'ensemble.
## Ce qui ne se lit pas : la position exacte, les concentrations locales, les
##   vides internes. La choroplethe affirme que la region est HOMOGENE -- c'est
##   faux, et la carte de points le prouve.
##
## EN QUOI LE SPATIAL EST UTILE ICI : une choroplethe ne sert pas a voir OU est
## le phenomene, mais a le rendre COMPARABLE A UNE DECISION. C'est la maille de
## la decision qui commande la maille de la carte.
## ----------------------------------------------------------------------

## ----------------------------------------------------------------------
## MAUP — LE PROBLEME DE L'UNITE SPATIALE MODIFIABLE
##
## EFFET D'ECHELLE : les memes points agreges par region (10 unites), par
##   departement (58) ou par arrondissement donnent trois cartes, trois
##   classements, trois correlations. Aucun n'est "le vrai".
## EFFET DE ZONAGE : a nombre d'unites constant, deplacer les limites change les
##   resultats (mecanisme du redecoupage electoral).
## CONSEQUENCE : aucune maille n'est neutre. Seule justification recevable : on
##   agrege a la MAILLE DE LA DECISION, en DISANT que la region est heterogene.
## ERREUR ECOLOGIQUE : conclure de la carte que "les habitants de telle region
##   ont une probabilite elevee d'etre exposes" est illegitime -- la carte
##   decrit l'agregat, pas les individus. Antidote : superposer fond agrege et
##   points.
## ----------------------------------------------------------------------

## ========================================================================
## 2.7 — EXPORTS DU BLOC ACLED
## ========================================================================
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

## ----------------------------------------------------------------------
## ERA5 -- CE QUE MESURE EXACTEMENT CE FICHIER
##
## ERA5 est la REANALYSE atmospherique de l'ECMWF (Copernicus CDS). Une
## reanalyse n'est NI une observation, NI une prevision : c'est un modele de
## circulation atmospherique force a rester coherent avec les observations
## disponibles. Le produit est un champ COMPLET et REGULIER -- une valeur
## partout, tous les mois -- la ou les observations reelles sont eparses. C'est
## son interet en Afrique centrale ; c'est aussi sa limite : dans les zones sans
## station, la valeur vient surtout du modele.
##
##   Variable ....... 2m_temperature      Resolution .... ~0,25 degre (~31 km)
##   Produit ........ Single Levels,      Pas de temps .. mensuel
##                    moyennes mensuelles UNITE ......... KELVIN
##   Format ......... NetCDF (lon x lat x temps)
##
## KELVIN : unite native, que rien n'affiche. Un raster non converti donne des
## valeurs autour de 298. Mais une ANOMALIE ou une DIFFERENCE calculee sans
## conversion passe inapercue : une difference de 2 K vaut 2 C, alors qu'une
## moyenne de 298 K vaut 24,85 C.
## ----------------------------------------------------------------------

# BLOC DE REFERENCE -- NON EXECUTE (compte Copernicus CDS requis).
#
# ecmwfr::wf_set_key(user = "123456", key = "xxxxxxxx-xxxx-xxxx", service = "cds")
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
# a) KELVIN -> CELSIUS. La ligne la plus facile a oublier de toute la journee.
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
## Ce que la figure code : une cellule = la temperature moyenne de l'air a 2 m
##   pour le mois affiche, sur une maille de ~31 km. Blanc = hors polygone.
## Ce que les choix techniques font : plot() de terra calcule ses bornes sur la
##   SEULE couche affichee. Deux mois traces separement n'ont pas la meme
##   echelle et ne se comparent pas a l'oeil.
## Ce qui se lit : que le decoupage a fonctionne, que les valeurs sont
##   plausibles, et que l'escalier des cellules revele la vraie resolution.
## Ce qui ne se lit pas : aucune variation infra-cellulaire. Une cellule couvre
##   ~950 km2 : la chaleur urbaine de Douala n'existe pas dans ce fichier.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 4 — EXTRACTION ZONALE TEMPORELLE : DU RASTER A LA SERIE STATISTIQUE
## ##########################################################################

## ========================================================================
## 4.1 — exact_extract() SUR UNE PILE DE COUCHES
## ========================================================================
# exact_extract() pondere par la FRACTION de chaque cellule couverte par le
# polygone. Une cellule a cheval sur deux regions est partagee, pas attribuee
# en entier a l'une des deux. Sur une maille de 31 km, la difference avec une
# extraction par centroide n'est PAS negligeable.
cmr1_proj <- st_transform(cmr1, crs(era5_cmr))
cat("CRS du raster  :", crs(era5_cmr, describe = TRUE)$name, "\n")
cat("CRS des regions:", st_crs(cmr1_proj)$input, "\n")

t2m_extrait <- exact_extract(era5_cmr, cmr1_proj, "mean", progress = FALSE)

cat("\nMatrice extraite :", nrow(t2m_extrait), "regions x",
    ncol(t2m_extrait), "mois\n")
cat("Coherence : regions attendues =", nrow(cmr1),
    "| couches attendues =", nlyr(era5_cmr), "\n")
cat("Valeurs manquantes dans la matrice :", sum(is.na(t2m_extrait)), "\n")
cat("Noms des 3 premieres colonnes extraites :",
    paste(head(names(t2m_extrait), 3), collapse = ", "), "\n")

## ========================================================================
## 4.2 — REMISE EN FORME LONGUE : LE PIEGE DES NOMS DE COUCHES
## ========================================================================
# PIEGE. exact_extract() prefixe ses colonnes par "mean.". Le suffixe n'est pas
# forcement un entier, et l'ordre alphabetique n'est PAS l'ordre chronologique
# ("t2m_10" < "t2m_2" en tri texte). On retrouve donc l'indice par match() sur
# names(era5_cmr). On ne devine jamais un indice a partir d'un nom de colonne.
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
## Ce que la figure code : une MOYENNE DE MOYENNES NON PONDEREE des dix regions
##   -- chaque region pese pareil, quelle que soit sa superficie ou sa
##   population. Ce n'est ni la temperature moyenne du Cameroun, ni celle que
##   subit un Camerounais moyen.
## Ce que les choix techniques font : le LOESS est une regression polynomiale
##   locale ponderee par la distance ; span (0,75 par defaut) fixe la largeur du
##   voisinage. CE N'EST PAS UN MODELE CLIMATIQUE : il ne predit rien, ne teste
##   rien. La bande rose est l'intervalle de confiance DE LA COURBE LISSEE, pas
##   l'etendue des valeurs observees.
## Ce qui se lit : la saisonnalite, qui domine tout le reste.
## Ce qui ne se lit pas : une tendance climatique. La convention est la NORMALE
##   TRENTENAIRE ; dix ans ne suffisent pas.
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
## Ce que la figure code : la ligne est la moyenne region x annee du mois ; le
##   ruban va du MINIMUM ABSOLU au MAXIMUM ABSOLU observes ce mois-la.
## Ce que les choix techniques font -- et c'est le point : un ruban min/max
##   n'est PAS un intervalle de confiance et PAS un ecart-type. Il melange la
##   variation SPATIALE et la variation INTERANNUELLE, et il est entierement
##   gouverne par les extremes : une seule cellule anormalement chaude, une
##   seule fois, elargit le ruban pour toujours. Un ruban interquartile serait
##   robuste ; celui-ci parle d'ENVELOPPE DES POSSIBLES.
## Ce qui se lit : le calendrier thermique, et le fait que l'AMPLITUDE varie
##   selon les mois (colonne amplitude).
## Ce qui ne se lit pas : quelle region produit le minimum et laquelle le
##   maximum. Le ruban est anonyme.
##
## EN QUOI LE SPATIAL EST UTILE ICI : c'est l'ecart entre regions, mois par
## mois, qui remplit le ruban. Une moyenne nationale unique aurait produit une
## ligne sans ruban, et masque que le pays vit, le meme mois, deux climats.
## ----------------------------------------------------------------------

## ========================================================================
## 4.5 — CARTE DE LA TEMPERATURE MOYENNE, ET EXPORTS
## ========================================================================
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
## Ce que la figure code : une seule valeur resume une centaine de mois par
##   cellule de 31 km.
## Ce que les choix techniques font : "-brewer.rd_yl_bu" est une palette
##   DIVERGENTE, le "-" inversant le sens pour que le rouge code le chaud. Une
##   divergente suppose un point de reference au milieu : elle raconte "plus
##   chaud que / plus froid que", pas "beaucoup / peu". Legitime pour une
##   temperature, deplace pour un effectif.
## Ce qui se lit : le gradient latitudinal et la marque du relief.
## Ce qui ne se lit pas : la variabilite. Deux cellules a 26 C de moyenne
##   peuvent avoir 4 C ou 14 C d'amplitude annuelle.
##
## EN QUOI LE SPATIAL EST UTILE ICI : l'interet d'une reanalyse est la
## COUVERTURE COMPLETE, pas la precision locale. Aucune zone blanche, alors que
## le reseau de stations en laisse d'immenses.
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
## A partir d'ici, la journee quitte le Cameroun pour le BENIN.
##
## LA RAISON TECHNIQUE. Le SAE suppose une enquete dont on puisse calculer, par
## domaine, une estimation directe ET sa variance d'echantillonnage reelle :
## poids, identifiant de grappe, geolocalisation. L'extrait camerounais dont
## l'atelier dispose (ecam5.dta) echoue au controle de reference : son taux de
## pauvrete national colle a l'INS (38,6 % contre 37,7 %), mais A L'INTERIEUR
## DES REGIONS il decroche -- l'Est y ressort a 7,5 % contre 41,5 % publie.
## C'est un extrait de formation, non representatif au niveau infraregional. Un
## exercice SAE dessus produirait des cartes magnifiques et des chiffres qu'il
## faudrait ensuite interdire de citer.
##
## CE QUE LE DEPLACEMENT COUTE : (1) le fil rouge camerounais se rompt ; (2) le
## vocabulaire administratif change (communes beninoises) ; (3) les ordres de
## grandeur ne sont pas transposables -- on apprend ici la METHODE, pas le
## diagnostic. Aucun chiffre de cette partie ne decrit le Cameroun.
##
## CE QU'IL APPORTE : une chaine complete et EXECUTABLE, rejouable sur les
## donnees de son propre pays.
##
## PROVENANCE : depot public github.com/JoshMerfeld/saereplication (J. Merfeld).
## Enquete : EHCVM 2018-2019, Benin, microdonnees Banque mondiale (catalogue
## 4291). Usage strictement pedagogique. METHODE ADAPTEE, NON REPRODUITE : le
## depot ajuste un modele UNITAIRE (EBP, povmap, Lasso) ; nous simplifions vers
## un modele D'AIRE (Fay-Herriot, sae). Les coefficients obtenus ici ne
## reproduisent donc pas ceux du depot.
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

# d) Coordonnees des grappes : presentes, mais DEPLACEES par le producteur pour
#    proteger l'anonymat des enquetes -- comme au DHS.
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

# Covariables aux DEUX resolutions : par commune (ajuster) et par cellule
# de 3 km (predire, Module 9).
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

# MEMES variables, NOMS DIFFERENTS : suffixe "_adm2" par commune, sans suffixe
# par cellule. Volontaire (on ne confond pas les resolutions), et piege au
# Module 9 : la formule ajustee sur lc_13_urbain_adm2 s'applique a lc_13_urbain.
cat("\nCommunes couvertes par la grille :",
    n_distinct(covariables_grille$admin2Pcod), "\n")
cat("Cellules par commune -- min :", min(table(covariables_grille$admin2Pcod)),
    "| median :", median(table(covariables_grille$admin2Pcod)),
    "| max :", max(table(covariables_grille$admin2Pcod)), "\n")

## ----------------------------------------------------------------------
## CE QUE MESURE insecure, EXACTEMENT
##
##  - une DECLARATION, pas une mesure anthropometrique. Le meme menage,
##    interroge autrement ou a une autre saison, peut repondre autrement ;
##  - l'unite est le MENAGE, pas l'individu : 30 % de menages en insecurite ne
##    fait pas 30 % de la population (BIAIS DE TAILLE -- au J05, 6,55 personnes
##    par menage sur un fichier d'individus, 4,59 sur un fichier de menages) ;
##  - la date compte : EHCVM 2018-2019.
## ----------------------------------------------------------------------

## ========================================================================
## 5.2 — RATTACHER CHAQUE MENAGE A SA COMMUNE
## ========================================================================
# menages ne porte PAS admin2Pcod : il porte id, l'identifiant de la cellule de
# 3 km ou tombe la grappe. C'est covariables_grille qui fait le pont.
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
## Les communes qu'aucune grappe n'a touchees n'auront AUCUNE estimation. Elles
## devront apparaitre en GRIS -- jamais a zero, jamais effacees. Un trou
## d'echantillonnage se voit sur une carte et JAMAIS dans un tableau.
## ----------------------------------------------------------------------

## ========================================================================
## 5.3 — LE PLAN DE SONDAGE
## ========================================================================
## ----------------------------------------------------------------------
## TROIS RAISONS DE NE PAS ECRIRE mean(insecure)
##
## 1. LES POIDS. Un menage represente hhweight menages du pays. Sans les poids
##    on decrit L'ECHANTILLON (au J05 : 40,8 % sans poids, 38,6 % avec).
## 2. LES GRAPPES. Sondage A DEUX DEGRES : deux menages de la meme grappe se
##    ressemblent. Ignorer cette structure DIVISE ARTIFICIELLEMENT
##    l'erreur-type -- fausse certitude. Pour le SAE, fatal : la variance est un
##    INGREDIENT du modele.
## 3. LE BON POIDS A CHAQUE ETAGE. Et : LA MOYENNE D'UNE MOYENNE N'EST PAS LA
##    MOYENNE.
##
## svydesign() ne calcule rien : il DECRIT le plan une fois pour toutes.
## ----------------------------------------------------------------------

# Aucune strate n'est declaree ici, faute d'identifiant de strate dans le
# fichier : l'erreur-type obtenue est donc legerement CONSERVATRICE.
plan_sondage <- svydesign(
  ids     = ~grappe,
  weights = ~hhweight,
  data    = menages_admin2
)

print(plan_sondage)

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
## Le premier decrit les menages PRESENTS DANS LE FICHIER, le deuxieme LES
## MENAGES DU BENIN. Le rapport des deux erreurs-types approche l'EFFET DE
## GRAPPE : au-dessus de 1, la structure du plan coute de la precision.
## Ce qui se lit : un chiffre d'enquete sans son plan de sondage n'est pas un
##   resultat, c'est une statistique descriptive de fichier.
## Ce qui ne se lit pas : la non-reponse. Les poids corrigent le tirage, pas les
##   menages qui n'ont pas repondu.
## ----------------------------------------------------------------------

## ========================================================================
## 5.4 — ESTIMATION DIRECTE PAR COMMUNE, ET VARIANCE NON ESTIMABLE
## ========================================================================
# svyby() applique svymean() SEPAREMENT a chaque commune, en respectant le plan.
# group_by()+mean() ignorerait poids ET grappes, et donnerait une erreur-type
# sous-estimee, donc inutilisable comme entree du modele.
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
## LE FAIT TECHNIQUE : avec un sondage en grappes, la variance s'estime ENTRE
## LES GRAPPES. Avec une seule grappe, il n'y a rien entre quoi calculer une
## variance -- ce n'est pas un bug, c'est l'arithmetique.
##
## POURQUOI CE N'EST PAS UNE COMMODITE : le modele prend la variance directe EN
## ENTREE (vardir). Une variance a zero declarerait au modele que l'estimation
## directe est PARFAITEMENT PRECISE, et lui donnerait un poids infini par
## rapport aux communes bien mesurees. Une variance NA ferait echouer
## l'ajustement.
##
## CE QUE L'EXCLUSION COUTE : ces communes sont typiquement les moins peuplees,
## les plus rurales -- pas un echantillon aleatoire des autres. Les retirer du
## MODELE est une necessite ; les faire disparaitre de la CARTE serait un
## mensonge par omission.
##
## LE SEUIL EST DECLARE DANS LE CODE, pas subi : n_grappes == 1.
## ----------------------------------------------------------------------

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
## Ce que la figure code : un point haut = une commune dont le chiffre est
##   BRUITE.
## Ce que les choix techniques font : echelle LOGARITHMIQUE en abscisse -- le
##   bon choix quand les valeurs s'etalent sur un ordre de grandeur, au prix
##   d'une deformation a annoncer (des ecarts egaux a l'ecran ne sont pas des
##   ecarts egaux en menages).
## Ce qui se lit : la decroissance en 1/racine(n) -- le PROBLEME que le SAE
##   vient resoudre.
## Ce qui ne se lit pas : que les communes de gauche seraient "mal enquetees".
##   Elles le sont SELON LE PLAN, dimensionne pour le national et le regional.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 6 — CHOISIR UNE COVARIABLE AUXILIAIRE
## ##########################################################################

## ----------------------------------------------------------------------
## CE QU'ON DEMANDE A UNE COVARIABLE
##
## Une information CONNUE PARTOUT et CORRELEE a ce qu'on estime. Exigence
## faible : la covariable n'a pas besoin d'etre une cause, elle doit predire.
## Nos candidates (Google Earth Engine) existent AUX DEUX RESOLUTIONS :
##   ntl_mean_adm2 ............ luminosite nocturne (VIIRS)
##   population_adm2 .......... population totale estimee
##   ndvi_mean_adm2 ........... indice de vegetation
##   precip_2018_adm2 ......... cumul de precipitations 2018
##   no2_adm2 ................. NO2 tropospherique
##   lc_13_urbain_adm2 ........ part de sol urbain (MODIS LC_Type1, classe 13)
##   lc_12_cultures_adm2 ...... part de sol cultive (classe 12)
##   lc_8_savane_boisee_adm2 .. part de savane boisee (classe 8)
##   lc_11_zones_humides_adm2 . part de zones humides (classe 11)
## Leur fabrication ne demanderait rien de nouveau : c'est la statistique zonale
## deja pratiquee ce matin (st_join pour ACLED, exact_extract pour ERA5).
## ----------------------------------------------------------------------

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

cat("\nCandidates absentes du fichier :",
    paste(setdiff(candidats, names(sae_data_candidates)), collapse = ", "),
    "(vide = tout va bien)\n")
cat("Valeurs manquantes par covariable :\n")
print(colSums(is.na(sae_data_candidates[candidats])))

correlations <- sapply(candidats, function(v) {
  cor(sae_data_candidates$insecure_direct, sae_data_candidates[[v]],
      use = "complete.obs")
})
correlations <- correlations[order(-abs(correlations))]

cat("\nCorrelation avec l'insecurite alimentaire directe,\n")
cat("triee par valeur absolue decroissante :\n")
print(round(correlations, 3))

# CONTROLE DE COLINEARITE : deux covariables tres correlees entre elles
# apportent la MEME information deux fois ; leurs coefficients deviennent
# instables et peuvent changer de signe.
matrice_cor <- cor(sae_data_candidates[candidats], use = "complete.obs")

cat("Matrice de correlation entre candidates (arrondie) :\n")
print(round(matrice_cor, 2))

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
## Ce que les choix techniques font : Pearson mesure une association LINEAIRE
##   (une relation en U donnerait zero). Sur des variables dissymetriques,
##   SPEARMAN serait plus honnete. Le criblage un-par-un est une methode FAIBLE
##   alors que le modele les utilisera ensemble ; un projet operationnel
##   selectionnerait par Lasso valide croise. Le seuil de colinearite a 0,7 est
##   CONVENTIONNEL : il declenche une discussion, il ne tranche pas.
## Ce qui se lit : l'ordre des candidates, et surtout le SIGNE -- a confronter
##   aux coefficients du modele au Module 7.
## Ce qui ne se lit pas : aucune causalite. Avec 76 communes et neuf candidates
##   on trouvera TOUJOURS quelque chose de correle. LE MODELE EMPRUNTE DE LA
##   FORCE, IL N'EXPLIQUE RIEN.
## ----------------------------------------------------------------------

## ##########################################################################
## MODULE 7 — FAY-HERRIOT : EMPRUNTER DE LA FORCE AUX AUTRES COMMUNES
## ##########################################################################

## ----------------------------------------------------------------------
## LE MODELE, EN TROIS LIGNES
##
##     p_i = x_i . beta + u_i + e_i,  u_i ~ N(0, sigma2_u), e_i ~ N(0, psi_i)
##
## e_i est l'erreur due au fait qu'on a enquete un echantillon (CONNUE, c'est
## var_direct) ; u_i est ce qui, dans la commune, echappe aux covariables
## (estimee). L'EBLUP est une moyenne ponderee entre estimation directe et
## prediction du modele : variance d'echantillonnage GRANDE -> tire vers le
## modele (on emprunte de la force) ; PETITE -> l'estimation directe est
## conservee. mseFH() ajuste ET calcule l'EQM de chaque prediction -- c'est elle
## qui rend le resultat publiable.
## ----------------------------------------------------------------------

# vardir : la variance d'echantillonnage CONNUE de chaque commune. C'est elle
# qui distingue un modele SAE d'une simple regression.
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
## beta est l'effet d'une augmentation d'UNE UNITE de la covariable. Les
## covariables etant des PARTS entre 0 et 1, beta est l'ecart attendu entre une
## commune a 0 % et une commune a 100 % : un ecart jamais observe, donc une
## extrapolation de la pente.
## CONTROLE IMMEDIAT : le signe de chaque beta doit correspondre au signe de la
## correlation du Module 6. Une inversion signale une COLINEARITE.
## LE RAPPORT sigma2_u / psi est la cle : grand = l'heterogeneite reelle domine
## le bruit, le modele corrigera peu ; petit = le bruit domine, lissage fort. UN
## GAIN MOYEN MODESTE N'EST PAS UN ECHEC DU MODELE.
## Ce qui ne se lit pas : les pvalue (76 communes, puissance faible). AIC/BIC/KIC
## n'ont AUCUN SENS EN VALEUR ABSOLUE : instruments de COMPARAISON.
## ----------------------------------------------------------------------

# RMSE (racine de l'EQM) pour rester dans l'unite de la variable : des POINTS
# DE POURCENTAGE, comparables a l'erreur-type de l'estimation directe.
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
## Ce que les choix techniques font : les deux barres NE SONT PAS DE MEME
##   NATURE. Cote direct, erreur-type d'echantillonnage. Cote Fay-Herriot,
##   racine de l'EQM d'un PREDICTEUR (echantillonnage + modele + estimation des
##   parametres). Les superposer est utile et legerement abusif : le dire. Le
##   facteur 1,96 suppose une normalite approximative, discutable pour une
##   proportion proche de 0 ou 1 (logit plus rigoureux). Le tri par niveau
##   montre le gradient et efface la geographie -- que la carte ajoutera.
## Ce qui se lit : points confondus = rien corrige ; points eloignes =
##   estimation tiree vers le modele (verifier n_menages) ; barre bleue plus
##   courte = gain de precision.
## Ce qui ne se lit pas : laquelle est "la vraie". Deux estimateurs : l'un sans
##   biais mais bruite, l'autre plus precis mais biaise vers le modele.
##   Arbitrage biais-variance, sans solution universelle.
## ----------------------------------------------------------------------

## ========================================================================
## 7.2 — LE VRAI TEST DU MECANISME
## ========================================================================
## ----------------------------------------------------------------------
## LA FIGURE QUI DECIDE SI LE MODELE FONCTIONNE
##
## Ce nuage n'est PAS une illustration de plus : c'est le test du mecanisme.
## Fay-Herriot corrige d'autant plus que la variance est grande, et elle est
## grande LA OU L'ECHANTILLON EST PETIT. Donc le gain doit etre MAXIMAL A
## GAUCHE et tendre vers zero a droite.
##   courbe DECROISSANTE .. le mecanisme opere ;
##   courbe PLATE ......... les covariables n'apportent presque rien ;
##   nuage SANS STRUCTURE . specification a revoir.
## Un point isole sous zero est acceptable ; des points negatifs NOMBREUX ou
## TRES eloignes de zero sont un signal d'alarme.
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
## LECTURE DE LA FIGURE -- GAIN CONTRE TAILLE D'ECHANTILLON
##
## Ce que la figure code : rmse_direct - rmse_fh en points ; la taille du point
##   ajoute le nombre de grappes (a effectif egal, 2 ou 8 grappes ne donnent pas
##   la meme variance directe).
## Ce que les choix techniques font : la ligne pointillee a zero est la
##   FRONTIERE DE DECISION. Le LOESS resume sans imposer, mais avec 76 points il
##   est sensible aux extremites : ne pas lire ses derniers centimetres. Le
##   tableau par tiers dit la meme chose SANS dependre du lissage : c'est lui
##   qui fait foi.
## Ce qui se lit : le gain est STRUCTURE par la taille de l'echantillon --
##   signature du mecanisme, seule preuve empirique que le modele fait ce qu'il
##   pretend faire.
## Ce qui ne se lit pas : que les estimations lissees seraient plus JUSTES.
##   Elles sont plus PRECISES au prix d'un biais vers le modele. Le RMSE combine
##   les deux, il ne les separe pas.
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 8 — TROIS CARTES A ECHELLE COMMUNE
## ##########################################################################

## ========================================================================
## 8.1 — JOINDRE LES ESTIMATIONS A LA GEOMETRIE, SANS EFFACER LES ABSENTES
## ========================================================================
# ON PART DE LA COUCHE. Un inner_join() ferait disparaitre de la carte -- donc
# du raisonnement -- les communes sans estimation.
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
##  - commune ESTIMEE A UNE VALEUR FAIBLE : elle est mesuree, et elle va bien ;
##  - commune NON ENQUETEE : nous n'en savons rien ;
##  - commune EXCLUE DU MODELE : l'enquete l'a touchee une seule fois -- un
##    chiffre sans savoir combien il vaut.
## Les colorer sur la meme echelle, ou les mettre a zero, revient a publier de
## l'ignorance deguisee en mesure. Convention : VALEUR EN COULEUR, ABSENCE EN
## GRIS, STATUT DANS LA LEGENDE.
## ----------------------------------------------------------------------

## ========================================================================
## 8.2 — LES TROIS CARTES
## ========================================================================
# ECHELLE COMMUNE : sans elle, deux palettes calculees separement donneraient au
# meme niveau d'insecurite deux couleurs differentes, et la comparaison visuelle
# -- tout l'objet de la figure -- serait fausse.
limites_insecurite <- range(
  c(communes_sae$insecure_direct, communes_sae$insecure_fh),
  na.rm = TRUE
)
cat("Echelle commune imposee aux cartes 1 et 2 :",
    round(limites_insecurite[1], 2), "a", round(limites_insecurite[2], 2),
    "points de pourcentage\n")

# value.na / label.na : les communes SANS estimation sont peintes en gris et
# nommees dans la legende.
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
## Ce qu'elles codent : (1) l'enquete seule ; (2) l'enquete lissee ; (3) la
##   reduction du RMSE -- LE RESULTAT DU TRAVAIL STATISTIQUE, pas le phenomene.
## Ce que les choix techniques font : echelle IMPOSEE aux cartes 1 et 2, seule
##   facon de les comparer du regard. brewer.blues est SEQUENTIELLE (quantite
##   ordonnee). La carte 3 est DIVERGENTE centree sur zero : ici zero est un
##   seuil qualitatif (le modele aide / il coute) ; une sequentielle masquerait
##   le signe.
## Ce qui se lit : l'ECART entre 1 et 2 (ou le modele est intervenu) et la carte
##   3 (pourquoi). Coherence a verifier a voix haute.
## Ce qui ne se lit pas : une carte lisse n'est pas une carte juste. L'oeil
##   interprete la regularite comme de la qualite : c'est un artefact du modele.
##
## EN QUOI LE SPATIAL EST UTILE ICI : la CONTIGUITE (si les communes fortement
## corrigees se touchent, l'echantillonnage a ete deficient sur une zone
## entiere -- defaut de plan, pas de commune) et le REPERAGE DES TROUS (les
## communes grises forment-elles un bloc ? Si oui, tout un territoire est absent
## du diagnostic national).
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
## DEUX PROBLEMES DISTINCTS, UNE MEME SOLUTION
##
## PROBLEME 1 -- LA PRECISION. L'estimation directe est bruitee la ou
## l'echantillon est petit ; Fay-Herriot la lisse. Resultat : un chiffre plus
## fiable, mais TOUJOURS UN CHIFFRE PAR COMMUNE. La resolution n'a pas bouge.
##
## PROBLEME 2 -- LA RESOLUTION. Meme precis, un chiffre par commune reste une
## moyenne sur toute sa superficie. Une commune de 800 km2 peut contenir une
## ville dense et des zones rurales vides ; l'enquete ne dit RIEN de cette
## variation interne.
##
## LA MEME SOLUTION : la covariable varie EN CONTINU dans l'espace (connue pour
## chaque cellule de 3 km). On applique donc la relation ajustee a l'echelle
## communale a chaque cellule.
##
## LA CONFUSION A INTERDIRE : ce n'est PAS UNE NOUVELLE MESURE, c'est une
## EXTRAPOLATION DU MODELE. Rien n'a ete observe a 3 km. La carte qui suit est
## la plus impressionnante de la journee, et la moins mesuree.
##
## Cette grille de 3 km n'a RIEN A VOIR avec les grilles de population a 100 m
## du J08 : deux grilles, deux significations.
## ----------------------------------------------------------------------

## ========================================================================
## 9.1 — RECONSTRUIRE L'EFFET ALEATOIRE ET PREDIRE
## ========================================================================
betas     <- fh$est$fit$estcoef[, "beta"]
beta0     <- betas["(Intercept)"]
beta_lc13 <- betas["lc_13_urbain_adm2"]
beta_lc8  <- betas["lc_8_savane_boisee_adm2"]

cat("Coefficients ajustes :\n")
cat("  intercept                :", round(beta0, 3), "\n")
cat("  part urbaine (lc_13)     :", round(beta_lc13, 3), "\n")
cat("  savane boisee (lc_8)     :", round(beta_lc8, 3), "\n")

# u_hat = EBLUP - partie expliquee par les covariables. C'est ce qui, dans la
# commune, echappe aux covariables : contexte local, marches, histoire,
# variables omises. Il est CONSTANT dans la commune.
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

# PIEGE DE NOMMAGE : les colonnes de la grille n'ont PAS le suffixe _adm2.
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

# CONTROLE INDISPENSABLE : une proportion predite peut sortir de [0, 100]. Le
# modele est lineaire, rien ne l'en empeche. On COMPTE, on ne tronque pas.
cat("Cellules predites HORS de l'intervalle [0, 100] :",
    sum(grille_pred$insecure_pred < 0 | grille_pred$insecure_pred > 100), "\n")

## ----------------------------------------------------------------------
## TROIS CONTROLES QUE CETTE PREDICTION IMPOSE
##
## 1. LES CELLULES SANS u_hat : une commune exclue ou jamais enquetee n'a pas
##    d'effet aleatoire. Le compteur dit combien de territoire disparait de la
##    carte finale -- chiffre a citer dans toute presentation du resultat.
## 2. LES VALEURS HORS BORNES : rien n'interdit mathematiquement -4 % ou 112 %.
##    Tronquer silencieusement embellirait la carte en dissimulant que le modele
##    est extrapole hors de son domaine de validite.
## 3. u_hat EST CONSTANT DANS LA COMMUNE : TOUTE la variation interne visible
##    vient des covariables. La carte de grille montre exactement la geographie
##    de la part de sol urbain et de savane boisee, translatee et mise a
##    l'echelle. Si les participants ne retiennent qu'une phrase, c'est celle-la.
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
## Ce que la figure code : une valeur PREDITE par un modele ajuste sur 76
##   communes. Aucune n'a ete observee : c'est la formule du modele evaluee en
##   15 000 points.
## Ce que les choix techniques font : meme echelle de couleurs que les cartes
##   communales -- delibere, pour que "la meme valeur donne la meme couleur". Le
##   rendu fin et continu est le danger : LA FINESSE GRAPHIQUE SE LIT
##   SPONTANEMENT COMME DE LA FINESSE DE MESURE. Le contour des communes est
##   maintenu pour rappeler l'unite d'ajustement.
## Ce qui se lit : la geographie des COVARIABLES a l'interieur des communes, et
##   les sauts brusques aux frontieres -- les u_hat, discontinus par
##   construction. Ces discontinuites montrent ou le modele s'arrete.
## Ce qui ne se lit pas : aucune variation infra-communale mesuree, aucune
##   incertitude, aucun menage. PRECISION N'EST PAS RESOLUTION. Une carte peut
##   etre tres fine et tres fausse -- la combinaison la plus dangereuse, parce
##   que la plus convaincante.
##
## LEGENDE A FAIRE ECRIRE : "Valeurs predites par un modele ajuste sur 76
## communes -- non mesurees a cette resolution."
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
## MODULE 10 — ACCESSIBILITE AUX SERVICES (BLOC DE REFERENCE, NON EXECUTE)
## ##########################################################################

## ----------------------------------------------------------------------
## MODULE NON EXECUTE -- RAISON TECHNIQUE
##
## TOUT LE CODE DE CE MODULE EST COMMENTE. Les deux fichiers dont il depend --
## datasets/DS.geojson (200 districts sanitaires) et datasets/gadm41_CMR_2.shp
## (58 departements, avec .shx .dbf .prj .cpg) -- NE SONT PAS PRESENTS sur le
## poste. Le code redevient executable des qu'ils rejoignent datasets/.
##
## DEUXIEME RAISON : le materiel d'origine construisait ses isochrones autour
## des coordonnees lues dans CMGC72FL.csv. Or ce fichier ne contient AUCUNE
## coordonnee (c'est le fichier des 130 covariables contextuelles par grappe
## DHS ; les positions sont dans CMGE71FL.shp). Le code d'origine etait donc
## faux et aurait echoue meme avec toutes les donnees presentes.
##
## LE VOCABULAIRE. Un ISOCHRONE relie les points atteignables en un MEME TEMPS
## de trajet. Ce qui suit n'en est pas un : ce sont des TAMPONS DE DISTANCE
## EUCLIDIENNE. Un tampon ignore le relief, les cours d'eau, l'etat des pistes,
## la saison des pluies, l'absence de pont. Un vrai isochrone passe par un
## reseau routier et un moteur de routage (osrm, OpenRouteService).
## ----------------------------------------------------------------------

# sf::sf_use_s2(FALSE)   # DS.geojson : 135 geometries invalides sur 200
#
# districts <- st_read("datasets/DS.geojson", quiet = TRUE) |> st_make_valid()
# cat("Districts sanitaires :", nrow(districts), "\n")
# cat("Champs disponibles :", paste(names(districts), collapse = ", "), "\n")
# cat("Geometries valides apres reparation :",
#     sum(st_is_valid(districts)), "sur", nrow(districts), "\n")
#
# ATTENTION AUX NOMS DE CHAMPS : ce fichier porte "name" et "parentName", pas
# nom_ds / code_ds. On adapte APRES avoir lu names(districts).
#
# departements <- st_read("datasets/gadm41_CMR_2.shp", quiet = TRUE) |>
#   st_make_valid()
#
# MESURER EXIGE DE REPROJETER : UTM 33N (EPSG:32633) pour le Cameroun.
# districts_utm <- st_transform(districts, 32633) |>
#   mutate(superficie_km2 = as.numeric(st_area(geometry)) / 1e6)
# print(summary(districts_utm$superficie_km2))
#
# CONTROLE PAR REFERENCE EXTERNE : la somme doit approcher 475 442 km2.
# cat("Superficie totale calculee :",
#     format(round(sum(districts_utm$superficie_km2)), big.mark = " "), "km2\n")
#
# HYPOTHESE DE TRAVAIL : faute de repertoire geolocalise des formations
# sanitaires, on utilise le CENTROIDE de chaque district comme point de service
# approche. CE N'EST PAS UN HOPITAL : la carte mesure "la distance au centre
# geometrique du district", pas "la distance au service".
# points_service <- st_centroid(districts_utm)
#
# buffer_5km  <- st_union(st_buffer(points_service, dist =  5000))
# buffer_10km <- st_union(st_buffer(points_service, dist = 10000))
# buffer_15km <- st_union(st_buffer(points_service, dist = 15000))
#
# Anneaux EXCLUSIFS : sans st_difference(), les surfaces se comptent deux fois.
# anneau_5_10  <- st_difference(buffer_10km, buffer_5km)
# anneau_10_15 <- st_difference(buffer_15km, buffer_10km)
# pays_utm     <- st_union(districts_utm)
# hors_15km    <- st_difference(pays_utm, buffer_15km)
#
# surf <- function(g) as.numeric(st_area(g)) / 1e6
# bilan_acces <- data.frame(
#   zone = c("moins de 5 km", "5 a 10 km", "10 a 15 km", "plus de 15 km"),
#   km2  = c(surf(buffer_5km), surf(anneau_5_10),
#            surf(anneau_10_15), surf(hors_15km))
# ) |>
#   mutate(part_pct = round(100 * km2 / surf(pays_utm), 1))
# print(bilan_acces)

## ----------------------------------------------------------------------
## SUPERFICIE COUVERTE N'EST PAS POPULATION COUVERTE
##
## Le tableau mesure des KILOMETRES CARRES ; une politique se decide sur des
## HABITANTS. Publier "38 % du territoire est a plus de 15 km d'un service" a la
## place de "12 % de la population est a plus de 15 km" n'est pas une
## approximation : c'est une autre affirmation, sur un autre sujet.
##
## La bonne methode, vue au J08 : croiser les tampons avec une GRILLE DE
## POPULATION (WorldPop 100 m) par exact_extract(). Le bloc ci-dessous suppose
## au contraire la population REPARTIE UNIFORMEMENT dans chaque district --
## hypothese fausse, mais explicite, pour rendre visible ce qu'elle coute.
## ----------------------------------------------------------------------

# districts_pop <- districts_utm |>
#   mutate(
#     zone_non_couverte = st_difference(geometry, buffer_5km),
#     part_non_couverte = as.numeric(st_area(zone_non_couverte)) /
#                         as.numeric(st_area(geometry))
#   )
# cat("Part moyenne de superficie a plus de 5 km d'un point de service :",
#     sprintf("%.1f %%", 100 * mean(districts_pop$part_non_couverte)), "\n")
#
# CARTE en quatre zones exclusives. Retour en WGS84 pour l'AFFICHAGE seulement.
# en_wgs <- function(g) st_sf(geometry = st_transform(g, 4326))
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
# tmap_save(carte_acces, "outputs/J10_accessibilite_sante.png",
#           width = 1600, height = 1800, dpi = 200)

## ----------------------------------------------------------------------
## LECTURE DE LA FIGURE -- CARTE DE COUVERTURE
##
## Ce que la figure code : quatre classes de distance EUCLIDIENNE a un point de
##   service approche par un centroide. Pas un temps de trajet.
## Ce que les choix techniques font : anneaux EXCLUSIFS (sinon double comptage).
##   Seuils 5/10/15 km conventionnels (marche, deux-roues, vehicule) : a
##   DECLARER, car passer de 5 a 8 km change entierement le message. Palette
##   vert-jaune-rouge ordonnee, qui PORTE UN JUGEMENT -- intentionnel ici.
## Ce qui se lit : la geographie du manque, et son caractere CONTIGU. On n'ouvre
##   pas un service par commune isolee, on couvre une zone.
## Ce qui ne se lit pas : relief, saison, pistes, ponts, cout du transport,
##   horaires, personnel, medicaments. Une structure ouverte sans personnel
##   produit la meme tache verte qu'un hopital de reference. Cette carte mesure
##   la DISTANCE, pas l'ACCES.
##
## EN QUOI LE SPATIAL EST UTILE ICI : "qui est loin de quoi ?" n'a AUCUNE
## formulation tabulaire -- la reponse depend de la position relative de deux
## couches. La carte n'illustre pas le resultat : elle EST le calcul.
## ----------------------------------------------------------------------


## ##########################################################################
## FIN DE JOURNEE
## ##########################################################################
##
## Le recapitulatif, le glossaire par domaine, le tableau des fonctions cles,
## les huit exercices et les prolongements vers J11 figurent dans
## demo_formateur_J10.qmd (section "Fin de journee") et dans
## scripts/script_formateur_J10.R. Ils ne sont pas dupliques ici : ce fichier
## est le CORRIGE DU CODE, distribue en fin de journee avec le rapport HTML.
## ##########################################################################

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



