# =====================================================================
# 00_extraire_J03.R
# Atelier IFORD x GDSG 2026 - J03 (L'univers vectoriel)
#
# Produit les EXTRAITS LEGERS dont a besoin le runtime WebR du J03
# (pedagogie/J03_univers_vectoriel/runtime.qmd).
#
# POURQUOI CE SCRIPT EXISTE.
#   Le J03 est la journee la plus favorable a WebR de tout l'atelier :
#   sf, dplyr et ggplot2 suffisent, et ces trois paquets sont disponibles
#   sur repo.r-wasm.org. Mais les fichiers sources du dossier-jour ne sont
#   pas servables tels quels au navigateur :
#     - DS.geojson pese ~20 Mo et porte 135 geometries invalides sur 200 ;
#     - les shapefiles (.shp/.shx/.dbf/.prj) voyagent a 4 fichiers, ce qui
#       complique la declaration `webr.resources` ;
#     - CMGC72FL.csv fait 430 lignes x 130 colonnes, dont l'immense
#       majorite ne sert a rien au J03.
#   On produit donc ici des couches GeoJSON simplifiees et des CSV reduits.
#
# EXECUTION
#   Ce script se lance manuellement depuis la racine du projet. Les `cat()`
#   impriment les poids et les effectifs reels au moment du lancement : ils
#   sont la seule source fiable, aucun chiffre n'est ecrit en dur ici.
#
# QUAND LE RELANCER.
#   - la premiere fois, avant le premier `quarto render` du site runtime ;
#   - a chaque fois que DS.geojson, CMGE71FL.shp, les CSV WorldPop ou
#     CMGC72FL.csv sont remplaces par une nouvelle livraison ;
#   - a chaque changement de la tolerance de simplification (voir plus bas).
#
# PRODUCTION (dans pedagogie/_commons/data/J03_extraits/) :
#   - ds_sante_cmr.geojson                   200 districts sanitaires
#   - dhs_grappes_cmr2018.geojson            430 grappes EDS geolocalisees
#   - pays_limitrophes_cmr.geojson           voisins du Cameroun
#   - CMR_population_v1_0_admin_level2.csv   copie VERBATIM (separateur ;)
#   - CMR_household_v1_0_admin_level2.csv    copie VERBATIM (separateur ,)
#   - covar_dhs_grappes_extrait.csv          430 grappes x ~12 covariables
#   - J03_extraits_README.csv                inventaire de ce qui precede
#
# Usage :
#   source("pedagogie/_commons/data/J03_extraits/00_extraire_J03.R")
#
# Dependances :
#   install.packages(c("sf", "dplyr", "readr", "rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 600)

.deps <- c("sf", "dplyr", "readr", "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J03-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(readr)
})

# Le moteur spherique s2 refuse ce que GEOS accepte : sur DS.geojson,
# 135 geometries sur 200 sont invalides pour s2 et redeviennent valides
# sous GEOS. Meme reglage que dans demo_formateur_J03.qmd.
sf::sf_use_s2(FALSE)

# Resolution de chemins independante du working directory (Rscript depuis
# la racine OU RStudio source() depuis n'importe ou).
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

dir_in_jour <- file.path(.PROJECT_ROOT, "pedagogie",
                         "J03_univers_vectoriel", "datasets")
dir_in_all  <- file.path(.PROJECT_ROOT, "..", "all_data")

dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J03_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# Cherche un fichier d'abord dans le datasets/ du jour, puis dans le
# magasin central all_data/. Echoue bruyamment plutot qu'en silence.
trouver <- function(nom) {
  for (d in c(dir_in_jour, dir_in_all)) {
    p <- file.path(d, nom)
    if (file.exists(p)) return(normalizePath(p))
    # all_data/ peut etre organise en sous-dossiers : on cherche aussi
    # recursivement, mais seulement en dernier recours.
    if (dir.exists(d)) {
      hit <- list.files(d, pattern = paste0("^", gsub("\\.", "\\\\.", nom), "$"),
                        recursive = TRUE, full.names = TRUE)
      if (length(hit) > 0) return(normalizePath(hit[1]))
    }
  }
  stop("[J03-extrait] Fichier introuvable : ", nom,
       "\n  cherche dans : ", dir_in_jour, "\n  et dans : ", dir_in_all)
}

# Poids d'une sortie, en Ko ou Mo selon l'ordre de grandeur.
poids <- function(p) {
  o <- file.size(p)
  if (o >= 1024^2) sprintf("%.1f Mo", o / 1024^2) else sprintf("%.0f Ko", o / 1024)
}

# ----------------------------------------------------------------------
# 0. La tolerance de simplification, et ce qu'elle coute
# ----------------------------------------------------------------------
# st_simplify() retire des sommets tant que la ligne simplifiee reste a
# moins de `dTolerance` de la ligne d'origine (algorithme Douglas-Peucker).
#
# On simplifie EN METRES, pas en degres : on reprojette d'abord en UTM
# zone 32N (EPSG:32632), on simplifie, on revient en WGS84 (EPSG:4326).
# Simplifier directement sur des degres donnerait une tolerance dont la
# valeur au sol varie avec la latitude -- exactement l'erreur que le J03
# enseigne a ne pas commettre.
#
# CE QUE LA SIMPLIFICATION COUTE :
#   - les frontieres perdent leurs details fins : une limite de district
#     qui suit un meandre de riviere devient une ligne brisee ;
#   - les surfaces changent legerement (le script imprime l'ecart) ;
#   - deux polygones voisins peuvent se decoller ou se chevaucher de
#     quelques dizaines de metres. preserveTopology = TRUE limite le
#     phenomene sans le supprimer.
#   - CONSEQUENCE PEDAGOGIQUE : ces couches servent a APPRENDRE les
#     operations vectorielles, pas a produire un chiffre de superficie
#     publiable. Les superficies exactes se calculent sur les couches
#     d'origine, dans le dossier-jour, sous RStudio.
TOL_DISTRICTS_M <- 500     # districts sanitaires : ~500 m
TOL_PAYS_M      <- 2000    # pays limitrophes (tres grands) : ~2 km

# ----------------------------------------------------------------------
# 1. Districts sanitaires (DS.geojson) -> ds_sante_cmr.geojson
# ----------------------------------------------------------------------
message("[J03-extrait] 1/6 Districts sanitaires...")
f_ds <- trouver("DS.geojson")
ds_brut <- st_read(f_ds, quiet = TRUE)

cat(sprintf("  source   : %s (%s)\n", basename(f_ds), poids(f_ds)))
cat(sprintf("  entites  : %d | champs : %d\n", nrow(ds_brut), ncol(ds_brut) - 1))
cat("  colonnes : ", paste(setdiff(names(ds_brut), "geometry"), collapse = ", "), "\n")
cat(sprintf("  geometries invalides AVANT reparation : %d sur %d\n",
            sum(!st_is_valid(ds_brut)), nrow(ds_brut)))

# Reparation, puis renommage. Export DHIS2 : le nom du district est dans
# 'name' prefixe par "District ", la region dans 'parentName' prefixee par
# "Region ". Aucune colonne ne s'appelle 'region' dans le fichier source.
ds <- ds_brut |>
  st_make_valid() |>
  mutate(district = sub("^District\\s+", "", name),
         region   = sub("^Region\\s+",   "", parentName)) |>
  select(district, region)

cat(sprintf("  geometries invalides APRES st_make_valid() : %d\n",
            sum(!st_is_valid(ds))))

surf_avant <- sum(as.numeric(st_area(st_transform(ds, 32632)))) / 1e6

ds_simpl <- ds |>
  st_transform(32632) |>
  st_simplify(dTolerance = TOL_DISTRICTS_M, preserveTopology = TRUE) |>
  st_make_valid() |>          # la simplification peut recreer des invalides
  st_transform(4326)

surf_apres <- sum(as.numeric(st_area(st_transform(ds_simpl, 32632)))) / 1e6

out_ds <- file.path(dir_out, "ds_sante_cmr.geojson")
st_write(ds_simpl, out_ds, delete_dsn = TRUE, quiet = TRUE)

cat(sprintf("  -> %s : %d districts, %d regions, %s\n",
            basename(out_ds), nrow(ds_simpl), n_distinct(ds_simpl$region),
            poids(out_ds)))
cat(sprintf("  cout de la simplification (%.0f m) : superficie totale %.0f -> %.0f km2 (%+.2f %%)\n",
            TOL_DISTRICTS_M, surf_avant, surf_apres,
            100 * (surf_apres - surf_avant) / surf_avant))

# ----------------------------------------------------------------------
# 2. Grappes EDS geolocalisees (CMGE71FL.shp) -> GeoJSON
# ----------------------------------------------------------------------
message("[J03-extrait] 2/6 Grappes EDS...")
f_gps <- trouver("CMGE71FL.shp")
gps <- st_read(f_gps, quiet = TRUE)

cat("  colonnes disponibles : ",
    paste(setdiff(names(gps), attr(gps, "sf_column")), collapse = ", "), "\n")

# On ne garde que les colonnes utiles au J03. intersect() protege du cas
# ou une colonne manquerait dans une autre livraison DHS : on prend ce
# qui existe reellement, plutot que de planter sur un nom suppose.
vars_gps <- c("DHSID", "DHSCC", "DHSYEAR", "DHSCLUST",
              "URBAN_RURA", "LATNUM", "LONGNUM", "ALT_GPS", "ADM1NAME")
manquantes <- setdiff(vars_gps, names(gps))
if (length(manquantes)) {
  warning("[J03-extrait] Colonnes GPS absentes : ",
          paste(manquantes, collapse = ", "))
}
gps_extrait <- gps |>
  select(all_of(intersect(vars_gps, names(gps)))) |>
  st_transform(4326)

out_gps <- file.path(dir_out, "dhs_grappes_cmr2018.geojson")
st_write(gps_extrait, out_gps, delete_dsn = TRUE, quiet = TRUE)

cat(sprintf("  -> %s : %d grappes, %s\n",
            basename(out_gps), nrow(gps_extrait), poids(out_gps)))
if ("URBAN_RURA" %in% names(gps_extrait)) {
  cat("  repartition urbain / rural :\n")
  print(table(gps_extrait$URBAN_RURA, useNA = "ifany"))
}
# Les coordonnees EDS sont volontairement DEPLACEES (2 km en urbain,
# 5 km en rural, 10 km pour 1 % des grappes rurales) pour proteger
# l'anonymat des enquetes. Une grappe peut donc tomber en mer ou hors
# de tout polygone : c'est attendu, ce n'est pas une erreur de donnee.

# ----------------------------------------------------------------------
# 3. Pays limitrophes -> GeoJSON simplifie
# ----------------------------------------------------------------------
message("[J03-extrait] 3/6 Pays limitrophes...")
f_pays <- trouver("Pays_limitrophes_Cmr.shp")
pays_brut <- st_read(f_pays, quiet = TRUE)

cat(sprintf("  entites lues : %d\n", nrow(pays_brut)))
cat("  colonnes : ",
    paste(setdiff(names(pays_brut), attr(pays_brut, "sf_column")), collapse = ", "), "\n")

# Ce shapefile contient des entites sans nom de pays (attribut vide).
# Elles n'ont rien a etiqueter : on les ecarte a la lecture, sinon chaque
# carte du runtime afficherait "Removed n rows containing missing values".
if (!"COUNTRY" %in% names(pays_brut)) {
  stop("[J03-extrait] La colonne COUNTRY est absente de ",
       basename(f_pays), " : verifier la livraison.")
}
cat(sprintf("  sans nom de pays (ecartees) : %d\n",
            sum(is.na(pays_brut$COUNTRY) | pays_brut$COUNTRY == "")))

pays <- pays_brut |>
  filter(!is.na(COUNTRY), COUNTRY != "") |>
  select(COUNTRY) |>
  st_make_valid() |>
  st_transform(32632) |>
  st_simplify(dTolerance = TOL_PAYS_M, preserveTopology = TRUE) |>
  st_make_valid() |>
  st_transform(4326)

out_pays <- file.path(dir_out, "pays_limitrophes_cmr.geojson")
st_write(pays, out_pays, delete_dsn = TRUE, quiet = TRUE)

cat(sprintf("  -> %s : %d entites, %s (tolerance %.0f m)\n",
            basename(out_pays), nrow(pays), poids(out_pays), TOL_PAYS_M))
cat("  pays conserves : ", paste(sort(unique(pays$COUNTRY)), collapse = ", "), "\n")

# ----------------------------------------------------------------------
# 4. CSV WorldPop -> copie VERBATIM (le piege du separateur est pedagogique)
# ----------------------------------------------------------------------
message("[J03-extrait] 4/6 CSV WorldPop...")
# On copie SANS RIEN TOUCHER, et surtout sans reecrire avec write_csv().
# Le J03 enseigne que CMR_population_...csv est separe par des POINTS-
# VIRGULES et CMR_household_...csv par des VIRGULES : reharmoniser les
# deux fichiers ici detruirait la lecon. La difference doit survivre
# jusqu'au navigateur.
for (nom in c("CMR_population_v1_0_admin_level2.csv",
              "CMR_household_v1_0_admin_level2.csv")) {
  src <- trouver(nom)
  dst <- file.path(dir_out, nom)
  file.copy(src, dst, overwrite = TRUE)
  premiere <- readLines(dst, n = 1L, warn = FALSE)
  sep <- if (grepl(";", premiere)) "point-virgule" else "virgule"
  cat(sprintf("  -> %s : %s, %d lignes de donnees, separateur %s\n",
              nom, poids(dst),
              length(readLines(dst, warn = FALSE)) - 1L, sep))
}

# ----------------------------------------------------------------------
# 5. Covariables contextuelles des grappes (CMGC72FL.csv) -> extrait
# ----------------------------------------------------------------------
message("[J03-extrait] 5/6 Covariables contextuelles...")
f_cov <- trouver("CMGC72FL.csv")
cov <- read_csv(f_cov, show_col_types = FALSE)

cat(sprintf("  source : %s (%s) -- %d grappes x %d colonnes\n",
            basename(f_cov), poids(f_cov), nrow(cov), ncol(cov)))
cat("  ce fichier porte-t-il des coordonnees ? ",
    any(grepl("^lat|^lon", names(cov), ignore.case = TRUE)), "\n")
# Reponse attendue : FALSE. La geometrie est dans CMGE71FL.shp ; les deux
# se recollent par DHSCLUST. C'est le cas d'ecole de la jointure
# attributaire enseignee au J03.

# Douze colonnes suffisent au J03 : la cle, quelques covariables
# interpretables, et DEUX CONTRE-EXEMPLES assumes.
vars_cov <- c(
  "DHSCLUST",                    # cle de jointure avec les grappes GPS
  "Aridity_2015",                # indice d'aridite
  "Rainfall_2015",               # pluviometrie annuelle (mm)
  "Malaria_Prevalence_2015",     # prevalence du paludisme
  "Enhanced_Vegetation_Index_2015",
  "Nightlights_Composite",       # lumieres nocturnes : proxy d'urbanisation
  "Travel_Times_2015",           # temps d'acces a une ville (min)
  "Proximity_to_Water",          # distance a l'eau de surface
  "All_Population_Count_2015",   # population dans le voisinage de la grappe
  "Slope",                       # pente moyenne
  # --- contre-exemples : a garder, pas a analyser -----------------------
  # Drought_Episodes et Growing_Season_Length portent tellement de
  # sentinelles negatives (respectivement ~125 et ~214 grappes sur 430)
  # qu'elles sont inexploitables. On les conserve exactement pour cela :
  # le runtime montre comment on s'en apercoit.
  "Drought_Episodes",
  "Growing_Season_Length"
)
manquantes <- setdiff(vars_cov, names(cov))
if (length(manquantes)) {
  warning("[J03-extrait] Covariables absentes : ",
          paste(manquantes, collapse = ", "))
}
cov_extrait <- cov |>
  select(all_of(intersect(vars_cov, names(cov)))) |>
  mutate(DHSCLUST = as.integer(DHSCLUST))

# On N'IMPUTE PAS et on ne recode PAS les sentinelles ici : le recodage
# est un exercice du runtime. On se contente de les compter, pour que le
# contenu de l'extrait produit soit connu avant d'etre servi au navigateur.
cat("  sentinelles (valeurs < 0) par colonne :\n")
for (v in setdiff(names(cov_extrait), "DHSCLUST")) {
  n_neg <- sum(cov_extrait[[v]] < 0, na.rm = TRUE)
  cat(sprintf("    %-32s %3d / %d\n", v, n_neg, nrow(cov_extrait)))
}

out_cov <- file.path(dir_out, "covar_dhs_grappes_extrait.csv")
write_csv(cov_extrait, out_cov)
cat(sprintf("  -> %s : %d grappes x %d colonnes, %s\n",
            basename(out_cov), nrow(cov_extrait), ncol(cov_extrait),
            poids(out_cov)))

# ----------------------------------------------------------------------
# 6. README des extraits
# ----------------------------------------------------------------------
message("[J03-extrait] 6/6 README...")
fichiers <- list.files(dir_out, pattern = "\\.(csv|geojson)$")
fichiers <- setdiff(fichiers, "J03_extraits_README.csv")

readme <- tibble(
  fichier   = fichiers,
  taille_ko = round(file.size(file.path(dir_out, fichiers)) / 1024),
  source    = "pedagogie/J03_univers_vectoriel/datasets/ (ou all_data/)",
  usage     = "Runtime WebR J03 - declare dans webr.resources de runtime.qmd",
  note      = "Couches simplifiees : pour APPRENDRE, pas pour publier un chiffre"
)
out_doc <- file.path(dir_out, "J03_extraits_README.csv")
write_csv(readme, out_doc)

cat("\n========================================================\n")
cat(" Extraction J03 pour WebR terminee.\n")
cat("========================================================\n")
cat(" Fichiers produits dans :\n")
cat("  ", normalizePath(dir_out), "\n\n")
print(as.data.frame(readme))
cat(sprintf("\n Poids total des extraits : %.1f Mo (budget WebR : 100 Mo)\n",
            sum(file.size(file.path(dir_out, fichiers))) / 1024^2))
cat("\n Prochaine etape : quarto render depuis pedagogie/, puis ouvrir\n")
cat(" J03_univers_vectoriel/runtime.html et cliquer Run code partout.\n\n")
