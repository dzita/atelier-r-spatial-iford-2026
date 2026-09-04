@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM =============================================================================
REM  installer_materiel_J08_J10.bat
REM  Mise en place du materiel des journees J08, J09 et J10 de l'atelier
REM  R spatial IFORD 2026, a partir du dossier source
REM  materiel-atelier-r-spatial-iford-2026-j08-j10\.
REM
REM  Les donnees vont dans all_data, et non dans les datasets\ des journees :
REM  voir le bloc de variables plus bas pour la raison.
REM
REM  CE QU'IL FAIT
REM    1. cree pedagogie\all_data\, plus outputs\ scripts\ archive_en\ dans
REM       chaque dossier-jour ;
REM    2. copie TOUTES les donnees A PLAT dans all_data\ (aucun sous-dossier) ;
REM    3. copie les 3 .pptx de chaque journee, renommes slides_JXX_fr / _en /
REM       _fr_en, dans le dossier de la journee ;
REM    4. copie les scripts _en.R du materiel source dans archive_en\ ;
REM    5. affiche un recapitulatif chiffre, puis pause.
REM
REM  ETAPE SUIVANTE, OBLIGATOIRE
REM    Ce script ne remplit plus les datasets\ des journees. Apres l'avoir
REM    lance, executer depuis la racine du projet :
REM        source("outils/distribuer_donnees.R")
REM    qui repartit all_data\ vers les onze journees.
REM
REM  CE QU'IL NE FAIT PAS
REM    - il ne supprime rien, ne renomme rien sur place, n'ecrase que par une
REM      copie identique : il est IDEMPOTENT, relancable sans degat ;
REM    - il ne decompresse rien : les .zip GHS-POP / GHS-BUILT sont copies tels
REM      quels, ce sont les .qmd des journees qui les ouvrent par unzip().
REM
REM  POURQUOI TOUT A PLAT DANS datasets\
REM    Regle 6.2 du referentiel : les .qmd portent des litteraux
REM    "datasets/<fichier>" SANS sous-dossier, et outils\distribuer_donnees.R
REM    les detecte par expression reguliere. Un fichier range dans
REM    datasets\GHS-POP\ ne serait ni trouve par le .qmd, ni vu par le script
REM    de distribution.
REM
REM  ATTENTION AUX GUILLEMETS : plusieurs chemins contiennent des espaces
REM  ("MES BUSINESS", "Open Buildings"). Tous les chemins de ce script sont
REM  entre guillemets, ne pas les retirer.
REM =============================================================================

REM --- Chemins ----------------------------------------------------------------
REM RACINE est deduite de l'emplacement de ce script (outils\ -> racine projet).
set "RACINE=%~dp0.."
set "SRC=C:\Users\PROLOG\OneDrive\MES BUSINESS\materiel-atelier-r-spatial-iford-2026-j08-j10"

set "J08=%RACINE%\pedagogie\J08_population_haute_resolution"
set "J09=%RACINE%\pedagogie\J09_teledetection"
set "J10=%RACINE%\pedagogie\J10_politiques_publiques"

REM LES DONNEES VONT DANS all_data, PAS DANS LES datasets\ DES JOURNEES.
REM Deposer les donnees directement dans le datasets\ de chaque journee
REM multiplie les exemplaires. L'architecture retenue est en trois temps :
REM   1. ce script depose TOUTES les donnees dans pedagogie\all_data ;
REM   2. outils\distribuer_donnees.R les repartit ensuite dans les
REM      datasets\ des onze journees, en lisant les litteraux
REM      "datasets/<fichier>" des .qmd ;
REM   3. les datasets\ ne sont plus versionnes : ils sont reconstruits.
REM Un seul exemplaire de chaque fichier existe donc dans Git, au lieu de
REM sept pour DS.geojson et de trois pour gadm41_CMR.gpkg.
REM Les .pptx et les scripts _en.R continuent, eux, d'aller dans le
REM dossier de leur journee : ce ne sont pas des donnees.
set "ALLDATA=%RACINE%\pedagogie\all_data"

set "S08=%SRC%\Tools_day_8\jour08_"
set "S09=%SRC%\Tools_day_9"
set "S10=%SRC%\Tools_day_10_"

REM --- Compteurs --------------------------------------------------------------
set /a COPIES=0
set /a MANQUE=0
set /a ECHEC=0

echo.
echo =====================================================================
echo  Installation du materiel J08 / J09 / J10
echo =====================================================================
echo  Source      : %SRC%
echo  Destination : %RACINE%\pedagogie
echo.

if not exist "%SRC%" (
  echo [ERREUR] Dossier source introuvable :
  echo          %SRC%
  echo Corrigez la variable SRC en tete de ce script, puis relancez.
  echo.
  pause
  exit /b 1
)

REM =============================================================================
REM  1. ARBORESCENCE
REM     Quatre sous-dossiers par journee. archive_en\ recoit les scripts _en.R
REM     du materiel source : ils sont conserves pour reference multilingue mais
REM     NE SONT PAS MAINTENUS (ils ne sont pas derives du .qmd, regle 1.5).
REM =============================================================================
echo --- 1. Creation de l'arborescence ------------------------------------
if not exist "%ALLDATA%" mkdir "%ALLDATA%"
echo   OK  all_data  ^(magasin central : destination de toutes les donnees^)

for %%D in ("%J08%" "%J09%" "%J10%") do (
  if not exist "%%~D"             mkdir "%%~D"
  REM datasets\ est cree vide : c'est distribuer_donnees.R qui le remplit.
  if not exist "%%~D\datasets"    mkdir "%%~D\datasets"
  if not exist "%%~D\outputs"     mkdir "%%~D\outputs"
  if not exist "%%~D\scripts"     mkdir "%%~D\scripts"
  if not exist "%%~D\archive_en"  mkdir "%%~D\archive_en"
  echo   OK  %%~nxD  ^(datasets vide, outputs, scripts, archive_en^)
)
echo.

REM =============================================================================
REM  2. DONNEES J08 -- population haute resolution
REM =============================================================================
echo --- 2. Donnees J08 ---------------------------------------------------

REM Effectifs administratifs COD-PS 2025 par region (pyramide des ages F/M/T).
call :copier "%S08%\data\cmr_admpop_adm1_2025.csv" "%ALLDATA%"

REM Limites GADM multicouches ADM0..ADM3. Le meme fichier sert aux 3 journees :
REM il est copie 3 fois, une par dossier-jour, car une journee est un dossier
REM autonome (regle 1.4) -- la duplication est voulue, pas un oubli.
call :copier "%S08%\data\gadm41_CMR.gpkg" "%ALLDATA%"

REM Grilles WorldPop 100 m, trois millesimes : 2015 (retrospectif),
REM 2025 (reference), 2030 (projection).
call :copier "%S08%\data\cmr_pop_2015_CN_100m_R2025A_v1.tif" "%ALLDATA%"
call :copier "%S08%\data\cmr_pop_2025_CN_100m_R2025A_v1.tif" "%ALLDATA%"
call :copier "%S08%\data\cmr_pop_2030_CN_100m_R2025A_v1.tif" "%ALLDATA%"

REM Les 7 tuiles GHS-POP E2025, A PLAT (module mosaique : unzip -> sprc ->
REM mosaic -> project). Le .qmd les liste par
REM list.files("datasets", pattern = "^GHS_POP_E2025.*\.zip$").
set /a N=0
for %%F in ("%S08%\data\GHS-POP\GHS_POP_E2025*.zip") do (
  set /a N+=1
  call :copier "%%~fF" "%ALLDATA%"
)
echo   -^> !N! tuile^(s^) GHS-POP .zip traitee^(s^)  ^(7 attendues^)
echo.

REM =============================================================================
REM  3. DONNEES J09 -- teledetection et inondations
REM =============================================================================
echo --- 3. Donnees J09 ---------------------------------------------------

call :copier "%S09%\data\gadm41_CMR.gpkg" "%ALLDATA%"

REM WorldPop 2024 : sert a la validation croisee du module 7
REM ^(batiments x 5 contre raster de population^).
call :copier "%S09%\data\cmr_pop_2024_CN_100m_R2025A_v1.tif" "%ALLDATA%"

REM Les 15 tuiles GHS-BUILT, A PLAT : 7 en E2015 et 8 en E2025, tuiles
REM R7_C19 a R9_C21. Les deux millesimes sont necessaires : la journee mesure
REM le GAIN de bati entre 2015 et 2025.
REM
REM LE LOT EST ASYMETRIQUE, ET C'EST VERIFIE SUR DISQUE : la tuile
REM GHS_BUILT_S_E2015_..._R7_C19.zip N'EXISTE PAS dans le materiel source,
REM alors que sa jumelle E2025 existe. Sur l'emprise de cette tuile, le
REM bati 2015 vaut NA : exact_extract(..., "sum") traite NA comme absent,
REM donc le "gain 2015 -> 2025" y devient egal a la TOTALITE du bati 2025.
REM Aucune erreur n'est levee. Le .qmd du J09 detecte l'asymetrie par
REM setdiff() sur les codes de tuiles et restreint les deux millesimes a
REM l'intersection de leurs emprises. ATTENDRE 15, PAS 16.
set /a N=0
for %%F in ("%S09%\data\GHS-BUILT\GHS_BUILT_S_E2015*.zip") do (
  set /a N+=1
  call :copier "%%~fF" "%ALLDATA%"
)
for %%F in ("%S09%\data\GHS-BUILT\GHS_BUILT_S_E2025*.zip") do (
  set /a N+=1
  call :copier "%%~fF" "%ALLDATA%"
)
echo   -^> !N! tuile^(s^) GHS-BUILT .zip traitee^(s^)  ^(15 attendues : 7 en 2015, 8 en 2025^)

REM Google Open Buildings, emprise Yagoua. ATTENTION : le dossier source
REM s'appelle "Open Buildings" AVEC UN ESPACE -- guillemets obligatoires.
REM L'espace disparait a la copie puisque le fichier arrive a plat.
call :copier "%S09%\data\Open Buildings\open_buildings_yagoua.gpkg" "%ALLDATA%"

REM Routes OSM de l'AOI01, repli local du telechargement Overpass.
call :copier "%S09%\data\OSM\routes_aoi01_yagoua.gpkg" "%ALLDATA%"

REM --- Shapefiles Copernicus EMS EMSR772, APLATIS ET RENOMMES ----------------
REM Le nom source porte le produit et la version ^(..._DEL_PRODUCT_..._v1^) :
REM illisible dans un .qmd et fragile ^(la version change^). On copie sous un
REM nom court et stable : EMSR772_AOI0N_areaOfInterestA / _floodDepthA.
REM
REM UN SHAPEFILE VOYAGE AVEC SON CORTEGE ^(regle 6.4^) : .shp seul est inutile.
REM   .shp = geometries, .shx = index, .dbf = table d'attributs,
REM   .prj = systeme de coordonnees.
REM Pas de .cpg dans la source EMSR772 : normal, il est optionnel ^(encodage
REM du .dbf^) et son absence n'empeche pas sf::st_read^(^) de lire la couche.
REM ATTENTION - LES SUFFIXES DE VERSION NE SONT PAS LES MEMES SELON L'AOI :
REM   AOI01 : areaOfInterestA_v1 mais floodDepthA_**v2**  ^(archive _v2^)
REM   AOI02 : areaOfInterestA_v1 et  floodDepthA_v1
REM   AOI03 : areaOfInterestA_v1 et  floodDepthA_v1
REM C'est precisement pour cela qu'on renomme : le .qmd ne doit jamais porter
REM un numero de version dans un chemin.
set "EMSR=%S09%\data\EMSR772_products"

REM DEUX EMPLACEMENTS POSSIBLES POUR CHAQUE FICHIER. Selon l'outil de
REM decompression, les shapefiles sont soit a plat dans EMSR772_products\, soit
REM dans un sous-dossier EMSR772_AOI0N_DEL_PRODUCT_vX\ -- et actuellement aux
REM DEUX endroits, l'extraction ayant ete faite deux fois. Ne dependre d'aucun
REM des deux : :copier_sous_alt essaie le plat, puis le sous-dossier, et ne
REM signale ABSENT que si les deux manquent.
REM Noter que le sous-dossier de l'AOI01 est en _v2, ceux des AOI02/03 en _v1.

REM Appels volontairement ecrits sur UNE SEULE LIGNE : la continuation par ^
REM a l'interieur d'un bloc for^(^) est fragile en batch et se combine mal avec
REM les %%E et les guillemets. Lignes longues, mais surement interpretees.

REM AOI01 -- la zone reellement etudiee par les modules 5 a 8.
set "SUB01=%EMSR%\EMSR772_AOI01_DEL_PRODUCT_v2"
for %%E in (shp shx dbf prj) do (
  call :copier_sous_alt "%EMSR%\EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.%%E" "%SUB01%\EMSR772_AOI01_DEL_PRODUCT_areaOfInterestA_v1.%%E" "%ALLDATA%\EMSR772_AOI01_areaOfInterestA.%%E"
  call :copier_sous_alt "%EMSR%\EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.%%E" "%SUB01%\EMSR772_AOI01_DEL_PRODUCT_floodDepthA_v2.%%E" "%ALLDATA%\EMSR772_AOI01_floodDepthA.%%E"
)

REM AOI02 et AOI03 -- generalisation de la fonction analyser_inondation^(^).
for %%A in (02 03) do (
  for %%E in (shp shx dbf prj) do (
    call :copier_sous_alt "%EMSR%\EMSR772_AOI%%A_DEL_PRODUCT_areaOfInterestA_v1.%%E" "%EMSR%\EMSR772_AOI%%A_DEL_PRODUCT_v1\EMSR772_AOI%%A_DEL_PRODUCT_areaOfInterestA_v1.%%E" "%ALLDATA%\EMSR772_AOI%%A_areaOfInterestA.%%E"
    call :copier_sous_alt "%EMSR%\EMSR772_AOI%%A_DEL_PRODUCT_floodDepthA_v1.%%E" "%EMSR%\EMSR772_AOI%%A_DEL_PRODUCT_v1\EMSR772_AOI%%A_DEL_PRODUCT_floodDepthA_v1.%%E" "%ALLDATA%\EMSR772_AOI%%A_floodDepthA.%%E"
  )
)
echo.

REM =============================================================================
REM  4. DONNEES J10 -- politiques publiques
REM     Toutes depuis Tools_day_10_\jour_09_shared\data\ ^(et JAMAIS depuis
REM     jour_10_shared\jour_10_shared\, cf. exclusions au point 7^).
REM =============================================================================
echo --- 4. Donnees J10 ---------------------------------------------------

REM Partie I : conflits armes ACLED, Cameroun, 31 colonnes format API.
call :copier "%S10%\jour_09_shared\data\acled_cameroon_export.csv" "%ALLDATA%"
call :copier "%S10%\jour_09_shared\data\gadm41_CMR.gpkg"           "%ALLDATA%"

REM Partie II : reanalyse climatique ERA5, temperature 2 m mensuelle, en Kelvin.
call :copier "%S10%\jour_09_shared\data\era5_t2m_mensuel_cameroun.nc" "%ALLDATA%"

REM Partie III : estimation en petits domaines, Benin ^(EHCVM 2018-2019^).
call :copier "%S10%\jour_09_shared\data\ehcvm2018_benin_menages.csv"   "%ALLDATA%"
call :copier "%S10%\jour_09_shared\data\gadm_ben_communes.gpkg"        "%ALLDATA%"
call :copier "%S10%\jour_09_shared\data\benin_grille_3km.gpkg"         "%ALLDATA%"
call :copier "%S10%\jour_09_shared\data\benin_covariables_admin2.csv"  "%ALLDATA%"
call :copier "%S10%\jour_09_shared\data\benin_covariables_grille.csv"  "%ALLDATA%"

REM Module 10 ^(accessibilite, conserve de l'ancien materiel^) : la couche des
REM 58 departements est disponible dans le lot J08, avec son cortege complet.
REM Elle est copiee ici pour que le module puisse repasser en eval: true des que
REM DS.geojson sera restaure ^(cf. outils\A_RESTAURER.md^).
call :copier "%S08%\data\gadm41_CMR_shp\gadm41_CMR_2.shp" "%ALLDATA%"
call :copier "%S08%\data\gadm41_CMR_shp\gadm41_CMR_2.shx" "%ALLDATA%"
call :copier "%S08%\data\gadm41_CMR_shp\gadm41_CMR_2.dbf" "%ALLDATA%"
call :copier "%S08%\data\gadm41_CMR_shp\gadm41_CMR_2.prj" "%ALLDATA%"
call :copier "%S08%\data\gadm41_CMR_shp\gadm41_CMR_2.cpg" "%ALLDATA%"
echo.

REM =============================================================================
REM  5. PRESENTATIONS .pptx
REM     Les trois variantes ^(FR, EN, bilingue^) sont conservees pour chaque
REM     journee. Convention de nom unifiee : slides_JXX_fr / _en / _fr_en.
REM     La source J08 dit "_bilingual" la ou J09 et J10 disent "_fr_en" :
REM     on retient "_fr_en" partout.
REM
REM     Les fichiers ~$....pptx sont des VERROUS Office ^(session PowerPoint
REM     ouverte^), pas des presentations. Ils ne sont jamais copies : ce script
REM     copie chaque .pptx par son nom exact, aucun caractere generique ne
REM     peut donc les atteindre.
REM =============================================================================
echo --- 5. Presentations .pptx -------------------------------------------

call :copier_sous "%S08%\jour_07_population_haute_resolution.pptx"           "%J08%\slides_J08_fr.pptx"
call :copier_sous "%S08%\jour_07_population_haute_resolution_en.pptx"        "%J08%\slides_J08_en.pptx"
call :copier_sous "%S08%\jour_07_population_haute_resolution_bilingual.pptx" "%J08%\slides_J08_fr_en.pptx"

call :copier_sous "%S09%\jour_08_teledetection.pptx"       "%J09%\slides_J09_fr.pptx"
call :copier_sous "%S09%\jour_08_teledetection_en.pptx"    "%J09%\slides_J09_en.pptx"
call :copier_sous "%S09%\jour_08_teledetection_fr_en.pptx" "%J09%\slides_J09_fr_en.pptx"

REM J10 : les 3 .pptx existent en TROIS exemplaires identiques ^(racine,
REM jour_09_shared\, jour_10_shared\jour_10_shared\^). On prend ceux de la
REM racine et on ignore les deux autres jeux.
call :copier_sous "%S10%\jour_09_applications_sociales.pptx"       "%J10%\slides_J10_fr.pptx"
call :copier_sous "%S10%\jour_09_applications_sociales_en.pptx"    "%J10%\slides_J10_en.pptx"
call :copier_sous "%S10%\jour_09_applications_sociales_fr_en.pptx" "%J10%\slides_J10_fr_en.pptx"
echo.

REM =============================================================================
REM  6. SCRIPTS _en.R -> archive_en\
REM     Copies SANS renommage, tels quels. Ce sont les scripts anglais du
REM     materiel source : ils servent de reference de traduction, mais ils ne
REM     sont pas derives du .qmd de la journee ^(regle 1.5^) et ne seront donc
REM     pas maintenus. C'est la raison du nom "archive".
REM =============================================================================
echo --- 6. Scripts _en.R vers archive_en\ --------------------------------

REM J08 : la version de scripts_etudiants\ ^(celle de la racine Tools_day_8\
REM est un doublon exact, cf. point 7^).
call :copier "%S08%\scripts_etudiants\jour_07_etudiants_population_haute_resolution_en.R" "%J08%\archive_en"

REM J09 : 4 scripts formateurs + 2 scripts etudiants.
call :copier "%S09%\Correction_Workshop_\jour_08_formateur_teledetection_en.R"          "%J09%\archive_en"
call :copier "%S09%\Correction_Workshop_\jour_08_formateur_inondations_en.R"            "%J09%\archive_en"
call :copier "%S09%\Correction_Workshop_\jour_08_formateur_prepare_open_buildings_en.R" "%J09%\archive_en"
call :copier "%S09%\Correction_Workshop_\jour_08_formateur_prepare_osm_routes_en.R"     "%J09%\archive_en"
call :copier "%S09%\scripts_etudiants\jour_08_etudiants_teledetection_en.R"             "%J09%\archive_en"
call :copier "%S09%\scripts_etudiants\jour_08_etudiants_inondations_en.R"               "%J09%\archive_en"

REM J10 : seule la trame etudiante existe en anglais ^(le CORRIGE complet n'a
REM pas d'equivalent EN^).
call :copier "%S10%\jour_09_shared\scripts_etudiants\jour_09_etudiants_applications_sociales_en.R" "%J10%\archive_en"
echo.

REM =============================================================================
REM  7. CE QUI N'EST DELIBEREMENT PAS COPIE
REM     Une raison technique par ligne. Aucun de ces fichiers n'est lu par un
REM     script du materiel : les copier violerait la regle 6.4 ^(une journee ne
REM     garde que ce qu'elle lit^) et gonflerait le dossier-jour pour rien.
REM
REM  - DATA_ECOLE.zip
REM      Contenu inconnu, reference par AUCUN script des trois journees.
REM      A ouvrir et a inventorier avant toute decision.
REM
REM  - gadm41_CMR_shp.zip et le dossier gadm41_CMR_shp\ deja decompresse
REM      Les memes limites GADM que gadm41_CMR.gpkg, mais en 4 shapefiles
REM      separes. Tous les scripts lisent le .gpkg multicouche ^(st_layers^) ;
REM      aucun ne lit ces .shp. Doublon integral.
REM
REM  - GHS_POP_GLOBE_R2023A_input_metadata.xlsx
REM      Metadonnees de production des tuiles GHS-POP. Jamais ouvert par un
REM      script ; GHSL_Data_Package_2023_light.pdf joue deja le role de
REM      documentation.
REM
REM  - ghsl_pop_2025_cmr_100m.tif
REM      C'est la SORTIE du module mosaique du J08, pas une source. Une sortie
REM      n'a rien a faire dans datasets\ : elle doit etre reproduite par le
REM      participant et ecrite dans outputs\. La livrer d'avance masquerait un
REM      echec de la chaine unzip / mosaic / project.
REM
REM  - benin_covariables_brutes_gee\ ^(12 CSV : ntl, population, ndvi, precip,
REM    buildings, rivers, distancecities, landclass, pollution co/hcho/no2/
REM    o3/so2^)
REM      Exports Google Earth Engine bruts. Le script utilise exclusivement
REM      les deux fichiers deja agreges ^(benin_covariables_admin2.csv et
REM      benin_covariables_grille.csv^) ; le materiel source les qualifie
REM      lui-meme de "non utilisees en exemple".
REM
REM  - jour_10_shared\jour_10_shared\ EN ENTIER ^(8 donnees + 3 pptx^)
REM      Dossier integralement redondant avec jour_09_shared\ : memes fichiers,
REM      memes noms. Garder les deux exposerait a copier un jour l'un, un jour
REM      l'autre, sans savoir lequel fait foi.
REM
REM  - jour_08_formateur_prepare_osm_routes ^(1^).R
REM      Copie Windows de jour_08_formateur_prepare_osm_routes.R ^(memes lignes
REM      17, 31, 36^). Doublon exact.
REM
REM  - Les .tif GHS deja decompresses ^(GHS-POP\ et GHS-BUILT\^)
REM      Les .zip sont copies ; les .tif correspondants doubleraient le poids
REM      pour la meme donnee. Surtout, l'exercice de la journee EST la chaine
REM      unzip -> sprc -> mosaic : livrer les .tif deja extraits la viderait
REM      de son objet.
REM
REM  - Les deux .R de la racine Tools_day_8\
REM      Doublons exacts de jour08_\scripts_etudiants\ ^(memes numeros de ligne
REM      pour les memes instructions : 33, 34, 505, 865, 869^).
REM
REM  - EMSR772 : imageFootprintA, observedEventA, source, summaryTable.xlsx,
REM    Maps\*.pdf, .json .lyr .sld .xml, floodDepthA .tif
REM      Aucun n'est lu par le module inondations, qui n'ouvre que
REM      areaOfInterestA et floodDepthA en vecteur. Les .sld / .lyr sont des
REM      styles ArcGIS/QGIS, les .json des doublons du .shp.
REM =============================================================================

REM =============================================================================
REM  8. RECAPITULATIF
REM =============================================================================
echo.
echo =====================================================================
echo  RECAPITULATIF
echo =====================================================================
echo   Fichiers copies              : !COPIES!
echo   Fichiers source INTROUVABLES : !MANQUE!
echo   Copies en ECHEC              : !ECHEC!
echo.
echo   Attendu si tout est present  : 85 fichiers
echo     J08 : 5 donnees + 7 zip GHS-POP + 3 pptx + 1 script_en   = 16
echo     J09 : 4 donnees + 15 zip GHS-BUILT + 24 fichiers EMSR772
echo           + 3 pptx + 6 scripts_en                            = 52
echo     J10 : 8 donnees + 5 gadm41_CMR_2 + 3 pptx + 1 script_en  = 17
echo   ^(24 fichiers EMSR772 = AOI01, AOI02, AOI03 : 2 couches x 4 annexes^)
echo   Tout ecart se lit sur les lignes [ABSENT] et [ECHEC] ci-dessus.
echo.

if !MANQUE! GTR 0 (
  echo   [!] Des fichiers source sont introuvables. Les lignes [ABSENT]
  echo       ci-dessus donnent leur nom. Verifiez la variable SRC en tete
  echo       de ce script, ou l'integrite du dossier source.
  echo.
)
if !ECHEC! GTR 0 (
  echo   [!] Des copies ont echoue ^(fichier verrouille, droits, disque^).
  echo       Fermez PowerPoint / RStudio et relancez ce script.
  echo.
)

echo   DEPENDANCE EXTERNE A CONNAITRE :
echo     DS.geojson ne fait pas partie de ce lot. Le module 10 du J10
echo     ^(accessibilite^) reste en eval: false tant qu'il manque.
echo     Le reste du J10 rend normalement.
echo.
echo   Voir aussi outils\A_RESTAURER.md ^(sources lourdes J01-J07 a remettre^)
echo   et outils\menage_poste.md ^(commandes del / ren a passer a la main^).
echo =====================================================================
echo.
pause
endlocal & exit /b 0

REM =============================================================================
REM  SOUS-ROUTINES
REM =============================================================================

:copier
REM %~1 = fichier source complet, %~2 = dossier destination
REM Copie sans renommage. Compte separement absence de source et echec de copie
REM -- un echec silencieux de copie est exactement ce que les regles interdisent.
if not exist "%~1" (
  set /a MANQUE+=1
  echo   [ABSENT] %~nx1
  goto :eof
)
copy /Y "%~1" "%~2\" >nul
if errorlevel 1 (
  set /a ECHEC+=1
  echo   [ECHEC ] %~nx1
) else (
  set /a COPIES+=1
  echo   [ok]     %~nx1
)
goto :eof

:copier_sous_alt
REM %~1 = source PRIORITAIRE, %~2 = source de REPLI, %~3 = destination COMPLETE.
REM Sert aux produits Copernicus EMS : selon la facon dont l'archive a ete
REM decompressee, les shapefiles se trouvent soit a plat dans EMSR772_products\,
REM soit dans un sous-dossier EMSR772_AOI0N_DEL_PRODUCT_vX\ -- et parfois aux
REM DEUX endroits. On essaie la version a plat, puis le sous-dossier, et on ne
REM compte un ABSENT que si aucune des deux n'existe.
if exist "%~1" (
  call :copier_sous "%~1" "%~3"
  goto :eof
)
if exist "%~2" (
  call :copier_sous "%~2" "%~3"
  goto :eof
)
set /a MANQUE+=1
echo   [ABSENT] %~nx1  ^(ni a plat ni en sous-dossier^)
goto :eof

:copier_sous
REM %~1 = fichier source complet, %~2 = chemin destination COMPLET (renommage)
if not exist "%~1" (
  set /a MANQUE+=1
  echo   [ABSENT] %~nx1
  goto :eof
)
copy /Y "%~1" "%~2" >nul
if errorlevel 1 (
  set /a ECHEC+=1
  echo   [ECHEC ] %~nx1  -^>  %~nx2
) else (
  set /a COPIES+=1
  echo   [ok]     %~nx1  -^>  %~nx2
)
goto :eof
