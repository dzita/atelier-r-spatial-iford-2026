# Day 8 - Exercise 2: Floods and damage - EMSR772 (Yagoua, Cameroon 2024)
# Trainer script
# Data: Copernicus EMS EMSR772 + Google Open Buildings

packages <- c(
  "sf",
  "dplyr",
  "ggplot2",
  "tmap",
  "readr",
  "tidyr",
  "osmdata",
  "terra",
  "exactextractr",
  "here"
)
to_install <- packages[!packages %in% rownames(installed.packages())]
if (length(to_install) > 0) {
  install.packages(to_install)
}

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

data_dir <- here("./jour_08_teledetection_observation_terre/data")
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
#
# Trainer note:
# Show the activation page on the Copernicus EMS website before starting:
# https://mapping.emergency.copernicus.eu/activations/EMSR772
# Emphasise the speed of production and the chain: image -> vector -> product.
# =========================================================================

# EXERCISE 1: Explore the EMSR772 data for AOI01 ----
# Load the area of interest and the flood depths.

emsr_dir_01 <- file.path(
  data_dir,
  "EMSR772_products",
  "EMSR772_AOI01_DEL_PRODUCT_v2"
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

# Trainer note:
# Tell students that the official Copernicus AOI01 is much larger: every
# figure computed in this workshop (buildings, population, roads) covers
# this reduced window, not the whole EMSR772 area. This is a teaching
# choice to keep the maps responsive.

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
cat(
  "Total flooded area:",
  round(sum(as.numeric(st_area(flood01))) / 1e6, 2),
  "km2\n"
)

# Trainer note:
# The "value" column holds depth ranges ("0.50 - 1.00", etc.). Each row
# is a polygon representing an area of a given depth. The union of all
# these polygons gives the overall flooded footprint.

# Interactive context map
tmap_mode("view")

tm_shape(aoi01) +
  tm_polygons(
    fill = "lightblue",
    fill_alpha = 0.2,
    col = "steelblue",
    lwd = 3
  ) +
  tm_shape(flood01) +
  tm_polygons(
    fill = "value",
    fill.scale = tm_scale_categorical(values = "brewer.yl_or_rd"),
    fill.legend = tm_legend(title = "Depth (m)"),
    fill_alpha = 0.7
  ) +
  tm_title("EMSR772 - AOI01: Yagoua, flood depths 2024") +
  tm_basemap(c("Esri.WorldImagery", "OpenStreetMap"))

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
cat(
  "\nTotal buildings (Yagoua area):",
  format(nrow(buildings_raw), big.mark = " "),
  "\n"
)
cat("Columns:", paste(names(buildings_raw), collapse = ", "), "\n")
print(head(buildings_raw, 3))

# Select the buildings within the study area
buildings_raw <- st_filter(buildings_raw, aoi01)

# Distribution of the confidence column
cat("\nBreakdown by confidence level:\n")
buildings_raw %>%
  st_drop_geometry() %>%
  mutate(
    conf_class = cut(
      confidence,
      c(0, 0.5, 0.7, 1),
      labels = c("<0.5", "0.5-0.7", ">0.7"),
      include.lowest = TRUE
    )
  ) %>%
  count(conf_class) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  print()

# Rebuild points from the centroid (latitude, longitude), as supplied by
# Google Open Buildings, and filter by confidence.
buildings <- buildings_raw %>%
  st_drop_geometry() %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

buildings_ok <- buildings %>% filter(confidence >= 0.7)

cat(
  "Buildings with confidence >= 0.7:",
  format(nrow(buildings_ok), big.mark = " "),
  "\n"
)

# Trainer note:
# A 0.7 threshold is a good compromise. For a sensitive humanitarian
# analysis, it can be raised to 0.75 or 0.8 to reduce false positives.
# Always document the chosen threshold in the final report.

# EXERCISE 3: Buildings in the AOI01 reference area ----
# Spatially filter the buildings contained in the areaOfInterest.

if (st_crs(buildings_ok) != st_crs(aoi01)) {
  buildings_ok <- st_transform(buildings_ok, st_crs(aoi01))
}

buildings_aoi01 <- st_filter(buildings_ok, aoi01)

cat(
  "Buildings in the AOI01 area:",
  format(nrow(buildings_aoi01), big.mark = " "),
  "\n"
)

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

# EXERCISE 4: Population estimate for the area ----
# Method: number of buildings x average occupancy rate per building.
# Documented assumption: 5 people per building (semi-urban/rural setting).

people_per_building <- 5

pop_aoi01 <- nrow(buildings_aoi01) * people_per_building

cat(
  "Estimated population in AOI01:",
  format(pop_aoi01, big.mark = " "),
  "people\n"
)
cat("  (assumption:", people_per_building, "people per building)\n")

# Trainer note:
# This rate is an assumption to be calibrated. For northern Cameroon, the
# 2005 RGPH census or WorldPop estimates help refine it. Alternative:
# extract the WorldPop population directly over the areaOfInterest using
# terra::extract() or exactextractr::exact_extract().

# EXERCISE 5: Buildings and population affected by flooding ----
# Cross the buildings in the area with the flood depth polygons.

buildings_flooded <- st_filter(buildings_aoi01, flood01)

cat(
  "Buildings affected by flooding:",
  format(nrow(buildings_flooded), big.mark = " "),
  "\n"
)
cat(
  "Share of buildings affected:",
  round(100 * nrow(buildings_flooded) / nrow(buildings_aoi01), 1),
  "%\n"
)

pop_flooded <- nrow(buildings_flooded) * people_per_building

cat(
  "Estimated population affected:",
  format(pop_flooded, big.mark = " "),
  "people\n"
)

summary_aoi01 <- tibble(
  zone = "AOI01",
  nb_buildings_aoi = nrow(buildings_aoi01),
  nb_buildings_flooded = nrow(buildings_flooded),
  pct_buildings_flooded = round(
    100 * nrow(buildings_flooded) / nrow(buildings_aoi01),
    1
  ),
  pop_estimated_aoi = pop_aoi01,
  pop_flooded = pop_flooded
)

print(summary_aoi01)

# Trainer note:
# st_filter() uses the st_intersects predicate by default: a building is
# "affected" if its centroid (point) intersects at least one floodDepth
# polygon. No need to union the polygons beforehand.

# Breakdown by depth class (supplementary analysis)
buildings_flooded_depth <- st_join(buildings_flooded, flood01["value"])

cat("\nBuildings by depth class:\n")
buildings_flooded_depth %>%
  st_drop_geometry() %>%
  count(value) %>%
  arrange(value) %>%
  mutate(pop_estimated = n * people_per_building) %>%
  print()

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
cat(
  "Resolution:",
  paste(round(res(worldpop), 6), collapse = " x "),
  "degrees\n"
)

# exact_extract() weights each raster cell by the fraction of its area
# covered by the polygon: more precise than a simple count of cells
# whose centre falls inside the polygon.
pop_aoi01_worldpop <- exact_extract(worldpop, aoi01, "sum")

flood01_union <- st_union(flood01)
pop_flooded_worldpop <- exact_extract(worldpop, st_as_sf(flood01_union), "sum")

comparison_pop_aoi01 <- tibble(
  source = c("Buildings (5 ppl/building)", "WorldPop (raster)"),
  pop_total_aoi = round(c(pop_aoi01, pop_aoi01_worldpop)),
  pop_flooded_zone = round(c(pop_flooded, pop_flooded_worldpop))
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

# Trainer note:
# For the total AOI population, the two methods agree reasonably well
# (same order of magnitude): this reasonably validates the 5
# people/building assumption for this specific area. The gap is much
# larger, however, for the population in the flooded zone: few building
# centroids fall inside the floodDepth polygons, which are often thin
# and fragmented, whereas the WorldPop raster smooths population over
# the whole flooded surface. The map above confirms this visually: the
# most populated cells (dark red) follow a settlement pattern that only
# partly overlaps the black floodDepth polygons. This illustrates a
# limitation of the point-in-polygon join with narrow polygons: a
# calculation based on flooded building footprints (rather than a
# centroid count) would give a more robust estimate.

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
#
# Trainer note:
# - Every OSM object is a node, a line (way) or a relation.
# - The "highway" key identifies roads; its value gives the type
#   (motorway, primary, secondary, tertiary, residential, track...).
# - OSM coverage is uneven: very dense in some areas mapped during
#   humanitarian responses (e.g. Humanitarian OpenStreetMap Team - HOT),
#   more incomplete elsewhere. Always check the data visually before
#   using it in an analysis.
# - The Overpass API is a public service for reasonable use: avoid
#   repeated queries over large extents, and consider saving the result
#   locally (st_write) to reuse it without re-querying the server.
# - ODbL licence: any reuse must credit OpenStreetMap and its
#   contributors.
# =========================================================================

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
    osm_query <- opq(bbox = bbox01) %>%
      add_osm_feature(key = "highway")
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
roads_aoi01 <- st_filter(roads_osm, aoi01)

roads_aoi01 <- roads_aoi01 %>%
  mutate(length_km = as.numeric(st_length(.)) / 1000)

cat("\nRoads in the AOI01 area:", nrow(roads_aoi01), "\n")
cat(
  "Total network length in AOI01:",
  round(sum(roads_aoi01$length_km), 1),
  "km\n"
)

# Intersection with the flooded areas
# (flood01_union was already computed in EXERCISE 6 for the WorldPop extraction)
roads_flooded <- st_intersection(roads_aoi01, flood01_union) %>%
  st_collection_extract("LINESTRING") %>%
  mutate(length_km = as.numeric(st_length(.)) / 1000)

cat(
  "\nRoad segments affected by flooding:",
  nrow(roads_flooded),
  "\n"
)
cat(
  "Total length of flooded road:",
  round(sum(roads_flooded$length_km), 1),
  "km\n"
)

pct_roads_flooded <- round(
  100 * sum(roads_flooded$length_km) / sum(roads_aoi01$length_km),
  1
)
cat("Share of the road network flooded:", pct_roads_flooded, "%\n")

cat("\nFlooded length by road type:\n")
roads_flooded %>%
  st_drop_geometry() %>%
  group_by(highway) %>%
  summarise(length_km = round(sum(length_km), 1)) %>%
  arrange(desc(length_km)) %>%
  print()

# Trainer note:
# st_intersection() clips each road exactly to the boundaries of the
# flood polygons: the resulting length is genuinely the flooded portion,
# not the total length of the road crossing it.
# st_collection_extract("LINESTRING") is needed because st_intersection()
# can return a GEOMETRYCOLLECTION (points + lines) when a road only
# touches a polygon at a single point.

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


write_csv(
  roads_flooded %>% st_drop_geometry() %>% select(highway, length_km),
  file.path(output_dir, "jour08_flooded_roads_osm_aoi01.csv")
)

# Key messages:
# - Copernicus EMS produces ready-to-use flood maps within hours, with
#   depth classes.
# - Open Buildings gives building centroids without population data; a
#   locally calibrated occupancy rate improves the estimate.
# - The analyse_flood() function illustrates the DRY principle (Don't
#   Repeat Yourself): one definition, three applications.
# - The results are estimates: buildings built after the image date,
#   buildings hidden by vegetation or clouds, and built-up/bare-soil
#   classification errors all introduce uncertainty.

# =========================================================================
# OPTIONAL EXERCISE: Wrap this up in a function and reproduce for AOI02 and AOI03 ----
# =========================================================================

# Function: analyse an EMSR772 activation area
analyse_flood <- function(emsr_dir, buildings_sf, ppl_per_bldg = 5) {
  aoi <- st_read(
    list.files(
      emsr_dir,
      pattern = "areaOfInterestA.*\\.shp$",
      full.names = TRUE
    )[1],
    quiet = TRUE
  )

  flood <- st_read(
    list.files(emsr_dir, pattern = "floodDepthA.*\\.shp$", full.names = TRUE)[
      1
    ],
    quiet = TRUE
  )

  zone_id <- sub(
    ".*_(AOI\\d+)_.*",
    "\\1",
    basename(list.files(emsr_dir, pattern = "floodDepthA.*\\.shp$")[1])
  )

  if (st_crs(buildings_sf) != st_crs(aoi)) {
    buildings_sf <- st_transform(buildings_sf, st_crs(aoi))
  }

  bldg_aoi <- st_filter(buildings_sf, aoi)
  bldg_flooded <- st_filter(bldg_aoi, flood)

  tibble(
    zone = zone_id,
    nb_buildings_aoi = nrow(bldg_aoi),
    nb_buildings_flooded = nrow(bldg_flooded),
    pct_buildings_flooded = round(100 * nrow(bldg_flooded) / nrow(bldg_aoi), 1),
    pop_estimated_aoi = nrow(bldg_aoi) * ppl_per_bldg,
    pop_flooded = nrow(bldg_flooded) * ppl_per_bldg
  )
}

# Unzip AOI02
zip_aoi02 <- file.path(
  data_dir,
  "EMSR772_products",
  "EMSR772_AOI02_DEL_PRODUCT_v1.zip"
)
unzip(zip_aoi02, exdir = file.path(data_dir, "EMSR772_products"))

emsr_dir_02 <- file.path(
  data_dir,
  "EMSR772_products",
  "EMSR772_AOI02_DEL_PRODUCT_v1"
)

# Unzip AOI03
zip_aoi03 <- file.path(
  data_dir,
  "EMSR772_products",
  "EMSR772_AOI03_DEL_PRODUCT_v1.zip"
)
unzip(zip_aoi03, exdir = file.path(data_dir, "EMSR772_products"))

emsr_dir_03 <- file.path(
  data_dir,
  "EMSR772_products",
  "EMSR772_AOI03_DEL_PRODUCT_v1"
)

# Apply the function to the three zones
summary_aoi02 <- analyse_flood(emsr_dir_02, buildings_ok)
summary_aoi03 <- analyse_flood(emsr_dir_03, buildings_ok)

# Compile the overall summary for the three zones
summary_total <- bind_rows(summary_aoi01, summary_aoi02, summary_aoi03)
print(summary_total)

# Summary chart: total vs affected buildings
ggplot(summary_total, aes(x = zone)) +
  geom_col(aes(y = nb_buildings_aoi), fill = "#AEC6CF", alpha = 0.9) +
  geom_col(aes(y = nb_buildings_flooded), fill = "#C23B22") +
  labs(
    title = "Buildings exposed to EMSR772 flooding - Yagoua 2024",
    subtitle = "Blue: total in the reference area | Red: affected by flooding",
    x = "AOI zone",
    y = "Number of buildings"
  ) +
  theme_minimal()

# Chart: share of flooded buildings by zone
ggplot(summary_total, aes(x = zone, y = pct_buildings_flooded)) +
  geom_col(fill = "#C23B22") +
  geom_text(
    aes(label = paste0(pct_buildings_flooded, "%")),
    vjust = -0.4,
    size = 3.5
  ) +
  labs(
    title = "Share of buildings affected by flooding",
    x = "AOI zone",
    y = "% of buildings flooded"
  ) +
  ylim(0, 100) +
  theme_minimal()

# Chart: population affected by zone
ggplot(
  summary_total %>%
    select(zone, pop_estimated_aoi, pop_flooded) %>%
    pivot_longer(-zone, names_to = "indicator", values_to = "population"),
  aes(x = zone, y = population, fill = indicator)
) +
  geom_col(position = "dodge") +
  scale_fill_manual(
    values = c(pop_estimated_aoi = "#AEC6CF", pop_flooded = "#C23B22"),
    labels = c(
      pop_estimated_aoi = "Total population (estimated)",
      pop_flooded = "Affected population (estimated)"
    )
  ) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Estimated population and affected population by zone",
    x = "AOI zone",
    y = "People",
    fill = NULL
  ) +
  theme_minimal()
