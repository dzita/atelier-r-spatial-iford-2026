# =====================================================================
# theme_iford.R
# Atelier IFORD x GDSG 2026 - Theme graphique commun (ggplot2 + tmap)
# Auteur : Ramesesse Dzita
# -----
# Objectif : garantir la coherence visuelle des cartes et graphiques
# produits durant les 10 jours et publiables pour l'IFORD.
# =====================================================================

suppressPackageStartupMessages({
  library(ggplot2)
})

# Palette inspiree des couleurs institutionnelles IFORD (bleu, ocre)
IFORD_PALETTE <- list(
  primary   = "#0F4C81",   # bleu IFORD
  secondary = "#C9A227",   # ocre
  neutral   = "#4A4A4A",
  light     = "#F2F2F2",
  accent    = "#A8201A"    # rouge sombre (alerte, anomalie)
)

theme_iford <- function(base_size = 12, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      plot.title       = element_text(face = "bold", size = base_size + 4,
                                      color = IFORD_PALETTE$primary),
      plot.subtitle    = element_text(size = base_size, color = IFORD_PALETTE$neutral),
      plot.caption     = element_text(size = base_size - 2, color = IFORD_PALETTE$neutral,
                                      hjust = 0, face = "italic"),
      legend.position  = "right",
      legend.title     = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      axis.text        = element_text(color = IFORD_PALETTE$neutral),
      strip.background = element_rect(fill = IFORD_PALETTE$light, color = NA),
      strip.text       = element_text(face = "bold")
    )
}

# Mention de source standardisee a inserer dans plot.caption
iford_caption <- function(source = "Source : a renseigner") {
  paste0(source,
         " · Atelier IFORD x GDSG, Yaoundé 27 juillet - 7 aout 2026")
}

# Options tmap recommandees pour publication
setup_tmap_iford <- function() {
  if (!requireNamespace("tmap", quietly = TRUE)) {
    stop("Package tmap requis : install.packages('tmap')")
  }
  tmap::tmap_options(
    legend.title.fontface  = "bold",
    legend.position        = tmap::tm_pos_out("right", "center"),
    frame                  = FALSE
  )
}
