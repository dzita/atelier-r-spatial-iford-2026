# =====================================================================
# J06 — Statistiques spatiales sur OSM Cameroun (exécution salle)
# Atelier IFORD x GDSG · Yaoundé 1er août 2026
# Pipeline analytique : Jean Saturnin Alogo Samba (GDSG/IFORD)
# Bascule OSM + animation : R. Dzita
# Données 100% réelles : OSM + GADM, agrégation par département
# =====================================================================

library(sf)
library(ggplot2)
library(dplyr)
library(tidyr)
library(spdep)
library(readr)

# ---- 1. Charger facilités OSM + ADM2 GADM ---------------------------
source("../_commons/helpers/fetch_data.R")

etabs <- read_csv("../_commons/data/cmr_sante/etablissements_sante_osm.csv",
                  show_col_types = FALSE)
adm2 <- read_sf(fetch_gadm_cameroon(2))

n <- nrow(etabs)
cat("Facilités OSM    :", n, "\n")
cat("Départements ADM2 :", nrow(adm2), "\n")
print(table(etabs$categorie))

points_sf <- st_as_sf(etabs, coords = c("longitude","latitude"), crs = 4326)

# ---- 2. Ratio R (motifs ponctuels) ----------------------------------
coords <- cbind(etabs$longitude, etabs$latitude)
nn1 <- knearneigh(coords, k = 1)
nb1 <- knn2nb(nn1)
D_obs <- mean(unlist(nbdists(nb1, coords)))
D_att <- 0.5 / sqrt(n / (diff(range(etabs$longitude)) * diff(range(etabs$latitude))))
R <- D_obs / D_att
cat("Ratio R =", round(R, 3), "->",
    ifelse(R < 0.85, "REGROUPE", ifelse(R > 1.15, "DISPERSE", "ALEATOIRE")), "\n")

# ---- 3. KDE (densité par noyau, sur les points) ---------------------
h_scott <- 1.06 * sd(etabs$longitude) * n^(-1/5)
n_grille <- 100
lon_seq <- seq(min(etabs$longitude)-0.5, max(etabs$longitude)+0.5, length.out = n_grille)
lat_seq <- seq(min(etabs$latitude)-0.5,  max(etabs$latitude)+0.5,  length.out = n_grille)
grille <- expand.grid(lon = lon_seq, lat = lat_seq)
kde <- numeric(nrow(grille))
for (i in seq_len(nrow(grille))) {
  d2 <- (grille$lon[i] - etabs$longitude)^2 + (grille$lat[i] - etabs$latitude)^2
  kde[i] <- sum(exp(-d2 / (2 * h_scott^2)))
}
grille$densite <- kde / (n * 2 * pi * h_scott^2)

ggplot() +
  geom_raster(data = grille, aes(lon, lat, fill = densite), interpolate = TRUE) +
  scale_fill_gradientn(colors = c("#FFFFF0","#FFEDA0","#FD8D3C","#E31A1C","#800026")) +
  geom_point(data = etabs, aes(longitude, latitude), color = "white", size = 0.5) +
  labs(title = "KDE — Facilités OSM Cameroun") +
  theme_minimal()

# ---- 4. Agrégation par département ADM2 (variable réelle) -----------
adm2_lambert <- adm2 |> st_transform(3119) |> st_make_valid()
points_lambert <- points_sf |> st_transform(3119)

etabs_in_dep <- points_lambert |>
  st_join(adm2_lambert |> select(GID_2, NAME_2, NAME_1), join = st_within)

n_par_dep <- etabs_in_dep |>
  st_drop_geometry() |>
  filter(!is.na(GID_2)) |>
  count(GID_2, name = "n_facilites")

adm2_n <- adm2_lambert |>
  left_join(n_par_dep, by = "GID_2") |>
  mutate(n_facilites = replace_na(n_facilites, 0L))

cat("Top 10 départements équipés :\n")
print(adm2_n |> st_drop_geometry() |>
        arrange(desc(n_facilites)) |>
        select(NAME_1, NAME_2, n_facilites) |> head(10))

# Carte choroplèthe des comptages
ggplot(adm2_n) +
  geom_sf(aes(fill = n_facilites), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "B", trans = "sqrt", name = "Nb facilités") +
  labs(title = "Nombre de facilités OSM par département — Cameroun") +
  theme_minimal()

# ---- 5. Moran's I global (sur n_facilites par département) ---------
adm2_sp <- adm2_n |> filter(!st_is_empty(geometry))
nb_cont <- poly2nb(adm2_sp, queen = TRUE)
W <- nb2listw(nb_cont, style = "W", zero.policy = TRUE)

moran <- moran.test(adm2_sp$n_facilites, W, zero.policy = TRUE)
print(moran)

# ---- 6. LISA local + carte clusters --------------------------------
lisa <- localmoran(adm2_sp$n_facilites, W, zero.policy = TRUE)
adm2_sp$lisa_p <- lisa[, "Pr(z != E(Ii))"]
z_v   <- as.numeric(scale(adm2_sp$n_facilites))
z_lag <- as.numeric(lag.listw(W, z_v, zero.policy = TRUE))

adm2_sp$quadrant <- case_when(
  z_v > 0 & z_lag > 0 & adm2_sp$lisa_p < 0.05 ~ "HH",
  z_v < 0 & z_lag < 0 & adm2_sp$lisa_p < 0.05 ~ "LL",
  z_v > 0 & z_lag < 0 & adm2_sp$lisa_p < 0.05 ~ "HL",
  z_v < 0 & z_lag > 0 & adm2_sp$lisa_p < 0.05 ~ "LH",
  TRUE                                          ~ "NS"
)
print(table(adm2_sp$quadrant))

ggplot(adm2_sp) +
  geom_sf(aes(fill = quadrant), color = "white", linewidth = 0.2) +
  scale_fill_manual(values = c(HH = "#C0392B", LL = "#2980B9",
                                HL = "#E67E22", LH = "#8E44AD", NS = "#BDC3C7")) +
  labs(title = "Carte LISA — offre de soins OSM par département",
       caption = "© OSM (ODbL) · GADM v4.1") +
  theme_minimal()

# ---- 7. Liste des déserts médicaux (LL) ----------------------------
adm2_sp |>
  st_drop_geometry() |>
  filter(quadrant == "LL") |>
  select(NAME_1, NAME_2, n_facilites) |>
  arrange(n_facilites)

# Fin J6
