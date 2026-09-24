#!/usr/bin/env bash
# Convertit la documentation assemblée (R/export_html.R) en une page html
# unique et autonome au format DSFR (styles, polices et scripts intégrés).
# Usage : .github/pandoc/build_unique.sh [fichier_md] [fichier_html]
#         (défauts : documentation_biso.md, documentation_biso.html)
# Nécessite pandoc et npm.
set -euo pipefail

DSFR_VERSION="1.15.3"
IN="${1:-documentation_biso.md}"
OUT="${2:-documentation_biso.html}"
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Ressources du Système de Design de l'État
(cd "$TMP" && npm pack "@gouvfr/dsfr@$DSFR_VERSION" --silent >/dev/null && tar xzf gouvfr-dsfr-*.tgz)
mkdir -p "$TMP/res"
ln -s "$TMP/package/dist" "$TMP/res/dsfr"

pandoc "$IN" \
  --from markdown \
  --to html5 \
  --template "$HERE/template_unique.html" \
  --lua-filter "$HERE/document_unique.lua" \
  --metadata title="Documentation BISO" \
  --metadata date="$(date +%d/%m/%Y)" \
  --metadata accueil="#contenu" \
  --resource-path "$TMP/res" \
  --embed-resources \
  --output "$OUT"

echo "Documentation générée dans $OUT"
