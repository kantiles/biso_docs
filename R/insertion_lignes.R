#-------------------------------------------------------#
# Utilitaire pour insérer les codes isd et les libellés #
#-------------------------------------------------------#

# Production de la documentation au format pdf

source("R/assemblage_documentation.R")

yaml <- c(
  "---
  title: \"Documentation BISO\"
  lang: fr
  format: 
   pdf:
     toc: true
     number-sections: false
     colorlinks: true
     fontsize: 12pt
     linestretch: 1.2
     geometry:
      - margin=2.5cm
---",
  ""
)

# Écriture du nouveau qmd et production du pdf -----

write_lines(
  c(yaml, resultat_liens),
  "documentation_biso.qmd"
)

quarto::quarto_render("documentation_biso.qmd")
