#-----------------------------------------------------#
# Export de la documentation assemblée pour le html #
#-----------------------------------------------------#

# Écrit le Markdown fusionné et enrichi, converti ensuite en une page html
# unique par .github/pandoc/build.sh

source("R/assemblage_documentation.R")

write_lines(
  resultat_liens,
  Sys.getenv("BISO_DOC_MD", "documentation_biso.md")
)
