# =====================================================================
# 00_telecharger_dhs_indicateurs.R
# Atelier IFORD x GDSG 2026 — Bonus du Jour 4
#
# Telecharge les indicateurs agreges par region de l'EDS-MICS Cameroun
# 2018 via l'API DHS StatCompiler (open, sans authentification pour
# les indicateurs agreges).
#
# Produit : pedagogie/_commons/data/dhs_cmr/indicateurs_dhs_cmr_2018.csv
#
# A executer UNE SEULE FOIS sur la machine de l'animateur, puis commit
# le CSV produit. Le runtime WebR utilise directement le CSV (rdhs ne
# fonctionne pas sur WebR a cause des dependances reseau).
#
# Dependances :
#   install.packages(c("rdhs", "dplyr", "readr"))
# =====================================================================

suppressPackageStartupMessages({
  library(rdhs)
  library(dplyr)
  library(readr)
})

# Indicateurs DHS standardises (codes officiels StatCompiler)
ind_ids <- c(
  "WS_SRCE_H_IMP",   # % menages source eau amelioree
  "HC_ELEC_H_ELC",   # % menages electricite
  "ED_LITR_W_LIT",   # % femmes 15-49 alphabetisees
  "ED_LITR_M_LIT",   # % hommes 15-49 alphabetises
  "HC_HHSZ_H_AVG"    # taille moyenne menage
)

message("[DHS] Requete StatCompiler API pour Cameroun 2018...")

dhs_raw <- dhs_data(
  countryIds   = "CM",
  indicatorIds = ind_ids,
  breakdown    = "subnational",   # par region
  surveyYearStart = 2018,
  surveyYearEnd   = 2019
)

# Format propre pour la pedagogie
indicateurs <- dhs_raw |>
  filter(!is.na(Value)) |>
  transmute(
    region            = CharacteristicLabel,
    indicateur        = IndicatorId,
    indicateur_libelle = Indicator,
    valeur            = Value,
    unite             = "%",
    enquete           = SurveyId,
    annee             = SurveyYear
  ) |>
  arrange(region, indicateur)

# Sauvegarde
out_path <- file.path(
  "pedagogie", "_commons", "data", "dhs_cmr",
  "indicateurs_dhs_cmr_2018.csv"
)
write_csv(indicateurs, out_path)

message(sprintf("[DHS] CSV ecrit : %s (%d lignes, %d regions x %d indicateurs)",
                out_path,
                nrow(indicateurs),
                n_distinct(indicateurs$region),
                n_distinct(indicateurs$indicateur)))

cat("\nApercu :\n")
print(head(indicateurs, 10))

cat("\nRegions couvertes :\n")
print(unique(indicateurs$region))
