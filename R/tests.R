#---------------------------#
# Tests de la documentation #
#---------------------------#

library(tidyverse)
library(glue)
library(httr2)
library(readr)


# Sommaire ---

# Les tests à créer sont :
# Complétude : Tous les indicateurs de BISO sont dans la documentation
# Faux : Tous les indicateurs de la documentation sont dans la doc biso

# Imports ------

# documentation BISO
url <- paste0(
  # Domaine
  "https://kantiles.getgrist.com/api/docs/",
  # Identifiant de la table
  "aWZpGbns47vKeHj3SrAVBy",
  # Nom de la table
  "/download/csv?tableId=Documentation"
)

resp <-
  request(url) |>
  req_headers(
    Authorization = paste0("Bearer ", Sys.getenv("KEY_GRIST"))
  ) |>
  req_perform()

df_biso_doc <- read_csv(I(rawToChar(resp_body_raw(resp)))) |>
  filter(!is.na(Lots))

df_doc <-
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

df_doc_ids <-
  df_doc |>
  tibble::enframe(name = NULL, value = "ligne") |>
  filter(str_detect(ligne, "\\*\\*ID_indicateur :\\*\\*")) |>
  mutate(
    id_indicateur = str_remove(ligne, "^\\#\\# ") |>
      str_remove("^\\*\\*ID_indicateur :\\*\\* ")
  ) |>
  separate_longer_delim(id_indicateur, delim = ", ") |>
  mutate(id_indicateur = str_trim(id_indicateur))

# Complétude -----

df_biso_doc |>
  filter_out(is.na(isd) & is.na(panorama) & is.na(vilas)) |>
  anti_join(df_doc_ids, by = join_by(id_indicateur)) |>
  arrange(Lots, panorama, id_indicateur) |>
  select(Lots, id_indicateur, lib_indicateur, source, vilas, isd, panorama) |>
  print(n = Inf)

# Faux -----

df_doc_ids |>
  anti_join(
    df_biso_doc,
    by = join_by(id_indicateur)
  )

# Doublons -----

df_doc_ids |>
  count(id_indicateur) |>
  filter(n != 1)
