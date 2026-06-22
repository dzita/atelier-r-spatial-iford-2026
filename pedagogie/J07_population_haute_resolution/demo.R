# =====================================================================
# J7 - Cartographie de la population a haute resolution (script de salle)
# Atelier IFORD x GDSG - Yaounde 4 aout 2026
# Conception pedagogique complete : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita (GDSG/IFORD)
# Datasets : Edith Darin (workshop_material/jour_07/data sur Drive)
# =====================================================================

library(sf)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(terra)
library(tmap)
library(exactextractr)
library(scales)
# library(mapedit)  # charge seulement pour l'Exercice 5 (interactif)
library(tibble)

source("../_commons/helpers/fetch_data.R")
out_dir <- "outputs"
dir.create(out_dir, showWarnings = FALSE)

# ====================================================================
# EXERCICE 0 : Choropleth population administrative
# ====================================================================
pop_adm1 <- read_csv(fetch_admpop_adm1_cmr_2025(), show_col_types = FALSE)
cmr1     <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_1", quiet = TRUE)

cat("Non-correspondances ADM1_EN :",
    paste(setdiff(cmr1$NAME_1, pop_adm1$ADM1_EN), collapse = ", "), "\n")
cat("Non-correspondances ADM1_FR :",
    paste(setdiff(cmr1$NAME_1, pop_adm1$ADM1_FR), collapse = ", "), "\n")

# GADM utilise ADM1_FR pour le Cameroun
cmr1_pop <- cmr1 |>
  left_join(pop_adm1 |> select(ADM1_FR, T_TL, F_TL, M_TL),
            by = c("NAME_1" = "ADM1_FR"))

cat("Regions sans match (NA T_TL):", sum(is.na(cmr1_pop$T_TL)), "\n")

carte_choropleth <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = T_TL), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "plasma", labels = comma) +
  labs(title    = "Population par region au Cameroun, 2025",
       subtitle = "Source: OCHA COD-PS Cameroun",
       fill     = "Population") +
  theme_minimal()
print(carte_choropleth)

# ====================================================================
# EXERCICE 0b : Ratio femmes/hommes
# ====================================================================
cmr1_pop <- cmr1_pop |> mutate(ratio_fm = F_TL / M_TL)

carte_ratio <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = ratio_fm), colour = "white", linewidth = 0.3) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 1, labels = number_format(accuracy = 0.01)) +
  labs(title = "Ratio femmes / hommes par region, Cameroun 2025",
       fill  = "F/H") +
  theme_minimal()
print(carte_ratio)

# ====================================================================
# EXERCICE 0c : Part de la population jeune (0-14 ans)
# ====================================================================
cmr1_pop <- cmr1_pop |>
  left_join(
    pop_adm1 |>
      mutate(jeunes_0_14     = T_00_04 + T_05_09 + T_10_14,
             part_jeunes_pct = 100 * jeunes_0_14 / T_TL) |>
      select(ADM1_FR, jeunes_0_14, part_jeunes_pct),
    by = c("NAME_1" = "ADM1_FR")
  )

carte_jeunes <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = part_jeunes_pct), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "magma") +
  labs(title    = "Part de la population de moins de 15 ans",
       subtitle = "Cameroun, 2025",
       fill     = "% 0-14 ans") +
  theme_minimal()
print(carte_jeunes)

# ====================================================================
# EXERCICE 1 : Grille WorldPop 2025 avec tmap
# ====================================================================
pop_2025 <- rast(fetch_worldpop_constrained_cmr(2025))
print(pop_2025)
cat("Resolution (degres):", res(pop_2025), "\n")
cat("Nombre de cellules:", ncell(pop_2025), "\n")

# Mode statique pour export
tmap_mode("plot")
carte_grille_2025 <- tm_shape(pop_2025) +
  tm_raster(
    col.scale  = tm_scale_intervals(n = 7, style = "quantile",
                                    values = "brewer.yl_or_rd"),
    col.legend = tm_legend(title = "Population (hab/cellule)")
  ) +
  tm_shape(cmr1) +
  tm_borders(col = "grey40", lwd = 0.5) +
  tm_title("Population carroyee WorldPop 2025 - Cameroun")
print(carte_grille_2025)

# Decommenter pour le mode interactif Leaflet en salle
# tmap_mode("view")
# carte_grille_2025

# ====================================================================
# EXERCICE 2 : Population a Yaounde en 2025
# ====================================================================
cmr2    <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_2", quiet = TRUE)
yaounde <- cmr2 |> filter(NAME_2 == "Mfoundi")

yaounde_v        <- vect(st_transform(yaounde, crs(pop_2025)))
pop_2025_yde     <- mask(crop(pop_2025, yaounde_v), yaounde_v)
pop_yaounde_2025 <- global(pop_2025_yde, "sum", na.rm = TRUE)$sum

cat("Population Yaounde (Mfoundi) en 2025:",
    format(round(pop_yaounde_2025), big.mark = " "), "habitants\n")

# Carte interactive avec fond satellite (en salle)
# tmap_mode("view")
# tm_basemap(c("Esri.WorldImagery", "OpenStreetMap")) +
#   tm_shape(pop_2025_yde) +
#   tm_raster(col_alpha = 0.6,
#             col.scale = tm_scale_intervals(n = 7, style = "quantile",
#                                            values = "brewer.yl_or_rd")) +
#   tm_shape(yaounde) +
#   tm_borders(col = "white", lwd = 2) +
#   tm_title("WorldPop 2025 sur imagerie satellite - Yaounde")

# ====================================================================
# EXERCICE 3 : Population a Yaounde en 2015
# ====================================================================
pop_2015         <- rast(fetch_worldpop_constrained_cmr(2015))
yaounde_v_2015   <- vect(st_transform(yaounde, crs(pop_2015)))
pop_2015_yde     <- mask(crop(pop_2015, yaounde_v_2015), yaounde_v_2015)
pop_yaounde_2015 <- global(pop_2015_yde, "sum", na.rm = TRUE)$sum

cat("Population Yaounde en 2015:",
    format(round(pop_yaounde_2015), big.mark = " "), "habitants\n")

# ====================================================================
# EXERCICE 4 : Comparaison 2015-2025 + agregation par region
# ====================================================================
cat("2015:", format(round(pop_yaounde_2015), big.mark = " "), "\n")
cat("2025:", format(round(pop_yaounde_2025), big.mark = " "), "\n")
cat("Croissance Yaounde:",
    round(100 * (pop_yaounde_2025 - pop_yaounde_2015) / pop_yaounde_2015, 1),
    "%\n")

pop_2025_par_region <- exact_extract(pop_2025, st_transform(cmr1, crs(pop_2025)), "sum")
pop_2015_par_region <- exact_extract(pop_2015, st_transform(cmr1, crs(pop_2015)), "sum")

regions_pop <- cmr1 |>
  st_drop_geometry() |>
  select(NAME_1) |>
  mutate(pop_worldpop_2015 = round(pop_2015_par_region),
         pop_worldpop_2025 = round(pop_2025_par_region),
         variation         = pop_worldpop_2025 - pop_worldpop_2015,
         croissance_pct    = round(100 * variation / pop_worldpop_2015, 1)) |>
  arrange(desc(pop_worldpop_2025))
print(regions_pop)

# Carte cote-a-cote avec breaks communs
cmr0          <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_0", quiet = TRUE)
cmr0_v        <- vect(st_transform(cmr0, crs(pop_2025)))
pop_2025_cmr  <- mask(crop(pop_2025, cmr0_v), cmr0_v)
cmr0_v_2015   <- vect(st_transform(cmr0, crs(pop_2015)))
pop_2015_cmr  <- mask(crop(pop_2015, cmr0_v_2015), cmr0_v_2015)

breaks_communs <- quantile(
  c(values(pop_2025_cmr), values(pop_2015_cmr)),
  probs = seq(0, 1, length.out = 8), na.rm = TRUE
)

tmap_mode("plot")
carte_comparaison <- tmap_arrange(
  tm_shape(pop_2015_cmr) +
    tm_raster(col.scale = tm_scale_intervals(breaks = breaks_communs,
                                             values = "brewer.yl_or_rd")) +
    tm_shape(cmr1) + tm_borders(col = "grey40", lwd = 0.3) +
    tm_title("2015"),
  tm_shape(pop_2025_cmr) +
    tm_raster(col.scale = tm_scale_intervals(breaks = breaks_communs,
                                             values = "brewer.yl_or_rd")) +
    tm_shape(cmr1) + tm_borders(col = "grey40", lwd = 0.3) +
    tm_title("2025"),
  ncol = 2
)
print(carte_comparaison)

# ====================================================================
# EXERCICE 4b : Projection WorldPop 2030
# ====================================================================
pop_2030         <- rast(fetch_worldpop_constrained_cmr(2030))
yaounde_v_2030   <- vect(st_transform(yaounde, crs(pop_2030)))
pop_2030_yde     <- mask(crop(pop_2030, yaounde_v_2030), yaounde_v_2030)
pop_yaounde_2030 <- global(pop_2030_yde, "sum", na.rm = TRUE)$sum

evol_yaounde <- tibble(
  annee      = c(2015, 2025, 2030),
  population = c(round(pop_yaounde_2015), round(pop_yaounde_2025),
                 round(pop_yaounde_2030))
) |> mutate(croissance_vs_2015 = round(100 * (population - population[1]) /
                                       population[1], 1))
print(evol_yaounde)

graphique_evolution <- ggplot(evol_yaounde, aes(x = annee, y = population)) +
  geom_line(colour = "#2C7FB8", linewidth = 1) +
  geom_point(colour = "#2C7FB8", size = 3) +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(breaks = c(2015, 2025, 2030)) +
  labs(title    = "Evolution de la population a Yaounde (Mfoundi)",
       subtitle = "WorldPop constrained - 2015, 2025, 2030",
       x = "Annee", y = "Population estimee") +
  theme_minimal()
print(graphique_evolution)

# ====================================================================
# EXERCICE 5 : Zone personnalisee dessinee (mapedit) - INTERACTIF
# ====================================================================
# Decommenter pour la demo en salle (session R interactive obligatoire)
# zone_etudiants <- mapedit::editMap(
#   leaflet::leaflet() |>
#     leaflet::addProviderTiles("Esri.WorldImagery") |>
#     leaflet::setView(lng = 11.52, lat = 3.86, zoom = 12)
# )$finished
#
# zone_v         <- vect(st_transform(zone_etudiants, crs(pop_2025)))
# pop_zone       <- mask(crop(pop_2025, zone_v), zone_v)
# pop_zone_total <- global(pop_zone, "sum", na.rm = TRUE)$sum
# cat("Population de la zone:", round(pop_zone_total), "habitants\n")

# Fallback bounding box (sans interaction)
bbox_zone <- st_bbox(c(xmin = 11.48, ymin = 3.82, xmax = 11.58, ymax = 3.93),
                     crs = st_crs(4326)) |>
  st_as_sfc() |> st_as_sf()
zone_v   <- vect(st_transform(bbox_zone, crs(pop_2025)))
pop_zone <- mask(crop(pop_2025, zone_v), zone_v)
cat("Population zone (fallback bbox):",
    round(global(pop_zone, "sum", na.rm = TRUE)$sum), "habitants\n")

# ====================================================================
# EXERCICE 5b : Comparer plusieurs villes
# ====================================================================
villes_dept <- c(
  "Douala (Wouri)"    = "Wouri",
  "Yaounde (Mfoundi)" = "Mfoundi",
  "Bafoussam (Mifi)"  = "Mifi",
  "Bamenda (Mezam)"   = "Mezam",
  "Garoua (Benoue)"   = "Benoue"
)

norm_ascii <- function(x) iconv(x, to = "ASCII//TRANSLIT")

pop_villes <- lapply(names(villes_dept), function(nom) {
  cible <- norm_ascii(villes_dept[[nom]])
  dept  <- cmr2 |> filter(norm_ascii(NAME_2) == cible)
  if (nrow(dept) == 0) {
    message("[Ex 5b] Departement introuvable : ", nom, " - skip.")
    return(NULL)
  }
  dept_v <- vect(st_transform(dept, crs(pop_2025)))
  tibble(
    ville    = nom,
    pop_2015 = round(global(mask(crop(pop_2015, dept_v), dept_v),
                            "sum", na.rm = TRUE)$sum),
    pop_2025 = round(global(mask(crop(pop_2025, dept_v), dept_v),
                            "sum", na.rm = TRUE)$sum)
  )
}) |> bind_rows() |>
  mutate(croissance_pct = round(100 * (pop_2025 - pop_2015) / pop_2015, 1))
print(pop_villes)

# ====================================================================
# EXERCICE 6 : Densite de population (echelle log)
# ====================================================================
# Aire calculee avant le mutate (la colonne geometrie peut s'appeler "geom" ou "geometry")
cmr1_pop$surface_km2 <- as.numeric(st_area(cmr1_pop)) / 1e6

cmr1_densite <- cmr1_pop |>
  mutate(densite_hab_km2 = T_TL / surface_km2)

carte_densite <- ggplot(cmr1_densite) +
  geom_sf(aes(fill = densite_hab_km2), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "inferno", trans = "log10",
                       labels = comma, name = "hab/km2 (log)") +
  labs(title    = "Densite de population par region, Cameroun 2025",
       subtitle = "Echelle logarithmique") +
  theme_minimal()
print(carte_densite)

# ====================================================================
# EXERCICE 7 : Distribution par age entre deux regions
# ====================================================================
regions_a_comparer <- c("Centre", "Adamawa")

pop_age <- pop_adm1 |>
  filter(ADM1_EN %in% regions_a_comparer) |>
  select(ADM1_EN, starts_with("T_"), -T_TL) |>
  pivot_longer(cols = starts_with("T_"),
               names_to = "groupe_age", values_to = "population") |>
  mutate(groupe_age = sub("T_", "", groupe_age),
         groupe_age = gsub("_", "-", groupe_age),
         groupe_age = sub("Plus", "+", groupe_age))

ggplot(pop_age, aes(x = groupe_age, y = population, fill = ADM1_EN)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = comma) +
  labs(title = "Structure par age - comparaison entre deux regions",
       x = "Groupe d'age", y = "Population", fill = "Region") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ====================================================================
# EXERCICE 8 : GHSL-POP - mosaique, reprojection, comparaison
# ====================================================================
ghsl_dir <- fetch_ghspop_tuiles_dir()
zips     <- list.files(ghsl_dir, pattern = "\\.zip$", full.names = TRUE)
cat("Tuiles ZIP:", length(zips), "\n")

# Decompresser (1 seule fois)
tifs_existants <- list.files(ghsl_dir, pattern = "\\.tif$", full.names = TRUE)
if (length(tifs_existants) == 0) {
  for (z in zips) unzip(z, exdir = ghsl_dir)
}
tifs <- list.files(ghsl_dir, pattern = "\\.tif$", full.names = TRUE)
cat("TIF extraits:", length(tifs), "\n")

# Mosaique + reprojection + rognage
cat("Mosaique en cours...\n")
tuiles      <- sprc(lapply(tifs, rast))
ghsl_mosaic <- mosaic(tuiles, fun = "mean")

cat("Reprojection Mollweide -> WGS84...\n")
ghsl_wgs84  <- project(ghsl_mosaic, "EPSG:4326", method = "bilinear")

cmr0_v_ghsl <- vect(cmr0)
ghsl_cmr    <- mask(crop(ghsl_wgs84, cmr0_v_ghsl), cmr0_v_ghsl)
ghsl_cmr[ghsl_cmr < 0] <- NA

# Extraction Yaounde
yaounde_v_ghsl <- vect(st_transform(yaounde, crs(ghsl_cmr)))
ghsl_yde       <- mask(crop(ghsl_cmr, yaounde_v_ghsl), yaounde_v_ghsl)
pop_ghsl_yde   <- global(ghsl_yde, "sum", na.rm = TRUE)$sum
cat("Population GHSL a Yaounde:",
    format(round(pop_ghsl_yde), big.mark = " "), "\n")

# Comparaison nationale
pop_worldpop_total <- round(global(pop_2025_cmr, "sum", na.rm = TRUE)$sum)
pop_ghsl_total     <- round(global(ghsl_cmr, "sum", na.rm = TRUE)$sum)

cat("\nComparaison totaux nationaux - Cameroun 2025:\n")
cat("WorldPop constrained:", format(pop_worldpop_total, big.mark = " "), "\n")
cat("GHS-POP:             ", format(pop_ghsl_total,     big.mark = " "), "\n")
cat("CSV officiel:        ", format(sum(pop_adm1$T_TL), big.mark = " "), "\n")
cat("Ecart GHSL vs WorldPop (%):",
    round(100 * (pop_ghsl_total - pop_worldpop_total) / pop_worldpop_total, 1),
    "\n")

# Comparaison par region
pop_ghsl_par_region <- exact_extract(ghsl_cmr,
                                     st_transform(cmr1, crs(ghsl_cmr)), "sum")

regions_comparaison <- cmr1 |>
  st_drop_geometry() |>
  select(NAME_1) |>
  mutate(pop_worldpop_2025 = round(pop_2025_par_region),
         pop_ghsl_2025     = round(pop_ghsl_par_region),
         ecart_pct         = round(100 * (pop_ghsl_2025 - pop_worldpop_2025) /
                                   pop_worldpop_2025, 1)) |>
  arrange(desc(abs(ecart_pct)))
print(regions_comparaison)

# ====================================================================
# Exports CSV / GeoPackage
# ====================================================================
write_csv(regions_pop,
          file.path(out_dir, "jour07_population_regions_worldpop_2015_2025.csv"))
write_csv(pop_villes,
          file.path(out_dir, "jour07_population_grandes_villes_2015_2025.csv"))
write_csv(regions_comparaison,
          file.path(out_dir, "jour07_comparaison_worldpop_ghsl_par_region.csv"))

# Fin J7
