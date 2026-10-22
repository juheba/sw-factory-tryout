#!/usr/bin/env bash
# Gesamtes Gate: Service (Gradle) und Frontend (Flutter).
set -euo pipefail

cd "$(dirname "$0")"

echo "== Service =="
./gradlew :service:build

echo "== Frontend =="
frontend/tool/verify.sh
