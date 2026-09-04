# =====================================================================
# 00_extraire_J08.R
# Atelier IFORD x GDSG 2026 — J08 « Population en haute resolution »
#
# A QUOI SERT CE SCRIPT
#   Le runtime WebR de la J08 (pedagogie/J08_population_haute_resolution/
#   runtime.qmd) tourne DANS UN NAVIGATEUR. Or terra, exactextractr et GDAL
#   raster ne sont pas disponibles en WebR : aucune grille WorldPop, aucune
#   tuile GHS-POP ne peut y etre ouverte.
#   La parade est de deplacer l'effort vers l'amont : TOUT le calcul raster
#   est fait ici, une fois, sur un poste avec R installe, et le runtime ne
#   travaille plus que sur des sorties VECTORIELLES et TABULAIRES legeres.
#
# EXECUTION
#   Ce script se lance manuellement depuis la racine du projet, sur un poste
#   disposant des binaires (.tif, .zip, .gpkg). Les valeurs affichees par ses
#   `cat()` sont la seule source fiable : aucun chiffre n'est ecrit en dur
#   dans ce fichier, et toute la sortie console est a lire au premier
#   passage. Les commentaires marques « RECETTE » disent quoi y verifier.
#
# QUAND LE RELANCER
#   - a la premiere installation du materiel ;
#   - si un fichier de datasets/ change (nouveau millesime WorldPop, tuile
#     GHS-POP recuperee, nouveau COD-PS) ;
#   - si l'on modifie le contrat de colonnes attendu par runtime.qmd.
#   Sinon, jamais : ses sorties sont versionnables et stables.
#
# ENTREES (lues dans pedagogie/J08_population_haute_resolution/datasets/)
#   gadm41_CMR.gpkg                        (multicouche ADM_ADM_0..3)
#   cmr_admpop_adm1_2025.csv               (COD-PS, 10 regions, pyramide)
#   cmr_pop_2015_CN_100m_R2025A_v1.tif     (WorldPop constrained)
#   cmr_pop_2025_CN_100m_R2025A_v1.tif
#   cmr_pop_2030_CN_100m_R2025A_v1.tif
#   GHS_POP_E2025_GLOBE_R2023A_54009_100_V1_0_R*_C*.zip   (7 tuiles)
#
# SORTIES (ecrites dans pedagogie/_commons/data/J08_extraits/)
#   J08_adm1_population.geojson   10 regions + toutes les colonnes de mesure
#   J08_adm2_population.geojson   58 departements (demonstration du MAUP)
#   J08_adm1_indicateurs.csv      ratio F/H, part des jeunes, part des aines
#   J08_pyramide_adm1.csv         format long : region x tranche x sexe
#   J08_totaux_nationaux.csv      un total national par source et par annee
#   J08_extraits_README.csv       inventaire des sorties
#
# CONTRAT DE COLONNES — ne pas renommer sans corriger runtime.qmd.
#
# Usage :
#   source("pedagogie/_commons/data/J08_extraits/00_extraire_J08.R")
#
# Dependances :
#   install.packages(c("sf","terra","exactextractr","dplyr","tidyr","readr",
#                      "rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 900)

.deps <- c("sf", "terra", "exactextractr", "dplyr", "tidyr", "readr",
           "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J08-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(sf)
  library(terra)
  library(exactextractr)
  library(dplyr)
  library(tidyr)
  library(readr)
})

# Le moteur spherique s2 refuse des geometries que GEOS accepte. GADM en
# contient. On bascule sur GEOS pour tout le script, et on repare a la lecture.
sf_use_s2(FALSE)

.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

dir_in  <- file.path(.PROJECT_ROOT, "pedagogie",
                     "J08_population_haute_resolution", "datasets")
dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J08_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# CRS de MESURE. EPSG:4326 est en degres : aucune surface ne peut y etre
# calculee. UTM 33N couvre le Cameroun. Repere de controle : 475 442 km2.
CRS_MESURE <- 32633

# Tolerance de simplification des geometries, en METRES (donc appliquee dans
# CRS_MESURE, jamais en degres).
#   Ce que cela coute : les details de contour inferieurs a cette distance
#   disparaissent. A 500 m, une frontiere regionale reste juste a l'echelle
#   d'une carte nationale affichee sur un ecran (1 px ~ 1 km), mais les
#   micro-decoupages cotiers et les enclaves fines sont lisses. AUCUNE
#   SURFACE N'EST RECALCULEE APRES SIMPLIFICATION : superficie_km2 est
#   mesuree sur la geometrie d'origine, avant lissage. C'est la regle : on
#   simplifie pour AFFICHER, jamais pour MESURER.
TOL_ADM1_M <- 500
TOL_ADM2_M <- 300

# Precision des coordonnees ecrites dans les GeoJSON : 5 decimales de degre
# ~ 1,1 m. Au-dela, on stocke du bruit de calcul et on triple le poids.
GEOJSON_OPTS <- c("COORDINATE_PRECISION=5", "RFC7946=YES")

`%||%` <- function(a, b) if (is.null(a)) b else a

poids_ko <- function(p) round(file.size(p) / 1024)

ecrire_geojson <- function(obj, nom) {
  chemin <- file.path(dir_out, nom)
  st_write(obj, chemin, delete_dsn = TRUE, quiet = TRUE,
           layer_options = GEOJSON_OPTS)
  cat(sprintf("  -> %-34s %7d Ko  %4d entites  %2d colonnes\n",
              nom, poids_ko(chemin), nrow(obj), ncol(obj) - 1L))
  invisible(chemin)
}

ecrire_csv <- function(obj, nom) {
  chemin <- file.path(dir_out, nom)
  write_csv(obj, chemin)
  cat(sprintf("  -> %-34s %7d Ko  %4d lignes   %2d colonnes\n",
              nom, poids_ko(chemin), nrow(obj), ncol(obj)))
  invisible(chemin)
}

cat("\n=====================================================\n")
cat(" J08 — extraction des donnees lourdes pour le runtime\n")
cat("=====================================================\n")
cat("Entrees  : ", dir_in,  "\n")
cat("Sorties  : ", dir_out, "\n\n")

# ---------------------------------------------------------------------
# 0. Inventaire : le fichier de donnees fait autorite, jamais le code
# ---------------------------------------------------------------------
attendus <- c(
  "gadm41_CMR.gpkg",
  "cmr_admpop_adm1_2025.csv",
  "cmr_pop_2015_CN_100m_R2025A_v1.tif",
  "cmr_pop_2025_CN_100m_R2025A_v1.tif",
  "cmr_pop_2030_CN_100m_R2025A_v1.tif"
)
cat("--- Inventaire des entrees ---\n")
for (f in attendus) {
  p <- file.path(dir_in, f)
  cat(sprintf("  %-40s %s\n", f,
              if (file.exists(p)) sprintf("OK (%d Ko)", poids_ko(p))
              else "ABSENT"))
}
tuiles_ghs <- list.files(dir_in, pattern = "^GHS_POP_E2025.*\\.zip$",
                         full.names = TRUE)
cat(sprintf("  %-40s %d archive(s)\n", "GHS_POP_E2025_*.zip",
            length(tuiles_ghs)))
if (!all(file.exists(file.path(dir_in, attendus)))) {
  stop("[J08-extrait] Entrees manquantes : remplir datasets/ avant de relancer ",
       "(source(\"outils/distribuer_donnees.R\")).")
}

# ---------------------------------------------------------------------
# 1. Limites administratives
# ---------------------------------------------------------------------
gpkg <- file.path(dir_in, "gadm41_CMR.gpkg")
cat("\n--- 1. Limites administratives ---\n")
couches <- st_layers(gpkg)$name           # on ne suppose pas les noms
cat("Couches presentes :", paste(couches, collapse = ", "), "\n")

lire_couche <- function(nom) {
  st_read(gpkg, layer = nom, quiet = TRUE) |> st_make_valid()
}
cmr0 <- lire_couche(grep("ADM_?0$", couches, value = TRUE)[1])
cmr1 <- lire_couche(grep("ADM_?1$", couches, value = TRUE)[1])
cmr2 <- lire_couche(grep("ADM_?2$", couches, value = TRUE)[1])

cat(sprintf("ADM0 : %d entite(s) | ADM1 : %d regions | ADM2 : %d departements\n",
            nrow(cmr0), nrow(cmr1), nrow(cmr2)))
cat("Geometries valides ADM1 :", sum(st_is_valid(cmr1)), "/", nrow(cmr1), "\n")
cat("Geometries valides ADM2 :", sum(st_is_valid(cmr2)), "/", nrow(cmr2), "\n")

# Superficies MESUREES sur la geometrie d'origine, en UTM 33N.
cmr1$superficie_km2 <- as.numeric(st_area(st_transform(cmr1, CRS_MESURE))) / 1e6
cmr2$superficie_km2 <- as.numeric(st_area(st_transform(cmr2, CRS_MESURE))) / 1e6
cat("Superficie totale ADM1 (km2) :", round(sum(cmr1$superficie_km2)),
    " — reference officielle 475 442 km2\n")
cat("Ecart a la reference (%)     :",
    round(100 * (sum(cmr1$superficie_km2) - 475442) / 475442, 2), "\n")

# ---------------------------------------------------------------------
# 2. Le tableau administratif COD-PS
# ---------------------------------------------------------------------
cat("\n--- 2. Effectifs administratifs COD-PS 2025 ---\n")
admpop <- read_csv(file.path(dir_in, "cmr_admpop_adm1_2025.csv"),
                   show_col_types = FALSE)
cat("Lignes :", nrow(admpop), " | colonnes :", ncol(admpop), "\n")
cat("Colonnes de nom disponibles :",
    paste(intersect(c("ADM1_EN", "ADM1_FR", "ADM1_PCODE"), names(admpop)),
          collapse = ", "), "\n")

# CHOIX DE LA CLE PAR LES DONNEES, jamais en dur : on compte les
# appariements de chaque candidate contre NAME_1 de GADM.
candidates <- intersect(c("ADM1_EN", "ADM1_FR"), names(admpop))
score <- vapply(candidates,
                function(c) sum(cmr1$NAME_1 %in% admpop[[c]]), integer(1))
print(score)
cle_admpop <- names(which.max(score))
cat("Cle retenue :", cle_admpop, " (",  max(score), "/", nrow(cmr1),
    " regions appariees )\n", sep = "")
if (max(score) < nrow(cmr1)) {
  cat("ATTENTION — appariement incomplet. Regions GADM sans ligne COD-PS :\n")
  print(setdiff(cmr1$NAME_1, admpop[[cle_admpop]]))
}

admpop$cle_region <- admpop[[cle_admpop]]

# ---------------------------------------------------------------------
# 3. Extraction zonale WorldPop — trois millesimes, ADM1 et ADM2
# ---------------------------------------------------------------------
cat("\n--- 3. Extraction zonale WorldPop (exact_extract) ---\n")

chemins_wp <- c(
  "2015" = file.path(dir_in, "cmr_pop_2015_CN_100m_R2025A_v1.tif"),
  "2025" = file.path(dir_in, "cmr_pop_2025_CN_100m_R2025A_v1.tif"),
  "2030" = file.path(dir_in, "cmr_pop_2030_CN_100m_R2025A_v1.tif")
)

zonal_wp <- function(chemin, couche) {
  r <- rast(chemin)
  # Controle : les trois millesimes doivent partager la MEME grille, sinon
  # la comparaison temporelle mesure un changement de methode.
  cat(sprintf("    %s : EPSG %s | res %.6f | %d cellules\n",
              basename(chemin),
              crs(r, describe = TRUE)$code %||% "?",
              res(r)[1], ncell(r)))
  # exact_extract() attend le vecteur DANS le CRS du raster, et pondere
  # chaque cellule par la FRACTION de sa surface couverte par le polygone.
  exact_extract(r, st_transform(couche, crs(r)), "sum", progress = FALSE)
}

pop_adm1 <- lapply(chemins_wp, zonal_wp, couche = cmr1)
pop_adm2 <- zonal_wp(chemins_wp[["2025"]], cmr2)

cat("  Regions sans valeur WorldPop 2025 :", sum(is.na(pop_adm1[["2025"]])), "\n")
cat("  Somme zonale nationale 2025       :",
    format(round(sum(pop_adm1[["2025"]], na.rm = TRUE)), big.mark = " "), "\n")
cat("  Departements sans valeur          :", sum(is.na(pop_adm2)), "\n")

# ---------------------------------------------------------------------
# 4. GHS-POP : decompresser, mosaiquer, extraire
# ---------------------------------------------------------------------
cat("\n--- 4. GHS-POP R2023A 2025 (7 tuiles Mollweide) ---\n")
pop_ghs_adm1        <- rep(NA_real_, nrow(cmr1))
pop_ghs_adm1_reproj <- rep(NA_real_, nrow(cmr1))

if (length(tuiles_ghs) == 0) {
  cat("Aucune tuile GHS-POP trouvee : la colonne pop_ghspop_2025 restera NA.\n")
  cat("Le runtime doit alors afficher ces regions en GRIS, pas a zero.\n")
} else {
  # Une sortie n'ecrit JAMAIS dans datasets/ : on decompresse en temporaire.
  tmp <- file.path(tempdir(), "ghs_pop_j08")
  dir.create(tmp, showWarnings = FALSE, recursive = TRUE)
  for (z in tuiles_ghs) unzip(z, exdir = tmp, overwrite = TRUE)
  tifs <- list.files(tmp, pattern = "\\.tif$", full.names = TRUE)
  cat("Tuiles decompressees :", length(tifs), "\n")

  mos <- terra::mosaic(terra::sprc(lapply(tifs, rast)), fun = "max")
  names(mos) <- "pop_ghspop"
  cat("Mosaique : EPSG", crs(mos, describe = TRUE)$code %||% "?",
      "| res", paste(round(res(mos), 2), collapse = " x "), "\n")

  # SENTINELLES : les valeurs negatives marquent le nodata GHSL. Elles
  # traversent sum() sans un mot. On les compte AVANT de les recoder.
  n_neg <- as.numeric(global(mos < 0, "sum", na.rm = TRUE)[[1]])
  cat("Cellules negatives (sentinelles nodata) :", format(n_neg, big.mark = " "),
      "-> recodees en NA\n")
  mos[mos < 0] <- NA

  # (a) EXTRACTION DANS LE CRS NATIF (Mollweide, projection equivalente) :
  #     c'est la mesure JUSTE — aucune resampling, la somme est conservee.
  pop_ghs_adm1 <- exact_extract(mos, st_transform(cmr1, crs(mos)), "sum",
                                progress = FALSE)
  cat("Total GHS-POP (CRS natif) :",
      format(round(sum(pop_ghs_adm1, na.rm = TRUE)), big.mark = " "), "\n")

  # (b) LA MEME EXTRACTION APRES REPROJECTION EN EPSG:4326 : reprojeter un
  #     raster d'EFFECTIFS ne conserve pas la somme (le reechantillonnage
  #     redistribue les valeurs sur une grille de geometrie differente).
  #     On mesure ce cout au lieu de le taire ; le runtime l'affiche.
  #     Ce bloc est le plus lent du script (plusieurs minutes).
  ok <- tryCatch({
    mos4326 <- project(mos, "EPSG:4326", method = "bilinear")
    pop_ghs_adm1_reproj <<- exact_extract(mos4326,
                                          st_transform(cmr1, 4326), "sum",
                                          progress = FALSE)
    TRUE
  }, error = function(e) { cat("Reprojection echouee :", conditionMessage(e),
                               "\n"); FALSE })
  if (ok) {
    cat("Total GHS-POP (reprojete 4326) :",
        format(round(sum(pop_ghs_adm1_reproj, na.rm = TRUE)), big.mark = " "),
        "\n")
    cat("Cout de la reprojection (%) :",
        round(100 * (sum(pop_ghs_adm1_reproj, na.rm = TRUE) -
                     sum(pop_ghs_adm1, na.rm = TRUE)) /
              sum(pop_ghs_adm1, na.rm = TRUE), 3), "\n")
  }
}

# ---------------------------------------------------------------------
# 5. Assemblage ADM1 : les trois sources cote a cote
# ---------------------------------------------------------------------
cat("\n--- 5. Assemblage ADM1 ---\n")

table_officielle <- admpop |>
  transmute(cle_region,
            pop_officielle_2025 = .data$T_TL,
            femmes_2025         = .data$F_TL,
            hommes_2025         = .data$M_TL)

adm1 <- cmr1 |>
  select(GID_1, NAME_1, superficie_km2) |>
  mutate(
    pop_worldpop_2015 = round(pop_adm1[["2015"]]),
    pop_worldpop_2025 = round(pop_adm1[["2025"]]),
    pop_worldpop_2030 = round(pop_adm1[["2030"]]),
    pop_ghspop_2025   = round(pop_ghs_adm1),
    pop_ghspop_2025_reproj = round(pop_ghs_adm1_reproj)
  ) |>
  # ON PART DE LA COUCHE GEOGRAPHIQUE : l'inverse perdrait la geometrie.
  left_join(table_officielle, by = c("NAME_1" = "cle_region")) |>
  mutate(
    variation_2015_2025 = pop_worldpop_2025 - pop_worldpop_2015,
    croissance_pct      = round(100 * variation_2015_2025 / pop_worldpop_2015, 1),
    densite_wp_2025     = round(pop_worldpop_2025 / superficie_km2, 1),
    densite_off_2025    = round(pop_officielle_2025 / superficie_km2, 1),
    ecart_wp_off_pct    = round(100 * (pop_worldpop_2025 - pop_officielle_2025) /
                                  pop_officielle_2025, 1),
    ecart_ghs_wp_pct    = round(100 * (pop_ghspop_2025 - pop_worldpop_2025) /
                                  pop_worldpop_2025, 1),
    ecart_ghs_off_pct   = round(100 * (pop_ghspop_2025 - pop_officielle_2025) /
                                  pop_officielle_2025, 1),
    superficie_km2      = round(superficie_km2, 1)
  )

# INSTRUMENTATION APRES JOINTURE — une jointure ratee ne leve pas d'erreur.
cat("Regions sans effectif officiel apparie :",
    sum(is.na(adm1$pop_officielle_2025)), "/", nrow(adm1), "\n")
cat("Regions sans valeur GHS-POP            :",
    sum(is.na(adm1$pop_ghspop_2025)), "/", nrow(adm1), "\n")

adm1_simple <- adm1 |>
  st_transform(CRS_MESURE) |>
  st_simplify(dTolerance = TOL_ADM1_M, preserveTopology = TRUE) |>
  st_transform(4326) |>
  st_make_valid()
cat("Simplification ADM1 : tolerance", TOL_ADM1_M, "m — geometries valides :",
    sum(st_is_valid(adm1_simple)), "/", nrow(adm1_simple), "\n")

# ---------------------------------------------------------------------
# 6. Assemblage ADM2 — la maille du MAUP
# ---------------------------------------------------------------------
adm2 <- cmr2 |>
  select(GID_1, GID_2, NAME_1, NAME_2, superficie_km2) |>
  mutate(
    pop_worldpop_2025 = round(pop_adm2),
    densite_wp_2025   = round(pop_worldpop_2025 / superficie_km2, 1),
    superficie_km2    = round(superficie_km2, 1)
  )

adm2_simple <- adm2 |>
  st_transform(CRS_MESURE) |>
  st_simplify(dTolerance = TOL_ADM2_M, preserveTopology = TRUE) |>
  st_transform(4326) |>
  st_make_valid()
cat("Simplification ADM2 : tolerance", TOL_ADM2_M, "m — geometries valides :",
    sum(st_is_valid(adm2_simple)), "/", nrow(adm2_simple), "\n")

# ---------------------------------------------------------------------
# 7. Structure par age : indicateurs et pyramide
# ---------------------------------------------------------------------
cat("\n--- 7. Structure par age (COD-PS) ---\n")
tranches <- c("00_04","05_09","10_14","15_19","20_24","25_29","30_34","35_39",
              "40_44","45_49","50_54","55_59","60_64","65_69","70_74","75_79",
              "80Plus")
col_T <- paste0("T_", tranches)
presentes <- intersect(col_T, names(admpop))
cat("Tranches quinquennales trouvees :", length(presentes), "/", length(col_T),
    "\n")
if (length(presentes) < length(col_T)) {
  cat("Tranches absentes :", paste(setdiff(col_T, presentes), collapse = ", "),
      "\n")
}

jeunes <- intersect(paste0("T_", c("00_04","05_09","10_14")), names(admpop))
aines  <- intersect(paste0("T_", c("65_69","70_74","75_79","80Plus")),
                    names(admpop))

indicateurs <- admpop |>
  transmute(
    NAME_1              = cle_region,
    pop_officielle_2025 = .data$T_TL,
    femmes_2025         = .data$F_TL,
    hommes_2025         = .data$M_TL,
    ratio_fh            = round(.data$F_TL / .data$M_TL, 3),
    part_moins_15_pct   = round(100 * rowSums(across(all_of(jeunes))) /
                                  .data$T_TL, 1),
    part_65_plus_pct    = round(100 * rowSums(across(all_of(aines))) /
                                  .data$T_TL, 1)
  ) |>
  arrange(desc(pop_officielle_2025))

# CONTROLE DE PLAUSIBILITE : un ratio F/H hors de [0,85 ; 1,15] sur une
# region entiere signale une erreur de colonne, pas une singularite.
cat("Ratio F/H : min", round(min(indicateurs$ratio_fh), 3),
    "| max", round(max(indicateurs$ratio_fh), 3), "\n")
cat("Somme des tranches = T_TL ? ecart max (%) :",
    round(max(abs(100 * (rowSums(admpop[, presentes]) - admpop$T_TL) /
                    admpop$T_TL)), 3), "\n")

pyramide <- admpop |>
  select(cle_region, all_of(intersect(c(paste0("F_", tranches),
                                        paste0("M_", tranches)),
                                      names(admpop)))) |>
  pivot_longer(-cle_region, names_to = "colonne", values_to = "effectif") |>
  mutate(
    NAME_1      = cle_region,
    sexe        = ifelse(startsWith(colonne, "F_"), "Femmes", "Hommes"),
    tranche_age = sub("^[FM]_", "", colonne),
    # ordre_tranche : l'ordre alphabetique de "80Plus" et de "05_09" ne
    # coincide pas avec l'ordre demographique. On le pose explicitement.
    ordre_tranche = match(tranche_age, tranches)
  ) |>
  select(NAME_1, sexe, tranche_age, ordre_tranche, effectif) |>
  arrange(NAME_1, sexe, ordre_tranche)

cat("Pyramide : ", nrow(pyramide), " lignes (",
    length(unique(pyramide$NAME_1)), " regions x ",
    length(unique(pyramide$tranche_age)), " tranches x 2 sexes)\n", sep = "")

# ---------------------------------------------------------------------
# 8. Totaux nationaux — trois sources ne s'accordent pas
# ---------------------------------------------------------------------
totaux <- tibble::tibble(
  source = c("WorldPop constrained R2025A", "WorldPop constrained R2025A",
             "WorldPop constrained R2025A", "GHS-POP R2023A",
             "COD-PS (projection administrative)"),
  annee  = c(2015, 2025, 2030, 2025, 2025),
  statut = c("modele de redistribution", "modele de redistribution",
             "projection du modele", "modele de redistribution",
             "projection demographique"),
  population = c(
    sum(adm1$pop_worldpop_2015, na.rm = TRUE),
    sum(adm1$pop_worldpop_2025, na.rm = TRUE),
    sum(adm1$pop_worldpop_2030, na.rm = TRUE),
    sum(adm1$pop_ghspop_2025,   na.rm = TRUE),
    sum(adm1$pop_officielle_2025, na.rm = TRUE)
  )
)
cat("\n--- 8. Totaux nationaux ---\n")
print(totaux)

# ---------------------------------------------------------------------
# 9. Ecriture
# ---------------------------------------------------------------------
cat("\n--- 9. Ecriture des sorties ---\n")
ecrire_geojson(adm1_simple, "J08_adm1_population.geojson")
ecrire_geojson(adm2_simple, "J08_adm2_population.geojson")
ecrire_csv(indicateurs, "J08_adm1_indicateurs.csv")
ecrire_csv(pyramide,    "J08_pyramide_adm1.csv")
ecrire_csv(totaux,      "J08_totaux_nationaux.csv")

readme <- tibble::tibble(
  fichier = c("J08_adm1_population.geojson", "J08_adm2_population.geojson",
              "J08_adm1_indicateurs.csv", "J08_pyramide_adm1.csv",
              "J08_totaux_nationaux.csv"),
  unite_observation = c("region ADM1", "departement ADM2", "region ADM1",
                        "region x tranche x sexe", "source x annee"),
  produit_par = "pedagogie/_commons/data/J08_extraits/00_extraire_J08.R",
  consomme_par = "pedagogie/J08_population_haute_resolution/runtime.qmd",
  taille_ko = c(
    poids_ko(file.path(dir_out, "J08_adm1_population.geojson")),
    poids_ko(file.path(dir_out, "J08_adm2_population.geojson")),
    poids_ko(file.path(dir_out, "J08_adm1_indicateurs.csv")),
    poids_ko(file.path(dir_out, "J08_pyramide_adm1.csv")),
    poids_ko(file.path(dir_out, "J08_totaux_nationaux.csv"))
  )
)
ecrire_csv(readme, "J08_extraits_README.csv")

cat("\n=====================================================\n")
cat(" Extraction J08 terminee. Poids total des sorties :",
    round(sum(file.size(list.files(dir_out, full.names = TRUE,
                                   pattern = "\\.(csv|geojson)$"))) / 1024),
    "Ko\n")
cat(" Relire les compteurs ci-dessus AVANT de rendre runtime.qmd.\n")
cat("=====================================================\n")
