# =====================================================================
# install_packages_day.R
# J8 - Teledetection et observation de la Terre
# Conception pedagogique : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita (GDSG/IFORD)
# =====================================================================

pkgs_J08 <- c(
  # Recyclage J1-J7
  "sf", "dplyr", "tidyr", "ggplot2", "readr", "tibble",
  "terra", "tmap", "exactextractr", "scales",
  # Nouveau du jour - decompression de CSV.GZ (Open Buildings)
  "R.utils"
)

repo <- "https://packagemanager.posit.co/cran/latest"
options(timeout = 600)

manquants <- pkgs_J08[!pkgs_J08 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J8] Tous les packages necessaires sont deja installes.")
} else {
  message("[J8] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, repos = repo)
}

# Verifications operationnelles
checks <- c(
  terra         = "raster moderne (mosaique GHSL, project, mask)",
  tmap          = "cartographie statique tmap v4",
  exactextractr = "extraction zonale sur grilles GHSL/WorldPop",
  R.utils       = "decompression GZ pour Open Buildings (gunzip)",
  sf            = "vecteurs sf (EMSR772 shapefiles, bati points)"
)
for (pkg in names(checks)) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("[J8] %s OK : %s", pkg, checks[pkg]))
  } else {
    warning(sprintf("[J8] %s manquant : %s", pkg, checks[pkg]))
  }
}

message("\n[J8] Avant la session :")
message("  1. Verifier que les datasets sont en local dans :")
message("     pedagogie/datasets/cameroun/jour_08_teledetection/")
message("     (GHS-BUILT/, EMSR772_products/, Open Buildings/, ",
        "cmr_pop_2024_CN_100m_R2025A_v1.tif)")
message("  2. Lancer une fois la mosaique GHSL en repetition (~30-60s)")
message("     pour avoir le cache en memoire.")
