# =====================================================================
# J01 — Introduction R + pensée spatiale (version exécution salle)
# Atelier IFORD x GDSG · Yaoundé 27 juillet 2026 · Animateur : R. Dzita
# =====================================================================

# ---- 0. Pré-vol -----------------------------------------------------
# Tous les packages chargés en début de script ; library() les met en mémoire.
library(here)         # chemins relatifs à la racine du projet
library(fs)           # opérations système de fichiers (alternative moderne)
library(tidyverse)    # méta-package : dplyr, tidyr, ggplot2, readr, purrr, stringr, forcats
library(janitor)      # nettoyage de noms de colonnes (clean_names)
library(skimr)        # résumé rapide d'un tableau (skim)
library(haven)        # lecture Stata (.dta), SPSS (.sav), SAS (.sas7bdat)
library(sf)           # données spatiales vectorielles ("Simple Features")
library(tmap)         # cartographie thématique (grammaire "tidy")

# source() exécute un script et ramène ses fonctions dans l'environnement.
source(here("pedagogie", "_commons", "helpers", "fetch_data.R"))
source(here("pedagogie", "_commons", "helpers", "theme_iford.R"))

R.version.string       # version de R utilisée
sf_extSoftVersion()    # versions des bibliothèques C/C++ : GDAL, GEOS, PROJ

# ---- 1. Vecteurs et tibble ------------------------------------------
# Deux vecteurs PARALLÈLES (même longueur, même ordre) puis on les
# assemble dans un tibble (tableau moderne).
regions <- c("Adamaoua", "Centre", "Est", "Extrême-Nord", "Littoral",
             "Nord", "Nord-Ouest", "Ouest", "Sud", "Sud-Ouest")
pop_est <- c(1340000, 4400000, 870000, 4200000, 3400000,
             2700000, 2000000, 2000000, 800000, 1700000)

tbl_cmr <- tibble(
  region   = regions,
  pop_2019 = pop_est,
  capitale = c("Ngaoundéré", "Yaoundé", "Bertoua", "Maroua", "Douala",
               "Garoua", "Bamenda", "Bafoussam", "Ebolowa", "Buea")
)
tbl_cmr

# ---- 2. dplyr en démographie ----------------------------------------
# Pipeline complet : on crée une variable catégorielle, on groupe, on agrège.
tbl_cmr |>
  mutate(
    pop_millions = pop_2019 / 1e6,
    pop_classe   = case_when(                 # IF / ELSE IF / ELSE lisible
      pop_2019 < 1e6 ~ "Moins de 1M",
      pop_2019 < 3e6 ~ "1 à 3M",
      TRUE           ~ "Plus de 3M"           # défaut
    )
  ) |>
  group_by(pop_classe) |>
  summarise(n = n(), pop_totale = sum(pop_2019))

# ---- 3. Charger les indicateurs DHS Cameroun 2018 (vraies données) --
# CSV agrégé par région via rdhs::dhs_data() (DHS StatCompiler API).
# Bootstrap : pedagogie/_commons/data/dhs_cmr/00_telecharger_dhs.R
library(readr); library(tidyr)
# Lecture CSV en format LONG (1 ligne par couple région × indicateur).
dhs <- read_csv(here("pedagogie", "_commons", "data", "dhs_cmr",
                     "indicateurs_dhs_cmr_2018.csv"),
                show_col_types = FALSE)
# pivot_wider : passe en format LARGE (1 ligne par région).
# rename : remplace les codes DHS par des noms parlants en français.
dhs_wide <- dhs |>
  select(region, indicateur, valeur) |>
  pivot_wider(names_from = indicateur, values_from = valeur) |>
  rename(tx_eau_ameliore  = WS_SRCE_H_IMP,
         tx_electricite   = HC_ELEC_H_ELC,
         tx_alpha_femmes  = ED_LITR_W_LIT,
         tx_alpha_hommes  = ED_LITR_M_LIT,
         taille_menage    = HC_HHSZ_H_AVG)
skim(dhs_wide)                                 # résumé rapide

# On dérive l'écart H-F en alphabétisation, puis on classe par électrification.
ind_region <- dhs_wide |>
  mutate(ecart_alpha_hf = tx_alpha_hommes - tx_alpha_femmes) |>
  arrange(desc(tx_electricite))
ind_region

# ---- 4. Charger ADM Cameroun (GADM v4.1) ----------------------------
# Les 4 fichiers JSON sont attendus dans datasets/cameroun/admin_boundaries/.
# A telecharger depuis https://gadm.org/download_country.html (choisir Cameroon).
# read_sf renvoie un objet sf = data.frame + colonne géométrie + CRS.
adm0 <- read_sf(fetch_gadm_cameroon(0))   # frontière nationale
adm1 <- read_sf(fetch_gadm_cameroon(1))   # 10 régions
adm3 <- read_sf(fetch_gadm_cameroon(3))   # ~360 arrondissements

print(adm1)              # affichage standardisé (type, bbox, CRS, attributs)
st_crs(adm1)$epsg        # code EPSG (4326 = WGS 84)

# ---- 5. Première carte ggplot ---------------------------------------
# Carte qualitative : 1 couleur par région, étiquette au centroïde.
ggplot(adm1) +
  geom_sf(aes(fill = NAME_1), color = "white", linewidth = 0.3, show.legend = FALSE) +
  geom_sf_label(aes(label = NAME_1), size = 2.8, colour = "black",
                fill = scales::alpha("white", 0.75), label.size = 0,
                fontface = "bold", label.padding = unit(0.1, "lines")) +
  scale_fill_viridis_d(option = "G") +    # palette qualitative daltonien-friendly
  labs(title = "Les 10 régions du Cameroun",
       subtitle = "Limites administratives ADM1 (GADM v4.1)",
       caption = iford_caption("Source : GADM v4.1, www.gadm.org")) +
  theme_iford()

# ---- 6. CRS : démo de l'erreur classique ----------------------------
# Création de 2 points GPS (longitude, latitude) en WGS 84 (EPSG:4326).
yaounde <- st_sfc(st_point(c(11.5021, 3.8480)), crs = 4326)
douala  <- st_sfc(st_point(c(9.7679, 4.0511)), crs = 4326)

# Pythagore sur des degrés : nombre sans dimension, INTERPRÉTATION IMPOSSIBLE.
sqrt((11.5021 - 9.7679)^2 + (3.8480 - 4.0511)^2)
# st_distance calcule la vraie distance géodésique (mètres). ~240 km attendus.
st_distance(yaounde, douala)

# ---- 7. Reprojection UTM 32N + aire ---------------------------------
# UTM 32N (EPSG:32632) = CRS plan en mètres, adapté à l'ouest du Cameroun.
adm1_utm32 <- st_transform(adm1, 32632)
adm1_utm32$superficie_km2 <- as.numeric(st_area(adm1_utm32)) / 1e6
# Contrôle : somme ~ 475 442 km² (superficie officielle du Cameroun).
sum(adm1_utm32$superficie_km2) |> round()

# ---- 7b. Démo Web Mercator (à NE JAMAIS utiliser pour stats) --------
# Web Mercator (EPSG:3857) déforme les aires en s'éloignant de l'équateur.
adm1_webmerc <- st_transform(adm1, 3857)
adm1_webmerc$webmerc_km2 <- as.numeric(st_area(adm1_webmerc)) / 1e6
# Table de comparaison : si Web Mercator était fidèle, ratio = 1 partout.
comparaison <- tibble(
  region        = adm1_utm32$NAME_1,
  utm32N_km2    = round(adm1_utm32$superficie_km2),
  webmerc_km2   = round(adm1_webmerc$webmerc_km2),
  ratio_webmerc = round(adm1_webmerc$webmerc_km2 / adm1_utm32$superficie_km2, 2)
)
print(comparaison)
# -> ratio > 1 partout, croît avec la latitude (nord plus déformé que sud).

# ---- 8. Carte choroplèthe densité -----------------------------------
# Mini-table population (clé NAME_1) puis jointure attributaire.
pop_tbl <- tibble(NAME_1 = regions, pop_2019 = pop_est)

# left_join sur sf : le résultat reste sf (la géométrie suit).
adm1_pop <- adm1_utm32 |>
  left_join(pop_tbl, by = "NAME_1") |>
  mutate(densite = pop_2019 / superficie_km2)  # densité hab/km²

setup_tmap_iford()   # applique les défauts visuels IFORD
tm_shape(adm1_pop) +
  tm_polygons(
    fill        = "densite",
    # Jenks = découpe en classes qui maximise l'écart inter-classes.
    # Palette jaune→rouge : adaptée à variable positive croissante.
    fill.scale  = tm_scale_intervals(style = "jenks", n = 5, values = "brewer.yl_or_rd"),
    fill.legend = tm_legend("Densité\n(hab/km²)")
  ) +
  tm_text("NAME_1", size = 0.6) +                   # étiquette des régions
  tm_compass(position = c("right", "top"), size = 1.2) +
  tm_scalebar(position = c("left", "bottom")) +
  tm_title("Densité de population par région — Cameroun (estim. 2019)") +
  tm_credits("Source : BUCREP (estim.), GADM v4.1\nIFORD x GDSG 2026",
             position = c("right", "bottom"))

# ---- 9. Sauvegarder la carte ----------------------------------------
# tmap_save(filename = here("pedagogie","J01_intro_R_pensee_spatiale","outputs","densite_regions.png"),
#           dpi = 300, width = 8, height = 7)

# Fin J1
