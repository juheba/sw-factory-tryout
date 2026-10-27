#!/usr/bin/env bash
# Baut die API-Dokumentation (Swagger UI) aus openapi/openapi.yaml nach site/dist.
# Läuft im Workflow .github/workflows/pages.yml und lokal: ./site/build.sh
#
# Swagger UI wird nicht aus einem Paketregister, sondern per Commit-SHA aus dem Git-Repository des Projekts geholt.
# Die SHA ist der Inhalt: Stimmt der Commit nicht, bricht der Build ab. Zur Aktualisierung Tag und SHA gemeinsam ändern
# (docs/betrieb.md, Abschnitt „Swagger UI aktualisieren“).
set -euo pipefail

SWAGGER_UI_REPO="https://github.com/swagger-api/swagger-ui.git"
SWAGGER_UI_TAG="v5.33.3"
SWAGGER_UI_SHA="38ca10e1867a66525751590d8d51011973107ad1"

cd "$(dirname "$0")/.."
OUT="site/dist"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "1/3 Spec prüfen"
python3 - openapi/openapi.yaml <<'PY'
import sys
try:
    import yaml
except ImportError:
    sys.exit("PyYAML fehlt (python3 -m pip install pyyaml)")
with open(sys.argv[1], encoding="utf-8") as f:
    spec = yaml.safe_load(f)
if not isinstance(spec, dict) or "openapi" not in spec or not spec.get("paths"):
    sys.exit("openapi.yaml ist keine gültige OpenAPI-Spec (Schlüssel openapi oder paths fehlt)")
print(f"   OpenAPI {spec['openapi']}, {len(spec['paths'])} Pfade")
PY

echo "2/3 Swagger UI $SWAGGER_UI_TAG holen"
git init -q "$WORK/ui"
git -C "$WORK/ui" fetch -q --depth 1 "$SWAGGER_UI_REPO" "$SWAGGER_UI_SHA"
git -C "$WORK/ui" checkout -q FETCH_HEAD
actual="$(git -C "$WORK/ui" rev-parse HEAD)"
if [ "$actual" != "$SWAGGER_UI_SHA" ]; then
  echo "Commit stimmt nicht: erwartet $SWAGGER_UI_SHA, erhalten $actual" >&2
  exit 1
fi

echo "3/3 Seite bauen nach $OUT"
rm -rf "$OUT"
mkdir -p "$OUT/ui"
for f in swagger-ui.css swagger-ui-bundle.js favicon-16x16.png favicon-32x32.png; do
  cp "$WORK/ui/dist/$f" "$OUT/ui/$f"
done
cp "$WORK/ui/dist/swagger-ui-bundle.js.LICENSE.txt" "$OUT/ui/"
cp "$WORK/ui/LICENSE" "$OUT/ui/LICENSE.txt"
cp openapi/openapi.yaml "$OUT/openapi.yaml"
sed "s/@@SWAGGER_UI_TAG@@/$SWAGGER_UI_TAG/g" site/index.html > "$OUT/index.html"
touch "$OUT/.nojekyll"
echo "fertig: $(find "$OUT" -type f | wc -l) Dateien"
