# Day 7 - High-resolution population mapping
# Student script: choropleth, WorldPop grids and custom areas

packages <- c(
  "sf",
  "dplyr",
  "ggplot2",
  "tidyr",
  "readr",
  "terra",
  "tmap",
  "exactextractr",
  "scales",
  "mapedit"
)
to_install <- packages[!packages %in% rownames(installed.packages())]
if (length(to_install) > 0) {
  install.packages(to_install)
}

library(sf)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)
library(terra)
library(tmap)
library(exactextractr)
library(scales)
library(mapedit)
library(here)

data_dir <- here("./jour_07_cartographie_population_haute_resolution/data")
output_dir <- here("./jour_07_cartographie_population_haute_resolution/outputs")
dir.create(output_dir, showWarnings = FALSE)

# --- Folder structure ---
cat("Data folder:", data_dir, "\n")
cat("Output folder:", output_dir, "\n")
cat("Files used:\n")
cat("  cmr_admpop_adm1_2025.csv\n")
cat("  gadm41_CMR.gpkg          (layers: ADM_ADM_0, ADM_ADM_1, ADM_ADM_2)\n")
cat("  cmr_pop_2025_CN_100m_R2025A_v1.tif\n")
cat("  cmr_pop_2015_CN_100m_R2025A_v1.tif\n")

# EXERCISE 0: Administrative population choropleth ----
# Objective: join the cmr_admpop_adm1_2025.csv table to GADM boundaries
#            and produce a choropleth of the total population.

adm1_pop <- read_csv(
  file.path(data_dir, "cmr_admpop_adm1_2025.csv"),
  show_col_types = FALSE
)
cmr1 <- st_read(
  file.path(data_dir, "gadm41_CMR.gpkg"),
  layer = "ADM_ADM_1",
  quiet = TRUE
)

# --- CSV structure (source: https://data.humdata.org/dataset/cod-ps-cmr) ---
cat("Dimensions:", nrow(adm1_pop), "rows,", ncol(adm1_pop), "columns\n")
names(adm1_pop)
print(adm1_pop %>% select(ADM1_EN, ADM1_FR, ADM1_PCODE, T_TL, F_TL, M_TL))

# --- GPKG structure ---
st_layers(file.path(data_dir, "gadm41_CMR.gpkg"))
names(cmr1)
cat("CRS:", st_crs(cmr1)$input, "\n")
cat("Number of regions:", nrow(cmr1), "\n")
print(cmr1 %>% st_drop_geometry() %>% select(GID_1, NAME_1))

# Question 1:
# Which column of the CSV contains the total population? (T_TL, F_TL, M_TL)
# Does GADM use English or French names in NAME_1?

# Compare the names in both files before joining
cat("\nGADM NAME_1:")
print(sort(cmr1$NAME_1))
cat("CSV ADM1_EN:")
print(sort(adm1_pop$ADM1_EN))
cat("CSV ADM1_FR:")
print(sort(adm1_pop$ADM1_FR))

# Spot the mismatches for each option
cat(
  "Mismatches ADM1_EN:",
  setdiff(cmr1$NAME_1, adm1_pop$ADM1_EN),
  "\n"
)
cat(
  "Mismatches ADM1_FR:",
  setdiff(cmr1$NAME_1, adm1_pop$ADM1_FR),
  "\n"
)

# Join with the key that matches
cmr1_pop <- cmr1 %>%
  left_join(
    adm1_pop %>% select(ADM1_FR, T_TL, F_TL, M_TL),
    by = c("NAME_1" = "ADM1_FR")
  )

# Check: 0 NA = complete join
cat("Regions without a match (NA in T_TL):", sum(is.na(cmr1_pop$T_TL)), "\n")

# Choropleth: replace ___ with the total population column
choropleth_map <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = ___), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "plasma", labels = comma) +
  labs(
    title = "Population by region in Cameroon, 2025",
    subtitle = "Source: Common Operational Dataset",
    fill = "Population"
  ) +
  theme_minimal()

print(choropleth_map)

ggsave(
  file.path(output_dir, "jour07_choropleth_population_adm1.png"),
  choropleth_map,
  width = 7,
  height = 6,
  dpi = 180
)

# Question 2:
# Which region has the highest population? The lowest?
# Why can a choropleth be misleading when comparing regions of very
# different sizes?

# EXERCISE 0b: Female/male ratio ----
# Objective: calculate and map the F/M ratio by region.

cmr1_pop <- cmr1_pop %>%
  mutate(ratio_fm = ___) # F_TL / M_TL

ratio_map <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = ratio_fm), colour = "white", linewidth = 0.3) +
  scale_fill_gradient2(
    low = "#2166AC",
    mid = "white",
    high = "#B2182B",
    midpoint = ___, # balance value for an F/M ratio
    labels = number_format(accuracy = 0.01)
  ) +
  labs(
    title = "Female / male ratio by region, Cameroon 2025",
    fill = "F/M"
  ) +
  theme_minimal()

print(ratio_map)

# Question 3:
# What does a ratio > 1 mean? < 1?
# In which regions is the imbalance most pronounced?

# EXERCISE 0c: Share of young population (0-14 years) ----
# Objective: calculate the share of 0-14 year olds in the total population
#            and map this variable.

cmr1_pop <- cmr1_pop %>%
  left_join(
    adm1_pop %>%
      mutate(
        youth_0_14 = ___ + ___ + ___, # T_00_04 + T_05_09 + T_10_14
        youth_share_pct = ___ # 100 * youth_0_14 / T_TL
      ) %>%
      select(ADM1_FR, youth_0_14, youth_share_pct),
    by = c("NAME_1" = "ADM1_FR")
  )

youth_map <- ggplot(cmr1_pop) +
  geom_sf(aes(fill = ___), colour = "white", linewidth = 0.3) + # youth_share_pct
  scale_fill_viridis_c(option = "magma") +
  labs(
    title = "Share of the population under 15 years old",
    subtitle = "Cameroon, 2025",
    fill = "% 0-14 years"
  ) +
  theme_minimal()

print(youth_map)

ggsave(
  file.path(output_dir, "jour07_part_population_jeune_adm1.png"),
  youth_map,
  width = 7,
  height = 6,
  dpi = 180
)

# Question 4:
# Which regions have the highest proportion of young people?
# Is there a correlation with the region's total population?

# EXERCISE 1: Visualising the 2025 WorldPop grid with tmap ----
# Objective: load the 2025 WorldPop raster and explore it interactively.

# --- Raster structure (source: https://hub.worldpop.org/geodata/summary?id=72799) ---
pop_2025 <- rast(file.path(data_dir, "cmr_pop_2025_CN_100m_R2025A_v1.tif"))

# --- Raster structure ---
print(pop_2025)
cat("Resolution (degrees):", res(pop_2025), "\n")
cat("Number of cells:", ncell(pop_2025), "\n")
cat("CRS:", crs(pop_2025, describe = TRUE)$name, "\n")

# Question 5:
# What is the resolution in degrees? What does a cell value represent?

# Interactive visualisation
tmap_mode("view")

tm_shape(pop_2025) +
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population\n(people/cell)"),
    col_alpha = 0.8
  ) +
  tm_shape(cmr1) +
  tm_borders(col = "grey30", lwd = 0.5)

# Question 6:
# Which areas show the highest concentration of population?
# What does the grid look like around Yaounde and Douala?

# Static mode for export
tmap_mode("plot")

static_map <- tm_shape(pop_2025) +
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population (people/cell)")
  ) +
  tm_shape(cmr1) +
  tm_borders(col = "grey40", lwd = 0.5) +
  tm_title("Gridded WorldPop population 2025 - Cameroon")

print(static_map)

tmap_save(
  static_map,
  file.path(output_dir, "jour07_grille_population_2025.png"),
  width = 8,
  height = 6,
  dpi = 180
)

# EXERCISE 2: Population in Yaounde in 2025 ----
# Objective: locate Yaounde in ADM2, crop the raster and calculate
#            the estimated population.

cmr2 <- st_read(
  file.path(data_dir, "gadm41_CMR.gpkg"),
  layer = "ADM_ADM_2",
  quiet = TRUE
)

# --- ADM2 structure ---
cat("Number of departments:", nrow(cmr2), "\n")
cat("Columns:", paste(names(cmr2), collapse = ", "), "\n")

# Yaounde is in the Mfoundi department, Centre region.
# Explore the departments: cmr2 %>% filter(NAME_1 == "Centre") %>% select(NAME_2)
yaounde <- cmr2 %>% filter(NAME_2 == "Mfoundi")

# Crop the raster to Yaounde: reproject the polygon to the raster's CRS,
# then crop() + mask(), then global() to sum the cells.
yaounde_v <- vect(st_transform(yaounde, crs(pop_2025)))
pop_2025_yde <- mask(crop(pop_2025, yaounde_v), yaounde_v)
pop_yaounde_2025 <- global(pop_2025_yde, "sum", na.rm = TRUE)$sum

cat(
  "Estimated population in Yaounde (Mfoundi) in 2025:",
  format(round(pop_yaounde_2025), big.mark = " "),
  "\n"
)

# Interactive map of Yaounde
tmap_mode("view")

tm_shape(pop_2025_yde) +
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population (people/cell)"),
    col_alpha = 0.85
  ) +
  tm_shape(yaounde) +
  tm_borders(col = "black", lwd = 1.5) +
  tm_title("WorldPop 2025 - Yaounde / Mfoundi")

# Overlay WorldPop on satellite imagery to see the actual built-up areas
tm_basemap(c("Esri.WorldImagery", "OpenStreetMap")) +
  tm_shape(pop_2025_yde) +
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population (people/cell)"),
    col_alpha = 0.6
  ) +
  tm_shape(yaounde) +
  tm_borders(col = "white", lwd = 2) +
  tm_title("WorldPop 2025 on satellite imagery - Yaounde")

# Question 7:
# Does the population appear uniformly distributed across the department?
# Where do the densest areas concentrate?
# Do high WorldPop values coincide with the dense built-up areas
# visible on the satellite imagery?

# EXERCISE 3: Population in Yaounde in 2015 (your turn!) ----
# Objective: reproduce the same extraction for 2015.

pop_2015 <- rast(file.path(data_dir, "cmr_pop_2015_CN_100m_R2025A_v1.tif"))

# --- 2015 raster structure ---
print(pop_2015)

# Crop pop_2015 to Yaounde (same structure as exercise 2)
yaounde_v_2015 <- vect(st_transform(yaounde, crs(pop_2015)))
pop_2015_yde <- mask(crop(pop_2015, ___), ___)
pop_yaounde_2015 <- global(___, "sum", na.rm = TRUE)$sum

cat(
  "Estimated population in Yaounde in 2015:",
  format(round(pop_yaounde_2015), big.mark = " "),
  "\n"
)

# Produce an interactive map (same structure as for 2025)
tmap_mode("view")

tm_shape(___) +
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population (people/cell)"),
    col_alpha = 0.85
  ) +
  tm_shape(yaounde) +
  tm_borders(col = "black", lwd = 1.5) +
  tm_title("WorldPop 2015 - Yaounde / Mfoundi")

# Question 8:
# Does the 2015 map look similar to the 2025 one?
# What changes do you observe visually?

# EXERCISE 4: 2015-2025 comparison and aggregation by region ----
# Objective: compare the counts and aggregate the grid by region.

cat("2015:", format(round(pop_yaounde_2015), big.mark = " "), "inhabitants\n")
cat("2025:", format(round(pop_yaounde_2025), big.mark = " "), "inhabitants\n")
cat(
  "Growth:",
  round(100 * (pop_yaounde_2025 - pop_yaounde_2015) / pop_yaounde_2015, 1),
  "%\n"
)

# Aggregation by region with exactextractr
pop_2025_by_region <- exact_extract(
  pop_2025,
  st_transform(cmr1, crs(pop_2025)),
  "sum"
)
pop_2015_by_region <- exact_extract(
  pop_2015,
  st_transform(cmr1, crs(pop_2015)),
  "sum"
)

regions_pop <- cmr1 %>%
  st_drop_geometry() %>%
  select(NAME_1) %>%
  mutate(
    pop_worldpop_2015 = round(pop_2015_by_region),
    pop_worldpop_2025 = round(pop_2025_by_region),
    variation = pop_worldpop_2025 - pop_worldpop_2015,
    growth_pct = round(100 * variation / pop_worldpop_2015, 1)
  ) %>%
  arrange(desc(pop_worldpop_2025))

print(regions_pop)

cat(
  "\nTotal WorldPop 2025:",
  format(sum(___), big.mark = " "), # regions_pop$pop_worldpop_2025
  "\nTotal official CSV 2025:",
  format(sum(___), big.mark = " "), # adm1_pop$T_TL
  "\n"
)

# Question 9:
# Compare the WorldPop 2025 total with the official CSV total.
# sum(regions_pop$pop_worldpop_2025)
# sum(adm1_pop$T_TL)
# What is the gap in %? How can it be explained?

# Your turn: produce a 2015 vs 2025 side-by-side map with common breaks.
# Hint: common_breaks <- quantile(c(values(r1), values(r2)), seq(0,1,length.out=8), na.rm=TRUE)

cmr0 <- st_read(
  file.path(data_dir, "gadm41_CMR.gpkg"),
  layer = "ADM_ADM_0",
  quiet = TRUE
)

cmr0_v <- vect(st_transform(cmr0, crs(pop_2025)))
pop_2025_cmr <- mask(crop(pop_2025, cmr0_v), cmr0_v)
cmr0_v_2015 <- vect(st_transform(cmr0, crs(pop_2015)))
pop_2015_cmr <- mask(crop(pop_2015, cmr0_v_2015), cmr0_v_2015)

common_breaks <- quantile(
  c(values(pop_2025_cmr), values(pop_2015_cmr)),
  probs = seq(0, 1, length.out = 8),
  na.rm = TRUE
)

tmap_mode("plot")

comparison_map <- tmap_arrange(
  tm_shape(pop_2015_cmr) +
    tm_raster(
      col.scale = tm_scale_intervals(
        breaks = common_breaks,
        values = "brewer.yl_or_rd"
      ),
      col.legend = tm_legend(title = "people/cell")
    ) +
    tm_shape(cmr1) +
    tm_borders(col = "grey40", lwd = 0.3) +
    tm_title("2015"),
  tm_shape(___) + # ___ : pop_2025_cmr
    tm_raster(
      col.scale = tm_scale_intervals(
        breaks = common_breaks,
        values = "brewer.yl_or_rd"
      ),
      col.legend = tm_legend(title = "people/cell")
    ) +
    tm_shape(cmr1) +
    tm_borders(col = "grey40", lwd = 0.3) +
    tm_title("2025"),
  ncol = 2
)

print(comparison_map)

tmap_save(
  comparison_map,
  file.path(output_dir, "jour07_comparaison_pop_2015_2025.png"),
  width = 12,
  height = 5,
  dpi = 180
)

# Your turn: visualise the growth by region with a bar chart
# (regions_pop$growth_pct, regions sorted with reorder)
growth_chart <- ggplot(
  regions_pop,
  aes(x = ___, y = reorder(NAME_1, ___)) # ___ : growth_pct
) +
  geom_col(fill = "#2C7FB8") +
  geom_vline(xintercept = 0, colour = "grey40", linetype = 2) +
  labs(
    title = "WorldPop population growth by region (2015-2025)",
    x = "Growth (%)",
    y = NULL
  ) +
  theme_minimal()

print(growth_chart)

ggsave(
  file.path(output_dir, "jour07_croissance_population_2015_2025.png"),
  growth_chart,
  width = 8,
  height = 5,
  dpi = 180
)

# EXERCISE 4b: WorldPop 2030 projection - 15-year change ----
# Objective: extend the temporal comparison to 2030 to visualise
#            Yaounde's growth trajectory.

pop_2030 <- rast(file.path(data_dir, "cmr_pop_2030_CN_100m_R2025A_v1.tif"))
print(pop_2030)

# Extract Yaounde's population in 2030 (same method as exercises 2 and 3)
yaounde_v_2030 <- vect(st_transform(yaounde, crs(pop_2030)))
pop_2030_yde <- mask(crop(___, ___), ___)
pop_yaounde_2030 <- global(___, "sum", na.rm = TRUE)$sum

cat(
  "Estimated population in Yaounde in 2030:",
  format(round(pop_yaounde_2030), big.mark = " "),
  "\n"
)

# Summary table: 15-year change
yaounde_evolution <- tibble(
  year = c(2015, 2025, 2030),
  population = c(round(pop_yaounde_2015), round(pop_yaounde_2025), round(___))
) %>%
  mutate(
    growth_vs_2015 = round(100 * (population - ___) / ___, 1)
  )

print(yaounde_evolution)

# Chart of the change over time
evolution_chart <- ggplot(yaounde_evolution, aes(x = year, y = population)) +
  geom_line(colour = "#2C7FB8", linewidth = 1) +
  geom_point(colour = "#2C7FB8", size = 3) +
  scale_y_continuous(labels = ___) + # comma
  scale_x_continuous(breaks = c(2015, 2025, 2030)) +
  labs(
    title = "Population change in Yaounde (Mfoundi)",
    subtitle = "WorldPop constrained - 2015, 2025, 2030",
    x = "Year",
    y = "Estimated population"
  ) +
  theme_minimal()

print(evolution_chart)

ggsave(
  file.path(output_dir, "jour07_evolution_population_yaounde_2015_2030.png"),
  evolution_chart,
  width = 7,
  height = 5,
  dpi = 180
)

# 3-panel map: 2015, 2025, 2030 with common breaks
cmr0_v_2030 <- vect(st_transform(cmr0, crs(pop_2030)))
pop_2030_cmr <- mask(crop(___, ___), ___)

breaks_3years <- quantile(
  c(values(pop_2015_cmr), values(pop_2025_cmr), values(pop_2030_cmr)),
  probs = seq(0, 1, length.out = 8),
  na.rm = TRUE
)

tmap_mode("plot")

# Your turn: reproduce the side-by-side map for the 3 years
# (same structure as comparison_map, adding a 3rd panel for 2030)
map_3years <- tmap_arrange(
  tm_shape(pop_2015_cmr) +
    tm_raster(
      col.scale = tm_scale_intervals(
        breaks = breaks_3years,
        values = "brewer.yl_or_rd"
      ),
      col.legend = tm_legend(title = "people/cell")
    ) +
    tm_shape(cmr1) +
    tm_borders(col = "grey40", lwd = 0.3) +
    tm_title("2015"),
  tm_shape(pop_2025_cmr) +
    tm_raster(
      col.scale = tm_scale_intervals(
        breaks = breaks_3years,
        values = "brewer.yl_or_rd"
      ),
      col.legend = tm_legend(title = "people/cell")
    ) +
    tm_shape(cmr1) +
    tm_borders(col = "grey40", lwd = 0.3) +
    tm_title("2025"),
  tm_shape(___) + # ___ : pop_2030_cmr
    tm_raster(
      col.scale = tm_scale_intervals(
        breaks = breaks_3years,
        values = "brewer.yl_or_rd"
      ),
      col.legend = tm_legend(title = "people/cell")
    ) +
    tm_shape(cmr1) +
    tm_borders(col = "grey40", lwd = 0.3) +
    tm_title("2030 (projection)"),
  ncol = 3
)

print(map_3years)

tmap_save(
  map_3years,
  file.path(output_dir, "jour07_comparaison_pop_2015_2025_2030.png"),
  width = 16,
  height = 5,
  dpi = 180
)

# Question 9b:
# Is growth between 2025 and 2030 of the same order as 2015-2025?
# What assumptions underlie a WorldPop projection for 2030?
# In what case can a projection diverge strongly from reality?

# EXERCISE 5: Custom area drawn by you ----
# Objective: choose an area on satellite imagery, draw it with
#            mapedit and extract its population.

# Step 1: explore the map on a satellite basemap to choose your area
# (neighbourhood, campus, market, road corridor, rural area...)
tmap_mode("view")

tm_basemap(c("Esri.WorldImagery", "OpenStreetMap")) +
  tm_shape(pop_2025) +
  tm_raster(
    col.scale = tm_scale_intervals(
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population"),
    col_alpha = 0.5
  ) +
  tm_title("Explore and choose an area to analyse")

# Step 2: draw your area with mapedit
# Use the polygon tool (pencil icon) then click "Done"
# Change lng/lat/zoom to centre on another city
student_zone <- mapedit::editMap(
  leaflet::leaflet() %>%
    leaflet::addProviderTiles("Esri.WorldImagery") %>%
    leaflet::setView(lng = 11.52, lat = 3.86, zoom = 12)
)$finished

# Step 3: extract the population of your area
zone_v <- vect(st_transform(student_zone, crs(pop_2025)))
pop_zone <- mask(crop(pop_2025, zone_v), zone_v)
pop_zone_total <- global(pop_zone, "sum", na.rm = TRUE)$sum

cat(
  "Population of your area:",
  format(round(pop_zone_total), big.mark = " "),
  "inhabitants\n"
)

# Step 4: visualise the area and its population on a satellite basemap
tmap_mode("view")

tm_basemap(c("Esri.WorldImagery", "OpenStreetMap")) +
  tm_shape(pop_zone) +
  tm_raster(
    col.scale = tm_scale_intervals(
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "Population (people/cell)"),
    col_alpha = 0.65
  ) +
  tm_shape(student_zone) +
  tm_borders(col = "cyan", lwd = 2) +
  tm_title(paste0(
    "My area - ",
    format(round(pop_zone_total), big.mark = " "),
    " inhabitants"
  ))

# Question 10:
# Compare your count with a neighbour's who drew the same area.
# Do you get the same result? Why might there be differences?
# What additional information would be needed to validate this count?

# Fallback without mapedit: manual bounding box (change the coordinates)
# bbox_zone <- st_bbox(
#   c(xmin = 11.48, ymin = 3.82, xmax = 11.58, ymax = 3.93),
#   crs = st_crs(4326)
# ) %>% st_as_sfc() %>% st_as_sf()
# zone_v   <- vect(st_transform(bbox_zone, crs(pop_2025)))
# pop_zone <- mask(crop(pop_2025, zone_v), zone_v)
# cat("Population:", round(global(pop_zone, "sum", na.rm = TRUE)$sum), "\n")

# EXERCISE 5b: Comparing several cities ----
# Objective: calculate the WorldPop population of several Cameroonian cities
#            and compare their 2015-2025 growth.

cities_dept <- c(
  "Douala (Wouri)" = "Wouri",
  "Yaounde (Mfoundi)" = "Mfoundi",
  "Bafoussam (Mifi)" = "Mifi",
  "Bamenda (Mezam)" = "Mezam",
  "Garoua (Benoue)" = "Benoue"
)

cities_pop <- lapply(names(cities_dept), function(name) {
  dept <- cmr2 %>% filter(NAME_2 == cities_dept[[name]])
  dept_v <- vect(st_transform(dept, crs(pop_2025)))
  tibble(
    city = name,
    pop_2015 = round(
      global(mask(crop(___, dept_v), dept_v), "sum", na.rm = TRUE)$sum
    ),
    pop_2025 = round(
      global(mask(crop(___, dept_v), dept_v), "sum", na.rm = TRUE)$sum
    )
  )
}) %>%
  bind_rows() %>%
  mutate(growth_pct = round(100 * (pop_2025 - ___) / ___, 1))

print(cities_pop)

# Question 11:
# Which city has the strongest relative growth?
# Compare Douala and Yaounde: which has the higher absolute population?
# Add another city of your choice to the cities_dept vector.

# EXERCISE 6: Population density ----
# Objective: calculate density in people/km2 and map it with a log scale.

cmr1_density <- cmr1_pop %>%
  mutate(
    area_km2 = as.numeric(st_area(geom)) / 1e6,
    density_hab_km2 = ___ # T_TL / area_km2
  )

density_map <- ggplot(cmr1_density) +
  geom_sf(aes(fill = density_hab_km2), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(
    option = "inferno",
    trans = "log10",
    labels = comma,
    name = "people/km2 (log)"
  ) +
  labs(
    title = "Population density by region, Cameroon 2025",
    subtitle = "Logarithmic scale"
  ) +
  theme_minimal()

print(density_map)

ggsave(
  file.path(output_dir, "jour07_densite_population_adm1.png"),
  density_map,
  width = 7,
  height = 6,
  dpi = 180
)

# Question 12:
# Why is a logarithmic scale necessary here?
# What is the difference between the total population map and this density map?
# Which one is better suited to comparing regions of different sizes?

# EXERCISE 7: Age distribution between two regions ----
# Objective: use the T_00_04...T_80Plus columns to visualise
#            the age structure of two regions.

regions_to_compare <- c("Centre", "Adamawa")

pop_by_age <- adm1_pop %>%
  filter(ADM1_EN %in% regions_to_compare) %>%
  select(ADM1_EN, starts_with("T_"), -T_TL) %>%
  pivot_longer(
    cols = starts_with("T_"),
    names_to = "age_group",
    values_to = "population"
  ) %>%
  mutate(
    age_group = sub("T_", "", age_group),
    age_group = gsub("_", "-", age_group),
    age_group = sub("Plus", "+", age_group)
  )

ggplot(pop_by_age, aes(x = age_group, y = population, fill = ADM1_EN)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Age structure - comparison between two regions",
    x = "Age group",
    y = "Population",
    fill = "Region"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Your turn: choose two other regions and comment on the difference.

# Question 13:
# Which region has a younger population?
# WorldPop does not differentiate ages: how can this limit be worked around
# in an analysis of the school-age population, for example?

# EXERCISE 8: GHSL-POP data - mosaic, reprojection, cropping and comparison ----
# Objective: start from the raw GHSL tiles, assemble them step by step,
#            reproduce the Yaounde map and compare counts with WorldPop.

# --- Source: European Commission, JRC ---
# GHS-POP R2023A, 100 m resolution, Mollweide projection (ESRI:54009)
# Download: https://human-settlement.emergency.copernicus.eu/download.php?ds=pop
# The downloaded tiles together cover the whole of Cameroon.
ghsl_dir <- file.path(data_dir, "GHS-POP")

# STEP 1: unzip the tiles ----
zips <- list.files(ghsl_dir, pattern = "\\.zip$", full.names = TRUE)
cat("ZIP tiles found:", length(zips), "\n")
cat(paste(" ", basename(zips)), sep = "\n")

for (z in zips) {
  unzip(z, exdir = ghsl_dir)
}

tifs <- list.files(ghsl_dir, pattern = "\\.tif$", full.names = TRUE)
cat("\nTIF files available:", length(tifs), "\n")

# STEP 2: explore a tile ----
sample_tile <- rast(tifs[1])
print(sample_tile)
cat("CRS:", crs(sample_tile, describe = TRUE)$name, "\n")
cat("Resolution:", res(sample_tile), "m\n")

# STEP 3: mosaic ----
# sprc() creates a collection of rasters from a list.
# mosaic() assembles them; fun = "mean" handles overlaps.
cat("Building mosaic...\n")
tiles <- sprc(lapply(___, rast)) # ___ : vector of TIF paths
ghsl_mosaic <- mosaic(___, fun = "mean") # ___ : the sprc collection

cat("Mosaic created.\n")
cat("Extent:", as.character(ext(ghsl_mosaic)), "\n")
cat("CRS:", crs(ghsl_mosaic, describe = TRUE)$name, "\n")

# STEP 4: reprojection to WGS84 ----
# To compare with WorldPop (EPSG:4326), we reproject the mosaic.
# method = "bilinear" is appropriate for continuous values such as population.
cat("Reprojecting to WGS84...\n")
ghsl_wgs84 <- project(___, "EPSG:4326", method = "bilinear") # ___ : ghsl_mosaic

cat("After reprojection:\n")
cat("  CRS:", crs(ghsl_wgs84, describe = TRUE)$name, "\n")
cat("  Resolution (degrees):", res(ghsl_wgs84), "\n")

# STEP 5: crop to Cameroon ----
# cmr0 was already loaded in exercise 4; vect() converts it to a SpatVector.
cmr0_v_ghsl <- vect(cmr0)
ghsl_cmr <- mask(crop(___, cmr0_v_ghsl), cmr0_v_ghsl) # ___ : ghsl_wgs84
ghsl_cmr[ghsl_cmr < 0] <- NA

# Save to avoid recomputing on re-run
writeRaster(
  ghsl_cmr,
  file.path(data_dir, "ghsl_pop_2025_cmr_100m.tif"),
  overwrite = TRUE,
  datatype = "FLT4S"
)
cat("File saved: ghsl_pop_2025_cmr_100m.tif\n")

# STEP 6: GHSL map of Cameroon ----
# Don't forget to play with color clustering (ie parameter style:  "fixed", "sd", "equal", "pretty",
#  "quantile", "kmeans", "hclust", "bclust", "fisher", "jenks", "dpih", "headtails",
#  "maximum", "box", "log10", and "log10_pretty")
tmap_mode("view")

tm_shape(ghsl_cmr) +
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "GHSL population (people/cell)"),
    col_alpha = 0.8
  ) +
  tm_shape(cmr1) +
  tm_borders(col = "grey30", lwd = 0.5) +
  tm_title("GHS-POP 2025 - Cameroon")

# STEP 7 (your turn): reproduce the Yaounde map with GHSL ----
# Same structure as exercise 2, replacing pop_2025 with ghsl_cmr.
yaounde_v_ghsl <- vect(st_transform(yaounde, crs(ghsl_cmr)))
ghsl_yde <- mask(crop(___, yaounde_v_ghsl), yaounde_v_ghsl) # ___ : ghsl_cmr
pop_ghsl_yde <- global(___, "sum", na.rm = TRUE)$sum # ___ : ghsl_yde

cat(
  "GHSL population in Yaounde (Mfoundi):",
  format(round(pop_ghsl_yde), big.mark = " "),
  "\n"
)

tmap_mode("view")

tm_basemap(c("Esri.WorldImagery", "OpenStreetMap")) +
  tm_shape(___) + # ___ : ghsl_yde
  tm_raster(
    col.scale = tm_scale_intervals(
      n = 7,
      style = "quantile",
      values = "brewer.yl_or_rd"
    ),
    col.legend = tm_legend(title = "GHSL population (people/cell)"),
    col_alpha = 0.7
  ) +
  tm_shape(yaounde) +
  tm_borders(col = "white", lwd = 2) +
  tm_title("GHS-POP 2025 - Yaounde / Mfoundi")

# STEP 8: WorldPop vs GHSL comparison - whole of Cameroon ----
pop_worldpop_total <- round(global(pop_2025_cmr, "sum", na.rm = TRUE)$sum)
pop_ghsl_total <- round(global(___, "sum", na.rm = TRUE)$sum) # ___ : ghsl_cmr

cat("\nComparison of national totals - Cameroon 2025\n")
cat("WorldPop constrained:", format(pop_worldpop_total, big.mark = " "), "\n")
cat("GHS-POP:             ", format(pop_ghsl_total, big.mark = " "), "\n")
cat("Official CSV:        ", format(sum(adm1_pop$T_TL), big.mark = " "), "\n")
cat("GHSL vs WorldPop gap (%):", round(100 * (___ - ___) / ___, 1), "\n") # (pop_ghsl_total - pop_worldpop_total) / pop_worldpop_total

# Your turn: compare the GHSL vs WorldPop gap by region with exact_extract
# (same structure as pop_2025_by_region / pop_2015_by_region in exercise 4)
pop_ghsl_by_region <- exact_extract(
  ___, # ghsl_cmr
  st_transform(cmr1, crs(ghsl_cmr)),
  "sum"
)

regions_comparison <- cmr1 %>%
  st_drop_geometry() %>%
  select(NAME_1) %>%
  mutate(
    pop_worldpop_2025 = round(pop_2025_by_region),
    pop_ghsl_2025 = round(___), # pop_ghsl_by_region
    gap_pct = round(
      100 * (pop_ghsl_2025 - pop_worldpop_2025) / pop_worldpop_2025,
      1
    )
  ) %>%
  arrange(desc(abs(gap_pct)))

print(regions_comparison)

# Question 14:
# In which regions is the gap between WorldPop and GHSL the largest?
# Is the gap systematically in the same direction (GHSL > WorldPop or the opposite)?
# In what case should GHSL be preferred over WorldPop for a demographic analysis?
# Why is WorldPop constrained closer to the official CSV?

# Exports ----

write_csv(
  regions_pop,
  file.path(output_dir, "jour07_population_regions_worldpop_2015_2025.csv")
)
write_csv(
  cities_pop,
  file.path(output_dir, "jour07_population_grandes_villes_2015_2025.csv")
)

st_write(
  cmr1_pop %>%
    left_join(
      regions_pop %>%
        select(
          NAME_1,
          pop_worldpop_2015,
          pop_worldpop_2025,
          variation,
          growth_pct
        ),
      by = "NAME_1"
    ),
  file.path(output_dir, "jour07_regions_population_complete.gpkg"),
  delete_dsn = TRUE
)

# Final debrief questions:
# 1. What is the fundamental difference between a choropleth and a population grid?
# 2. Why do WorldPop totals differ from census figures?
# 3. In what case should WorldPop be preferred over GHS-POP?
# 4. What precautions should be taken before publishing a count drawn from a grid?
# 5. How can the CSV's age groups be used to target an intervention?
