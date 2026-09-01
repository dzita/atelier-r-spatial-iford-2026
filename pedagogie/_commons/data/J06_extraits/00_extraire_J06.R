# =====================================================================
# 00_extraire_J06.R
# Atelier IFORD x GDSG 2026 - J06 « L'art de la cartographie »
#
# A QUOI SERT CE SCRIPT
#   Le runtime WebR (pedagogie/J06_art_cartographie/runtime.qmd) refait
#   TOUT le travail cartographique en ggplot2 + geom_sf(). Deux paquets
#   centraux de la journee sont indisponibles dans le navigateur :
#     - tmap    (trop de dependances pour un chargement navigateur fluide) ;
#     - classInt (discretisation Jenks / Fisher) ;
#   et deux autres le sont pour la lecture des sources :
#     - haven (ECAM5 .dta, EDS .SAV) ;
#     - leaflet / mapview (widgets interactifs, interdits en document
#       distribue de toute facon -- REGLES §6.6).
#
#   Consequence sur le partage des roles :
#     - CE SCRIPT lit les binaires, pondere, calcule les bornes de Jenks
#       (que WebR ne sait pas calculer) et ecrit des couches legeres ;
#     - LE RUNTIME calcule en direct ce qu'il PEUT calculer -- quantiles
#       (`quantile()`), intervalles egaux (`seq()`), moyenne/ecart-type --
#       et lit les bornes de Jenks dans un CSV. Le participant compare
#       ainsi quatre discretisations du MEME tableau, et voit que la carte
#       change alors que la donnee, elle, ne bouge pas.
#
# QUAND LE RELANCER
#   - a la premiere mise en place du depot ;
#   - si les CSV WorldPop ou GADM sont remplaces ;
#   - si la regle de recodage de s09q13a change (section 2).
#
# A EXECUTER PAR L'UTILISATEUR LUI-MEME.
#   La session qui a ecrit ce fichier ne disposait NI de R, NI de shell :
#   rien n'a ete execute. Les points « A VALIDER AU PREMIER RENDU » sont
#   des hypotheses sur le contenu des binaires.
#
# ENTREES (dans pedagogie/J06_art_cartographie/datasets/)
#   gadm41_CMR_1.shp    10 regions   (NAME_1, GID_1)
#   gadm41_CMR_2.shp    58 DEPARTEMENTS -- pas des arrondissements
#   DS.geojson          200 districts sanitaires (135 geometries invalides)
#   CMGE71FL.shp        430 grappes EDS geolocalisees
#   CMHR71FL.SAV        recode menage EDS 2018 (MAJUSCULES, >4 000 colonnes)
#   ecam5.dta           9 472 individus / 2 065 menages
#   CMR_population_v1_0_admin_level2.csv   separateur « ; »
#   CMR_household_v1_0_admin_level2.csv    separateur « , »
#
# SORTIES (dans _commons/data/J06_extraits/) -- CONTRAT AVEC LE RUNTIME :
#   cmr_adm1_carto.geojson       10 regions + indicateurs + ecart a la moyenne
#   cmr_adm2_carto.geojson       58 departements + population/menages WorldPop
#   cmr_ds_carto.geojson         200 districts sanitaires + acces a l'eau
#   eds_grappes_points.csv       430 grappes (lon, lat, milieu, indicateurs)
#   bornes_discretisation.csv    4 methodes x plusieurs variables
#   J06_extraits_README.csv      documentation des sorties
#   Ne pas renommer sans corriger runtime.qmd (webr.resources ET lectures).
#
# Usage :
#   source("pedagogie/_commons/data/J06_extraits/00_extraire_J06.R")
#
# Dependances :
#   install.packages(c("sf", "haven", "dplyr", "tidyr", "readr", "stringr",
#                      "stringi", "classInt", "rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 600)

.deps <- c("sf", "haven", "dplyr", "tidyr", "readr", "stringr",
           "stringi", "classInt", "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J06-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(sf)
  library(haven)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(classInt)
})

sf_use_s2(FALSE)   # DS.geojson : 135 geometries invalides sur 200

.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

dir_in  <- file.path(.PROJECT_ROOT, "pedagogie", "J06_art_cartographie",
                     "datasets")
dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J06_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# Tolerances de simplification, en DEGRES (les couches sont en EPSG:4326).
TOL_ADM1 <- 0.010   # ~1,1 km
TOL_ADM2 <- 0.006   # ~0,66 km
TOL_DS   <- 0.005   # ~0,55 km

normaliser <- function(x) {
  x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    tolower() |>
    stringr::str_replace_all("[^a-z ]", " ") |>
    stringr::str_replace_all("\\b(et|de|du|la|le)\\b", " ") |>
    stringr::str_replace_all("\\s+", "")
}

# ----------------------------------------------------------------------
# 1. Les trois mailles geographiques
# ----------------------------------------------------------------------
message("[J06-extrait] Lecture des couches administratives...")
adm1 <- st_read(file.path(dir_in, "gadm41_CMR_1.shp"), quiet = TRUE) |>
  st_make_valid() |> mutate(cle = normaliser(NAME_1))
adm2 <- st_read(file.path(dir_in, "gadm41_CMR_2.shp"), quiet = TRUE) |>
  st_make_valid() |> mutate(cle = normaliser(NAME_2))
cat(sprintf("[J06-extrait] ADM1 : %d entites ; ADM2 : %d entites (58 departements attendus)\n",
            nrow(adm1), nrow(adm2)))

# Superficies : MESURER EXIGE DE REPROJETER. EPSG:4326 est en degres, toute
# superficie calculee dessus est fausse. UTM 33N (EPSG:32633) pour le Cameroun.
# Controle : le total doit approcher les 475 442 km2 officiels.
adm1$superficie_km2 <- as.numeric(st_area(st_transform(adm1, 32633))) / 1e6
adm2$superficie_km2 <- as.numeric(st_area(st_transform(adm2, 32633))) / 1e6
cat(sprintf("[J06-extrait] Superficie totale ADM1 : %.0f km2 (officiel : 475 442)\n",
            sum(adm1$superficie_km2)))

# ----------------------------------------------------------------------
# 2. ECAM5 : l'indicateur regional du fond de carte
#    Pauvrete monetaire (nivie) + satisfaction alimentaire (s09q13a), les
#    deux PONDERES par coefextr. Le FIES de la FAO n'a jamais ete fourni :
#    s09q13a en tient lieu (decision consignee, REPRISE_J06_J11.md §3).
# ----------------------------------------------------------------------
message("[J06-extrait] Lecture ECAM5 (ecam5.dta)...")
ecam5 <- read_dta(file.path(dir_in, "ecam5.dta"))
cat(sprintf("[J06-extrait] ECAM5 : %d lignes x %d colonnes\n",
            nrow(ecam5), ncol(ecam5)))

# BLOC DEFENSIF : on regarde la variable AVANT de la recoder.
# Une variable Stata sans libelle de valeur n'est pas un haven_labelled :
# as_factor() n'aurait alors rien a traduire.
if ("s09q13a" %in% names(ecam5)) {
  cat("[J06-extrait] Modalites de s09q13a (satisfaction alimentaire) :\n")
  print(table(as.character(haven::as_factor(ecam5$s09q13a)), useNA = "ifany"))
} else {
  warning("[J06-extrait] s09q13a absente : l'indicateur alimentaire sera NA.")
}

ecam <- ecam5 |>
  mutate(
    region_eq = as.character(as_factor(s0q1)),
    poids     = as.numeric(coefextr),
    pauvre    = as.numeric(nivie)
  ) |>
  mutate(cle_eq = normaliser(region_eq)) |>
  # Douala et Yaounde ne sont pas des regions administratives : ce sont les
  # capitales du Littoral et du Centre. Table de correspondance ECRITE A LA
  # MAIN -- aucune manipulation de chaine ne devine cela.
  mutate(region_adm = case_when(
    cle_eq == normaliser("Douala")  ~ "Littoral",
    cle_eq == normaliser("Yaounde") ~ "Centre",
    TRUE ~ region_eq
  ),
  cle = normaliser(region_adm))

# HYPOTHESE, A VALIDER AU PREMIER RENDU : les modalites de s09q13a dont le
# libelle porte une marque de negation ou d'insatisfaction designent les
# menages NON satisfaits ; les libelles de non-reponse passent a NA
# (non-reponse, pas « satisfait »). Si les libelles reels different, corriger
# les deux motifs ci-dessous -- c'est le seul endroit a changer.
MOTIF_INSATISFAIT <- "(?i)non|pas|jamais|insatisf|insuffis|rarement"
MOTIF_NONREPONSE  <- "(?i)^\\s*(nsp|ne sait|refus|sans|manquant|na)\\b"

if ("s09q13a" %in% names(ecam5)) {
  lib <- as.character(haven::as_factor(ecam5$s09q13a))
  ecam$insatisfait <- case_when(
    is.na(lib)                            ~ NA_real_,
    str_detect(lib, MOTIF_NONREPONSE)     ~ NA_real_,
    str_detect(lib, MOTIF_INSATISFAIT)    ~ 1,
    TRUE                                  ~ 0
  )
} else {
  ecam$insatisfait <- NA_real_
}

ind_region <- ecam |>
  group_by(cle, region_adm) |>
  summarise(
    n_individus       = n(),
    tx_pauvrete       = 100 * sum(pauvre * poids, na.rm = TRUE) /
                              sum(poids[!is.na(pauvre)]),
    tx_insatisf_alim  = 100 * sum(insatisfait * poids, na.rm = TRUE) /
                              sum(poids[!is.na(insatisfait)]),
    .groups = "drop"
  )
cat("[J06-extrait] Indicateurs regionaux ECAM5 (extrait de formation) :\n")
print(as.data.frame(ind_region))
cat("[J06-extrait] RAPPEL : ces taux regionaux ne sont PAS citables\n")
cat("  (extrait non representatif a l'interieur des regions).\n")

# ----------------------------------------------------------------------
# 3. WorldPop : population et menages par departement
#    PIEGE DE SEPARATEUR : population en « ; », menages en « , ».
#    read_csv() sur le premier renverrait UNE colonne unique, sans erreur.
# ----------------------------------------------------------------------
pop2 <- read_delim(file.path(dir_in, "CMR_population_v1_0_admin_level2.csv"),
                   delim = ";", show_col_types = FALSE)
men2 <- read_csv(file.path(dir_in, "CMR_household_v1_0_admin_level2.csv"),
                 show_col_types = FALSE)
cat(sprintf("[J06-extrait] WorldPop population : %d lignes, %d colonnes (attendu 7)\n",
            nrow(pop2), ncol(pop2)))
cat(sprintf("[J06-extrait] WorldPop menages    : %d lignes, %d colonnes (attendu 7)\n",
            nrow(men2), ncol(men2)))
if (ncol(pop2) == 1) stop("[J06-extrait] Mauvais separateur sur le fichier population.")

pop2 <- pop2 |> transmute(cle = normaliser(names1),
                          pop_total = as.numeric(total),
                          pop_incertitude = as.numeric(uncertainty))
men2 <- men2 |> transmute(cle = normaliser(names1),
                          menages_total = as.numeric(total))

# On part TOUJOURS de la couche geographique, pas du tableau : l'inverse
# perd la geometrie.
adm2_carto <- adm2 |>
  select(GID_1, NAME_1, GID_2, NAME_2, cle, superficie_km2) |>
  left_join(pop2, by = "cle") |>
  left_join(men2, by = "cle") |>
  mutate(
    densite           = pop_total / superficie_km2,
    taille_moy_menage = pop_total / menages_total
  )
cat(sprintf("[J06-extrait] Departements sans population apres jointure : %d sur %d\n",
            sum(is.na(adm2_carto$pop_total)), nrow(adm2_carto)))
if (any(is.na(adm2_carto$pop_total))) {
  cat("  -> orphelins : ",
      paste(adm2_carto$NAME_2[is.na(adm2_carto$pop_total)], collapse = ", "),
      "\n  (ecrire une table de correspondance a la main si la normalisation ne suffit pas)\n")
}

# Centroides, pour la carte a symboles proportionnels du runtime. On les
# calcule ICI : st_centroid sur une couche non simplifiee est plus juste,
# et le runtime n'a plus qu'a lire deux colonnes numeriques.
ctr <- suppressWarnings(st_coordinates(st_centroid(st_geometry(adm2_carto))))
adm2_carto$lon_c <- ctr[, 1]
adm2_carto$lat_c <- ctr[, 2]

# ----------------------------------------------------------------------
# 4. EDS : acces a l'eau amelioree par grappe, puis par district sanitaire
#    (la troisieme maille du MAUP dans le runtime)
# ----------------------------------------------------------------------
message("[J06-extrait] Lecture EDS menages (CMHR71FL.SAV) - 10 a 60 s...")
f_sav <- file.path(dir_in, "CMHR71FL.SAV")
vars_voulues <- c("hv001", "hv005", "hv009", "hv024", "hv025",
                  "hv201", "hv206", "hv270")
noms_sav <- names(read_sav(f_sav, n_max = 0))
vars     <- noms_sav[match(toupper(vars_voulues), toupper(noms_sav))]
if (anyNA(vars)) {
  warning("[J06-extrait] Variables EDS introuvables : ",
          paste(vars_voulues[is.na(vars)], collapse = ", "))
  vars <- na.omit(vars)
}
hr <- read_sav(f_sav, col_select = all_of(as.character(vars)))
names(hr) <- tolower(names(hr))

# Definition JMP (OMS/UNICEF) d'une source AMELIOREE. « Source amelioree »
# n'est PAS « eau potable » : la definition porte sur le type d'ouvrage, pas
# sur la qualite de l'eau ni sur la continuite du service.
# A VALIDER AU PREMIER RENDU : verifier que les codes imprimes ci-dessous
# sont bien couverts.
codes_eau_amelioree <- c(11, 12, 13, 14, 21, 31, 41, 51, 61, 62, 71, 72)
cat("[J06-extrait] Codes hv201 presents :\n")
print(sort(unique(as.numeric(hr$hv201))))

grappes_ind <- hr |>
  mutate(grappe = as.numeric(hv001),
         poids  = as.numeric(hv005) / 1e6,
         eau    = as.numeric(as.numeric(hv201) %in% codes_eau_amelioree),
         elec   = as.numeric(as.numeric(hv206) == 1),
         taille = as.numeric(hv009)) |>
  group_by(grappe) |>
  summarise(n_menages        = n(),
            poids_total      = sum(poids),
            tx_eau_amelioree = 100 * sum(eau  * poids) / sum(poids),
            tx_electricite   = 100 * sum(elec * poids) / sum(poids),
            taille_moy       = sum(taille * poids) / sum(poids),
            .groups = "drop")

ge <- st_read(file.path(dir_in, "CMGE71FL.shp"), quiet = TRUE) |> st_make_valid()
n_zero <- sum(ge$LATNUM == 0 & ge$LONGNUM == 0)
cat(sprintf("[J06-extrait] Grappes en (0,0) exclues : %d sur %d\n", n_zero, nrow(ge)))
ge <- ge |> filter(!(LATNUM == 0 & LONGNUM == 0))

grappes <- ge |>
  st_drop_geometry() |>
  transmute(dhsclust = DHSCLUST, region_eds = ADM1NAME,
            milieu = URBAN_RURA, lon = LONGNUM, lat = LATNUM) |>
  left_join(grappes_ind, by = c("dhsclust" = "grappe"))
cat(sprintf("[J06-extrait] Grappes sans indicateur apres jointure : %d\n",
            sum(is.na(grappes$tx_eau_amelioree))))
write_csv(grappes, file.path(dir_out, "eds_grappes_points.csv"))

# --- Districts sanitaires --------------------------------------------------
message("[J06-extrait] Lecture DS.geojson (~20 Mo)...")
ds <- st_read(file.path(dir_in, "DS.geojson"), quiet = TRUE)
cat(sprintf("[J06-extrait] DS : %d entites, valides avant reparation : %d\n",
            nrow(ds), sum(st_is_valid(ds))))
ds <- st_make_valid(ds) |>
  mutate(ds_nom    = str_squish(str_remove(name,       "^District\\s*")),
         region_ds = str_squish(str_remove(parentName, "^Region\\s*"))) |>
  select(ds_nom, region_ds)
cat(sprintf("[J06-extrait] DS valides apres st_make_valid() : %d\n", sum(st_is_valid(ds))))

pts <- grappes |>
  filter(!is.na(lon), !is.na(lat)) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)
if (st_crs(pts) != st_crs(ds)) ds <- st_transform(ds, st_crs(pts))

n_avant <- nrow(pts)
pts_ds <- st_join(pts, ds, join = st_within)
cat(sprintf("[J06-extrait] st_join : %d avant, %d apres (duplicats = %d)\n",
            n_avant, nrow(pts_ds), nrow(pts_ds) - n_avant))
pts_ds <- pts_ds |> distinct(dhsclust, .keep_all = TRUE)

i_orph <- which(is.na(pts_ds$ds_nom))
cat(sprintf("[J06-extrait] Grappes recalees au district le plus proche : %d\n",
            length(i_orph)))
if (length(i_orph) > 0) {
  j <- st_nearest_feature(pts_ds[i_orph, ], ds)
  pts_ds$ds_nom[i_orph]    <- ds$ds_nom[j]
  pts_ds$region_ds[i_orph] <- ds$region_ds[j]
}

ds_ind <- pts_ds |>
  st_drop_geometry() |>
  filter(!is.na(tx_eau_amelioree)) |>
  group_by(ds_nom) |>
  summarise(n_grappes        = n(),
            tx_eau_amelioree = sum(tx_eau_amelioree * poids_total) /
                               sum(poids_total),
            .groups = "drop")

ds_carto <- ds |>
  left_join(ds_ind, by = "ds_nom") |>
  mutate(fiable = !is.na(n_grappes) & n_grappes >= 3)
cat(sprintf("[J06-extrait] DS renseignes : %d / %d ; fiables (>=3 grappes) : %d\n",
            sum(!is.na(ds_carto$tx_eau_amelioree)), nrow(ds_carto),
            sum(ds_carto$fiable)))

# --- ADM1 : la meme grandeur, remontee a la maille regionale ---------------
# Le runtime compare region / departement / district : c'est le MAUP mis en
# scene. On calcule donc l'eau amelioree AUSSI par region, en reponderant.
pts_adm1 <- st_join(pts, select(st_transform(adm1, st_crs(pts)), NAME_1),
                    join = st_within) |>
  distinct(dhsclust, .keep_all = TRUE)
eau_region <- pts_adm1 |>
  st_drop_geometry() |>
  filter(!is.na(tx_eau_amelioree), !is.na(NAME_1)) |>
  group_by(NAME_1) |>
  summarise(n_grappes = n(),
            tx_eau_amelioree = sum(tx_eau_amelioree * poids_total) /
                               sum(poids_total),
            .groups = "drop")

adm1_carto <- adm1 |>
  select(GID_1, NAME_1, cle, superficie_km2) |>
  left_join(ind_region, by = "cle") |>
  left_join(eau_region, by = "NAME_1") |>
  mutate(
    # Colonne pensee pour une palette DIVERGENTE : elle a un centre neutre
    # (le zero = la moyenne nationale non ponderee des regions). Une palette
    # sequentielle sur cette colonne serait un contresens de semiologie.
    ecart_eau_moyenne = tx_eau_amelioree - mean(tx_eau_amelioree, na.rm = TRUE)
  )
cat(sprintf("[J06-extrait] Regions sans taux d'eau : %d sur %d\n",
            sum(is.na(adm1_carto$tx_eau_amelioree)), nrow(adm1_carto)))

# ----------------------------------------------------------------------
# 5. Bornes de discretisation -- ce que WebR ne peut PAS calculer
#    quantiles et intervalles egaux sont refaits en direct dans le runtime
#    (quantile() / seq() sont dans R base) ; JENKS et FISHER exigent
#    classInt, absent de WebR : on les pre-calcule ici.
# ----------------------------------------------------------------------
bornes_de <- function(x, variable, maille, n = 5) {
  x <- x[is.finite(x)]
  if (length(x) < n + 1) return(NULL)
  methodes <- c(quantile = "quantile", egal = "equal",
                jenks = "jenks", ecart_type = "sd")
  res <- lapply(names(methodes), function(m) {
    br <- tryCatch(
      classInt::classIntervals(x, n = n, style = methodes[[m]])$brks,
      error = function(e) NULL)
    if (is.null(br)) return(NULL)
    tibble(variable = variable, maille = maille, methode = m,
           classe = seq_len(length(br) - 1),
           borne_inf = head(br, -1), borne_sup = br[-1])
  })
  bind_rows(res)
}

bornes <- bind_rows(
  bornes_de(adm1_carto$tx_eau_amelioree, "tx_eau_amelioree", "region"),
  bornes_de(adm1_carto$tx_pauvrete,      "tx_pauvrete",      "region"),
  bornes_de(adm2_carto$densite,          "densite",          "departement"),
  bornes_de(adm2_carto$pop_total,        "pop_total",        "departement"),
  bornes_de(ds_carto$tx_eau_amelioree,   "tx_eau_amelioree", "district")
)
write_csv(bornes, file.path(dir_out, "bornes_discretisation.csv"))
cat(sprintf("[J06-extrait] bornes_discretisation.csv : %d lignes, %d combinaisons variable x maille x methode\n",
            nrow(bornes), n_distinct(paste(bornes$variable, bornes$maille, bornes$methode))))

# ----------------------------------------------------------------------
# 6. Simplifier -- et dire ce que cela coute
# ----------------------------------------------------------------------
# st_simplify (Douglas-Peucker) supprime les sommets qui s'ecartent de moins
# de dTolerance de la ligne simplifiee. Tolerance en DEGRES ici (EPSG:4326).
#
# CE QUE CELA COUTE, et pourquoi c'est acceptable pour CE document :
#   - le trait de cote et les frontieres perdent leur detail fin ; a
#     l'echelle d'affichage du runtime (le pays entier sur 7 pouces de
#     large) la difference est sous le pixel ;
#   - deux polygones voisins peuvent cesser de coincider exactement : de
#     fines fentes blanches peuvent apparaitre entre departements. Si elles
#     genent, baisser TOL_ADM2 -- au prix du poids du fichier ;
#   - les superficies changent legerement. C'est pourquoi superficie_km2 et
#     densite sont calcules AVANT la simplification, sur la geometrie
#     d'origine reprojetee en UTM 33N. Le runtime ne recalcule aucune
#     superficie : il lit la colonne.
message("[J06-extrait] Simplification des geometries...")
adm1_simp <- st_simplify(adm1_carto, dTolerance = TOL_ADM1, preserveTopology = TRUE)
adm2_simp <- st_simplify(adm2_carto, dTolerance = TOL_ADM2, preserveTopology = TRUE)
ds_simp   <- st_simplify(ds_carto,   dTolerance = TOL_DS,   preserveTopology = TRUE)
cat(sprintf("[J06-extrait] Entites conservees : ADM1 %d, ADM2 %d, DS %d\n",
            nrow(adm1_simp), nrow(adm2_simp), nrow(ds_simp)))

f1 <- file.path(dir_out, "cmr_adm1_carto.geojson")
f2 <- file.path(dir_out, "cmr_adm2_carto.geojson")
f3 <- file.path(dir_out, "cmr_ds_carto.geojson")
st_write(adm1_simp, f1, delete_dsn = TRUE, quiet = TRUE)
st_write(adm2_simp, f2, delete_dsn = TRUE, quiet = TRUE)
st_write(ds_simp,   f3, delete_dsn = TRUE, quiet = TRUE)

# ----------------------------------------------------------------------
# 7. README des extraits + bilan de poids
# ----------------------------------------------------------------------
sorties <- c("cmr_adm1_carto.geojson", "cmr_adm2_carto.geojson",
             "cmr_ds_carto.geojson", "eds_grappes_points.csv",
             "bornes_discretisation.csv")
readme <- tibble(
  fichier = sorties,
  entites = c(nrow(adm1_simp), nrow(adm2_simp), nrow(ds_simp),
              nrow(grappes), nrow(bornes)),
  unite   = c("region", "departement", "district sanitaire",
              "grappe EDS", "borne de classe"),
  source  = c("GADM 4.1 + ECAM5 + EDS-MICS 2018",
              "GADM 4.1 + WorldPop admin level 2",
              "DHIS2 MINSANTE + EDS-MICS 2018",
              "EDS-MICS 2018 (DHS)",
              "classInt (quantile / equal / jenks / sd)"),
  simplifiee = c(sprintf("oui, %.3f deg", TOL_ADM1),
                 sprintf("oui, %.3f deg", TOL_ADM2),
                 sprintf("oui, %.3f deg", TOL_DS),
                 "sans objet", "sans objet"),
  taille_ko = round(vapply(file.path(dir_out, sorties), file.size,
                           numeric(1)) / 1024)
)
write_csv(readme, file.path(dir_out, "J06_extraits_README.csv"))

cat("\n========================================================\n")
cat(" Extraction J06 pour WebR terminee.\n")
cat("========================================================\n")
cat(" Fichiers dans :\n  ", normalizePath(dir_out), "\n\n")
print(as.data.frame(readme))
cat(sprintf("\n Poids total des extraits : %.2f Mo\n",
            sum(readme$taille_ko) / 1024))
