# =====================================================================
# J4 - Gestion des donnees pour l'analyse spatiale (script de salle)
# Atelier IFORD x GDSG - Yaounde 30 juillet 2026
# Architecture modulaire : Jean Saturnin Alogo Samba (GDSG/IFORD)
# Bascule DHS Cameroun 2018 reel : Ramesesse Dzita (GDSG/IFORD)
# Donnees : EDS-MICS Cameroun 2018 (DHS Program)
# =====================================================================

# --- Packages ---
# dplyr/tidyr/readr/ggplot2 = tidyverse (manipulation + viz).
# haven = lire .DTA Stata. survey/srvyr = sondages avec plan de sondage.
# sf = vectoriel spatial.
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(haven)
library(survey)
library(srvyr)
library(sf)

# Helpers internes : fetch_dhs_recode_cmr_2018() + fetch_gadm_cameroon().
source("../_commons/helpers/fetch_data.R")

# ---- 0. Chargement des microfichiers DHS (deux options) -------------
# Option A : .DTA Stata complets (5 741 vars HR) via haven::read_dta().
# toupper() : on force toutes les variables en MAJUSCULES pour matcher la doc DHS.
menages <- read_dta(fetch_dhs_recode_cmr_2018("HR"))
names(menages) <- toupper(names(menages))

personnes <- read_dta(fetch_dhs_recode_cmr_2018("PR"))
names(personnes) <- toupper(names(personnes))

# Option B : extraits CSV pre-prepares (alternative legere).
# menages   <- read_csv("../_commons/data/dhs_cmr/dhs_cmr_2018_menages_extrait.csv")
# personnes <- read_csv("../_commons/data/dhs_cmr/dhs_cmr_2018_personnes_extrait.csv")

# cat() affiche du texte ; "\n" = saut de ligne.
cat("HR:", nrow(menages), "menages /", ncol(menages), "vars\n")
cat("PR:", nrow(personnes), "personnes /", ncol(personnes), "vars\n")

# ---- Module 1 : Tidyverse rappel ------------------------------------
# transmute() = mutate() + select() : on cree des variables ET on ne garde QUE celles-ci.
# haven::as_factor() convertit les codes Stata en libelles lisibles (yes/no, urban/rural).
menages_clef <- menages |>
  transmute(
    cluster_id     = HV001,                       # PSU : numero de grappe
    menage_id      = HV002,                       # numero de menage DANS le cluster
    poids_menage   = HV005,                       # poids menage (x 1e6 dans le .DTA)
    psu            = HV021,                       # equivalent a HV001 dans la plupart des EDS
    strate         = haven::as_factor(HV022),     # strate echantillonnage region x milieu
    region         = haven::as_factor(HV024),
    milieu         = haven::as_factor(HV025),
    taille_menage  = as.numeric(HV009),
    age_chef       = as.numeric(HV220),
    sexe_chef      = haven::as_factor(HV219),
    electricite    = haven::as_factor(HV206),
    television     = haven::as_factor(HV208),
    quintile       = haven::as_factor(HV270)      # index de richesse en quintiles
  )

# Pipeline classique : filter -> count -> arrange.
menages_clef |>
  filter(milieu == "urban") |>
  count(region) |>
  arrange(desc(n))

# Pipeline d'agregation : group_by(...) puis summarise(...) ligne par groupe.
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
# Extraction des variables cles cote PR. HVIDX = numero de ligne dans le menage.
personnes_clef <- personnes |>
  transmute(
    cluster_id   = HV001,
    menage_id    = HV002,
    ligne        = HVIDX,
    age          = as.numeric(HV105),
    sexe         = haven::as_factor(HV104),
    niveau_educ  = haven::as_factor(HV106)
  )

# Reflexe systematique : QUANTIFIER les non-matches AVANT la jointure.
personnes_orph <- personnes_clef |>
  anti_join(menages_clef, by = c("cluster_id", "menage_id")) |>
  nrow()
cat("Personnes orphelines :", personnes_orph, "\n")

# left_join : on prend toutes les personnes (gauche), on ajoute les caracteristiques HR.
personnes_enrichies <- personnes_clef |>
  left_join(
    menages_clef |> select(cluster_id, menage_id, region, milieu, strate,
                            poids_menage, electricite),
    by = c("cluster_id", "menage_id")
  )

# ---- Module 3 : Valeurs manquantes -----------------------------------
# across(everything(), ~ sum(is.na(.))) = nombre de NA par variable.
# pivot_longer pour passer en format long, filter pour ne garder que les variables a NA.
resume_na <- menages_clef |>
  summarise(across(everything(), ~ sum(is.na(.)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_na") |>
  filter(n_na > 0)
print(resume_na)

# Imputation par la mediane du couple (region, milieu) : strategie MAR classique.
# if_else strict sur les types -> on caste explicitement en numeric.
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
# Declaration du design : PSU + strate + poids + emboitement (nest = TRUE pour DHS).
dhs_design <- menages_clef |>
  mutate(poids = poids_menage / 1e6) |>
  as_survey_design(
    ids     = cluster_id,
    strata  = strate,
    weights = poids,
    nest    = TRUE
  )

# Calcul cote BRUT (sans poids) : moyenne classique.
brut <- menages_clef |>
  group_by(region) |>
  summarise(tx_elec_brut = round(mean(electricite == "yes") * 100, 1),
            .groups = "drop")

# Calcul cote PONDERE : survey_mean() applique poids + variance correcte du plan.
pondere <- dhs_design |>
  group_by(region) |>
  summarise(tx_elec_pond = round(survey_mean(electricite == "yes") * 100, 1))

# Comparaison cote a cote pour visualiser l'effet des poids.
inner_join(brut, pondere, by = "region") |>
  arrange(desc(tx_elec_brut))

# ---- Module 5 : Indicateurs par region (pour J5) ---------------------
# Indicateurs ponderes cote menages : on jette les colonnes _se (erreur-type).
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

# Design separe sur les personnes (poids menage partage entre membres).
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

# Indicateur alphabetisation : population cible = adultes 25+ ans.
indic_individus <- personnes_design |>
  filter(age >= 25, !is.na(alpha_bin)) |>
  group_by(region) |>
  summarise(pct_alpha_25plus = round(survey_mean(alpha_bin) * 100, 1)) |>
  select(-ends_with("_se"))

# Sortie finale : une ligne par region, prete pour J5.
indicateurs_region <- indic_menages |>
  left_join(indic_individus, by = "region")

print(indicateurs_region)

# ---- Module 6 : Jointure GADM ADM1 -----------------------------------
# adm1 = polygones administratifs de niveau 1 (regions) du Cameroun.
adm1 <- read_sf(fetch_gadm_cameroon(1))

# Normalisation : minuscules + sans accent + sans tiret -> "farnorth", puis dictionnaire.
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

# Cle de jointure normalisee dans les deux jeux.
adm1$region_key <- normalize_region(adm1$NAME_1)
indicateurs_region$region_key <- normalize_region(indicateurs_region$region)

# Resultat = sf avec les attributs indicateurs.
adm1_indic <- adm1 |>
  left_join(indicateurs_region, by = "region_key")

# Carte choroplethe : ggplot2 + geom_sf + palette viridis (daltonien-friendly).
ggplot(adm1_indic) +
  geom_sf(aes(fill = pct_electricite), color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "D",
                       name = "% ménages\nélectrifiés\n(pondéré)") +
  geom_sf_label(aes(label = NAME_1), size = 2.3, colour = "black",
                fill = scales::alpha("white", 0.75), label.size = 0,
                fontface = "bold", label.padding = unit(0.1, "lines")) +
  labs(title    = "Accès à l'électricité par région - Cameroun 2018",
       subtitle = "EDS-MICS Cameroun 2018 (DHS Program) - pourcentage de menages electrifies (estimation ponderee)",
       caption  = "Source : EDS-MICS Cameroun 2018 (DHS Program) / IFORD x GDSG 2026") +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank())

# ---- Export pour J5 --------------------------------------------------
# out_dir <- "outputs"
# dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
# write_csv(indicateurs_region,
#           file.path(out_dir, "indicateurs_region_dhs2018.csv"))

# Fin J4
