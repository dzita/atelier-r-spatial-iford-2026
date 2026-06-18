# =====================================================================
# install_packages_day.R
# J10 — Flux de travail reproductibles et clôture
# Packages minimaux pour suivre la journée.
# =====================================================================
#
# Convention atelier IFORD x GDSG 2026 :
#   - Chaque dossier JXX_.../ contient un install_packages_day.R
#     qui liste UNIQUEMENT les packages necessaires pour ce jour.
#   - Pour installer tout l'environnement d'un coup, lancer plutot :
#     source("environnement_technique/install_packages.R")
# =====================================================================

pkgs_J10 <- c(
  # Reproductibilité et init projet
  "usethis",         # create_project, use_git, use_github
  "gh",              # GitHub API
  "gert",            # Git en pur R (sans dépendance système)
  "renv",            # snapshot / restore de l'environnement R

  # Automatisation fonctionnelle
  "purrr",           # map_*, possibly, safely

  # Rendu Quarto + publication
  "quarto",          # interface R vers la CLI Quarto
  "knitr",
  "rmarkdown",
  "bookdown"         # rapports multi-chapitres
)

manquants <- pkgs_J10[!pkgs_J10 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J10] Tous les packages necessaires sont deja installes.")
} else {
  message("[J10] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, dependencies = TRUE)
}

# Verification fonctionnelle : Quarto CLI et Git accessibles
if (requireNamespace("quarto", quietly = TRUE)) {
  v <- tryCatch(quarto::quarto_version(), error = function(e) NA)
  if (!is.na(v)) {
    message("[J10] Quarto CLI detecte. Version : ", v)
  } else {
    warning("[J10] Quarto CLI non trouve. Installer depuis https://quarto.org/docs/get-started/")
  }
}

git_path <- Sys.which("git")
if (nzchar(git_path)) {
  message("[J10] Git detecte : ", git_path)
} else {
  warning("[J10] Git non trouve dans le PATH. Installer depuis https://git-scm.com/downloads")
}
