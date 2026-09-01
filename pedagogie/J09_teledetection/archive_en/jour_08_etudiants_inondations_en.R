# Day 8 - Exercise 2: Floods and damage - EMSR772 (Yagoua, Cameroon 2024)
# Student script
# Data: Copernicus EMS EMSR772 + Google Open Buildings

packages <- c("sf", "dplyr", "ggplot2", "tmap", "readr", "tidyr", "osmdata",
              "terra", "exactextractr")
to_install <- packages[!packages %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

library(sf)
library(dplyr)
library(ggplot2)
library(tmap)
library(readr)
library(tidyr)
library(osmdata)
library(terra)
library(exactextractr)
library(here)

data_dir   <- here("./jour_08_teledetection_observation_terre/data")
output_dir <- here("./jour_08_teledetection_observation_terre/outputs")
dir.create(output_dir, showWarnings = FALSE)

cat("Data folder:", data_dir, "\n")
cat("Files used:\n")
cat("  EMSR772_products/EMSR772_AOI01_DEL_PRODUCT_v2/\n")
cat("    EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.shp\n")
cat("    EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.shp\n")
cat("  EMSR772_products/EMSR772_AOI02_DEL_PRODUCT_v1.zip\n")
cat("  EMSR772_products/EMSR772_AOI03_DEL_PRODUCT_v1.zip\n")
cat("  Open Buildings/open_buildings_yagoua.gpkg\n")
cat("    (prepared from the raw CSV.GZ tiles by\n")
cat("     scripts_formateurs/jour_08_formateur_prepare_open_buildings.R)\n")
cat("  cmr_pop_2024_CN_100m_R2025A_v1.tif (WorldPop raster, 100 m)\n")
cat("  OSM/routes_aoi01_yagoua.gpkg\n")
cat("    (fallback if the Overpass API is unavailable, prepared by\n")
cat("     scripts_formateurs/jour_08_formateur_prepare_osm_routes.R)\n")

# =========================================================================
# Context: Copernicus Emergency Management Service (EMS)
# =========================================================================
# Copernicus EMS rapidly maps areas affected by natural disasters from
# satellite imagery, within hours to a few days after the event.
#
# Activation EMSR772 (GLIDE FL-2024-000162-CMR) covers floods in the
# Yagoua region, in northern Cameroon, in 2024.
#
# Products available per area of interest (AOI):
#   - areaOfInterest : perimeter of the zone mapped by EMS
#   - floodDepth     : polygons with a flood depth class
#                      ("value" column: e.g. "0.50 - 1.00" in metres)
#   - observedEvent  : overall footprint of the observed event
#   - imageFootprint : extent of the satellite image used
# =========================================================================

# EXERCISE 1: Explore the EMSR772 data for AOI01 ----
# Load the area of interest and the flood depths.

emsr_dir_01 <- file.path(
  data_dir, "EMSR772_products", "EMSR772_AOI01_DEL_PRODUCT_v2"
)

aoi01 <- st_read(
  file.path(emsr_dir_01, "EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.shp"),
  quiet = TRUE
)

flood01 <- st_read(
  file.path(emsr_dir_01, "EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.shp"),
  quiet = TRUE
)
flood01 <- st_make_valid(flood01)

# Reduced study area: the official EMSR772 AOI01 covers ~6870 km2 (over
# 100 km wide) and contains more than 400,000 Open Buildings footprints
# at confidence >= 0.7: far too many for smooth interactive maps. We
# therefore zoom in on an ad hoc 5 x 5 km window, centred on the most
# densely flooded sector of the AOI (near Yagoua), which alone accounts
# for a large share of the total flooded area.
zoom_window <- st_bbox(
  c(xmin = 15.31957, ymin = 10.22218, xmax = 15.36528, ymax = 10.26745),
  crs = st_crs(aoi01)
)

aoi01 <- aoi01 %>% st_intersection(st_as_sfc(zoom_window))
flood01 <- st_filter(flood01, aoi01)

# --- Data structure ---
cat("=== Area of interest AOI01 (reduced window) ===\n")
print(aoi01)
cat("CRS         :", st_crs(aoi01)$input, "\n")
cat("Locality    :", aoi01$locality, "\n")
cat("AOI area    :", round(as.numeric(st_area(aoi01)) / 1e6, 1), "km2\n")

cat("\n=== Flood depths AOI01 ===\n")
print(flood01 %>% st_drop_geometry() %>% select(obj_desc, value, det_method))
cat("Flood CRS   :", st_crs(flood01)$input, "\n")
cat("Depth classes:\n")
print(table(flood01$value))
cat("Total flooded area:",
    round(sum(as.numeric(st_area(flood01))) / 1e6, 2), "km2\n")

# Interactive context map
tmap_mode("view")

tm_shape(aoi01) +
  tm_polygons(fill = "lightblue", fill_alpha = 0.2,
              col = "steelblue", lwd = 3) +
  tm_shape(flood01) +
  tm_polygons(
    fill = "value",
    fill.scale = tm_scale_categorical(values = "brewer.yl_or_rd"),
    fill.legend = tm_legend(title = "Depth (m)"),
    fill_alpha = 0.7
  ) +
  tm_title("EMSR772 - AOI01: Yagoua, flood depths 2024") +
  tm_basemap(c("Esri.WorldImagery", "OpenStreetMap"))

# Question 1:
# Which depth classes are present in this area?
# What is the total flooded area relative to the area of interest?

# EXERCISE 2: Load Google Open Buildings ----
# Open Buildings: Google's worldwide database of building footprints,
# distributed by S2 tile in CSV.GZ. Main columns:
#   latitude, longitude  -> centroid position
#   area_in_meters       -> estimated building area
#   confidence           -> probability that the object is indeed a building (0-1)
#   full_plus_code       -> location code
#
# The raw tiles cover an area far larger than Yagoua and weigh several
# GB in total: here we load the version already restricted to the
# study area (AOI01 + 5 km buffer), prepared once by
# scripts_formateurs/jour_08_formateur_prepare_open_buildings.R.

ob_gpkg <- file.path(data_dir, "Open Buildings", "open_buildings_yagoua.gpkg")

buildings_raw <- st_read(ob_gpkg, quiet = TRUE)

cat("Open Buildings file (prepared):", ob_gpkg, "\n")
cat("\nTotal buildings (Yagoua area):", format(nrow(buildings_raw), big.mark = " "), "\n")
cat("Columns:", paste(names(buildings_raw), collapse = ", "), "\n")
print(head(buildings_raw, 3))

# Distribution of the confidence column
cat("\nBreakdown by confidence level:\n")
buildings_raw %>%
  st_drop_geometry() %>%
  mutate(conf_class = cut(confidence, c(0, 0.5, 0.7, 1),
                           labels = c("<0.5", "0.5-0.7", ">0.7"),
                           include.lowest = TRUE)) %>%
  count(conf_class) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  print()

# Rebuild points from the centroid (latitude, longitude), as supplied by
# Google Open Buildings, and filter by confidence.
buildings <- buildings_raw %>%
  st_drop_geometry() %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

buildings_ok <- buildings %>% filter(confidence >= ___)  # threshold: 0.7

cat("Buildings with confidence >= 0.7:", format(nrow(buildings_ok), big.mark = " "), "\n")

# Question 2:
# Why filter on confidence before the spatial join?
# What would be the impact of a lower (0.5) or higher (0.9) threshold?

# EXERCISE 3: Buildings in the AOI01 reference area ----
# Spatially filter the buildings contained in the areaOfInterest.

if (st_crs(buildings_ok) != st_crs(aoi01)) {
  buildings_ok <- st_transform(buildings_ok, st_crs(aoi01))
}

buildings_aoi01 <- st_filter(___, ___)  # buildings_ok, aoi01

cat("Buildings in the AOI01 area:", format(nrow(buildings_aoi01), big.mark = " "), "\n")

# Map with the buildings in the area
tmap_mode("view")

tm_shape(aoi01) +
  tm_borders(col = "steelblue", lwd = 3) +
  tm_shape(flood01) +
  tm_polygons(
    fill = "value",
    fill.scale = tm_scale_categorical(values = "brewer.yl_or_rd"),
    fill.legend = tm_legend(title = "Depth (m)"),
    fill_alpha = 0.6
  ) +
  tm_shape(buildings_aoi01) +
  tm_dots(fill = "white", size = 0.15) +
  tm_title("AOI01 - Buildings and flooded areas") +
  tm_basemap(c("Esri.WorldImagery", "OpenStreetMap"))

# Question 3:
# Where are the buildings concentrated in the area?
# Which part of the area looks most exposed to flooding?

# EXERCISE 4: Population estimate for the area ----
# Method: number of buildings x average occupancy rate per building.
# Documented assumption: 5 people per building (semi-urban/rural setting).

people_per_building <- 5

pop_aoi01 <- ___ * people_per_building  # nrow(buildings_aoi01)

cat("Estimated population in AOI01:", format(pop_aoi01, big.mark = " "), "people\n")
cat("  (assumption:", people_per_building, "people per building)\n")

# Question 4:
# Is this assumption appropriate for the Yagoua area (northern Cameroon)?
# What data would allow this rate to be calibrated more precisely?
# How could a WorldPop raster be used for an independent estimate?

# EXERCISE 5: Buildings and population affected by flooding ----
# Cross the buildings in the area with the flood depth polygons.

buildings_flooded <- st_filter(___, ___)  # buildings_aoi01, flood01

cat("Buildings affected by flooding:", format(nrow(buildings_flooded), big.mark = " "), "\n")
cat("Share of buildings affected:",
    round(100 * nrow(buildings_flooded) / nrow(buildings_aoi01), 1), "%\n")

pop_flooded <- ___ * people_per_building  # nrow(buildings_flooded)

cat("Estimated population affected:", format(pop_flooded, big.mark = " "), "people\n")

summary_aoi01 <- tibble(
  zone                    = "AOI01",
  nb_buildings_aoi        = nrow(buildings_aoi01),
  nb_buildings_flooded    = nrow(buildings_flooded),
  pct_buildings_flooded   = round(100 * nrow(buildings_flooded) / nrow(buildings_aoi01), 1),
  pop_estimated_aoi       = pop_aoi01,
  pop_flooded             = pop_flooded
)

print(summary_aoi01)

# =========================================================================
# EXERCISE 6: Cross-validation with a population raster (WorldPop) ----
# =========================================================================
# The population derived from the building count (EXERCISE 4 and 5) rests
# on a strong assumption (5 people/building). WorldPop provides an
# independent estimate, calibrated on census data and satellite
# references, as a raster: each 100 m cell holds an estimated number
# of inhabitants.

worldpop_path <- file.path(data_dir, "cmr_pop_2024_CN_100m_R2025A_v1.tif")

worldpop <- rast(worldpop_path)

cat("=== WorldPop population raster (Cameroon, 2024, 100 m) ===\n")
print(worldpop)

# exact_extract(raster, polygon, "sum") sums the raster cell values
# contained in the polygon, weighted by the covered fraction: more
# precise than a simple count of cells whose centre falls inside.
pop_aoi01_worldpop <- exact_extract(___, ___, "sum")  # worldpop, aoi01

flood01_union <- st_union(flood01)
pop_flooded_worldpop <- exact_extract(worldpop, st_as_sf(___), "sum")  # flood01_union

comparison_pop_aoi01 <- tibble(
  source           = c("Buildings (5 ppl/building)", "WorldPop (raster)"),
  pop_total_aoi    = round(c(pop_aoi01, pop_aoi01_worldpop)),
  pop_flooded_zone = round(c(pop_flooded, ___))  # pop_flooded_worldpop
)

cat("\n=== Comparison of population estimation methods (AOI01) ===\n")
print(comparison_pop_aoi01)

# Map of the population raster, cropped to AOI01
worldpop_aoi01 <- mask(crop(worldpop, vect(aoi01)), vect(aoi01))

tmap_mode("view")

tm_shape(worldpop_aoi01) +
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population (people/cell)"),
    col_alpha = 0.85
  ) +
  tm_shape(aoi01) +
  tm_borders(col = "steelblue", lwd = 3) +
  tm_shape(flood01) +
  tm_borders(col = "black", lwd = 1) +
  tm_title("AOI01 - WorldPop population raster (100 m)") +
  tm_basemap(c("Esri.WorldImagery", "OpenStreetMap"))

# Question 5:
# Do the two methods give similar results for the total AOI population?
# And for the population in the flooded area? How would you explain any
# gap between the two approaches?

# =========================================================================
# EXERCISE 7: Flooded roads from OpenStreetMap (osmdata) ----
# =========================================================================
# OpenStreetMap (OSM) is a free, collaborative geographic database:
# anyone can add or correct objects (roads, buildings, waterways...),
# each described by tags of the form key = value (e.g.
# highway = "primary").
# The data is freely accessible via the Overpass API, queried here from
# R with the osmdata package.
# The public Overpass API is a free service with limited capacity: it
# sometimes responds with an error (429 "too many requests", 504
# "timeout"). If that happens, the code below automatically falls back
# to a copy already downloaded in data/OSM/routes_aoi01_yagoua.gpkg.

# bbox of the area of interest, used to query OpenStreetMap
bbox01 <- st_bbox(aoi01)

cat("=== OpenStreetMap (Overpass) query ===\n")
cat("Queried extent (bbox):\n")
print(bbox01)
cat("Tag searched: highway (road network)\n")

# If the Overpass API fails or is excessively slow (30 s), a locally
# downloaded copy is reloaded instead of getting stuck.
local_osm_file <- file.path(data_dir, "OSM", "routes_aoi01_yagoua.gpkg")

roads_osm <- tryCatch(
  {
    setTimeLimit(elapsed = 30, transient = TRUE)
    osm_query <- opq(bbox = ___) %>%  # bbox01
      add_osm_feature(key = ___)  # "highway"
    osm_data <- osmdata_sf(osm_query)
    osm_data$osm_lines
  },
  error = function(e) {
    cat("Overpass query unavailable (", conditionMessage(e), ").\n", sep = "")
    cat("Using the local copy:", local_osm_file, "\n")
    st_read(local_osm_file, quiet = TRUE)
  },
  finally = setTimeLimit(elapsed = Inf, transient = FALSE)
)

# --- Data structure ---
cat("\n=== OpenStreetMap roads retrieved ===\n")
cat("Number of segments:", nrow(roads_osm), "\n")
cat("Columns:", paste(names(roads_osm), collapse = ", "), "\n")
cat("Breakdown by road type (highway):\n")
print(table(roads_osm$highway))

if (st_crs(roads_osm) != st_crs(aoi01)) {
  roads_osm <- st_transform(roads_osm, st_crs(aoi01))
}

# Roads contained in the AOI01 area
roads_aoi01 <- st_filter(___, ___)  # roads_osm, aoi01

roads_aoi01 <- roads_aoi01 %>%
  mutate(length_km = as.numeric(st_length(.)) / 1000)

cat("\nRoads in the AOI01 area:", nrow(roads_aoi01), "\n")
cat("Total network length in AOI01:",
    round(sum(roads_aoi01$length_km), 1), "km\n")

# Question 6:
# The "highway" key groups together very different roads (motorway,
# track, footpath...). Should they all be kept for a flood exposure
# analysis, or should some types be filtered out?

# Intersection with the flooded areas
# (flood01_union was already computed in EXERCISE 6 for the WorldPop extraction)
roads_flooded <- st_intersection(___, ___) %>%  # roads_aoi01, flood01_union
  st_collection_extract("LINESTRING") %>%
  mutate(length_km = as.numeric(st_length(.)) / 1000)

cat("\nRoad segments affected by flooding:", nrow(roads_flooded), "\n")
cat("Total length of flooded road:",
    round(sum(roads_flooded$length_km), 1), "km\n")

pct_roads_flooded <- round(
  100 * sum(roads_flooded$length_km) / sum(roads_aoi01$length_km), 1
)
cat("Share of the road network flooded:", pct_roads_flooded, "%\n")

cat("\nFlooded length by road type:\n")
roads_flooded %>%
  st_drop_geometry() %>%
  group_by(___) %>%  # highway
  summarise(length_km = round(sum(length_km), 1)) %>%
  arrange(desc(length_km)) %>%
  print()

# Map of roads and their exposure to flooding
tmap_mode("view")

tm_shape(aoi01) +
  tm_borders(col = "steelblue", lwd = 3) +
  tm_shape(flood01) +
  tm_polygons(
    fill = "value",
    fill.scale = tm_scale_categorical(values = "brewer.yl_or_rd"),
    fill.legend = tm_legend(title = "Depth (m)"),
    fill_alpha = 0.5
  ) +
  tm_shape(roads_aoi01) +
  tm_lines(col = "white", lwd = 1) +
  tm_shape(roads_flooded) +
  tm_lines(col = "red", lwd = 2.5) +
  tm_title("AOI01 - OpenStreetMap road network and flooded roads") +
  tm_basemap(c("Esri.WorldImagery", "OpenStreetMap"))

# Question 7:
# What share of the area's road network is flooded?
# Which road types appear most affected, and what could the consequences
# be for access to services (health, markets)?
# What limitations should be kept in mind about the completeness of OSM
# data in this region?

write_csv(
  roads_flooded %>% st_drop_geometry() %>% select(highway, length_km),
  file.path(output_dir, "jour08_flooded_roads_osm_aoi01.csv")
)

# =========================================================================
# OPTIONAL EXERCISE: Wrap this up in a function and reproduce for AOI02 and AOI03 ----
# =========================================================================

# Function: analyse an EMSR772 activation area
analyse_flood <- function(emsr_dir, buildings_sf, ppl_per_bldg = 5) {

  aoi <- st_read(
    list.files(emsr_dir, pattern = "areaOfInterestA.*\\.shp$",
               full.names = TRUE)[1],
    quiet = TRUE
  )

  flood <- st_read(
    list.files(emsr_dir, pattern = "floodDepthA.*\\.shp$",
               full.names = TRUE)[1],
    quiet = TRUE
  )

  zone_id <- sub(".*_(AOI\\d+)_.*", "\\1",
                 basename(list.files(emsr_dir, pattern = "floodDepthA.*\\.shp$")[1]))

  if (st_crs(buildings_sf) != st_crs(aoi)) {
    buildings_sf <- st_transform(buildings_sf, st_crs(aoi))
  }

  bldg_aoi     <- st_filter(buildings_sf, aoi)
  bldg_flooded <- st_filter(bldg_aoi, flood)

  tibble(
    zone                  = zone_id,
    nb_buildings_aoi      = nrow(bldg_aoi),
    nb_buildings_flooded  = nrow(bldg_flooded),
    pct_buildings_flooded = round(100 * nrow(bldg_flooded) / nrow(bldg_aoi), 1),
    pop_estimated_aoi     = nrow(bldg_aoi)     * ppl_per_bldg,
    pop_flooded           = nrow(bldg_flooded) * ppl_per_bldg
  )
}

# Your turn: unzip AOI02 and AOI03 and apply the function ----

# Unzip AOI02
zip_aoi02 <- file.path(data_dir, "EMSR772_products", "EMSR772_AOI02_DEL_PRODUCT_v1.zip")
unzip(zip_aoi02, exdir = file.path(data_dir, "EMSR772_products"))

emsr_dir_02 <- file.path(data_dir, "EMSR772_products", ___)  # name of the AOI02 folder

# Unzip AOI03
zip_aoi03 <- file.path(data_dir, "EMSR772_products", "EMSR772_AOI03_DEL_PRODUCT_v1.zip")
unzip(zip_aoi03, exdir = file.path(data_dir, "EMSR772_products"))

emsr_dir_03 <- file.path(data_dir, "EMSR772_products", ___)  # name of the AOI03 folder

# Apply the function
summary_aoi02 <- analyse_flood(___, buildings_ok)  # emsr_dir_02
summary_aoi03 <- analyse_flood(___, buildings_ok)  # emsr_dir_03

# Compile the overall summary for the three zones
summary_total <- bind_rows(summary_aoi01, summary_aoi02, summary_aoi03)
print(summary_total)

# Summary chart
ggplot(summary_total, aes(x = zone)) +
  geom_col(aes(y = nb_buildings_aoi),     fill = "#AEC6CF", alpha = 0.9) +
  geom_col(aes(y = nb_buildings_flooded), fill = "#C23B22") +
  labs(
    title    = "Buildings exposed to EMSR772 flooding - Yagoua 2024",
    subtitle = "Blue: total in the reference area | Red: affected by flooding",
    x        = "AOI zone",
    y        = "Number of buildings"
  ) +
  theme_minimal()

ggplot(summary_total, aes(x = zone, y = pct_buildings_flooded)) +
  geom_col(fill = "#C23B22") +
  geom_text(aes(label = paste0(pct_buildings_flooded, "%")),
            vjust = -0.4, size = 3.5) +
  labs(
    title = "Share of buildings affected by flooding",
    x     = "AOI zone",
    y     = "% of buildings flooded"
  ) +
  ylim(0, 100) +
  theme_minimal()

# Question (optional):
# Which zone is most affected in absolute terms? In proportion?
# How could the population estimate be improved (alternative sources)?
# What other indicators would be useful for a humanitarian response?
