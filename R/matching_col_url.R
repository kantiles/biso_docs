#----------------------------------------------------------#
# Association des indicateurs à l'ancre de leur section     #
# dans la documentation HTML (doc.parquet)                  #
#----------------------------------------------------------#

# Pour chaque id_indicateur, on retrouve l'identifiant ("ancre") de la section
# "##" sous laquelle il est documenté. Cet identifiant est soit explicite
# (`{#ancre}` dans le Markdown), soit généré automatiquement par pandoc à
# partir du titre (mêmes règles que la page html finale) : on demande donc à
# pandoc lui-même de le calculer, plutôt que de réimplémenter son algorithme.

library(tidyverse)

url_base <- "https://kantiles.github.io/biso_docs/#"

# Fichiers Markdown sources, dans le même ordre que assemblage_documentation.R
fichiers_md <- c("finess.md", "as.md", "rp.md", "autre.md", "meta.md")

# Concaténation des sources (l'ordre des titres importe pour le calcul des
# identifiants pandoc en cas de titres en double)
lignes <- fichiers_md |>
  map(read_lines) |>
  flatten_chr()

fichier_concat <- tempfile(fileext = ".md")
write_lines(lignes, fichier_concat)

# Extraction des identifiants de titres (niveaux 1 et 2) via pandoc ----

filtre_lua <- tempfile(fileext = ".lua")
fichier_headers <- tempfile(fileext = ".tsv")

write_lines(
  c(
    sprintf('local out = io.open("%s", "w")', fichier_headers),
    "function Header(el)",
    "  if el.level == 1 or el.level == 2 then",
    '    out:write(el.identifier .. "\\n")',
    "  end",
    "  return el",
    "end",
    "function Pandoc(doc)",
    "  out:close()",
    "  return doc",
    "end"
  ),
  filtre_lua
)

system2(
  "pandoc",
  c(
    shQuote(fichier_concat),
    "--from",
    "markdown",
    "--to",
    "html5",
    "--lua-filter",
    shQuote(filtre_lua),
    "-o",
    tempfile(fileext = ".html")
  )
)

identifiants <- read_lines(fichier_headers)

# Repérage, dans les sources, des titres (mêmes lignes, même ordre) et des
# lignes d'ID_indicateur, pour associer chaque indicateur à l'identifiant du
# titre sous lequel il apparaît
idx_titres <- str_which(lignes, "^#{1,2}\\s")
idx_ids <- str_which(lignes, "\\*\\*ID_indicateur :\\*\\*")

stopifnot(length(idx_titres) == length(identifiants))

df_correspondance_ancre <- map_dfr(
  idx_ids,
  \(idx_id) {
    ancre <- identifiants[max(which(idx_titres < idx_id))]

    ids <- lignes[idx_id] |>
      str_remove("^\\*\\*ID_indicateur :\\*\\*\\s*") |>
      str_split(",\\s*") |>
      unlist() |>
      str_trim()

    tibble(id_indicateur = ids, ancre = ancre)
  }
) |>
  distinct(id_indicateur, .keep_all = TRUE) |>
  mutate(url_doc = paste0(url_base, ancre)) |>
  select(id_indicateur, url_doc)

# Mise à jour de doc.parquet ----

df_biso_doc <-
  gristapi::grist_api$new(
    server = 'https://grist.numerique.gouv.fr',
    api_key = Sys.getenv("KEY_GRIST"),
    doc_id = "vTbLn84jirY4"
  ) |>
  gristapi::fetch_table("Documentation_biso") |>
  filter(!is.na(lots)) |>
  select(-id)

df_doc <- df_biso_doc |>
  select(id_indicateur) |>
  left_join(df_correspondance_ancre, by = "id_indicateur")

writexl::write_xlsx(df_doc, "doc_url.xlsx")
