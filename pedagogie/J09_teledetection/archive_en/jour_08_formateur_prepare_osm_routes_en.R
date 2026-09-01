# Day 8 - Preparing the backup copy of the OpenStreetMap road network
# Trainer script only: no student version.
# To be run once (or to refresh the copy), to have a local copy
# of the OSM road network over the extent of the "Floods and buildings"
# workshop, used as a fallback if the Overpass API is
# unavailable during the session (see EXERCISE 7 in the main script).

packages <- c("sf", "dplyr", "osmdata", "here")
to_install <- packages[!packages %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

library(sf)
library(dplyr)
library(osmdata)
library(here)

data_dir <- here("./jour_08_teledetection_observation_terre/data")

cat("Data folder:", data_dir, "\n")
cat("Files used:\n")
cat("  EMSR772_products/EMSR772_AOI01_DEL_PRODUCT_v2/\n")
cat("    EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.shp\n")

# =========================================================================
# Step 1: rebuild the same extent as in the main workshop
# =========================================================================
# Important: this window must stay identical to the one used in
# jour_08_formateur_inondations.R (EXERCISE 7), otherwise the backup copy
# no longer matches the area the students explore.

emsr_dir_01 <- file.path(
  data_dir, "EMSR772_products", "EMSR772_AOI01_DEL_PRODUCT_v2"
)

aoi01 <- st_read(
  file.path(emsr_dir_01, "EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.shp"),
  quiet = TRUE
)

fenetre_zoom <- st_bbox(
  c(xmin = 15.31957, ymin = 10.22218, xmax = 15.36528, ymax = 10.26745),
  crs = st_crs(aoi01)
)
aoi01 <- aoi01 %>% st_intersection(st_as_sfc(fenetre_zoom))
bbox01 <- st_bbox(aoi01)

cat("\nQueried extent (bbox):\n")
print(bbox01)

# =========================================================================
# Step 2: query the Overpass API, with several attempts
# =========================================================================
# The public Overpass API has limited capacity: a single attempt sometimes
# fails (429 "too many requests", 504 "timeout"), and the osmdata
# package then retries internally with pauses that can
# last several minutes. We therefore cap each attempt at 30 seconds
# (setTimeLimit) and retry ourselves a few times with a short
# pause, rather than letting a single attempt drag on.

osm_query <- opq(bbox = bbox01) %>%
  add_osm_feature(key = "highway")

osm_data <- NULL
n_attempts <- 5

for (i in seq_len(n_attempts)) {
  cat("\nAttempt", i, "/", n_attempts, "...\n")
  osm_data <- tryCatch(
    {
      setTimeLimit(elapsed = 30, transient = TRUE)
      osmdata_sf(osm_query)
    },
    error = function(e) {
      cat("  failed:", conditionMessage(e), "\n")
      NULL
    },
    finally = setTimeLimit(elapsed = Inf, transient = FALSE)
  )
  if (!is.null(osm_data)) break
  if (i < n_attempts) Sys.sleep(10)
}

if (is.null(osm_data)) {
  stop(
    "OSM download failed after ", n_attempts, " attempts. ",
    "Try again later (the Overpass API is sometimes overloaded)."
  )
}

roads_osm <- osm_data$osm_lines

cat("\n=== Summary ===\n")
cat("Segments retrieved:", nrow(roads_osm), "\n")
cat("Breakdown by road type (highway):\n")
print(table(roads_osm$highway))

# =========================================================================
# Step 3: export
# =========================================================================

out_dir  <- file.path(data_dir, "OSM")
dir.create(out_dir, showWarnings = FALSE)
out_gpkg <- file.path(out_dir, "routes_aoi01_yagoua.gpkg")

st_write(roads_osm, out_gpkg, delete_dsn = TRUE, quiet = TRUE)

cat("\nGeoPackage written:", out_gpkg, "\n")

# Trainer note:
# - This script is meant to be run once by the trainer (or to refresh the
#   copy if the road network has changed on OSM): the resulting file
#   serves as a fallback in jour_08_formateur_inondations.R /
#   jour_08_etudiants_inondations.R when the Overpass API is unavailable.
# - GeoPackage (.gpkg) is preferred over shapefile here, for the same
#   reasons as the Open Buildings copy: a single file, no truncation of
#   column names, no text field size limit.
# - ODbL license: any reuse must credit OpenStreetMap and its
#   contributors.
