# =====================================================================
# install_packages_day.R
# J9 - Applications spatiales et sciences sociales
# Conception pedagogique : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita (GDSG/IFORD)
# =====================================================================

pkgs_J09 <- c(
  # Recyclage J1-J7
  "sf", "dplyr", "tidyr", "ggplot2", "readr", "tibble",
  "terra", "tmap", "exactextractr", "scales",
  # Nouveaux du jour (optionnels mais recommandes pour la demo en direct)
  "acledR",  # API ACLED (conflits armes)
  "ecmwfr",  # API Copernicus CDS (ERA5)
  "ncdf4"    # inspection NetCDF avancee (optionnel)
)

repo <- "https://packagemanager.posit.co/cran/latest"
options(timeout = 600)

manquants <- pkgs_J09[!pkgs_J09 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J9] Tous les packages necessaires sont deja installes.")
} else {
  message("[J9] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, repos = repo)
}

# Verifications operationnelles
checks <- c(
  acledR        = "API ACLED (conflits armes Cameroun)",
  ecmwfr        = "API Copernicus CDS (telechargement ERA5 NetCDF)",
  ncdf4         = "inspection NetCDF avancee (optionnel)",
  terra         = "raster (lecture NetCDF, crop, mask, conversion K->C)",
  tmap          = "cartographie statique (cartes choroplethes + raster)",
  exactextractr = "extraction zonale multi-couches (ERA5 mensuel)"
)
for (pkg in names(checks)) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("[J9] %s OK : %s", pkg, checks[pkg]))
  } else {
    warning(sprintf("[J9] %s manquant : %s", pkg, checks[pkg]))
  }
}

# Note IMPORTANTE pour la mise en place avant la session
message("\n[J9] Avant la session :")
message("  1. Creer un compte ACLED : https://developer.acleddata.com/")
message("  2. Creer un compte CDS   : https://cds.climate.copernicus.eu/")
message("  3. Copier pedagogie/datasets/cameroun/jour_09_acled_era5/.env.example")
message("     en .env (meme dossier) et remplir les 4 identifiants.")
message("  4. Lancer une fois la requete ERA5 via ecmwfr pour mettre en cache")
message("     era5_t2m_mensuel_cameroun.nc (~quelques Mo, prend 5-10 min).")
