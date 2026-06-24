# =====================================================================
# J06 — Statistiques spatiales sur OSM Cameroun (exécution salle)
# Atelier IFORD x GDSG · Yaoundé 1er août 2026
# Pipeline analytique : Jean Saturnin Alogo Samba (GDSG/IFORD)
# Bascule OSM + animation : R. Dzita
# Données 100% réelles : OSM + GADM, agrégation par département
# =====================================================================

# Librairies socles : sf (spatial), ggplot2 (carto), dplyr/tidyr (tableaux),
# spdep (statistiques spatiales desktop), readr (lecture CSV).
library(sf)
library(ggplot2)
library(dplyr)
library(tidyr)
library(spdep)
library(readr)

# ---- 1. Charger facilités OSM + ADM2 GADM ---------------------------
# OSM = base mondiale collaborative (Overpass = API d'interrogation).
# GADM ADM2 = polygones administratifs niveau département.
source("../_commons/helpers/fetch_data.R")

etabs <- read_csv("../_commons/data/cmr_sante/etablissements_sante_osm.csv",
                  show_col_types = FALSE)
# st_make_valid() repare les vertices dupliques de GADM qui font planter
# st_join avec "Edge 0 is degenerate" — defense indispensable des le chargement.
adm2 <- read_sf(fetch_gadm_cameroon(2)) |> st_make_valid()

n <- nrow(etabs)
cat("Facilités OSM    :", n, "\n")
cat("Départements ADM2 :", nrow(adm2), "\n")
print(table(etabs$categorie))

# Conversion en objet spatial (CRS 4326 = WGS84 degrés).
points_sf <- st_as_sf(etabs, coords = c("longitude","latitude"), crs = 4326)

# ---- 2. Ratio R (motifs ponctuels) ----------------------------------
# Ratio R = compare la distance moyenne au plus proche voisin observée
# à celle attendue sous distribution complètement aléatoire (CSR).
coords <- cbind(etabs$longitude, etabs$latitude)
nn1 <- knearneigh(coords, k = 1)
nb1 <- knn2nb(nn1)
D_obs <- mean(unlist(nbdists(nb1, coords)))
D_att <- 0.5 / sqrt(n / (diff(range(etabs$longitude)) * diff(range(etabs$latitude))))
R <- D_obs / D_att
cat("Ratio R =", round(R, 3), "->",
    ifelse(R < 0.85, "REGROUPE", ifelse(R > 1.15, "DISPERSE", "ALEATOIRE")), "\n")

# ---- 3. KDE (densité par noyau, sur les points) ---------------------
# KDE = lissage : chaque point devient une cloche gaussienne, on additionne.
# h_scott = règle de Scott pour choisir la largeur de la cloche.
h_scott <- 1.06 * sd(etabs$longitude) * n^(-1/5)
n_grille <- 100
lon_seq <- seq(min(etabs$longitude)-0.5, max(etabs$longitude)+0.5, length.out = n_grille)
lat_seq <- seq(min(etabs$latitude)-0.5,  max(etabs$latitude)+0.5,  length.out = n_grille)
grille <- expand.grid(lon = lon_seq, lat = lat_seq)

# Pour chaque cellule de grille, somme des contributions des n points.
kde <- numeric(nrow(grille))
for (i in seq_len(nrow(grille))) {
  d2 <- (grille$lon[i] - etabs$longitude)^2 + (grille$lat[i] - etabs$latitude)^2
  kde[i] <- sum(exp(-d2 / (2 * h_scott^2)))
}
grille$densite <- kde / (n * 2 * pi * h_scott^2)

# Carte KDE : palette séquentielle clair -> foncé.
ggplot() +
  geom_raster(data = grille, aes(lon, lat, fill = densite), interpolate = TRUE) +
  geom_sf(data = adm2, fill = NA, color = "grey50", linewidth = 0.12) +
  scale_fill_gradientn(name = "Densité KDE\n(facilités / deg²)",
                       colors = c("#FFFFF0","#FFEDA0","#FD8D3C","#E31A1C","#800026")) +
  geom_point(data = etabs, aes(longitude, latitude), color = "white", size = 0.5) +
  labs(title = "Densité par noyau (KDE) des facilités de santé OSM",
       subtitle = paste0("Méthode : KDE · h_Scott = ", round(h_scott, 3), " °"),
       caption = "Source : OpenStreetMap Overpass · GADM v4.1 · IFORD x GDSG 2026",
       x = NULL, y = NULL) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

# ---- 4. Agrégation par département ADM2 (variable réelle) -----------
# Reprojection en Lambert Cameroun (EPSG:3119) pour calculs métriques.
adm2_lambert <- adm2 |> st_transform(3119) |> st_make_valid()
points_lambert <- points_sf |> st_transform(3119)

# Jointure spatiale st_within = chaque point hérite du polygone qui le contient.
etabs_in_dep <- points_lambert |>
  st_join(adm2_lambert |> select(GID_2, NAME_2, NAME_1), join = st_within)

# Comptage par département (GID_2 = identifiant unique ADM2).
n_par_dep <- etabs_in_dep |>
  st_drop_geometry() |>
  filter(!is.na(GID_2)) |>
  count(GID_2, name = "n_facilites")

# Recoller les comptages à la couche de polygones.
adm2_n <- adm2_lambert |>
  left_join(n_par_dep, by = "GID_2") |>
  mutate(n_facilites = replace_na(n_facilites, 0L))

cat("Top 10 départements équipés :\n")
print(adm2_n |> st_drop_geometry() |>
        arrange(desc(n_facilites)) |>
        select(NAME_1, NAME_2, n_facilites) |> head(10))

# Carte choroplèthe : transformation racine pour atténuer l'écart urbain/rural.
ggplot(adm2_n) +
  geom_sf(aes(fill = n_facilites), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(option = "B", trans = "sqrt", name = "Nb facilités\nOSM (n)") +
  labs(title = "Offre de soins par département — Cameroun",
       subtitle = "Méthode : agrégation spatiale (st_join + count) sur OSM ADM2",
       caption = "Source : OpenStreetMap Overpass · GADM v4.1 · IFORD x GDSG 2026",
       x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank(),
        plot.title = element_text(face = "bold"))

# ---- 5. Moran's I global (sur n_facilites par département) ---------
# Matrice de voisinage par contiguïté queen (partage au moins un point).
# Style "W" = normalisation ligne (somme des poids par département = 1).
adm2_sp <- adm2_n |> filter(!st_is_empty(geometry))
nb_cont <- poly2nb(adm2_sp, queen = TRUE)
W <- nb2listw(nb_cont, style = "W", zero.policy = TRUE)

# Test asymptotique officiel de spdep : I + p-valeur.
moran <- moran.test(adm2_sp$n_facilites, W, zero.policy = TRUE)
print(moran)

# ---- 6. LISA local + carte clusters --------------------------------
# LISA = Local Indicators of Spatial Association.
# Un I local par département + p-valeur permutationnelle.
lisa <- localmoran(adm2_sp$n_facilites, W, zero.policy = TRUE)
adm2_sp$lisa_p <- lisa[, "Pr(z != E(Ii))"]
z_v   <- as.numeric(scale(adm2_sp$n_facilites))           # valeur centrée-réduite
z_lag <- as.numeric(lag.listw(W, z_v, zero.policy = TRUE)) # moyenne des voisins

# 4 quadrants × significativité p < 0.05.
adm2_sp$quadrant <- case_when(
  z_v > 0 & z_lag > 0 & adm2_sp$lisa_p < 0.05 ~ "HH",
  z_v < 0 & z_lag < 0 & adm2_sp$lisa_p < 0.05 ~ "LL",
  z_v > 0 & z_lag < 0 & adm2_sp$lisa_p < 0.05 ~ "HL",
  z_v < 0 & z_lag > 0 & adm2_sp$lisa_p < 0.05 ~ "LH",
  TRUE                                          ~ "NS"
)
print(table(adm2_sp$quadrant))

# Carte LISA : palette divergente (rouge = chaud, bleu = froid, gris = neutre).
ggplot(adm2_sp) +
  geom_sf(aes(fill = quadrant), color = "white", linewidth = 0.2) +
  scale_fill_manual(name = "Quadrant LISA\n(p < 0.05)",
                    values = c(HH = "#C0392B", LL = "#2980B9",
                                HL = "#E67E22", LH = "#8E44AD", NS = "#BDC3C7")) +
  labs(title = "Clusters spatiaux LISA — offre de soins OSM par département",
       subtitle = "Méthode : Local Moran's I · Rouge HH = clusters équipés · Bleu LL = déserts médicaux",
       caption = "Source : OpenStreetMap Overpass · GADM v4.1 · IFORD x GDSG 2026",
       x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank(),
        plot.title = element_text(face = "bold"))

# ---- 7. Liste des déserts médicaux (LL) ----------------------------
adm2_sp |>
  st_drop_geometry() |>
  filter(quadrant == "LL") |>
  select(NAME_1, NAME_2, n_facilites) |>
  arrange(n_facilites)

# Fin J6
