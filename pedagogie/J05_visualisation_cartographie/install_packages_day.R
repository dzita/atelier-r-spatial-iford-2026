# =====================================================================
# install_packages_day.R
# J5 — Visualisation et cartographie
# Packages minimaux pour suivre la journée.
# =====================================================================
#
# Convention atelier IFORD x GDSG 2026 :
#   - Chaque dossier JXX_.../ contient un install_packages_day.R
#     qui liste UNIQUEMENT les packages necessaires pour ce jour.
#   - Pour installer tout l'environnement d'un coup, lancer plutot :
#     source("environnement_technique/install_packages.R")
# =====================================================================

pkgs_J05 <- c(
  # Recyclage J1/J2
  "sf", "dplyr", "ggplot2",
  # Nouveautés de J5 — cartographie thématique
  "tmap",           # v4 : modes plot/view, classifications, multi-panel
  "classInt",       # algorithmes de classification (Jenks, head-tails)
  "RColorBrewer",   # palettes ColorBrewer
  "viridisLite",    # viridis perceptuellement uniforme
  "leaflet",        # cartes interactives web
  "ggspatial",      # flèche du nord + échelle pour ggplot
  "scales"          # formatage des étiquettes
)

manquants <- pkgs_J05[!pkgs_J05 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J5] Tous les packages necessaires sont deja installes.")
} else {
  message("[J5] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, dependencies = TRUE)
}

# Verification fonctionnelle : tmap v4 requis (API change majeur depuis v3)
if (requireNamespace("tmap", quietly = TRUE)) {
  v <- as.character(packageVersion("tmap"))
  if (utils::compareVersion(v, "4.0") >= 0) {
    message("[J5] tmap v", v, " operationnel.")
  } else {
    warning("[J5] tmap v", v,
            " detecte. Version 4.0+ requise. Mettre a jour : install.packages('tmap')")
  }
}
