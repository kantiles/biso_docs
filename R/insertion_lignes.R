#-------------------------------------------------------#
# Utilitaire pour insérer les codes isd et les libellés #
#-------------------------------------------------------#

library(dplyr)
library(stringr)
library(readr)
library(purrr)

# Import ------

# Table de correspondance

df_correspondance <- readxl::read_xlsx(
  "~/kDrive/Common documents/Drees/Livraison BISOK Mai 2026/documentation_biso_v27_05.xlsx"
) |>
  select(id_indicateur, isd, lib_indicateur)

# Lecture et fusion des qmd

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

lignes <- c(
  yaml,
  map(
    c(
      "finess.md",
      "as.md",
      "rp.md",
      "autre.md"
    ),
    read_lines
  ) |>
    flatten_chr()
)

# Insertion d'éléments ----

# On ajoute les codes ISD et les libellés des indicateurs
resultat <- map(
  seq_along(lignes),
  function(i) {
    ligne <- lignes[i]

    # Détection du bloc ID_indicateur
    if (str_detect(ligne, "^## \\*\\*ID_indicateur :\\*\\*")) {
      # Extraction des ids
      ids <- ligne |>
        str_remove("^## \\*\\*ID_indicateur :\\*\\*\\s*") |>
        str_split(",\\s*") |>
        unlist()

      # Recherche des codes ISD
      codes_isd <- df_correspondance |>
        filter(id_indicateur %in% ids) |>
        distinct(isd) |>
        pull(isd) |>
        na.omit()

      # Recherche des libellés
      lib_indicateurs <- df_correspondance |>
        filter(id_indicateur %in% ids) |>
        distinct(lib_indicateur) |>
        pull(lib_indicateur) |>
        na.omit()

      # Lignes à ajouter
      ligne_isd <- paste0(
        "**Code ISD :** ",
        paste(codes_isd, collapse = ", ")
      )

      if (length(codes_isd) == 0) {
        c(
          ligne,
          "",
          "**Libellé de l'indicateur :**",
          "",
          paste0("- ", lib_indicateurs)
        )
      } else {
        c(
          ligne,
          "",
          "**Libellé :**",
          "",
          paste0("- ", lib_indicateurs),
          "",
          ligne_isd
        )
      }
    } else {
      ligne
    }
  }
) |>
  unlist()

# Écriture du nouveau qmd et production du pdf -----

write_lines(
  resultat,
  "documentation_biso.qmd"
)

quarto::quarto_render("documentation_biso.qmd")
