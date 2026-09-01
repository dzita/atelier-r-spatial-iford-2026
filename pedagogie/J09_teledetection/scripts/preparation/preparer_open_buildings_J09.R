## ============================================================================
## J09 -- PREPARATION DE LA COUCHE OPEN BUILDINGS (zone de Yagoua)
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Mercredi 5 aout 2026
##
## *** NON EXECUTABLE EN SALLE ***
##
## Ce script N'EST PAS un exercice et ne doit PAS etre lance pendant l'atelier.
## Ses entrees -- les tuiles Open Buildings brutes au format CSV.GZ -- NE SONT
## PAS LIVREES avec la journee : elles pesent plusieurs gigaoctets par tuile et
## couvrent une zone bien plus large que Yagoua.
##
## Il est conserve ici comme TRACE DE PROVENANCE du fichier
## datasets/open_buildings_yagoua.gpkg utilise au module 6 : il documente
## exactement quelle emprise a ete retenue, avec quelle marge, et quelles
## colonnes ont ete conservees. Sans cette trace, le .gpkg serait une donnee
## tombee du ciel -- ce que la regle 1.1 de l'atelier interdit ("le fichier de
## donnees fait autorite, jamais le code" suppose qu'on sache d'ou il vient).
##
## Pour le rejouer (hors salle) : telecharger les tuiles Open Buildings
## correspondantes depuis https://sites.research.google/open-buildings/ et les
## deposer dans le dossier declare par tuiles_dir ci-dessous.
##
## Licence : Google Open Buildings, CC BY 4.0. Toute reutilisation doit citer
## Google Research / Open Buildings.
## ============================================================================

library(sf)
library(dplyr)
library(readr)

sf_use_s2(FALSE)   # meme reglage que le materiel de la journee
crs_mesure <- 32633

## ----------------------------------------------------------------------------
## PARAMETRES -- a adapter par le formateur avant execution hors salle
## ----------------------------------------------------------------------------
## Les tuiles brutes ne sont PAS dans datasets/ : elles ne font pas partie de
## la journee. Indiquer ici le dossier ou elles ont ete telechargees.
tuiles_dir <- file.path("~", "open_buildings_tuiles_brutes")

## Sortie : elle est ecrite dans outputs/, PAS dans datasets/. C'est le
## formateur qui, une fois le fichier valide, le verse au magasin central de
## donnees d'ou l'outil de distribution le recopiera.
sortie_gpkg <- file.path("outputs", "open_buildings_yagoua.gpkg")

## Emprise de reference : l'AOI01 officielle de l'activation EMSR772, plus une
## marge. Le shapefile, lui, EST livre avec la journee.
chemin_aoi01 <- file.path("datasets", "EMSR772_AOI01_areaOfInterestA.shp")
marge_m      <- 5000

dir.create("outputs", showWarnings = FALSE)

cat("=== Preparation Open Buildings -- zone de Yagoua ===\n")
cat("Tuiles brutes attendues dans :", tuiles_dir, "\n")
cat("Sortie                       :", sortie_gpkg, "\n")

## ============================================================================
## Etape 1 : construire l'emprise de reference "Yagoua"
## ============================================================================
## L'activation EMSR772 couvre trois localites distinctes et eloignees :
## AOI01 = Yagoua, AOI02 = Makari, AOI03 = Waza, jusqu'a environ 300 km
## d'ecart. Pour rester "autour de Yagoua", on ne garde que l'AOI01, avec une
## marge de 5 km.
##
## CONSEQUENCE A CONNAITRE, ET ELLE EST ENSEIGNEE AU MODULE 9 : la couche
## produite NE COUVRE PAS AOI02 ni AOI03. Y appliquer la fonction
## analyser_inondation() renvoie zero batiment -- ce qui n'est PAS "aucun
## batiment touche", mais "aucune donnee". Le module 9 met ce piege en scene
## avec un garde-fou explicite.

if (!file.exists(chemin_aoi01))
  stop("AOI01 introuvable : ", chemin_aoi01)

aoi01 <- sf::st_make_valid(sf::st_read(chemin_aoi01, quiet = TRUE))

cat("\nAOI01 lue :", nrow(aoi01), "polygone(s), CRS", sf::st_crs(aoi01)$input, "\n")
if ("locality" %in% names(aoi01))
  cat("Localite declaree :", paste(aoi01$locality, collapse = ", "), "\n")

## La marge est une DISTANCE : elle se pose en CRS metrique, jamais en degres.
## Un st_buffer(dist = 5000) sur du WGS84 ajouterait 5 000 DEGRES.
aoi_yagoua <- aoi01 %>%
  sf::st_transform(crs_mesure) %>%
  sf::st_buffer(dist = marge_m) %>%
  sf::st_transform(4326) %>%
  sf::st_union() %>%
  sf::st_as_sf()

cat("\nEmprise de reference (AOI01 + marge de", marge_m, "m) :\n")
print(sf::st_bbox(aoi_yagoua))

## ============================================================================
## Etape 2 : traiter les tuiles une par une, en streaming
## ============================================================================
## Deux precautions pour rester rapide et leger en memoire :
##  1. read_csv_chunked() lit chaque tuile PAR BLOCS au lieu de tout charger
##     d'un coup ;
##  2. sur chaque bloc, on filtre d'abord sur les colonnes NUMERIQUES
##     latitude / longitude -- comparaison simple, tres rapide -- pour ne
##     garder que les lignes dans la bbox, AVANT toute conversion en
##     geometrie. Convertir une colonne WKT en objets spatiaux (st_as_sf) est
##     l'etape couteuse : on ne la paie que sur le petit sous-ensemble deja
##     filtre, jamais sur la tuile entiere.
## Le filtre bbox est approximatif (un rectangle) ; il est affine ensuite par
## un st_filter() exact sur le polygone.

ob_fichiers <- list.files(tuiles_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

cat("\nTuiles Open Buildings brutes trouvees :", length(ob_fichiers), "\n")
if (length(ob_fichiers) == 0) {
  stop("Aucune tuile CSV.GZ dans ", tuiles_dir, ".\n",
       "Ce script n'est pas executable en salle : les tuiles brutes ne sont ",
       "pas livrees avec la journee. Voir l'en-tete.")
}
cat(paste0("  ", basename(ob_fichiers)), sep = "\n")

bbox_yagoua  <- sf::st_bbox(aoi_yagoua)
n_brut_total <- 0

batiments_liste <- lapply(seq_along(ob_fichiers), function(i) {

  f <- ob_fichiers[i]
  cat(sprintf("\n[%d/%d] %s\n", i, length(ob_fichiers), basename(f)))

  filtrer_bbox <- function(chunk, pos) {
    n_brut_total <<- n_brut_total + nrow(chunk)
    chunk %>%
      filter(
        longitude >= bbox_yagoua["xmin"], longitude <= bbox_yagoua["xmax"],
        latitude  >= bbox_yagoua["ymin"], latitude  <= bbox_yagoua["ymax"]
      )
  }

  tuile_bbox <- readr::read_csv_chunked(
    f,
    callback       = readr::DataFrameCallback$new(filtrer_bbox),
    chunk_size     = 200000,
    show_col_types = FALSE
  )

  cat("  batiments dans la bbox :",
      format(nrow(tuile_bbox), big.mark = " "), "\n")

  if (nrow(tuile_bbox) == 0) return(NULL)

  ## La colonne "geometry" des CSV Open Buildings est du WKT : on pose le CRS
  ## explicitement (crs = 4326). Sans lui, sf a des nombres mais ne sait pas
  ## ce qu'ils mesurent.
  tuile_sf     <- sf::st_as_sf(tuile_bbox, wkt = "geometry", crs = 4326)
  tuile_yagoua <- sf::st_filter(tuile_sf, aoi_yagoua)

  cat("  retenus apres filtre exact :",
      format(nrow(tuile_yagoua), big.mark = " "), "\n")

  tuile_yagoua
})

batiments_yagoua <- bind_rows(batiments_liste)

## ============================================================================
## Etape 3 : bilan et export
## ============================================================================

cat("\n=== Bilan ===\n")
cat("Total batiments bruts (toutes tuiles) :",
    format(n_brut_total, big.mark = " "), "\n")
cat("Batiments retenus autour de Yagoua    :",
    format(nrow(batiments_yagoua), big.mark = " "), "\n")
cat("Colonnes conservees                   :",
    paste(names(batiments_yagoua), collapse = ", "), "\n")

## AUCUN SEUIL DE CONFIANCE N'EST APPLIQUE ICI, et c'est delibere : le seuil
## est une DECISION D'ANALYSE, elle appartient au module 6 ou elle est
## declaree, discutee et testee en sensibilite. Si on filtrait des la
## preparation, les participants ne pourraient plus faire varier le seuil, et
## la distribution de confidence -- qu'ils doivent voir -- serait tronquee.
if ("confidence" %in% names(batiments_yagoua)) {
  cat("\nRepartition par niveau de confiance (AUCUN filtre applique) :\n")
  batiments_yagoua %>%
    sf::st_drop_geometry() %>%
    mutate(conf_classe = cut(confidence, c(0, 0.5, 0.7, 1),
                             labels = c("<0.5", "0.5-0.7", ">=0.7"),
                             include.lowest = TRUE)) %>%
    count(conf_classe) %>%
    print()
} else {
  cat("\n*** Colonne 'confidence' absente des tuiles : verifier le millesime ",
      "du produit Open Buildings telecharge. ***\n")
}

sf::st_write(batiments_yagoua, sortie_gpkg, delete_dsn = TRUE, quiet = TRUE)

cat("\nGeoPackage ecrit :", sortie_gpkg, "\n")

## ----------------------------------------------------------------------------
## POINTS DE METHODE
##
## - LIRE PAR BLOCS ET FILTRER SUR DES NOMBRES AVANT DE CONSTRUIRE DES
##   GEOMETRIES. C'est ce qui rend le traitement praticable sur des tuiles de
##   plusieurs Go couvrant une zone bien plus large que la zone d'interet.
##
## - GEOPACKAGE PLUTOT QUE SHAPEFILE. Un seul fichier (pas de .shp/.dbf/.shx/
##   .prj eparpilles), pas de troncature des noms de colonnes a 10 caracteres,
##   pas de limite de taille de champ texte. Le shapefile tronquerait
##   "area_in_meters" et "full_plus_code".
##
## - LA MARGE SE POSE EN METRES. st_buffer() sur du WGS84 travaille en degres :
##   dist = 5000 y signifierait 5 000 degres. On reprojette, on tamponne, on
##   revient.
##
## - CE QUE CE SCRIPT NE FAIT PAS : il n'applique aucun seuil de confiance et
##   ne supprime aucune colonne. Toutes les decisions d'analyse restent dans
##   le materiel de la journee, ou elles sont visibles et discutables.
## ----------------------------------------------------------------------------
