-- Réécrit les liens pour la version HTML :
--  * fichier.md -> fichier.html (readme.md -> index.html)
--  * #ancre absente du document courant -> meta.html#ancre
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
    return link
  end
  link.target = t:gsub("^readme%.md", "index.html"):gsub("%.md(#?)", ".html%1")
  return link
end

function Pandoc(doc)
  doc:walk({ Header = collect, Span = collect, Div = collect })
  return doc:walk({ Link = fix })
end
