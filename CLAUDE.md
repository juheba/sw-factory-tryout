# CLAUDE.md – Arbeitsanweisung für Coding-Agents

Dieses Repo ist ein spec-first Monorepo aus Java-Microservice und Flutter-Frontend. Alles, was du hier änderst,
muss über das Gate unten verifiziert sein, bevor du es als fertig meldest.

## Struktur

```
openapi/openapi.yaml      Vertrag, einzige Quelle der Wahrheit
service/                  Spring Boot Microservice (Gradle)
frontend/                 Flutter-App (Dart), nutzt einen aus der Spec generierten Client
docs/                     Architektur (Mermaid), ADRs, Prozess
config/checkstyle/        Stilregeln für den Service
verify.sh                 Gesamtes Gate (Service und Frontend)
```

## Stack

- **Service:** Java 25 (Toolchain), Gradle (Kotlin DSL, Wrapper), Spring Boot 4.x (Spring Framework 7, Jackson 3),
  OpenAPI Generator (`spring`, `interfaceOnly`). Tests: JUnit 5, MockMvc, AssertJ. Qualität: Checkstyle, JaCoCo.
- **Frontend:** Flutter (stable), Dart. Client aus der Spec mit OpenAPI Generator (`dart`), erzeugt in
  `frontend/packages/order_api` (nicht eingecheckt). Qualität: `dart format`, `flutter analyze`, `flutter test`.

## Befehle

| Zweck | Befehl |
|---|---|
| **Gate gesamt (Pflicht vor jedem Commit/PR)** | `./verify.sh` |
| Nur Service prüfen | `./gradlew :service:build` |
| Nur Frontend prüfen | `frontend/tool/verify.sh` |
| Service-Code aus der Spec neu erzeugen | `./gradlew :service:openApiGenerate` |
| Dart-Client aus der Spec neu erzeugen | `./gradlew :frontend:openApiGenerate` |
| Service starten | `./gradlew :service:bootRun` |
| Frontend formatieren | `cd frontend && dart format lib test` |

„Fertig“ heißt: das Gate für alle berührten Teile ist grün. Melde nie Erfolg, ohne den Befehl wirklich
ausgeführt zu haben. Wenn ein benötigtes Tool (z. B. Flutter) in deiner Umgebung fehlt, sag das ausdrücklich,
statt Erfolg zu behaupten.

## Spec-first-Regeln

1. Die Wahrheit ist `openapi/openapi.yaml`. API-Änderungen beginnen **dort**.
2. Generierter Code (`service/build/generated/`, `frontend/packages/order_api/`) wird **nie** von Hand geändert
   und **nie** eingecheckt.
3. Service: Controller implementieren die generierten `*Api`-Interfaces (Paket `com.example.orderservice.web`).
4. Service: `OpenApiContractTest` muss grün bleiben; Vertrag und Endpunkte dürfen nicht auseinanderlaufen.
5. Frontend: Der generierte Client wird nur in `lib/orders/orders_repository.dart` verwendet. Die UI arbeitet mit
   den eigenen Modellen (`OrderSummary`). Ändert sich die Spec, wird nur das Repository angepasst.
6. Neue Endpunkte brauchen: Spec-Eintrag, Service-Implementierung mit Tests (Erfolgs- und mindestens ein Fehlerfall)
   und, falls das Frontend sie braucht, Repository und UI mit Widget-Test.

## Konventionen

- Code und Bezeichner auf Englisch; Doku und Commit-Beschreibungen dürfen Deutsch sein.
- Service: Constructor Injection, keine Wildcard-Imports, Zeilen höchstens 120 Zeichen,
  Fehler als RFC-9457-Problem-Details (siehe `GlobalExceptionHandler`).
- Frontend: Lints aus `flutter_lints`, Formatierung mit `dart format`. Keine Geschäftslogik in Widgets.
- Keine neuen Abhängigkeiten oder Versions-Updates ohne ausdrücklichen Auftrag im Issue.
- Keine Secrets, Tokens oder `.env`-Dateien lesen oder committen.

## Git-Workflow

- Nie direkt auf `main` pushen. Branch pro Issue: `agent/<issue-nr>-<kurzer-slug>`.
- Commits klein und im Stil Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`).
- Pull Request mit `Closes #<issue-nr>`, kurzer Zusammenfassung und dem Ergebnis von `./verify.sh`.
- Kein Force-Push.

## Dokumentation

- Ändert sich Architektur oder Ablauf, aktualisiere `docs/architecture.md` (Mermaid-Diagramme) im selben PR.
- Grundlegende Entscheidungen als ADR in `docs/adr/` festhalten (Format siehe `0001-spec-first-openapi.md`).

## Wenn etwas unklar ist

Bei widersprüchlichen oder unvollständigen Akzeptanzkriterien im Issue: Annahmen im PR-Text benennen, statt zu raten
und stillschweigend etwas anderes zu bauen.
