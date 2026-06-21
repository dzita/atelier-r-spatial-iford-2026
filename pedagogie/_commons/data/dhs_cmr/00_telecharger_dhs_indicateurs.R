# =====================================================================
# 00_telecharger_dhs_indicateurs.R
# Atelier IFORD x GDSG 2026
#
# Produit pedagogie/_commons/data/dhs_cmr/indicateurs_dhs_cmr_2018.csv
# Cinq indicateurs DHS standardises par region (10 lignes x 5 vars +
# colonne region), au format long (region, indicateur, valeur) attendu
# par J5 et le bonus J1 / J4 Module 7.
#
# Strategie : calcul LOCAL depuis le microfichier DHS Cameroun 2018
# (HR + IR + MR), avec plan de sondage stratifie via srvyr - plutot
# que l'appel API rdhs (qui necessitait reseau + parfois rate limit).
#
# Avantages :
#   - Pas de dependance reseau ni token DHS
#   - Coherence parfaite avec ce que les participants calculent en J4
#   - Reproductible offline
#
# Petite difference : les valeurs produites peuvent differer de 0.3-1
# point des valeurs publiees par DHS StatCompiler (qui appliquent des
# definitions tres precises sur certains indicateurs comme "alphabetise"
# = combinaison V149 niveau ecole + V155 niveau lecture). On documente
# notre definition exacte dans le CSV README.
#
# A executer UNE SEULE FOIS sur la machine de l'animateur, puis commit
# le CSV produit. Le runtime WebR utilise directement ce CSV.
#
# Usage :
#   source("pedagogie/_commons/data/dhs_cmr/00_telecharger_dhs_indicateurs.R")
#
# Dependances :
#   install.packages(c("haven","dplyr","tidyr","readr","srvyr","survey"),
#                    repos="https://packagemanager.posit.co/cran/latest")
# =====================================================================

# Installation conditionnelle
.deps <- c("haven", "dplyr", "tidyr", "readr", "srvyr", "survey")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[DHS] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(srvyr)
})

# Resolution de chemins independante du working directory (PowerShell
# Rscript depuis la racine OU RStudio source() depuis n'importe ou).
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

source(file.path(.PROJECT_ROOT, "pedagogie", "_commons", "helpers",
                 "fetch_data.R"))

out_dir <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "dhs_cmr")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Definition JMP (OMS/UNICEF) des sources d'eau "amelioree"
eau_amelio_mods <- c("piped to dwelling", "piped to yard/plot",
                     "public tap/standpipe", "tube well or borehole",
                     "protected well", "protected spring", "bottled water",
                     "piped to neighbor")

# ---------------------------------------------------------------------
# 1. HR - Indicateurs ponderes par region (eau, electricite, taille)
# ---------------------------------------------------------------------
message("[DHS] Lecture HR (menages)...")
hr <- read_dta(fetch_dhs_recode_cmr_2018("HR"))
names(hr) <- toupper(names(hr))

# Note : HV024 DHS Cameroun 2018 a 12 modalites (les capitales Yaounde
# et Douala sont separees du reste de leur region). Pour la cartographie
# J5 sur GADM ADM1 (10 polygones), on recodera region_adm1 en fusionnant
# les capitales dans leur region. Le calcul reste sur HV024 brut, puis
# on agrege via le design srvyr (poids preserves).
recoder_region_adm1 <- function(x) {
  x <- as.character(x)
  case_when(
    x %in% c("yaounde", "centre (without yaounde)") ~ "centre",
    x %in% c("douala",  "littoral (without douala)") ~ "littoral",
    TRUE ~ x
  )
}

hr_design <- hr |>
  transmute(
    cluster_id    = HV001,
    strate        = HV022,
    poids         = HV005 / 1e6,
    region_dhs    = haven::as_factor(HV024),
    region_adm1   = recoder_region_adm1(haven::as_factor(HV024)),
    source_eau    = haven::as_factor(HV201),
    electricite   = haven::as_factor(HV206),
    taille_menage = as.numeric(HV009)
  ) |>
  mutate(eau_amelio_bin = as.integer(source_eau %in% eau_amelio_mods),
         elec_bin       = as.integer(electricite == "yes")) |>
  as_survey_design(ids = cluster_id, strata = strate,
                   weights = poids, nest = TRUE)

# Agregation sur 10 regions ADM1 (recodees) -- pour J5 cartographie
ind_hr <- hr_design |>
  group_by(region = region_adm1) |>
  summarise(
    WS_SRCE_H_IMP = survey_mean(eau_amelio_bin) * 100,
    HC_ELEC_H_ELC = survey_mean(elec_bin) * 100,
    HC_HHSZ_H_AVG = survey_mean(taille_menage)
  ) |>
  select(-ends_with("_se"))

# Agregation sur les 12 modalites DHS (pour analyses fines urbain/capitale)
ind_hr_subnational <- hr_design |>
  group_by(region = region_dhs) |>
  summarise(
    WS_SRCE_H_IMP = survey_mean(eau_amelio_bin) * 100,
    HC_ELEC_H_ELC = survey_mean(elec_bin) * 100,
    HC_HHSZ_H_AVG = survey_mean(taille_menage)
  ) |>
  select(-ends_with("_se"))

message(sprintf("[DHS] HR : %d regions ADM1 + %d desagregations DHS x 3 indicateurs",
                nrow(ind_hr), nrow(ind_hr_subnational)))

# ---------------------------------------------------------------------
# 2. IR - Alphabetisation femmes 15-49
# ---------------------------------------------------------------------
# Definition simplifiee de "alphabetise" :
#   V155 (literacy level) >= "able to read whole sentence"
#   OU niveau d'education >= secondaire (V149)
# C'est tres proche de la def DHS officielle ED_LITR_W_LIT.
message("[DHS] Lecture IR (femmes 15-49)...")
ir <- read_dta(fetch_dhs_recode_cmr_2018("IR"))
names(ir) <- toupper(names(ir))

ir_design <- ir |>
  transmute(
    cluster_id  = V001,
    strate      = V022,
    poids       = V005 / 1e6,
    region_dhs  = haven::as_factor(V024),
    region_adm1 = recoder_region_adm1(haven::as_factor(V024)),
    v155        = haven::as_factor(V155),
    v149        = haven::as_factor(V149)
  ) |>
  mutate(
    # Alphabetisee : peut lire une phrase entiere OU education au moins secondaire
    alpha_bin = as.integer(
      v155 %in% c("able to read whole sentence") |
      v149 %in% c("secondary", "higher")
    )
  ) |>
  as_survey_design(ids = cluster_id, strata = strate,
                   weights = poids, nest = TRUE)

ind_ir <- ir_design |>
  group_by(region = region_adm1) |>
  summarise(ED_LITR_W_LIT = survey_mean(alpha_bin, na.rm = TRUE) * 100) |>
  select(-ends_with("_se"))

ind_ir_subnational <- ir_design |>
  group_by(region = region_dhs) |>
  summarise(ED_LITR_W_LIT = survey_mean(alpha_bin, na.rm = TRUE) * 100) |>
  select(-ends_with("_se"))

message(sprintf("[DHS] IR : %d regions ADM1 x 1 indicateur (femmes alpha)",
                nrow(ind_ir)))

# ---------------------------------------------------------------------
# 3. MR - Alphabetisation hommes 15-59
# ---------------------------------------------------------------------
message("[DHS] Lecture MR (hommes 15-59)...")
mr <- read_dta(fetch_dhs_recode_cmr_2018("MR"))
names(mr) <- toupper(names(mr))

mr_design <- mr |>
  transmute(
    cluster_id  = MV001,
    strate      = MV022,
    poids       = MV005 / 1e6,
    region_dhs  = haven::as_factor(MV024),
    region_adm1 = recoder_region_adm1(haven::as_factor(MV024)),
    mv155       = haven::as_factor(MV155),
    mv149       = haven::as_factor(MV149)
  ) |>
  mutate(
    alpha_bin = as.integer(
      mv155 %in% c("able to read whole sentence") |
      mv149 %in% c("secondary", "higher")
    )
  ) |>
  as_survey_design(ids = cluster_id, strata = strate,
                   weights = poids, nest = TRUE)

ind_mr <- mr_design |>
  group_by(region = region_adm1) |>
  summarise(ED_LITR_M_LIT = survey_mean(alpha_bin, na.rm = TRUE) * 100) |>
  select(-ends_with("_se"))

ind_mr_subnational <- mr_design |>
  group_by(region = region_dhs) |>
  summarise(ED_LITR_M_LIT = survey_mean(alpha_bin, na.rm = TRUE) * 100) |>
  select(-ends_with("_se"))

message(sprintf("[DHS] MR : %d regions ADM1 x 1 indicateur (hommes alpha)",
                nrow(ind_mr)))

# ---------------------------------------------------------------------
# 4. Fusion + pivot long (format attendu par J5)
# ---------------------------------------------------------------------
indicateurs_wide <- ind_hr |>
  left_join(ind_ir, by = "region") |>
  left_join(ind_mr, by = "region")

# Version subnational (12 lignes avec capitales separees)
indicateurs_wide_sub <- ind_hr_subnational |>
  left_join(ind_ir_subnational, by = "region") |>
  left_join(ind_mr_subnational, by = "region")

# Libelles long pour la doc
libelle <- c(
  WS_SRCE_H_IMP = "% menages avec source d'eau amelioree (def JMP)",
  HC_ELEC_H_ELC = "% menages avec electricite",
  HC_HHSZ_H_AVG = "Taille moyenne menage",
  ED_LITR_W_LIT = "% femmes 15-49 alphabetisees",
  ED_LITR_M_LIT = "% hommes 15-59 alphabetises"
)

# Unite par indicateur
unite_par_ind <- c(
  WS_SRCE_H_IMP = "%",
  HC_ELEC_H_ELC = "%",
  HC_HHSZ_H_AVG = "personnes",
  ED_LITR_W_LIT = "%",
  ED_LITR_M_LIT = "%"
)

indicateurs <- indicateurs_wide |>
  pivot_longer(-region, names_to = "indicateur", values_to = "valeur") |>
  mutate(
    indicateur_libelle = libelle[indicateur],
    unite              = unite_par_ind[indicateur],
    enquete            = "CM2018DHS",
    annee              = 2018,
    valeur             = round(valeur, 2)
  ) |>
  select(region, indicateur, indicateur_libelle, valeur, unite,
         enquete, annee) |>
  arrange(region, indicateur)

# ---------------------------------------------------------------------
# 5. Sauvegarde
# ---------------------------------------------------------------------
out_path <- file.path(out_dir, "indicateurs_dhs_cmr_2018.csv")
write_csv(indicateurs, out_path)

# Version subnational (12 lignes : Yaounde et Douala separes)
indicateurs_sub <- indicateurs_wide_sub |>
  pivot_longer(-region, names_to = "indicateur", values_to = "valeur") |>
  mutate(
    indicateur_libelle = libelle[indicateur],
    unite              = unite_par_ind[indicateur],
    enquete            = "CM2018DHS",
    annee              = 2018,
    valeur             = round(valeur, 2)
  ) |>
  select(region, indicateur, indicateur_libelle, valeur, unite,
         enquete, annee) |>
  arrange(region, indicateur)

out_path_sub <- file.path(out_dir, "indicateurs_dhs_cmr_2018_subnational.csv")
write_csv(indicateurs_sub, out_path_sub)

message(sprintf(
  "[DHS] CSV principal (ADM1 cartographique) : %s (%d lignes : %d regions x %d indicateurs)",
  out_path, nrow(indicateurs),
  n_distinct(indicateurs$region), n_distinct(indicateurs$indicateur)
))
message(sprintf(
  "[DHS] CSV subnational (avec Yaounde/Douala separes) : %s (%d lignes)",
  out_path_sub, nrow(indicateurs_sub)
))

cat("\nApercu principal (10 regions ADM1) :\n")
print(indicateurs_wide |> mutate(across(where(is.numeric), \(x) round(x, 1))))

cat("\nApercu subnational (12 lignes) :\n")
print(indicateurs_wide_sub |> mutate(across(where(is.numeric), \(x) round(x, 1))))
