## ============================================================================
## J10 — Les donnees spatiales au service des politiques publiques
## Installation des packages necessaires a la journee (a executer UNE fois).
## Atelier IFORD x GDSG 2026
## ============================================================================
##
## PREVOIR DU TEMPS. Deux paquets de cette liste sont longs a installer :
##   - survey  : nombreuses dependances (Matrix, mitools, minqa, numDeriv...)
##   - sae     : depend de nlme, MASS et surtout de sp / spdep, dont la
##               compilation depuis les sources peut prendre plusieurs minutes
##               sur une machine sans binaire disponible.
## Sur un poste Windows ou macOS, choisir les BINAIRES lorsque R le propose
## ("Do you want to install from sources...?" -> repondre "no"). Sous Linux,
## prevoir 15 a 30 minutes et une connexion stable. A faire AVANT la salle.

## Liste alignee sur les library() REELLEMENT charges par demo_formateur_J10.qmd,
## et rien de plus.
pkgs_j10 <- c(
  "sf",             # donnees vectorielles (Simple Features)
  "sae",            # modele de Fay-Herriot : mseFH()  -- LOURD
  "survey",         # plans de sondage : svydesign(), svymean(), svyby() -- LOURD
  "dplyr",          # verbes de manipulation de tableaux
  "tidyr",          # pivot_longer(), replace_na()
  "ggplot2",        # graphiques
  "readr",          # lecture des CSV
  "tmap",           # cartographie thematique -- VERSION 4 requise
  "scales",         # mise en forme des axes (label_number)
  "terra",          # rasters et NetCDF : rast(), crop(), mask()
  "exactextractr"   # statistiques zonales ponderees par la fraction de cellule
)

## Paquets volontairement ECARTES, et la journee a laquelle ils appartiennent.
## Les inclure ici allongerait l'installation de plusieurs dizaines de minutes
## en salle, pour des paquets que le J10 ne charge jamais :
##   - haven, janitor, naniar, stringi ......... J05 (lecture .dta/.sav, cles)
##   - spdep, gstat, automap ................... J04 (autocorrelation, krigeage)
##   - mapedit, leaflet ........................ J08 (zone dessinee a la main)
##   - osmdata ................................. J09 (routes OpenStreetMap)
##   - tidyterra ............................... J09 (rasters dans ggplot2)
##   - acledR, ecmwfr, rgee .................... APIs, blocs de reference du J10
##                                               en eval: false -- NON requis
##                                               pour rendre le document.
##   - tibble .................................. installe comme dependance de
##                                               dplyr ; le document l'appelle
##                                               en tibble::tribble().

a_installer <- pkgs_j10[!pkgs_j10 %in% rownames(installed.packages())]
if (length(a_installer)) {
  message("Installation de : ", paste(a_installer, collapse = ", "))
  if (any(c("sae", "survey") %in% a_installer)) {
    message("  -> sae et/ou survey sont dans la liste : prevoir plusieurs minutes.")
  }
  install.packages(a_installer)
} else {
  message("Tous les packages du J10 sont deja installes.")
}

## Verification : tout doit se charger sans erreur.
invisible(lapply(pkgs_j10, function(p) {
  ok <- suppressWarnings(suppressPackageStartupMessages(
    require(p, character.only = TRUE, quietly = TRUE)))
  message(ifelse(ok, "OK      : ", "MANQUE  : "), p)
}))

## --- Controle de version tmap ------------------------------------------------
## Le materiel de cette journee utilise l'API tmap 4 : tm_polygons(fill = ),
## tm_scale_continuous(), tm_scale_intervals(), tm_legend(), tm_title().
## Avec tmap 3, TOUS les blocs cartographiques echouent.
v_tmap <- tryCatch(packageVersion("tmap"), error = function(e) NULL)
if (!is.null(v_tmap)) {
  message("\ntmap installe : version ", v_tmap)
  if (v_tmap < "4.0.0") {
    warning("tmap ", v_tmap, " detecte : le materiel du J10 exige tmap >= 4.0.0. ",
            "Lancez install.packages(\"tmap\") pour mettre a jour.")
  }
}

## --- Controle de l'ordre de chargement sae / dplyr ---------------------------
## sae depend de MASS, qui definit une fonction select(). Si dplyr est charge
## AVANT sae, c'est MASS::select() qui gagne et la journee casse au Module 6 sur
## un message incomprehensible. demo_formateur_J10.qmd charge donc sae en second
## et dplyr en quatrieme. Ce controle le verifie dans la session courante.
##
## CORRECTIF 01/09/2026 -- la version precedente de ce controle produisait un
## FAUX POSITIF. Elle appelait library(sae) puis library(dplyr) dans la session
## courante. Or la boucle de verification plus haut a DEJA attache dplyr, et
## library() sur un package deja attache est une operation NULLE : elle ne le
## remonte pas dans la search path. Resultat : library(sae) inserait MASS
## AU-DESSUS de dplyr, et le controle signalait un probleme qu'il venait lui-meme
## de creer. Le .qmd, lui, s'execute dans une session Quarto neuve et charge bien
## sae en second, dplyr en quatrieme.
##
## On teste donc dans un PROCESSUS SEPARE et neuf, seul endroit ou la question
## a un sens.
deja_attaches <- intersect(c("dplyr", "sae", "MASS"),
                           sub("^package:", "", search()))
if (length(deja_attaches)) {
  message("\nPackages deja attaches dans cette session : ",
          paste(deja_attaches, collapse = ", "),
          "\n  -> l'ordre de chargement ne peut pas etre teste ici.")
}

if (requireNamespace("dplyr", quietly = TRUE) &&
    requireNamespace("sae", quietly = TRUE)) {
  code <- paste(
    'suppressPackageStartupMessages({library(sae); library(dplyr)})',
    'cat(environmentName(environment(get("select"))))',
    sep = "; ")
  fournisseur <- tryCatch(
    system2(file.path(R.home("bin"), "Rscript"),
            args = c("-e", shQuote(code)), stdout = TRUE, stderr = FALSE),
    error = function(e) NA_character_)
  fournisseur <- if (length(fournisseur)) tail(fournisseur, 1) else NA_character_

  if (is.na(fournisseur) || !nzchar(fournisseur)) {
    message("\nControle sae/dplyr : non concluant (Rscript injoignable). ",
            "A verifier au premier rendu : le .qmd imprime ",
            "'select() vient de :' -- il doit afficher dplyr.")
  } else {
    message("\nDans une session neuve, select() est fourni par : ", fournisseur)
    if (!identical(fournisseur, "dplyr")) {
      warning("select() vient de ", fournisseur, " et non de dplyr, ",
              "MEME en session neuve. Verifiez l'ordre des library() en tete ",
              "de demo_formateur_J10.qmd : sae doit venir AVANT dplyr.")
    }
  }
}

## --- Rappel sur les donnees --------------------------------------------------
## Le dossier datasets/ doit contenir les 8 fichiers listes dans
## datasets/LISEZMOI.md. Depuis la racine du projet :
##   source("outils/distribuer_donnees.R")
if (dir.exists("datasets")) {
  message("\nFichiers presents dans datasets/ : ", length(list.files("datasets")))
} else {
  message("\nATTENTION : dossier datasets/ absent. Lancez, depuis la racine ",
          "du projet, source(\"outils/distribuer_donnees.R\").")
}
