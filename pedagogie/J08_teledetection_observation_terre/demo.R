# =====================================================================
# J8 - Teledetection et observation de la Terre (script de salle)
# Atelier IFORD x GDSG - Yaounde 5 aout 2026
# Conception pedagogique complete : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita (GDSG/IFORD)
# Partie I : GHSL Built-Up Cameroun 2015 vs 2025
# Partie II : Inondations EMSR772 Yagoua 2024 + Open Buildings
#
# Teledetection = mesurer la surface terrestre sans contact, depuis un
# satellite ou un avion. Les capteurs optiques (Sentinel-2, Landsat)
# enregistrent la lumiere reflechie par le sol ; des modeles transforment
# ensuite ces pixels en cartes de couverture (bati, eau, vegetation...).
# =====================================================================

# sf      = vecteurs spatiaux (points, lignes, polygones)
# terra   = rasters (grilles regulieres de pixels, ex. GHSL)
# exactextractr = extraction zonale exacte (somme pixels x fraction couverte
#                 par chaque polygone -- plus precis qu'un simple "centre dans")
# tmap    = cartes thematiques statiques ou interactives
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

# --- Helpers GHSL ---
# GHSL Built-Up R2023A (JRC, Commission europeenne) : carte mondiale de
# la surface batie (m2 par pixel) pour les annees 1975 a 2030, derivee
# de series Sentinel-2 et Landsat. Resolution 100 m.
# Projection : Mollweide mondiale equal-area (ESRI:54009) -- coordonnees
# en metres. Indispensable pour mesurer des surfaces sans distorsion
# (a la difference du WGS84 en degres).
# Le Cameroun chevauche 8 tuiles ZIP de 10 deg x 10 deg : on les dezippe,
# puis on fusionne les rasters individuels en une mosaique continue
# (terra::mosaic = colle les tuiles cote a cote en gerant les recouvrements).
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

# Decoupe le raster sur l'emprise du pays :
#   crop() = enleve la bordure rectangulaire hors bbox du pays,
#   mask() = met a NA tous les pixels en dehors du polygone.
preparer_raster <- function(r, pays) {
  pays_vect <- vect(st_transform(pays, crs(r)))
  mask(crop(r, pays_vect), pays_vect)
}

# exactextractr::exact_extract() somme les pixels du raster en ponderant
# par la fraction de chaque pixel couverte par le polygone (plus precis
# qu'un simple "centroid in").
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
# GADM = decoupage administratif Cameroun (ADM0 pays / ADM1 regions /
# ADM2 departements), reutilise tel quel depuis J7. En WGS84 (EPSG:4326).
cmr0 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_0", quiet = TRUE)
cmr1 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_1", quiet = TRUE)
cmr2 <- st_read(fetch_gadm_cmr_gpkg(), layer = "ADM_ADM_2", quiet = TRUE)

# Mosaique des 8 tuiles GHSL pour chaque annee, puis decoupe au contour pays.
bati_2015     <- charger_ghsl(2015)
bati_2025     <- charger_ghsl(2025)
bati_2015_cmr <- preparer_raster(bati_2015, cmr0)
bati_2025_cmr <- preparer_raster(bati_2025, cmr0)

# Section 1 : Indicateurs nationaux
# Reprojection en Mollweide (CRS du raster) pour mesurer une surface en
# km2 dans une projection equal-area, sans distorsion liee a la latitude.
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
# Carte 1 - palette sequentielle magma (faible -> fort), legende en %.
carte_part_2025 <- ggplot(regions_2025) +
  geom_sf(aes(fill = part_batie_pct), colour = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "magma",
                       labels = function(x) paste0(round(x, 1), " %")) +
  labs(title    = "Part de surface batie par region - Cameroun, 2025",
       subtitle = "GHSL Built-Up Surface R2023A - resolution 100 m (JRC)",
       caption  = "Source : GHSL Built-Up R2023A (JRC) - IFORD x GDSG 2026",
       fill     = "Part batie (%)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))
print(carte_part_2025)
ggsave(file.path(out_dir, "jour08_part_batie_2025.png"),
       carte_part_2025, width = 8, height = 5, dpi = 180)

# Carte 2 - palette divergente centree sur 0 (bleu = perte / rouge = gain).
# midpoint = 0 force la couleur "blanche" sur l'absence de variation,
# ce qui rend immediatement lisibles les regions qui ont gagne (rouge).
carte_gain <- ggplot(regions_2025 |>
                     left_join(regions_chg, by = c("GID_1", "NAME_1"))) +
  geom_sf(aes(fill = gain_bati_km2), colour = "white", linewidth = 0.2) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0,
                       labels = function(x) paste0("+", round(x, 0))) +
  labs(title    = "Gain de surface batie 2015 -> 2025 - regions du Cameroun",
       subtitle = "GHSL Built-Up R2023A - difference en km2 par region ADM1",
       caption  = "Source : GHSL Built-Up R2023A (JRC) - IFORD x GDSG 2026",
       fill     = "Gain (km2)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))
print(carte_gain)
ggsave(file.path(out_dir, "jour08_gain_bati_2015_2025.png"),
       carte_gain, width = 8, height = 5, dpi = 180)

# Section 4 : Typologie de croissance
# Croisement de 2 dimensions (gain absolu km2 x densite 2025), avec la
# mediane comme seuil -> 4 profils mutuellement exclusifs. case_when()
# evalue les conditions dans l'ordre, la 1ere VRAIE s'applique.
regions_typo <- regions_chg |>
  mutate(profil = case_when(
    gain_bati_km2 >= median(gain_bati_km2) &
      part_batie_pct_2025 >= median(part_batie_pct_2025) ~ "Croissance forte et tissu dense",
    gain_bati_km2 >= median(gain_bati_km2) ~ "Croissance forte",
    part_batie_pct_2025 >= median(part_batie_pct_2025) ~ "Tissu dense",
    TRUE ~ "Croissance moderee"
  ))

# Carte typologie pour le bilan de salle.
carte_typo <- ggplot(regions_2025 |>
                     left_join(regions_typo, by = c("GID_1", "NAME_1"))) +
  geom_sf(aes(fill = profil), colour = "white", linewidth = 0.2) +
  scale_fill_manual(values = c(
    "Croissance forte et tissu dense" = "#B2182B",
    "Croissance forte"                = "#FD8D3C",
    "Tissu dense"                     = "#2C7FB8",
    "Croissance moderee"              = "#FEE8C8"
  )) +
  labs(title    = "Typologie de croissance batie par region - Cameroun, 2015->2025",
       subtitle = "GHSL Built-Up R2023A - croisement gain absolu x densite (seuils = mediane)",
       caption  = "Source : GHSL Built-Up R2023A (JRC) - IFORD x GDSG 2026",
       fill     = "Profil regional") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))
print(carte_typo)
ggsave(file.path(out_dir, "jour08_typologie_regions.png"),
       carte_typo, width = 8, height = 5, dpi = 180)

# Section 5 : Zoom ADM2
# Meme pipeline mais sur les 58 departements : zoom plus fin pour reperer
# les chefs-lieux (Wouri/Douala, Mfoundi/Yaounde) et les communes peri-
# urbaines en expansion qui ne sortent pas a la maille regionale.
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

# Carte departementale : 58 polygones (trait fin 0.12 pour ne pas surcharger).
carte_dept <- ggplot(departements_2025 |>
                     left_join(departements_chg, by = c("GID_2", "NAME_2"))) +
  geom_sf(aes(fill = gain_bati_km2), colour = "white", linewidth = 0.12) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0,
                       labels = function(x) paste0("+", round(x, 0))) +
  labs(title    = "Gain de surface batie 2015 -> 2025 - departements du Cameroun",
       subtitle = "GHSL Built-Up R2023A - 58 departements ADM2 - zoom local",
       caption  = "Source : GHSL Built-Up R2023A (JRC) - IFORD x GDSG 2026",
       fill     = "Gain (km2)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))
print(carte_dept)
ggsave(file.path(out_dir, "jour08_gain_bati_departements.png"),
       carte_dept, width = 9, height = 6, dpi = 180)

# Section 6 : Exports
write_csv(regions_chg,      file.path(out_dir, "jour08_regions_bati_2015_2025.csv"))
write_csv(regions_typo,     file.path(out_dir, "jour08_regions_typologie_bati.csv"))
write_csv(departements_chg, file.path(out_dir, "jour08_departements_bati_2015_2025.csv"))

# ====================================================================
# PARTIE II - Inondations EMSR772 + Open Buildings
# ====================================================================

# Copernicus EMS (CEMS) = service europeen d'urgence qui produit en
# moins de 24 h des couches geographiques d'emprise de catastrophe a
# partir d'images satellite acquises en urgence. Chaque activation porte
# un code EMSR + un numero.
# EMSR772 = activation declenchee pour les inondations massives autour
# de YAGOUA (nord Cameroun, region de l'Extreme-Nord), octobre 2024.
# Trois zones d'analyse (AOI01 = Yagoua centre, AOI02 et AOI03 plus rurales).
emsr_dir    <- fetch_emsr772_dir()
emsr_dir_01 <- file.path(emsr_dir, "EMSR772_AOI01_DEL_PRODUCT_v2")

# Ex 1 : EMS AOI01
# st_make_valid() repare les geometries invalides (vertices dupliques,
# auto-intersections), tres frequentes dans les shapefiles Copernicus
# livres en urgence. Sans cette etape, st_area/st_filter plantent avec
# l'erreur "wk_handle.wk_wkb".
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

# Carte AOI01 + profondeurs (palette YlOrRd = standard ColorBrewer pour
# alea d'intensite croissante).
carte_flood <- ggplot() +
  geom_sf(data = aoi01, fill = "lightblue", alpha = 0.3,
          colour = "steelblue", linewidth = 1) +
  geom_sf(data = flood01, aes(fill = value), colour = NA, alpha = 0.85) +
  scale_fill_brewer(palette = "YlOrRd", name = "Profondeur (m)") +
  labs(title    = "Profondeurs d'inondation - AOI01 Yagoua (oct. 2024)",
       subtitle = "EMSR772 v2 - Copernicus Emergency Management Service",
       caption  = "Source : Copernicus EMSR772 v2 - IFORD x GDSG 2026") +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank(),
        plot.title = element_text(face = "bold"))
print(carte_flood)
ggsave(file.path(out_dir, "jour08_aoi01_profondeurs.png"),
       carte_flood, width = 8, height = 5, dpi = 180)

# Ex 2 : Google Open Buildings v3 (Sirko et al. 2021)
# Inventaire mondial d'empreintes de batiments detectees par un modele
# de machine learning sur de l'imagerie satellite haute-resolution (~50 cm).
# Distribue en CSV.gz par tuile S2 (carte Sentinel-2 de la grille mondiale).
# Filtre standard recommande : confidence >= 0.7 -> rejette les faux
# positifs (vegetation dense, ombres, structures non residentielles).
ob_dir <- fetch_open_buildings_dir()
ob_fichiers <- list.files(ob_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
# lapply + bind_rows = lit chaque CSV.gz et empile -- pratique car le
# nombre de fichiers depend de la couverture de la zone choisie.
batiments_raw <- lapply(ob_fichiers, function(f)
  read_csv(f, show_col_types = FALSE)) |> bind_rows()
# st_as_sf() : transforme un dataframe (lon, lat) en objet sf georeference.
# CRS 4326 = WGS84 = standard mondial (degres lat/lon, format GPS).
batiments <- st_as_sf(batiments_raw,
                     coords = c("longitude", "latitude"), crs = 4326)
batiments_ok <- batiments |> filter(confidence >= 0.7)
cat("Batiments confidence >= 0.7 :",
    format(nrow(batiments_ok), big.mark = " "), "\n")

# Ex 3 : Filtre spatial - bati dans AOI01.
# st_filter(x, y) = garde de x les elements qui intersectent y (predicat
# par defaut : st_intersects). Reprojection obligatoire au CRS de l'AOI
# avant l'intersection, sinon les coordonnees ne se comparent pas et le
# filtre renvoie 0 ligne.
if (st_crs(batiments_ok) != st_crs(aoi01)) {
  batiments_ok <- st_transform(batiments_ok, st_crs(aoi01))
}
batiments_aoi01 <- st_filter(batiments_ok, aoi01)

# Ex 4 : Estimation population
# Taux 5 pers./batiment calibre sur la DHS Cameroun 2018 (taille moyenne
# de menage ~5,5 personnes au niveau national). A ajuster selon contexte
# (rural traditionnel ~7, urbain dense moderne ~3-4).
pers_par_batiment <- 5
pop_aoi01 <- nrow(batiments_aoi01) * pers_par_batiment

# Ex 5 : Batiments inondes
# Deuxieme st_filter() en cascade : parmi les batiments de l'AOI, ceux qui
# intersectent au moins un polygone d'inondation = batiments EXPOSES.
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

# Carte de synthese AOI01 : contour AOI + flood colore + bati gris +
# bati expose en rouge. Le sous-titre donne directement le chiffre cle.
carte_expo <- ggplot() +
  geom_sf(data = aoi01, fill = NA, colour = "steelblue", linewidth = 1) +
  geom_sf(data = flood01, aes(fill = value), colour = NA, alpha = 0.6) +
  geom_sf(data = batiments_aoi01, colour = "grey40", size = 0.3, alpha = 0.5) +
  geom_sf(data = batiments_inondes, colour = "red", size = 0.4, alpha = 0.8) +
  scale_fill_brewer(palette = "YlOrRd", name = "Profondeur (m)") +
  labs(title    = "Batiments exposes aux inondations - AOI01 Yagoua, 2024",
       subtitle = paste0("EMSR772 v2 + Open Buildings v3 - Rouge : ",
                         format(nrow(batiments_inondes), big.mark = " "),
                         " batiments touches / ",
                         format(nrow(batiments_aoi01), big.mark = " "), " total"),
       caption  = "Sources : Copernicus EMSR772 v2 - Google Open Buildings v3 - IFORD x GDSG 2026") +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank(),
        plot.title = element_text(face = "bold"))
print(carte_expo)
ggsave(file.path(out_dir, "jour08_aoi01_batiments_exposes.png"),
       carte_expo, width = 8, height = 5, dpi = 180)

# Ex 6 : Fonction reutilisable + AOI02 + AOI03
# Principe DRY (Don't Repeat Yourself) : une seule definition, trois
# applications. Argument zone_pattern = "AOI01"/"AOI02"/"AOI03" matche
# les fichiers par expression reguliere ; recursive = TRUE absorbe les
# differences de structure de ZIP (AOI01 dans sous-dossier vs AOI02/03
# directement a la racine).
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

# Graphique de synthese 3 AOI : barre totale (bleu) + barre touches
# (rouge) empilees pour visualiser part exposee par zone.
g_bilan <- ggplot(bilan_total, aes(x = zone)) +
  geom_col(aes(y = nb_batiments_aoi),     fill = "#AEC6CF", alpha = 0.9) +
  geom_col(aes(y = nb_batiments_inondes), fill = "#C23B22") +
  geom_text(aes(y = nb_batiments_inondes,
                label = format(nb_batiments_inondes, big.mark = " ")),
            vjust = -0.4, size = 3.5, colour = "#C23B22") +
  scale_y_continuous(labels = comma) +
  labs(title    = "Batiments exposes aux inondations - Yagoua, oct. 2024",
       subtitle = "EMSR772 v2 - 3 AOI - bleu = total AOI / rouge = touches",
       caption  = "Sources : Copernicus EMSR772 v2 - Google Open Buildings v3 - IFORD x GDSG 2026",
       x = "Zone AOI", y = "Nombre de batiments (n)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))
print(g_bilan)
ggsave(file.path(out_dir, "jour08_bilan_3aoi.png"),
       g_bilan, width = 8, height = 5, dpi = 180)

write_csv(bilan_total,
          file.path(out_dir, "jour08_bilan_inondations_emsr772.csv"))

# Fin J8
