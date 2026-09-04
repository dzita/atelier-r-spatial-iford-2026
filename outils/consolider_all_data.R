## =============================================================================
## CONSOLIDATION — remonter toutes les donnees vers pedagogie/all_data
## -----------------------------------------------------------------------------
## POURQUOI CE SCRIPT
## Des datasets/ de journees ont pu etre remplis directement, avant que
## l'architecture ne soit fixee : le .bat d'installation y deposait les donnees
## J08-J10, et des fichiers y ont ete copies a la main. Une partie des donnees
## n'existe alors QUE dans un dossier-jour et pas dans le magasin central. Ce
## script les y remonte.
##
## L'ARCHITECTURE CIBLE, apres passage :
##   1. all_data/ contient UN exemplaire de chaque fichier. C'est lui qui est
##      versionne dans Git.
##   2. distribuer_donnees.R repartit all_data/ vers les onze datasets/, en
##      lisant les litteraux "datasets/<fichier>" des .qmd.
##   3. les datasets/ ne sont plus versionnes : ils sont reconstruits apres
##      chaque clone. Un seul exemplaire de DS.geojson dans Git au lieu de sept.
##
## CE SCRIPT NE SUPPRIME RIEN. Il copie vers le haut, c'est tout. Le menage des
## datasets/ est fait par Git (ils sont ignores), et manuellement ensuite si
## besoin.
##
## PRUDENCE SUR LES COLLISIONS. Si un fichier existe deja dans all_data avec une
## TAILLE DIFFERENTE, il n'est PAS ecrase : le conflit est signale et tranche a
## la main. Ecraser en silence deux fichiers homonymes de contenus differents
## est exactement le genre d'erreur que le referentiel interdit (regle 1.2).
##
## Usage : ouvrir atelier-r-spatial-iford-2026.Rproj, puis
##         source("outils/consolider_all_data.R")
## =============================================================================

## --- Se placer a la racine du projet ----------------------------------------
.marqueur <- "atelier-r-spatial-iford-2026.Rproj"
if (!file.exists(.marqueur)) {
  .depart <- getwd()
  for (.i in 1:6) {
    if (file.exists(.marqueur)) break
    .parent <- dirname(getwd())
    if (identical(.parent, getwd())) break
    setwd(.parent)
  }
  if (file.exists(.marqueur)) {
    message("Repertoire de travail replace sur la racine :\n  ", getwd())
  } else {
    setwd(.depart)
    stop("Racine du projet introuvable depuis ", .depart,
         "\nOuvrez atelier-r-spatial-iford-2026.Rproj, puis relancez.")
  }
}

central <- "pedagogie/all_data"
dir.create(central, recursive = TRUE, showWarnings = FALSE)

## --- Inventaire du magasin central AVANT ------------------------------------
avant <- list.files(central, recursive = TRUE, full.names = TRUE)
cat("Magasin central avant consolidation :", length(avant), "fichier(s)\n\n")

## --- Les onze dossiers-jours ------------------------------------------------
jours <- list.dirs("pedagogie", recursive = FALSE)
jours <- sort(jours[grepl("/J[0-9]{2}_", jours)])
cat("Journees examinees :", length(jours), "\n")
if (length(jours) != 11)
  warning("Attendu 11 dossiers-jours, ", length(jours), " trouve(s). ",
          "Verifiez la nomenclature JXX_ a deux chiffres.")

## Fichiers qui ne sont PAS des donnees et ne doivent pas remonter.
a_ignorer <- c("LISEZMOI.md", ".gitkeep", "README.md")

copies <- character(0)   # remontes
deja   <- character(0)   # presents a l'identique
conflits <- character(0) # meme nom, taille differente
origine <- list()        # pour tracer les doublons entre journees

for (jd in jours) {
  dd <- file.path(jd, "datasets")
  if (!dir.exists(dd)) next

  fichiers <- list.files(dd, full.names = TRUE, recursive = TRUE)
  fichiers <- fichiers[!basename(fichiers) %in% a_ignorer]
  if (!length(fichiers)) next

  n_j <- 0L
  for (f in fichiers) {
    bn  <- basename(f)
    dst <- file.path(central, bn)

    ## On trace d'ou vient chaque nom, pour signaler les doublons ensuite.
    origine[[bn]] <- c(origine[[bn]], basename(jd))

    if (!file.exists(dst)) {
      ok <- file.copy(f, dst, overwrite = FALSE, copy.date = TRUE)
      if (isTRUE(ok)) { copies <- c(copies, bn); n_j <- n_j + 1L }
      else            conflits <- c(conflits, paste0(bn, " (echec de copie)"))
    } else if (isTRUE(file.size(f) == file.size(dst))) {
      deja <- c(deja, bn)
    } else {
      conflits <- c(conflits,
                    sprintf("%s (%s : %.1f Mo | all_data : %.1f Mo)",
                            bn, basename(jd),
                            file.size(f) / 1024^2, file.size(dst) / 1024^2))
    }
  }
  cat(sprintf("  %-34s %3d fichier(s) examine(s), %2d remonte(s)\n",
              basename(jd), length(fichiers), n_j))
}

## --- Compte rendu -----------------------------------------------------------
apres <- list.files(central, recursive = TRUE, full.names = TRUE)

cat("\n=====================================================================\n")
cat(" CONSOLIDATION — RECAPITULATIF\n")
cat("=====================================================================\n")
cat("  Remontes vers all_data      :", length(unique(copies)), "\n")
cat("  Deja presents a l'identique :", length(unique(deja)), "\n")
cat("  CONFLITS (non ecrases)      :", length(conflits), "\n")
cat("  Magasin central apres       :", length(apres), "fichier(s)\n")
cat("  Poids total du magasin      :",
    round(sum(file.size(apres), na.rm = TRUE) / 1024^2), "Mo\n\n")

if (length(unique(copies))) {
  cat("Fichiers remontes :\n")
  cat(paste0("  + ", sort(unique(copies)), collapse = "\n"), "\n\n")
}

if (length(conflits)) {
  cat("!! CONFLITS — meme nom, contenu different. RIEN N'A ETE ECRASE.\n")
  cat("   Tranchez a la main : gardez la bonne version dans all_data,\n")
  cat("   puis relancez ce script.\n")
  cat(paste0("  ! ", conflits, collapse = "\n"), "\n\n")
}

## --- Doublons entre journees : ce que la nouvelle architecture economise ----
multi <- origine[vapply(origine, function(x) length(unique(x)) > 1L, logical(1))]
if (length(multi)) {
  cat("Fichiers presents dans PLUSIEURS journees (un seul exemplaire dans Git\n")
  cat("desormais, les datasets/ n'etant plus versionnes) :\n")
  for (bn in names(sort(vapply(multi, function(x) length(unique(x)), integer(1)),
                        decreasing = TRUE))) {
    cat(sprintf("  %-46s x%d  (%s)\n", bn, length(unique(multi[[bn]])),
                paste(unique(multi[[bn]]), collapse = ", ")))
  }
  cat("\n")
}

cat("ETAPE SUIVANTE :\n")
cat("  source(\"outils/distribuer_donnees.R\")\n")
cat("  pour repartir all_data/ vers les onze datasets/.\n")
cat("=====================================================================\n")
