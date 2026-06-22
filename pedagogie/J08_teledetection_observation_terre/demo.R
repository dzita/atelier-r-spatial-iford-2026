# =====================================================================
# J8 - Teledetection et observation de la Terre (script de salle)
# Atelier IFORD x GDSG - Yaounde 5 aout 2026
# Conception pedagogique complete : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita (GDSG/IFORD)
# Partie I : GHSL Built-Up Cameroun 2015 vs 2025
# Partie II : Inondations EMSR772 Yagoua 2024 + Open Buildings
# =====================================================================

library(sf)
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(terra)
library(tmap)
library(exactextractr)
library(scales)
library(tibble)

source("../_commons/helpers/fetch_data.R")
out_dir <- "outputs"
dir.create(out_dir, showWarnings = FALSE)

# ====================================================================
# PARTIE I - GHSL Built-Up
# ====================================================================

# Helpers
ghsl_dir <- fetch_ghs_built_dir()

charger_ghsl <- function(annee, data_dir = ghsl_dir) {
  archives <- list.files(data_dir,
    pattern = paste0("^GHS_BUILT_S_E", annee, ".*\\.zip$"),
    full.names = TRUE)
  rasters <- lapply(archives, function(z) {
    tmp_dir <- tempfile("ghsl_"); dir.create(tmp_dir)
    unzip(z, exdir = tmp_dir)
    rast(list.files(tmp_dir, pattern = "\\.tif$",
                    full.names = TRUE, recursive = TRUE)[1])
  })
  do.call(mosaic, rasters)
}

preparer_raster <- function(r, pays) {
  pays_vect <- vect(st_transform(pays, crs(r)))
  mask(crop(r, pays_vect), pays_vect)
}

resumer_bati <- function(polygones, raster, annee, id_col, nom_col) {
  pol_m <- st_transform(polygones, crs(raster))
  bati_km2    <- exact_extract(raster, pol_m, "sum") / 1e6
  surface_km2 <- as.numeric(st_area(pol_m)) / 1e6
  pol_m |>
    mutate(annee = annee, surface_km2 = surface_km2, bati_km2 = bati_km2,
           part_batie_pct = 100 * bati_km2 / surface_km2) |>
    select(all_of(c(id_col, nom_col)), annee, surface_km2,
           bati_km2, part_batie_pct)
}

# Section 0 : Chargement
cmr0 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_0", quiet = TRUE)
cmr1 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_1", quiet = TRUE)
cmr2 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_2", quiet = TRUE)

bati_2015     <- charger_ghsl(2015)
bati_2025     <- charger_ghsl(2025)
bati_2015_cmr <- preparer_raster(bati_2015, cmr0)
bati_2025_cmr <- preparer_raster(bati_2025, cmr0)

# Section 1 : Indicateurs nationaux
cmr0_m           <- st_transform(cmr0, crs(bati_2025_cmr))
surface_cmr0_km2 <- as.numeric(st_area(cmr0_m)) / 1e6

national <- bind_rows(
  tibble(annee = 2015,
         bati_km2 = exact_extract(bati_2015_cmr, cmr0_m, "sum") / 1e6),
  tibble(annee = 2025,
         bati_km2 = exact_extract(bati_2025_cmr, cmr0_m, "sum") / 1e6)
) |>
  mutate(part_batie_pct = 100 * bati_km2 / surface_cmr0_km2)
print(national)

# Section 2 : Indicateurs regionaux ADM1
regions_2015 <- resumer_bati(cmr1, bati_2015_cmr, 2015, "GID_1", "NAME_1")
regions_2025 <- resumer_bati(cmr1, bati_2025_cmr, 2025, "GID_1", "NAME_1")

regions_chg <- regions_2015 |>
  st_drop_geometry() |>
  select(GID_1, NAME_1, bati_km2_2015 = bati_km2,
         part_batie_pct_2015 = part_batie_pct) |>
  left_join(regions_2025 |>
              st_drop_geometry() |>
              select(GID_1, bati_km2_2025 = bati_km2,
                     part_batie_pct_2025 = part_batie_pct),
            by = "GID_1") |>
  mutate(gain_bati_km2 = bati_km2_2025 - bati_km2_2015,
         croissance_pct = if_else(bati_km2_2015 > 0,
                                  100 * gain_bati_km2 / bati_km2_2015,
                                  NA_real_)) |>
  arrange(desc(gain_bati_km2))
print(regions_chg)

# Section 3 : Cartes
carte_part_2025 <- ggplot(regions_2025) +
  geom_sf(aes(fill = part_batie_pct), colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "magma") +
  labs(title = "Part de surface batie GHSL en 2025",
       fill = "% bati") +
  theme_minimal()
print(carte_part_2025)
ggsave(file.path(out_dir, "jour08_part_batie_2025.png"),
       carte_part_2025, width = 8, height = 5, dpi = 180)

carte_gain <- ggplot(regions_2025 |>
                     left_join(regions_chg, by = c("GID_1", "NAME_1"))) +
  geom_sf(aes(fill = gain_bati_km2), colour = "white", linewidth = 0.2) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B") +
  labs(title = "Gain de surface batie 2015-2025",
       fill = "Gain km2") +
  theme_minimal()
print(carte_gain)

# Section 4 : Typologie de croissance
regions_typo <- regions_chg |>
  mutate(profil = case_when(
    gain_bati_km2 >= median(gain_bati_km2) &
      part_batie_pct_2025 >= median(part_batie_pct_2025) ~ "Croissance forte et tissu dense",
    gain_bati_km2 >= median(gain_bati_km2) ~ "Croissance forte",
    part_batie_pct_2025 >= median(part_batie_pct_2025) ~ "Tissu dense",
    TRUE ~ "Croissance moderee"
  ))

# Section 5 : Zoom ADM2
departements_2015 <- resumer_bati(cmr2, bati_2015_cmr, 2015, "GID_2", "NAME_2")
departements_2025 <- resumer_bati(cmr2, bati_2025_cmr, 2025, "GID_2", "NAME_2")

departements_chg <- departements_2015 |>
  st_drop_geometry() |>
  select(GID_2, NAME_2, bati_km2_2015 = bati_km2) |>
  left_join(departements_2025 |>
              st_drop_geometry() |>
              select(GID_2, bati_km2_2025 = bati_km2),
            by = "GID_2") |>
  mutate(gain_bati_km2 = bati_km2_2025 - bati_km2_2015) |>
  arrange(desc(gain_bati_km2))
print(departements_chg |> slice_head(n = 10))

# Section 6 : Exports
write_csv(regions_chg,      file.path(out_dir, "jour08_regions_bati_2015_2025.csv"))
write_csv(regions_typo,     file.path(out_dir, "jour08_regions_typologie_bati.csv"))
write_csv(departements_chg, file.path(out_dir, "jour08_departements_bati_2015_2025.csv"))

# ====================================================================
# PARTIE II - Inondations EMSR772 + Open Buildings
# ====================================================================

emsr_dir    <- fetch_emsr772_dir()
emsr_dir_01 <- file.path(emsr_dir, "EMSR772_AOI01_DEL_PRODUCT_v2")

# Ex 1 : EMS AOI01 (avec st_make_valid pour reparer les geometries)
aoi01 <- st_read(file.path(emsr_dir_01,
                           "EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.shp"),
                 quiet = TRUE) |> st_make_valid()
flood01 <- st_read(file.path(emsr_dir_01,
                             "EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.shp"),
                   quiet = TRUE) |> st_make_valid()

cat("AOI01 surface :",
    round(as.numeric(st_area(aoi01)) / 1e6, 1), "km2\n")
cat("Surface inondee :",
    round(sum(as.numeric(st_area(flood01))) / 1e6, 2), "km2\n")
print(table(flood01$value))

# Ex 2 : Open Buildings
ob_dir <- fetch_open_buildings_dir()
ob_fichiers <- list.files(ob_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
batiments_raw <- lapply(ob_fichiers, function(f)
  read_csv(f, show_col_types = FALSE)) |> bind_rows()
batiments <- st_as_sf(batiments_raw,
                     coords = c("longitude", "latitude"), crs = 4326)
batiments_ok <- batiments |> filter(confidence >= 0.7)
cat("Batiments confidence >= 0.7 :",
    format(nrow(batiments_ok), big.mark = " "), "\n")

# Ex 3 : Batiments dans AOI01
if (st_crs(batiments_ok) != st_crs(aoi01)) {
  batiments_ok <- st_transform(batiments_ok, st_crs(aoi01))
}
batiments_aoi01 <- st_filter(batiments_ok, aoi01)

# Ex 4 : Estimation population
pers_par_batiment <- 5
pop_aoi01 <- nrow(batiments_aoi01) * pers_par_batiment

# Ex 5 : Batiments inondes
batiments_inondes <- st_filter(batiments_aoi01, flood01)
pop_inondee <- nrow(batiments_inondes) * pers_par_batiment

bilan_aoi01 <- tibble(
  zone = "AOI01",
  nb_batiments_aoi      = nrow(batiments_aoi01),
  nb_batiments_inondes  = nrow(batiments_inondes),
  pct_batiments_inondes = round(100 * nrow(batiments_inondes) /
                                nrow(batiments_aoi01), 1),
  pop_estimee_aoi       = pop_aoi01,
  pop_inondee           = pop_inondee
)
print(bilan_aoi01)

# Ex 6 : Fonction reutilisable + AOI02 + AOI03
analyser_inondation <- function(emsr_root, zone_pattern, batiments_sf,
                                pers_par_bat = 5) {
  shp_aoi <- list.files(emsr_root,
                        pattern = paste0(zone_pattern, ".*areaOfInterestA.*\\.shp$"),
                        full.names = TRUE, recursive = TRUE)[1]
  shp_flood <- list.files(emsr_root,
                          pattern = paste0(zone_pattern, ".*floodDepthA.*\\.shp$"),
                          full.names = TRUE, recursive = TRUE)[1]
  if (is.na(shp_aoi) || is.na(shp_flood)) {
    stop("Shapefiles ", zone_pattern, " introuvables dans ", emsr_root)
  }
  aoi   <- st_read(shp_aoi,   quiet = TRUE) |> st_make_valid()
  flood <- st_read(shp_flood, quiet = TRUE) |> st_make_valid()
  if (st_crs(batiments_sf) != st_crs(aoi)) {
    batiments_sf <- st_transform(batiments_sf, st_crs(aoi))
  }
  bat_aoi     <- st_filter(batiments_sf, aoi)
  bat_inondes <- st_filter(bat_aoi, flood)
  tibble(
    zone = zone_pattern,
    nb_batiments_aoi      = nrow(bat_aoi),
    nb_batiments_inondes  = nrow(bat_inondes),
    pct_batiments_inondes = if (nrow(bat_aoi) > 0)
                              round(100 * nrow(bat_inondes) / nrow(bat_aoi), 1)
                            else NA_real_,
    pop_estimee_aoi       = nrow(bat_aoi)     * pers_par_bat,
    pop_inondee           = nrow(bat_inondes) * pers_par_bat
  )
}

# Decompresser AOI02 et AOI03 si necessaire
for (zone in c("AOI02", "AOI03")) {
  zip_path <- file.path(emsr_dir,
                        sprintf("EMSR772_%s_DEL_PRODUCT_v1.zip", zone))
  shp_existe <- length(list.files(emsr_dir,
                                  pattern = sprintf("%s.*floodDepthA.*\\.shp$", zone),
                                  recursive = TRUE)) > 0
  if (!shp_existe && file.exists(zip_path)) {
    unzip(zip_path, exdir = emsr_dir)
  }
}

bilan_aoi02 <- analyser_inondation(emsr_dir, "AOI02", batiments_ok)
bilan_aoi03 <- analyser_inondation(emsr_dir, "AOI03", batiments_ok)
bilan_total <- bind_rows(bilan_aoi01, bilan_aoi02, bilan_aoi03)
print(bilan_total)

write_csv(bilan_total,
          file.path(out_dir, "jour08_bilan_inondations_emsr772.csv"))

# Fin J8
