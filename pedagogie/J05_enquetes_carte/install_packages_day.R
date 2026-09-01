## ============================================================================
## J05 — Des enquetes a la carte : relier donnees et territoires
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026
## ============================================================================

## Liste alignee sur les library() REELLEMENT charges par la journee.
## Les paquets de statistique spatiale (spdep, gstat, automap), de raster
## (terra, exactextractr, tidyterra) et d'imputation avancee (VIM, mice)
## relevent des journees J04, J07 et suivantes : ils sont installes par le
## install_packages_day.R de ces journees-la. Les inclure ici allongerait
## l'installation de plusieurs dizaines de minutes en salle, pour des paquets
## jamais charges au J05.

pkgs_j05 <- c(
  "tidyverse",   # dplyr, tidyr, ggplot2, readr, stringr, forcats...
  "haven",       # lire .sav (SPSS) et .dta (Stata) avec les etiquettes
  "janitor",     # clean_names()
  "naniar",      # vis_miss() : structure des valeurs manquantes
  "sf",          # donnees vectorielles (Simple Features)
  "tmap",        # cartographie thematique -- VERSION 4 requise
  "stringi",     # translitteration des accents (cles de jointure)
  "ggrepel",     # etiquettes non chevauchantes (section 5.2)
  "scales"       # mise en forme des axes
)

a_installer <- pkgs_j05[!pkgs_j05 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  install.packages(a_installer)
} else {
  message("Tous les packages du J05 sont deja installes.")
}

## Verification : tout doit se charger sans erreur
invisible(lapply(pkgs_j05, function(p) {
  ok <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))

## Le materiel de cette journee utilise l'API tmap 4 : tm_polygons(fill = ),
## tm_scale_intervals(), tm_legend(), tm_title(), tm_scalebar().
## Avec tmap 3, tous les blocs cartographiques echouent.
v_tmap <- tryCatch(packageVersion("tmap"), error = function(e) NULL)
if (!is.null(v_tmap)) {
  message("\ntmap installe : version ", v_tmap)
  if (v_tmap < "4.0.0")
    warning("tmap ", v_tmap, " detecte : le materiel du J05 exige tmap >= 4.0.0. ",
            "Lancez install.packages(\"tmap\") pour mettre a jour.")
}

## Rappel sur les donnees : le dossier datasets/ doit contenir les 7 sources
## listees dans datasets/LISEZMOI.md. Depuis la racine du projet :
##   source("outils/distribuer_donnees.R")
if (dir.exists("datasets")) {
  message("\nFichiers presents dans datasets/ : ", length(list.files("datasets")))
} else {
  message("\nATTENTION : dossier datasets/ absent. Lancez, depuis la racine ",
          "du projet, source(\"outils/distribuer_donnees.R\").")
}
