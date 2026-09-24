-- Adapte les documents Markdown au site HTML :
--  * fichier.md -> fichier.html (readme.md -> index.html)
--  * #ancre absente du document courant -> meta.html#ancre
--  * autres fichiers du dépôt -> lien vers GitHub
--  * liste des sections (h2) exposée au gabarit pour le menu latéral
local repo_url = "https://github.com/" .. (os.getenv("GITHUB_REPOSITORY") or "kantiles/biso_docs")
local ids = {}

local function collect(el)
  if el.identifier and el.identifier ~= "" then ids[el.identifier] = true end
end

local function fix(link)
  local t = link.target
  if t:match("^%a[%w+.-]*:") then return link end -- URL externe
  local anchor = t:match("^#(.+)$")
  if anchor then
    if not ids[anchor] then link.target = "meta.html#" .. anchor end
  elseif t:match("^[^#]+%.md") then
    link.target = t:gsub("^readme%.md", "index.html"):gsub("%.md(#?)", ".html%1")
  else
    link.target = repo_url .. "/blob/main/" .. t
  end
  return link
end

function Pandoc(doc)
  local sections = {}
  doc:walk({
    Header = function(h)
      collect(h)
      if h.level == 2 then
        table.insert(sections, { id = h.identifier, title = pandoc.utils.stringify(h.content) })
      end
    end,
    Span = collect,
    Div = collect,
  })
  doc.meta.sections = sections
  doc.meta.repo_url = repo_url
  return doc:walk({ Link = fix })
end
