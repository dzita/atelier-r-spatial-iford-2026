# =====================================================================
# J10 — Démo : workflow reproductible + fonction d'automatisation
# Atelier IFORD x GDSG · Yaoundé 6 août 2026 · Animateur : R. Dzita
# =====================================================================

# Ce script est une démonstration condensée du contenu de J10.
# Pour la version pédagogique narrée, voir demo.qmd.

# ---- 1. Création projet RStudio (via usethis) -----------------------
# usethis::create_project("~/projets/cmr_densite_dep")
# Puis depuis le nouveau projet :
# usethis::use_git()
# usethis::use_github()  # nécessite gh CLI ou PAT configuré

# ---- 2. Structure de dossiers ---------------------------------------
library(here)
# dir.create(here("R"), showWarnings = FALSE)
# dir.create(here("data", "raw"), showWarnings = FALSE, recursive = TRUE)
# dir.create(here("data", "intermediate"), showWarnings = FALSE, recursive = TRUE)
# dir.create(here("outputs", "figures"), showWarnings = FALSE, recursive = TRUE)
# dir.create(here("outputs", "tables"), showWarnings = FALSE, recursive = TRUE)

# ---- 3. Pipeline pour une source : fonction réutilisable ------------
library(sf)
library(terra)
library(dplyr)
library(tibble)
library(purrr)
library(exactextractr)

pipeline_source <- function(raster_path, source_nom, adm2_template) {
  r <- rast(raster_path) |> project("EPSG:3119")
  pop <- exact_extract(r, adm2_template, "sum")

  tibble(
    source = source_nom,
    NAME_1 = adm2_template$NAME_1,
    NAME_2 = adm2_template$NAME_2,
    pop = pop
  )
}

# ---- 4. Application en batch avec purrr::map_dfr --------------------
# Suppose : adm2_template chargé en Lambert 3119 ailleurs
# adm2 <- read_sf(...) |> st_transform(3119) |> st_make_valid()
#
# trois_sources <- map_dfr(
#   list(worldpop = "data/intermediate/worldpop.tif",
#        ghspop   = "data/intermediate/ghspop.tif",
#        hrsl     = "data/intermediate/hrsl.tif"),
#   ~ pipeline_source(.x, .y, adm2),
#   .id = "source"
# )

# ---- 5. Boucle for équivalente (pour les puristes) ------------------
# resultats <- list()
# for (src in names(sources)) {
#   resultats[[src]] <- pipeline_source(sources[[src]], src, adm2)
# }
# trois_sources <- bind_rows(resultats)

# ---- 6. Snapshot renv (gestion versions packages) -------------------
# renv::init()       # première fois
# renv::snapshot()   # à chaque ajout/MAJ de package

# ---- 7. Rendre le rapport ------------------------------------------
# quarto::quarto_render(here("rapport.qmd"), output_format = "pdf")

# ---- 8. Commit + push ----------------------------------------------
# Dans le terminal RStudio :
# git add R/ rapport.qmd outputs/figures/*.png outputs/tables/*.csv
# git commit -m "Pipeline complet : 3 sources, densité par département"
# git push

# Fin J10
