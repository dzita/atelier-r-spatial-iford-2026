# =====================================================================
# 00_extraire_J11.R
# Atelier IFORD x GDSG 2026 — J11 « Perenniser et transmettre »
#
# A QUOI SERT CE SCRIPT
#   La J11 est une journee de METHODE : reproductibilite, projets, chemins
#   relatifs, documentation, FAIR. Elle est donc la journee la plus a l'aise
#   en WebR — presque tout son contenu est du R pur, executable dans le
#   navigateur.
#   Il reste une exception : le materiel du jour illustre ses principes sur
#   ECAM5, un fichier Stata (.dta). haven n'existe pas en WebR, et un
#   fichier d'enquete complet n'a de toute facon rien a faire dans un
#   navigateur. Ce script produit donc UN SEUL agregat regional, aux
#   colonnes fixes, plus le fond de carte simplifie et la table de
#   correspondance qui sert d'exemple de jointure documentee.
#
# QUI DOIT L'EXECUTER
#   VOUS. La session qui a redige ce script n'avait ni R, ni shell, ni acces
#   au .dta : elle n'a VERIFIE AUCUN NOM DE COLONNE au-dela de ce que
#   documente REGLES_MATERIEL_ATELIER.md (§7). Le script est donc ecrit
#   DEFENSIVEMENT : il cherche ses colonnes parmi des candidates, imprime ce
#   qu'il a trouve, et s'arrete proprement s'il ne trouve pas.
#   Les marques « a valider au premier rendu » signalent chaque hypothese.
#
# QUAND LE RELANCER
#   - a la premiere installation ;
#   - si ecam5.dta ou gadm41_CMR_1.shp changent ;
#   - jamais autrement.
#
# ENTREES (pedagogie/J11_perenniser_transmettre/datasets/)
#   ecam5.dta              9 472 individus, 2 065 menages, 70 colonnes
#   gadm41_CMR_1.shp       (+ .shx .dbf .prj .cpg) — 10 regions
#
# SORTIES (pedagogie/_commons/data/J11_extraits/)
#   J11_ecam5_regions.csv           1 ligne par region d'enquete
#   J11_adm1_cmr.geojson            10 regions simplifiees + cle technique
#   J11_correspondance_regions.csv  la table de passage, ecrite a la main
#   J11_extraits_README.csv
#
# CONTRAT DE COLONNES — ne pas renommer sans corriger runtime.qmd.
#
# Usage :
#   source("pedagogie/_commons/data/J11_extraits/00_extraire_J11.R")
#
# Dependances :
#   install.packages(c("haven","sf","dplyr","readr","stringi","stringr",
#                      "rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 600)

.deps <- c("haven", "sf", "dplyr", "readr", "stringi", "stringr", "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J11-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(haven); library(sf); library(dplyr); library(readr)
  library(stringi); library(stringr)
})
sf_use_s2(FALSE)

.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)
dir_in  <- file.path(.PROJECT_ROOT, "pedagogie", "J11_perenniser_transmettre",
                     "datasets")
dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J11_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

CRS_MESURE <- 32633
TOL_M <- 500
# Ce que coute la tolerance de 500 m : les micro-decoupages cotiers et les
# enclaves plus fines que 500 m disparaissent du trace. A l'echelle d'une
# carte nationale affichee dans un navigateur (1 px ~ 1 km), c'est invisible.
# La superficie est MESUREE AVANT simplification : on simplifie pour
# afficher, jamais pour mesurer.

GEOJSON_OPTS <- c("COORDINATE_PRECISION=5", "RFC7946=YES")
poids_ko <- function(p) round(file.size(p) / 1024)
ecrire_csv <- function(o, n) {
  p <- file.path(dir_out, n); write_csv(o, p)
  cat(sprintf("  -> %-34s %6d Ko  %4d lignes  %2d colonnes\n",
              n, poids_ko(p), nrow(o), ncol(o)))
}

# Cle technique de jointure. Les mots de liaison comptent : sans eux, des
# libelles comme « Nord-Ouest » et « Nord Ouest » divergent.
normaliser <- function(x) {
  x |>
    as.character() |>
    stri_trans_general("Latin-ASCII") |>
    tolower() |>
    str_replace_all("[^a-z ]", " ") |>
    str_replace_all("\\b(et|de|du|la|le)\\b", " ") |>
    str_replace_all("\\s+", "")
}

cat("\n=====================================================\n")
cat(" J11 — extraction pour le runtime WebR\n")
cat("=====================================================\n")
cat("Entrees : ", dir_in, "\nSorties : ", dir_out, "\n\n")

for (f in c("ecam5.dta", "gadm41_CMR_1.shp")) {
  p <- file.path(dir_in, f)
  cat(sprintf("  %-24s %s\n", f,
              if (file.exists(p)) sprintf("OK (%d Ko)", poids_ko(p)) else "ABSENT"))
}
if (!file.exists(file.path(dir_in, "ecam5.dta")))
  stop("[J11-extrait] ecam5.dta absent : remplir datasets/ avant de relancer.")

# ---------------------------------------------------------------------
# 1. ECAM5 — trouver les colonnes AVANT de les utiliser
# ---------------------------------------------------------------------
cat("\n--- 1. ECAM5 : reperage des colonnes ---\n")
# On ne lit PAS le fichier entier pour connaitre ses noms : n_max = 0.
noms <- names(read_dta(file.path(dir_in, "ecam5.dta"), n_max = 0))
cat("Colonnes du fichier :", length(noms), "\n")

trouver <- function(candidates, etiquette) {
  v <- intersect(candidates, noms)
  cat(sprintf("  %-16s : %s\n", etiquette,
              if (length(v)) paste(v, collapse = ", ") else "AUCUNE TROUVEE"))
  if (length(v)) v[1] else NA_character_
}
# Candidates documentees dans REGLES_MATERIEL_ATELIER.md §7 et §3.2.
c_region <- trouver(c("s0q1", "region", "hv024"), "region")
c_poids  <- trouver(c("coefextr", "poids", "weight"), "poids")
c_taille <- trouver(c("tailm", "taille_menage", "hhsize"), "taille menage")
c_chef   <- trouver(c("s01q3", "lien_chef"), "lien au chef")
c_milieu <- trouver(c("milieu", "s0q2", "urbain", "strate"), "milieu")

if (any(is.na(c(c_region, c_poids, c_taille)))) {
  cat("\nColonnes disponibles (premieres 70) :\n")
  print(head(noms, 70))
  stop("[J11-extrait] Colonnes essentielles introuvables. Corriger les listes ",
       "de candidates ci-dessus a partir du codebook, puis relancer.")
}

vars <- unique(na.omit(c(c_region, c_poids, c_taille, c_chef, c_milieu)))
ecam <- read_dta(file.path(dir_in, "ecam5.dta"), col_select = all_of(vars))
cat("Lignes lues :", nrow(ecam), "| variables :", ncol(ecam), "\n")

# Les libelles Stata deviennent des facteurs lisibles.
ecam <- ecam |>
  mutate(across(where(\(x) inherits(x, "haven_labelled")),
                ~ haven::as_factor(.x)))

# UNE LIGNE = UN INDIVIDU. Pour decrire des MENAGES, on retient le chef.
# C'est la parade au biais de taille : parcourir des lignes d'individus
# surrepresente mecaniquement les grands menages.
if (!is.na(c_chef)) {
  chefs <- ecam |> filter(as.integer(.data[[c_chef]]) == 1L)
  cat("Chefs de menage identifies :", nrow(chefs), "sur", nrow(ecam),
      "lignes  (repere documente : 2 065 menages)\n")
} else {
  chefs <- ecam
  cat("ATTENTION : aucune variable de lien au chef. Le fichier est traite tel\n")
  cat("quel — les moyennes ci-dessous sont alors des moyennes d'INDIVIDUS.\n")
  cat("A VALIDER AU PREMIER RENDU.\n")
}

# LE BIAIS DE TAILLE, chiffre : la meme grandeur sur deux unites.
taille_individus <- weighted.mean(as.numeric(ecam[[c_taille]]),
                                  as.numeric(ecam[[c_poids]]), na.rm = TRUE)
taille_menages   <- weighted.mean(as.numeric(chefs[[c_taille]]),
                                  as.numeric(chefs[[c_poids]]), na.rm = TRUE)
cat("Taille moyenne des menages, lue sur les INDIVIDUS :",
    round(taille_individus, 2), "\n")
cat("Taille moyenne des menages, lue sur les MENAGES   :",
    round(taille_menages, 2), "\n")
cat("Les deux sont exactes : elles repondent a deux questions differentes.\n")

# On EXPORTE ce contre-exemple : le runtime doit pouvoir le montrer sans
# jamais ouvrir le .dta.
biais_taille <- tibble::tibble(
  unite_de_parcours = c("Lignes d'INDIVIDUS", "Lignes de MENAGES (chefs)"),
  question_repondue = c(
    "Quelle est la taille du menage d'une personne prise au hasard ?",
    "Quelle est la taille d'un menage pris au hasard ?"),
  n_lignes = c(nrow(ecam), nrow(chefs)),
  taille_moyenne_ponderee = round(c(taille_individus, taille_menages), 2)
)

regions <- chefs |>
  mutate(region = as.character(.data[[c_region]]),
         poids  = as.numeric(.data[[c_poids]]),
         taille = as.numeric(.data[[c_taille]]),
         milieu = if (!is.na(c_milieu)) as.character(.data[[c_milieu]])
                  else NA_character_) |>
  filter(!is.na(region)) |>
  group_by(region) |>
  summarise(
    n_menages               = n(),
    poids_total             = round(sum(poids, na.rm = TRUE)),
    taille_moyenne_brute    = round(mean(taille, na.rm = TRUE), 2),
    taille_moyenne_ponderee = round(weighted.mean(taille, poids,
                                                  na.rm = TRUE), 2),
    part_urbain_pct = if (all(is.na(milieu))) NA_real_ else
      round(100 * weighted.mean(grepl("urb", milieu, ignore.case = TRUE),
                                poids, na.rm = TRUE), 1),
    .groups = "drop") |>
  mutate(cle_region = normaliser(region)) |>
  arrange(desc(n_menages))

cat("\nRegions d'enquete :", nrow(regions), "\n")
print(regions)
cat("\nEcart brut / pondere sur la taille moyenne (points) : max",
    round(max(abs(regions$taille_moyenne_brute -
                    regions$taille_moyenne_ponderee)), 2), "\n")

# ---------------------------------------------------------------------
# 2. Fond de carte
# ---------------------------------------------------------------------
cat("\n--- 2. Fond de carte GADM ADM1 ---\n")
adm1 <- st_read(file.path(dir_in, "gadm41_CMR_1.shp"), quiet = TRUE) |>
  st_make_valid()
cat("Entites :", nrow(adm1), "| CRS EPSG :", st_crs(adm1)$epsg,
    "| valides :", sum(st_is_valid(adm1)), "\n")
adm1$superficie_km2 <- round(
  as.numeric(st_area(st_transform(adm1, CRS_MESURE))) / 1e6, 1)
cat("Superficie totale (km2) :", round(sum(adm1$superficie_km2)),
    "— reference 475 442\n")

adm1_out <- adm1 |>
  transmute(NAME_1, cle_region = normaliser(NAME_1), superficie_km2) |>
  st_transform(CRS_MESURE) |>
  st_simplify(dTolerance = TOL_M, preserveTopology = TRUE) |>
  st_transform(4326) |> st_make_valid()
cat("Simplification :", TOL_M, "m — geometries valides :",
    sum(st_is_valid(adm1_out)), "/", nrow(adm1_out), "\n")

# ---------------------------------------------------------------------
# 3. La table de correspondance — une DECISION DE METHODE, pas un calcul
# ---------------------------------------------------------------------
cat("\n--- 3. Correspondance ECAM5 -> GADM ---\n")
# La normalisation resout les accents et la ponctuation. Elle ne resout PAS
# le fait qu'ECAM5 a douze regions d'enquete et la carte dix : Douala et
# Yaounde ne sont pas des regions administratives. Aucun traitement de
# chaine ne devine cela — c'est une decision, elle doit etre visible.
apparie_auto <- regions$cle_region %in% adm1_out$cle_region
cat("Regions ECAM5 appariees par la seule normalisation :",
    sum(apparie_auto), "sur", nrow(regions), "\n")
cat("Non appariees :", paste(regions$region[!apparie_auto], collapse = " | "),
    "\n")

# Table ecrite a la main, verifiable ligne a ligne par un lecteur humain.
# A VALIDER AU PREMIER RENDU : les libelles de gauche doivent correspondre
# EXACTEMENT a ce que la ligne « Non appariees » ci-dessus vient d'afficher.
correspondance_manuelle <- tibble::tribble(
  ~libelle_source,   ~NAME_1_cible,   ~justification,
  "Douala",          "Littoral",      "Douala est une ville, pas une region administrative : elle appartient au Littoral",
  "Yaounde",         "Centre",        "Yaounde est une ville, pas une region administrative : elle appartient au Centre"
)

correspondance <- regions |>
  select(libelle_source = region, cle_source = cle_region) |>
  left_join(adm1_out |> st_drop_geometry() |>
              select(NAME_1_auto = NAME_1, cle_source = cle_region),
            by = "cle_source") |>
  left_join(correspondance_manuelle |> mutate(cle_source = normaliser(libelle_source)) |>
              select(cle_source, NAME_1_manuel = NAME_1_cible, justification),
            by = "cle_source") |>
  mutate(NAME_1 = dplyr::coalesce(NAME_1_auto, NAME_1_manuel),
         methode = case_when(!is.na(NAME_1_auto)   ~ "normalisation",
                             !is.na(NAME_1_manuel) ~ "table manuelle",
                             TRUE                  ~ "NON APPARIEE"),
         justification = ifelse(is.na(justification),
                                "libelle identique apres normalisation",
                                justification)) |>
  select(libelle_source, cle_source, NAME_1, methode, justification)

print(correspondance)
cat("Regions encore non appariees :",
    sum(correspondance$methode == "NON APPARIEE"), "\n")
cat("CONTROLE : chaque NAME_1 de la table existe-t-il dans GADM ? ",
    all(na.omit(correspondance$NAME_1) %in% adm1_out$NAME_1), "\n")

# ---------------------------------------------------------------------
# 4. Ecriture
# ---------------------------------------------------------------------
cat("\n--- 4. Ecriture ---\n")
ecrire_csv(regions, "J11_ecam5_regions.csv")
ecrire_csv(biais_taille, "J11_biais_taille.csv")
ecrire_csv(correspondance, "J11_correspondance_regions.csv")
p <- file.path(dir_out, "J11_adm1_cmr.geojson")
st_write(adm1_out, p, delete_dsn = TRUE, quiet = TRUE,
         layer_options = GEOJSON_OPTS)
cat(sprintf("  -> %-34s %6d Ko  %4d entites\n", "J11_adm1_cmr.geojson",
            poids_ko(p), nrow(adm1_out)))

readme <- tibble::tibble(
  fichier = c("J11_ecam5_regions.csv", "J11_biais_taille.csv",
              "J11_correspondance_regions.csv", "J11_adm1_cmr.geojson"),
  unite_observation = c("region d'enquete ECAM5", "unite de parcours",
                        "libelle source", "region ADM1"),
  produit_par  = "pedagogie/_commons/data/J11_extraits/00_extraire_J11.R",
  consomme_par = "pedagogie/J11_perenniser_transmettre/runtime.qmd"
)
ecrire_csv(readme, "J11_extraits_README.csv")

cat("\n=====================================================\n")
cat(" Extraction J11 terminee. Poids total :",
    round(sum(file.size(list.files(dir_out, full.names = TRUE,
                                   pattern = "\\.(csv|geojson)$"))) / 1024),
    "Ko\n")
cat("=====================================================\n")
