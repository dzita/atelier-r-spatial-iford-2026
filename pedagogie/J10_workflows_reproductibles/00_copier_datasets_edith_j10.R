# 00_copier_datasets_edith_j10.R
# -------------------------------------------------------------------------
# Atelier IFORD x GDSG - J10 (Flux reproductibles)
#
# Objet : Copier les 3 datasets pedagogiques d'Edith Darin depuis le repo
#         formateur 'jour_10_flux_reproductibles_projets' vers
#         pedagogie/datasets/cameroun/jour_10/ afin que le helper
#         fetch_indicateurs_regions_demo() les retrouve.
#
# A executer UNE SEULE FOIS sur le poste formateur, puis commit.
#
# Datasets copies :
#   - regions_indicateurs_demo.gpkg     (GeoPackage, 10 features)
#   - regions_indicateurs_demo_shp/     (Shapefile equivalent)
#   - projet_final_indicateurs_demo.csv (variante tabulaire)
#
# Conception : Edith Darin (GDSG/IFORD)
# Integration convention IFORD : Ramesesse Dzita
# -------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(fs)
  library(rprojroot)
})

projet_root <- rprojroot::find_root(rprojroot::has_file("README.md"))

# Source : repo formateur d'Edith (positionnement standard sur poste GDSG)
# A adapter si le repo Edith est ailleurs sur la machine.
candidats_source <- c(
  "C:/Dev/GitHub/jour_10_flux_reproductibles_projets/data",
  file.path(Sys.getenv("USERPROFILE"),
            "Dev/GitHub/jour_10_flux_reproductibles_projets/data"),
  file.path(Sys.getenv("HOME"),
            "Dev/GitHub/jour_10_flux_reproductibles_projets/data")
)
src_dir <- NULL
for (c in candidats_source) {
  if (dir.exists(c)) { src_dir <- c; break }
}
if (is.null(src_dir)) {
  stop("Repo formateur Edith introuvable. Cloner d'abord :\n",
       "  git clone <url-edith> ~/Dev/GitHub/jour_10_flux_reproductibles_projets\n",
       "ou modifier 'candidats_source' dans ce script.")
}

# Destination : pedagogie/datasets/cameroun/jour_10/
dst_dir <- file.path(projet_root, "pedagogie", "datasets", "cameroun",
                     "jour_10")
fs::dir_create(dst_dir, recurse = TRUE)

message("Copie depuis : ", src_dir)
message("Vers         : ", dst_dir)

# 1. GeoPackage
fs::file_copy(
  file.path(src_dir, "regions_indicateurs_demo.gpkg"),
  file.path(dst_dir, "regions_indicateurs_demo.gpkg"),
  overwrite = TRUE
)
message("  [OK] regions_indicateurs_demo.gpkg")

# 2. Dossier shapefile (5 fichiers : shp + dbf + shx + prj + cpg)
shp_dir_src <- file.path(src_dir, "regions_indicateurs_demo_shp")
shp_dir_dst <- file.path(dst_dir, "regions_indicateurs_demo_shp")
fs::dir_create(shp_dir_dst)
fs::file_copy(
  fs::dir_ls(shp_dir_src),
  shp_dir_dst,
  overwrite = TRUE
)
message("  [OK] regions_indicateurs_demo_shp/ (",
        length(fs::dir_ls(shp_dir_dst)), " fichiers)")

# 3. CSV
fs::file_copy(
  file.path(src_dir, "projet_final_indicateurs_demo.csv"),
  file.path(dst_dir, "projet_final_indicateurs_demo.csv"),
  overwrite = TRUE
)
message("  [OK] projet_final_indicateurs_demo.csv")

# 4. Copie additionnelle vers _commons/data/jour_10_extraits/ pour le runtime WebR
#    (le runtime telecharge via download.file un chemin relatif servi par Quarto)
webr_dir <- file.path(projet_root, "pedagogie", "_commons", "data",
                      "jour_10_extraits")
fs::dir_create(webr_dir, recurse = TRUE)
fs::file_copy(
  file.path(dst_dir, "regions_indicateurs_demo.gpkg"),
  file.path(webr_dir, "regions_indicateurs_demo.gpkg"),
  overwrite = TRUE
)
message("  [OK] _commons/data/jour_10_extraits/regions_indicateurs_demo.gpkg ",
        "(pour runtime WebR)")

# Verification
message("\nFichiers presents dans ", dst_dir, " :")
for (f in fs::dir_ls(dst_dir, recurse = TRUE)) {
  taille_ko <- round(fs::file_info(f)$size / 1024, 1)
  message("  ", basename(f), " (", taille_ko, " ko)")
}

message("\nOK. Le helper fetch_indicateurs_regions_demo() peut maintenant ",
        "lire ces fichiers.")
