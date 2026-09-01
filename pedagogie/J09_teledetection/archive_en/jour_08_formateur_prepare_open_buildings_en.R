# Day 8 - Preparing Open Buildings data for the Yagoua area
# Trainer script only: no student version.
# To be run once, ahead of the "Floods and buildings" workshop,
# to keep only the building footprints located around the
# EMSR772 activation zone (Yagoua, Cameroon).

packages <- c("sf", "dplyr", "readr", "here")
to_install <- packages[!packages %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

library(sf)
library(dplyr)
library(readr)
library(here)

data_dir <- here("./jour_08_teledetection_observation_terre/data")

cat("Data folder:", data_dir, "\n")
cat("Files used:\n")
cat("  Open Buildings/*.csv.gz  (raw buildings, several tiles)\n")
cat("  EMSR772_products/EMSR772_AOI01_DEL_PRODUCT_v2/\n")
cat("    EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.shp\n")

# =========================================================================
# Step 1: build the "Yagoua" reference extent
# =========================================================================
# The EMSR772 activation actually covers 3 distinct localities, far apart
# from one another: AOI01 = Yagoua, AOI02 = Makari,
# AOI03 = Waza (up to ~300 km apart). To stay "around Yagoua",
# we only keep the AOI01 zone, with a 5 km buffer.

emsr_dir_01 <- file.path(
  data_dir, "EMSR772_products", "EMSR772_AOI01_DEL_PRODUCT_v2"
)

aoi01 <- st_read(
  file.path(emsr_dir_01, "EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.shp"),
  quiet = TRUE
)

cat("\nEMSR772 area of interest used: AOI01 (", aoi01$locality, ")\n")

aoi_yagoua <- aoi01 %>%
  st_buffer(dist = 5000) %>%
  st_as_sf()

cat("\nReference extent (AOI01 + 5 km buffer):\n")
print(st_bbox(aoi_yagoua))

# =========================================================================
# Step 2: process the Open Buildings tiles one by one, in streaming mode
# =========================================================================
# The raw CSV.GZ tiles are large (coverage far wider than just the Yagoua
# area; several GB per file). Two precautions to stay fast and light on
# memory:
#  1. read_csv_chunked() reads each tile in chunks instead of loading
#     everything into memory at once.
#  2. On each chunk, we first filter on the numeric "latitude"/"longitude"
#     columns (a simple, very fast comparison) to keep only the rows within
#     the Yagoua bbox, BEFORE converting anything to geometry. Converting a
#     WKT column into spatial objects (st_as_sf) is the expensive step: we
#     only do it on the small, already-filtered subset, never on the whole
#     tile.
# The bbox filter is approximate (a rectangle); it is then refined by an
# exact st_filter() against the aoi_yagoua polygon.

ob_dir   <- file.path(data_dir, "Open Buildings")
ob_files <- list.files(ob_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

cat("\nRaw Open Buildings files:", length(ob_files), "\n")
cat(paste0("  ", basename(ob_files)), sep = "\n")

bbox_yagoua  <- st_bbox(aoi_yagoua)
n_raw_total <- 0

buildings_yagoua_list <- lapply(seq_along(ob_files), function(i) {

  f <- ob_files[i]

  cat(sprintf("\n[%d/%d] %s\n", i, length(ob_files), basename(f)))

  filter_bbox <- function(chunk, pos) {
    n_raw_total <<- n_raw_total + nrow(chunk)
    chunk %>%
      filter(
        longitude >= bbox_yagoua["xmin"], longitude <= bbox_yagoua["xmax"],
        latitude  >= bbox_yagoua["ymin"], latitude  <= bbox_yagoua["ymax"]
      )
  }

  tile_bbox <- read_csv_chunked(
    f,
    callback   = DataFrameCallback$new(filter_bbox),
    chunk_size = 200000,
    show_col_types = FALSE
  )

  cat("  buildings within the Yagoua bbox:",
      format(nrow(tile_bbox), big.mark = " "), "\n")

  if (nrow(tile_bbox) == 0) return(NULL)

  tile_sf     <- st_as_sf(tile_bbox, wkt = "geometry", crs = 4326)
  tile_yagoua <- st_filter(tile_sf, aoi_yagoua)

  cat("  kept after exact filter on AOI01:",
      format(nrow(tile_yagoua), big.mark = " "), "\n")

  tile_yagoua
})

buildings_yagoua <- bind_rows(buildings_yagoua_list)

# =========================================================================
# Step 3: summary and export
# =========================================================================

cat("\n=== Summary ===\n")
cat("Total raw buildings (all tiles):",
    format(n_raw_total, big.mark = " "), "\n")
cat("Buildings kept around Yagoua:",
    format(nrow(buildings_yagoua), big.mark = " "), "\n")

cat("\nBreakdown by confidence level:\n")
buildings_yagoua %>%
  st_drop_geometry() %>%
  mutate(conf_class = cut(confidence, c(0, 0.5, 0.7, 1),
                           labels = c("<0.5", "0.5-0.7", ">0.7"),
                           include.lowest = TRUE)) %>%
  count(conf_class) %>%
  print()

out_gpkg <- file.path(ob_dir, "open_buildings_yagoua.gpkg")

st_write(buildings_yagoua, out_gpkg, delete_dsn = TRUE, quiet = TRUE)

cat("\nGeoPackage written:", out_gpkg, "\n")

# Trainer note:
# - Reading each tile in chunks (read_csv_chunked) and filtering first on
#   latitude/longitude, before any conversion to geometry, avoids paying
#   the cost of st_as_sf() on millions of polygons outside the zone.
#   This is what makes processing feasible on multi-GB tiles covering an
#   area far wider than Yagoua.
# - GeoPackage (.gpkg) is preferred over shapefile here: a single file (no
#   scattered .shp/.dbf/.shx/.prj), no truncation of column names to 10
#   characters, and no text field size limit.
# - This script is meant to be run once by the trainer: the resulting file
#   (much lighter than the raw CSV.GZ tiles) can then be used directly in
#   the workshop scripts, instead of reloading and refiltering all the
#   tiles every time.
# - Google Open Buildings is distributed under the CC BY 4.0 license: any
#   reuse must credit Google Research / Open Buildings.
