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

# Ajout de liens ----

# On ajoute les codes ISD et les libellés des indicateurs
resultat_liens <- str_replace_all(
  resultat,

  c(
    "ID_indicateur" = "ID indicateur",
    "Finess" = "[Finess](#finess)",
    "EHPA" = "[EHPA](#enquête-auprès-des-établissements-dhébergement-pour-personnes-âgées)",
    "FiLoSoFi" = "[FiLoSoFi](#insee-dispositif-fichier-localisé-social-et-fiscal-filosofi)",
    "RSA" = "[RSA](#rsa)",
    "APA" = "[APA](#apa)",
    "Âge" = "[Âge](#age)",
    "âge" = "[âge](#age)",
    "Juge des enfants " = "[Juge des enfants](#juge-des-enfants)",
    "juge des enfants " = "[juge des enfants](#juge-des-enfants)",
    "Catégories de demandes d'emploi" = "[Catégories de demandes d'emploi](#catégories-des-inscrits-à-france-travail)",
    "Espérance de vie" = "[Espérance de vie](#espérance-de-vie)",
    "espérance de vie" = "[espérance de vie](#espérance-de-vie)",
    "Revenu disponible" = "[Revenu disponible](#revenu-disponible)",
    "revenu disponible" = "[revenu disponible](#revenu-disponible)",
    "Unité de consommation" = "[Unité de consommation](#unité-de-consommation)",
    "unité de consommation" = "[unité de consommation](#unité-de-consommation)",
    "Unité de Consommation" = "[Unité de Consommation](#unité-de-consommation)",
    "Intensité de la pauvreté" = "[Intensité de la pauvreté](#intensité-de-la-pauvreté)",
    "intensité de la pauvreté" = "[intensité de la pauvreté](#intensité-de-la-pauvreté)",
    "Niveau de vie" = "[Niveau de vie](#niveau-de-vie)",
    "niveau de vie" = "[niveau de vie](#niveau-de-vie)",
    "Nombre de personnes du ménage fiscal" = "[Nombre de personnes du ménage fiscal](#nombre-de-personnes-du-ménage-fiscal)",
    "nombre de personnes du ménage fiscal" = "[nombre de personnes du ménage fiscal](#nombre-de-personnes-du-ménage-fiscal)",
    "Rapports interdéciles" = "[Rapports interdéciles](#rapports-interdéciles)",
    "rapports interdéciles" = "[rapports interdéciles](#rapports-interdéciles)",
    "Pauvreté" = "[Pauvreté](#pauvreté)",
    "pauvreté" = "[pauvreté](#pauvreté)",
    "Déciles" = "[Déciles](#déciles)",
    "déciles" = "[déciles](#déciles)",
    "Taux de chômage localisés" = "[Taux de chômage localisés](https://www.insee.fr/fr/metadonnees/source/serie/s2107)"
  )
)


# Écriture du nouveau qmd et production du pdf -----

write_lines(
  resultat_liens,
  "documentation_biso.qmd"
)

quarto::quarto_render("documentation_biso.qmd")
