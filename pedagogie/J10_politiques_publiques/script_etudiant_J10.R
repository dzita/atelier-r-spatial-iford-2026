## ============================================================================
## SCRIPT ETUDIANT -- TRAME A COMPLETER
## J10 -- LES DONNEES SPATIALES AU SERVICE DES POLITIQUES PUBLIQUES
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Jeudi 6 aout 2026
##
## MODE D'EMPLOI. Les commentaires portent la consigne : lisez-les, puis
## ecrivez votre code aux emplacements marques ">>> A COMPLETER". Avancez
## section par section, en verifiant chaque compteur avant de continuer.
## Le corrige complet est distribue en fin de journee
## (scripts/script_etudiant_J10_corrige.R).
##
## CETTE TRAME COMPTE 60 EMPLACEMENTS ">>> A COMPLETER".
##
## Les sections PACKAGES et LECTURE DES DONNEES sont COMPLETES : sans elles,
## rien ne tourne. Les trous commencent au premier verbe de manipulation.
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
## automatiquement au rendu ; Rscript, non. Ce script vit dans scripts/ : on
## remonte d'un cran.
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
## MODULE 0 — LE DOSSIER, LES PACKAGES, L'INVENTAIRE   [fourni en entier]
## ##########################################################################

## ========================================================================
## 0.2 — LES PACKAGES, ET UN ORDRE DE CHARGEMENT QUI COMPTE
## ========================================================================
# L'ORDRE DES DEUX PREMIERES LIGNES N'EST PAS INDIFFERENT.
# sae depend de MASS. MASS definit une fonction select(). Si dplyr est charge
# AVANT sae, c'est MASS::select() qui gagne, et tout appel a select() dans la
# suite du script echoue sur un message incomprehensible. En chargeant sae
# d'abord et dplyr ensuite, c'est dplyr::select() qui masque MASS::select().
# NE PAS REORDONNER CES LIGNES.
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
# La ligne ci-dessus DOIT afficher "dplyr". Si elle affiche "MASS", relancez R
# et rechargez les packages dans l'ordre ci-dessus.

## ========================================================================
## 0.3 — INVENTAIRE : CE QUE LA JOURNEE ATTEND
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


## ##########################################################################
## MODULE 1 — DONNEES EVENEMENTIELLES : LIRE ACLED
## ##########################################################################

## ----------------------------------------------------------------------
## UN EVENEMENT ACLED N'EST PAS UN FAIT VERIFIE : C'EST UN FAIT RAPPORTE.
## La base mesure conjointement l'activite conflictuelle ET l'activite des
## sources qui la rapportent. Toute la journee : ecrire "evenements rapportes".
## ----------------------------------------------------------------------

## ========================================================================
## 1.2 — LECTURE DU FICHIER   [fourni]
## ========================================================================
# Separateur : virgule. Un mauvais separateur renvoie UNE colonne unique, sans
# lever la moindre erreur -- d'ou le controle qui suit.
acled_brut <- read_csv("datasets/acled_cameroon_export.csv", show_col_types = FALSE)

cat("ACLED :", nrow(acled_brut), "lignes x", ncol(acled_brut), "colonnes\n")
cat("Une seule colonne lue ? ", ncol(acled_brut) == 1,
    "  (TRUE = mauvais separateur)\n\n")
print(names(acled_brut))

## ========================================================================
## 1.3 — CONTROLE DES VALEURS DOUTEUSES   [fourni]
## ========================================================================
# a) fatalities negatifs ? b) coordonnees (0,0), la sentinelle "null island" ?
# c) points hors emprise plausible du Cameroun ? d) qualite de la localisation.
cat("fatalities -- min :", min(acled_brut$fatalities, na.rm = TRUE),
    "| max :", max(acled_brut$fatalities, na.rm = TRUE),
    "| NA :", sum(is.na(acled_brut$fatalities)), "\n")
cat("fatalities negatifs :", sum(acled_brut$fatalities < 0, na.rm = TRUE), "\n")
cat("Coordonnees exactement (0, 0) :",
    sum(acled_brut$latitude == 0 & acled_brut$longitude == 0, na.rm = TRUE), "\n")
hors_emprise <- with(
  acled_brut,
  latitude < 1 | latitude > 14 | longitude < 8 | longitude > 17
)
cat("Points hors de l'emprise plausible du Cameroun :",
    sum(hors_emprise, na.rm = TRUE), "\n")
cat("\nRepartition de geo_precision (1 = lieu precis, 3 = region) :\n")
print(table(acled_brut$geo_precision, useNA = "ifany"))
cat("\nRepartition de time_precision (1 = jour connu, 3 = mois) :\n")
print(table(acled_brut$time_precision, useNA = "ifany"))

## ========================================================================
## 1.4 — NETTOYAGE ET CHAMP TEMPOREL
## ========================================================================
# TRAVAIL 1. Creez acled_clean a partir de acled_brut :
#   - convertissez event_date en Date, year en entier (colonne annee), creez
#     mois au format "%Y-%m", forcez fatalities, longitude et latitude en
#     numerique ;
#   - retirez les lignes sans coordonnees ET les coordonnees exactement (0, 0) ;
#   - AFFICHEZ le nombre de lignes avant, apres, et le nombre de lignes
#     retirees. Une suppression non comptee est une suppression cachee.
n_avant <- nrow(acled_brut)

# ......................................................................
# >>> A COMPLETER  (corrige : scripts/script_etudiant_J10_corrige.R)
# ......................................................................

# TRAVAIL 2. Bornez le champ d'analyse aux DIX DERNIERES ANNEES DU FICHIER.
# Attention : bornez sur max(annee) du fichier, PAS sur Sys.Date(). Un materiel
# pedagogique doit donner la meme sortie en 2026 et en 2030.
# Affichez le champ retenu et le nombre d'evenements conserves.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ========================================================================
## 1.5 — DEUX SERIES : LES EVENEMENTS, PUIS LES DECES
## ========================================================================
# TRAVAIL 3. resume_types : comptez les evenements par event_type, trie
# decroissant, et ajoutez une colonne part_pct (part en %).

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 4. resume_admin1 : comptez les evenements par admin1, c'est-a-dire
# par region TELLE QU'ACLED L'ECRIT. Affichez le tableau et le nombre d'admin1
# manquants. RETENEZ CES LIBELLES : ils sont le sujet du Module 2.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 5. graphe_annuel : comptez par annee ET event_type, puis tracez un
# graphique en BARRES EMPILEES (x = annee, y = effectif, fill = event_type).
# Palette qualitative (Set2), titre qui dit "evenements RAPPORTES", axe x avec
# une graduation par annee.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 6. resume_deces : par annee, la somme de fatalities, le nombre
# d'evenements, et le rapport des deux (deces_par_evenement). Cette troisieme
# colonne est ce qui separe "plus d'evenements" de "des evenements plus
# meurtriers" -- deux phenomenes que la courbe des deces seule confond.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 7. graphe_deces : courbe + points, x = annee, y = deces.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 2 — DU POINT AU POLYGONE : LA JOINTURE QUI ECHOUE EN SILENCE
## ##########################################################################

## ========================================================================
## 2.1 — CONVERTIR LES EVENEMENTS EN COUCHE SPATIALE
## ========================================================================
# TRAVAIL 8. Creez acled_pts avec st_as_sf().
#   ATTENTION : l'ordre des coordonnees est c(longitude, latitude), et JAMAIS
#   l'inverse. sf ne verifie rien : une inversion ne leve aucune erreur, elle
#   deplace simplement tout le Cameroun dans l'ocean Indien.
#   Posez crs = 4326 et gardez les colonnes lon/lat (remove = FALSE).
#   Affichez ensuite le nombre d'entites, le CRS et la bbox.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## --- Lecture des limites administratives   [fourni] --------------------------
# On liste d'abord les couches du GeoPackage : on ne suppose pas leur nom.
couches_gadm <- st_layers("datasets/gadm41_CMR.gpkg")
print(couches_gadm)

cmr0 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_0", quiet = TRUE)
cmr1 <- st_read("datasets/gadm41_CMR.gpkg", layer = "ADM_ADM_1", quiet = TRUE)

cat("\nADM_ADM_0 (pays)    :", nrow(cmr0), "entite(s)\n")
cat("ADM_ADM_1 (regions) :", nrow(cmr1), "entites\n")
cat("\nLibelles NAME_1 tels que GADM les ecrit :\n")
print(sort(cmr1$NAME_1))

## ----------------------------------------------------------------------
## COMPAREZ LES DEUX LISTES DE LIBELLES (ACLED admin1, GADM NAME_1).
## ACLED ecrit en FRANCAIS SANS ACCENTS (Sud, Extreme-Nord) ; GADM en ANGLAIS
## (South, Far North). Ce n'est PAS un probleme d'accents, c'est un probleme de
## LANGUE. Et pourtant left_join() acceptera la jointure sans broncher.
## Nous allons PROVOQUER l'accident avant de le corriger.
## ----------------------------------------------------------------------

## ========================================================================
## 2.2 — TENTATIVE N.1 : JOINDRE PAR LE LIBELLE
## ========================================================================
# TRAVAIL 9. Faites la jointure DELIBEREMENT FAUSSE : partez de cmr1 (toujours
# de la couche, jamais du tableau), retirez la geometrie, gardez NAME_1, et
# joignez resume_admin1 par c("NAME_1" = "admin1").
# COMPTEZ ensuite : regions appariees, regions NA. Imprimez le resultat.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 10. Cote ACLED : combien d'evenements se retrouveraient orphelins ?
# Filtrez les evenements dont admin1 n'est pas dans cmr1$NAME_1, affichez leur
# nombre, leur part en %, et la liste des libelles concernes.
# Traduisez le pourcentage en langage de salle avant de continuer.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ========================================================================
## 2.3 — TENTATIVE N.2 : NORMALISER LES CHAINES
## ========================================================================
# TRAVAIL 11. Ecrivez une fonction normaliser(x) qui retire les accents
# (iconv vers "ASCII//TRANSLIT"), passe en minuscules et supprime tout ce qui
# n'est pas une lettre a-z. Appliquez-la aux deux jeux de libelles et comptez
# les cles communes. Que constatez-vous ? Pourquoi ?

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ========================================================================
## 2.4 — TENTATIVE N.3 : LA TABLE DE CORRESPONDANCE ECRITE A LA MAIN
## ========================================================================
# TRAVAIL 12. Ecrivez corresp_regions, une table a deux colonnes
# (admin1_acled, NAME_1_gadm) couvrant les DIX regions. Dix lignes ecrites a la
# main : ce n'est pas un bricolage, c'est une DECISION DE METHODE.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 13. Les DEUX controles obligatoires, avec setdiff(), DANS LES DEUX
# SENS : libelles de la table absents de la couche (= faute de frappe), et
# libelles de la couche absents de la table (= region oubliee). Puis les
# libelles ACLED absents de la table. Les trois listes doivent etre vides.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ========================================================================
## 2.5 — LA ROUTE SURE : LA JOINTURE SPATIALE st_within
## ========================================================================
# TRAVAIL 14. a) Affichez les CRS des deux couches et verifiez qu'ils sont
# identiques ; reprojetez si besoin. b) Faites la jointure spatiale de acled_pts
# vers cmr1[c("NAME_1")] avec join = st_within. c) DEUX CONTROLES : le nombre de
# lignes avant/apres (st_join peut DUPLIQUER si des polygones se recouvrent), et
# le nombre de points tombes hors de toute region -- qui ne sont pas des dechets
# mais une information.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 15. CONFRONTATION : ce que dit le LIBELLE d'ACLED contre ce que dit la
# POSITION. Joignez corresp_regions au resultat, creez une colonne accord
# (NAME_1 == NAME_1_gadm), comptez les accords et les desaccords, et listez le
# detail des desaccords. Le taux de desaccord est un indicateur de qualite a
# publier a cote de la carte.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ========================================================================
## 2.6 — AGREGATION REGIONALE ET CARTE CHOROPLETHE
## ========================================================================
# TRAVAIL 16. resume_par_region : a partir du resultat spatial, retirez la
# geometrie, ecartez les NAME_1 manquants, puis par NAME_1 calculez
# n_evenements, deces (somme de fatalities) et n_batailles.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 17. cmr1_acled : partez de cmr1, joignez resume_par_region par
# NAME_1, COMPTEZ les NA et dites lesquelles, PUIS seulement remplacez les NA
# par 0.
#   POURQUOI C'EST LEGITIME ICI : la jointure est spatiale, donc une region
#   absente du tableau est une region ou AUCUN evenement n'a ete rapporte -- le
#   zero est une MESURE. Avec la jointure par libelle du 2.2, le meme
#   replace_na(0) aurait fabrique de fausses regions pacifiees.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 18. carte_types : tmap_mode("plot"), puis les regions en fond
# (tm_borders), les points colores par event_type (tm_dots, fill_alpha 0.6), et
# la frontiere nationale par-dessus. Legende a l'exterieur.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 19. carte_regions : choroplethe de n_evenements, discretisation en
# QUANTILES a 5 classes, palette sequentielle "brewer.reds". Interrogez-vous :
# qu'auraient donne des intervalles egaux ? un decoupage de Jenks ?

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ----------------------------------------------------------------------
## MAUP -- vous venez de passer d'un semis de points a un decoupage en
## polygones. EFFET D'ECHELLE : les memes points agreges par region, par
## departement ou par arrondissement donnent trois cartes differentes. EFFET DE
## ZONAGE : a nombre d'unites constant, deplacer les limites change tout.
## Aucune maille n'est neutre : on agrege a la MAILLE DE LA DECISION.
## ERREUR ECOLOGIQUE : la carte decrit l'agregat, pas les individus.
## ----------------------------------------------------------------------

# TRAVAIL 20. Exports du bloc ACLED : les deux couches en .gpkg, les trois
# tableaux en .csv, les deux graphiques et les deux cartes en .png.
# TOUT dans outputs/, prefixe J10_. JAMAIS dans datasets/.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 3 — REANALYSE CLIMATIQUE : OUVRIR UN NETCDF
## ##########################################################################

## ----------------------------------------------------------------------
## ERA5 est une REANALYSE : ni une observation, ni une prevision, mais un
## modele atmospherique force a rester coherent avec les observations
## disponibles. Champ COMPLET et REGULIER (une valeur partout, tous les mois),
## resolution ~31 km, UNITE = KELVIN.
## ----------------------------------------------------------------------

## ========================================================================
## 3.2 — OUVRIR LE NETCDF ET L'INTERROGER   [fourni]
## ========================================================================
era5_brut <- rast("datasets/era5_t2m_mensuel_cameroun.nc")

cat("Nombre de couches (pas de temps) :", nlyr(era5_brut), "\n")
cat("Resolution :", paste(round(res(era5_brut), 4), collapse = " x "), "degres\n")
cat("CRS :", crs(era5_brut, describe = TRUE)$name, "\n")
print(ext(era5_brut))
print(head(names(era5_brut), 6))

dates_era5 <- as.Date(time(era5_brut))
cat("\nDates lisibles ?", !all(is.na(dates_era5)), "\n")
cat("Premiere couche :", format(min(dates_era5), "%Y-%m"), "\n")
cat("Derniere couche :", format(max(dates_era5), "%Y-%m"), "\n")

# CONTROLE D'UNITE : l'ordre de grandeur trahit le Kelvin.
valeurs_couche1 <- values(era5_brut[[1]], na.rm = TRUE)
cat("\nCouche 1 -- moyenne :", round(mean(valeurs_couche1), 2), "\n")
cat("Ordre de grandeur ~300 => KELVIN. Ordre de grandeur ~25 => Celsius.\n")

## ========================================================================
## 3.3 — CONVERSION EN CELSIUS, DECOUPE NATIONALE
## ========================================================================
# TRAVAIL 21. Convertissez le raster en degres Celsius. Une soustraction, la
# ligne la plus facile a oublier de toute la journee. Affichez ensuite min,
# moyenne et max de la premiere couche convertie et jugez la plausibilite
# (attendu : environ 15 a 40 C pour le Cameroun).

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 22. a) Transformez cmr0 en SpatVector dans le CRS du raster (vect +
# st_transform). b) Rognez (crop) PUIS masquez (mask) : les deux sont
# necessaires, crop seul laisserait le Nigeria et le Tchad. c) Affichez les
# dimensions, le nombre de couches et le nombre de cellules non vides.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 23. CONTROLE VISUEL OBLIGATOIRE apres tout decoupage : tracez la
# premiere couche avec plot(), titre indiquant le mois, et superposez les
# limites regionales. Une erreur de CRS ne se voit pas dans les chiffres.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 4 — EXTRACTION ZONALE TEMPORELLE
## ##########################################################################

# TRAVAIL 24. a) Reprojetez cmr1 dans le CRS du raster et affichez les deux CRS.
# b) Extrayez la moyenne de chaque couche par region avec exact_extract().
#    exact_extract() pondere par la FRACTION de cellule couverte : sur une
#    maille de 31 km, la difference avec une extraction par centroide n'est pas
#    negligeable.
# c) CONTROLES : dimensions de la matrice extraite, coherence avec le nombre de
#    regions et de couches, valeurs manquantes.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 25. Remettez en forme longue (t2m_long).
#   PIEGE : exact_extract() prefixe ses colonnes par "mean.", et l'ordre
#   ALPHABETIQUE des noms n'est PAS l'ordre chronologique ("t2m_10" < "t2m_2"
#   en tri texte). Retrouvez donc l'indice de chaque couche par match() sur
#   paste0("mean.", names(era5_cmr)), puis la date par dates_era5[idx].
#   CONTROLES : nombre de lignes attendu (regions x mois), idx non apparies,
#   dates manquantes, temperatures manquantes.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 26. t2m_national : moyenne par date. Attention a ce que vous venez de
# calculer : c'est une MOYENNE DE MOYENNES NON PONDEREE (chaque region pese
# pareil, quelle que soit sa superficie ou sa population).

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 27. graphe_t2m_serie : courbe de la serie + tendance LOESS avec sa
# bande de confiance (se = TRUE). Rappelez dans le sous-titre que la bande est
# l'intervalle de confiance DE LA COURBE LISSEE, pas l'etendue des valeurs.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 28. t2m_saisonnalite : par mois (1-12), la moyenne, le minimum, le
# maximum, le nombre d'observations, puis une colonne amplitude = max - min.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 29. graphe_saisonnalite : ligne de la moyenne + ruban min/max
# (geom_ribbon), axe x avec les abreviations de mois.
#   Un ruban min/max n'est NI un intervalle de confiance NI un ecart-type : il
#   melange variation spatiale et variation interannuelle, et il est gouverne
#   par les extremes. Dites-le dans le sous-titre.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 30. t2m_moy_rast : moyenne du raster sur toutes les couches, puis
# carte tmap avec la palette divergente inversee "-brewer.rd_yl_bu" (le "-"
# inverse le degrade pour que le rouge code le chaud), limites regionales et
# frontiere nationale superposees.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 31. Exports ERA5 : trois .csv, un .tif, deux .png de graphiques et un
# .png de carte, tous dans outputs/ avec le prefixe J10_.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 5 — UNE ENQUETE NE SUFFIT PAS (BENIN)
## ##########################################################################

## ----------------------------------------------------------------------
## POURQUOI CETTE PARTIE CHANGE DE PAYS
##
## Le SAE suppose une enquete dont on puisse calculer, par domaine, une
## estimation directe ET sa variance reelle : poids, grappes, geolocalisation.
## L'extrait camerounais dont l'atelier dispose (ecam5.dta) echoue au controle
## de reference : national conforme a l'INS (38,6 % contre 37,7 %), mais A
## L'INTERIEUR DES REGIONS il decroche (Est a 7,5 % contre 41,5 % publie). Un
## exercice SAE dessus produirait des chiffres qu'il faudrait interdire de
## citer. On apprend donc ici la METHODE, pas un diagnostic sur le Cameroun.
##
## Provenance : depot github.com/JoshMerfeld/saereplication (J. Merfeld) ;
## enquete EHCVM 2018-2019, Benin (Banque mondiale, catalogue 4291). Usage
## strictement pedagogique. Methode ADAPTEE (modele d'aire) et non reproduite
## (le depot ajuste un modele unitaire).
## ----------------------------------------------------------------------

## ========================================================================
## 5.1 — LECTURE DES DONNEES BENINOISES   [fourni]
## ========================================================================
# Une ligne = UN MENAGE (pas un individu).
menages <- read_csv("datasets/ehcvm2018_benin_menages.csv", show_col_types = FALSE)

cat("EHCVM Benin :", nrow(menages), "menages x", ncol(menages), "colonnes\n")
cat("Colonnes reelles :", paste(names(menages), collapse = ", "), "\n")
cat("Grappes distinctes :", n_distinct(menages$grappe), "\n")
cat("Part BRUTE (non ponderee) de menages en insecurite :",
    sprintf("%.2f %%", 100 * mean(menages$insecure, na.rm = TRUE)), "\n")
cat("hhweight -- min :", round(min(menages$hhweight), 1),
    "| max :", round(max(menages$hhweight), 1), "\n")

print(st_layers("datasets/gadm_ben_communes.gpkg"))
print(st_layers("datasets/benin_grille_3km.gpkg"))

ben_communes <- st_read("datasets/gadm_ben_communes.gpkg",
                        layer = "ben_adm2_communes", quiet = TRUE)
ben_grille   <- st_read("datasets/benin_grille_3km.gpkg",
                        layer = "grille_3km", quiet = TRUE)

cat("\nCommunes (admin2) :", nrow(ben_communes),
    "| Cellules de grille :", nrow(ben_grille), "\n")
cat("Champs de ben_communes :", paste(names(ben_communes), collapse = ", "), "\n")
cat("admin2Pcod est-il une cle unique ?",
    n_distinct(ben_communes$admin2Pcod) == nrow(ben_communes), "\n")

covariables_admin2 <- read_csv("datasets/benin_covariables_admin2.csv",
                               show_col_types = FALSE)
covariables_grille <- read_csv("datasets/benin_covariables_grille.csv",
                               show_col_types = FALSE)

cat("\nCovariables par commune :", ncol(covariables_admin2), "colonnes\n")
print(names(covariables_admin2))
cat("\nCovariables par cellule :", ncol(covariables_grille), "colonnes\n")
print(names(covariables_grille))
# MEMES variables, NOMS DIFFERENTS : suffixe "_adm2" par commune, sans suffixe
# par cellule. Retenez-le : c'est un piege au Module 9.

## ----------------------------------------------------------------------
## insecure vaut 1 si le menage a DECLARE avoir connu une situation
## d'insecurite alimentaire. C'est une DECLARATION, pas une mesure. L'unite est
## le MENAGE, pas l'individu (biais de taille). La date compte : 2018-2019.
## ----------------------------------------------------------------------

## ========================================================================
## 5.2 — RATTACHER CHAQUE MENAGE A SA COMMUNE
## ========================================================================
# TRAVAIL 32. Le fichier menages ne porte PAS admin2Pcod : il porte id,
# l'identifiant de la cellule de 3 km. C'est covariables_grille qui fait le pont
# id -> admin2Pcod.
#   a) construisez la table de passage (id, admin2Pcod), en distinct() ;
#   b) VERIFIEZ qu'aucun id n'y est en double -- sinon la jointure DUPLIQUERA
#      des menages ;
#   c) joignez, puis comptez : menages avant/apres, duplications, menages sans
#      commune, et communes representees sur le total du pays.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ========================================================================
## 5.3 — LE PLAN DE SONDAGE
## ========================================================================
## ----------------------------------------------------------------------
## TROIS RAISONS DE NE PAS ECRIRE mean(insecure)
## 1. LES POIDS : un menage represente hhweight menages du pays. Sans les poids
##    on decrit L'ECHANTILLON, pas la POPULATION.
## 2. LES GRAPPES : sondage a deux degres. Ignorer la structure DIVISE
##    ARTIFICIELLEMENT l'erreur-type -- fausse certitude. Pour le SAE, fatal :
##    la variance est un INGREDIENT du modele.
## 3. LE BON POIDS A CHAQUE ETAGE. La moyenne d'une moyenne n'est pas la moyenne.
## svydesign() ne calcule rien : il DECRIT le plan une fois pour toutes.
## ----------------------------------------------------------------------

# TRAVAIL 33. Declarez le plan de sondage avec svydesign() : ids = ~grappe,
# weights = ~hhweight. Imprimez l'objet.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 34. Comparez, au niveau national : la moyenne BRUTE (sans poids) et
# la moyenne PONDEREE (svymean), en %. Affichez l'ecart et l'erreur-type.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 35. Refaites le meme calcul EN IGNORANT les grappes (ids = ~1) et
# comparez les deux erreurs-types. Leur rapport approche l'EFFET DE GRAPPE.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ========================================================================
## 5.4 — ESTIMATION DIRECTE PAR COMMUNE
## ========================================================================
# TRAVAIL 36. direct_svy : appliquez svyby(~insecure, ~admin2Pcod, plan,
# svymean). C'est l'equivalent d'un group_by()+summarise(mean()) -- sauf que
# celui-ci ignorerait poids ET grappes, et donnerait une erreur-type
# sous-estimee, donc inutilisable comme entree du modele.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 37. Calculez, par commune, le nombre de menages (n_menages) et le
# nombre de GRAPPES distinctes (n_grappes). La seconde est celle qui compte
# pour la suite.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 38. direct_admin2 : assemblez admin2Pcod, insecure_direct
# (coef * 100), se_direct (SE * 100), puis joignez n_menages et n_grappes.
# Affichez les distributions (min, mediane, max) des deux effectifs.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 39. LE MOMENT DE METHODE. a) Reperez les communes a UNE SEULE grappe
# et celles dont se_direct est NA ou nul. b) MEMORISEZ leur code dans un
# vecteur communes_exclues AVANT de les retirer -- elles devront apparaitre en
# GRIS sur les cartes du Module 8, pas disparaitre. c) Filtrez et creez
# var_direct = se_direct^2. d) Affichez conservees / exclues / sans estimation.
#   POURQUOI : la variance s'estime ENTRE LES GRAPPES. Avec une seule grappe,
#   il n'y a rien entre quoi la calculer. Une variance a zero declarerait au
#   modele que l'estimation est PARFAITEMENT PRECISE, et lui donnerait un poids
#   infini. Le seuil (n_grappes == 1) est DECLARE dans le code, pas subi.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 40. graphe_precision : se_direct en fonction de n_menages, abscisse en
# echelle LOG. C'est le PROBLEME que le SAE vient resoudre. Ajoutez la
# correlation entre log(n_menages) et se_direct.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 6 — CHOISIR UNE COVARIABLE AUXILIAIRE
## ##########################################################################

## ----------------------------------------------------------------------
## Le modele a besoin d'une information CONNUE PARTOUT et CORRELEE a ce qu'on
## estime. Elle n'a pas besoin d'etre une cause : elle doit predire.
## Candidates : ntl_mean_adm2, population_adm2, ndvi_mean_adm2,
## precip_2018_adm2, no2_adm2, lc_13_urbain_adm2, lc_12_cultures_adm2,
## lc_8_savane_boisee_adm2, lc_11_zones_humides_adm2.
## ----------------------------------------------------------------------

# TRAVAIL 41. Joignez direct_admin2 a covariables_admin2 par admin2Pcod, et
# COMPTEZ les duplications introduites (doit valoir 0).

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 42. CRIBLAGE : verifiez d'abord que les neuf candidates existent bien
# dans le fichier (setdiff) et comptez leurs NA. Puis calculez la correlation de
# chacune avec insecure_direct et triez par valeur absolue decroissante.
#   Pearson mesure une association LINEAIRE ; sur des variables dissymetriques,
#   Spearman serait souvent plus honnete.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 43. COLINEARITE : calculez la matrice de correlation entre candidates
# et listez explicitement les paires correlees a plus de 0,7 en valeur absolue.
# Le seuil est CONVENTIONNEL : il declenche une discussion, il ne tranche pas.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 44. sae_data : gardez admin2Pcod, n_menages, n_grappes,
# insecure_direct, se_direct, var_direct et les DEUX covariables retenues
# (lc_13_urbain_adm2, lc_8_savane_boisee_adm2). Convertissez en data.frame
# (sae::mseFH n'accepte pas un tibble). Comptez les lignes incompletes.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 7 — FAY-HERRIOT
## ##########################################################################

## ----------------------------------------------------------------------
##     p_i = x_i . beta + u_i + e_i,  u_i ~ N(0, sigma2_u), e_i ~ N(0, psi_i)
## e_i : erreur d'echantillonnage, CONNUE (var_direct). u_i : ce qui echappe
## aux covariables, estimee. L'EBLUP est une moyenne ponderee entre estimation
## directe et prediction du modele : variance grande -> tire vers le modele
## (on emprunte de la force) ; variance petite -> l'estimation directe est
## conservee.
## ----------------------------------------------------------------------

# TRAVAIL 45. Ajustez le modele avec mseFH() : formule
# insecure_direct ~ lc_13_urbain_adm2 + lc_8_savane_boisee_adm2,
# vardir = var_direct. Affichez la convergence, le nombre d'iterations,
# sigma2_u (fh$est$fit$refvar), la variance d'echantillonnage moyenne et LEUR
# RAPPORT -- c'est la cle de lecture de tout ce qui suit. Imprimez ensuite les
# coefficients et les mesures d'ajustement.
#   CONTROLE : le signe de chaque beta doit correspondre au signe de la
#   correlation du Module 6. Une inversion signale une colinearite.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 46. Ajoutez a sae_data : insecure_fh (fh$est$eblup[, 1]), rmse_direct
# (racine de var_direct), rmse_fh (racine de fh$mse), gain_rmse (difference),
# gain_pct et deplacement (insecure_fh - insecure_direct). Affichez les
# statistiques du gain, le nombre de communes a gain NEGATIF, et les dix
# communes les plus corrigees.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 47. comparaison_long : joignez les noms de commune (adm2_name), puis
# pivot_longer avec names_to = c(".value", "methode") et
# names_pattern = "(.*)_(direct|fh)". Verifiez que le nombre de lignes vaut bien
# deux fois le nombre de communes.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 48. graphe_comparaison : geom_pointrange avec ymin/ymax =
# estimation +/- 1,96 x rmse, coord_flip(), couleur par methode.
#   Attention : les deux barres ne sont PAS de meme nature (erreur-type
#   d'echantillonnage d'un cote, racine d'EQM d'un predicteur de l'autre).

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 49. LE VRAI TEST DU MECANISME. graphe_gain_n : gain_rmse en fonction
# de n_menages, abscisse en LOG, ligne horizontale a zero, taille des points =
# n_grappes, tendance LOESS.
#   Si le lissage fonctionne comme la theorie le prevoit, la courbe doit
#   DECROITRE : le gain doit etre maximal la ou l'echantillon est petit. Une
#   courbe plate signifierait que les covariables n'apportent rien.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 50. Le meme test EN CHIFFRES, qui ne depend pas du lissage : coupez
# n_menages en trois tiers (quantiles), et affichez par tiers le nombre de
# communes, la mediane de n_menages, le gain moyen et le gain relatif moyen.
# Ajoutez la correlation entre log(n_menages) et gain_rmse : elle doit etre
# NEGATIVE.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 8 — TROIS CARTES A ECHELLE COMMUNE
## ##########################################################################

# TRAVAIL 51. communes_sae : partez de ben_communes (jamais de sae_data), faites
# un left_join -- un inner_join ferait disparaitre de la carte, donc du
# raisonnement, les communes sans estimation. Ajoutez une colonne statut a trois
# modalites : "Estimee", "Exclue (une seule grappe)", "Non enquetee". Affichez
# la repartition.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 52. Calculez limites_insecurite : l'etendue commune aux deux series
# (insecure_direct et insecure_fh). Sans cette echelle imposee, deux palettes
# calculees separement donneraient au meme niveau deux couleurs differentes, et
# la comparaison visuelle -- tout l'objet de la figure -- serait fausse.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 53. Les trois cartes, puis tmap_arrange(..., ncol = 3) :
#   1. insecure_direct, palette SEQUENTIELLE "brewer.blues", limits imposees ;
#   2. insecure_fh, MEME palette, MEMES limits ;
#   3. gain_rmse, palette DIVERGENTE "-brewer.rd_bu" centree sur zero.
#   Dans les trois : value.na = "grey85" et un label.na explicite, pour que les
#   communes sans estimation soient GRISES et NOMMEES dans la legende -- jamais
#   a zero, jamais effacees.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 54. Exports SAE : sae_data et la liste des communes exclues en .csv,
# communes_sae en .gpkg, les trois graphiques et la planche de cartes en .png.

# ......................................................................
# >>> A COMPLETER
# ......................................................................


## ##########################################################################
## MODULE 9 — PRECISION N'EST PAS RESOLUTION
## ##########################################################################

## ----------------------------------------------------------------------
## PROBLEME 1, LA PRECISION : l'estimation directe est bruitee la ou
## l'echantillon est petit ; Fay-Herriot la lisse. TOUJOURS UN CHIFFRE PAR
## COMMUNE : la resolution n'a pas bouge.
## PROBLEME 2, LA RESOLUTION : un chiffre par commune reste une moyenne sur
## toute sa superficie. La covariable, elle, varie EN CONTINU (grille de 3 km).
## LA CONFUSION A INTERDIRE : appliquer le modele a la grille n'est PAS UNE
## NOUVELLE MESURE, c'est une EXTRAPOLATION. Rien n'a ete observe a 3 km.
## ----------------------------------------------------------------------

# TRAVAIL 55. Extrayez les trois coefficients de fh$est$fit$estcoef[, "beta"]
# (intercept, lc_13, lc_8) et affichez-les.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 56. Reconstruisez l'effet aleatoire de commune :
#   u_hat = insecure_fh - (beta0 + beta_lc13 * lc_13_urbain_adm2
#                                + beta_lc8  * lc_8_savane_boisee_adm2)
# Affichez sa moyenne, son ecart-type, son etendue, et le rapport
# sd(u_hat) / sd(insecure_fh).
#   u_hat est CONSTANT dans la commune : toute la variation interne de la carte
#   a venir viendra donc des covariables, et d'elles seules.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 57. grille_pred : joignez u_hat a covariables_grille par admin2Pcod et
# calculez insecure_pred avec les MEMES coefficients.
#   PIEGE DE NOMMAGE : cote grille, les colonnes s'appellent lc_13_urbain et
#   lc_8_savane_boisee -- SANS le suffixe _adm2.
# Comptez les cellules sans u_hat (commune exclue ou non enquetee) AVANT de les
# retirer : ce chiffre doit figurer dans toute presentation du resultat.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 58. CONTROLE INDISPENSABLE : comptez les cellules dont la prediction
# sort de l'intervalle [0, 100]. Le modele est lineaire et la variable est une
# proportion : rien ne l'en empeche. On COMPTE, on ne tronque pas en silence.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 59. grille_sae : joignez les predictions a ben_grille par id, comptez
# les cellules cartographiees et celles perdues a la jointure. Puis la carte,
# avec LA MEME echelle de couleurs que les cartes communales et le contour des
# communes par-dessus -- pour rappeler l'unite a laquelle le modele a
# reellement ete ajuste.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

# TRAVAIL 60. Exports de la grille : le .csv des predictions, le .gpkg, le .png.
# Puis listez tout le contenu de outputs/.

# ......................................................................
# >>> A COMPLETER
# ......................................................................

## ----------------------------------------------------------------------
## L'AVERTISSEMENT QUI DOIT ACCOMPAGNER LA CARTE DE GRILLE
##
## Chaque cellule porte une valeur PREDITE par un modele ajuste sur 76 communes.
## Aucune n'a ete observee. Le rendu fin et continu se lit spontanement comme de
## la finesse de mesure : c'est precisement le danger. Les sauts brusques aux
## frontieres communales sont les u_hat, discontinus par construction -- ils
## montrent ou le modele s'arrete.
##
## Legende a ecrire : "Valeurs predites par un modele ajuste sur 76 communes --
## non mesurees a cette resolution."
## ----------------------------------------------------------------------


## ##########################################################################
## MODULE 10 — ACCESSIBILITE AUX SERVICES   [non traite en salle]
## ##########################################################################
##
## Ce module depend de datasets/DS.geojson et datasets/gadm41_CMR_2.shp, qui ne
## sont pas presents sur le poste. Son code de reference figure, entierement
## commente, dans scripts/script_etudiant_J10_corrige.R et dans
## demo_formateur_J10.qmd.
##
## Ce qu'il faut en retenir sans l'executer :
##  - un ISOCHRONE relie les points atteignables en un MEME TEMPS de trajet ; un
##    TAMPON de 5 km est une distance a vol d'oiseau. Ce n'est pas la meme
##    chose, et l'ecart entre les deux est enorme en relief ou en saison des
##    pluies ;
##  - MESURER EXIGE DE REPROJETER : jamais de distance calculee en degres ;
##  - les anneaux doivent etre EXCLUSIFS (st_difference), sinon les surfaces se
##    comptent deux fois ;
##  - SUPERFICIE COUVERTE N'EST PAS POPULATION COUVERTE. Publier "38 % du
##    territoire est a plus de 15 km d'un service" a la place de "12 % de la
##    population" n'est pas une approximation : c'est une autre affirmation.
##
## ##########################################################################

cat("=== FIN DE LA TRAME J10 ===\n")
cat("60 emplacements a completer. Corrige : scripts/script_etudiant_J10_corrige.R\n")
