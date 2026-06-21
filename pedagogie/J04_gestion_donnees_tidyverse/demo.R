# =====================================================================
# J4 - Gestion des donnees pour l'analyse spatiale (script de salle)
# Atelier IFORD x GDSG - Yaounde 30 juillet 2026
# Architecture modulaire : Jean Saturnin Alogo Samba (GDSG/IFORD)
# Bascule DHS Cameroun 2018 reel : Ramesesse Dzita (GDSG/IFORD)
# Donnees : EDS-MICS Cameroun 2018 (DHS Program)
# =====================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(haven)
library(survey)
library(srvyr)
library(sf)

# Helpers
source("../_commons/helpers/fetch_data.R")

# ---- 0. Chargement des microfichiers DHS (deux options) -------------
# Option A (recommandee desktop) : .DTA originaux via haven
menages <- read_dta(fetch_dhs_recode_cmr_2018("HR"))
names(menages) <- toupper(names(menages))   # certains releases en lowercase

personnes <- read_dta(fetch_dhs_recode_cmr_2018("PR"))
names(personnes) <- toupper(names(personnes))

# Option B (alternative, equivalente pedagogiquement) : CSV extraits
# menages   <- read_csv("../_commons/data/dhs_cmr/dhs_cmr_2018_menages_extrait.csv")
# personnes <- read_csv("../_commons/data/dhs_cmr/dhs_cmr_2018_personnes_extrait.csv")

cat("HR:", nrow(menages), "menages /", ncol(menages), "vars\n")
cat("PR:", nrow(personnes), "personnes /", ncol(personnes), "vars\n")

# ---- Module 1 : Tidyverse rappel ------------------------------------
# On extrait du .DTA les vars cles (cf. script 00_extraire_dhs_pour_webr.R
# pour la liste complete et le mapping en francais)
menages_clef <- menages |>
  transmute(
    cluster_id     = HV001,
    menage_id      = HV002,
    poids_menage   = HV005,
    psu            = HV021,
    strate         = haven::as_factor(HV022),
    region         = haven::as_factor(HV024),
    milieu         = haven::as_factor(HV025),
    taille_menage  = as.numeric(HV009),
    age_chef       = as.numeric(HV220),
    sexe_chef      = haven::as_factor(HV219),
    electricite    = haven::as_factor(HV206),
    television     = haven::as_factor(HV208),
    quintile       = haven::as_factor(HV270)
  )

# Verbes dplyr de base
menages_clef |>
  filter(milieu == "urban") |>
  count(region) |>
  arrange(desc(n))

# group_by + summarise
menages_clef |>
  group_by(region) |>
  summarise(
    n_menages       = n(),
    taille_moy      = round(mean(taille_menage, na.rm = TRUE), 2),
    pct_urbain      = round(mean(milieu == "urban") * 100, 1),
    pct_electricite = round(mean(electricite == "yes") * 100, 1),
    .groups = "drop"
  ) |>
  arrange(desc(pct_electricite))

# ---- Module 2 : Jointures HR <-> PR ----------------------------------
personnes_clef <- personnes |>
  transmute(
    cluster_id   = HV001,
    menage_id    = HV002,
    ligne        = HVIDX,
    age          = as.numeric(HV105),
    sexe         = haven::as_factor(HV104),
    niveau_educ  = haven::as_factor(HV106)
  )

# Diagnostic prealable : personnes orphelines ?
personnes_orph <- personnes_clef |>
  anti_join(menages_clef, by = c("cluster_id", "menage_id")) |>
  nrow()
cat("Personnes orphelines :", personnes_orph, "\n")

# Joindre HR -> PR
personnes_enrichies <- personnes_clef |>
  left_join(
    menages_clef |> select(cluster_id, menage_id, region, milieu, strate,
                            poids_menage, electricite),
    by = c("cluster_id", "menage_id")
  )

# ---- Module 3 : Valeurs manquantes -----------------------------------
# Detection
resume_na <- menages_clef |>
  summarise(across(everything(), ~ sum(is.na(.)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_na") |>
  filter(n_na > 0)
print(resume_na)

# Imputation mediane par groupe sur age_chef (avec conversion numeric)
menages_clef <- menages_clef |>
  mutate(age_chef_num = as.numeric(age_chef)) |>
  group_by(region, milieu) |>
  mutate(
    age_chef_imp = if_else(
      is.na(age_chef_num),
      as.numeric(round(median(age_chef_num, na.rm = TRUE))),
      age_chef_num
    )
  ) |>
  ungroup()

# ---- Module 4 : Plan de sondage avec srvyr ---------------------------
dhs_design <- menages_clef |>
  mutate(poids = poids_menage / 1e6) |>
  as_survey_design(
    ids     = cluster_id,
    strata  = strate,
    weights = poids,
    nest    = TRUE
  )

# Comparer brut vs pondere
brut <- menages_clef |>
  group_by(region) |>
  summarise(tx_elec_brut = round(mean(electricite == "yes") * 100, 1),
            .groups = "drop")

pondere <- dhs_design |>
  group_by(region) |>
  summarise(tx_elec_pond = round(survey_mean(electricite == "yes") * 100, 1))

inner_join(brut, pondere, by = "region") |>
  arrange(desc(tx_elec_brut))

# ---- Module 5 : Indicateurs par region (pour J5) ---------------------
indic_menages <- dhs_design |>
  group_by(region) |>
  summarise(
    n_menages        = unweighted(n()),
    taille_moy       = round(survey_mean(taille_menage, na.rm = TRUE), 2),
    pct_urbain       = round(survey_mean(milieu == "urban") * 100, 1),
    pct_electricite  = round(survey_mean(electricite == "yes") * 100, 1),
    pct_tv           = round(survey_mean(television == "yes") * 100, 1)
  ) |>
  select(-ends_with("_se"))

# Indicateurs individus (alphabetisation proxy via niveau_educ)
personnes_design <- personnes_enrichies |>
  filter(!is.na(strate)) |>
  mutate(
    poids = poids_menage / 1e6,
    alpha_bin = case_when(
      niveau_educ == "no education, preschool" ~ 0L,
      !is.na(niveau_educ)                       ~ 1L,
      TRUE                                       ~ NA_integer_
    )
  ) |>
  as_survey_design(ids = cluster_id, strata = strate, weights = poids, nest = TRUE)

indic_individus <- personnes_design |>
  filter(age >= 25, !is.na(alpha_bin)) |>
  group_by(region) |>
  summarise(pct_alpha_25plus = round(survey_mean(alpha_bin) * 100, 1)) |>
  select(-ends_with("_se"))

indicateurs_region <- indic_menages |>
  left_join(indic_individus, by = "region")

print(indicateurs_region)

# ---- Module 6 : Jointure GADM ADM1 -----------------------------------
adm1 <- read_sf(fetch_gadm_cameroon(1))

# Normaliser les noms DHS vs GADM
norm <- function(x) {
  x |> iconv(from = "UTF-8", to = "ASCII//TRANSLIT") |> tolower() |>
       gsub("[^a-z0-9]", "", x = _)
}
dict <- c(northwest = "nordouest", southwest = "sudouest",
          farnorth = "extremenord", north = "nord", south = "sud",
          east = "est", west = "ouest", centre = "centre",
          littoral = "littoral", adamawa = "adamaoua", adamaoua = "adamaoua")
normalize_region <- function(x) {
  v <- norm(x); ifelse(v %in% names(dict), dict[v], v)
}

adm1$region_key <- normalize_region(adm1$NAME_1)
indicateurs_region$region_key <- normalize_region(indicateurs_region$region)

adm1_indic <- adm1 |>
  left_join(indicateurs_region, by = "region_key")

# Carte
ggplot(adm1_indic) +
  geom_sf(aes(fill = pct_electricite), color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "D", name = "% electricite") +
  geom_sf_label(aes(label = NAME_1), size = 2.3, color = "white",
                fontface = "bold") +
  labs(title = "Acces a l'electricite par region - Cameroun 2018",
       subtitle = "EDS-MICS 2018 (DHS Program), pondere",
       caption = "Sources : DHS Program / GADM v4.1 / IFORD x GDSG 2026") +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank())

# ---- Export pour J5 --------------------------------------------------
# out_dir <- "outputs"
# dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
# write_csv(indicateurs_region,
#           file.path(out_dir, "indicateurs_region_dhs2018.csv"))

# Fin J4
