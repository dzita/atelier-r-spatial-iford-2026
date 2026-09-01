## ============================================================================
## J01 — Changer d'outil sans changer de métier : les fondations
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026 -- genere depuis script_formateur_J01.R
## ============================================================================

pkgs_j01 <- c(
  "dplyr",
  "haven",
  "labelled",
  "readxl",
  "tidyverse"
)

## NB : devtools n'est PAS installe ici. Il n'est cite dans la journee qu'a
## titre indicatif (devtools::install_github(...)), et sa compilation est
## longue sur des postes d'atelier. A ajouter seulement en cas de besoin reel.

a_installer <- pkgs_j01[!pkgs_j01 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  install.packages(a_installer)
} else {
  message("Tous les packages du J01 sont deja installes.")
}

# Verification : tout doit se charger sans erreur
invisible(lapply(pkgs_j01, function(p) {
  ok <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))
