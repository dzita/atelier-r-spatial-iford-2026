# Day 8 - Remote sensing and Earth observation
# Long trainer script: full analysis of GHSL built-up in Cameroon (2015-2025)
# GHSL Built-Up Surface data: https://human-settlement.emergency.copernicus.eu/dataDownload.php

library(sf)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(terra)
library(exactextractr)
library(here)

data_dir <- here("./jour_08_teledetection_observation_terre/data")
output_dir <- here("./jour_08_teledetection_observation_terre/outputs")
dir.create(output_dir, showWarnings = FALSE)

load_ghsl <- function(year, data_dir) {
  archives <- list.files(
    file.path(data_dir, 'GHS-BUILT/'),
    pattern = paste0("^GHS_BUILT_S_E", year, ".*\\.zip$"),
    full.names = TRUE
  )

  rasters <- lapply(archives, function(zip_path) {
    tmp_dir <- tempfile("ghsl_")
    dir.create(tmp_dir)
    unzip(zip_path, exdir = tmp_dir)
    tif_path <- list.files(
      tmp_dir,
      pattern = "\\.tif$",
      full.names = TRUE,
      recursive = TRUE
    )[1]
    rast(tif_path)
  })

  do.call(mosaic, rasters)
}

prepare_raster <- function(raster, country) {
  country_vect <- vect(st_transform(country, crs(raster)))
  mask(crop(raster, country_vect), country_vect)
}

summarise_built_up <- function(polygons, raster, year, id_col, name_col) {
  poly_m <- st_transform(polygons, crs(raster))
  built_km2 <- exact_extract(raster, poly_m, "sum") / 1e6
  area_km2 <- as.numeric(st_area(poly_m)) / 1e6

  poly_m %>%
    mutate(
      year = year,
      area_km2 = area_km2,
      built_km2 = built_km2,
      built_share_pct = 100 * built_km2 / area_km2
    ) %>%
    select(
      all_of(c(id_col, name_col)),
      year,
      area_km2,
      built_km2,
      built_share_pct
    )
}

cmr0 <- st_read(
  file.path(data_dir, "gadm41_CMR.gpkg"),
  layer = "ADM_ADM_0",
  quiet = TRUE
)
cmr1 <- st_read(
  file.path(data_dir, "gadm41_CMR.gpkg"),
  layer = "ADM_ADM_1",
  quiet = TRUE
)
cmr2 <- st_read(
  file.path(data_dir, "gadm41_CMR.gpkg"),
  layer = "ADM_ADM_2",
  quiet = TRUE
)

built_2015 <- load_ghsl(2015, data_dir)
built_2025 <- load_ghsl(2025, data_dir)

built_2015_cmr <- prepare_raster(built_2015, cmr0)
built_2025_cmr <- prepare_raster(built_2025, cmr0)

# -------------------------------------------------------------------------
# 0. Inspection and quality checks
# -------------------------------------------------------------------------

print(cmr0)
print(cmr1)
print(cmr2)
st_crs(cmr1)
st_geometry_type(cmr1)
st_bbox(cmr1)

print(built_2015_cmr)
print(built_2025_cmr)

ggplot() +
  geom_sf(data = cmr1, fill = NA, colour = "grey40", linewidth = 0.3) +
  geom_sf(data = cmr2, fill = NA, colour = "grey80", linewidth = 0.15) +
  labs(title = "Administrative boundaries of Cameroon") +
  theme_minimal()

# Trainer note:
# The GHSL layer is in a global equal-area projection.
# We always reproject the administrative boundaries into the raster's CRS
# before any zonal extraction.

# -------------------------------------------------------------------------
# 1. National indicators
# -------------------------------------------------------------------------

cmr0_m <- st_transform(cmr0, crs(built_2015_cmr))
area_cmr0_km2 <- as.numeric(st_area(cmr0_m)) / 1e6

national_2015 <- tibble(
  year = 2015,
  built_km2 = exact_extract(built_2015_cmr, cmr0_m, "sum") / 1e6
) %>%
  mutate(built_share_pct = 100 * built_km2 / area_cmr0_km2)

national_2025 <- tibble(
  year = 2025,
  built_km2 = exact_extract(built_2025_cmr, cmr0_m, "sum") / 1e6
) %>%
  mutate(built_share_pct = 100 * built_km2 / area_cmr0_km2)

national <- bind_rows(national_2015, national_2025)
print(national)

national_change <- national %>%
  pivot_wider(names_from = year, values_from = c(built_km2, built_share_pct)) %>%
  mutate(
    built_gain_km2 = built_km2_2025 - built_km2_2015,
    growth_pct = 100 * built_gain_km2 / built_km2_2015,
    delta_built_share_pct = built_share_pct_2025 - built_share_pct_2015
  )

print(national_change)

# Trainer note:
# GHSL values are built-up surface per 100 m cell.
# Converting to km2 makes it easier to read and compare across territories.

# -------------------------------------------------------------------------
# 2. Regional indicators (ADM1)
# -------------------------------------------------------------------------

regions_2015 <- summarise_built_up(cmr1, built_2015_cmr, 2015, "GID_1", "NAME_1")
regions_2025 <- summarise_built_up(cmr1, built_2025_cmr, 2025, "GID_1", "NAME_1")

regions_change <- regions_2015 %>%
  st_drop_geometry() %>%
  select(
    GID_1,
    NAME_1,
    built_km2_2015 = built_km2,
    built_share_pct_2015 = built_share_pct
  ) %>%
  left_join(
    regions_2025 %>%
      st_drop_geometry() %>%
      select(
        GID_1,
        built_km2_2025 = built_km2,
        built_share_pct_2025 = built_share_pct
      ),
    by = "GID_1"
  ) %>%
  mutate(
    built_gain_km2 = built_km2_2025 - built_km2_2015,
    growth_pct = if_else(
      built_km2_2015 > 0,
      100 * built_gain_km2 / built_km2_2015,
      NA_real_
    ),
    delta_built_share_pct = built_share_pct_2025 - built_share_pct_2015,
    national_share_2025_pct = 100 * built_km2_2025 / sum(built_km2_2025)
  ) %>%
  arrange(desc(built_gain_km2))

print(regions_change)

# Summary table for discussion
regions_summary <- regions_change %>%
  mutate(
    gain_rank = min_rank(desc(built_gain_km2)),
    share_2025_rank = min_rank(desc(built_share_pct_2025))
  )

print(regions_summary)

# -------------------------------------------------------------------------
# 3. Main visualizations
# -------------------------------------------------------------------------

map_share_2025 <- ggplot(regions_2025) +
  geom_sf(aes(fill = built_share_pct), colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "magma") +
  labs(
    title = "Share of GHSL built-up surface in 2025",
    subtitle = "Administrative level 1",
    fill = "% built-up"
  ) +
  theme_minimal()

map_gain <- ggplot(
  regions_2025 %>% left_join(regions_change, by = c("GID_1", "NAME_1"))
) +
  geom_sf(aes(fill = built_gain_km2), colour = "white", linewidth = 0.2) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B") +
  labs(
    title = "Built-up surface gain between 2015 and 2025",
    subtitle = "Difference in km2 across Cameroon's regions",
    fill = "Gain km2"
  ) +
  theme_minimal()

map_growth <- ggplot(
  regions_2025 %>% left_join(regions_change, by = c("GID_1", "NAME_1"))
) +
  geom_sf(aes(fill = growth_pct), colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "plasma") +
  labs(
    title = "Relative built-up growth 2015-2025",
    subtitle = "Percentage change by region",
    fill = "% growth"
  ) +
  theme_minimal()

print(map_share_2025)
print(map_gain)
print(map_growth)

ggsave(
  file.path(output_dir, "jour08_part_batie_2025.png"),
  map_share_2025,
  width = 8,
  height = 5,
  dpi = 180
)
ggsave(
  file.path(output_dir, "jour08_gain_bati_2015_2025.png"),
  map_gain,
  width = 8,
  height = 5,
  dpi = 180
)
ggsave(
  file.path(output_dir, "jour08_croissance_bati_2015_2025.png"),
  map_growth,
  width = 8,
  height = 5,
  dpi = 180
)

plot_built <- ggplot(
  regions_change,
  aes(x = built_km2_2015, y = built_km2_2025, label = NAME_1)
) +
  geom_point(size = 2.5, colour = "#2C7FB8") +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey40") +
  geom_text(vjust = -0.6, size = 3) +
  labs(
    title = "Regional built-up area 2015 vs 2025",
    subtitle = "Points above the diagonal gained built-up area",
    x = "Built-up 2015 (km2)",
    y = "Built-up 2025 (km2)"
  ) +
  theme_minimal()

print(plot_built)

# -------------------------------------------------------------------------
# 4. Growth typology
# -------------------------------------------------------------------------

regions_typology <- regions_change %>%
  mutate(
    profile = case_when(
      built_gain_km2 >= median(built_gain_km2) &
        built_share_pct_2025 >=
          median(built_share_pct_2025) ~ "Strong growth and dense fabric",
      built_gain_km2 >= median(built_gain_km2) ~ "Strong growth",
      built_share_pct_2025 >= median(built_share_pct_2025) ~ "Dense fabric",
      TRUE ~ "Moderate growth"
    )
  )

map_typology <- ggplot(
  regions_2025 %>% left_join(regions_typology, by = c("GID_1", "NAME_1"))
) +
  geom_sf(aes(fill = profile), colour = "white", linewidth = 0.2) +
  scale_fill_manual(
    values = c(
      "Strong growth and dense fabric" = "#B2182B",
      "Strong growth" = "#FD8D3C",
      "Dense fabric" = "#2C7FB8",
      "Moderate growth" = "#FEE8C8"
    )
  ) +
  labs(
    title = "Teaching typology of built-up growth",
    fill = "Profile"
  ) +
  theme_minimal()

print(map_typology)
print(regions_typology)

# Trainer note:
# You can ask participants to change the thresholds or weights to see how
# the typology changes.

# -------------------------------------------------------------------------
# 5. Zoom on departments (ADM2)
# -------------------------------------------------------------------------

departments_2015 <- summarise_built_up(cmr2, built_2015_cmr, 2015, "GID_2", "NAME_2")
departments_2025 <- summarise_built_up(cmr2, built_2025_cmr, 2025, "GID_2", "NAME_2")

departments_change <- departments_2015 %>%
  st_drop_geometry() %>%
  select(
    GID_2,
    NAME_2,
    built_km2_2015 = built_km2,
    built_share_pct_2015 = built_share_pct
  ) %>%
  left_join(
    departments_2025 %>%
      st_drop_geometry() %>%
      select(
        GID_2,
        built_km2_2025 = built_km2,
        built_share_pct_2025 = built_share_pct
      ),
    by = "GID_2"
  ) %>%
  mutate(
    built_gain_km2 = built_km2_2025 - built_km2_2015,
    growth_pct = if_else(
      built_km2_2015 > 0,
      100 * built_gain_km2 / built_km2_2015,
      NA_real_
    )
  ) %>%
  arrange(desc(built_gain_km2))

print(departments_change %>% slice_head(n = 10))

map_dept_gain <- ggplot(
  departments_2025 %>% left_join(departments_change, by = c("GID_2", "NAME_2"))
) +
  geom_sf(aes(fill = built_gain_km2), colour = "white", linewidth = 0.12) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B") +
  labs(
    title = "Built-up gain 2015-2025 at ADM2 level",
    subtitle = "Useful zoom-in for local discussion",
    fill = "Gain km2"
  ) +
  theme_minimal()

print(map_dept_gain)

# -------------------------------------------------------------------------
# 6. Exports
# -------------------------------------------------------------------------

write_csv(
  regions_change,
  file.path(output_dir, "jour08_regions_bati_2015_2025.csv")
)
write_csv(
  regions_typology,
  file.path(output_dir, "jour08_regions_typologie_bati.csv")
)
write_csv(
  departments_change,
  file.path(output_dir, "jour08_departements_bati_2015_2025.csv")
)

st_write(
  regions_2025,
  file.path(output_dir, "jour08_regions_bati_2025.gpkg"),
  delete_dsn = TRUE
)
st_write(
  regions_2025 %>% left_join(regions_change, by = c("GID_1", "NAME_1")),
  file.path(output_dir, "jour08_regions_bati_2015_2025.gpkg"),
  delete_dsn = TRUE
)
st_write(
  departments_2025 %>% left_join(departments_change, by = c("GID_2", "NAME_2")),
  file.path(output_dir, "jour08_departements_bati_2015_2025.gpkg"),
  delete_dsn = TRUE
)

# Additional exercises:
# A. Redo the typology using quartiles.
# B. Compare the ADM1 and ADM2 results in a summary table.
# C. Calculate the share of 2025 built-up area concentrated in the 3 most dynamic regions.
# D. Test another derived indicator: built-up area per km2 of territory.
# E. Document the limitations of the 2015-2025 comparison (precision, margins, coverage).

# Key takeaways:
# - GHSL provides a standardized, high-resolution indicator of built-up area.
# - GADM boundaries allow cells to be aggregated into comparable regions.
# - Gain and relative growth maps identify areas of urban pressure.
