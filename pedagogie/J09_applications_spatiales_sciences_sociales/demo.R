# =====================================================================
# J9 - Applications spatiales et sciences sociales (script de salle)
# Atelier IFORD x GDSG - Yaounde 6 aout 2026
# Conception pedagogique complete : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita (GDSG/IFORD)
# Donnees : ACLED (conflits) + ERA5 (temperature) Cameroun
# =====================================================================

library(sf)
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(tmap)
library(scales)
library(terra)
library(exactextractr)
library(tibble)

source("../_commons/helpers/fetch_data.R")

# Helper .env (identifiants ACLED + CDS)
charger_env <- function(path) {
  if (!file.exists(path)) return(invisible(FALSE))
  lignes <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lignes <- lignes[nzchar(trimws(lignes)) & !startsWith(trimws(lignes), "#")]
  for (ligne in lignes) {
    morceaux <- strsplit(ligne, "=", fixed = TRUE)[[1]]
    if (length(morceaux) < 2) next
    nom    <- trimws(morceaux[1])
    valeur <- trimws(paste(morceaux[-1], collapse = "="))
    valeur <- gsub('^["\']|["\']$', "", valeur)
    if (nzchar(nom)) do.call(Sys.setenv, stats::setNames(list(valeur), nom))
  }
  invisible(TRUE)
}
charger_env("../datasets/cameroun/jour_09_acled_era5/.env")

annee_courante <- as.integer(format(Sys.Date(), "%Y"))
annee_min      <- annee_courante - 10
out_dir <- "outputs"
dir.create(out_dir, showWarnings = FALSE)

# ====================================================================
# PARTIE I - ACLED (conflits armes)
# ====================================================================

# Ex 1 : Chargement ACLED
acled_brut <- read_csv(fetch_acled_cmr(), show_col_types = FALSE)
cat("ACLED :", nrow(acled_brut), "lignes x", ncol(acled_brut), "colonnes\n")

# Ex 2 : Nettoyage et filtrage
acled_clean <- acled_brut |>
  mutate(
    event_date = as.Date(event_date),
    annee      = as.integer(year),
    mois       = format(event_date, "%Y-%m"),
    fatalities = as.numeric(fatalities),
    longitude  = as.numeric(longitude),
    latitude   = as.numeric(latitude)
  ) |>
  filter(!is.na(longitude), !is.na(latitude))

if (min(acled_clean$annee) <= annee_min) {
  acled_clean <- acled_clean |> filter(annee >= annee_min)
}
cat("Apres filtre :", nrow(acled_clean), "evenements\n")

# Ex 3 : Exploration
acled_clean |> count(event_type, sort = TRUE, name = "n_evenements") |> print()
acled_clean |> count(admin1, sort = TRUE, name = "n_evenements") |> print()

# Ex 4a : Annuelle par type
resume_annuel <- acled_clean |> count(annee, event_type, name = "n_evenements")
graphe_annuel <- ggplot(resume_annuel,
                        aes(x = annee, y = n_evenements, fill = event_type)) +
  geom_col() +
  scale_x_continuous(breaks = seq(min(resume_annuel$annee),
                                  max(resume_annuel$annee), by = 1)) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Evolution annuelle des conflits au Cameroun",
       subtitle = "Source: ACLED",
       x = "Annee", y = "Nombre d'evenements", fill = "Type") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
print(graphe_annuel)

# Ex 4c : Deces annuels
resume_deces <- acled_clean |>
  group_by(annee) |>
  summarise(deces = sum(fatalities, na.rm = TRUE), .groups = "drop")
graphe_deces <- ggplot(resume_deces, aes(x = annee, y = deces)) +
  geom_line(colour = "#CB181D", linewidth = 1.2) +
  geom_point(colour = "#CB181D", size = 2.5) +
  scale_x_continuous(breaks = seq(min(resume_deces$annee),
                                  max(resume_deces$annee), by = 1)) +
  labs(title = "Deces lies aux conflits au Cameroun (source: ACLED)",
       x = "Annee", y = "Nombre de deces") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
print(graphe_deces)

# Ex 5 : Cartographie
acled_pts <- st_as_sf(acled_clean,
                      coords = c("longitude", "latitude"),
                      crs = 4326, remove = FALSE)

cmr0 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_0", quiet = TRUE)
cmr1 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_1", quiet = TRUE)

tmap_mode("plot")

# Carte points par type
carte_types <- tm_shape(cmr1) +
  tm_borders(col = "grey50", lwd = 0.8) +
  tm_shape(acled_pts) +
  tm_dots(fill = "event_type", size = 0.04, alpha = 0.6,
          fill.legend = tm_legend(title = "Type d'evenement")) +
  tm_shape(cmr0) +
  tm_borders(col = "grey20", lwd = 1.8) +
  tm_title("Conflits armes au Cameroun (source: ACLED)") +
  tm_layout(legend.outside = TRUE)
print(carte_types)

# Choropleth par region via st_within
resume_par_region <- acled_pts |>
  st_join(cmr1[c("NAME_1")], join = st_within) |>
  st_drop_geometry() |>
  filter(!is.na(NAME_1)) |>
  group_by(NAME_1) |>
  summarise(n_evenements = n(),
            deces = sum(fatalities, na.rm = TRUE),
            .groups = "drop")

cmr1_acled <- cmr1 |>
  left_join(resume_par_region, by = "NAME_1") |>
  mutate(n_evenements = replace_na(n_evenements, 0L),
         deces = replace_na(deces, 0))

carte_regions <- tm_shape(cmr1_acled) +
  tm_polygons(fill = "n_evenements",
              fill.scale = tm_scale_continuous(values = "brewer.reds"),
              fill.legend = tm_legend(title = "Nb d'evenements")) +
  tm_borders(col = "white", lwd = 0.6) +
  tm_title("Conflits par region - Cameroun (source: ACLED)") +
  tm_layout(legend.outside = TRUE)
print(carte_regions)

# Ex 6 : Export ACLED
st_write(acled_pts, file.path(out_dir, "jour09_acled_points.gpkg"),
         delete_dsn = TRUE, quiet = TRUE)
st_write(cmr1_acled, file.path(out_dir, "jour09_acled_regions.gpkg"),
         delete_dsn = TRUE, quiet = TRUE)
write_csv(resume_par_region,
          file.path(out_dir, "jour09_acled_resume_regions.csv"))

# ====================================================================
# PARTIE II - ERA5 (temperature) - eval interactif uniquement
# ====================================================================
# Necessite token CDS + NetCDF telecharge. Decommenter pour la salle.

# nc_path  <- fetch_era5_t2m_cmr()
# era5_brut <- rast(nc_path)
# dates_era5 <- as.Date(time(era5_brut))
# era5_celsius <- era5_brut - 273.15
# cmr0_vect <- vect(st_transform(cmr0, crs(era5_celsius)))
# era5_cmr  <- mask(crop(era5_celsius, cmr0_vect), cmr0_vect)
#
# # Ex 9 : Extraction par region
# cmr1_proj   <- st_transform(cmr1, crs(era5_cmr))
# t2m_extrait <- exact_extract(era5_cmr, cmr1_proj, "mean")
# t2m_long <- cmr1 |>
#   st_drop_geometry() |> select(NAME_1) |>
#   bind_cols(t2m_extrait) |>
#   pivot_longer(cols = -NAME_1, names_to = "couche",
#                values_to = "t2m_celsius") |>
#   mutate(idx = as.integer(sub("mean\\.", "", couche)),
#          date = dates_era5[idx],
#          annee = as.integer(format(date, "%Y")),
#          mois = as.integer(format(date, "%m"))) |>
#   select(-couche, -idx)
#
# # Ex 10a : Serie nationale
# t2m_national <- t2m_long |>
#   group_by(date) |>
#   summarise(t2m_moy = mean(t2m_celsius, na.rm = TRUE))
#
# ggplot(t2m_national, aes(x = date, y = t2m_moy)) +
#   geom_line(colour = "#2171B5") +
#   geom_smooth(method = "loess", colour = "#CB181D", linetype = "dashed") +
#   labs(title = "Evolution T2m Cameroun", x = "Date", y = "T (degC)") +
#   theme_minimal()
#
# # Ex 11a : Carte T moyenne
# t2m_moy_rast <- mean(era5_cmr)
# tm_shape(t2m_moy_rast) +
#   tm_raster(col.scale = tm_scale_continuous(values = "brewer.rd_yl_bu",
#                                             reverse = TRUE),
#             col.legend = tm_legend(title = "T degC")) +
#   tm_shape(cmr1) + tm_borders() +
#   tm_layout(legend.outside = TRUE)

# Fin J9
