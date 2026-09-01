# =====================================================================
# 00_extraire_J05.R
# Atelier IFORD x GDSG 2026 - J05 « Des enquetes a la carte »
#
# A QUOI SERT CE SCRIPT
#   Le runtime WebR (pedagogie/J05_enquetes_carte/runtime.qmd) tourne dans
#   le navigateur. Trois paquets dont la journee depend n'y sont PAS
#   disponibles :
#     - haven   (lecture .dta / .SAV)
#     - survey  (estimation ponderee avec plan de sondage)
#     - tmap    (cartographie thematique)
#   Le calcul lourd est donc fait ICI, une fois, sur le poste de
#   l'animateur ; le runtime ne fait plus que CARTOGRAPHIER et INTERPRETER
#   des sorties legeres (CSV + GeoJSON).
#
#   Regle de partage des roles :
#     - ce script PONDERE et AGREGE  -> il produit des taux ;
#     - le runtime ne repondere jamais -> il compare des mailles, discute
#       le biais de taille, l'erreur ecologique et le MAUP.
#
# QUAND LE RELANCER
#   - a la premiere mise en place du depot ;
#   - si un fichier de datasets/ est remplace (nouvelle vague ECAM ou EDS) ;
#   - si l'on change la definition d'un indicateur (ex. la liste JMP des
#     sources d'eau amelioree, section 3).
#   Sinon jamais : les sorties sont versionnees.
#
# A EXECUTER PAR L'UTILISATEUR LUI-MEME.
#   La session qui a ecrit ce fichier ne disposait NI de R, NI de shell :
#   rien de ce qui suit n'a ete execute. Les points marques
#   « A VALIDER AU PREMIER RENDU » sont des hypotheses sur le contenu des
#   binaires (.dta / .SAV / .shp), a confirmer a la premiere execution.
#
# ENTREES (toutes dans pedagogie/J05_enquetes_carte/datasets/)
#   ecam5.dta                  9 472 individus, 2 065 menages, 70 colonnes
#   CMHR71FL.SAV               recode menage EDS-MICS 2018 (72 Mo, MAJUSCULES)
#   CMGE71FL.shp (+ annexes)   430 grappes EDS geolocalisees
#   CMGC72FL.csv               430 grappes x 130 covariables contextuelles
#   DS.geojson                 200 districts sanitaires (135 geometries invalides)
#   gadm41_CMR_1.shp           10 regions administratives
#
# SORTIES (dans _commons/data/J05_extraits/) -- CONTRAT AVEC LE RUNTIME :
#   ecam5_pauvrete_region.csv        1 ligne / region administrative (10)
#   ecam5_pauvrete_region_milieu.csv 1 ligne / (region x milieu)
#   ecam5_taille_menages.csv         le biais de taille, chiffre
#   eds_grappes_eau.csv              1 ligne / grappe EDS (430 attendues)
#   cmr_regions_J05.geojson          ADM1 simplifie + indicateurs ECAM5
#   districts_sanitaires_J05.geojson 200 DS simplifies + indicateurs EDS
#   J05_extraits_README.csv          documentation des sorties
#   Les noms ci-dessus sont ceux que le runtime lit. Ne pas les changer
#   sans corriger runtime.qmd (bloc webr.resources ET appels read_sf/read.csv).
#
# Usage :
#   source("pedagogie/_commons/data/J05_extraits/00_extraire_J05.R")
#
# Dependances :
#   install.packages(c("sf", "haven", "dplyr", "tidyr", "readr",
#                      "stringr", "stringi", "rprojroot"),
#                    repos = "https://packagemanager.posit.co/cran/latest")
# =====================================================================

options(timeout = 600)

.deps <- c("sf", "haven", "dplyr", "tidyr", "readr", "stringr",
           "stringi", "rprojroot")
.miss <- .deps[!vapply(.deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(.miss) > 0) {
  message("[J05-extrait] Installation de : ", paste(.miss, collapse = ", "))
  install.packages(.miss,
                   repos = "https://packagemanager.posit.co/cran/latest")
}

suppressPackageStartupMessages({
  library(sf)
  library(haven)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
})

# Les geometries de DS.geojson sont sales (135 invalides sur 200). Le moteur
# spherique s2 refuse ce que GEOS accepte : on le desactive pour tout le
# script, comme le fait le demo_formateur du J05.
sf_use_s2(FALSE)

# Resolution de chemins independante du working directory.
.PROJECT_ROOT <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)

dir_in  <- file.path(.PROJECT_ROOT, "pedagogie", "J05_enquetes_carte",
                     "datasets")
dir_out <- file.path(.PROJECT_ROOT, "pedagogie", "_commons", "data",
                     "J05_extraits")
dir.create(dir_out, showWarnings = FALSE, recursive = TRUE)

# Tolerance de simplification, declaree une fois et commentee au moment de
# l'appel (section 5). En degres : le CRS des couches est EPSG:4326.
TOL_ADM1 <- 0.010   # ~1,1 km a l'equateur
TOL_DS   <- 0.005   # ~0,55 km

# ----------------------------------------------------------------------
# 0. Cle de jointure resistante aux accents (cf. REGLES §3.2)
#    Les mots de liaison comptent : sans eux, 11 departements sur 58 sont
#    perdus. On garde TOUJOURS le libelle d'origine pour l'affichage.
# ----------------------------------------------------------------------
normaliser <- function(x) {
  x |>
    stringi::stri_trans_general("Latin-ASCII") |>
    tolower() |>
    stringr::str_replace_all("[^a-z ]", " ") |>
    stringr::str_replace_all("\\b(et|de|du|la|le)\\b", " ") |>
    stringr::str_replace_all("\\s+", "")
}

# ----------------------------------------------------------------------
# 1. ECAM5 : ponderer, puis agreger par region
#    C'est LA partie que WebR ne peut pas faire (haven + survey).
# ----------------------------------------------------------------------
message("[J05-extrait] Lecture ECAM5 (ecam5.dta)...")
ecam5 <- read_dta(file.path(dir_in, "ecam5.dta"))
cat(sprintf("[J05-extrait] ECAM5 brut : %d lignes x %d colonnes\n",
            nrow(ecam5), ncol(ecam5)))

# Variables reellement presentes (fiche REPRISE_J06_J11.md §4) :
#   s0q1     region d'enquete, 12 modalites etiquetees
#   milieu   1 = urbain, 2 = rural
#   tailm    taille du menage
#   nivie    0 = non pauvre, 1 = pauvre
#   coefextr coefficient d'extrapolation = POIDS DE SONDAGE
#   s01q3    lien au chef de menage ; == 1 identifie le chef
#   s09q13a  satisfaction alimentaire (substitut du FIES jamais fourni)
vars_attendues <- c("s0q1", "milieu", "tailm", "nivie", "coefextr", "s01q3")
manquantes <- setdiff(vars_attendues, names(ecam5))
if (length(manquantes)) {
  stop("[J05-extrait] Variables ECAM5 absentes : ",
       paste(manquantes, collapse = ", "),
       "\n  -> ouvrir le .dta et corriger la liste ci-dessus.")
}

ecam <- ecam5 |>
  mutate(
    region_eq = as.character(as_factor(s0q1)),
    milieu_lb = ifelse(milieu == 1, "Urbain", "Rural"),
    poids     = as.numeric(coefextr),
    pauvre    = as.numeric(nivie),
    taille    = as.numeric(tailm),
    chef      = as.numeric(s01q3) == 1
  )

# --- 1.1 Le biais de taille, chiffre une fois pour toutes -------------------
# Parcourir des lignes d'INDIVIDUS surrepresente les grands menages : chaque
# menage y apparait autant de fois qu'il compte de membres. Trois chiffres
# differents pour « la » taille moyenne d'un menage -- les trois sont exacts,
# ils repondent a trois questions differentes.
taille_menages <- tibble(
  base = c("individus, pondere", "menages (chefs), pondere",
           "menages (chefs), NON pondere"),
  taille_moyenne = c(
    with(ecam,               sum(taille * poids) / sum(poids)),
    with(filter(ecam, chef), sum(taille * poids) / sum(poids)),
    with(filter(ecam, chef), mean(taille))
  ),
  n = c(nrow(ecam), sum(ecam$chef), sum(ecam$chef))
)
write_csv(taille_menages, file.path(dir_out, "ecam5_taille_menages.csv"))
cat("[J05-extrait] Biais de taille (3 lectures de la meme donnee) :\n")
print(as.data.frame(taille_menages))

# --- 1.2 Le pont 12 regions d'enquete -> 10 regions administratives ---------
# Douala et Yaounde ne sont PAS des regions administratives : ce sont les
# capitales du Littoral et du Centre, que les enquetes isolent pour des
# raisons d'echantillonnage. Aucune manipulation de chaine ne devine cela :
# c'est une DECISION DE METHODE, elle doit rester visible.
correspondance <- tribble(
  ~region_eq_cle,      ~region_adm,
  normaliser("Douala"),  "Littoral",
  normaliser("Yaounde"), "Centre"
)

ecam <- ecam |>
  mutate(cle_eq = normaliser(region_eq)) |>
  left_join(correspondance, by = c("cle_eq" = "region_eq_cle")) |>
  mutate(region_adm = coalesce(region_adm, region_eq),
         cle_adm    = normaliser(region_adm))

cat(sprintf("[J05-extrait] regions d'enquete : %d ; regions admin apres pont : %d\n",
            n_distinct(ecam$region_eq), n_distinct(ecam$region_adm)))

# --- 1.3 Les taux ponderes par region --------------------------------------
# On agrege AU NIVEAU ADMINISTRATIF en repassant par les poids : la fusion de
# deux regions d'enquete n'est pas la moyenne de leurs deux taux, c'est la
# moyenne ponderee de leurs individus. (REGLES §3.5 : la moyenne d'une
# moyenne n'est pas la moyenne.)
pauvrete_region <- ecam |>
  group_by(region_adm, cle_adm) |>
  summarise(
    n_individus         = n(),
    n_menages           = sum(chef),
    tx_pauvrete_pond    = 100 * sum(pauvre * poids, na.rm = TRUE) /
                                sum(poids[!is.na(pauvre)]),
    tx_pauvrete_brut    = 100 * mean(pauvre, na.rm = TRUE),
    taille_moy_menage   = sum(taille * poids) / sum(poids),
    .groups = "drop"
  ) |>
  arrange(desc(tx_pauvrete_pond))

# Meme calcul, mais sur les seuls chefs de menage : le taux de pauvrete
# « par menage » n'est pas le taux « par individu ».
pauvrete_menage <- ecam |>
  filter(chef) |>
  group_by(cle_adm) |>
  summarise(tx_pauvrete_menage = 100 * sum(pauvre * poids, na.rm = TRUE) /
                                       sum(poids[!is.na(pauvre)]),
            .groups = "drop")

pauvrete_region <- pauvrete_region |>
  left_join(pauvrete_menage, by = "cle_adm")

# CONFRONTATION A UNE REFERENCE PUBLIEE -- geste obligatoire avant toute
# carte (REGLES §3.8). Repere INS : national 37,7 % ; Extreme-Nord 69,2 ;
# Nord-Ouest 66,8 ; Nord 61,1 ; Adamaoua 45,1 ; Est 41,5.
tx_national <- 100 * with(ecam, sum(pauvre * poids, na.rm = TRUE) /
                                sum(poids[!is.na(pauvre)]))
cat(sprintf("[J05-extrait] Taux de pauvrete national pondere : %.1f %% (INS publie : 37,7 %%)\n",
            tx_national))
cat("[J05-extrait] Ecart a la reference INS par region (colonne ecart_ins) :\n")
ref_ins <- tribble(
  ~cle_adm,                 ~tx_ins_publie,
  normaliser("Extreme-Nord"), 69.2,
  normaliser("Nord-Ouest"),   66.8,
  normaliser("Nord"),         61.1,
  normaliser("Adamaoua"),     45.1,
  normaliser("Est"),          41.5
)
pauvrete_region <- pauvrete_region |>
  left_join(ref_ins, by = "cle_adm") |>
  mutate(ecart_ins = round(tx_pauvrete_pond - tx_ins_publie, 1))
print(as.data.frame(pauvrete_region))

# NE PAS « CORRIGER » L'ANOMALIE. ecam5.dta est un extrait de FORMATION : il
# est representatif au niveau national mais PAS a l'interieur des regions.
# Decision deja prise, consignee dans REPRISE_J06_J11.md §2 et §5 : on ne
# masque pas l'ecart, on en fait un exercice, et le runtime INTERDIT de citer
# les chiffres regionaux.
pauvrete_region$avertissement <-
  "extrait de formation - NON representatif a l'interieur des regions - ne pas citer"

write_csv(pauvrete_region, file.path(dir_out, "ecam5_pauvrete_region.csv"))

# --- 1.4 Le meme tableau croise par milieu ---------------------------------
pauvrete_region_milieu <- ecam |>
  group_by(region_adm, cle_adm, milieu_lb) |>
  summarise(
    n_individus      = n(),
    tx_pauvrete_pond = 100 * sum(pauvre * poids, na.rm = TRUE) /
                             sum(poids[!is.na(pauvre)]),
    .groups = "drop"
  )
write_csv(pauvrete_region_milieu,
          file.path(dir_out, "ecam5_pauvrete_region_milieu.csv"))

# ----------------------------------------------------------------------
# 2. EDS-MICS 2018 : indicateurs ponderes par GRAPPE
#    CMHR71FL.SAV pese 72 Mo et compte plus de 4 000 colonnes : on ne lit
#    QUE les variables utiles, et on gere la casse MAJUSCULES du SPSS DHS.
# ----------------------------------------------------------------------
message("[J05-extrait] Lecture EDS menages (CMHR71FL.SAV) - 10 a 60 s...")
f_sav <- file.path(dir_in, "CMHR71FL.SAV")

vars_voulues <- c("hv001", "hv005", "hv009", "hv024", "hv025",
                  "hv201", "hv205", "hv206", "hv270")
noms_sav <- names(read_sav(f_sav, n_max = 0))
vars     <- noms_sav[match(toupper(vars_voulues), toupper(noms_sav))]
if (anyNA(vars)) {
  warning("[J05-extrait] Variables EDS introuvables : ",
          paste(vars_voulues[is.na(vars)], collapse = ", "))
  vars <- na.omit(vars)
}
hr <- read_sav(f_sav, col_select = all_of(as.character(vars)))
names(hr) <- tolower(names(hr))
cat(sprintf("[J05-extrait] EDS menages : %d lignes x %d colonnes retenues\n",
            nrow(hr), ncol(hr)))

# Definition JMP (OMS/UNICEF) d'une source AMELIOREE : reseau, borne-fontaine,
# forage, puits protege, source protegee, eau de pluie, eau en bouteille.
# Les codes ci-dessous sont ceux du Recode Manual DHS VII.
# A VALIDER AU PREMIER RENDU : imprimer table(hr$hv201) et verifier que les
# codes presents sont bien couverts par la liste.
codes_eau_amelioree <- c(11, 12, 13, 14, 21, 31, 41, 51, 61, 62, 71, 72)
cat("[J05-extrait] Codes hv201 presents dans le fichier :\n")
print(sort(unique(as.numeric(hr$hv201))))

hr <- hr |>
  mutate(
    grappe        = as.numeric(hv001),
    poids         = as.numeric(hv005) / 1e6,   # regle DHS : diviser par 1e6
    taille        = as.numeric(hv009),
    eau_amelioree = as.numeric(as.numeric(hv201) %in% codes_eau_amelioree),
    electricite   = as.numeric(as.numeric(hv206) == 1)
  )

grappes_ind <- hr |>
  group_by(grappe) |>
  summarise(
    n_menages         = n(),
    poids_total       = sum(poids),
    tx_eau_amelioree  = 100 * sum(eau_amelioree * poids) / sum(poids),
    tx_electricite    = 100 * sum(electricite   * poids) / sum(poids),
    taille_moy_menage = sum(taille * poids) / sum(poids),
    .groups = "drop"
  )
cat(sprintf("[J05-extrait] Indicateurs calcules sur %d grappes EDS\n",
            nrow(grappes_ind)))

# ----------------------------------------------------------------------
# 3. La geometrie des grappes + les covariables de contexte
# ----------------------------------------------------------------------
message("[J05-extrait] Lecture des grappes geolocalisees (CMGE71FL.shp)...")
ge <- st_read(file.path(dir_in, "CMGE71FL.shp"), quiet = TRUE) |>
  st_make_valid()

# Controle qualite obligatoire : le DHS code une position manquante par le
# couple (0, 0) -- un point au large du golfe de Guinee, pas un NA.
n_zero <- sum(ge$LATNUM == 0 & ge$LONGNUM == 0)
cat(sprintf("[J05-extrait] Grappes en (0,0) a exclure : %d sur %d\n",
            n_zero, nrow(ge)))
ge <- ge |> filter(!(LATNUM == 0 & LONGNUM == 0))

# CMGC72FL.csv ne contient AUCUNE coordonnee malgre son nom : ce sont les
# covariables contextuelles, deja extraites de rasters par le DHS.
# Sentinelles negatives (-9999) : recoder en NA AVANT tout calcul.
gc <- read_csv(file.path(dir_in, "CMGC72FL.csv"), show_col_types = FALSE)
cov_utiles <- c("DHSCLUST", "Travel_Times_2015", "Nightlights_Composite",
                "Aridity_2015", "Malaria_Prevalence_2015",
                "All_Population_Count_2015")
cov_utiles <- intersect(cov_utiles, names(gc))
gc <- gc |>
  select(all_of(cov_utiles)) |>
  mutate(across(-DHSCLUST, ~ ifelse(.x < 0, NA_real_, .x)))
cat("[J05-extrait] Sentinelles negatives recodees en NA, par covariable :\n")
print(colSums(is.na(gc)))

grappes <- ge |>
  st_drop_geometry() |>
  select(DHSCLUST, ADM1NAME, URBAN_RURA, LATNUM, LONGNUM) |>
  left_join(grappes_ind, by = c("DHSCLUST" = "grappe")) |>
  left_join(gc, by = "DHSCLUST") |>
  rename(lat = LATNUM, lon = LONGNUM,
         region_eds = ADM1NAME, milieu = URBAN_RURA)

# Compteur de controle apres jointure (REGLES §3.3).
cat(sprintf("[J05-extrait] Grappes sans indicateur EDS apres jointure : %d\n",
            sum(is.na(grappes$tx_eau_amelioree))))

write_csv(grappes, file.path(dir_out, "eds_grappes_eau.csv"))

# ----------------------------------------------------------------------
# 4. Districts sanitaires : la seconde maille
#    C'est ici que se joue le MAUP du runtime : le MEME indicateur, agrege
#    a deux mailles differentes, ne donne pas la meme carte.
# ----------------------------------------------------------------------
message("[J05-extrait] Lecture des districts sanitaires (DS.geojson, ~20 Mo)...")
ds <- st_read(file.path(dir_in, "DS.geojson"), quiet = TRUE)
cat(sprintf("[J05-extrait] DS : %d entites, geometries valides AVANT reparation : %d\n",
            nrow(ds), sum(st_is_valid(ds))))
ds <- st_make_valid(ds)
cat(sprintf("[J05-extrait] geometries valides APRES st_make_valid() : %d\n",
            sum(st_is_valid(ds))))

# Il n'existe NI « NomDS », NI « CodeDS » : le nom est dans `name` (prefixe
# « District »), la region dans `parentName` (prefixe « Region »).
ds <- ds |>
  mutate(
    ds_nom     = str_squish(str_remove(name,       "^District\\s*")),
    region_ds  = str_squish(str_remove(parentName, "^Region\\s*"))
  ) |>
  select(ds_nom, region_ds)

# Points des grappes, reconstruits depuis lon/lat. ORDRE c(longitude, latitude)
# -- l'inversion ne leve aucune erreur, elle place simplement les points
# ailleurs (REGLES §3.6).
pts <- grappes |>
  filter(!is.na(lon), !is.na(lat)) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = FALSE)

if (st_crs(pts) != st_crs(ds)) ds <- st_transform(ds, st_crs(pts))

n_avant <- nrow(pts)
pts_ds  <- st_join(pts, ds, join = st_within)
# st_join peut DUPLIQUER des lignes si deux polygones se recouvrent.
cat(sprintf("[J05-extrait] st_join : %d points avant, %d apres (duplicats = %d)\n",
            n_avant, nrow(pts_ds), nrow(pts_ds) - n_avant))
pts_ds <- pts_ds |> distinct(DHSCLUST, .keep_all = TRUE)

# Les points non apparies ne sont pas des dechets : on les RECALE sur le
# district le plus proche et on TRACE le recalage dans une colonne dediee.
i_orphelins <- which(is.na(pts_ds$ds_nom))
cat(sprintf("[J05-extrait] Grappes non rattachees (recalees au plus proche) : %d\n",
            length(i_orphelins)))
pts_ds$recale <- FALSE
if (length(i_orphelins) > 0) {
  j <- st_nearest_feature(pts_ds[i_orphelins, ], ds)
  pts_ds$ds_nom[i_orphelins]    <- ds$ds_nom[j]
  pts_ds$region_ds[i_orphelins] <- ds$region_ds[j]
  pts_ds$recale[i_orphelins]    <- TRUE
}

# Second etage d'agregation : de la grappe au district. On repondere par le
# poids TOTAL de chaque grappe -- une grappe de 30 menages representatifs de
# 40 000 personnes ne pese pas comme une grappe de 20.
ds_ind <- pts_ds |>
  st_drop_geometry() |>
  filter(!is.na(tx_eau_amelioree)) |>
  group_by(ds_nom) |>
  summarise(
    n_grappes        = n(),
    n_menages        = sum(n_menages),
    tx_eau_amelioree = sum(tx_eau_amelioree * poids_total) / sum(poids_total),
    tx_electricite   = sum(tx_electricite   * poids_total) / sum(poids_total),
    .groups = "drop"
  )

ds_carte <- ds |>
  left_join(ds_ind, by = "ds_nom") |>
  mutate(
    # Seuil DECLARE dans le code, pas subi (REGLES §4.4) : sous 3 grappes,
    # l'estimation du district repose sur trop peu d'observations.
    fiable = !is.na(n_grappes) & n_grappes >= 3
  )
cat(sprintf("[J05-extrait] Districts renseignes : %d / %d ; fiables (>= 3 grappes) : %d\n",
            sum(!is.na(ds_carte$tx_eau_amelioree)), nrow(ds_carte),
            sum(ds_carte$fiable)))

# ----------------------------------------------------------------------
# 5. Simplifier les geometries -- et dire ce que cela coute
# ----------------------------------------------------------------------
# st_simplify (Douglas-Peucker) supprime les sommets qui s'ecartent de moins
# de dTolerance de la ligne simplifiee. En EPSG:4326 la tolerance est en
# DEGRES : 0,005 degre vaut environ 550 m a ces latitudes.
#
# CE QUE CELA COUTE :
#   - les frontieres perdent leur detail fin ; deux polygones voisins peuvent
#     cesser de coincider exactement (fentes ou chevauchements de quelques
#     centaines de metres) ;
#   - les SUPERFICIES changent legerement : ces couches simplifiees servent a
#     AFFICHER, jamais a mesurer. Toute superficie du runtime est recalculee
#     depuis la couche GADM d'origine (_commons/data/gadm41_CMR_*.json).
#   - preserveTopology = TRUE evite qu'un polygone degenere ou disparaisse.
# Ce qu'on y gagne : un GeoJSON servi au navigateur, pas 20 Mo telecharges
# avant le premier trace.
message("[J05-extrait] Simplification des geometries...")
ds_simp <- st_simplify(ds_carte, dTolerance = TOL_DS, preserveTopology = TRUE)
cat(sprintf("[J05-extrait] DS : %d entites conservees apres simplification (tolerance %.3f deg)\n",
            nrow(ds_simp), TOL_DS))

f_ds <- file.path(dir_out, "districts_sanitaires_J05.geojson")
st_write(ds_simp, f_ds, delete_dsn = TRUE, quiet = TRUE)

# --- Regions administratives (ADM1) + indicateurs ECAM5 --------------------
adm1 <- st_read(file.path(dir_in, "gadm41_CMR_1.shp"), quiet = TRUE) |>
  st_make_valid() |>
  mutate(cle_adm = normaliser(NAME_1))

# Le MEME indicateur d'eau amelioree, mais agrege a la maille REGIONALE.
# C'est ce qui permet au runtime de mettre le MAUP en scene : deux cartes du
# meme phenomene, deux mailles, deux lectures. On repondere depuis les
# grappes (jamais la moyenne des moyennes de districts).
pts_adm1 <- st_join(pts, select(st_transform(adm1, st_crs(pts)), NAME_1),
                    join = st_within) |>
  distinct(DHSCLUST, .keep_all = TRUE)
eau_region <- pts_adm1 |>
  st_drop_geometry() |>
  filter(!is.na(tx_eau_amelioree), !is.na(NAME_1)) |>
  group_by(NAME_1) |>
  summarise(n_grappes = n(),
            tx_eau_amelioree = sum(tx_eau_amelioree * poids_total) /
                               sum(poids_total),
            .groups = "drop")
cat(sprintf("[J05-extrait] Eau amelioree calculee pour %d regions sur 10\n",
            nrow(eau_region)))

adm1_carte <- adm1 |>
  select(NAME_1, GID_1, cle_adm) |>
  left_join(select(pauvrete_region, -region_adm), by = "cle_adm") |>
  left_join(eau_region, by = "NAME_1")
cat(sprintf("[J05-extrait] Regions sans taux apres jointure : %d sur %d\n",
            sum(is.na(adm1_carte$tx_pauvrete_pond)), nrow(adm1_carte)))
if (any(is.na(adm1_carte$tx_pauvrete_pond))) {
  cat("  -> regions orphelines : ",
      paste(adm1_carte$NAME_1[is.na(adm1_carte$tx_pauvrete_pond)],
            collapse = ", "), "\n")
}

adm1_simp <- st_simplify(adm1_carte, dTolerance = TOL_ADM1,
                         preserveTopology = TRUE)
f_adm1 <- file.path(dir_out, "cmr_regions_J05.geojson")
st_write(adm1_simp, f_adm1, delete_dsn = TRUE, quiet = TRUE)

# ----------------------------------------------------------------------
# 6. README des extraits + bilan de poids
# ----------------------------------------------------------------------
sorties <- c("ecam5_pauvrete_region.csv",
             "ecam5_pauvrete_region_milieu.csv",
             "ecam5_taille_menages.csv",
             "eds_grappes_eau.csv",
             "cmr_regions_J05.geojson",
             "districts_sanitaires_J05.geojson")

readme <- tibble(
  fichier   = sorties,
  entites   = c(nrow(pauvrete_region), nrow(pauvrete_region_milieu),
                nrow(taille_menages), nrow(grappes),
                nrow(adm1_simp), nrow(ds_simp)),
  unite     = c("region administrative", "region x milieu",
                "base de calcul", "grappe EDS",
                "region administrative", "district sanitaire"),
  source    = c(rep("ECAM5 2021-2022 (INS Cameroun)", 3),
                "EDS-MICS 2018 (DHS) + CMGC72FL",
                "GADM 4.1 + ECAM5", "DHIS2 MINSANTE + EDS-MICS 2018"),
  ponderee  = c("oui (coefextr)", "oui (coefextr)", "oui et non (3 lectures)",
                "oui (hv005/1e6)", "oui (coefextr)", "oui (2 etages)"),
  taille_ko = round(vapply(file.path(dir_out, sorties), file.size,
                           numeric(1)) / 1024)
)
write_csv(readme, file.path(dir_out, "J05_extraits_README.csv"))

cat("\n========================================================\n")
cat(" Extraction J05 pour WebR terminee.\n")
cat("========================================================\n")
cat(" Fichiers dans :\n  ", normalizePath(dir_out), "\n\n")
print(as.data.frame(readme))
cat(sprintf("\n Poids total des extraits : %.2f Mo\n",
            sum(readme$taille_ko) / 1024))
cat(" Rappel : les taux regionaux d'ECAM5 ne sont PAS citables (extrait de\n")
cat(" formation, non representatif a l'interieur des regions).\n")
