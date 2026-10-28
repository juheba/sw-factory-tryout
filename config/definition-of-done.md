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

## Je nach Änderung

| Nr. | Gilt bei | Punkt | Prüft |
|---|---|---|---|
| DoD-A1 | API | Fehler sind RFC-9457-Problem-Details über den `GlobalExceptionHandler`. Neue Endpunkte haben Spec-Eintrag, Service-Implementierung, Test für Erfolg und mindestens einen Fehlerfall. | Urteil |
| DoD-A2 | API, Service | Controller implementieren die generierten `*Api`-Interfaces im Paket `com.example.orderservice.web`. | Gate (Vertragstest), Urteil |
| DoD-A3 | API, Frontend | Der generierte Client steht nur in einem Repository unter `lib/*/`. Die UI arbeitet mit eigenen Modellen. Ändert sich die Spec, wird nur das Repository angepasst. | Urteil |
| DoD-B1 | UI | Keine Geschäftslogik in Widgets. Erfolgs- und Fehlerzustand haben je einen Widget-Test, und das Frontend zeigt Fehler verständlich an. | Urteil |
| DoD-C1 | Service | Constructor Injection, keine Wildcard-Imports, Zeilen höchstens 120 Zeichen. | Gate (Checkstyle), Urteil (Constructor Injection) |
| DoD-D1 | Workflow, Betrieb | Änderungen an Automatisierung, Sicherheit oder Ablauf sind im ADR oder in `docs/betrieb.md` begründet. Nur der Owner ändert Schutzbereiche. | Urteil |

## Je Issue

Die Akzeptanzkriterien des Issues sind der letzte Teil der Definition. Sie ergänzen diese Liste und werden in DoD-5
geprüft.

## Pflege

- Änderungen nur durch den Owner, in einem eigenen PR mit Begründung.
- Wird ein Urteilspunkt wiederholt verletzt, prüfen wir, ob das Gate ihn erzwingen kann (zum Beispiel eine
  Checkstyle-Regel oder ein Test).
- Fehlt der Liste ein Punkt, den ein Review gefunden hat, kommt er hinzu (Lernschleife, Roadmap P8).
