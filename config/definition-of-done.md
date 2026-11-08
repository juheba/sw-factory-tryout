# Definition of Done

Gemeinsamer Maßstab für Coder, Reviewer, QA und Owner. Ein Pull Request ist fertig, wenn alle zutreffenden Punkte
erfüllt sind. Die Datei liegt im Schutzbereich `config/`: Agents lesen sie, ändern sie aber nicht. Änderungen macht
der Owner. Reviewer und QA lesen die Fassung aus `main`, nicht die aus dem PR.

**Art der Prüfung** (Spalte „Prüft“):

- **Gate:** `./verify.sh` erzwingt den Punkt. Rot heißt nicht fertig. Der Reviewer wiederholt das nicht.
- **Sperre:** Berechtigungen des Agenten (`.claude/agent-settings.json`), `.gitignore` oder `CODEOWNERS` verhindern den
  Verstoß technisch. Der Reviewer prüft nur, ob ein Umweg im Diff steht.
- **Urteil:** Ein Mensch oder der Reviewer muss lesen und beurteilen. Hier liegt der Wert des Reviews.

Wiederkehrende Urteilsbefunde wandern, wo möglich, ins Gate oder in diese Liste.

**Im PR-Text:** Der Coder listet jeden Punkt mit `✅` (erfüllt), `n/a` (trifft nicht zu) oder `Abweichung: <Grund>`.
Der Reviewer antwortet pro Urteilspunkt mit `✅`, `❌` oder `nicht beurteilbar` und zitiert die Punktnummer.

## Immer

| Nr. | Punkt | Prüft |
|---|---|---|
| DoD-1 | `./verify.sh` ist grün: Service (Build, Tests, Checkstyle, JaCoCo, `OpenApiContractTest`) und Frontend (`dart format`, `flutter analyze`, `flutter test`). Das tatsächliche Ergebnis steht im PR-Text. | Gate |
| DoD-2 | Betrifft die Änderung die API, beginnt sie in `openapi/openapi.yaml`. Service und Frontend folgen der Spec, nicht umgekehrt. | Gate (Vertragstest), Urteil (Frontend) |
| DoD-3 | Generierter Code (`service/build/generated/`, `frontend/packages/order_api/`) ist weder von Hand geändert noch eingecheckt. | Sperre (`.gitignore`), Urteil (erzwungenes `git add -f`) |
| DoD-4 | Neues Verhalten hat einen Test für den Erfolgsfall und mindestens einen Fehlerfall. Der Test prüft das Kriterium wirklich und läuft nicht nur trivial durch. | Urteil |
| DoD-5 | Alle Akzeptanzkriterien des Issues sind erfüllt. Jede Abweichung steht mit Begründung im PR-Text. | Urteil |
| DoD-6 | Annahmen und offene Punkte stehen im PR-Text. Es wurde nichts stillschweigend anders gebaut als beauftragt. | Urteil |
| DoD-7 | Keine neuen Abhängigkeiten oder Versionssprünge ohne Auftrag im Issue. Keine Secrets, Tokens oder `.env`-Dateien. | Sperre (Build-Dateien, `.env`), Urteil (Code, der eine Bibliothek nachbaut oder Daten ausliest) |
| DoD-8 | Doku ist aktuell: `docs/architecture.md` bei Änderung der Architektur oder des Ablaufs, Roadmap-Status des betroffenen Punkts, ADR bei Grundsatzentscheidung. | Urteil |
| DoD-9 | Keine Änderung in Schutzbereichen (`.github/`, `.claude/`, `CLAUDE.md`, `config/`, `site/`, `verify.sh`, `frontend/tool/`, Build-Dateien). Ein Verstoß ist immer ein blockierender Befund. | Sperre (Berechtigungen, `CODEOWNERS`), Urteil (Umwege) |
| DoD-10 | Commits sind klein und im Stil Conventional Commits, der Branch heißt `agent/<issue-nr>-<slug>`, der PR enthält `Closes #<issue-nr>`. | Urteil |
| DoD-11 | Die Standards der betroffenen Linsen sind eingehalten (`config/standards/`, heute [Architektur](standards/architektur.md)). Befunde zitieren die Kennung des Standards (zum Beispiel `ARCH-2`). | Gate (soweit ein Standard „Gate“ nennt), Urteil |

## Je nach Änderung

| Nr. | Gilt bei | Punkt | Prüft |
|---|---|---|---|
| DoD-A1 | API | Fehler sind RFC-9457-Problem-Details über den `GlobalExceptionHandler`. Neue Endpunkte haben Spec-Eintrag, Service-Implementierung, Test für Erfolg und mindestens einen Fehlerfall. | Urteil |
| DoD-A2 | API, Service | Controller implementieren die generierten `*Api`-Interfaces im Paket `com.example.orderservice.web`. | Gate (Vertragstest), Urteil |
| DoD-A3 | API, Frontend | Der generierte Client steht nur in einem Repository unter `lib/*/`. Die UI arbeitet mit eigenen Modellen. Ändert sich die Spec, wird nur das Repository angepasst. | Urteil |
| DoD-B1 | UI | Keine Geschäftslogik in Widgets. Erfolgs- und Fehlerzustand haben je einen Widget-Test, und das Frontend zeigt Fehler verständlich an. | Urteil |
| DoD-C1 | Service | Constructor Injection, keine Wildcard-Imports, Zeilen höchstens 120 Zeichen. | Gate (Checkstyle), Urteil (Constructor Injection) |
| DoD-D1 | Workflow, Betrieb | Änderungen an Automatisierung, Sicherheit oder Ablauf sind im ADR oder in `docs/betrieb.md` begründet. Nur der Owner ändert Schutzbereiche. | Urteil |

## Update-PRs (Dependabot)

Gilt für PRs mit Autor `dependabot[bot]` und Branch `dependabot/…` (Entscheidung in [📌 #136](https://github.com/juheba/sw-factory-tryout/issues/136), 07.11.2026). Sie
entstehen ohne Issue und ohne Coder, deshalb ersetzen die Punkte hier einen Teil der Liste „Immer“:

- **Unverändert:** DoD-1 (Gate), DoD-3 und DoD-8 (falls betroffen, zum Beispiel Badges im README), DoD-11 nur als
  Gate (das Urteil entfällt, weil kein eigener Code entsteht).
- **`n/a`:** DoD-2, DoD-4, DoD-5 und DoD-6 (kein Auftrag, kein eigener Code), DoD-7 (der Versionssprung ist der Zweck
  des PRs; neue Abhängigkeiten prüft DoD-U2), DoD-10 (Branch, Commit und Text erzeugt Dependabot).
- **Ersetzt:** DoD-9 durch DoD-U2. Die Änderung im Schutzbereich ist bei Update-PRs gewollt, der Owner gibt sie per
  Code-Owner-Review frei. Ein Befund ist nur ein Umweg: alles, was über die Versionszeilen hinausgeht.

| Nr. | Punkt | Prüft |
|---|---|---|
| DoD-U1 | Release Notes und Changelog sind auf Breaking Changes, geänderte Standardwerte und entfernte Optionen gelesen und gegen unseren Code abgeglichen. Betroffene Stellen stehen mit Datei und Zeile im Review. Quelle ist der Text, den Dependabot in den PR setzt; fehlt er oder ist er gekürzt, lautet die Bewertung `nicht beurteilbar`. | Urteil |
| DoD-U2 | Der Diff ändert nur Versions- oder SHA-Zeilen (mit Tag-Kommentar) in den erwarteten Dateien (`gradle/libs.versions.toml`, Build-Dateien, `.github/workflows/`). Neue Abhängigkeiten, neue Repositories, Plugins oder sonstige Zeilen sind ein blockierender Befund. | Urteil |
| DoD-U3 | Bei Updates mit Wirkung über den Diff hinaus ist das nötige Vorgehen genannt: `org.openapi.generator` (generierter Code kann sich ändern, Gate bestätigt Service und Client), `anthropics/claude-code-action` (Vorgehen B1 in `docs/betrieb.md`, Smoke-Test nach [📌 #133](https://github.com/juheba/sw-factory-tryout/issues/133)), Gradle-Wrapper und Major-Updates (Release Notes vollständig lesen). | Urteil |

## Je Issue

Die Akzeptanzkriterien des Issues sind der letzte Teil der Definition. Sie ergänzen diese Liste und werden in DoD-5
geprüft.

## Pflege

- Änderungen nur durch den Owner, in einem eigenen PR mit Begründung.
- Wird ein Urteilspunkt wiederholt verletzt, prüfen wir, ob das Gate ihn erzwingen kann (zum Beispiel eine
  Checkstyle-Regel oder ein Test).
- Fehlt der Liste ein Punkt, den ein Review gefunden hat, kommt er hinzu (Lernschleife, Roadmap P8).
