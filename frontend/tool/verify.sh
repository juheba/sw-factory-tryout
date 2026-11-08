#!/usr/bin/env bash
# Gate für das Frontend: Client generieren, Abhängigkeiten holen, Format, Analyse, Tests.
set -euo pipefail

cd "$(dirname "$0")/.."

# ARCH-5: Client gekapselt (config/standards/architektur.md, Issue #196): Der generierte Client steht nur in den
# Repositories.
# Läuft zuerst, weil es nichts braucht außer grep.
verstoesse=$(grep -rl --include='*.dart' "package:order_api" lib | grep -vE '^lib/[^/]+/[^/]+_repository\.dart$' || true)
if [ -n "$verstoesse" ]; then
  echo "ARCH-5: Client gekapselt verletzt: package:order_api darf nur in lib/<feature>/*_repository.dart stehen. Betroffen:"
  echo "$verstoesse"
  exit 1
fi

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
