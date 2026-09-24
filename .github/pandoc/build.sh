#!/usr/bin/env bash
# Convertit les fichiers Markdown du dépôt en site HTML au format DSFR.
# Usage : .github/pandoc/build.sh [dossier_sortie] (défaut : _site)
# Nécessite pandoc et npm.
set -euo pipefail

DSFR_VERSION="1.15.3"
OUT="${1:-_site}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$OUT/dsfr/utility"

# Ressources du Système de Design de l'État
(cd "$TMP" && npm pack "@gouvfr/dsfr@$DSFR_VERSION" --silent >/dev/null && tar xzf gouvfr-dsfr-*.tgz)
DIST="$TMP/package/dist"
cp "$DIST"/dsfr.min.css "$DIST"/dsfr.module.min.js "$DIST"/dsfr.nomodule.min.js "$OUT/dsfr/"
cp -R "$DIST"/fonts "$DIST"/icons "$DIST"/favicon "$OUT/dsfr/"
cp -R "$DIST"/utility/icons "$OUT/dsfr/utility/"

# Pages dans l'ordre du menu, puis les éventuels autres fichiers
pages=(readme finess as rp autre meta)
for f in "$ROOT"/*.md; do
  name="$(basename "$f" .md)"
  [[ " ${pages[*]} " == *" $name "* ]] || pages+=("$name")
done

title_of() {
  grep -m1 '^#' "$ROOT/$1.md" \
    | sed -E 's/^#+ *//; s/\*\*//g; s/\[([^]]*)\]\([^)]*\)/\1/g; s/ *\{#[^}]*\}//'
}
href_of() { [[ "$1" == readme ]] && echo index.html || echo "$1.html"; }

for current in "${pages[@]}"; do
  [[ -f "$ROOT/$current.md" ]] || continue
  meta="$TMP/$current.yaml"
  {
    echo "pagetitle: '$(title_of "$current" | sed "s/'/''/g")'"
    echo "navpages:"
    for p in "${pages[@]}"; do
      [[ -f "$ROOT/$p.md" ]] || continue
      echo "  - href: '$(href_of "$p")'"
      echo "    title: '$(title_of "$p" | sed "s/'/''/g")'"
      [[ "$p" == "$current" ]] && echo "    active: true"
    done
  } > "$meta"

  pandoc "$ROOT/$current.md" \
    --from markdown \
    --to html5 \
    --template "$HERE/template.html" \
    --lua-filter "$HERE/links.lua" \
    --metadata-file "$meta" \
    --output "$OUT/$(href_of "$current")"
done

echo "Site généré dans $OUT"
