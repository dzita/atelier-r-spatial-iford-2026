# =====================================================================
# install_packages_day.R
# J4 - Gestion des donnees pour l'analyse spatiale
# Packages minimaux pour suivre la journee.
# Conception pedagogique : Jean Saturnin Alogo Samba (GDSG/IFORD)
# Bascule DHS reel : Ramesesse Dzita
# =====================================================================

pkgs_J04 <- c(
  # Recyclage J1 (deja installes normalement)
  "dplyr", "tidyr", "readr", "ggplot2", "tibble",
  # Lecture des microfichiers Stata DHS (.DTA)
  "haven",
  # Enquetes pondonderees - Module 4 (plan de sondage stratifie)
  "survey",   # moteur de Lumley 2010
  "srvyr",    # wrapper tidyverse de survey
  # Visualisation des valeurs manquantes - Module 3
  "naniar",
  # Cartographie rapide en fin de Module 6
  "sf"
)

# Posit Public Package Manager : binaires pre-compiles pour R 4.6+
# (CRAN classique peut etre en retard sur les binaires Windows recents)
repo <- "https://packagemanager.posit.co/cran/latest"
options(timeout = 600)

manquants <- pkgs_J04[!pkgs_J04 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J4] Tous les packages necessaires sont deja installes.")
} else {
  message("[J4] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, repos = repo)
}

# Verifications operationnelles
checks <- c(
  haven    = "lecture des microfichiers .DTA Stata",
  srvyr    = "syntaxe tidyverse pour enquetes ponderees",
  naniar   = "exploration visuelle des valeurs manquantes",
  sf       = "donnees vectorielles spatiales"
)
for (pkg in names(checks)) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("[J4] %s OK : %s", pkg, checks[pkg]))
  } else {
    warning(sprintf("[J4] %s manquant : %s", pkg, checks[pkg]))
  }
}
