# =====================================================================
# install_packages_day.R
# J10 — Flux reproductibles, mini-projet et clôture
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
  # --- Reproductibilite projet ---
  "usethis",         # create_project, use_git, use_github
  "here",            # chemins relatifs robustes
  "fs",              # manipulation de fichiers reproductible
  "renv",            # snapshot / restore de l'environnement R

  # --- Versioning ---
  "gh",              # GitHub API
  "gert",            # Git en pur R (sans dependance systeme)

  # --- Rendu Quarto + publication ---
  "quarto",          # interface R vers la CLI Quarto
  "knitr",
  "rmarkdown",
  "bookdown",        # rapports multi-chapitres

  # --- Manipulation spatiale ---
  "sf",              # vecteurs spatiaux
  "dplyr",
  "tibble",
  "readr",

  # --- Cartographie ---
  "tmap",            # plot + view (interactif)
  "ggplot2",

  # --- Automatisation fonctionnelle ---
  "purrr"            # map_dfr, possibly, safely
)

manquants <- pkgs_J10[!pkgs_J10 %in% rownames(installed.packages())]

if (length(manquants) == 0) {
  message("[J10] Tous les packages necessaires sont deja installes.")
} else {
  message("[J10] Installation des packages manquants : ",
          paste(manquants, collapse = ", "))
  install.packages(manquants, dependencies = TRUE)
}

# --- Verification fonctionnelle : Quarto CLI et Git accessibles ---------
if (requireNamespace("quarto", quietly = TRUE)) {
  v <- tryCatch(quarto::quarto_version(), error = function(e) NA)
  if (!is.na(v)) {
    message("[J10] Quarto CLI detecte. Version : ", v)
  } else {
    warning("[J10] Quarto CLI non trouve. Installer depuis ",
            "https://quarto.org/docs/get-started/")
  }
}

git_path <- Sys.which("git")
if (nzchar(git_path)) {
  message("[J10] Git detecte : ", git_path)
} else {
  warning("[J10] Git non trouve dans le PATH. Installer depuis ",
          "https://git-scm.com/downloads")
}

# --- Verification dataset fil rouge -------------------------------------
projet_root <- tryCatch(rprojroot::find_root(rprojroot::has_file("README.md")),
                        error = function(e) getwd())
dataset_j10 <- file.path(projet_root, "pedagogie", "datasets", "cameroun",
                         "jour_10", "regions_indicateurs_demo.gpkg")
if (file.exists(dataset_j10)) {
  message("[J10] Dataset fil rouge present : regions_indicateurs_demo.gpkg")
} else {
  warning("[J10] Dataset fil rouge absent. ",
          "Lancer 00_copier_datasets_edith_j10.R pour le bootstrap.")
}
