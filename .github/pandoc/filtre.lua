-- Adapte la documentation assemblée (un seul fichier) à la page html unique :
--  * fichier.md#ancre -> #ancre (tous les fichiers sont dans la page)
--  * autres fichiers du dépôt -> lien vers GitHub
--  * sommaire (h1 puis h2) exposé au gabarit pour le menu latéral
local repo_url = "https://github.com/" .. (os.getenv("GITHUB_REPOSITORY") or "kantiles/biso_docs")

local function fix(link)
  local t = link.target
  if t:match("^%a[%w+.-]*:") or t:match("^#") then return link end
  local anchor = t:match("^[^#]+%.md#(.+)$")
  if anchor then
    link.target = "#" .. anchor
  elseif not t:match("^[^#]+%.md$") then
    link.target = repo_url .. "/blob/main/" .. t
  end
  return link
end

function Pandoc(doc)
  local chapitres = {}
  for _, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 1 then
      table.insert(chapitres, {
        num = tostring(#chapitres + 1),
        id = b.identifier,
        title = pandoc.utils.stringify(b.content),
        sections = {},
      })
    elseif b.t == "Header" and b.level == 2 and #chapitres > 0 then
      table.insert(chapitres[#chapitres].sections,
        { id = b.identifier, title = pandoc.utils.stringify(b.content) })
    end
  end
  doc.meta.chapitres = chapitres
  doc.meta.repo_url = repo_url
  return doc:walk({ Link = fix })
end
