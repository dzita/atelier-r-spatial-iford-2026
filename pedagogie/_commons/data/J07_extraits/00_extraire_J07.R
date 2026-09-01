# =====================================================================
# 00_extraire_J07.R
# Atelier IFORD x GDSG 2026 - J07 « Statistiques spatiales »
#
# A QUOI SERT CE SCRIPT
#   Le runtime WebR (pedagogie/J07_statistiques_spatiales/runtime.qmd) ne
#   peut CALCULER aucune des statistiques de la journee : ni spdep
#   (voisinages, Moran, LISA, Getis-Ord), ni spatstat (processus ponctuels,
#   K de Ripley, KDE), ni haven (lecture des .SAV), ne sont disponibles
#   dans le navigateur.
#
#   Le parti pris de la journee est donc :
#     - CE SCRIPT calcule -- une fois, sur le poste de l'animateur -- les
#       resultats, et les ecrit comme COLONNES D'UN GEOJSON et comme
#       COURBES DANS DES CSV ;
#     - LE RUNTIME les CARTOGRAPHIE et fait travailler leur INTERPRETATION :
#       ce qu'est un quadrant « haut-haut », pourquoi un LISA n'est pas une
#       carte de valeurs, ce que le nombre de voisins change au resultat.
#     Le calcul lui-meme reste montre dans le runtime, en bloc `r` lecture
#     seule, avec renvoi a demo_formateur_J7.qmd.
#
# QUAND LE RELANCER
#   - a la premiere mise en place du depot ;
#   - si l'indicateur cartographie change (section 2) ;
#   - a chaque fois qu'on change la MATRICE DE POIDS : le resultat en depend,
#     et c'est precisement ce que le runtime fait constater.
#
# A EXECUTER PAR L'UTILISATEUR LUI-MEME.
#   La session qui a ecrit ce fichier ne disposait NI de R, NI de shell :
#   rien n'a ete execute. Les points « A VALIDER AU PREMIER RENDU » sont des
#   hypotheses sur le contenu des binaires.
#
# ENTREES (dans pedagogie/J07_statistiques_spatiales/datasets/ ; les deux
# fichiers EDS de menages vivent dans le dossier du J05 ou du J06 selon la
# distribution -- le chemin est resolu par .trouver() ci-dessous)
#   DS.geojson         200 districts sanitaires (135 geometries invalides)
#   CMGE71FL.shp       430 grappes EDS geolocalisees
#   CMGC72FL.csv       430 grappes x 130 covariables contextuelles
#   CMHR71FL.SAV       recode menage EDS 2018 (indicateur a cartographier)
#   Pays_limitrophes_Cmr.shp  fenetre d'observation pour spatstat
#
# SORTIES (dans _commons/data/J07_extraits/) -- CONTRAT AVEC LE RUNTIME :
#   ds_autocorrelation.geojson  200 DS : valeur, lag, LISA, quadrant, Gi*
#   moran_global.csv            I de Moran par matrice de poids
#   voisinage_liens.csv         aretes du graphe de voisinage (2 matrices)
#   fonctions_ponctuelles.csv   courbes G, K, L + enveloppes Monte-Carlo
#   kde_grappes_grille.csv      surfaces KDE (3 bandwidths, 3 sous-populations)
#   quadrat_test.csv            comptages observes / attendus sous CSR
#   J07_extraits_README.csv     documentation des sorties
#   Ne pas renommer sans corriger runtime.qmd (webr.resources ET lectures).
#
# Usage :
#   source("pedagogie/_commons/data/J07_extraits/00_extraire_J07.R")
#
# Dependances :
#   install.packages(c("sf", "spdep", "spatstat", "spatstat.explore",
#                      "spatstat.geom", "haven", "dplyr", "tidyr", "readr",
#                      "stringr", "stringi", "rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 600)
set.seed(20260901)   # les enveloppes Monte-Carlo doivent etre reproductibles

.deps <- c("sf", "spdep", "spatstat.explore", "spatstat.geom", "haven",
           "dplyr", "tidyr", "readr", "stringr", "stringi", "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J07-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(sf)
  library(spdep)
  library(spatstat.geom)
  library(spatstat.explore)
  library(haven)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
})

sf_use_s2(FALSE)

.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

dir_j07 <- file.path(.PROJECT_ROOT, "pedagogie", "J07_statistiques_spatiales",
                     "datasets")
dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J07_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# CMHR71FL.SAV n'est pas dans datasets/ du J07 (regle 6.4 : on ne garde que
# ce que la journee LIT). On le cherche dans les dossiers voisins.
.trouver <- function(nom) {
  base <- file.path(.PROJECT_ROOT, "pedagogie")
  candidats <- c(
    file.path(base, "J07_statistiques_spatiales", "datasets", nom),
    file.path(base, "J06_art_cartographie",       "datasets", nom),
    file.path(base, "J05_enquetes_carte",         "datasets", nom),
    file.path(base, "all_data",                   nom)
  )
  ok <- candidats[file.exists(candidats)]
  if (length(ok) == 0)
    stop("[J07-extrait] Introuvable : ", nom,
         "\n  -> lancer source(\"outils/distribuer_donnees.R\") d'abord.")
  ok[1]
}

TOL_DS <- 0.005   # degres ; ~0,55 km

# ----------------------------------------------------------------------
# 1. Les districts sanitaires : les unites de l'analyse d'autocorrelation
# ----------------------------------------------------------------------
message("[J07-extrait] Lecture DS.geojson (~20 Mo)...")
ds <- st_read(file.path(dir_j07, "DS.geojson"), quiet = TRUE)
cat(sprintf("[J07-extrait] DS : %d entites ; geometries valides AVANT reparation : %d\n",
            nrow(ds), sum(st_is_valid(ds))))
ds <- st_make_valid(ds) |>
  mutate(ds_nom    = str_squish(str_remove(name,       "^District\\s*")),
         region_ds = str_squish(str_remove(parentName, "^Region\\s*"))) |>
  select(ds_nom, region_ds)
cat(sprintf("[J07-extrait] DS valides APRES st_make_valid() : %d\n", sum(st_is_valid(ds))))

# ----------------------------------------------------------------------
# 2. L'indicateur cartographie : acces a une source d'eau AMELIOREE
#    (definition JMP OMS/UNICEF -- ce n'est PAS « eau potable »)
# ----------------------------------------------------------------------
message("[J07-extrait] Lecture EDS menages (CMHR71FL.SAV)...")
f_sav <- .trouver("CMHR71FL.SAV")
vars_voulues <- c("hv001", "hv005", "hv009", "hv201", "hv206")
noms_sav <- names(read_sav(f_sav, n_max = 0))
vars     <- noms_sav[match(toupper(vars_voulues), toupper(noms_sav))]
if (anyNA(vars)) {
  warning("[J07-extrait] Variables EDS introuvables : ",
          paste(vars_voulues[is.na(vars)], collapse = ", "))
  vars <- na.omit(vars)
}
hr <- read_sav(f_sav, col_select = all_of(as.character(vars)))
names(hr) <- tolower(names(hr))

# A VALIDER AU PREMIER RENDU : verifier que les codes hv201 imprimes sont
# bien couverts par la liste JMP ci-dessous.
codes_eau_amelioree <- c(11, 12, 13, 14, 21, 31, 41, 51, 61, 62, 71, 72)
cat("[J07-extrait] Codes hv201 presents :\n")
print(sort(unique(as.numeric(hr$hv201))))

grappes_ind <- hr |>
  mutate(grappe = as.numeric(hv001),
         poids  = as.numeric(hv005) / 1e6,
         eau    = as.numeric(as.numeric(hv201) %in% codes_eau_amelioree),
         elec   = as.numeric(as.numeric(hv206) == 1)) |>
  group_by(grappe) |>
  summarise(n_menages        = n(),
            poids_total      = sum(poids),
            tx_eau_amelioree = 100 * sum(eau  * poids) / sum(poids),
            tx_electricite   = 100 * sum(elec * poids) / sum(poids),
            .groups = "drop")

ge <- st_read(file.path(dir_j07, "CMGE71FL.shp"), quiet = TRUE) |> st_make_valid()
cat(sprintf("[J07-extrait] Grappes en (0,0) exclues : %d sur %d\n",
            sum(ge$LATNUM == 0 & ge$LONGNUM == 0), nrow(ge)))
ge <- ge |> filter(!(LATNUM == 0 & LONGNUM == 0))

pts <- ge |>
  st_drop_geometry() |>
  transmute(dhsclust = DHSCLUST, milieu = URBAN_RURA,
            region_eds = ADM1NAME, lon = LONGNUM, lat = LATNUM) |>
  left_join(grappes_ind, by = c("dhsclust" = "grappe")) |>
  filter(!is.na(lon), !is.na(lat)) |>
  # ORDRE c(longitude, latitude) : l'inversion ne leve aucune erreur, elle
  # place simplement les points ailleurs.
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)

if (st_crs(pts) != st_crs(ds)) ds <- st_transform(ds, st_crs(pts))

n_avant <- nrow(pts)
pts_ds <- st_join(pts, ds, join = st_within) |>
  distinct(dhsclust, .keep_all = TRUE)
cat(sprintf("[J07-extrait] st_join : %d points avant, %d apres deduplication\n",
            n_avant, nrow(pts_ds)))
i_orph <- which(is.na(pts_ds$ds_nom))
cat(sprintf("[J07-extrait] Grappes recalees (st_nearest_feature) : %d\n", length(i_orph)))
if (length(i_orph) > 0) {
  j <- st_nearest_feature(pts_ds[i_orph, ], ds)
  pts_ds$ds_nom[i_orph]    <- ds$ds_nom[j]
  pts_ds$region_ds[i_orph] <- ds$region_ds[j]
}

ds_ind <- pts_ds |>
  st_drop_geometry() |>
  filter(!is.na(tx_eau_amelioree)) |>
  group_by(ds_nom) |>
  summarise(n_grappes        = n(),
            tx_eau_amelioree = sum(tx_eau_amelioree * poids_total) /
                               sum(poids_total),
            tx_electricite   = sum(tx_electricite   * poids_total) /
                               sum(poids_total),
            .groups = "drop")

ds_val <- ds |> left_join(ds_ind, by = "ds_nom")
cat(sprintf("[J07-extrait] Districts renseignes : %d / %d -- soit %d districts SANS aucune observation.\n",
            sum(!is.na(ds_val$tx_eau_amelioree)), nrow(ds_val),
            sum(is.na(ds_val$tx_eau_amelioree))))

# DECISION DE METHODE, a assumer devant la salle. spdep ne sait pas traiter
# un NA : toute unite sans valeur casserait le calcul du I de Moran. Deux
# voies possibles :
#   (a) restreindre l'analyse aux districts renseignes -- mais le graphe de
#       voisinage se troue et des districts deviennent des iles ;
#   (b) imputer par la moyenne de la region -- ce qu'on fait ici, en TRACANT
#       l'imputation dans une colonne dediee.
# L'imputation par une moyenne ECRASE LA VARIANCE et tire mecaniquement le
# I de Moran vers le haut (des voisins imputes par la meme valeur se
# ressemblent par construction). Le runtime doit le dire.
ds_val <- ds_val |>
  group_by(region_ds) |>
  mutate(impute = is.na(tx_eau_amelioree),
         tx_eau = ifelse(impute, mean(tx_eau_amelioree, na.rm = TRUE),
                         tx_eau_amelioree)) |>
  ungroup() |>
  mutate(tx_eau = ifelse(is.na(tx_eau), mean(tx_eau, na.rm = TRUE), tx_eau))
cat(sprintf("[J07-extrait] Valeurs imputees : %d (%.0f %% des districts)\n",
            sum(ds_val$impute), 100 * mean(ds_val$impute)))

# ----------------------------------------------------------------------
# 3. Les matrices de poids spatiaux -- LE choix qui commande tout
# ----------------------------------------------------------------------
# Une statistique d'autocorrelation ne mesure rien « en soi » : elle mesure
# la ressemblance entre unites SELON UNE DEFINITION DU VOISINAGE. Changer
# cette definition change le resultat. On en calcule donc DEUX, pour que le
# runtime puisse les comparer.
#
#   (a) contiguite Queen : deux districts sont voisins s'ils partagent au
#       moins un point de frontiere. Nombre de voisins VARIABLE ;
#   (b) k plus proches voisins, k = 4 : chaque district a exactement 4
#       voisins, meme s'ils sont loin. Nombre de voisins CONSTANT.
#
# style = "W" : ligne-standardisee, la somme des poids d'une ligne vaut 1.
# Chaque unite pese alors autant, quel que soit son nombre de voisins.
message("[J07-extrait] Construction des matrices de poids...")
nb_queen <- poly2nb(ds_val, queen = TRUE)
cat(sprintf("[J07-extrait] Contiguite Queen : %.2f voisins en moyenne ; unites SANS voisin : %d\n",
            mean(card(nb_queen)), sum(card(nb_queen) == 0)))

coords <- suppressWarnings(st_coordinates(st_centroid(st_geometry(ds_val))))
nb_knn4 <- knn2nb(knearneigh(coords, k = 4))
cat(sprintf("[J07-extrait] k plus proches voisins (k=4) : %.2f voisins par unite\n",
            mean(card(nb_knn4))))

# zero.policy = TRUE : une ile (district sans voisin contigu) recoit un lag
# nul plutot que d'interrompre le calcul. On l'a compte ci-dessus.
lw_queen <- nb2listw(nb_queen, style = "W", zero.policy = TRUE)
lw_knn4  <- nb2listw(nb_knn4,  style = "W", zero.policy = TRUE)

# --- Les aretes du graphe, pour que le runtime puisse le DESSINER ---------
aretes <- function(nb, nom) {
  n <- length(nb)
  do.call(rbind, lapply(seq_len(n), function(i) {
    v <- nb[[i]]
    if (length(v) == 0 || identical(v, 0L)) return(NULL)
    data.frame(matrice = nom, de = i, vers = v,
               de_lon = coords[i, 1], de_lat = coords[i, 2],
               vers_lon = coords[v, 1], vers_lat = coords[v, 2])
  }))
}
liens <- bind_rows(aretes(nb_queen, "contiguite_queen"),
                   aretes(nb_knn4,  "knn4"))
write_csv(liens, file.path(dir_out, "voisinage_liens.csv"))
cat(sprintf("[J07-extrait] voisinage_liens.csv : %d aretes (%s)\n",
            nrow(liens),
            paste(names(table(liens$matrice)), table(liens$matrice),
                  sep = " = ", collapse = " ; ")))

# ----------------------------------------------------------------------
# 4. I de Moran global, sur les deux matrices et deux variables
# ----------------------------------------------------------------------
# I > 0 : les valeurs semblables se touchent (agregation) ;
# I < 0 : damier, les voisins se ressemblent MOINS que le hasard ;
# I ~ E[I] = -1/(n-1) : indiscernable d'une repartition aleatoire.
# Le test de permutation (Monte-Carlo) ne suppose PAS la normalite : c'est
# celui a preferer sur des taux bornes a [0, 100].
moran_1 <- function(x, lw, variable, matrice) {
  mt <- moran.test(x, lw, zero.policy = TRUE)
  mc <- moran.mc(x, lw, nsim = 999, zero.policy = TRUE)
  tibble(variable = variable, matrice = matrice,
         n = length(x),
         moran_i = unname(mt$estimate[1]),
         esperance = unname(mt$estimate[2]),
         variance = unname(mt$estimate[3]),
         z = unname(mt$statistic),
         p_normalite = unname(mt$p.value),
         p_permutation = mc$p.value,
         nsim = 999,
         voisins_moyen = mean(card(lw$neighbours)))
}
# Seconde variable, imputee de la meme facon (moyenne generale ici : elle ne
# sert qu'a montrer que le I depend AUSSI du phenomene, pas seulement de W).
tx_elec <- ds_val$tx_electricite
tx_elec[is.na(tx_elec)] <- mean(tx_elec, na.rm = TRUE)

moran_global <- bind_rows(
  moran_1(ds_val$tx_eau, lw_queen, "tx_eau_amelioree", "contiguite_queen"),
  moran_1(ds_val$tx_eau, lw_knn4,  "tx_eau_amelioree", "knn4"),
  moran_1(tx_elec,       lw_queen, "tx_electricite",   "contiguite_queen")
)
write_csv(moran_global, file.path(dir_out, "moran_global.csv"))
cat("[J07-extrait] I de Moran global :\n")
print(as.data.frame(moran_global))

# ----------------------------------------------------------------------
# 5. LISA (Moran local) et Getis-Ord Gi*
# ----------------------------------------------------------------------
# LISA decompose le I global en contributions locales. Les quadrants :
#   HH  valeur haute entouree de valeurs hautes   (point chaud)
#   LL  valeur basse entouree de valeurs basses   (point froid)
#   HL  valeur haute entouree de valeurs basses   (atypique positif)
#   LH  valeur basse entouree de valeurs hautes   (atypique negatif)
# ATTENTION : la carte LISA n'est PAS une carte de valeurs. Un district
# « HH » n'est pas le plus eleve du pays : c'est un district au-dessus de la
# moyenne DONT LES VOISINS le sont aussi.
message("[J07-extrait] LISA et Getis-Ord...")
x   <- ds_val$tx_eau
z   <- as.numeric(scale(x))                    # variable centree-reduite
lag <- lag.listw(lw_queen, z, zero.policy = TRUE)  # moyenne des voisins

lm_res <- localmoran(x, lw_queen, zero.policy = TRUE)
SEUIL_P <- 0.05   # seuil DECLARE, pas subi

ds_val <- ds_val |>
  mutate(
    tx_eau_std   = z,
    lag_std      = lag,
    lisa_ii      = lm_res[, "Ii"],
    lisa_z       = lm_res[, "Z.Ii"],
    lisa_p       = lm_res[, ncol(lm_res)],
    quadrant = case_when(
      lisa_p > SEUIL_P            ~ "non significatif",
      z > 0 & lag > 0             ~ "HH - haut entoure de haut",
      z < 0 & lag < 0             ~ "LL - bas entoure de bas",
      z > 0 & lag < 0             ~ "HL - haut entoure de bas",
      z < 0 & lag > 0             ~ "LH - bas entoure de haut",
      TRUE                        ~ "non significatif"
    )
  )
cat("[J07-extrait] Repartition des quadrants LISA :\n")
print(table(ds_val$quadrant))

# Getis-Ord Gi* : meme famille, autre question. Le LISA repond « ce district
# se ressemble-t-il a ses voisins ? » ; Gi* repond « la somme locale est-elle
# anormalement haute ou basse ? ». include.self() ajoute l'unite a son propre
# voisinage : c'est ce qui distingue Gi* de Gi.
lw_self <- nb2listw(include.self(nb_queen), style = "W", zero.policy = TRUE)
gi <- as.numeric(localG(x, lw_self, zero.policy = TRUE))
ds_val <- ds_val |>
  mutate(
    gi_z = gi,
    # Seuils classiques du z-score : 1,96 = 5 %, 2,58 = 1 % (bilateral).
    gi_classe = cut(gi_z,
                    breaks = c(-Inf, -2.58, -1.96, 1.96, 2.58, Inf),
                    labels = c("froid 99 %", "froid 95 %", "non significatif",
                               "chaud 95 %", "chaud 99 %")),
    nb_voisins = card(nb_queen)
  )
cat("[J07-extrait] Repartition des classes Gi* :\n")
print(table(ds_val$gi_classe))
cat("[J07-extrait] Concordance LISA x Gi* :\n")
print(table(ds_val$quadrant, ds_val$gi_classe))

# --- Simplifier, puis ecrire ----------------------------------------------
# st_simplify (Douglas-Peucker) : tolerance en DEGRES (EPSG:4326).
# CE QUE CELA COUTE : les frontieres perdent leur detail ; deux voisins
# peuvent cesser de coincider exactement. Cette couche sert a AFFICHER.
# Point capital : le VOISINAGE a ete construit sur la geometrie NON
# simplifiee. Simplifier avant poly2nb() aurait pu separer deux polygones
# qui se touchaient et donc CHANGER le I de Moran. L'ordre des operations
# est ici une decision de methode, pas un detail technique.
ds_simp <- st_simplify(ds_val, dTolerance = TOL_DS, preserveTopology = TRUE)
f_ds <- file.path(dir_out, "ds_autocorrelation.geojson")
st_write(ds_simp, f_ds, delete_dsn = TRUE, quiet = TRUE)
cat(sprintf("[J07-extrait] %s : %d entites, %.0f Ko\n",
            basename(f_ds), nrow(ds_simp), file.size(f_ds) / 1024))

# ----------------------------------------------------------------------
# 6. Processus ponctuels : quadrat, G, K, L -- courbes pre-calculees
# ----------------------------------------------------------------------
# spatstat travaille en coordonnees PLANES. On reprojette en UTM 33N
# (EPSG:32633) : sur des degres, K(r) et G(r) n'auraient pas de sens
# metrique -- « r = 0,1 » ne serait ni une distance ni une surface.
message("[J07-extrait] Processus ponctuels (spatstat)...")
pays <- st_union(st_transform(ds_val, 32633))
pts_utm <- st_transform(pts_ds, 32633)
xy <- st_coordinates(pts_utm)

# CORRECTIF 01/09/2026. La ligne etait : as.owin(st_as_sfc(pays)).
# st_union() renvoie deja un sfc, pas un sf : st_as_sfc() n'avait donc rien
# a convertir et echouait sur
#   « pas de methode pour 'st_as_sfc' applicable pour un objet de classe
#     c('sfc_MULTIPOLYGON', 'sfc') ».
# Selon la version de spatstat.geom, as.owin() accepte un sfc, un sf, ou
# ni l'un ni l'autre. On essaie dans cet ordre et on echoue en nommant la
# cause, plutot que de laisser un message obscur arreter tout le script.
fen <- tryCatch(
  as.owin(pays),
  error = function(e1) tryCatch(
    as.owin(st_as_sf(pays)),
    error = function(e2)
      stop("[J07-extrait] Impossible de construire la fenetre spatstat ",
           "a partir de la couche des districts.\n",
           "  as.owin(sfc) : ", conditionMessage(e1), "\n",
           "  as.owin(sf)  : ", conditionMessage(e2), "\n",
           "  Verifiez la version de spatstat.geom (>= 3.0 attendue).",
           call. = FALSE)))
# CORRECTIF 01/09/2026 -- ALIGNEMENT DES POINTS ET DE LEURS ATTRIBUTS.
#
# ppp() ecarte silencieusement les points hors fenetre. Les grappes EDS ont
# des coordonnees VOLONTAIREMENT DEPLACEES par le DHS (2 km en urbain, 5 km
# en rural, 10 km pour 1 % des grappes rurales) : certaines tombent donc
# hors du contour du pays. C'est attendu, ce n'est pas une erreur de donnee.
#
# Ce qui, en revanche, etait un bug : la section KDE plus bas reprenait les
# libelles urbain/rural par pts_utm$milieu[seq_len(npoints(pp))], donc les
# N PREMIERS, en supposant que le point ecarte soit le dernier. Il ne l'est
# pas. A partir du rang du point rejete, chaque grappe recevait le libelle
# de la suivante -- et les cartes de densite « urbain » et « rural »
# melangeaient les deux, sans qu'aucune erreur ne soit levee.
#
# On filtre donc AVANT de construire pp, avec la fenetre elle-meme comme
# critere : xy et pts_utm restent alignes par construction.
dedans <- inside.owin(xy[, 1], xy[, 2], fen)
n_rejetes <- sum(!dedans)

if (n_rejetes > 0) {
  cat(sprintf("[J07-extrait] %d grappe(s) hors du contour, ecartee(s) AVANT ppp :\n",
              n_rejetes))
  print(utils::head(sf::st_drop_geometry(pts_utm)[!dedans,
        intersect(c("DHSCLUST", "milieu", "ds_nom"), names(pts_utm))], 10))
  cat("  (deplacement DHS : attendu, cf. note ci-dessus)\n")
}

pts_utm <- pts_utm[dedans, ]
xy      <- xy[dedans, , drop = FALSE]

pp  <- ppp(x = xy[, 1], y = xy[, 2], window = fen)

# Controle : plus aucun point ne doit etre rejete a ce stade.
if (npoints(pp) != nrow(xy))
  stop("[J07-extrait] ", nrow(xy) - npoints(pp), " point(s) encore rejete(s) ",
       "par ppp() apres filtrage. L'alignement des attributs n'est pas sur : ",
       "ne pas utiliser les sorties KDE.", call. = FALSE)

cat(sprintf("[J07-extrait] ppp : %d points, 0 rejete (alignement garanti)\n",
            npoints(pp)))

# --- 6.1 Test du quadrat : la fenetre est decoupee en cellules, on compare
# les effectifs observes aux effectifs attendus sous processus de Poisson
# homogene (CSR : Complete Spatial Randomness).
qt <- quadrat.test(pp, nx = 8, ny = 8)
qc <- quadratcount(pp, nx = 8, ny = 8)
# CORRECTIF 01/09/2026. Le code posait trois noms sur le retour de
# as.data.frame(qc), et echouait sur
#   « 'names' attribute [3] must be the same length as the vector [2] ».
# as.data.frame() sur un quadratcount ne renvoie pas le meme nombre de
# colonnes selon la version de spatstat.geom : tantot 3 (ligne, colonne,
# effectif), tantot 2. On passe donc par as.table(), dont la forme est
# stable, et on nomme d'apres ce qu'on RECOIT plutot que d'apres ce qu'on
# suppose.
quadrat_df <- as.data.frame(as.table(qc), stringsAsFactors = FALSE)

if (ncol(quadrat_df) == 3L) {
  # Cas 2D attendu : Var1 = bande en Y (ligne), Var2 = bande en X (colonne).
  names(quadrat_df) <- c("ligne", "colonne", "observe")
} else if (ncol(quadrat_df) == 2L) {
  # La table est arrivee a plat : on conserve l'identifiant de cellule tel
  # quel plutot que d'inventer un decoupage ligne x colonne.
  names(quadrat_df) <- c("cellule", "observe")
  message("[J07-extrait] quadratcount aplati en 2 colonnes ",
          "(version de spatstat.geom) : colonne 'cellule' au lieu de ",
          "'ligne' + 'colonne'. Le runtime doit en tenir compte.")
} else {
  stop("[J07-extrait] Forme inattendue de quadratcount : ",
       ncol(quadrat_df), " colonnes (", paste(names(quadrat_df),
       collapse = ", "), "). Attendu 2 ou 3.", call. = FALSE)
}

quadrat_df <- quadrat_df |>
  mutate(attendu_csr = npoints(pp) / nrow(quadrat_df),
         statistique = as.numeric(qt$statistic),
         ddl         = as.numeric(qt$parameter),
         p_value     = as.numeric(qt$p.value),
         nx = 8, ny = 8)
write_csv(quadrat_df, file.path(dir_out, "quadrat_test.csv"))
cat(sprintf("[J07-extrait] Test du quadrat 8x8 : X2 = %.1f, ddl = %d, p = %.4g\n",
            qt$statistic, qt$parameter, qt$p.value))

# --- 6.2 G (plus proche voisin), K de Ripley et sa transformee L, avec
# enveloppes Monte-Carlo. 39 simulations donnent un test bilateral a 5 %.
# ATTENTION AU TEMPS DE CALCUL : quelques minutes sur 400+ points.
NSIM <- 39
env_G <- envelope(pp, Gest, nsim = NSIM, verbose = FALSE)
env_K <- envelope(pp, Kest, nsim = NSIM, verbose = FALSE)
env_L <- envelope(pp, Lest, nsim = NSIM, verbose = FALSE)

vers_df <- function(e, nom) {
  as.data.frame(e)[, c("r", "obs", "theo", "lo", "hi")] |>
    mutate(fonction = nom, nsim = NSIM)
}
fonctions <- bind_rows(vers_df(env_G, "G"),
                       vers_df(env_K, "K"),
                       vers_df(env_L, "L"))
write_csv(fonctions, file.path(dir_out, "fonctions_ponctuelles.csv"))
cat(sprintf("[J07-extrait] fonctions_ponctuelles.csv : %d lignes (G, K, L x %d rayons)\n",
            nrow(fonctions), nrow(fonctions) / 3))

# ----------------------------------------------------------------------
# 7. KDE : trois largeurs de bande, trois sous-populations
#    Le runtime ne peut pas appeler density.ppp : il lit la grille.
# ----------------------------------------------------------------------
# La largeur de bande h est LE parametre de la KDE :
#   h trop petit -> surface bosselee qui suit chaque point (sur-ajustement) ;
#   h trop grand -> surface lisse qui efface les concentrations locales.
# On en exporte trois pour que le participant voie que la carte change
# alors que les points, eux, ne bougent pas.
message("[J07-extrait] Estimation de densite par noyau...")
h_scott <- as.numeric(bw.scott(pp))[1]
bandwidths <- c(petit = h_scott / 2, scott = h_scott, grand = h_scott * 2)
cat(sprintf("[J07-extrait] bandwidths (m) : petit %.0f, scott %.0f, grand %.0f\n",
            bandwidths[1], bandwidths[2], bandwidths[3]))

# CORRECTIF 01/09/2026. Le code prenait pts_utm$milieu[seq_len(npoints(pp))],
# c'est-a-dire les N PREMIERS libelles, en supposant que le point ecarte par
# ppp() soit le dernier. Le filtrage par inside.owin() a la section 6 rend
# desormais pts_utm et pp de meme longueur ET dans le meme ordre : on lit
# donc la colonne directement, sans decoupage.
stopifnot(nrow(pts_utm) == npoints(pp))

sous_pop <- list(
  tous   = rep(TRUE, npoints(pp)),
  urbain = pts_utm$milieu == "U",
  rural  = pts_utm$milieu == "R"
)
cat(sprintf("[J07-extrait] sous-populations : %d urbaines, %d rurales, %d NA\n",
            sum(sous_pop$urbain, na.rm = TRUE),
            sum(sous_pop$rural,  na.rm = TRUE),
            sum(is.na(pts_utm$milieu))))

grilles <- list()
for (nb_nom in names(bandwidths)) {
  for (sp_nom in names(sous_pop)) {
    sel <- sous_pop[[sp_nom]]
    sel[is.na(sel)] <- FALSE
    if (sum(sel) < 10) next
    d <- density(pp[sel], sigma = bandwidths[[nb_nom]], dimyx = c(120, 120))
    g <- as.data.frame(d)                       # colonnes x, y, value
    names(g)[3] <- "densite"
    grilles[[paste(nb_nom, sp_nom)]] <- g |>
      filter(!is.na(densite)) |>
      mutate(bandwidth = nb_nom, sigma_m = bandwidths[[nb_nom]],
             sous_population = sp_nom,
             densite = densite * 1e6)          # points par km2
  }
}
kde <- bind_rows(grilles)
# La grille reste en UTM 33N (EPSG:32633), en METRES. C'est VOLONTAIRE :
# une reprojection cellule par cellule en degres deformerait la grille, qui
# cesserait d'etre reguliere -- et geom_raster() exige une grille reguliere.
# Le runtime reprojette donc la COUCHE des districts en 32633 pour la
# superposer, jamais l'inverse.
kde <- kde |>
  select(x, y, densite, bandwidth, sigma_m, sous_population)

f_kde <- file.path(dir_out, "kde_grappes_grille.csv")
write_csv(kde, f_kde)
cat(sprintf("[J07-extrait] kde_grappes_grille.csv : %d lignes, %.1f Mo\n",
            nrow(kde), file.size(f_kde) / 1024^2))

# ----------------------------------------------------------------------
# 8. README des extraits + bilan de poids
# ----------------------------------------------------------------------
sorties <- c("ds_autocorrelation.geojson", "moran_global.csv",
             "voisinage_liens.csv", "fonctions_ponctuelles.csv",
             "kde_grappes_grille.csv", "quadrat_test.csv")
readme <- tibble(
  fichier = sorties,
  entites = c(nrow(ds_simp), nrow(moran_global), nrow(liens),
              nrow(fonctions), nrow(kde), nrow(quadrat_df)),
  unite   = c("district sanitaire", "test", "arete de voisinage",
              "point de courbe", "cellule de grille", "cellule de quadrat"),
  calcul  = c("spdep : localmoran + localG",
              "spdep : moran.test + moran.mc (999 permutations)",
              "spdep : poly2nb (queen) et knearneigh (k=4)",
              paste0("spatstat : Gest, Kest, Lest + enveloppes (", NSIM, " sim.)"),
              "spatstat : density.ppp, 3 bandwidths x 3 sous-populations",
              "spatstat : quadrat.test 8x8"),
  taille_ko = round(vapply(file.path(dir_out, sorties), file.size,
                           numeric(1)) / 1024)
)
write_csv(readme, file.path(dir_out, "J07_extraits_README.csv"))

cat("\n========================================================\n")
cat(" Extraction J07 pour WebR terminee.\n")
cat("========================================================\n")
cat(" Fichiers dans :\n  ", normalizePath(dir_out), "\n\n")
print(as.data.frame(readme))
cat(sprintf("\n Poids total des extraits : %.2f Mo\n",
            sum(readme$taille_ko) / 1024))
cat(" Rappel : le I de Moran depend de la matrice de poids ; les deux\n")
cat(" matrices exportees sont la pour que le runtime le fasse constater.\n")
