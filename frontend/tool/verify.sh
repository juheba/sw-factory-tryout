#!/usr/bin/env bash
# Gate für das Frontend: Client generieren, Abhängigkeiten holen, Format, Analyse, Tests.
set -euo pipefail

cd "$(dirname "$0")/.."

(cd .. && ./gradlew :frontend:openApiGenerate)

flutter pub get

# dart format korrigiert die Dateien selbst und meldet per Exit-Code, dass etwas abwich.
# Der Diff zeigt, was sich geändert hat; lokal bleibt die Korrektur im Arbeitsverzeichnis.
if ! dart format --set-exit-if-changed lib test; then
  echo "Formatierung wich ab. Änderungen von dart format:"
  git --no-pager diff -- lib test || true
  exit 1
fi

flutter analyze
flutter test
