## ============================================================================
## SCRIPT ÉTUDIANT — J01 · Changer d'outil sans changer de métier : les fondations
## Atelier IFORD × GDSG 2026 · Lundi 27 juillet 2026
## ----------------------------------------------------------------------------
## Ce script reprend la trame de la démonstration du formateur : les commentaires
## et les lectures de données sont fournis, le reste du code est à écrire par vous,
## sous la supervision du formateur. Travaillez depuis la racine du projet
## (ouvrir atelier-r-spatial-iford-2026.Rproj) ; les chemins sont relatifs.
## Solution complète : script_etudiant_J01_corrige.R
## ============================================================================

## ============================================================================
## [PREPARATION ATELIER - GDSG, juillet 2026]
## Ce script s'execute depuis la RACINE du projet RStudio :
##   1. Ouvrir atelier-r-spatial-iford-2026.Rproj (les chemins sont relatifs).
##   2. Donnees : datasets/ (fournies avec ce dossier ; chemins relatifs)
##   3. Les sorties de ce script sont ecrites dans outputs/.
## Donnees du jour (format SPSS, fournies via outils/distribuer_donnees.R) :
##      - datasets/CMHR71FL.SAV   (menages / Household Recode)
##      - datasets/CMIR71FL.SAV   (femmes  / Individual Recode)
dir.create("outputs", recursive = TRUE, showWarnings = FALSE)
## ============================================================================

## =============================================================================
## PROGRAMME DE FORMATION R -- DONNEES SPATIALES, ANALYSE ET MANIPULATION DANS R
## JOUR 01 -- FONDATIONS R & RSTUDIO
## -----------------------------------------------------------------------------
## Public       : niveau 1 en R, bonne familiarite STATA / SPSS
## Support      : DHS Cameroun 2018 -- fichier menages (CMHR71FL) et
##                fichier femmes  (CMIR71FL)
## Objectif     : installer, s'orienter, scripter, importer, transposer
##                (cf. slide 2) -- avant d'attaquer la manipulation de
##                donnees au Jour 1
## Usage        : ce script s'execute du debut a la fin, section par
##                section (Ctrl+Entree / Cmd+Entree ligne a ligne, ou
##                Ctrl+Alt+R pour tout executer). Il est concu pour ne
##                jamais s'arreter en erreur, meme sans les fichiers de
##                donnees : chaque import est protege par un test.
## =============================================================================


## =============================================================================
## 0. VERIFICATIONS DE DEPART -------------------------------------------------
##    (equivalent : verifier sa version de STATA/SPSS avant de commencer)
## =============================================================================

# Version de R utilisee -- a comparer avec celle installee en salle
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# Repertoire de travail courant (equivalent du "cd" en STATA)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# --- Astuce : travailler par PROJET RSTUDIO --------------------------------
# File > New Project > Existing/New Directory
# Un projet RStudio associe automatiquement un dossier de travail au script,
# ce qui evite les chemins absolus qui cassent d'un ordinateur a l'autre.
# Une fois le projet ouvert, getwd() renvoie directement la racine du projet.


## =============================================================================
## 1. DE STATA / SPSS A R : TABLEAU DE CORRESPONDANCE (a garder sous les yeux)
## =============================================================================
##
##  Notion                     | STATA / SPSS                    | R
##  ----------------------------------------------------------------------------
##  Editeur de commandes       | Do-file editor / Syntax editor  | Script editor (RStudio)
##  Fenetre de resultats       | Results window                  | Console
##  Extensions                 | ado-files, packages SPSS        | Packages CRAN
##  Fichier de donnees natif   | .dta / .sav                      | haven::read_dta() / read_sav()
##  Assignation d'une valeur   | generate / gen ; compute         | <-
##  Structure du jeu de donnees| describe / codebook              | str(df) / glimpse(df)
##  Premieres lignes           | browse / Data View                | head(df)
##  Statistiques descriptives  | summarize                         | summary(df)
##  Tri a plat                 | tab varname                       | table(df$varname)
##  Valeurs manquantes         | misstable summarize               | colSums(is.na(df))
##  Commentaire                | * ou //                           | #
## =============================================================================


## =============================================================================
## 2. R ET RSTUDIO : DEUX CHOSES DIFFERENTES (slide 5)
## =============================================================================
# R       = le langage / le moteur de calcul (comme le moteur STATA, tourne
#           meme sans interface graphique). A installer en premier.
# RStudio = l'environnement de travail (IDE) : script editor (haut-gauche),
#           console (bas-gauche), environment/history (haut-droite),
#           files/plots/packages/help (bas-droite). Se connecte
#           automatiquement a R apres son installation.
#
# Installation (slide 6) :
#   1. R       -> https://cran.r-project.org
#   2. RStudio -> https://posit.co/download/rstudio-desktop  (version gratuite)
#   Installer RStudio APRES R.


## =============================================================================
## 3. PREMIER SCRIPT R (slide 8)
## =============================================================================

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# Le symbole <- assigne une valeur a un objet -- equivalent de generate/gen
# en STATA, ou de compute en SPSS. Le signe = fonctionne aussi la plupart
# du temps, mais <- reste la convention R.

# Bonne pratique (slide 14) : nommer clairement ses objets --------------------
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................
                                  # fin de la session : surveiller le panneau
                                  # Environment (haut-droite dans RStudio)


## =============================================================================
## 4. PACKAGES ET LIBRAIRIES (slides 9-11)
## =============================================================================

## 4.1 -- Un PACKAGE = un ensemble de fonctions/donnees/documentation,
##        comparable a un module SPSS ou un jeu d'ado-files STATA.
## 4.2 -- Une LIBRAIRIE = le dossier ou les packages sont installes.

# Liste des packages necessaires pour le J01 et pour la suite du parcours
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# Installation "intelligente" : n'installe que ce qui manque -----------------
# (equivalent slide 10, colonne "CRAN" -- install.packages() suffit dans
# l'immense majorite des cas)
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# Autres sources d'installation possibles (slide 10), a titre indicatif :
#   GitHub       : devtools::install_github("tidyverse/ggplot2")
#   Fichier local: install.packages("chemin/fichier.tar.gz", repos = NULL, type = "source")
#   Interface    : Tools > Install Packages

# Chargement (a faire a CHAQUE session, contrairement a l'installation) ------
library(tidyverse)
library(haven)
library(readxl)
library(labelled)

# --- Conflits de fonctions (masking) -- slide 9 -----------------------------
# Quand deux packages charges partagent une fonction du meme nom, le dernier
# charge masque l'autre. R vous previent avec un message
# "The following objects are masked...". Pour lever toute ambiguite, on
# prefixe explicitement la fonction par son package :
#   dplyr::filter(df, condition)
#   stats::filter(x, ...)


## =============================================================================
## 5. IMPORTER LES DONNEES DE LA FORMATION (slide 12)
## =============================================================================
## Extrait DHS Cameroun 2018 :
##   - fichier menages : CMHR71FL
##   - fichier femmes  : CMIR71FL
## Utilise sur les Jours 1 a 3 -- a placer dans le meme dossier que ce script,
## ou a defaut, adapter le chemin ci-dessous.

# Ou sont les donnees ? (equivalent du "cd" en STATA) -----------------------
# Ce script fonctionne que vous l'ouvriez depuis le dossier de la journee OU
# depuis la racine du projet : on detecte automatiquement le bon prefixe.
base_jour <- if (dir.exists("datasets")) "." else "pedagogie/J01_fondations"
if (!dir.exists(file.path(base_jour, "datasets")))
  stop("Dossier datasets/ introuvable. Ouvrez atelier-r-spatial-iford-2026.Rproj ",
       "puis lancez source(\"outils/distribuer_donnees.R\").")

## 5.1 -- Fichier menages : SPSS (.sav) -- conserve les labels, comme SPSS
chemin_menages <- file.path(base_jour, "datasets/CMHR71FL.SAV")
if (file.exists(chemin_menages)) {
  df_menages <- read_sav(chemin_menages)
  message("Fichier menages (.sav) importe : ", nrow(df_menages), " lignes, ",
          ncol(df_menages), " variables.")
} else {
  message("[Info] '", chemin_menages, "' introuvable -- lancez ",
          "source(\"outils/distribuer_donnees.R\") puis reexecutez.")
  df_menages <- NULL
}

## 5.2 -- Fichier femmes : SPSS (.sav) egalement ----------------------------
chemin_femmes <- file.path(base_jour, "datasets/CMIR71FL.SAV")
if (file.exists(chemin_femmes)) {
  df_femmes <- read_sav(chemin_femmes)
  message("Fichier femmes (.sav) importe : ", nrow(df_femmes), " lignes, ",
          ncol(df_femmes), " variables.")
} else {
  message("[Info] '", chemin_femmes, "' introuvable -- lancez ",
          "source(\"outils/distribuer_donnees.R\") puis reexecutez.")
  df_femmes <- NULL
}

## 5.3 -- Les autres formats : le geste est identique, seule la fonction change
##        (blocs de reference : ces fichiers ne sont pas fournis ce jour)
# df <- haven::read_dta("chemin/vers/fichier.dta")      # STATA -- garde les labels
# df <- readr::read_csv("chemin/vers/fichier.csv")      # CSV   -- pas de labels
# df <- readxl::read_excel("chemin/vers/fichier.xlsx")  # Excel, feuille 1

# --- Pourquoi haven ? --------------------------------------------------------
# Concu specifiquement pour les utilisateur.rice.s de STATA et SPSS : il
# importe les fichiers .dta/.sav en conservant les labels de valeurs et de
# variables, pour retrouver des reperes familiers dans R.

# --- PIEGE DE NOMMAGE, a connaitre -------------------------------------------
# DHS nomme ses variables en MINUSCULES dans les fichiers STATA (.dta) mais en
# MAJUSCULES dans les fichiers SPSS (.sav). Un test "v201" %in% names(df)
# echoue donc SILENCIEUSEMENT sur un .sav. On resout la casse une fois pour
# toutes avec cette petite fonction, reutilisee plus bas :
trouver_vars <- function(df, vars) {
  correspondance <- match(toupper(vars), toupper(names(df)))
  names(df)[correspondance[!is.na(correspondance)]]
}

# Verification des labels sur "milieu de residence" :
var_milieu <- trouver_vars(df_menages, "hv025")
if (!is.null(df_menages) && length(var_milieu)) {
  cat("Variable trouvee sous le nom :", var_milieu, "\n")
  cat("Label de la variable :", attr(df_menages[[var_milieu]], "label"), "\n\n")
  print(labelled::val_labels(df_menages[[var_milieu]]))
}


## =============================================================================
## 6. PREMIERS REFLEXES APRES L'IMPORT (slide 13)
## =============================================================================
## Les memes reflexes qu'en STATA/SPSS, transposes en R -- a executer sur
## chaque nouveau jeu de donnees, en debut d'exploration.
##
## CONSIGNE : ecrivez une fonction explorer_jeu_de_donnees(df, nom, vars) qui
## affiche, pour un SOUS-ENSEMBLE de variables (vars) : la structure str(),
## les premieres lignes head(), les statistiques summary() et le compte des
## valeurs manquantes colSums(is.na()).
## ATTENTION : un fichier DHS compte des MILLIERS de variables -- ne jamais
## faire str() ou summary() sur l'objet entier. Utilisez trouver_vars()
## (definie en section 5) pour resoudre les noms sans souci de casse.

# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# Application sur les deux fichiers importes ---------------------------------
# Variables suggerees :
#   menages : hv001, hv002, hv009, hv024, hv025, hv206, hv270
#   femmes  : v012, v024, v025, v106, v201, v190
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# Tri a plat d'une variable precise (equivalent : tab varname) --------------
# Adapter "v201" au nom reel de la variable disponible dans votre extrait.
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# Liste complete des variables disponibles (reflexe complementaire) ---------
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................


## =============================================================================
## 7. BONNES PRATIQUES DES LE DEPART (slide 14)
## =============================================================================
## 1. Travailler par PROJET RSTUDIO (File > New Project) : associe un
##    dossier de travail au script, evite les chemins absolus qui cassent
##    d'un ordinateur a l'autre.
## 2. Garder le script comme TRACE COMPLETE : comme un do-file, il doit
##    permettre de tout refaire de zero -- install.packages() et library()
##    inclus en haut de fichier (voir section 4 ci-dessus).
## 3. COMMENTER au fil de l'eau : le symbole # commente une ligne,
##    exactement comme * ou // dans STATA.
## 4. NOMMER CLAIREMENT les objets (df_menages, df_femmes... plutot que
##    df1, df2, temp) -- surveiller regulierement le panneau Environment.


## =============================================================================
## 8. MINI EXERCICE GUIDE -- A VOUS DE JOUER
## =============================================================================
## Objectif : reproduire les 5 competences du J01 (slide 2) sur un objet
## simple, sans dependre des fichiers DHS.

# 8.1 -- Scripter : creer trois objets et un calcul simple
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# 8.2 -- Transposer : recreer un "tri a plat" comme en STATA/SPSS, sur un
# vecteur factice representant une variable categorielle
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# 8.3 -- S'orienter : verifier ce qui se trouve dans l'Environment
# ..........................................................................
# >>> À COMPLÉTER : écrivez ici le code correspondant aux consignes ci-dessus.
# >>> (Aide en salle : formateur / support. Solution : script_etudiant_J01_corrige.R)
# ..........................................................................

# 8.4 -- Consigne pour la salle :
#   - Dupliquer les lignes 8.1 a 8.3 juste en dessous
#   - Remplacer les valeurs par les votres
#   - Executer avec Ctrl+Entree ligne par ligne, puis verifier le resultat
#     dans la Console et le panneau Environment


## =============================================================================
## 9. CHECKLIST DE FIN DE JOURNEE (slide 16)
## =============================================================================
## [ ] R et RStudio installes et ouverts sans erreur
## [ ] Ce script execute du debut a la fin sans erreur bloquante
## [ ] tidyverse, haven, readxl et labelled installes et charges
## [ ] Le jeu de donnees DHS Cameroun 2018 importe avec succes
##     (df_menages / df_femmes non NULL)
## [ ] str(), summary(), table(), colSums(is.na()) executes sur les donnees
## [ ] Un projet RStudio cree pour la suite de la formation
##
## NB : en cas de blocage a l'installation, une session de rattrapage est
## prevue en debut de J02 plutot que de retarder le groupe complet.


## =============================================================================
## 10. FEUILLE DE ROUTE -- LA SUITE DU PARCOURS
## =============================================================================
## Les onze journees de l'atelier :
##   J01  Fondations R & RStudio  <-- aujourd'hui
##   J02  Penser l'espace : les donnees geospatiales (+ module IA)
##   J03  L'univers vectoriel : points, lignes, polygones avec sf
##   J04  La Terre en pixels : les donnees raster avec terra
##   J05  Des enquetes a la carte : geolocaliser les donnees d'enquete
##   J06  L'art de la visualisation cartographique
##   J07  Statistiques spatiales : autocorrelation, voisinage, agregats
##   J08  Compter chaque habitant : la population en haute resolution
##   J09  Voir le territoire depuis l'espace : la teledetection
##   J10  Les donnees spatiales au service des politiques publiques
##   J11  Perenniser et transmettre
##
## Les trois journees suivantes en detail :
## J02 -- Penser l'espace. Journee SANS R : coordonnees, systemes de
##   reference, projections ; vecteur contre raster ; ou trouver les donnees.
##   L'apres-midi : module "Bien utiliser l'IA pour l'analyse de donnees".
## J03 -- L'univers vectoriel. Le package sf : lire un shapefile, comprendre
##   la colonne geometry, jointures attributaires et spatiales, premieres
##   cartes avec ggplot2 et geom_sf().
## J04 -- La Terre en pixels. Le package terra : lire un raster, resolution
##   et emprise, algebre de bandes, extraction de valeurs vers des polygones.
##
## Les gestes acquis aujourd'hui (import, str, summary, table, colSums(is.na))
## restent le point de depart de CHAQUE journee : avant de cartographier une
## donnee, on l'importe et on l'inspecte. La couche spatiale s'ajoute a ces
## reflexes, elle ne les remplace pas.
## =============================================================================
