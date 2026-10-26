# sw-factory-tryout

[![CI](https://github.com/juheba/sw-factory-tryout/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/juheba/sw-factory-tryout/actions/workflows/ci.yml)

Spec-first Monorepo als Ausgangspunkt für die eigene Software Factory (Stufe 1):
Ein Issue wird von einem Coding-Agent (Claude Code) bearbeitet, die CI prüft das Ergebnis, ein Mensch reviewt den PR.

```
openapi/    Vertrag (openapi.yaml), Quelle der Wahrheit
service/    Spring Boot 4, Java 25, Gradle
frontend/   Flutter (Dart), mit generiertem API-Client
docs/       Architektur (Mermaid), Prozess, ADRs
```

## Voraussetzungen

- Git, ein JDK ist nicht zwingend nötig (Gradle lädt JDK 25 per Toolchain nach), empfohlen ist aber ein lokales JDK 25
- [Flutter SDK](https://docs.flutter.dev/install) (stable)

## Erste Einrichtung (einmalig)

Das Frontend enthält nur Quellcode. Die Plattformordner (Android, iOS, Web) erzeugt Flutter selbst:

```bash
git init && git add -A && git commit -m "chore: initial import"   # damit du Änderungen von flutter create siehst
cd frontend
flutter create --platforms=android,ios,web --project-name order_app .
git status        # prüfen: lib/, test/ und pubspec.yaml dürfen nicht überschrieben sein
dart format lib test
cd ..
```

Falls `flutter create` eigene Dateien überschrieben hat: `git checkout -- frontend/lib frontend/test frontend/pubspec.yaml`.

## Schnellstart

```bash
./gradlew :service:bootRun         # Service starten (http://localhost:8080)
./verify.sh                        # Gate gesamt: Service und Frontend
```

Frontend: `cd frontend && flutter run -d chrome`, Android-Emulator mit `--dart-define=API_BASE_URL=http://10.0.2.2:8080`

Ablauf: siehe [docs/process.md](docs/process.md)

## Arbeitsweise

- `CLAUDE.md` beschreibt Regeln, Befehle und Definition of Done für Agents.
- Aufträge als GitHub-Issue mit der Vorlage „Agent-Auftrag“.
- Prozess und Ausbaustufen: [docs/process.md](docs/process.md), Architektur: [docs/architecture.md](docs/architecture.md)
- Roadmap und offene Punkte: [docs/roadmap.md](docs/roadmap.md), Betrieb und Notfälle: [docs/betrieb.md](docs/betrieb.md)
