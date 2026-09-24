# ------------------------------------------------ #
# Import et controle de la documentation sur grist #
# ------------------------------------------------ #

# Import ----

# library(gristapi)
# library(tidyverse)

# api <- grist_api$new(
#   server = 'https://grist.numerique.gouv.fr',
#   api_key = Sys.getenv("KEY_GRIST_DREES"),
#   doc_id = "vTbLn84jirY4"
# )

# df_biso_doc <- fetch_table(api, "Documentation_biso") |>
#   filter(!is.na(Lots))

resp <-
  httr2::request(paste0(
    # Domaine
    "https://grist.numerique.gouv.fr/api/docs/",
    # Identifiant du document
    "vTbLn84jirY4",
    # Nom de la table
    "/download/csv?tableId=Documentation_biso"
  )) |>
  httr2::req_headers(
    Authorization = paste0("Bearer ", Sys.getenv("KEY_GRIST"))
  ) |>
  httr2::req_perform()

df_biso_doc <- readr::read_csv(
  I(rawToChar(httr2::resp_body_raw(resp))),
  show_col_types = FALSE
) |>
  filter(!is.na(Lots))

# Nettoyage de l'environement ----

rm(resp)
