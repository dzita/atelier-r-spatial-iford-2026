# =====================================================================
# install_packages_day.R
# J6 — Statistiques spatiales et analyse
# Packages minimaux pour suivre la journée.
# Conception pédagogique : Jean Saturnin Alogo Samba (GDSG/IFORD)
# =====================================================================

pkgs_J06 <- c(
  # Recyclage J1-J5
  "sf", "dplyr", "ggplot2", "tibble",
  # Nouveauté de J6 — autocorrélation spatiale
  "spdep"
)

manquants <- pkgs_J06[!pkgs_J06 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J6] Tous les packages necessaires sont deja installes.")
} else {
  message("[J6] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, dependencies = TRUE)
}

# Verification : spdep opérationnel
if (requireNamespace("spdep", quietly = TRUE)) {
  message("[J6] spdep operationnel pour les statistiques spatiales.")
  message("[J6] Version detectee : ", as.character(packageVersion("spdep")))
}
