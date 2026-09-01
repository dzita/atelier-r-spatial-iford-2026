# =====================================================================
# 00_extraire_J10.R
# Atelier IFORD x GDSG 2026 — J10 « Politiques publiques »
#
# A QUOI SERT CE SCRIPT
#   Le runtime WebR de la J10 tourne DANS UN NAVIGATEUR. Quatre des cinq
#   paquets structurants de la journee n'y existent pas : terra et ncdf4
#   (pour le NetCDF ERA5), survey (pour le plan de sondage beninois) et sae
#   (pour le modele de Fay-Herriot). Rien de la partie « estimation sur
#   petits domaines » ne peut donc etre calcule dans le navigateur.
#   Ce script fait ici, une fois, TOUS ces calculs, et n'ecrit que des
#   resultats deja estimes : le runtime cartographie, trace et interprete.
#
# QUI DOIT L'EXECUTER
#   VOUS. La session qui a redige ce script n'avait ni R, ni shell, ni acces
#   aux binaires (.nc, .gpkg) : elle n'a VERIFIE AUCUN CHIFFRE.
#
# UN AVERTISSEMENT A NE PAS PERDRE EN ROUTE
#   Cette journee CHANGE DE PAYS en cours de route. Les modules ACLED et
#   ERA5 portent sur le CAMEROUN ; la partie « petits domaines » porte sur
#   le BENIN. Ce choix est assume et documente : l'extrait ECAM5 camerounais
#   n'est pas representatif a l'interieur des regions (l'Est y ressort a
#   7,5 % de pauvrete contre 41,5 % publie par l'INS), et un exercice
#   d'estimation construit dessus produirait des chiffres qu'il faudrait
#   interdire de citer. Le runtime doit le DIRE explicitement.
#
# QUAND LE RELANCER
#   - a la premiere installation ;
#   - si l'export ACLED, le NetCDF ERA5 ou les fichiers beninois changent ;
#   - si l'on modifie le choix des covariables du modele.
#
# ENTREES (pedagogie/J10_politiques_publiques/datasets/)
#   acled_cameroon_export.csv        gadm41_CMR.gpkg
#   era5_t2m_mensuel_cameroun.nc
#   ehcvm2018_benin_menages.csv      gadm_ben_communes.gpkg
#   benin_grille_3km.gpkg            benin_covariables_admin2.csv
#   benin_covariables_grille.csv
#
# SORTIES (pedagogie/_commons/data/J10_extraits/)
#   J10_acled_adm1.geojson           10 regions CMR + comptages
#   J10_acled_annuel_region.csv      region x annee
#   J10_acled_types_annuel.csv       annee x type d'evenement
#   J10_acled_points.geojson         les evenements retenus, 4 colonnes
#   J10_era5_national_mensuel.csv    serie mensuelle nationale, en CELSIUS
#   J10_era5_regional_mensuel.csv    region x mois
#   J10_era5_adm1.geojson            moyenne, min, max, amplitude par region
#   J10_benin_communes_sae.geojson   TOUTES les communes, estimees ou non
#   J10_benin_sae_communes.csv       la meme table, sans geometrie
#   J10_benin_grille_prediction.csv  cellules de 3 km predites
#   J10_extraits_README.csv
#
# CONTRAT DE COLONNES — ne pas renommer sans corriger runtime.qmd.
#
# Usage :
#   source("pedagogie/_commons/data/J10_extraits/00_extraire_J10.R")
#
# Dependances :
#   install.packages(c("sf","terra","exactextractr","survey","sae","dplyr",
#                      "tidyr","readr","stringr","rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 900)

.deps <- c("sf", "terra", "exactextractr", "survey", "sae", "dplyr", "tidyr",
           "readr", "stringr", "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J10-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

# L'ORDRE DE CHARGEMENT N'EST PAS INDIFFERENT. sae depend de MASS, qui
# definit select(). Charge apres dplyr, MASS::select() gagnerait et tout
# appel a select() echouerait sur un message incomprehensible.
suppressPackageStartupMessages({
  library(sae)
  library(survey)
  library(dplyr)
  library(sf); library(terra); library(exactextractr)
  library(tidyr); library(readr); library(stringr)
})
cat("select() fourni par :", environmentName(environment(select)), "\n")

sf_use_s2(FALSE)

.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)
dir_in  <- file.path(.PROJECT_ROOT, "pedagogie", "J10_politiques_publiques",
                     "datasets")
dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J10_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

CRS_MESURE_CMR <- 32633        # UTM 33N — Cameroun
CRS_MESURE_BEN <- 32631        # UTM 31N — Benin
TOL_CMR_M <- 500               # simplification des regions camerounaises
TOL_BEN_M <- 200               # simplification des communes beninoises

# Ce que coute la simplification : tout detail de contour plus fin que la
# tolerance disparait. 200 m sur des communes beninoises (quelques dizaines
# de km de large) reste invisible a l'ecran ; en dessous de 50 m on stocke
# du bruit de numerisation. AUCUNE SURFACE N'EST MESUREE APRES simplification.

GEOJSON_OPTS <- c("COORDINATE_PRECISION=5", "RFC7946=YES")
`%||%` <- function(a, b) if (is.null(a)) b else a
poids_ko <- function(p) round(file.size(p) / 1024)
ecrire_geojson <- function(o, n) {
  p <- file.path(dir_out, n)
  st_write(o, p, delete_dsn = TRUE, quiet = TRUE, layer_options = GEOJSON_OPTS)
  cat(sprintf("  -> %-36s %7d Ko  %6d entites  %2d colonnes\n",
              n, poids_ko(p), nrow(o), ncol(o) - 1L))
}
ecrire_csv <- function(o, n) {
  p <- file.path(dir_out, n)
  write_csv(o, p)
  cat(sprintf("  -> %-36s %7d Ko  %6d lignes   %2d colonnes\n",
              n, poids_ko(p), nrow(o), ncol(o)))
}

cat("\n=====================================================\n")
cat(" J10 — extraction des donnees lourdes pour le runtime\n")
cat("=====================================================\n")
cat("Entrees : ", dir_in, "\nSorties : ", dir_out, "\n\n")

fichiers <- c("acled_cameroon_export.csv", "gadm41_CMR.gpkg",
              "era5_t2m_mensuel_cameroun.nc", "ehcvm2018_benin_menages.csv",
              "gadm_ben_communes.gpkg", "benin_grille_3km.gpkg",
              "benin_covariables_admin2.csv", "benin_covariables_grille.csv")
cat("--- Inventaire ---\n")
for (f in fichiers) {
  p <- file.path(dir_in, f)
  cat(sprintf("  %-34s %s\n", f,
              if (file.exists(p)) sprintf("OK (%d Ko)", poids_ko(p)) else "ABSENT"))
}

# =====================================================================
# PARTIE I — CAMEROUN : ACLED
# =====================================================================
cat("\n=== PARTIE I — ACLED (Cameroun) ===\n")

acled <- read_csv(file.path(dir_in, "acled_cameroon_export.csv"),
                  show_col_types = FALSE)
cat("Lignes lues :", nrow(acled), "| colonnes :", ncol(acled), "\n")
# CONTROLE DU SEPARATEUR : un mauvais separateur renvoie UNE colonne unique,
# sans lever la moindre erreur.
stopifnot(ncol(acled) > 5)
cat("Annees couvertes :", paste(range(acled$year, na.rm = TRUE), collapse = " - "),
    "\n")

# CONTROLE DES SENTINELLES, AVANT tout calcul.
n0 <- nrow(acled)
cat("Evenements a (0, 0) — le point « null island » :",
    sum(acled$latitude == 0 & acled$longitude == 0, na.rm = TRUE), "\n")
cat("Fatalities negatives :", sum(acled$fatalities < 0, na.rm = TRUE), "\n")
cat("Coordonnees hors de l'emprise du Cameroun (1,6-13,1 N / 8,4-16,2 E) :",
    sum(!(acled$latitude  > 1.5  & acled$latitude  < 13.2 &
          acled$longitude > 8.3  & acled$longitude < 16.3), na.rm = TRUE), "\n")

acled_net <- acled |>
  filter(!is.na(latitude), !is.na(longitude),
         !(latitude == 0 & longitude == 0),
         latitude  > 1.5, latitude  < 13.2,
         longitude > 8.3, longitude < 16.3,
         !is.na(fatalities), fatalities >= 0)
cat("Lignes retirees :", n0 - nrow(acled_net), "sur", n0, "\n")

# Champ temporel borne sur la DERNIERE annee du fichier, pas sur Sys.Date() :
# le materiel doit donner la meme sortie en 2026 et en 2030.
an_max <- max(acled_net$year, na.rm = TRUE)
an_min <- an_max - 9
acled_net <- acled_net |> filter(year >= an_min, year <= an_max)
cat("Champ retenu :", an_min, "-", an_max, "|", nrow(acled_net), "evenements\n")

# ORDRE DES COORDONNEES : c(longitude, latitude), et JAMAIS l'inverse.
acled_sf <- st_as_sf(acled_net, coords = c("longitude", "latitude"),
                     crs = 4326, remove = FALSE)

gpkg_cmr <- file.path(dir_in, "gadm41_CMR.gpkg")
couches <- st_layers(gpkg_cmr)$name
cat("Couches GADM CMR :", paste(couches, collapse = ", "), "\n")
cmr1 <- st_read(gpkg_cmr, layer = grep("ADM_?1$", couches, value = TRUE)[1],
                quiet = TRUE) |> st_make_valid()

# JOINTURE SPATIALE, jamais par libelle : les admin1 d'ACLED sont en
# francais non accentue, les NAME_1 de GADM en anglais. On le CHIFFRE avant
# de passer a la position.
apparies <- sum(unique(acled_net$admin1) %in% cmr1$NAME_1)
cat("Libelles admin1 d'ACLED trouves tels quels dans NAME_1 :", apparies,
    "sur", length(unique(acled_net$admin1)), "\n")

n_av <- nrow(acled_sf)
acled_j <- st_join(acled_sf, cmr1 |> select(NAME_1), join = st_within)
cat("Lignes avant / apres st_join :", n_av, "/", nrow(acled_j),
    "(duplications :", nrow(acled_j) - n_av, ")\n")
cat("Evenements hors de toute region (frontiere, mer) :",
    sum(is.na(acled_j$NAME_1)), "\n")

# Agregations. Apres jointure SPATIALE, une region absente est une region
# sans evenement rapporte : le zero est ici une MESURE.
par_region <- acled_j |>
  st_drop_geometry() |>
  filter(!is.na(NAME_1)) |>
  group_by(NAME_1) |>
  summarise(n_evenements = n(),
            n_deces      = sum(fatalities, na.rm = TRUE),
            .groups = "drop")

acled_adm1 <- cmr1 |>
  select(GID_1, NAME_1) |>
  left_join(par_region, by = "NAME_1") |>
  mutate(n_evenements = tidyr::replace_na(n_evenements, 0L),
         n_deces      = tidyr::replace_na(n_deces, 0L),
         deces_par_evenement = round(n_deces / pmax(n_evenements, 1), 2),
         annee_min = an_min, annee_max = an_max)
cat("Regions a zero evenement (mesure, pas trou) :",
    sum(acled_adm1$n_evenements == 0), "\n")

annuel_region <- acled_j |>
  st_drop_geometry() |> filter(!is.na(NAME_1)) |>
  group_by(NAME_1, annee = year) |>
  summarise(n_evenements = n(), n_deces = sum(fatalities, na.rm = TRUE),
            .groups = "drop")

types_annuel <- acled_net |>
  group_by(annee = year, event_type) |>
  summarise(n_evenements = n(), n_deces = sum(fatalities, na.rm = TRUE),
            .groups = "drop")
cat("Types d'evenements distincts :", length(unique(types_annuel$event_type)),
    "\n")

points_out <- acled_j |>
  transmute(annee = year, event_type, fatalities,
            NAME_1 = NAME_1, admin1_acled = admin1)
cat("Points exportes :", nrow(points_out), "\n")

# =====================================================================
# PARTIE II — CAMEROUN : ERA5
# =====================================================================
cat("\n=== PARTIE II — ERA5 (Cameroun) ===\n")
era <- rast(file.path(dir_in, "era5_t2m_mensuel_cameroun.nc"))
cat("Couches (= mois) :", nlyr(era), "| res :",
    paste(round(res(era), 4), collapse = " x "), "degre\n")
cat("Cellules par couche :", ncell(era), "\n")
dates_era <- terra::time(era)
cat("Dates portees par le fichier :",
    if (all(is.na(dates_era))) "AUCUNE — a reconstruire" else
      paste(range(as.Date(dates_era)), collapse = " -> "), "\n")
if (all(is.na(dates_era))) {
  # Repli : on reconstruit une sequence mensuelle. A VALIDER AU PREMIER
  # RENDU — si le fichier ne commence pas en janvier, ce repli est faux.
  dates_era <- seq(as.Date("2015-01-01"), by = "month", length.out = nlyr(era))
  cat("ATTENTION : dates reconstruites par defaut a partir de 2015-01.\n")
}

# CONTROLE D'UNITE : l'ordre de grandeur trahit le Kelvin.
moy_brute <- as.numeric(global(era[[1]], "mean", na.rm = TRUE)[[1]])
cat("Moyenne de la premiere couche :", round(moy_brute, 1),
    if (moy_brute > 200) " -> KELVIN" else " -> deja en Celsius", "\n")
era_c <- if (moy_brute > 200) era - 273.15 else era     # la ligne a ne pas oublier

cmr0 <- st_read(gpkg_cmr, layer = grep("ADM_?0$", couches, value = TRUE)[1],
                quiet = TRUE) |> st_make_valid()
v0 <- vect(st_transform(cmr0, crs(era_c)))
era_cmr <- mask(crop(era_c, v0), v0)
cat("Cellules non vides apres decoupe :",
    sum(!is.na(values(era_cmr[[1]]))), "sur", ncell(era_cmr), "\n")

# Serie NATIONALE : moyenne ponderee par la fraction de cellule couverte.
nat <- exact_extract(era_cmr, st_transform(cmr0, crs(era_cmr)), "mean",
                     progress = FALSE)
era_national <- tibble::tibble(
  date  = as.Date(dates_era),
  annee = as.integer(format(as.Date(dates_era), "%Y")),
  mois  = as.integer(format(as.Date(dates_era), "%m")),
  t2m_c = round(as.numeric(nat[1, ]), 3)
)
cat("Serie nationale :", nrow(era_national), "mois |",
    "min", round(min(era_national$t2m_c, na.rm = TRUE), 1),
    "| max", round(max(era_national$t2m_c, na.rm = TRUE), 1), "degres C\n")

# Serie REGIONALE. PIEGE : exact_extract nomme ses colonnes d'apres les
# couches ("mean.t2m_1", "mean.t2m_10"...) et l'ordre ALPHABETIQUE de ces
# noms n'est PAS l'ordre chronologique. On retrouve l'indice par match().
reg <- exact_extract(era_cmr, st_transform(cmr1, crs(era_cmr)), "mean",
                     progress = FALSE)
idx <- match(sub("^mean\\.", "", names(reg)), names(era_cmr))
cat("Couches retrouvees par match() :", sum(!is.na(idx)), "/", ncol(reg), "\n")
era_regional <- as.data.frame(reg) |>
  mutate(NAME_1 = cmr1$NAME_1) |>
  pivot_longer(-NAME_1, names_to = "colonne", values_to = "t2m_c") |>
  mutate(i     = match(sub("^mean\\.", "", colonne), names(era_cmr)),
         date  = as.Date(dates_era)[i],
         annee = as.integer(format(date, "%Y")),
         mois  = as.integer(format(date, "%m")),
         t2m_c = round(t2m_c, 3)) |>
  select(NAME_1, date, annee, mois, t2m_c) |>
  arrange(NAME_1, date)
cat("Serie regionale :", nrow(era_regional), "lignes |",
    "regions sans aucune valeur :",
    sum(tapply(era_regional$t2m_c, era_regional$NAME_1,
               function(x) all(is.na(x)))), "\n")

era_adm1 <- cmr1 |>
  select(GID_1, NAME_1) |>
  left_join(
    era_regional |>
      group_by(NAME_1) |>
      summarise(t2m_moyen_c = round(mean(t2m_c, na.rm = TRUE), 2),
                t2m_min_c   = round(min(t2m_c,  na.rm = TRUE), 2),
                t2m_max_c   = round(max(t2m_c,  na.rm = TRUE), 2),
                .groups = "drop") |>
      mutate(amplitude_c = round(t2m_max_c - t2m_min_c, 2)),
    by = "NAME_1")

# =====================================================================
# PARTIE III — BENIN : plan de sondage, estimation directe, Fay-Herriot
# =====================================================================
cat("\n=== PARTIE III — BENIN (petits domaines) ===\n")
cat("Rappel : cette partie porte sur le BENIN, pas sur le Cameroun.\n")

men <- read_csv(file.path(dir_in, "ehcvm2018_benin_menages.csv"),
                show_col_types = FALSE)
cat("Menages :", nrow(men), "| colonnes :", paste(names(men), collapse = ", "),
    "\n")
cat("insecure : modalites", paste(sort(unique(men$insecure)), collapse = " / "),
    "| NA :", sum(is.na(men$insecure)), "\n")
cat("hhweight : min", round(min(men$hhweight), 2),
    "| max", round(max(men$hhweight), 2),
    "| somme", round(sum(men$hhweight)), "\n")
cat("Grappes distinctes :", length(unique(men$grappe)), "\n")

cov_grille <- read_csv(file.path(dir_in, "benin_covariables_grille.csv"),
                       show_col_types = FALSE)
cov_adm2   <- read_csv(file.path(dir_in, "benin_covariables_admin2.csv"),
                       show_col_types = FALSE)
cat("Covariables grille :", nrow(cov_grille), "cellules |",
    "communes :", nrow(cov_adm2), "\n")

# Le fichier menages ne porte PAS admin2Pcod : c'est la table de covariables
# de grille qui fait le pont id -> admin2Pcod.
men <- men |> left_join(cov_grille |> select(id, admin2Pcod), by = "id")
cat("Menages sans commune apres jointure id -> admin2Pcod :",
    sum(is.na(men$admin2Pcod)), "sur", nrow(men), "\n")
men <- men |> filter(!is.na(admin2Pcod), !is.na(insecure))

# PLAN DE SONDAGE. ids = grappe (unite primaire), weights = hhweight.
# Aucune strate n'est declaree, faute d'identifiant de strate : l'erreur-type
# obtenue est donc legerement CONSERVATRICE.
design <- svydesign(ids = ~grappe, weights = ~hhweight, data = men)

moy_brute_ins  <- 100 * mean(men$insecure)
moy_ponderee   <- 100 * as.numeric(svymean(~insecure, design)[1])
cat("Moyenne BRUTE d'insecure (%)    :", round(moy_brute_ins, 1), "\n")
cat("Moyenne PONDEREE d'insecure (%) :", round(moy_ponderee, 1), "\n")
cat("Ecart (points)                  :",
    round(moy_ponderee - moy_brute_ins, 2), "\n")

# Estimation DIRECTE par commune, dans le respect du plan.
direct <- svyby(~insecure, ~admin2Pcod, design, svymean, na.rm = TRUE)
direct <- tibble::tibble(
  admin2Pcod      = as.character(direct$admin2Pcod),
  insecure_direct = 100 * direct$insecure,
  se_direct       = 100 * direct$se
)

tailles <- men |>
  group_by(admin2Pcod) |>
  summarise(n_menages = n(), n_grappes = n_distinct(grappe), .groups = "drop")
direct <- direct |> left_join(tailles, by = "admin2Pcod")
cat("Communes enquetees :", nrow(direct), "\n")
cat("Menages par commune — min", min(direct$n_menages),
    "| mediane", median(direct$n_menages), "| max", max(direct$n_menages), "\n")

# LE MOMENT DE METHODE : une commune a UNE SEULE GRAPPE n'a pas de variance
# estimable (la variance s'estime ENTRE grappes). Elle est exclue du modele,
# seuil declare, et MEMORISEE pour rester grise sur les cartes.
exclues <- direct |> filter(n_grappes <= 1 | is.na(se_direct) | se_direct <= 0)
sae_in  <- direct |> filter(n_grappes > 1, !is.na(se_direct), se_direct > 0)
cat("Communes exclues (une seule grappe ou variance nulle) :", nrow(exclues),
    "\n")
cat("Communes retenues pour le modele :", nrow(sae_in), "\n")

sae_in <- sae_in |>
  left_join(cov_adm2, by = "admin2Pcod") |>
  mutate(var_direct = se_direct^2)

# CRIBLAGE DES COVARIABLES : correlation avec l'estimation directe, puis
# colinearite entre candidates. Le criblage est IMPRIME, pas suppose.
candidates <- intersect(
  c("ntl_mean_adm2", "population_adm2", "ndvi_mean_adm2", "precip_2018_adm2",
    "no2_adm2", "lc_13_urbain_adm2", "lc_12_cultures_adm2",
    "lc_8_savane_boisee_adm2", "lc_11_zones_humides_adm2"),
  names(sae_in))
correl <- vapply(candidates, function(v)
  suppressWarnings(cor(sae_in[[v]], sae_in$insecure_direct,
                       use = "complete.obs")), numeric(1))
cat("\nCorrelation de chaque covariable avec l'estimation directe :\n")
print(round(sort(correl, decreasing = TRUE), 3))
cat("NA par covariable :\n")
print(vapply(sae_in[candidates], function(x) sum(is.na(x)), integer(1)))

# DECISION EXPLICITE, alignee sur le demo_formateur : part de sol urbain et
# part de savane boisee. Les deux existent aussi dans le fichier de grille,
# SANS le suffixe _adm2 — c'est le piege du module 9.
cov_retenues <- intersect(c("lc_13_urbain_adm2", "lc_8_savane_boisee_adm2"),
                          names(sae_in))
cat("Covariables retenues :", paste(cov_retenues, collapse = " + "), "\n")
if (length(cov_retenues) == 2) {
  cat("Correlation entre les deux retenues :",
      round(cor(sae_in[[cov_retenues[1]]], sae_in[[cov_retenues[2]]],
                use = "complete.obs"), 3), "\n")
}

sae_in <- sae_in |> filter(if_all(all_of(cov_retenues), ~ !is.na(.x)))
form <- as.formula(paste("insecure_direct ~", paste(cov_retenues,
                                                    collapse = " + ")))

# FAY-HERRIOT. Ce qui distingue ce modele d'une simple regression : vardir,
# la variance d'echantillonnage CONNUE de chaque commune.
fh <- mseFH(form, vardir = sae_in$var_direct, data = as.data.frame(sae_in))
cat("\nCoefficients du modele :\n")
print(round(fh$est$fit$estcoef, 4))
cat("Variance de l'effet aleatoire de commune :",
    round(fh$est$fit$refvar, 4), "\n")
cat("Convergence :", fh$est$fit$convergence, "\n")

sae_out <- sae_in |>
  mutate(insecure_fh = as.numeric(fh$est$eblup[, 1]),
         rmse_direct = sqrt(var_direct),
         rmse_fh     = sqrt(fh$mse),
         gain_rmse   = rmse_direct - rmse_fh,
         gain_pct    = 100 * gain_rmse / rmse_direct,
         deplacement = insecure_fh - insecure_direct)
cat("Gain de RMSE (points) — moyen :", round(mean(sae_out$gain_rmse), 3),
    "| median :", round(median(sae_out$gain_rmse), 3),
    "| negatif dans", sum(sae_out$gain_rmse < 0), "communes\n")

# Le test du mecanisme, en chiffres : le gain doit etre le plus fort la ou
# l'echantillon est le plus petit. Le tableau par tiers fait foi.
tiers <- sae_out |>
  mutate(tiers_n = ntile(n_menages, 3)) |>
  group_by(tiers_n) |>
  summarise(n_communes = n(),
            menages_median = median(n_menages),
            gain_rmse_moyen = round(mean(gain_rmse), 3),
            gain_pct_moyen  = round(mean(gain_pct), 1), .groups = "drop")
cat("\nGain par tiers de taille d'echantillon :\n"); print(tiers)

# --- Communes : on part de la COUCHE, personne ne disparait ------------
gpkg_ben <- file.path(dir_in, "gadm_ben_communes.gpkg")
couches_ben <- st_layers(gpkg_ben)$name
cat("\nCouches GADM Benin :", paste(couches_ben, collapse = ", "), "\n")
communes <- st_read(gpkg_ben, layer = couches_ben[1], quiet = TRUE) |>
  st_make_valid()
cat("Communes :", nrow(communes), "| cle admin2Pcod unique :",
    !anyDuplicated(communes$admin2Pcod), "\n")

communes_sae <- communes |>
  select(admin2Pcod, adm2_name = any_of(c("adm2_name", "NAME_2"))) |>
  left_join(sae_out |>
              select(admin2Pcod, n_menages, n_grappes, insecure_direct,
                     rmse_direct, insecure_fh, rmse_fh, gain_rmse, gain_pct,
                     deplacement, all_of(cov_retenues)),
            by = "admin2Pcod") |>
  left_join(exclues |> select(admin2Pcod) |> mutate(.exclue = TRUE),
            by = "admin2Pcod") |>
  mutate(statut = case_when(
    !is.na(insecure_fh)     ~ "Estimee (direct + Fay-Herriot)",
    isTRUE(.exclue)         ~ "Une seule grappe — variance non estimable",
    TRUE                    ~ "Non enquetee"),
    .exclue = NULL)
cat("Statuts des communes :\n"); print(table(communes_sae$statut))
cat("REGLE §4.4 : les communes des deux derniers statuts restent GRISES sur\n")
cat("les cartes du runtime — elles ne sont ni a zero, ni effacees.\n")

# --- Prediction sur la grille de 3 km ---------------------------------
cat("\n--- Prediction fine (grille de 3 km) ---\n")
beta <- as.numeric(fh$est$fit$estcoef[, 1])
noms_beta <- rownames(fh$est$fit$estcoef)
cat("Coefficients :", paste(noms_beta, round(beta, 4), collapse = " | "), "\n")

# Effet aleatoire de commune, reconstruit par difference :
#   u_hat = EBLUP - partie expliquee par les covariables.
# Il est CONSTANT dans la commune : toute la variation visible sur la carte
# de grille vient donc des COVARIABLES, et d'elles seules.
X_adm2 <- cbind(1, as.matrix(sae_out[, cov_retenues]))
sae_out$u_hat <- sae_out$insecure_fh - as.numeric(X_adm2 %*% beta)
cat("u_hat — ecart-type :", round(sd(sae_out$u_hat), 3), "\n")

# PIEGE DE NOMMAGE : les colonnes de la grille n'ont PAS le suffixe _adm2.
cov_grille_noms <- sub("_adm2$", "", cov_retenues)
cat("Covariables cote grille :", paste(cov_grille_noms, collapse = " + "), "\n")
manquantes <- setdiff(cov_grille_noms, names(cov_grille))
if (length(manquantes)) stop("Covariables absentes du fichier de grille : ",
                             paste(manquantes, collapse = ", "))

grille_3km <- st_read(file.path(dir_in, "benin_grille_3km.gpkg"),
                      layer = st_layers(file.path(dir_in,
                                                  "benin_grille_3km.gpkg"))$name[1],
                      quiet = TRUE) |> st_make_valid()
cat("Cellules de grille :", nrow(grille_3km), "\n")
centro <- st_coordinates(st_centroid(st_transform(grille_3km, 4326)))

pred <- cov_grille |>
  left_join(sae_out |> select(admin2Pcod, u_hat), by = "admin2Pcod") |>
  mutate(partie_fixe = beta[1] +
           beta[2] * .data[[cov_grille_noms[1]]] +
           (if (length(cov_grille_noms) > 1)
              beta[3] * .data[[cov_grille_noms[2]]] else 0),
         pred_insecure = partie_fixe + u_hat)
cat("Cellules sans u_hat (commune non modelisee) :",
    sum(is.na(pred$u_hat)), "sur", nrow(pred), "\n")

pred <- pred |>
  left_join(tibble::tibble(id = grille_3km$id,
                           x = round(centro[, 1], 5),
                           y = round(centro[, 2], 5)), by = "id")
cat("Cellules sans coordonnees apres jointure id :", sum(is.na(pred$x)), "\n")

# CONTROLE : une proportion predite peut sortir de [0, 100]. Le modele est
# lineaire, rien ne l'en empeche. On COMPTE, on ne tronque pas en silence.
hors <- sum(pred$pred_insecure < 0 | pred$pred_insecure > 100, na.rm = TRUE)
cat("Cellules predites hors de [0, 100] :", hors, "sur",
    sum(!is.na(pred$pred_insecure)), "\n")

grille_out <- pred |>
  transmute(id, admin2Pcod, x, y,
            pred_insecure = round(pred_insecure, 2),
            hors_bornes   = !is.na(pred_insecure) &
              (pred_insecure < 0 | pred_insecure > 100),
            u_hat = round(u_hat, 3)) |>
  filter(!is.na(x), !is.na(y))

# =====================================================================
# ECRITURE
# =====================================================================
cat("\n--- Ecriture des sorties ---\n")
simp <- function(x, crs_m, tol) {
  x |> st_transform(crs_m) |>
    st_simplify(dTolerance = tol, preserveTopology = TRUE) |>
    st_transform(4326) |> st_make_valid()
}
ecrire_geojson(simp(acled_adm1, CRS_MESURE_CMR, TOL_CMR_M),
               "J10_acled_adm1.geojson")
ecrire_geojson(simp(era_adm1, CRS_MESURE_CMR, TOL_CMR_M),
               "J10_era5_adm1.geojson")
ecrire_geojson(st_transform(points_out, 4326), "J10_acled_points.geojson")
ecrire_geojson(simp(communes_sae, CRS_MESURE_BEN, TOL_BEN_M),
               "J10_benin_communes_sae.geojson")

ecrire_csv(annuel_region, "J10_acled_annuel_region.csv")
ecrire_csv(types_annuel,  "J10_acled_types_annuel.csv")
ecrire_csv(era_national,  "J10_era5_national_mensuel.csv")
ecrire_csv(era_regional,  "J10_era5_regional_mensuel.csv")
ecrire_csv(communes_sae |> st_drop_geometry(), "J10_benin_sae_communes.csv")
ecrire_csv(grille_out,    "J10_benin_grille_prediction.csv")

readme <- tibble::tibble(
  fichier = c("J10_acled_adm1.geojson", "J10_acled_annuel_region.csv",
              "J10_acled_types_annuel.csv", "J10_acled_points.geojson",
              "J10_era5_national_mensuel.csv", "J10_era5_regional_mensuel.csv",
              "J10_era5_adm1.geojson", "J10_benin_communes_sae.geojson",
              "J10_benin_sae_communes.csv", "J10_benin_grille_prediction.csv"),
  pays = c(rep("Cameroun", 7), rep("Benin", 3)),
  unite_observation = c("region ADM1", "region x annee", "annee x type",
                        "evenement", "mois", "region x mois", "region ADM1",
                        "commune", "commune", "cellule de 3 km"),
  produit_par  = "pedagogie/_commons/data/J10_extraits/00_extraire_J10.R",
  consomme_par = "pedagogie/J10_politiques_publiques/runtime.qmd"
)
ecrire_csv(readme, "J10_extraits_README.csv")

cat("\n=====================================================\n")
cat(" Extraction J10 terminee. Poids total :",
    round(sum(file.size(list.files(dir_out, full.names = TRUE,
                                   pattern = "\\.(csv|geojson)$"))) / 1024),
    "Ko\n")
cat(" Rappel : la partie petits domaines porte sur le BENIN.\n")
cat("=====================================================\n")
