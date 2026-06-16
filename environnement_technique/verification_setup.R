# =====================================================================
# verification_setup.R
# Atelier IFORD x GDSG 2026 - Auteur : Ramesesse Dzita
# Verifie que l'environnement R + GDAL est pret a animer les 10 jours.
# A executer apres install_packages.R, avant le J1.
# =====================================================================

cat("==========================================================\n")
cat(" VERIFICATION ENVIRONNEMENT - IFORD x GDSG R-Spatial 2026\n")
cat("==========================================================\n\n")

# ------ Version R + locale ------
cat("[1/6] Version R et locale\n")
cat("  R version : ", R.version.string, "\n", sep = "")
cat("  Plateforme: ", R.version$platform, "\n", sep = "")
cat("  Locale    : ", Sys.getlocale("LC_CTYPE"), "\n\n", sep = "")

# ------ Packages essentiels ------
cat("[2/6] Packages essentiels (necessaires pour J1 a J10)\n")
essentiels <- c(
  # Coeur tidyverse + IO
  "here", "dplyr", "tidyr", "readr", "ggplot2", "stringr", "haven",
  "tibble", "janitor", "skimr",
  # Spatial vectoriel
  "sf", "lwgeom", "s2", "rmapshaper",
  # Spatial raster
  "terra", "stars", "tidyterra", "exactextractr", "elevatr",
  # Cartographie
  "tmap", "leaflet", "mapview", "ggspatial", "classInt", "biscale",
  "cols4all", "scales", "rnaturalearth", "rnaturalearthdata",
  # Statistique spatiale
  "spdep", "spatialreg", "spatstat",
  # Enquetes ponderees
  "srvyr", "survey", "rdhs",
  # Reporting
  "quarto", "rmarkdown", "knitr", "kableExtra", "gt", "DT",
  # Helpers
  "httr2", "fs"
)
manquants <- character(0)
for (p in essentiels) {
  ok <- requireNamespace(p, quietly = TRUE)
  cat(sprintf("  [%s] %s\n", if (ok) "OK" else "MANQUE", p))
  if (!ok) manquants <- c(manquants, p)
}
cat("\n")

# ------ Packages optionnels (sympas mais non bloquants) ------
cat("[3/6] Packages optionnels\n")
optionnels <- c("INLA", "brms", "wopr", "performance", "DHARMa")
# Note : wpp2024 retire (indisponible sur CRAN pour R 4.6.0 au 15 juin 2026)
optionnels_manquants <- character(0)
for (p in optionnels) {
  ok <- requireNamespace(p, quietly = TRUE)
  cat(sprintf("  [%s] %s\n", if (ok) "OK" else "absent", p))
  if (!ok) optionnels_manquants <- c(optionnels_manquants, p)
}
cat("\n")

# ------ Versions des libs systeme via sf ------
cat("[4/6] Bibliotheques systeme spatiales (GDAL/GEOS/PROJ)\n")
if (requireNamespace("sf", quietly = TRUE)) {
  print(sf::sf_extSoftVersion())
} else {
  cat("  sf indisponible - impossible de verifier GDAL/GEOS/PROJ.\n")
}
cat("\n")

# ------ Test fonctionnel sf : charger Cameroun + reprojection + aire ------
cat("[5/6] Test fonctionnel sf (Cameroun)\n")
test_sf <- tryCatch(
  {
    if (requireNamespace("rnaturalearth", quietly = TRUE) &&
        requireNamespace("sf", quietly = TRUE)) {
      cmr <- rnaturalearth::ne_countries(country = "Cameroon", returnclass = "sf")
      cmr_utm <- sf::st_transform(cmr, 32632) # UTM 32N
      area_km2 <- as.numeric(sf::st_area(cmr_utm)) / 1e6
      cat(sprintf("  Cameroun, surface (UTM 32N) : %.0f km2 (attendu ~475 442)\n", area_km2))
      ecart <- abs(area_km2 - 475442) / 475442 * 100
      cat(sprintf("  Ecart au chiffre officiel : %.1f %% (acceptable si < 5 %%)\n", ecart))
      TRUE
    } else {
      cat("  rnaturalearth ou sf indisponible\n")
      FALSE
    }
  },
  error = function(e) {
    cat("  ECHEC : ", conditionMessage(e), "\n", sep = "")
    FALSE
  }
)
cat("\n")

# ------ Test fonctionnel terra : raster en memoire ------
cat("[6/6] Test fonctionnel terra (raster synthetique)\n")
test_terra <- tryCatch(
  {
    if (requireNamespace("terra", quietly = TRUE)) {
      r <- terra::rast(nrows = 10, ncols = 10,
                       xmin = 8, xmax = 16, ymin = 2, ymax = 13,
                       crs = "EPSG:4326")
      terra::values(r) <- runif(100)
      cat(sprintf("  terra::rast OK - moyenne aleatoire = %.3f\n",
                  mean(terra::values(r))))
      TRUE
    } else {
      cat("  terra indisponible\n")
      FALSE
    }
  },
  error = function(e) {
    cat("  ECHEC : ", conditionMessage(e), "\n", sep = "")
    FALSE
  }
)

# ------ Verdict final ------
cat("\n==========================================================\n")
if (length(manquants) == 0 && isTRUE(test_sf) && isTRUE(test_terra)) {
  cat(" VERDICT : Environnement pret pour l'atelier.\n")
  if (length(optionnels_manquants) > 0) {
    cat(" Note : packages optionnels absents :\n")
    cat("        ", paste(optionnels_manquants, collapse = ", "), "\n", sep = "")
    cat("        Ces packages ne bloquent aucune demo.\n")
  }
} else {
  cat(" VERDICT : Probleme detecte.\n")
  if (length(manquants) > 0) {
    cat("  Packages essentiels MANQUANTS : ",
        paste(manquants, collapse = ", "), "\n", sep = "")
    cat("  -> Relancer source('environnement_technique/install_packages.R')\n")
  }
  if (!isTRUE(test_sf))    cat("  Test sf KO\n")
  if (!isTRUE(test_terra)) cat("  Test terra KO\n")
  cat("\n  Contacter : Ramesesse Dzita (animateur, ramondzita@gmail.com)\n")
}
cat("==========================================================\n")
