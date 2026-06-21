# =====================================================================
# 00_extraire_dhs_pour_webr.R
# Atelier IFORD x GDSG 2026 - Jour 4 (Gestion des donnees tidyverse)
#
# Produit des EXTRAITS CSV legers des microfichiers DHS Cameroun 2018
# pour le runtime WebR (qui ne peut pas charger directement les .DTA
# Stata complets, trop lourds et necessitant le package haven non
# embarque sur webR).
#
# A executer UNE SEULE FOIS sur la machine de l'animateur apres avoir
# extrait le pack CM_2018_DHS dans pedagogie/datasets/cameroun/.
#
# Production :
#   - dhs_cmr_2018_menages_extrait.csv   (HR : ~14k menages, ~25 vars)
#   - dhs_cmr_2018_personnes_extrait.csv (PR : ~70k personnes, ~12 vars)
#   - dhs_cmr_2018_README.csv            (documentation extraits)
#
# Usage :
#   source("pedagogie/_commons/data/dhs_cmr/00_extraire_dhs_pour_webr.R")
#
# Dependances :
#   install.packages(c("haven","dplyr","readr"),
#                    repos="https://packagemanager.posit.co/cran/latest")
# =====================================================================

# Conditionnel install
.deps <- c("haven", "dplyr", "readr")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[DHS] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(readr)
})

# Helper fetch_dhs_recode_cmr_2018()
source(file.path("pedagogie", "_commons", "helpers", "fetch_data.R"))

dir_out <- file.path("pedagogie", "_commons", "data", "dhs_cmr")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------------------
# 1. HR - Household Recode (un menage par ligne)
# ----------------------------------------------------------------------
message("[DHS] Lecture HR (menages) - peut prendre 10-30s...")
hr <- read_dta(fetch_dhs_recode_cmr_2018("HR"))
# Normaliser les noms de variables : certains releases DHS les stockent
# en minuscules (hv001) alors que la documentation officielle utilise
# le format majuscule (HV001). On force MAJUSCULES pour rester aligne
# avec la doc DHS et permettre du code lisible.
names(hr) <- toupper(names(hr))
message(sprintf("[DHS] HR brut: %d menages x %d variables",
                nrow(hr), ncol(hr)))

# On selectionne les variables structurellement utiles pour la pedagogie
# (sondage, attribution, equipements, demographie chef de menage,
# index richesse). Code DHS conserve pour tracer la source.
vars_hr <- c(
  # Identifiants + plan de sondage
  "HV001",  # cluster (PSU)
  "HV002",  # numero menage dans le cluster
  "HV005",  # poids menage (a diviser par 1e6)
  "HV021",  # PSU pour calcul variance
  "HV022",  # strate
  "HV023",  # sous-population (region x milieu)
  "HV024",  # region administrative
  "HV025",  # milieu de residence (urbain/rural)
  # Composition demographique du menage
  "HV009",  # nombre de membres
  "HV014",  # nombre d'enfants < 5 ans
  "HV219",  # sexe du chef de menage
  "HV220",  # age du chef de menage
  "HV216",  # nombre de chambres pour dormir
  # Conditions de vie / equipements
  "HV201",  # source d'eau a boire
  "HV205",  # type de toilette
  "HV206",  # electricite
  "HV207",  # radio
  "HV208",  # television
  "HV209",  # refrigerateur
  "HV210",  # velo
  "HV211",  # moto
  "HV212",  # voiture
  # Index richesse (DHS construct)
  "HV270",  # quintile de richesse
  "HV271"   # score continu de richesse
)

# Verifier que toutes existent
manquantes <- setdiff(vars_hr, names(hr))
if (length(manquantes)) {
  warning("Variables HR absentes (sur ", length(manquantes), "/",
          length(vars_hr), ") : ", paste(manquantes, collapse = ", "))
  vars_hr <- intersect(vars_hr, names(hr))
}

hr_extract <- hr |>
  select(all_of(vars_hr)) |>
  # Convertir labels Stata en facteurs lisibles
  mutate(across(where(\(x) inherits(x, "haven_labelled")),
                ~ haven::as_factor(.x))) |>
  # Renommage francais pour la pedagogie (modules 1-6)
  rename(
    cluster_id      = HV001,
    menage_id       = HV002,
    poids_menage    = HV005,
    psu             = HV021,
    strate          = HV022,
    sous_pop        = HV023,
    region          = HV024,
    milieu          = HV025,
    taille_menage   = HV009,
    enfants_moins_5 = HV014,
    sexe_chef       = HV219,
    age_chef        = HV220,
    nb_chambres     = HV216,
    source_eau      = HV201,
    type_toilette   = HV205,
    electricite     = HV206,
    radio           = HV207,
    television      = HV208,
    refrigerateur   = HV209,
    velo            = HV210,
    moto            = HV211,
    voiture         = HV212,
    quintile        = HV270,
    score_richesse  = HV271
  )

out_hr <- file.path(dir_out, "dhs_cmr_2018_menages_extrait.csv")
write_csv(hr_extract, out_hr)
message(sprintf("[DHS] HR ecrit: %s (%.1f Mo, %d menages, %d vars)",
                out_hr,
                file.size(out_hr) / 1024^2,
                nrow(hr_extract), ncol(hr_extract)))

# ----------------------------------------------------------------------
# 2. PR - Person Recode (un membre de menage par ligne)
# ----------------------------------------------------------------------
message("[DHS] Lecture PR (personnes) - peut prendre 30-60s...")
pr <- read_dta(fetch_dhs_recode_cmr_2018("PR"))
names(pr) <- toupper(names(pr))  # cf. note normalisation HR ci-dessus
message(sprintf("[DHS] PR brut: %d personnes x %d variables",
                nrow(pr), ncol(pr)))

vars_pr <- c(
  "HV001",  # cluster (joindre avec HR)
  "HV002",  # menage_id (joindre avec HR)
  "HVIDX",  # numero ligne membre
  "HV101",  # lien avec chef de menage
  "HV102",  # residence habituelle
  "HV103",  # a dormi la nuit precedente
  "HV104",  # sexe
  "HV105",  # age en annees
  "HV106",  # plus haut niveau d'education atteint
  "HV108",  # nombre d'annees d'ecole
  "HV121",  # actuellement scolarise
  "HV270"   # quintile (heritage du menage)
)

manquantes <- setdiff(vars_pr, names(pr))
if (length(manquantes)) {
  warning("Variables PR absentes : ", paste(manquantes, collapse = ", "))
  vars_pr <- intersect(vars_pr, names(pr))
}

pr_extract <- pr |>
  select(all_of(vars_pr)) |>
  mutate(across(where(\(x) inherits(x, "haven_labelled")),
                ~ haven::as_factor(.x))) |>
  rename(
    cluster_id   = HV001,
    menage_id    = HV002,
    ligne        = HVIDX,
    lien_chef    = HV101,
    residence    = HV102,
    dormi_nuit   = HV103,
    sexe         = HV104,
    age          = HV105,
    niveau_educ  = HV106,
    annees_ecole = HV108,
    scolarise    = HV121,
    quintile     = HV270
  )

out_pr <- file.path(dir_out, "dhs_cmr_2018_personnes_extrait.csv")
write_csv(pr_extract, out_pr)
message(sprintf("[DHS] PR ecrit: %s (%.1f Mo, %d personnes, %d vars)",
                out_pr,
                file.size(out_pr) / 1024^2,
                nrow(pr_extract), ncol(pr_extract)))

# ----------------------------------------------------------------------
# 3. README extraits
# ----------------------------------------------------------------------
docs <- tibble(
  fichier  = c("dhs_cmr_2018_menages_extrait.csv",
               "dhs_cmr_2018_personnes_extrait.csv"),
  source   = "EDS-MICS Cameroun 2018 (DHS Program)",
  recode   = c("HR (Household Recode)",
               "PR (Person Recode)"),
  jointure = c("Cle (cluster_id, menage_id)",
               "Cle (cluster_id, menage_id, ligne) ; rejoint HR sur (cluster_id, menage_id)"),
  licence  = "DHS Program - usage formation IFORD/GDSG (https://dhsprogram.com/)",
  taille_ko= c(round(file.size(out_hr) / 1024),
               round(file.size(out_pr) / 1024)),
  remarque = c(sprintf("Extrait pedagogique : %d variables sur %d originales",
                       ncol(hr_extract), ncol(hr)),
               sprintf("Extrait pedagogique : %d variables sur %d originales",
                       ncol(pr_extract), ncol(pr)))
)
out_doc <- file.path(dir_out, "dhs_cmr_2018_README.csv")
write_csv(docs, out_doc)

cat("\n========================================================\n")
cat(" Extraction DHS Cameroun 2018 pour WebR terminee.\n")
cat("========================================================\n")
cat(" Fichiers produits dans :\n")
cat("  ", normalizePath(dir_out), "\n\n")
print(docs)
cat("\n")
