# =====================================================================
# demo.R
# J10 — Démo de salle : workflow R-spatial reproductible
# Atelier IFORD x GDSG - Yaounde, 7 aout 2026
#
# Miroir condense de demo.qmd. Le formateur le lance dans RStudio,
# ligne par ligne, pour montrer les 6 sections de la journee :
#   1. Projet structure + here::here()
#   2. Quarto multi-format (idee, render commands)
#   3. tmap plot vs view (un seul objet, deux modes)
#   4. Git basics (commandes en bash + usethis)
#   5. Automatisation par boucle reg., purrr::map_dfr
#   6. FAIR + metadonnees minimales + sidecar JSON
#
# Conception : Edith Darin (GDSG/IFORD) - trame multi-format + tmap +
#              atelier R + grille mini-projet + metadonnees minimales
# Integration convention IFORD : Ramesesse Dzita
# =====================================================================

suppressPackageStartupMessages({
  library(here)
  library(fs)
  library(sf)
  library(dplyr)
  library(tibble)
  library(readr)
  library(purrr)
  library(tmap)
  library(jsonlite)
})

# ---------------------------------------------------------------------
# Section 1 - Projet structure + ancrage sur le .Rproj
# ---------------------------------------------------------------------
# rprojroot::find_root() est plus robuste que here::here() quand le
# script est lance depuis Rscript ou depuis un CWD different (la racine
# pedagogie/_quarto.yml peut faire concurrence au .Rproj racine).
projet_root <- rprojroot::find_root(
  rprojroot::has_file("atelier-r-spatial-iford-2026.Rproj")
)
message("Racine projet : ", projet_root)

source(file.path(projet_root, "pedagogie", "_commons", "helpers",
                 "fetch_data.R"))

regions <- sf::read_sf(fetch_indicateurs_regions_demo())
cat("Regions :", nrow(regions),
    "| Colonnes :", paste(names(regions), collapse = ", "), "\n")
cat("CRS     :", sf::st_crs(regions)$input, "\n")

# ---------------------------------------------------------------------
# Section 2 - Quarto multi-format
# ---------------------------------------------------------------------
# Demo : commandes a montrer en terminal (pas a executer ici)
# quarto render demo.qmd --to html
# quarto render demo.qmd --to pptx
# quarto render demo.qmd --to pdf
# quarto render demo.qmd --to docx
#
# Discussion : choix du format selon usage (rapport / restitution /
# archive / relecture). Carte interactive = HTML uniquement.

indicateurs <- regions |>
  sf::st_drop_geometry() |>
  dplyr::select(region, population, menages, eau_amelioree_pct,
                alphabetisation_pct, ecoles, formations_sanitaires) |>
  dplyr::arrange(dplyr::desc(population))

print(indicateurs)

# ---------------------------------------------------------------------
# Section 3 - tmap plot vs view
# ---------------------------------------------------------------------
# Construction d'un objet unique, rendu dans les deux modes.

tmap_mode("plot")

carte_eau <- tm_shape(regions) +
  tm_polygons(
    fill        = "eau_amelioree_pct",
    fill.scale  = tm_scale_intervals(style = "quantile", values = "viridis"),
    fill.legend = tm_legend(title = "Eau amelioree (%)")
  ) +
  tm_text("region", size = 0.5) +
  tm_title("Acces a l'eau amelioree par region",
           position = tm_pos_in("left", "top"))

print(carte_eau)  # statique

# Basculer en interactif (Leaflet) pour la demo en salle
tmap_mode("view")
print(carte_eau)  # interactif (zoom, popup, fond satellite)

# Repasser en plot pour la suite
tmap_mode("plot")

# ---------------------------------------------------------------------
# Section 4 - Git basics (a commenter en salle, pas a executer ici)
# ---------------------------------------------------------------------
# git status
# git add scripts/analyse.R
# git commit -m "Ajouter le calcul de densite par region"
# git push
# git pull
#
# Depuis R, equivalents via usethis :
# usethis::use_git()
# usethis::use_github()
# usethis::use_readme_md()
# usethis::use_mit_license()

# ---------------------------------------------------------------------
# Section 5 - Automatisation par boucle regionale (purrr::map_dfr)
# ---------------------------------------------------------------------
resumer_region <- function(nom) {
  r <- regions |> dplyr::filter(region == nom)
  if (nrow(r) == 0) {
    return(tibble::tibble(region = nom, densite = NA_real_,
                          taille_menage = NA_real_,
                          fosa_pour_10k = NA_real_))
  }
  surface_km2 <- as.numeric(sf::st_area(r)) / 1e6
  tibble::tibble(
    region        = nom,
    pop_2024      = r$population,
    surface_km2   = round(surface_km2, 0),
    densite       = round(r$population / surface_km2, 1),
    taille_menage = round(r$population / r$menages, 2),
    fosa_pour_10k = round(r$formations_sanitaires / r$population * 1e4, 2)
  )
}

# Test unitaire avant boucle
print(resumer_region("Adamaoua"))

# Application a toutes les regions
tableau_regions <- purrr::map_dfr(regions$region, resumer_region) |>
  dplyr::arrange(dplyr::desc(densite))

print(tableau_regions)

# Export dans outputs/ (ancre sur le projet root)
outputs_dir <- file.path(projet_root, "pedagogie",
                         "J10_workflows_reproductibles", "outputs")
fs::dir_create(outputs_dir)

readr::write_csv(
  tableau_regions,
  file.path(outputs_dir, "indicateurs_regions_calcul.csv")
)

regions_enrichi <- regions |>
  dplyr::left_join(tableau_regions, by = "region")

sf::st_write(
  regions_enrichi,
  file.path(outputs_dir, "regions_indicateurs_enrichi.gpkg"),
  delete_dsn = TRUE,
  quiet = TRUE
)

message("Exports OK dans : ", outputs_dir)

# ---------------------------------------------------------------------
# Section 6 - FAIR + metadonnees minimales + sidecar JSON
# ---------------------------------------------------------------------
# Grille des 7 metadonnees minimales (a coller dans chaque export)
metadata <- tibble::tribble(
  ~`#`, ~`Element`,           ~`Valeur`,
  1L,   "Titre",              "Indicateurs regionaux derives (atelier IFORD J10)",
  2L,   "Source",             "regions_indicateurs_demo.gpkg (Edith Darin / GDSG)",
  3L,   "Date",               format(Sys.Date(), "%Y-%m-%d"),
  4L,   "CRS",                sf::st_crs(regions)$input,
  5L,   "Resolution",         "ADM1 - 10 regions du Cameroun",
  6L,   "Methode",            "densite = pop/superficie ; FOSA/10k = FOSA/pop*1e4",
  7L,   "Limites",            "donnees d'entrainement, ne pas citer comme officiel"
)
print(metadata)

# Sidecar JSON lisible par machine
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
commit_court <- tryCatch(
  system("git rev-parse --short HEAD", intern = TRUE,
         ignore.stderr = TRUE)[1],
  error = function(e) NA_character_
)

meta_livrable <- list(
  titre    = metadata$Valeur[1],
  source   = metadata$Valeur[2],
  date     = metadata$Valeur[3],
  auteur   = "Ramesesse Dzita - GDSG IFORD",
  crs      = metadata$Valeur[4],
  resolution = metadata$Valeur[5],
  methode  = metadata$Valeur[6],
  licence  = "CC-BY 4.0 (donnees d'entrainement)",
  limites  = metadata$Valeur[7],
  reproductibilite = list(
    code   = "pedagogie/J10_workflows_reproductibles/demo.R",
    commit = commit_court %||% "unknown"
  )
)

sidecar_path <- file.path(outputs_dir,
                          "regions_indicateurs_enrichi.gpkg.json")
jsonlite::write_json(meta_livrable, sidecar_path,
                     pretty = TRUE, auto_unbox = TRUE)

message("Sidecar metadonnees ecrit : ", basename(sidecar_path))

# ---------------------------------------------------------------------
# Synthese pedagogique a verbaliser en cloture de demo
# ---------------------------------------------------------------------
message("\n=== J10 demo terminee ===")
message("- 1 dataset (regions_indicateurs_demo.gpkg) a servi 6 sections")
message("- 2 livrables produits dans outputs/ + 1 sidecar JSON FAIR")
message("- Code 100% reproductible : here::here() + helper fetch_*")
message("- Carte unique rendue en mode plot (rapport) et view (HTML)")
