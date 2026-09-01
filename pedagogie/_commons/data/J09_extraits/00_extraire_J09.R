# =====================================================================
# 00_extraire_J09.R
# Atelier IFORD x GDSG 2026 — J09 « Teledetection et inondations »
#
# A QUOI SERT CE SCRIPT
#   Le runtime WebR de la J09 tourne DANS UN NAVIGATEUR : ni terra, ni
#   exactextractr, ni osmdata n'y sont disponibles. Or toute la journee
#   repose sur des rasters (mosaiques GHS-BUILT 2015 et 2025, grille
#   WorldPop 2024) et sur des couches vectorielles lourdes (plus de
#   400 000 empreintes de batiments dans l'AOI01 officielle).
#   Ce script fait ici, une fois, TOUT le calcul raster et toutes les
#   intersections couteuses, et n'ecrit que des sorties legeres que le
#   navigateur peut ouvrir avec sf + dplyr + ggplot2.
#
# QUI DOIT L'EXECUTER
#   VOUS. La session qui a redige ce script n'avait ni R, ni shell, ni acces
#   aux binaires (.tif, .zip, .gpkg, .shp) : elle n'a VERIFIE AUCUN CHIFFRE.
#   Tous les commentaires « a valider au premier rendu » signalent une
#   hypothese non verifiee.
#
# QUAND LE RELANCER
#   - a la premiere installation ;
#   - si la tuile GHS-BUILT E2015 R7_C19 (manquante) est recuperee ;
#   - si l'archive EMSR772_AOI01 est remplacee par une version plus recente ;
#   - si l'on change la fenetre d'etude (TAILLE_FENETRE_M ci-dessous).
#
# ENTREES (pedagogie/J09_teledetection/datasets/)
#   gadm41_CMR.gpkg
#   GHS_BUILT_S_E2015_*.zip  (7 attendues)   /  GHS_BUILT_S_E2025_*.zip (8)
#   cmr_pop_2024_CN_100m_R2025A_v1.tif
#   EMSR772_AOI0{1,2,3}_areaOfInterestA.shp  (+ .shx .dbf .prj)
#   EMSR772_AOI0{1,2,3}_floodDepthA.shp      (+ annexes)
#   open_buildings_yagoua.gpkg
#   routes_aoi01_yagoua.gpkg
#
# SORTIES (pedagogie/_commons/data/J09_extraits/)
#   J09_adm1_bati.geojson            10 regions : bati 2015/2025, part, gain
#   J09_adm2_bati.geojson            58 departements (MAUP)
#   J09_fenetre_yagoua.geojson       1 polygone : la fenetre d'etude assumee
#   J09_flood_yagoua.geojson         polygones de profondeur, classes ordonnees
#   J09_batiments_yagoua.geojson     batiments de la fenetre + exposition
#   J09_routes_yagoua.geojson        troncons OSM + longueur inondee
#   J09_pop_grille_yagoua.csv        cellules WorldPop 100 m + fraction inondee
#   J09_comparaison_methodes.csv     batiments x 5 contre WorldPop
#   J09_zones_bilan.csv              les trois AOI, dont deux non couvertes
#   J09_extraits_README.csv
#
# CONTRAT DE COLONNES — ne pas renommer sans corriger runtime.qmd.
#
# Usage :
#   source("pedagogie/_commons/data/J09_extraits/00_extraire_J09.R")
#
# Dependances :
#   install.packages(c("sf","terra","exactextractr","dplyr","tidyr","readr",
#                      "stringr","rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 900)

.deps <- c("sf", "terra", "exactextractr", "dplyr", "tidyr", "readr",
           "stringr", "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J09-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(sf); library(terra); library(exactextractr)
  library(dplyr); library(tidyr); library(readr); library(stringr)
})

# Les produits Copernicus EMS sont produits en urgence : auto-intersections
# frequentes. s2 les refuse, GEOS les accepte. On repare a la lecture.
sf_use_s2(FALSE)

.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)
dir_in  <- file.path(.PROJECT_ROOT, "pedagogie", "J09_teledetection", "datasets")
dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J09_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

CRS_MESURE <- 32633            # UTM 33N : le seul CRS ou l'on mesure ici

# --- Parametres DECLARES, jamais subis --------------------------------
SEUIL_CONFIANCE     <- 0.7     # Open Buildings : probabilite du modele
OCCUPATION_PAR_BATI <- 5       # personnes par batiment — HYPOTHESE, pas mesure
TAILLE_FENETRE_M    <- 5000    # fenetre d'etude carree, 5 x 5 km
SEUIL_BATI_MIN_KM2  <- 1       # sous ce bati 2015, pas de croissance relative
SEUIL_COUVERTURE    <- 50      # sous ce nombre de batiments, zone non lisible
TOL_ADM1_M          <- 500     # simplification : cf. note ci-dessous
TOL_ADM2_M          <- 300
TOL_FLOOD_M         <- 10      # emprises d'inondation : tolerance FINE
TOL_ROUTES_M        <- 5

# Ce que coute la simplification : les details de contour plus fins que la
# tolerance disparaissent. 500 m est invisible sur une carte nationale ;
# 10 m sur les emprises d'inondation preserve la forme des bras d'eau, qui
# est precisement ce que le module cherche a montrer. AUCUNE SURFACE ni
# LONGUEUR n'est mesuree apres simplification : on mesure d'abord, on
# simplifie ensuite, et seulement pour afficher.

GEOJSON_OPTS <- c("COORDINATE_PRECISION=6", "RFC7946=YES")
`%||%` <- function(a, b) if (is.null(a)) b else a
poids_ko <- function(p) round(file.size(p) / 1024)

ecrire_geojson <- function(obj, nom) {
  p <- file.path(dir_out, nom)
  st_write(obj, p, delete_dsn = TRUE, quiet = TRUE, layer_options = GEOJSON_OPTS)
  cat(sprintf("  -> %-34s %7d Ko  %6d entites  %2d colonnes\n",
              nom, poids_ko(p), nrow(obj), ncol(obj) - 1L))
}
ecrire_csv <- function(obj, nom) {
  p <- file.path(dir_out, nom)
  write_csv(obj, p)
  cat(sprintf("  -> %-34s %7d Ko  %6d lignes   %2d colonnes\n",
              nom, poids_ko(p), nrow(obj), ncol(obj)))
}

cat("\n=====================================================\n")
cat(" J09 — extraction des donnees lourdes pour le runtime\n")
cat("=====================================================\n")
cat("Entrees : ", dir_in,  "\nSorties : ", dir_out, "\n\n")

# ---------------------------------------------------------------------
# 0. Inventaire
# ---------------------------------------------------------------------
z2015 <- list.files(dir_in, pattern = "^GHS_BUILT_S_E2015.*\\.zip$",
                    full.names = TRUE)
z2025 <- list.files(dir_in, pattern = "^GHS_BUILT_S_E2025.*\\.zip$",
                    full.names = TRUE)
code_tuile <- function(x) str_extract(basename(x), "R\\d+_C\\d+")
cat("--- Inventaire ---\n")
cat("Tuiles GHS-BUILT 2015 :", length(z2015), "|",
    paste(sort(code_tuile(z2015)), collapse = " "), "\n")
cat("Tuiles GHS-BUILT 2025 :", length(z2025), "|",
    paste(sort(code_tuile(z2025)), collapse = " "), "\n")
asym <- setdiff(code_tuile(z2025), code_tuile(z2015))
if (length(asym)) {
  cat("ASYMETRIE DE COUVERTURE — tuile(s) presente(s) en 2025 et absente(s)\n")
  cat("en 2015 :", paste(asym, collapse = " "), "\n")
  cat("Consequence : sans garde-fou, le « gain » y vaudrait la TOTALITE du\n")
  cat("bati 2025. Les deux millesimes sont restreints a l'emprise commune.\n")
}

autres <- c("gadm41_CMR.gpkg", "cmr_pop_2024_CN_100m_R2025A_v1.tif",
            "EMSR772_AOI01_areaOfInterestA.shp",
            "EMSR772_AOI01_floodDepthA.shp",
            "open_buildings_yagoua.gpkg", "routes_aoi01_yagoua.gpkg")
for (f in autres) {
  p <- file.path(dir_in, f)
  cat(sprintf("  %-40s %s\n", f,
              if (file.exists(p)) sprintf("OK (%d Ko)", poids_ko(p)) else "ABSENT"))
}

# ---------------------------------------------------------------------
# 1. Limites administratives
# ---------------------------------------------------------------------
cat("\n--- 1. Limites administratives ---\n")
gpkg <- file.path(dir_in, "gadm41_CMR.gpkg")
couches <- st_layers(gpkg)$name
cat("Couches :", paste(couches, collapse = ", "), "\n")
lire <- function(n) st_read(gpkg, layer = n, quiet = TRUE) |> st_make_valid()
cmr0 <- lire(grep("ADM_?0$", couches, value = TRUE)[1])
cmr1 <- lire(grep("ADM_?1$", couches, value = TRUE)[1])
cmr2 <- lire(grep("ADM_?2$", couches, value = TRUE)[1])
cmr1$superficie_km2 <- as.numeric(st_area(st_transform(cmr1, CRS_MESURE))) / 1e6
cmr2$superficie_km2 <- as.numeric(st_area(st_transform(cmr2, CRS_MESURE))) / 1e6
cat("ADM1 :", nrow(cmr1), "regions | ADM2 :", nrow(cmr2), "departements\n")
cat("Superficie totale (km2) :", round(sum(cmr1$superficie_km2)),
    "— reference 475 442\n")

# ---------------------------------------------------------------------
# 2. Mosaiques GHS-BUILT, alignees sur une emprise commune
# ---------------------------------------------------------------------
cat("\n--- 2. GHS-BUILT : mosaiquer, aligner, extraire ---\n")

charger_ghsl <- function(zips, etiquette) {
  if (length(zips) == 0) return(NULL)
  tmp <- file.path(tempdir(), paste0("ghsl_", etiquette))
  dir.create(tmp, showWarnings = FALSE, recursive = TRUE)
  for (z in zips) unzip(z, exdir = tmp, overwrite = TRUE)
  tifs <- list.files(tmp, pattern = "\\.tif$", full.names = TRUE)
  cat("  ", etiquette, ":", length(tifs), "tuiles decompressees\n")
  m <- terra::mosaic(terra::sprc(lapply(tifs, rast)), fun = "max")
  names(m) <- paste0("bati_", etiquette)
  # Valeur = m2 de bati dans la cellule de 100 m, donc 0 a 10 000.
  cat("     EPSG", crs(m, describe = TRUE)$code %||% "?",
      "| res", paste(round(res(m)), collapse = " x "),
      "| cellules", format(ncell(m), big.mark = " "), "\n")
  m
}

b2015 <- charger_ghsl(z2015, "2015")
b2025 <- charger_ghsl(z2025, "2025")

adm1_bati <- cmr1 |> select(GID_1, NAME_1, superficie_km2)
adm2_bati <- cmr2 |> select(GID_1, GID_2, NAME_1, NAME_2, superficie_km2)

if (!is.null(b2015) && !is.null(b2025)) {
  # ALIGNEMENT : meme emprise rectangulaire, puis meme masque de cellules
  # valides. Les tuiles GHSL partagent la meme grille : un crop suffit.
  emprise_commune <- terra::intersect(ext(b2015), ext(b2025))
  b2015a <- crop(b2015, emprise_commune)
  b2025a <- crop(b2025, emprise_commune)
  masque_commun <- !is.na(b2015a) & !is.na(b2025a)
  b2015a <- mask(b2015a, masque_commun, maskvalues = c(0, NA))
  b2025a <- mask(b2025a, masque_commun, maskvalues = c(0, NA))
  cat("  Emprise commune retenue. Cellules valides des deux cotes :",
      format(as.numeric(global(masque_commun, "sum", na.rm = TRUE)[[1]]),
             big.mark = " "), "\n")

  extraire_bati <- function(r, couche) {
    # exact_extract pondere par la FRACTION de cellule couverte : sur des
    # departements etroits, c'est ce qui evite de perdre les bordures.
    exact_extract(r, st_transform(couche, crs(r)), "sum", progress = FALSE)
  }
  # m2 -> km2
  adm1_bati$bati_2015_km2 <- round(extraire_bati(b2015a, cmr1) / 1e6, 3)
  adm1_bati$bati_2025_km2 <- round(extraire_bati(b2025a, cmr1) / 1e6, 3)
  adm2_bati$bati_2015_km2 <- round(extraire_bati(b2015a, cmr2) / 1e6, 3)
  adm2_bati$bati_2025_km2 <- round(extraire_bati(b2025a, cmr2) / 1e6, 3)

  # COUVERTURE : une region hors de l'emprise commune n'a pas « zero bati »,
  # elle n'a PAS DE MESURE. Le runtime doit la peindre en gris.
  couverture <- exact_extract(masque_commun,
                              st_transform(cmr1, crs(masque_commun)),
                              "mean", progress = FALSE)
  adm1_bati$couverture_ghsl_pct <- round(100 * couverture, 1)
  adm1_bati$mesure_disponible <- adm1_bati$couverture_ghsl_pct > 50
  couverture2 <- exact_extract(masque_commun,
                               st_transform(cmr2, crs(masque_commun)),
                               "mean", progress = FALSE)
  adm2_bati$couverture_ghsl_pct <- round(100 * couverture2, 1)
  adm2_bati$mesure_disponible <- adm2_bati$couverture_ghsl_pct > 50
  cat("  Regions couvertes a plus de 50 % :", sum(adm1_bati$mesure_disponible),
      "/", nrow(adm1_bati), "\n")
  cat("  Departements couverts a plus de 50 % :",
      sum(adm2_bati$mesure_disponible), "/", nrow(adm2_bati), "\n")
} else {
  cat("  Mosaiques indisponibles : les colonnes de bati resteront NA.\n")
  adm1_bati$bati_2015_km2 <- NA_real_; adm1_bati$bati_2025_km2 <- NA_real_
  adm1_bati$couverture_ghsl_pct <- NA_real_; adm1_bati$mesure_disponible <- FALSE
  adm2_bati$bati_2015_km2 <- NA_real_; adm2_bati$bati_2025_km2 <- NA_real_
  adm2_bati$couverture_ghsl_pct <- NA_real_; adm2_bati$mesure_disponible <- FALSE
}

derive_bati <- function(d, seuil) {
  d |>
    mutate(
      part_batie_2015_pct = round(100 * bati_2015_km2 / superficie_km2, 3),
      part_batie_2025_pct = round(100 * bati_2025_km2 / superficie_km2, 3),
      gain_bati_km2       = round(bati_2025_km2 - bati_2015_km2, 3),
      # SEUIL DECLARE : sous ce bati initial, un denominateur minuscule
      # fabrique des taux a trois chiffres. On renvoie NA, pas un nombre.
      croissance_pct = ifelse(
        !is.na(bati_2015_km2) & bati_2015_km2 >= seuil & mesure_disponible,
        round(100 * (bati_2025_km2 - bati_2015_km2) / bati_2015_km2, 1),
        NA_real_),
      superficie_km2 = round(superficie_km2, 1)
    )
}
adm1_bati <- derive_bati(adm1_bati, SEUIL_BATI_MIN_KM2)
adm2_bati <- derive_bati(adm2_bati, SEUIL_BATI_MIN_KM2)

# TYPOLOGIE : deux medianes croisees, rythme (gain) x etat (part batie).
# Seuils RELATIFS aux dix regions : par construction chaque moitie en
# contient cinq. Ce n'est pas une classification absolue.
med_gain <- median(adm1_bati$gain_bati_km2, na.rm = TRUE)
med_part <- median(adm1_bati$part_batie_2025_pct, na.rm = TRUE)
adm1_bati <- adm1_bati |>
  mutate(typologie = case_when(
    is.na(gain_bati_km2) | !mesure_disponible ~ NA_character_,
    gain_bati_km2 >= med_gain & part_batie_2025_pct >= med_part ~
      "Deja bati, croissance rapide",
    gain_bati_km2 >= med_gain & part_batie_2025_pct <  med_part ~
      "Peu bati, croissance rapide",
    gain_bati_km2 <  med_gain & part_batie_2025_pct >= med_part ~
      "Deja bati, croissance lente",
    TRUE ~ "Peu bati, croissance lente"))
cat("  Medianes de typologie — gain :", round(med_gain, 3),
    "km2 | part batie :", round(med_part, 3), "%\n")

# ---------------------------------------------------------------------
# 3. Copernicus EMS — lecture des trois AOI
# ---------------------------------------------------------------------
cat("\n--- 3. Copernicus EMS (activation EMSR772, Yagoua 2024) ---\n")
lire_shp <- function(f) {
  p <- file.path(dir_in, f)
  if (!file.exists(p)) { cat("  ABSENT :", f, "\n"); return(NULL) }
  st_read(p, quiet = TRUE) |> st_make_valid()
}
aoi <- lapply(1:3, function(i) lire_shp(sprintf("EMSR772_AOI%02d_areaOfInterestA.shp", i)))
flo <- lapply(1:3, function(i) lire_shp(sprintf("EMSR772_AOI%02d_floodDepthA.shp", i)))
names(aoi) <- names(flo) <- sprintf("AOI%02d", 1:3)

for (i in seq_along(aoi)) {
  if (is.null(aoi[[i]])) next
  s <- sum(as.numeric(st_area(st_transform(aoi[[i]], CRS_MESURE)))) / 1e6
  cat(sprintf("  %s : AOI %d polygone(s), %.0f km2 | floodDepth %s polygone(s)\n",
              names(aoi)[i], nrow(aoi[[i]]), s,
              if (is.null(flo[[i]])) "0" else nrow(flo[[i]])))
}

# La colonne de classe de profondeur : on ne suppose pas son nom.
col_classe <- intersect(c("value", "VALUE", "depth", "class"), names(flo[[1]]))[1]
cat("  Colonne de classe de profondeur retenue :", col_classe, "\n")
cat("  Modalites brutes :", paste(unique(as.character(flo[[1]][[col_classe]])),
                                  collapse = " | "), "\n")

# PIEGE : la colonne est du TEXTE. L'ordre alphabetique coincide ici avec
# l'ordre numerique par chance, pas par construction ("10.00 - 20.00" se
# classerait avant "2.00 - 5.00"). On extrait la BORNE BASSE numerique.
borne_basse <- function(x) {
  suppressWarnings(as.numeric(str_extract(as.character(x), "^-?\\d+\\.?\\d*")))
}

# ---------------------------------------------------------------------
# 4. La fenetre d'etude — une reduction assumee
# ---------------------------------------------------------------------
cat("\n--- 4. Fenetre d'etude ---\n")
# CHOIX DE METHODE, A ENONCER EN SALLE.
# L'AOI01 officielle depasse 100 km de large. Toutes les intersections y
# seraient trop lentes pour une seance, et la couche de batiments y compte
# plusieurs centaines de milliers d'entites.
# On retient une fenetre carree de TAILLE_FENETRE_M, centree sur le
# CENTROIDE DU PLUS GRAND POLYGONE INONDE — choix deterministe, reproductible,
# et qui ne depend d'aucune coordonnee ecrite en dur.
# CONSEQUENCE, a repeter partout : tous les chiffres des sorties « yagoua »
# portent sur cette fenetre, PAS sur l'AOI01, et ne sont donc JAMAIS un
# bilan de l'inondation de Yagoua.
flood01_m <- st_transform(flo[["AOI01"]], CRS_MESURE)
flood01_m$surface_m2 <- as.numeric(st_area(flood01_m))
centre <- st_centroid(flood01_m[which.max(flood01_m$surface_m2), ])
cc <- st_coordinates(centre)[1, ]
h <- TAILLE_FENETRE_M / 2
fenetre_m <- st_sf(
  nom = "Fenetre d'etude 5 x 5 km",
  cote_m = TAILLE_FENETRE_M,
  origine = "centroide du plus grand polygone inonde de l'AOI01",
  geometry = st_sfc(st_polygon(list(rbind(
    c(cc[1] - h, cc[2] - h), c(cc[1] + h, cc[2] - h),
    c(cc[1] + h, cc[2] + h), c(cc[1] - h, cc[2] + h),
    c(cc[1] - h, cc[2] - h)))), crs = CRS_MESURE))
surf_aoi01 <- sum(as.numeric(st_area(st_transform(aoi[["AOI01"]], CRS_MESURE)))) / 1e6
cat("  AOI01 officielle :", round(surf_aoi01), "km2\n")
cat("  Fenetre retenue  :", (TAILLE_FENETRE_M / 1000)^2, "km2, soit",
    round(100 * (TAILLE_FENETRE_M / 1000)^2 / surf_aoi01, 2), "% de l'AOI01\n")

flood_fen <- st_intersection(flood01_m, fenetre_m) |> st_make_valid()
flood_fen$surface_ha <- as.numeric(st_area(flood_fen)) / 1e4
flood_fen <- flood_fen |>
  mutate(classe_profondeur = as.character(.data[[col_classe]]),
         ordre_classe = borne_basse(classe_profondeur)) |>
  select(classe_profondeur, ordre_classe, surface_ha)
cat("  Polygones d'inondation dans la fenetre :", nrow(flood_fen), "\n")
cat("  Surface inondee dans la fenetre (ha)   :",
    round(sum(flood_fen$surface_ha)), "\n")
flood_union <- st_union(st_geometry(flood_fen))

# ---------------------------------------------------------------------
# 5. Open Buildings dans la fenetre
# ---------------------------------------------------------------------
cat("\n--- 5. Open Buildings ---\n")
# CORRECTIF 01/09/2026 -- POURQUOI CETTE SECTION NE FINISSAIT JAMAIS.
#
# Le code lisait la couche ENTIERE (144 Mo, de l'ordre du million de
# polygones), puis lui appliquait st_make_valid(), st_transform() et un
# st_intersects(..., sparse = FALSE) : quatre passes completes, alors que
# seuls les batiments de la fenetre de 5 x 5 km servent ensuite.
# st_make_valid() sur un million de polygones se compte en heures.
#
# Parade : pousser le filtre spatial DANS GDAL, a la lecture. wkt_filter
# n'apporte en memoire que les entites qui intersectent l'emprise demandee,
# en s'appuyant sur l'index spatial du GeoPackage. Tout ce qui suit
# travaille alors sur quelques milliers de batiments au lieu d'un million.
#
# L'emprise de filtrage couvre la fenetre d'etude ET les trois AOI, sinon
# le bilan de la section 9 ne trouverait rien pour AOI02 et AOI03.
f_ob <- file.path(dir_in, "open_buildings_yagoua.gpkg")

info_ob <- st_layers(f_ob)
crs_ob  <- info_ob$crs[[1]]
cat("  Couche :", info_ob$name[1], "|",
    format(info_ob$features[1], big.mark = " "), "entites au total\n")

emprises <- c(
  lapply(aoi, function(a) st_as_sfc(st_bbox(st_transform(a, crs_ob)))),
  list(st_as_sfc(st_bbox(st_transform(fenetre_m, crs_ob))))
)
filtre_wkt <- st_as_text(st_union(do.call(c, emprises)))

t_ob <- Sys.time()
ob <- st_read(f_ob, wkt_filter = filtre_wkt, quiet = TRUE)
cat("  Batiments retenus par le filtre spatial :",
    format(nrow(ob), big.mark = " "),
    sprintf("(%.0f s)\n", as.numeric(difftime(Sys.time(), t_ob, units = "secs"))))

# Reparation CIBLEE : on ne repare que ce qui est invalide, et on le dit.
# st_make_valid() applique en aveugle a toute la couche etait l'autre moitie
# du probleme.
n_inval <- sum(!st_is_valid(ob))
cat("  Geometries invalides :", n_inval, "/", nrow(ob), "\n")
if (n_inval > 0) {
  ob <- st_make_valid(ob)
  cat("  -> reparees ; restantes :", sum(!st_is_valid(ob)), "\n")
}

cat("  Colonnes :", paste(setdiff(names(ob), attr(ob, "sf_column")),
                          collapse = ", "), "\n")
col_conf <- intersect(c("confidence", "CONFIDENCE"), names(ob))[1]
col_area <- intersect(c("area_in_meters", "AREA_IN_METERS"), names(ob))[1]
cat("  Seuil de confiance declare :", SEUIL_CONFIANCE, "\n")
cat("  Batiments sous le seuil    :",
    sum(ob[[col_conf]] < SEUIL_CONFIANCE, na.rm = TRUE), "\n")

ob_m <- st_transform(ob, CRS_MESURE)

# CORRECTIF 01/09/2026. `sparse = FALSE` construisait une matrice logique
# dense et desactivait le chemin optimise de sf. st_filter() utilise
# l'index spatial et ne materialise rien.
bat_fen <- ob_m |>
  st_filter(fenetre_m, .predicate = st_intersects) |>
  filter(.data[[col_conf]] >= SEUIL_CONFIANCE)
cat("  Batiments dans la fenetre, au-dessus du seuil :", nrow(bat_fen), "\n")

bat_fen$surface_m2 <- as.numeric(st_area(bat_fen))
touche <- lengths(st_intersects(bat_fen, st_sf(geometry = flood_union))) > 0
bat_fen$inonde <- touche

# Classe de profondeur du batiment. st_join() DUPLIQUERAIT les lignes quand
# un batiment chevauche deux polygones de profondeur : on le montre en
# comptant, puis on evite la duplication en resolvant nous-memes le conflit
# — on retient la classe LA PLUS PROFONDE, decision explicite et non un
# hasard d'ordre de tri.
n_avant <- nrow(bat_fen)
n_apres_join <- nrow(st_join(bat_fen,
                             flood_fen |> select(classe_profondeur),
                             join = st_intersects, left = TRUE))
cat("  Lignes avant / apres un st_join naif :", n_avant, "/", n_apres_join,
    " -> duplications evitees :", n_apres_join - n_avant, "\n")
# CORRECTIF 01/09/2026.
# Le code ne traitait qu'un seul cas d'absence : l'intersection VIDE
# (length(k) == 0). Il en existe un second, qui s'est produit au bati 202 :
# l'intersection n'est pas vide, mais TOUTES les classes de profondeur qui
# recouvrent le batiment valent NA. which.max() sur un vecteur entierement
# NA renvoie integer(0) ; l'indexation ne rend alors rien, et vapply()
# echoue sur « values must be length 1, but FUN(X[[202]]) result is
# length 0 ».
#
# Un polygone d'inondation sans classe de profondeur n'est pas une anomalie
# du script : Copernicus EMS ne donne une hauteur d'eau que la ou son modele
# a pu en estimer une. L'etendue observee est donc plus large que l'etendue
# mesuree -- c'est meme la lecon du module 5. On compte ces cas et on les
# nomme, plutot que de les laisser faire planter la chaine.
idx <- st_intersects(bat_fen, flood_fen)

n_flood_na <- sum(is.na(flood_fen$ordre_classe))
if (n_flood_na > 0)
  cat("  Polygones d'inondation SANS classe de profondeur :",
      n_flood_na, "/", nrow(flood_fen),
      "\n    -> les batiments qui ne touchent que ceux-la auront",
      "classe_profondeur = NA.\n")

classe_max <- vapply(idx, function(k) {
  if (length(k) == 0) return(NA_character_)
  o <- flood_fen$ordre_classe[k]
  if (all(is.na(o))) return(NA_character_)   # touche, mais profondeur inconnue
  as.character(flood_fen$classe_profondeur[k[which.max(o)]])
}, character(1))

ordre_max <- vapply(idx, function(k) {
  if (length(k) == 0) return(NA_real_)
  o <- flood_fen$ordre_classe[k]
  if (all(is.na(o))) return(NA_real_)        # max(NA, na.rm=TRUE) donnerait -Inf
  max(o, na.rm = TRUE)
}, numeric(1))

# Trois etats a distinguer, et la carte doit les distinguer aussi (regle 4.4) :
#   - hors zone inondee            : inonde = FALSE
#   - inonde, profondeur connue    : classe_profondeur renseignee
#   - inonde, profondeur INCONNUE  : inonde = TRUE et classe_profondeur = NA
n_touche_sans_classe <- sum(lengths(idx) > 0 & is.na(classe_max))
cat("  Batiments touches mais SANS profondeur mesuree :",
    n_touche_sans_classe, "\n")
if (n_touche_sans_classe > 0)
  cat("    Ces batiments sont exposes : ils ne doivent PAS etre comptes\n",
      "   comme non touches, ni colories comme profondeur nulle.\n")

batiments <- bat_fen |>
  mutate(confidence        = .data[[col_conf]],
         area_in_meters    = .data[[col_area]],
         classe_profondeur = classe_max,
         ordre_classe      = ordre_max) |>
  select(confidence, area_in_meters, surface_m2, inonde,
         classe_profondeur, ordre_classe)
cat("  Batiments touches :", sum(batiments$inonde), "sur", nrow(batiments),
    "(", round(100 * mean(batiments$inonde), 1), "%)\n")

# ---------------------------------------------------------------------
# 6. WorldPop 2024 sur la fenetre — cellule par cellule
# ---------------------------------------------------------------------
cat("\n--- 6. WorldPop 2024 dans la fenetre ---\n")
wp <- rast(file.path(dir_in, "cmr_pop_2024_CN_100m_R2025A_v1.tif"))
names(wp) <- "pop"
cat("  EPSG", crs(wp, describe = TRUE)$code %||% "?",
    "| res", res(wp)[1], "(en degres si EPSG 4326)\n")

fenetre_wgs <- st_transform(fenetre_m, crs(wp))
# CONTROLE : la fenetre est-elle DANS l'emprise du raster ? Une extraction
# hors emprise ne leve pas d'erreur, elle renvoie NA ou 0.
cat("  Fenetre incluse dans l'emprise du raster :",
    relate(vect(fenetre_wgs), as.polygons(ext(wp)), "within")[1], "\n")

wp_fen <- mask(crop(wp, vect(fenetre_wgs)), vect(fenetre_wgs))
cat("  Cellules dans la fenetre :", sum(!is.na(values(wp_fen))), "\n")

# coverage_fraction() renvoie, pour CHAQUE cellule, la fraction de sa
# surface couverte par le polygone d'inondation. C'est exactement ce que
# exact_extract utilise en interne : le runtime pourra donc rejouer, dans
# le navigateur, la difference entre « compter au centroide » et
# « ponderer par la fraction » — sans raster.
flood_wgs <- st_transform(st_sf(geometry = flood_union), crs(wp))
frac <- exactextractr::coverage_fraction(wp_fen, flood_wgs)[[1]]

grille <- as.data.frame(wp_fen, xy = TRUE, na.rm = FALSE) |>
  mutate(frac_inondee = as.vector(values(frac))) |>
  filter(!is.na(pop)) |>
  transmute(x = round(x, 6), y = round(y, 6),
            pop = round(pop, 4),
            frac_inondee = round(pmin(pmax(frac_inondee, 0), 1), 4))
cat("  Lignes de la grille exportee :", nrow(grille), "\n")
cat("  Population totale de la fenetre (somme des cellules) :",
    round(sum(grille$pop)), "\n")
cat("  Population ponderee par la fraction inondee :",
    round(sum(grille$pop * grille$frac_inondee)), "\n")
cat("  Population au centroide (fraction > 0,5)    :",
    round(sum(grille$pop[grille$frac_inondee > 0.5])), "\n")

# ---------------------------------------------------------------------
# 7. Routes OSM
# ---------------------------------------------------------------------
cat("\n--- 7. Routes OpenStreetMap ---\n")
routes <- st_read(file.path(dir_in, "routes_aoi01_yagoua.gpkg"), quiet = TRUE) |>
  st_make_valid() |> st_transform(CRS_MESURE)
col_hw <- intersect(c("highway", "HIGHWAY", "fclass"), names(routes))[1]
routes_fen <- st_intersection(routes, fenetre_m) |> st_make_valid()
routes_fen$longueur_m <- as.numeric(st_length(routes_fen))
inter_r <- st_intersection(routes_fen, st_sf(geometry = flood_union))
long_inondee <- if (nrow(inter_r) > 0) sum(as.numeric(st_length(inter_r))) else 0
cat("  Troncons dans la fenetre :", nrow(routes_fen), "\n")
cat("  Longueur totale (km)     :", round(sum(routes_fen$longueur_m) / 1000, 1), "\n")
cat("  Longueur inondee (km)    :", round(long_inondee / 1000, 1), "\n")
routes_out <- routes_fen |>
  mutate(highway = as.character(.data[[col_hw]]),
         inonde = lengths(st_intersects(routes_fen,
                                        st_sf(geometry = flood_union))) > 0,
         longueur_m = round(longueur_m, 1)) |>
  select(highway, longueur_m, inonde)

# ---------------------------------------------------------------------
# 8. Les deux methodes d'estimation de la population touchee
# ---------------------------------------------------------------------
cat("\n--- 8. Deux methodes, deux reponses ---\n")
pop_bat_fenetre <- nrow(batiments) * OCCUPATION_PAR_BATI
pop_bat_inondee <- sum(batiments$inonde) * OCCUPATION_PAR_BATI
pop_wp_fenetre  <- sum(grille$pop)
pop_wp_inondee  <- sum(grille$pop * grille$frac_inondee)

comparaison <- tibble::tibble(
  methode = c(sprintf("Batiments x %d personnes", OCCUPATION_PAR_BATI),
              "WorldPop 2024 (grille 100 m, ponderee par fraction)"),
  pop_fenetre      = round(c(pop_bat_fenetre, pop_wp_fenetre)),
  pop_zone_inondee = round(c(pop_bat_inondee, pop_wp_inondee))
) |>
  mutate(part_inondee_pct = round(100 * pop_zone_inondee / pop_fenetre, 1))
print(comparaison)
cat("Ecart relatif sur la fenetre entiere (%) :",
    round(100 * (pop_bat_fenetre - pop_wp_fenetre) / pop_wp_fenetre, 1), "\n")
cat("Ecart relatif en zone inondee (%)        :",
    round(100 * (pop_bat_inondee - pop_wp_inondee) / pop_wp_inondee, 1), "\n")
cat("NOTE : WorldPop utilise le bati detecte comme covariable. Les deux\n")
cat("methodes ne sont donc PAS totalement independantes.\n")

# Sensibilite a l'hypothese d'occupation : le facteur s'annule dans tout
# pourcentage, mais pas dans un effectif.
sensibilite <- tibble::tibble(
  occupation = c(3, 5, 8),
  pop_inondee_estimee = sum(batiments$inonde) * c(3, 5, 8)
)
print(sensibilite)

# ---------------------------------------------------------------------
# 9. Les trois zones — et deux zones que la couche ne couvre pas
# ---------------------------------------------------------------------
cat("\n--- 9. Bilan des trois AOI ---\n")
ligne_vide <- function(nm) tibble::tibble(
  zone = nm, surface_aoi_km2 = NA_real_, surface_inondee_km2 = NA_real_,
  n_batiments = NA_integer_, couverture_batiments = FALSE,
  n_batiments_inondes = NA_integer_, pct_batiments_inondes = NA_real_,
  pop_inondee_estimee = NA_real_, interpretable = FALSE)

bilan <- lapply(names(aoi), function(nm) {
  if (is.null(aoi[[nm]]) || is.null(flo[[nm]])) return(ligne_vide(nm))
  t_aoi <- Sys.time()
  a <- st_transform(aoi[[nm]], CRS_MESURE)
  f <- st_transform(flo[[nm]], CRS_MESURE) |> st_make_valid()

  # CORRECTIF 01/09/2026 -- POURQUOI CETTE SECTION NE FINISSAIT PAS.
  #
  # 1. st_union(st_geometry(f)) fusionnait toutes les emprises inondees, a
  #    chaque tour de boucle. C'est l'operation la plus couteuse de sf sur
  #    des milliers de polygones -- ET ELLE EST INUTILE ICI : on veut savoir
  #    si un batiment touche AU MOINS UNE emprise, ce que
  #    lengths(st_intersects(dans, f)) > 0 donne directement.
  # 2. st_intersects(ob_m, a) balayait la couche ENTIERE pour chacune des
  #    trois AOI. On la reduit d'abord par l'emprise rectangulaire de l'AOI
  #    -- test tres rapide, servi par l'index spatial -- puis on ne fait le
  #    test exact que sur les candidats restants.
  candidats <- ob_m |> st_filter(st_as_sfc(st_bbox(a)),
                                 .predicate = st_intersects)
  dans <- candidats |> st_filter(a, .predicate = st_intersects)
  dans <- dans[dans[[col_conf]] >= SEUIL_CONFIANCE, ]
  n_bat <- nrow(dans)

  # La couche Open Buildings ne couvre que l'AOI01 + une marge. Sur AOI02 et
  # AOI03, n_bat vaut 0 : CE ZERO N'EST PAS UNE MESURE. Le drapeau
  # `couverture_batiments` plus bas est ce qui distingue « aucun batiment
  # touche » de « aucun batiment connu ».
  n_ino <- if (n_bat > 0)
    sum(lengths(st_intersects(dans, f)) > 0) else NA_integer_

  cat(sprintf("  %-6s : %s candidats -> %s dans l'AOI (%.0f s)\n", nm,
              format(nrow(candidats), big.mark = " "),
              format(n_bat, big.mark = " "),
              as.numeric(difftime(Sys.time(), t_aoi, units = "secs"))))
  couvert <- n_bat >= SEUIL_COUVERTURE
  tibble::tibble(
    zone = nm,
    surface_aoi_km2 = round(sum(as.numeric(st_area(a))) / 1e6),
    surface_inondee_km2 = round(sum(as.numeric(st_area(f))) / 1e6, 1),
    n_batiments = n_bat,
    couverture_batiments = couvert,
    n_batiments_inondes = if (couvert) n_ino else NA_integer_,
    pct_batiments_inondes = if (couvert) round(100 * n_ino / n_bat, 1) else NA_real_,
    pop_inondee_estimee = if (couvert) n_ino * OCCUPATION_PAR_BATI else NA_real_,
    interpretable = couvert
  )
}) |> bind_rows()
print(bilan)
cat("Zones NON couvertes par la couche de batiments :",
    paste(bilan$zone[!bilan$couverture_batiments], collapse = ", "), "\n")
cat("Leurs cellules doivent rester GRISES dans le runtime, jamais a zero.\n")

# ---------------------------------------------------------------------
# 10. Simplification et ecriture
# ---------------------------------------------------------------------
cat("\n--- 10. Ecriture des sorties ---\n")
simplifier <- function(x, tol) {
  x |> st_simplify(dTolerance = tol, preserveTopology = TRUE) |>
    st_transform(4326) |> st_make_valid()
}
adm1_out <- adm1_bati |> st_transform(CRS_MESURE) |> simplifier(TOL_ADM1_M)
adm2_out <- adm2_bati |> st_transform(CRS_MESURE) |> simplifier(TOL_ADM2_M)
cat("  ADM1 simplifie a", TOL_ADM1_M, "m — valides :",
    sum(st_is_valid(adm1_out)), "/", nrow(adm1_out), "\n")

ecrire_geojson(adm1_out, "J09_adm1_bati.geojson")
ecrire_geojson(adm2_out, "J09_adm2_bati.geojson")
ecrire_geojson(st_transform(fenetre_m, 4326), "J09_fenetre_yagoua.geojson")
ecrire_geojson(simplifier(flood_fen, TOL_FLOOD_M), "J09_flood_yagoua.geojson")
# Les batiments sont exportes en CENTROIDES : une empreinte de 30 m2 dessinee
# a l'echelle de 5 km n'apporte aucun detail visible, et les polygones
# multiplieraient le poids par dix. La surface reste dans area_in_meters.
ecrire_geojson(st_transform(st_centroid(batiments), 4326),
               "J09_batiments_yagoua.geojson")
ecrire_geojson(simplifier(routes_out, TOL_ROUTES_M), "J09_routes_yagoua.geojson")
ecrire_csv(grille,      "J09_pop_grille_yagoua.csv")
ecrire_csv(comparaison, "J09_comparaison_methodes.csv")
ecrire_csv(bilan,       "J09_zones_bilan.csv")

readme <- tibble::tibble(
  fichier = c("J09_adm1_bati.geojson", "J09_adm2_bati.geojson",
              "J09_fenetre_yagoua.geojson", "J09_flood_yagoua.geojson",
              "J09_batiments_yagoua.geojson", "J09_routes_yagoua.geojson",
              "J09_pop_grille_yagoua.csv", "J09_comparaison_methodes.csv",
              "J09_zones_bilan.csv"),
  unite_observation = c("region ADM1", "departement ADM2", "la fenetre d'etude",
                        "polygone d'une classe de profondeur",
                        "centroide de batiment", "troncon de voie OSM",
                        "cellule WorldPop 100 m", "methode d'estimation",
                        "zone AOI"),
  produit_par  = "pedagogie/_commons/data/J09_extraits/00_extraire_J09.R",
  consomme_par = "pedagogie/J09_teledetection/runtime.qmd"
)
ecrire_csv(readme, "J09_extraits_README.csv")

cat("\n=====================================================\n")
cat(" Extraction J09 terminee. Poids total :",
    round(sum(file.size(list.files(dir_out, full.names = TRUE,
                                   pattern = "\\.(csv|geojson)$"))) / 1024),
    "Ko\n")
cat(" Parametres utilises : seuil confiance", SEUIL_CONFIANCE,
    "| occupation", OCCUPATION_PAR_BATI,
    "| fenetre", TAILLE_FENETRE_M, "m\n")
cat("=====================================================\n")
