## ============================================================================
## J09 -- PREPARATION DE LA COPIE DE SECOURS DU RESEAU ROUTIER OSM
## ----------------------------------------------------------------------------
## Atelier IFORD x GDSG 2026 -- Mercredi 5 aout 2026
##
## *** NON EXECUTABLE EN SALLE ***
##
## Ce script N'EST PAS un exercice. Il interroge l'API publique Overpass, qui
## est un service gratuit a usage limite : vingt participants qui la sollicitent
## simultanement la font echouer pour tout le monde. Il est a executer UNE FOIS
## par le formateur, en amont de la seance (ou pour rafraichir la copie).
##
## Il est conserve ici comme TRACE DE PROVENANCE du fichier
## datasets/routes_aoi01_yagoua.gpkg, utilise au module 8 comme repli local
## quand Overpass ne repond pas. Il documente exactement quelle emprise a ete
## interrogee et quelle etiquette a ete demandee.
##
## IMPORTANT : la fenetre ci-dessous doit rester IDENTIQUE a celle du module 5
## du materiel de la journee. Si elle change ici et pas la-bas, la copie de
## secours ne correspond plus a la zone que les participants explorent -- et le
## repli produirait silencieusement un reseau decale.
##
## Licence : OpenStreetMap, ODbL. Toute reutilisation doit citer OpenStreetMap
## et ses contributeurs.
## ============================================================================

library(sf)
library(dplyr)
library(osmdata)

sf_use_s2(FALSE)   # meme reglage que le materiel de la journee

## ----------------------------------------------------------------------------
## PARAMETRES
## ----------------------------------------------------------------------------
chemin_aoi01 <- file.path("datasets", "EMSR772_AOI01_areaOfInterestA.shp")

## Sortie dans outputs/, JAMAIS dans datasets/ : un dossier de donnees est un
## dossier d'entrees. C'est le formateur qui verse ensuite le fichier valide au
## magasin central, d'ou l'outil de distribution le recopiera.
sortie_gpkg <- file.path("outputs", "routes_aoi01_yagoua.gpkg")

n_tentatives   <- 5
delai_max_s    <- 30
pause_entre_s  <- 10

dir.create("outputs", showWarnings = FALSE)

cat("=== Preparation de la copie de secours OSM -- AOI01 Yagoua ===\n")
cat("Sortie :", sortie_gpkg, "\n")

## ============================================================================
## Etape 1 : reconstruire EXACTEMENT la fenetre du materiel de la journee
## ============================================================================

if (!file.exists(chemin_aoi01))
  stop("AOI01 introuvable : ", chemin_aoi01)

aoi01_complet <- sf::st_make_valid(sf::st_read(chemin_aoi01, quiet = TRUE))

cat("\nAOI01 officielle :", nrow(aoi01_complet), "polygone(s), CRS",
    sf::st_crs(aoi01_complet)$input, "\n")

## Ces quatre coordonnees sont recopiees telles quelles depuis le module 5 du
## materiel de la journee. Toute modification doit etre faite AUX DEUX ENDROITS.
fenetre_zoom <- sf::st_bbox(
  c(xmin = 15.31957, ymin = 10.22218, xmax = 15.36528, ymax = 10.26745),
  crs = sf::st_crs(aoi01_complet)
)

aoi01  <- sf::st_make_valid(
  sf::st_intersection(aoi01_complet, sf::st_as_sfc(fenetre_zoom))
)
bbox01 <- sf::st_bbox(aoi01)

cat("\nEmprise interrogee (bbox) :\n")
print(bbox01)

## ============================================================================
## Etape 2 : interroger l'API Overpass, avec plusieurs tentatives bornees
## ============================================================================
## L'API publique est a capacite limitee : une tentative isolee echoue parfois
## (429 "trop de requetes", 504 "delai depasse"), et osmdata reessaie alors en
## interne avec des pauses qui peuvent durer plusieurs minutes -- pendant
## lesquelles R attend en silence, sans rien afficher. On borne donc CHAQUE
## tentative a 30 secondes (setTimeLimit) et on reessaie soi-meme quelques
## fois, avec une pause courte et un message a chaque essai.

requete_osm <- opq(bbox = bbox01) %>%
  add_osm_feature(key = "highway")

osm_data <- NULL

for (i in seq_len(n_tentatives)) {
  cat("\nTentative", i, "/", n_tentatives, "...\n")
  osm_data <- tryCatch(
    {
      setTimeLimit(elapsed = delai_max_s, transient = TRUE)
      osmdata_sf(requete_osm)
    },
    error = function(e) {
      cat("  echec :", conditionMessage(e), "\n")
      NULL
    },
    finally = setTimeLimit(elapsed = Inf, transient = FALSE)
  )
  if (!is.null(osm_data)) break
  if (i < n_tentatives) Sys.sleep(pause_entre_s)
}

if (is.null(osm_data)) {
  stop("Echec du telechargement OSM apres ", n_tentatives, " tentatives. ",
       "Reessayer plus tard : l'API Overpass est parfois saturee.")
}

routes_osm <- osm_data$osm_lines

if (is.null(routes_osm) || nrow(routes_osm) == 0)
  stop("Overpass a repondu mais n'a renvoye aucune ligne. Verifier l'emprise ",
       "et l'etiquette demandee.")

## ============================================================================
## Etape 3 : bilan et export
## ============================================================================

cat("\n=== Bilan ===\n")
cat("Segments recuperes :", nrow(routes_osm), "\n")
cat("CRS                :", sf::st_crs(routes_osm)$input, "\n")
cat("Colonnes           :", length(names(routes_osm)), "au total\n")
cat("Repartition par type de route (highway) :\n")
print(table(routes_osm$highway, useNA = "ifany"))

## CONTROLE VISUEL OBLIGATOIRE AVANT DE VERSER LA COPIE.
## La couverture OSM est tres heterogene : dense la ou une reponse humanitaire
## a mobilise des cartographes (le Humanitarian OpenStreetMap Team a beaucoup
## travaille sur l'Extreme-Nord camerounais), lacunaire ailleurs. Un reseau
## visiblement troue n'est pas un bug du script : c'est l'etat de la base. Il
## faut le savoir AVANT la seance, parce que le module 8 en depend.
plot(sf::st_geometry(routes_osm), col = "grey30", lwd = 0.6,
     main = "Controle visuel : reseau OSM recupere sur la fenetre AOI01")
plot(sf::st_geometry(aoi01), border = "steelblue", lwd = 2, add = TRUE)

sf::st_write(routes_osm, sortie_gpkg, delete_dsn = TRUE, quiet = TRUE)

cat("\nGeoPackage ecrit :", sortie_gpkg, "\n")

## ----------------------------------------------------------------------------
## POINTS DE METHODE
##
## - BORNER CHAQUE TENTATIVE. setTimeLimit(elapsed = 30, transient = TRUE)
##   evite qu'une requete s'eternise sans rien afficher. Le finally remet la
##   limite a Inf : sans lui, la limite resterait active pour la suite de la
##   session R.
##
## - GEOPACKAGE PLUTOT QUE SHAPEFILE. Les objets OSM portent des dizaines de
##   colonnes d'etiquettes aux noms longs ; le shapefile les tronquerait a
##   10 caracteres et en fusionnerait plusieurs.
##
## - CE SCRIPT NE MESURE AUCUNE LONGUEUR. Il stocke des geometries en WGS84 ;
##   toutes les longueurs sont calculees dans le materiel de la journee, apres
##   reprojection en UTM 33N. Mesurer ici, en degres, produirait des nombres
##   sans signification.
##
## - LA COPIE PERIME. OSM evolue en continu : rafraichir avant chaque session
##   si l'on veut que la copie de secours et la reponse Overpass en direct
##   racontent la meme chose.
## ----------------------------------------------------------------------------
