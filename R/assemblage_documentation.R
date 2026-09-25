#-------------------------------------------------------#
# Utilitaire pour insérer les codes isd et les libellés #
#-------------------------------------------------------#

# Produit `resultat_liens` : les lignes Markdown fusionnées et enrichies,
# utilisées par R/insertion_lignes.R (pdf) et R/export_html.R (html).
# Le dossier des données BISO (csv ou parquet) peut être changé via la
# variable d'environnement BISO_DATA_DIR.

library(tidyverse)

# Import ------

# Documentation sur Grist
df_biso_doc <-
  gristapi::grist_api$new(
    server = 'https://grist.numerique.gouv.fr',
    api_key = Sys.getenv("KEY_GRIST"),
    doc_id = "vTbLn84jirY4"
  ) |>
  gristapi::fetch_table("Documentation_biso") |>
  filter(!is.na(lots)) |>
  select(-id)

# Données BISO
df_biso <- map(
  list.files(
    Sys.getenv(
      "BISO_DATA_DIR",
      "../biso/data/format/20_07_26/livraison_huwise"
    ),
    pattern = "\\.(csv|parquet)$",
    full.names = TRUE
  ),
  \(fichier) {
    if (str_ends(fichier, "\\.parquet")) {
      arrow::read_parquet(fichier, col_select = c(id_indicateur, annee))
    } else {
      read_csv(fichier, show_col_types = FALSE)
    }
  }
) |>
  bind_rows()

# Table de correspondance

df_correspondance <- df_biso_doc |>
  select(id_indicateur, isd, panorama, lib_indicateur, source)

# Lecture et fusion des md

lignes <- map(
  c(
    "finess.md",
    "as.md",
    "rp.md",
    "autre.md",
    "meta.md"
  ),
  read_lines
) |>
  flatten_chr()

# Insertion d'éléments ----

# Récupération des années

resume_annees <- function(x) {
  x <- sort(unique(x))

  # Découpe en séquences consécutives
  grp <- cumsum(c(TRUE, diff(x) != 1))

  groupes <- split(x, grp)

  # Éclater les groupes de 2
  groupes <- purrr::map(
    groupes,
    \(y) {
      if (length(y) == 2) {
        as.list(y)
      } else {
        list(y)
      }
    }
  ) |>
    purrr::flatten()

  plages <- purrr::map_chr(groupes, \(y) {
    if (length(y) == 1) {
      as.character(y)
    } else {
      paste0("de ", min(y), " à ", max(y))
    }
  })

  # Assemblage final
  if (length(plages) == 1) {
    plages
  } else if (length(plages) == 2) {
    paste(plages, collapse = " et ")
  } else {
    paste0(
      paste(plages[-length(plages)], collapse = ", "),
      " et ",
      plages[length(plages)]
    )
  }
}

df_annees <-
  df_biso |>
  distinct(id_indicateur, annee) |>
  summarise(
    annees = resume_annees(annee),
    .by = id_indicateur
  )

# On ajoute les codes ISD, les années, les sources, et les libellés des indicateurs
resultat <- map(
  seq_along(lignes),
  function(i) {
    ligne <- lignes[i]

    # Détection du bloc ID_indicateur
    if (str_detect(ligne, "\\*\\*ID_indicateur :\\*\\*")) {
      # Extraction des ids
      ids <- ligne |>
        str_remove("^## ") |>
        str_remove("^\\*\\*ID_indicateur :\\*\\*\\s*") |>
        str_split(",\\s*") |>
        unlist()

      # Filtre sur nos ids
      df_correspondance_filtre <- df_correspondance |>
        filter(id_indicateur %in% ids) |>
        mutate(id_indicateur = factor(id_indicateur, levels = ids)) |>
        arrange(id_indicateur)

      # Recherche des codes ISD
      codes_isd <- df_correspondance_filtre |>
        summarise(
          id_indicateurs = paste(id_indicateur, collapse = ", "),
          .by = isd
        )

      # Recherche des codes panorama
      codes_panorama <- df_correspondance_filtre |>
        summarise(
          id_indicateurs = paste(id_indicateur, collapse = ", "),
          .by = panorama
        )

      # Recherche des libellés
      lib_indicateurs <- df_correspondance_filtre |>
        distinct(lib_indicateur) |>
        pull(lib_indicateur) |>
        na.omit()

      # Recherche des sources
      lib_source <- df_correspondance_filtre |>
        summarise(
          id_indicateurs = paste(id_indicateur, collapse = ", "),
          .by = source
        ) |>
        mutate(
          source = str_replace_all(
            source,
            c(
              # On ajoute les liens aux ancres
              "enquête Aide sociale" = "[enquête Aide sociale](#as)",
              "Finess" = "[Finess](#finess)",
              "LIVIA" = "[LIVIA](#livia)",
              "estimations de population" = "[estimations de population](#estim_pop)",
              "RP" = "[RP](#rp)",
              "Etat civil" = "[Etat-civil](#ec)",
              "FiLoSoFi" = "[FiLoSoFi](#filosofi)",
              "Omphale" = "[Omphale](#omphale)"
            )
          )
        )

      # Recherche des années disponibles
      annees <- df_annees |>
        filter(id_indicateur %in% ids) |>
        summarise(
          id_indicateurs = paste(id_indicateur, collapse = ", "),
          .by = annees
        )

      # On renvoit la ligne suivie de l'ensemble des ajouts
      c(
        ligne,
        "",

        "**Libellés :**",
        "",
        paste0("- ", lib_indicateurs),
        "",
        # ISD
        # Si on a un ISD
        if (!all(is.na(codes_isd$isd))) {
          c(
            # Si on en a un seul : on le met à la suite de **Code ISD :**
            if (nrow(codes_isd) == 1) {
              paste0("**Code ISD :** ", codes_isd |> pull(isd))
            } else {
              # Sinon, on listes les ISD et les indicateurs qui s'y refèrent
              ids_isd <- codes_isd |> filter(!is.na(isd))
              c(
                "**Code ISD :** ",
                "",
                paste0(
                  "- ",
                  ids_isd$isd,
                  " pour ",
                  ids_isd$id_indicateurs
                )
              )
            },
            ""
          )
        },

        # Panorama : même structure
        if (!all(is.na(codes_panorama$panorama))) {
          c(
            if (nrow(codes_panorama) == 1) {
              paste0(
                "**Panorama :** Tableau ",
                codes_panorama |> pull(panorama)
              )
            } else {
              ids_pano <- codes_panorama |> filter(!is.na(panorama))
              c(
                "**Panorama :** ",
                "",
                paste0(
                  "- Tableau ",
                  ids_pano$panorama,
                  " pour ",
                  ids_pano$id_indicateurs
                )
              )
            },
            ""
          )
        },

        # Si on a qu'une seule source : la metre à la suite, sinon faire une liste en remettant les id_indicateurs qui correspondent.
        if (nrow(lib_source) == 1) {
          paste0("**Sources :** ", lib_source |> pull(source))
        } else {
          c(
            "**Sources :** ",
            "",
            paste0(
              "- ",
              lib_source$source,
              " pour ",
              lib_source$id_indicateurs
            )
          )
        },
        "",
        # Si on a qu'une seule date : la metre à la suite, sinon faire une liste en remettant les id_indicateurs qui correspondent.
        if (nrow(annees) == 1) {
          paste0("**Dates :** ", annees |> pull(annees))
        } else {
          c(
            "**Dates :**",
            "",
            paste0("- ", annees$annees, " pour ", annees$id_indicateurs)
          )
        }
      )
    } else {
      ligne
    }
  }
) |>
  unlist()

# Ajout de liens et remplacements ----

resultat_liens <- str_replace_all(
  resultat,
  c(
    "ID_indicateur" = "Identifiants des indicateurs"
  )
)
