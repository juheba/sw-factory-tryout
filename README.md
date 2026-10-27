# sw-factory-tryout

[![CI](https://github.com/juheba/sw-factory-tryout/actions/workflows/ci.yml/badge.svg?branch=main&style=flat)](https://github.com/juheba/sw-factory-tryout/actions/workflows/ci.yml)
[![API-Doku](https://github.com/juheba/sw-factory-tryout/actions/workflows/pages.yml/badge.svg?branch=main&style=flat)](https://juheba.github.io/sw-factory-tryout/)

[![OpenAPI 3.0.3](https://img.shields.io/badge/OpenAPI-3.0.3-6BA539?style=flat)](openapi/openapi.yaml)
[![Java 25](https://img.shields.io/badge/Java-25-007396?style=flat)](service/build.gradle.kts)
[![Spring Boot 4.x](https://img.shields.io/badge/Spring%20Boot-4.x-6DB33F?style=flat)](gradle/libs.versions.toml)
[![Flutter stable](https://img.shields.io/badge/Flutter-stable-02569B?style=flat)](frontend/)

Spec-first Monorepo als Ausgangspunkt für die eigene Software Factory (Stufe 1):
Ein Issue wird von einem Coding-Agent (Claude Code) bearbeitet, die CI prüft das Ergebnis, ein Mensch reviewt den PR.

```
openapi/    Vertrag (openapi.yaml), Quelle der Wahrheit
service/    Spring Boot 4, Java 25, Gradle
frontend/   Flutter (Dart), mit generiertem API-Client
docs/       Architektur (Mermaid), Prozess, ADRs
site/       Baut die API-Doku (Swagger UI) für GitHub Pages
```

## API-Dokumentation

Der Vertrag steht als Webseite (Swagger UI, nur lesend) unter https://juheba.github.io/sw-factory-tryout/ und wird bei jeder
Änderung an `openapi/` auf `main` neu erzeugt. Lokal bauen: `./site/build.sh`, dann `site/dist/` mit einem beliebigen
Webserver ausliefern (zum Beispiel `python3 -m http.server -d site/dist`).

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
