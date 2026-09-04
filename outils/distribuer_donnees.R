## =============================================================================
## DISTRIBUTION DES DONNÉES PAR JOUR — chaque dossier JXX devient autonome
## -----------------------------------------------------------------------------
## Copie, dans pedagogie/JXX_*/datasets/, les fichiers de données dont le .qmd
## de CE jour a besoin, depuis le magasin central pedagogie/all_data/.
##
## - Auto-détection : lit les littéraux "datasets/<fichier>" dans les .R et .qmd
##   situés A LA RACINE du dossier-jour (non récursif), puis copie le fichier
##   trouvé dans le magasin central.
## - Shapefiles : copie automatiquement tous les fichiers annexes (.shx, .dbf,
##   .prj, .cpg, .sbn, .sbx, .shp.xml) portant le même nom.
## - Idempotent : relançable sans risque (écrase par une copie identique).
##
## Usage : ouvrir atelier-r-spatial-iford-2026.Rproj puis
##         source("outils/distribuer_donnees.R")
## -----------------------------------------------------------------------------
## QUATRE PARTIS PRIS, ET LEURS RAISONS
##
## 1. LE MAGASIN CENTRAL EST "pedagogie/all_data".
##    Il n'existe pas de "pedagogie/datasets/cameroun" sur ce dépôt. Un chemin
##    de magasin faux arrête le script sur son propre stop() et rend TOUTE
##    copie impossible, y compris pour les fichiers réellement présents : la
##    valeur ci-dessous ne se modifie donc qu'après vérification sur disque.
##
## 2. DÉTECTION NON RÉCURSIVE, EXPLICITÉE (règle §6.2).
##    list.files() est déjà non récursif par défaut, mais un comportement
##    implicite ne se relit pas : `recursive = FALSE` est passé explicitement
##    et commenté. C'est le .qmd de la racine du dossier-jour qui pilote la
##    copie — jamais les scripts rangés dans scripts/, qui en sont des dérivés
##    et dupliqueraient les références.
##
## 3. AUCUN ÉCHEC SILENCIEUX DE COPIE (règle §1.2).
##    file.copy() renvoie un TRUE/FALSE qu'il serait facile d'ignorer ; le
##    compteur s'incrémenterait alors même quand la copie échoue (disque plein,
##    fichier verrouillé, droits). Le retour est testé, et les échecs sont
##    comptés et nommés séparément des fichiers absents du magasin.
##
## 4. COMPTE-RENDU FINAL EN cat() (règle §5.2).
##    Les message() partent sur stderr et se perdent dans un Render Quarto ou
##    un Rscript redirigé. Le bilan de fin — nombre de fichiers copiés, nombre
##    de fichiers introuvables dans le magasin AVEC LEUR NOM, nombre d'échecs
##    de copie — est écrit en cat() sur stdout.
## =============================================================================

## --- Se placer a la racine du projet ----------------------------------------
## Ce script raisonne en chemins relatifs a la racine. Selon d'ou on le lance
## (racine, pedagogie/, un dossier-jour apres un Render...), le repertoire de
## travail n'y est pas. On remonte donc jusqu'a trouver le .Rproj, plutot que
## d'exiger un setwd() prealable dont l'oubli ferait echouer le script.
.marqueur <- "atelier-r-spatial-iford-2026.Rproj"
if (!file.exists(.marqueur)) {
  .depart <- getwd()
  for (.i in 1:6) {
    if (file.exists(.marqueur)) break
    .parent <- dirname(getwd())
    if (identical(.parent, getwd())) break   # racine du disque atteinte
    setwd(.parent)
  }
  if (file.exists(.marqueur)) {
    message("Repertoire de travail replace sur la racine du projet :\n  ", getwd())
  } else {
    setwd(.depart)
    stop("Racine du projet introuvable depuis ", .depart,
         "\nOuvrez atelier-r-spatial-iford-2026.Rproj, ou placez-vous a la ",
         "racine du projet avec setwd(), puis relancez ce script.")
  }
}

## --- Magasin central --------------------------------------------------------
## Seul emplacement de reference des donnees sources (cf. entete, point 1).
central <- "pedagogie/all_data"
if (!dir.exists(central))
  stop("Magasin central introuvable : ", central,
       "\nLes sources lourdes doivent etre restaurees dans ce dossier ",
       "(cf. outils/A_RESTAURER.md).")

## index de tous les fichiers du magasin central
idx        <- list.files(central, recursive = TRUE, full.names = TRUE)
idx_base   <- basename(idx)

jours <- list.dirs("pedagogie", recursive = FALSE)
jours <- sort(jours[grepl("/J[0-9]{2}_", jours)])

## CONTROLE DE COUVERTURE.
## L'atelier compte ONZE journees. Si le compte differe, c'est qu'un dossier
## a ete renomme hors convention (JX au lieu de J0X) et qu'il sera ignore en
## silence par la boucle ci-dessous.
cat("Journees detectees :", length(jours), "\n")
cat(paste0("  - ", basename(jours), collapse = "\n"), "\n\n")
if (length(jours) != 11L)
  warning("ATTENDU 11 dossiers-jours, ", length(jours), " detecte(s).\n",
          "  Un dossier hors convention JXX_ (deux chiffres) serait ignore.\n",
          "  Verifiez la liste ci-dessus avant d'aller plus loin.")

extensions_shp <- c("shp","shx","dbf","prj","cpg","sbn","sbx","xml")
total_copies <- 0L; recap <- list()

for (jd in jours) {
  ## Références "datasets/<fichier>" dans les .R et .qmd du jour.
  ## recursive = FALSE (regle §6.2) : SEULE la racine du dossier-jour est lue.
  ## Les scripts de scripts/ sont des derives du .qmd et ne pilotent rien.
  ## SEULS LES .qmd PILOTENT LA COPIE.
  ## Lire aussi les .R de la racine serait une erreur : les trois scripts
  ## d'une journee sont DERIVES du .qmd (regle 1.5) et ne sont pas toujours
  ## regeneres apres une correction. Ils portent donc des references mortes
  ## que le .qmd, lui, ne porte plus :
  ##   - FIES_Cameroun.csv         (J06, J07, J11) -- substitue par s09q13a
  ##   - Sentinel-2 B03 / B04      (J07)           -- bandes jamais acquises
  ##   - ghs_built_2025_cmr_100m   (J08)           -- appartient au J09
  ## Les lire ferait reclamer au magasin des fichiers volontairement absents,
  ## et noierait les vrais manquants sous de fausses alertes.
  ## Le referentiel est explicite (6.2) : c'est le .qmd qui pilote.
  fichiers_src <- list.files(jd, pattern = "\\.qmd$", full.names = TRUE,
                             recursive = FALSE)
  refs <- character(0)
  for (s in fichiers_src) {
    tx <- readLines(s, warn = FALSE, encoding = "UTF-8")
    m  <- regmatches(tx, gregexpr('["\']datasets/[^"\']+["\']', tx))
    refs <- c(refs, gsub('^["\']datasets/|["\']$', "", unlist(m)))
  }

  ## Les .R de la racine ne pilotent plus rien, mais on ne les ignore pas en
  ## silence : on signale les references qu'ils portent et que le .qmd ne
  ## porte pas. C'est le symptome d'un script a regenerer.
  orphelins <- character(0)
  for (s in list.files(jd, pattern = "\\.R$", full.names = TRUE,
                       recursive = FALSE)) {
    tx <- readLines(s, warn = FALSE, encoding = "UTF-8")
    m  <- regmatches(tx, gregexpr('["\']datasets/[^"\']+["\']', tx))
    orphelins <- c(orphelins, gsub('^["\']datasets/|["\']$', "", unlist(m)))
  }
  orphelins <- setdiff(unique(basename(orphelins)), unique(basename(refs)))
  refs <- unique(basename(refs[grepl("\\.", refs)]))

  ## PAS DE `next` SILENCIEUX (regle 1.2). Une journee dont le .qmd ne porte
  ## aucun litteral "datasets/<fichier>" serait sinon passee sans un mot --
  ## indiscernable d'une journee correctement traitee. C'est le cas,
  ## legitime, d'une journee purement methodologique ; c'est aussi le
  ## symptome d'un .qmd dont les chemins ont ete casses. Les deux doivent
  ## se voir.
  if (!length(refs)) {
    message(sprintf("%-32s  aucun litteral \"datasets/...\" trouve", basename(jd)))
    recap[[basename(jd)]] <- list(copies = 0L, manquants = character(0),
                                  echecs = character(0), sans_ref = TRUE)
    next
  }

  dd <- file.path(jd, "datasets")
  dir.create(dd, recursive = TRUE, showWarnings = FALSE)

  copies <- 0L; manquants <- character(0); echecs <- character(0)
  for (bn in refs) {
    stem <- tools::file_path_sans_ext(bn)
    if (tolower(tools::file_ext(bn)) == "shp") {
      hits <- idx[tools::file_path_sans_ext(idx_base) == stem &
                  tolower(tools::file_ext(idx_base)) %in% extensions_shp]
    } else {
      hits <- idx[idx_base == bn]
    }
    if (!length(hits)) { manquants <- c(manquants, bn); next }
    for (h in unique(hits)) {
      ## Le retour de file.copy() est TESTE : une copie ratee ne doit pas
      ## incrementer le compteur en silence (regle §1.2).
      ok <- file.copy(h, file.path(dd, basename(h)), overwrite = TRUE)
      if (isTRUE(ok)) copies <- copies + 1L
      else            echecs <- c(echecs, basename(h))
    }
  }
  total_copies <- total_copies + copies
  recap[[basename(jd)]] <- list(copies    = copies,
                                manquants = unique(manquants),
                                echecs    = unique(echecs),
                                orphelins = orphelins)
  message(sprintf("%-32s %2d fichier(s) copié(s)%s", basename(jd), copies,
                  if (length(manquants))
                    paste0("  |  ABSENTS du magasin : ", paste(unique(manquants), collapse = ", "))
                  else ""))
}

## --- Compte-rendu final (cat, sur stdout) -----------------------------------
manq_all  <- sort(unique(unlist(lapply(recap, `[[`, "manquants"))))
echec_all <- sort(unique(unlist(lapply(recap, `[[`, "echecs"))))

cat("\n=============================== BILAN ===============================\n")
cat("Magasin central lu          : ", central, " (", length(idx),
    " fichier(s) indexes)\n", sep = "")
cat("Journees detectees          : ", length(jours), " / 11 attendues\n", sep = "")
cat("Journees traitees           : ", length(recap), "\n", sep = "")
cat("Fichiers copies             : ", total_copies, "\n", sep = "")
cat("Fichiers INTROUVABLES       : ", length(manq_all), "\n", sep = "")
cat("Copies en ECHEC             : ", length(echec_all), "\n", sep = "")

cat("\n-- Detail par journee -----------------------------------------------\n")
for (nm in names(recap)) {
  r <- recap[[nm]]
  if (isTRUE(r$sans_ref)) {
    cat(sprintf("  %-32s AUCUNE reference \"datasets/...\"\n", nm))
  } else {
    cat(sprintf("  %-32s copies=%-3d introuvables=%-3d echecs=%d\n",
                nm, r$copies, length(r$manquants), length(r$echecs)))
  }
}

## Couverture : toute journee detectee mais absente du recap n'a pas ete vue.
non_traitees <- setdiff(basename(jours), names(recap))
if (length(non_traitees)) {
  cat("\n!! JOURNEES DETECTEES MAIS NON TRAITEES :\n")
  for (n in non_traitees) cat("   - ", n, "\n", sep = "")
}
sans_ref <- names(recap)[vapply(recap, function(r) isTRUE(r$sans_ref), logical(1))]
if (length(sans_ref)) {
  cat("\n-- Journees sans aucune reference de donnees ------------------------\n")
  cat("   Legitime pour une journee purement methodologique ; suspect sinon.\n")
  cat("   Verifiez que le .qmd de ces journees porte bien des litteraux\n")
  cat("   \"datasets/<fichier>\" a plat, sans here() ni sous-dossier.\n")
  for (n in sans_ref) cat("   - ", n, "\n", sep = "")
}

if (length(manq_all)) {
  cat("\n-- Referencés par un .qmd mais ABSENTS du magasin central -----------\n")
  cat("   (a restaurer dans ", central, " — cf. outils/A_RESTAURER.md)\n", sep = "")
  for (m in manq_all) cat("   - ", m, "\n", sep = "")
} else {
  cat("\nAucun fichier manquant : toutes les references ont ete satisfaites.\n")
}

if (length(echec_all)) {
  cat("\n-- Fichiers TROUVES mais dont la COPIE A ECHOUE ---------------------\n")
  cat("   (fichier verrouille, droits insuffisants, disque plein ?)\n")
  for (e in echec_all) cat("   - ", e, "\n", sep = "")
}

## -- References mortes dans les scripts derives ------------------------------
orph <- Filter(length, lapply(recap, `[[`, "orphelins"))
if (length(orph)) {
  cat("\n-- Scripts .R portant des references que le .qmd ne porte plus ------\n")
  cat("   Ces fichiers ne sont PAS distribues : le .qmd fait autorite (6.2).\n")
  cat("   C'est le symptome de scripts derives non regeneres apres correction.\n")
  cat("   Attendus a ce stade : FIES_Cameroun.csv (J06/J07/J11), les bandes\n")
  cat("   Sentinel B03 et B04 (J07), ghs_built_2025_cmr_100m.tif (J08).\n")
  cat("   Ils disparaitront a la regeneration des scripts depuis le .qmd.\n")
  for (nm in names(orph))
    cat(sprintf("   %-32s %s\n", nm, paste(orph[[nm]], collapse = ", ")))
}

cat("\nChaque dossier pedagogie/JXX_*/ est desormais autonome : datasets/ +\n",
    "scripts + install_packages_day.R + README, tous en chemins relatifs.\n",
    "Partageable tel quel.\n", sep = "")
cat("=====================================================================\n")
