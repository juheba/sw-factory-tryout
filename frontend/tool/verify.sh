#!/usr/bin/env bash
# Gate für das Frontend: Client generieren, Abhängigkeiten holen, Format, Analyse, Tests.
set -euo pipefail

cd "$(dirname "$0")/.."

(cd .. && ./gradlew :frontend:openApiGenerate)

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
