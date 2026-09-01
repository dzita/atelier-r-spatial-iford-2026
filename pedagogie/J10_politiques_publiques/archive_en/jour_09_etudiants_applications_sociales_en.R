# Day 9 - Spatial applications and social sciences
# Student script: ACLED (conflict) and ERA5 (temperature) in Cameroon,
# then Fay-Herriot small area estimation (food insecurity) in Benin

# ========== FILE STRUCTURE ==========

cat(paste(
  "",
  "jour_09_applications_spatiales_sciences_sociales/",
  "├── data/",
  "│   ├── ACLED Data.csv                       <- ACLED Explorer export (Part I, Cameroon)",
  "│   ├── gadm41_CMR.gpkg                      <- Cameroon administrative boundaries (GADM v4.1)",
  "│   ├── era5_t2m_mensuel_cameroun.nc         <- downloaded via ecmwfr (Part II, see Block B)",
  "│   ├── ehcvm2018_benin_menages.csv          <- geo-referenced EHCVM 2018-2019 households (Part III)",
  "│   ├── gadm_ben_communes.gpkg               <- Benin commune boundaries (admin2)",
  "│   ├── benin_grille_3km.gpkg                <- 3 km grid cells (Part III, Exercise 21)",
  "│   ├── benin_covariables_admin2.csv         <- geospatial covariates by commune (see Block C)",
  "│   ├── benin_covariables_grille.csv         <- geospatial covariates by grid cell",
  "│   └── benin_covariables_brutes_gee/        <- raw GEE covariates, not used in the example",
  "├── scripts_etudiants/",
  "│   └── jour_09_etudiants_applications_sociales_en.R  <- this file",
  "├── scripts_formateurs/",
  "│   ├── jour_09_formateur_applications_sociales_en.R",
  "│   ├── jour_09_formateur_acled_api_en.R     <- full API call (see Block A)",
  "│   └── jour_09_formateur_ecmwf_api_en.R     <- full API call (see Block B)",
  "└── outputs/",
  sep = "\n"
))

# ========== PACKAGES ==========

required_packages <- c(
  "sf",
  "sae",
  "survey",
  "dplyr",
  "tidyr",
  "ggplot2",
  "readr",
  "tmap",
  "scales",
  "terra",
  "exactextractr"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

library(sf)
library(sae) # must be loaded before dplyr (MASS masks select())
library(survey)
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(tmap)
library(scales)
library(terra)
library(exactextractr)

# Optional packages for the APIs
# install.packages("acledR")  # ACLED API
# install.packages("ecmwfr")  # Copernicus CDS API (ERA5)

data_dir <- "../data"
output_dir <- "../outputs"
dir.create(output_dir, showWarnings = FALSE)

current_year <- as.integer(format(Sys.Date(), "%Y"))
min_year <- current_year - 10

# ==========================================================================
#
#  PART I - ACLED: armed conflict data
#
# ==========================================================================

# =========================================================================
# BLOCK A. The ACLED API and the acledR package
# =========================================================================
#
# ACLED - Armed Conflict Location & Event Data Project
#   Website: https://acleddata.com/
#   Account: https://developer.acleddata.com/ (free)
#
# Event types:
#   Battles | Explosions/Remote violence | Violence against civilians
#   Riots   | Protests | Strategic developments
#
# Key columns:
#   event_date, event_type, sub_event_type, admin1, admin2,
#   location, latitude, longitude, fatalities
#
# API call with acledR:
#   acledR::acled_api(email, password, country, start_date, end_date)
#
# ---- Example API call (requires a myACLED account) --------------------
#
# acled_raw <- acledR::acled_api(
#   email      = "your@email.com",
#   password   = "your_password",
#   country    = "Cameroon",
#   start_date = paste0(min_year, "-01-01"),
#   end_date   = as.character(Sys.Date()),
#   monadic    = FALSE
# )
# write_csv(acled_raw, file.path(data_dir, "acled_cameroon_10ans.csv"))
#
# Full script (real API call, .env file handling):
#   scripts_formateurs/jour_09_formateur_acled_api_en.R
#
# For this workshop: use the provided CSV file (same format as the API).

# =========================================================================
# EXERCISE 1: Load and explore the ACLED data ----
# Read "ACLED Data.csv" with read_csv().
# Display the dimensions (nrow, ncol) and the structure with glimpse().
# =========================================================================

acled_csv <- file.path(data_dir, ___)

acled_raw <- read_csv(___, show_col_types = FALSE)

cat("Dimensions:", nrow(___), "rows ×", ncol(___), "columns\n\n")
glimpse(___)

# =========================================================================
# EXERCISE 2: Explore the columns and the available years ----
# Display all column names.
# Display the distinct years present in the "year" column.
# =========================================================================

print(names(___))

available_years <- sort(unique(acled_raw$___))
cat("\nAvailable years:", paste(available_years, collapse = ", "), "\n")

# =========================================================================
# 1. Cleaning and filtering
# =========================================================================

acled_clean <- acled_raw |>
  mutate(
    event_date = as.Date(event_date),
    year = as.integer(year),
    month = format(event_date, "%Y-%m"),
    fatalities = as.numeric(fatalities),
    longitude = as.numeric(longitude),
    latitude = as.numeric(latitude)
  ) |>
  filter(!is.na(longitude), !is.na(latitude))

cat(
  "\nTime range:",
  format(min(acled_clean$event_date), "%Y-%m-%d"),
  "to",
  format(max(acled_clean$event_date), "%Y-%m-%d"),
  "\n"
)

if (min(acled_clean$year) <= min_year) {
  acled_clean <- acled_clean |> filter(year >= min_year)
}

# =========================================================================
# EXERCISE 3: Event types and regions ----
# a) Count events by event_type, sorted in decreasing order.
# b) Count events by admin1 (region), sorted in decreasing order.
# =========================================================================

# a) Types
type_summary <- acled_clean |>
  count(___, sort = TRUE, name = "n_events")

print(type_summary)

# b) Regions
admin1_summary <- acled_clean |>
  count(___, sort = TRUE, name = "n_events")

print(admin1_summary)

# =========================================================================
# EXERCISE 4: Annual trend ----
# Create a summary by year AND by event_type (n_events).
# Visualise it with a stacked bar chart: x = year, fill = event_type.
# =========================================================================

annual_summary <- acled_clean |>
  count(___, ___, name = "n_events")

annual_plot <- ggplot(
  annual_summary,
  aes(x = ___, y = n_events, fill = ___)
) +
  geom_col() +
  scale_x_continuous(
    breaks = seq(min(annual_summary$year), max(annual_summary$year), by = 1)
  ) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Annual trend of conflicts in Cameroon",
    subtitle = "Source: ACLED",
    x = "Year",
    y = "Number of events",
    fill = "Type"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(annual_plot)

# =========================================================================
# EXERCISE 5: Annual deaths ----
# Calculate the total number of deaths (sum of fatalities) by year.
# Draw a line chart: x = year, y = deaths.
# =========================================================================

deaths_summary <- acled_clean |>
  group_by(___) |>
  summarise(deaths = sum(___, na.rm = TRUE), .groups = "drop")

deaths_plot <- ggplot(deaths_summary, aes(x = ___, y = ___)) +
  geom_line(colour = "#CB181D", linewidth = 1.2) +
  geom_point(colour = "#CB181D", size = 2.5) +
  scale_x_continuous(
    breaks = seq(min(deaths_summary$year), max(deaths_summary$year), by = 1)
  ) +
  labs(
    title = "Conflict-related deaths in Cameroon (source: ACLED)",
    x = "Year",
    y = "Number of deaths"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(deaths_plot)

# =========================================================================
# 2. Mapping ACLED
# =========================================================================

# Conversion to an sf layer
acled_points <- st_as_sf(
  acled_clean,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)

# Administrative boundaries
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

# =========================================================================
# EXERCISE 6: Map of events by type ----
# With tmap ("plot" mode), overlay:
#   1. The regions (cmr1): tm_borders()
#   2. The ACLED points coloured by event_type: tm_dots()
#   3. The national border (cmr0): tm_borders() with a thicker line
# =========================================================================

tmap_mode("plot")

types_map <- tm_shape(___) +
  tm_borders(col = "grey50", lwd = 0.8) +
  tm_shape(___) +
  tm_dots(
    fill = ___,
    size = 0.04,
    alpha = 0.6,
    fill.legend = tm_legend(title = "Event type")
  ) +
  tm_shape(___) +
  tm_borders(col = "grey20", lwd = 1.8) +
  tm_title("Armed conflicts in Cameroon (source: ACLED)") +
  tm_layout(legend.outside = TRUE)

print(types_map)

# =========================================================================
# EXERCISE 7: Choropleth map by region ----
# a) Spatial join (st_within) between acled_points and cmr1.
#    Group by NAME_1: calculate n_events and deaths.
# b) Join to cmr1 by "NAME_1" (left_join). Replace NA with 0.
# c) Choropleth map: fill = "n_events", palette "brewer.reds".
# =========================================================================

# a) Summary by region
region_summary <- acled_points |>
  st_join(cmr1[c("NAME_1")], join = ___) |>
  st_drop_geometry() |>
  filter(!is.na(NAME_1)) |>
  group_by(___) |>
  summarise(
    n_events = n(),
    deaths = sum(___, na.rm = TRUE),
    .groups = "drop"
  )

# b) Join with cmr1
cmr1_acled <- cmr1 |>
  left_join(___, by = ___) |>
  mutate(
    n_events = replace_na(n_events, 0L),
    deaths = replace_na(deaths, 0)
  )

# c) Map
regions_map <- tm_shape(___) +
  tm_polygons(
    fill = ___,
    fill.scale = tm_scale_continuous(values = "brewer.reds"),
    fill.legend = tm_legend(title = "Nb of events")
  ) +
  tm_borders(col = "white", lwd = 0.6) +
  tm_title("Conflicts by region - Cameroon (source: ACLED)") +
  tm_layout(legend.outside = TRUE)

print(regions_map)

# ==========================================================================
#
#  PART II - ERA5: temperature data
#
# ==========================================================================

# =========================================================================
# BLOCK B. ERA5 and the ecmwfr package
# =========================================================================
#
# ERA5 - ECMWF atmospheric reanalysis
#   Access: https://cds.climate.copernicus.eu/ (free account)
#
# Characteristics:
#   - Resolution: ~31 km (0.25°), coverage 1940-present
#   - Variables: temperature, precipitation, wind, humidity...
#   - Format: NetCDF (longitude × latitude × time)
#   - Temperatures in Kelvin -> convert to Celsius: T_C = T_K - 273.15
#
# Product used: ERA5 Single Levels Monthly Means
#   dataset_short_name: "reanalysis-era5-single-levels-monthly-means"
#   variable:           "2m_temperature"
#
# ecmwfr package:
#   install.packages("ecmwfr")
#   wf_set_key()  : store the CDS credentials in the keyring
#   wf_request()  : submit the request and download the NetCDF file
#
# Credentials to place in the .env file:
#   cds_user="123456"           <- numeric UID (CDS profile)
#   cds_key="xxxxxxxx-xxxx-..." <- API key (CDS profile)
#
# ---- Example request ----------------------------------------------------
#
# ecmwfr::wf_set_key(user = "123456", key = "xxx", service = "cds")
#
# request <- list(
#   dataset_short_name = "reanalysis-era5-single-levels-monthly-means",
#   product_type       = "monthly_averaged_reanalysis",
#   variable           = "2m_temperature",
#   year               = as.character((current_year - 10):(current_year - 1)),
#   month              = sprintf("%02d", 1:12),
#   time               = "00:00",
#   area               = c(13.1, 8.4, 1.6, 16.2),  # N, W, S, E (Cameroon)
#   data_format        = "netcdf",
#   target             = "era5_t2m_mensuel_cameroun.nc"
# )
#
# ecmwfr::wf_request(request = request, transfer = TRUE, path = data_dir)
#
# Full script (real API call, .env file handling):
#   scripts_formateurs/jour_09_formateur_ecmwf_api_en.R

# =========================================================================
# EXERCISE 8: Read the NetCDF file with terra ----
# Read the "era5_t2m_mensuel_cameroun.nc" file with rast().
# Display the number of layers, the resolution and the dates (time()).
# =========================================================================

nc_path <- file.path(data_dir, ___)

era5_raw <- rast(___)

cat("Number of layers:", nlyr(___), "\n")
cat("Resolution:       ", paste(res(___), collapse = " × "), "degrees\n")

# The dates of each layer
era5_dates <- as.Date(time(___))
cat("First layer:", format(min(era5_dates), "%Y-%m"), "\n")
cat("Last layer: ", format(max(era5_dates), "%Y-%m"), "\n")
cat("Original unit: Kelvin\n")

# =========================================================================
# EXERCISE 9: Convert to Celsius and crop to Cameroon ----
# a) Subtract 273.15 from the raster to convert Kelvin -> Celsius.
# b) Turn cmr0 into a SpatVector (vect + st_transform).
# c) Crop, then mask, the raster to the national outline.
# =========================================================================

# a) Kelvin -> Celsius conversion
era5_celsius <- era5_raw - ___

# b) National outline as a SpatVector
cmr0_vect <- vect(st_transform(cmr0, crs(___)))

# c) Cropping to Cameroon
era5_cmr <- mask(crop(___, ___), ___)

print(era5_cmr)

# =========================================================================
# EXERCISE 10: Quick visual check of the cropped raster ----
# Before going further, visually check the cropping result:
# display the first layer of era5_cmr with plot(), with a title that
# shows the corresponding month (era5_dates[1]).
# =========================================================================

plot(
  era5_cmr[[___]],
  main = paste("ERA5 T2m (°C):", format(era5_dates[___], "%Y-%m"))
)

# =========================================================================
# EXERCISE 11: Zonal extraction by region with exactextractr ----
# a) Reproject cmr1 into the raster's CRS (st_transform + crs()).
# b) Extract the mean of each layer by region with exact_extract().
# c) Reshape to long format with pivot_longer:
#    - cols     = -NAME_1
#    - names_to = "layer"
#    - values_to = "t2m_celsius"
#    Add the idx, date, year, month columns from era5_dates.
#    Careful: the layer name is not a plain integer (e.g. "t2m_1"),
#    recover idx by matching against names(era5_cmr) with match().
# =========================================================================

# a) Reprojection
cmr1_proj <- st_transform(cmr1, crs(___))

# b) Zonal extraction: one row per region, one column per layer
t2m_extracted <- exact_extract(___, ___, "mean")

# c) Reshape to long format
t2m_long <- cmr1 |>
  st_drop_geometry() |>
  select(NAME_1) |>
  bind_cols(t2m_extracted) |>
  pivot_longer(
    cols = -NAME_1,
    names_to = "layer",
    values_to = ___
  ) |>
  mutate(
    idx = match(layer, paste0("mean.", ___)),
    date = era5_dates[___],
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m"))
  ) |>
  select(-layer, -idx)

cat("Extraction complete:", nrow(t2m_long), "rows\n")
glimpse(___)

# =========================================================================
# EXERCISE 12: National time series ----
# Calculate the national monthly mean (mean of t2m_celsius by date).
# Draw a line chart: x = date, y = t2m_mean.
# Add a smoothed trend with geom_smooth(method = "loess").
# =========================================================================

t2m_national <- t2m_long |>
  group_by(___) |>
  summarise(t2m_mean = mean(___, na.rm = TRUE), .groups = "drop")

t2m_series_plot <- ggplot(t2m_national, aes(x = ___, y = ___)) +
  geom_line(colour = "#2171B5", linewidth = 0.7) +
  geom_smooth(
    method = "loess",
    se = FALSE,
    colour = "#CB181D",
    linetype = "dashed",
    linewidth = 0.9
  ) +
  labs(
    title = "Trend of 2m temperature in Cameroon",
    subtitle = "National monthly mean (source: ERA5). Red line: smoothed trend.",
    x = "Date",
    y = "Temperature (°C)"
  ) +
  theme_minimal()

print(t2m_series_plot)

# =========================================================================
# EXERCISE 13: Seasonality ----
# Calculate the mean, min and max temperature by month (1-12)
# aggregating across all years and all regions.
# Draw a line with a ribbon (geom_ribbon) for the amplitude.
# =========================================================================

t2m_seasonality <- t2m_long |>
  group_by(___) |>
  summarise(
    t2m_mean = mean(___, na.rm = TRUE),
    t2m_min = min(___, na.rm = TRUE),
    t2m_max = max(___, na.rm = TRUE),
    .groups = "drop"
  )

seasonality_plot <- ggplot(t2m_seasonality, aes(x = month, y = t2m_mean)) +
  geom_ribbon(aes(ymin = ___, ymax = ___), fill = "#FDBB84", alpha = 0.4) +
  geom_line(colour = "#D94801", linewidth = 1) +
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  labs(
    title = "Seasonality of 2m temperature - Cameroon",
    subtitle = "Source: ERA5",
    x = "Month",
    y = "Temperature (°C)"
  ) +
  theme_minimal()

print(seasonality_plot)

# =========================================================================
# EXERCISE 14: Map of the mean temperature ----
# Calculate the mean of the raster across all layers with mean().
# Create a tmap map with tm_raster() and the reversed palette
# "-brewer.rd_yl_bu" (the "-" prefix reverses the colour gradient).
# Overlay the cmr1 and cmr0 boundaries.
# =========================================================================

t2m_mean_rast <- mean(___)

t2m_mean_map <- tm_shape(___) +
  tm_raster(
    col.scale = tm_scale_continuous(
      values = ___
    ),
    col.legend = tm_legend(title = "T°C")
  ) +
  tm_shape(cmr1) +
  tm_borders(col = "grey40", lwd = 0.8) +
  tm_shape(cmr0) +
  tm_borders(col = "grey10", lwd = 1.8) +
  tm_title("Mean 2m temperature - Cameroon (source: ERA5)") +
  tm_layout(legend.outside = TRUE)

print(t2m_mean_map)

# =========================================================================
# 3. Export
# =========================================================================

# ACLED
st_write(
  acled_points,
  file.path(output_dir, "jour09_acled_points.gpkg"),
  delete_dsn = TRUE
)
st_write(
  cmr1_acled,
  file.path(output_dir, "jour09_acled_regions.gpkg"),
  delete_dsn = TRUE
)
write_csv(type_summary, file.path(output_dir, "jour09_acled_resume_types.csv"))
write_csv(
  region_summary,
  file.path(output_dir, "jour09_acled_resume_regions.csv")
)

ggsave(
  file.path(output_dir, "jour09_acled_annuel.png"),
  annual_plot,
  width = 10,
  height = 6,
  dpi = 180
)
ggsave(
  file.path(output_dir, "jour09_acled_deces.png"),
  deaths_plot,
  width = 8,
  height = 5,
  dpi = 180
)

tmap_save(
  types_map,
  file.path(output_dir, "jour09_acled_carte_types.png"),
  width = 1800,
  height = 1400,
  dpi = 200
)
tmap_save(
  regions_map,
  file.path(output_dir, "jour09_acled_carte_regions.png"),
  width = 1400,
  height = 1600,
  dpi = 200
)

# ERA5
write_csv(
  t2m_long,
  file.path(output_dir, "jour09_era5_t2m_mensuel_regions.csv")
)
write_csv(
  t2m_national,
  file.path(output_dir, "jour09_era5_t2m_mensuel_national.csv")
)

writeRaster(
  t2m_mean_rast,
  file.path(output_dir, "jour09_era5_t2m_moyenne.tif"),
  overwrite = TRUE
)

ggsave(
  file.path(output_dir, "jour09_era5_serie_nationale.png"),
  t2m_series_plot,
  width = 10,
  height = 5,
  dpi = 180
)
ggsave(
  file.path(output_dir, "jour09_era5_saisonnalite.png"),
  seasonality_plot,
  width = 8,
  height = 5,
  dpi = 180
)

tmap_save(
  t2m_mean_map,
  file.path(output_dir, "jour09_era5_carte_t2m.png"),
  width = 1400,
  height = 1600,
  dpi = 200
)

# ==========================================================================
#
#  PART III - Small area estimation (Fay-Herriot)
#
# ==========================================================================

# =========================================================================
# BLOCK C. Principle of small area estimation (SAE)
# =========================================================================
#
# Problem: a national survey (e.g. DHS) is representative at the national
# level and sometimes at the regional level, but in small regions (few
# women surveyed), the direct estimate (proportion observed in the
# sample) is very noisy: its sampling variance is large.
#
# Small Area Estimation (SAE) combines:
#   1. the direct estimate p_i (observed in each region i)
#   2. its known (or approximated) sampling variance psi_i
#   3. an auxiliary covariate x_i, known for ALL regions
#      (census, satellite imagery, another administrative source...)
#
# Fay-Herriot model (1979), at the domain (region) level:
#   p_i = x_i'beta + u_i + e_i
#     u_i ~ N(0, sigma2_u)   between-region variance (to be estimated)
#     e_i ~ N(0, psi_i)      sampling variance (known/approximated)
#
# The EBLUP estimator ("Empirical Best Linear Unbiased Predictor") is a
# weighted average between the direct estimate p_i and the model
# prediction x_i'beta:
#   - if psi_i is large (small sample)  -> the estimate is pulled towards
#     the model prediction ("borrowing strength" from other regions)
#   - if psi_i is small (large sample)  -> the direct estimate is already
#     reliable, little correction
#
# Two distinct problems, one shared solution:
#   1. PRECISION - the direct estimate p_i is noisy in domains with a
#      small sample. Fay-Herriot smooths it by borrowing strength from a
#      model (above). Result: a more reliable figure, but still ONE
#      figure per domain, at the same geographic resolution as before
#      (Exercises 16-18).
#   2. RESOLUTION - even a perfectly precise figure per domain remains an
#      average over its whole area: the survey says nothing about
#      variation within a domain (e.g. an 800 km² commune with a dense
#      town and empty rural areas, where perhaps no household was
#      surveyed). Since the auxiliary covariate itself varies
#      continuously in space (3 km grid), applying the relationship fitted
#      by Fay-Herriot to each cell rather than the commune average
#      produces a surface finer than the survey itself. This is not a new
#      measurement, but an extrapolation of the model (Exercise 21).
#   Both rely on the same principle: use a covariate known EVERYWHERE to
#   compensate for what the survey cannot say on its own, whether from a
#   lack of precision or a lack of resolution.
#
# sae package (CRAN): install.packages("sae")
#   mseFH(formula, vardir, data)  fits the model AND computes the
#   estimated mean squared error (MSE) of each smoothed estimate. The
#   fitted model returned (fh$est$fit) also includes goodness-of-fit
#   measures (fh$est$fit$goodness: log-likelihood, AIC, BIC, KIC), useful
#   for comparing several specifications (with/without a covariate,
#   another covariate...). The B argument (0 by default) also allows
#   bootstrap-corrected versions of these criteria to be computed
#   (Marhuenda et al., 2014), not used here to keep the example simple.
#
# Data used here (Benin, no longer Cameroon for this part):
#   - Direct estimate: share of households in food insecurity, by
#     commune (admin2), Enquête Harmonisée sur les Conditions de Vie des
#     Ménages (EHCVM) 2018-2019, Benin. Geo-referenced household data
#     (replication of J. Merfeld, github.com/JoshMerfeld/saereplication).
#     Calculated directly from the survey weights (hhweight) and the
#     clusters (grappe) with the survey package, NO approximation here,
#     unlike the previous example (see Exercise 16).
#   - Sample size: actual number of households surveyed per commune
#     (between 36 and 745 depending on the commune), read directly from
#     the data, not approximated.
#   - Direct variance: actual standard error of the survey estimator
#     (survey::svyby), which accounts for the cluster sampling design.
#     A few communes have only a single surveyed cluster: their variance
#     is not estimable and they are removed before fitting the model
#     (see Exercise 16).
#   - Auxiliary covariates: chosen by a correlation screening (Exercise
#     17) among geospatial covariates extracted via Google Earth Engine
#     (night-time lights, population, NDVI vegetation, rainfall, air
#     pollution, MODIS land cover), all available both by commune (to fit
#     the model) and by 3 km grid cell (for the fine-scale prediction,
#     Exercise 21). Two are retained: share of urban land and share of
#     wooded savanna (MODIS LC_Type1 land cover). With 76 communes, do
#     not expect an established causal effect: the goal is to understand
#     the mechanism.
#     Script showing how these covariates are extracted from GEE
#     (illustrative R code with rgee, untested, for teaching purposes):
#     scripts_formateurs/jour_09_formateur_gee_api_en.R
#
# Source and acknowledgements: this workshop reuses the data and
# extraction code from the github.com/JoshMerfeld/saereplication
# repository (Josh Merfeld, University of Queensland), which documents a
# small area estimation for Benin, thanks to the author for making this
# material public and reproducible.
#   - Household survey: Enquête Harmonisée sur les Conditions de Vie des
#     Ménages (EHCVM) 2018-2019, Benin. Microdata:
#     https://microdata.worldbank.org/index.php/catalog/4291
#   - Geospatial covariates: extracted from Google Earth Engine by the
#     repository's author (original JavaScript scripts in
#     scripts/gee/*.js of the repository), translated here into R for
#     illustration (see jour_09_formateur_gee_api_en.R above).
#   - No licence is indicated on the original repository: this data is
#     used here strictly for teaching purposes, not for an operational
#     decision.
#   - Adapted method, not reproduced identically: the original repository
#     fits a UNIT-level model (Empirical Best Prediction, povmap package,
#     covariates selected by Lasso with cross-validation), a richer but
#     more complex method. This workshop deliberately simplifies to an
#     AREA-level model (Fay-Herriot, sae package) to stay pedagogical: the
#     coefficients and maps obtained here therefore do NOT reproduce
#     those of the original repository.
#
# Grid resolution: 3 km x 3 km (~15,400 cells for all of Benin), NOT
# 100 m. This is a choice made by the original repository's author for
# the GEE covariate extraction (trade-off between spatial detail and
# computing time over the whole country), unrelated to the resolution of
# the population rasters seen on Day 7 (GHS-POP, WorldPop, 100 m): these
# are two different grids, not to be confused.
#
# Limitations to keep in mind:
#   - The grid-scale prediction (Exercise 21) is an extrapolation of the
#     communal model, not a new measurement (see the "Two distinct
#     problems, one shared solution" block above and Exercise 21).
#   - 76 communes and two covariates: limited statistical power to
#     validate these covariates (see Exercise 18).
#   - Method simplified compared to the original repository (area-level
#     model rather than unit-level, see above): a real operational
#     project would instead use the unit-level model (EBP/povmap) and a
#     more rigorous covariate selection (Lasso with cross-validation)
#     than a simple correlation screening (Exercise 17).

# =========================================================================
# EXERCISE 15: Load the data (households, boundaries, covariates) ----
# a) Read "ehcvm2018_benin_menages.csv" (geo-referenced households) with
#    read_csv(). Display the dimensions and the structure with glimpse().
# b) Read the commune boundaries ("gadm_ben_communes.gpkg") and the 3 km
#    grid ("benin_grille_3km.gpkg") with st_read().
# c) Read the covariates by commune ("benin_covariables_admin2.csv") and
#    by grid cell ("benin_covariables_grille.csv").
# =========================================================================

households_csv <- file.path(data_dir, ___)

households <- read_csv(___, show_col_types = FALSE)

cat(
  "Dimensions EHCVM households:",
  nrow(___),
  "rows ×",
  ncol(___),
  "columns\n\n"
)
glimpse(___)

ben_communes <- st_read(
  file.path(data_dir, "gadm_ben_communes.gpkg"),
  layer = "ben_adm2_communes",
  quiet = TRUE
)
ben_grid <- st_read(
  file.path(data_dir, "benin_grille_3km.gpkg"),
  layer = "grille_3km",
  quiet = TRUE
)

cat(
  "\nCommunes:",
  nrow(ben_communes),
  " | Grid cells (3 km):",
  nrow(ben_grid),
  "\n"
)

# These two files are already pre-processed (one value per commune / per
# grid cell), the raw extraction from Google Earth Engine is not redone
# here so as to stay focused on SAE. This pre-processing, however, needs
# nothing new: it is the same zonal statistics logic already practised
# today (st_join() in Part I to aggregate ACLED by region, exact_extract()
# in Part II for ERA5), with the skills from the previous workshops, this
# work is within reach of participants. See
# scripts_formateurs/jour_09_formateur_gee_api_en.R for the corresponding
# extraction code (illustrative, untested).
covariates_admin2 <- read_csv(
  file.path(data_dir, "benin_covariables_admin2.csv"),
  show_col_types = FALSE
)
covariates_grid <- read_csv(
  file.path(data_dir, "benin_covariables_grille.csv"),
  show_col_types = FALSE
)

cat("\nCovariates by commune:\n")
glimpse(covariates_admin2)
cat("\nCovariates by grid cell:\n")
glimpse(covariates_grid)

# =========================================================================
# EXERCISE 16: Attach households to their commune and estimate ----
# a) Join households to covariates_grid (id, admin2Pcod columns) by "id"
#    to know the commune of each household.
# b) Build the sampling design with survey::svydesign() (ids = grappe,
#    weights = hhweight) then the weighted direct estimate by commune
#    with svyby(~insecure, ~admin2Pcod, plan, svymean). Use coef() and
#    SE() to recover the estimate and its standard error (in %).
# c) Count the number of households per commune (n_households) and
#    calculate var_direct = se_direct^2. Remove communes where se_direct
#    is NA or zero (a single surveyed cluster: variance not estimable).
# =========================================================================

households_admin2 <- households |>
  left_join(
    covariates_grid |> select(id, admin2Pcod) |> distinct(),
    by = ___
  )

cat(
  "\nHouseholds without a commune after the join:",
  sum(is.na(households_admin2$admin2Pcod)),
  "\n"
)

# svydesign() computes nothing itself: it describes the sampling design so
# that the survey:: functions that follow automatically take it into
# account.
#   - weights = ~hhweight : each household does not count as 1 but as its
#     sampling weight (some household profiles are over- or
#     under-represented in the sample; the weight corrects this bias, an
#     unweighted mean(insecure) would be biased).
#   - ids = ~grappe : declares that households are grouped by cluster
#     (primary sampling unit). Two households from the same cluster
#     resemble each other more than two households picked at random (same
#     neighbourhood, same conditions), ignoring this structure would give
#     an artificially small (overly optimistic) standard error.
sampling_design <- svydesign(
  ids = ~___,
  weights = ~___,
  data = households_admin2
)

# svyby() applies an estimation function (here svymean, the weighted mean
# of insecure) SEPARATELY for each commune (~admin2Pcod), respecting the
# sampling design above. It is the equivalent, with weights and cluster
# effects, of a group_by(admin2Pcod) |> summarise(mean(...)), but
# group_by()+mean() would ignore weights and clusters, and would give a
# biased insecure_direct with an underestimated standard error.
direct_svy <- svyby(~___, ~admin2Pcod, sampling_design, svymean)

n_households_admin2 <- households_admin2 |>
  count(admin2Pcod, name = "n_households")

direct_admin2 <- data.frame(
  admin2Pcod = direct_svy$admin2Pcod,
  insecure_direct = coef(direct_svy) * ___,
  se_direct = SE(direct_svy) * ___
) |>
  left_join(n_households_admin2, by = "admin2Pcod")

cat(
  "\nCommunes with a non-estimable direct variance (single cluster):",
  sum(is.na(direct_admin2$se_direct) | direct_admin2$se_direct == 0),
  "\n"
)

direct_admin2 <- direct_admin2 |>
  filter(!is.na(se_direct), se_direct > ___) |>
  mutate(var_direct = se_direct^___)

cat("\nCommunes kept for the model:", nrow(direct_admin2), "\n")
print(direct_admin2)

# =========================================================================
# EXERCISE 17: Selecting the auxiliary covariates ----
# a) Join direct_admin2 to covariates_admin2 (by admin2Pcod).
# b) Calculate, for each candidate covariate, its correlation with
#    insecure_direct (cor()). Sort by decreasing absolute value.
# c) Keep the two most correlated covariates that are not too correlated
#    with each other (collinearity).
# =========================================================================

sae_data_candidates <- direct_admin2 |>
  left_join(___, by = "admin2Pcod")

candidates <- c(
  "ntl_mean_adm2",
  "population_adm2",
  "ndvi_mean_adm2",
  "precip_2018_adm2",
  "no2_adm2",
  "lc_13_urbain_adm2",
  "lc_12_cultures_adm2",
  "lc_8_savane_boisee_adm2",
  "lc_11_zones_humides_adm2"
)

correlations <- sapply(
  candidates,
  function(v) cor(___, sae_data_candidates[[v]])
)
correlations <- correlations[order(-abs(___))]

cat(
  "\nCorrelation with the direct food insecurity estimate (all covariates):\n"
)
print(round(correlations, 3))

cat(
  "\nCorrelation between the two selected covariates (collinearity):",
  round(cor(sae_data_candidates$___, sae_data_candidates$___), 2),
  "\n"
)

# Selected: lc_13_urbain_adm2 (share of urban land, MODIS LC_Type1
# class 13) and lc_8_savane_boisee_adm2 (share of wooded savanna, class 8).
sae_data <- sae_data_candidates |>
  select(
    admin2Pcod,
    n_households,
    insecure_direct,
    se_direct,
    var_direct,
    ___,
    ___
  ) |>
  as.data.frame()

# =========================================================================
# EXERCISE 18: Fit the Fay-Herriot model ----
# a) Use sae::mseFH() with the formula
#    insecure_direct ~ lc_13_urbain_adm2 + lc_8_savane_boisee_adm2 and
#    vardir = var_direct. Extract the EBLUP (fh$est$eblup) and the MSE
#    (fh$mse) to create the insecure_fh and rmse_fh columns.
# b) Calculate gain_rmse = rmse_direct - rmse_fh.
# c) Display the coefficients (fh$est$fit$estcoef) and the goodness-of-fit
#    measures (fh$est$fit$goodness).
# =========================================================================

fh <- mseFH(___ ~ ___ + ___, vardir = ___, data = sae_data)

sae_data <- sae_data |>
  mutate(
    insecure_fh = fh$est$eblup[, 1],
    rmse_direct = sqrt(var_direct),
    rmse_fh = sqrt(___),
    gain_rmse = ___ - ___
  )

print(
  sae_data |>
    select(
      admin2Pcod,
      n_households,
      insecure_direct,
      rmse_direct,
      insecure_fh,
      rmse_fh,
      gain_rmse
    )
)

cat(
  "\nAverage precision gain (RMSE direct - RMSE FH):",
  round(mean(sae_data$gain_rmse), 3),
  "\n"
)

cat(
  "\nModel coefficients (covariates: urban share, wooded savanna share):\n"
)
print(fh$est$fit$estcoef)

# Reading the coefficient table (beta, std.error, tvalue, pvalue columns):
#   - The sign of each beta should match the correlation found in
#     Exercise 17: positive beta for lc_13_urbain_adm2 (more urban
#     communes have higher direct food insecurity) and negative beta for
#     lc_8_savane_boisee_adm2 (more wooded communes have lower
#     insecurity). If a sign is reversed compared to Exercise 17, it is a
#     sign of collinearity or a confounding effect between the two
#     covariates worth investigating.
#   - The pvalue column tests whether each beta differs from 0. With only
#     76 communes and two covariates, do not over-interpret a negligible
#     p: statistical power remains limited (see Block C).
#
# fh$est$fit$goodness (log-likelihood, AIC, BIC, KIC) has no meaning in
# absolute terms: these indicators are used to COMPARE several
# specifications against each other (e.g. with vs without the second
# covariate, or another pair of covariates), the model with the lowest
# AIC/BIC is preferred. A possible extension: rerun mseFH() with a single
# term (insecure_direct ~ lc_13_urbain_adm2) and compare its AIC/BIC to
# that of the two-covariate model above.
cat("\nModel goodness-of-fit measures (log-likelihood, AIC, BIC, KIC):\n")
print(fh$est$fit$___)

# gain_rmse (calculated above) is the true measure of the SAE "result":
# positive -> the Fay-Herriot estimate is more precise (lower RMSE) than
# the direct estimate for that commune; close to 0 -> the model brings
# almost nothing (the direct estimate was already reliable, cf. Exercise
# 19, the gain should be concentrated in communes with low n_households).
# A modest average gain is not a model failure: it means that the
# variance BETWEEN communes (real heterogeneity of food insecurity)
# dominates the SAMPLING variance, in that case, the direct estimate was
# already close to the truth for most communes, and there is not much to
# correct.

# =========================================================================
# EXERCISE 19: Compare direct and Fay-Herriot estimates ----
# a) Join sae_data to the commune names (adm2_name) from ben_communes.
# b) Reshape to long format with pivot_longer (names_pattern) to obtain
#    "method" (direct / fh), "insecure" and "rmse". Draw a point-range
#    plot (geom_pointrange), x = commune (sorted by insecure), y =
#    insecure, coloured by method.
# c) Draw a scatter plot of gain_rmse vs n_households (log scale on x):
#    the Fay-Herriot precision gain should be larger for the
#    least-sampled communes, this is the very mechanism of SAE.
# =========================================================================

comparison_long <- sae_data |>
  left_join(
    st_drop_geometry(ben_communes) |> select(admin2Pcod, adm2_name),
    by = "admin2Pcod"
  ) |>
  select(adm2_name, insecure_direct, rmse_direct, insecure_fh, rmse_fh) |>
  pivot_longer(
    cols = -adm2_name,
    names_to = c(".value", "method"),
    names_pattern = ___
  ) |>
  mutate(
    method = recode(
      method,
      direct = "Direct estimate",
      fh = "Fay-Herriot (EBLUP)"
    )
  )

comparison_plot <- ggplot(
  comparison_long,
  aes(
    x = reorder(___, insecure),
    y = ___,
    ymin = insecure - 1.96 * rmse,
    ymax = insecure + 1.96 * rmse,
    colour = ___
  )
) +
  geom_pointrange(position = position_dodge(width = 0.5), size = 0.25) +
  coord_flip() +
  labs(
    title = "Food insecurity by commune - Benin",
    subtitle = "Direct estimate (EHCVM 2018-2019) vs Fay-Herriot - 95% intervals",
    x = NULL,
    y = "Households in food insecurity (%)",
    colour = NULL
  ) +
  theme_minimal(base_size = 8)

print(comparison_plot)

# Reading the plot (a pair of points per commune, sorted bottom to top by
# average insecurity):
#   - Direct and FH points close to each other -> the model barely
#     corrected this commune: its direct estimate was already reliable
#     (large sample, or already close to what the covariate predicts).
#   - Direct and FH points far apart -> the estimate was strongly pulled
#     towards the model prediction: a sign of a small sample (check
#     n_households for that commune) and/or a large gap between the
#     observed value and what the covariates predict.
#   - FH interval visibly shorter than the direct interval for the same
#     commune: that is the precision gain (rmse_fh < rmse_direct) made
#     visible, the interval does not necessarily shorten for EVERY
#     commune (see Exercise 18: a positive average gain does not prevent
#     a few individual communes from barely moving).

gain_vs_n_plot <- ggplot(sae_data, aes(x = ___, y = ___)) +
  geom_point(colour = "#2171B5", size = 2.2, alpha = 0.7) +
  geom_smooth(
    method = "loess",
    se = FALSE,
    colour = "#CB181D",
    linetype = "dashed"
  ) +
  scale_x_log10() +
  labs(
    title = "The Fay-Herriot precision gain is larger in poorly sampled communes",
    subtitle = "Each point = one commune",
    x = "Number of households surveyed (log scale)",
    y = "Precision gain (RMSE direct - RMSE FH)"
  ) +
  theme_minimal()

print(gain_vs_n_plot)

# This scatter plot is the true test of the SAE mechanism, not just an
# illustration: if the Fay-Herriot smoothing works as expected, the loess
# curve should DECREASE (larger precision gain on the left, where
# n_households is small, than on the right). A flat curve or one with no
# clear trend would suggest that the selected covariates bring little
# value. A point below 0 (negative gain, meaning FH is LESS precise than
# direct for that commune) remains possible but should stay rare and
# close to 0: it indicates a commune where the covariate poorly predicts
# the observed value, without the sample being small enough to be
# compensated by the smoothing.

# =========================================================================
# EXERCISE 20: Map direct vs Fay-Herriot estimates ----
# a) Join sae_data to ben_communes (by admin2Pcod).
# b) Create three tmap maps (tm_polygons): insecure_direct and
#    insecure_fh with the SAME colour scale (calculated with range() on
#    both variables, so they can be compared visually), and gain_rmse
#    with a diverging scale centred on 0 (the true SAE "result": where is
#    the precision gain concentrated?).
# c) Arrange the three maps side by side with tmap_arrange().
# =========================================================================

communes_sae <- ben_communes |> left_join(___, by = "admin2Pcod")

insecurity_limits <- range(c(communes_sae$___, communes_sae$___), na.rm = TRUE)

direct_map <- tm_shape(communes_sae) +
  tm_polygons(
    fill = ___,
    fill.scale = tm_scale_continuous(
      values = "brewer.blues",
      limits = insecurity_limits
    ),
    fill.legend = tm_legend(title = "Food insecurity\ndirect (%)")
  ) +
  tm_borders(col = "white", lwd = 0.4) +
  tm_title("Direct estimate")

fh_map <- tm_shape(communes_sae) +
  tm_polygons(
    fill = ___,
    fill.scale = tm_scale_continuous(
      values = "brewer.blues",
      limits = insecurity_limits
    ),
    fill.legend = tm_legend(title = "Food insecurity\nFay-Herriot (%)")
  ) +
  tm_borders(col = "white", lwd = 0.4) +
  tm_title("Fay-Herriot estimate")

gain_map <- tm_shape(communes_sae) +
  tm_polygons(
    fill = "gain_rmse",
    fill.scale = tm_scale_continuous(values = "-brewer.rd_bu", midpoint = ___),
    fill.legend = tm_legend(
      title = "Precision gain\n(RMSE direct - RMSE FH)"
    )
  ) +
  tm_borders(col = "white", lwd = 0.4) +
  tm_title("Precision gain")

sae_map <- tmap_arrange(___, ___, ___, ncol = 3)
print(sae_map)

# =========================================================================
# EXERCISE 21: Predict at the grid scale (3 km) ----
# The Fay-Herriot model is fitted at the commune level (Exercise 18), but
# its coefficients (fh$est$fit$estcoef[, "beta"]) and the commune random
# effect it implies can be applied to the covariate values of EACH GRID
# CELL (3 km), to obtain a map at a resolution finer than the survey
# itself, the "small area" result in the spatial sense, not just the
# statistical sense.
# a) Extract the beta0, beta_lc13, beta_lc8 coefficients from
#    fh$est$fit$estcoef[, "beta"].
# b) Reconstruct the commune random effect:
#    u_hat = insecure_fh - (beta0 + beta_lc13*lc_13_urbain_adm2 +
#                            beta_lc8*lc_8_savane_boisee_adm2)
# c) Join u_hat to covariates_grid (by admin2Pcod) and calculate
#    insecure_pred = beta0 + beta_lc13*lc_13_urbain + beta_lc8*lc_8_savane_boisee + u_hat
# d) Map insecure_pred on ben_grid (same colour scale as the commune
#    maps, for comparison).
# =========================================================================

betas <- fh$est$fit$estcoef[, "beta"]
beta0 <- betas[___]
beta_lc13 <- betas[___]
beta_lc8 <- betas[___]

sae_data <- sae_data |>
  mutate(
    u_hat = insecure_fh -
      (beta0 +
        beta_lc13 * lc_13_urbain_adm2 +
        beta_lc8 * lc_8_savane_boisee_adm2)
  )

grid_pred <- covariates_grid |>
  left_join(sae_data |> select(admin2Pcod, u_hat), by = "admin2Pcod") |>
  filter(!is.na(u_hat)) |>
  mutate(
    insecure_pred = ___ + ___ * lc_13_urbain + ___ * lc_8_savane_boisee + ___
  )

cat(
  "\nGrid-scale prediction:",
  nrow(grid_pred),
  "cells out of",
  nrow(covariates_grid),
  "(communes without an estimable direct variance excluded)\n"
)

grid_sae <- ben_grid |>
  inner_join(grid_pred |> select(id, insecure_pred), by = ___)

grid_map <- tm_shape(grid_sae) +
  tm_fill(
    fill = "insecure_pred",
    fill.scale = tm_scale_continuous(
      values = "brewer.blues",
      limits = insecurity_limits
    ),
    fill.legend = tm_legend(title = "Food insecurity\npredicted (%)")
  ) +
  tm_shape(ben_communes) +
  tm_borders(col = "grey20", lwd = 0.6) +
  tm_title("Fay-Herriot prediction at the grid scale (3 km)") +
  tm_layout(legend.outside = TRUE)

print(grid_map)

# WARNING - this map is the most visually impressive one in the whole
# workshop, but also the least measured: each 3 km cell shows a value
# PREDICTED by a model fitted on only 76 communes (Exercise 18), not a
# field observation. The smooth, continuous rendering can give a false
# impression of fine precision, worth reminding participants: this map
# shows what the covariate-food insecurity relationship predicts inside
# each commune, not what was measured at that resolution (see
# "Limitations to keep in mind", Block C, and Exercise 21).

# =========================================================================
# 4. SAE export
# =========================================================================

write_csv(
  sae_data,
  file.path(output_dir, "jour09_sae_estimations_communes.csv")
)
write_csv(
  grid_pred |> select(id, admin2Pcod, insecure_pred),
  file.path(output_dir, "jour09_sae_estimations_grille.csv")
)

ggsave(
  file.path(output_dir, "jour09_sae_comparaison.png"),
  comparison_plot,
  width = 8,
  height = 12,
  dpi = 180
)
ggsave(
  file.path(output_dir, "jour09_sae_gain_vs_echantillon.png"),
  gain_vs_n_plot,
  width = 8,
  height = 5,
  dpi = 180
)

tmap_save(
  sae_map,
  file.path(output_dir, "jour09_sae_cartes_communes.png"),
  width = 2400,
  height = 1000,
  dpi = 200
)
tmap_save(
  grid_map,
  file.path(output_dir, "jour09_sae_carte_grille.png"),
  width = 1600,
  height = 1600,
  dpi = 200
)
