# Standard: Sicherheit

Maßstab der Linse **Sicherheit** ([ADR 0003](../../docs/adr/0003-rollenmodell.md), [Rollen](../../docs/rollen.md)).
Der Coder baut danach, der Reviewer prüft danach. Die Datei liegt im Schutzbereich `config/`: Agents lesen sie,
Änderungen macht der Owner in einem eigenen PR mit Begründung. Reviewer und QA lesen die Fassung aus `main`.

Grundlage sind die [OWASP Top 10:2025](https://owasp.org/Top10/2025/) und die
[OWASP API Security Top 10:2023](https://owasp.org/API-Security/editions/2023/en/0x11-t10/). Der Bezug steht je Punkt
unter **Quelle**. Hier steht der **Produktcode** (Service, Frontend, Vertrag). Die Sicherheit der Agents und Workflows
regelt [ADR 0002](../../docs/adr/0002-agent-sicherheit.md). Neue Werkzeuge (Scanner, Sonar und ähnliche) werden in eigenen
Issues bewertet und sind hier nicht vorausgesetzt.

**Aufbau je Punkt:** **Prinzip** (allgemein), **Hier** (Umsetzung in diesem Repo), **Quelle**, **Prüft** wie in der
[Definition of Done](../definition-of-done.md): **Gate** (der Build erzwingt es), **Sperre** (Berechtigungen oder
`CODEOWNERS` verhindern es) oder **Urteil** (ein Mensch oder der Reviewer beurteilt es). Zitiert wird Kennung und
Kurzname, zum Beispiel `SEC-2: Fehler ohne Interna`. Die Kennung bleibt stabil.

## Punkte

### SEC-1: Eingaben an der Grenze geprüft

- **Prinzip:** Jede Eingabe von außen wird an der Grenze gegen ein festes Schema geprüft: Typ, Pflicht, Länge,
  Wertebereich, erlaubte Werte. Was nicht passt, wird abgelehnt und nicht repariert.
- **Hier:** Grenzen stehen im Vertrag `openapi/openapi.yaml` (`required`, `maxLength`, `maximum`, `enum`). Der Generator
  erzeugt daraus Bean Validation (`useBeanValidation`), Verstöße werden zu 400. Jedes neue Feld bekommt Grenzen.
  Fachliche Prüfungen (zum Beispiel unbekannte Artikelnummer) stehen im Paket `service`.
- **Quelle:** A05:2025 Injection, API4:2023 Unrestricted Resource Consumption.
- **Prüft:** Gate (Bean Validation aus der Spec, Tests mit Fehlerfall nach `DoD-4: Tests mit Fehlerfall`), Urteil
  (hat jedes neue Feld Grenzen).

### SEC-2: Fehler ohne Interna

- **Prinzip:** Fehlerantworten nennen, was der Aufrufer falsch gemacht hat, aber keine Interna: keine Stacktraces,
  Klassennamen, SQL, Pfade oder Konfiguration. Unerwartete Fehler enden kontrolliert, nicht in einem offenen Zustand.
- **Hier:** Fehler als RFC-9457-Problem-Details über den `GlobalExceptionHandler`
  (`ARCH-4: Fehler innen, Format außen`). `detail` enthält nur fachliche Texte. Für unbekannte Exceptions bleiben die
  Spring-Boot-Standardwerte (`server.error.include-message` und `include-stacktrace` nicht gesetzt).
- **Quelle:** A10:2025 Mishandling of Exceptional Conditions, A02:2025 Security Misconfiguration.
- **Prüft:** Urteil (Texte in `detail`, neue Exception-Handler).

### SEC-3: Geheimnisse nie im Repo

- **Prinzip:** Schlüssel, Token und Passwörter stehen nie im Code, in der Konfiguration im Repo, in Logs oder in PR-
  und Issue-Texten. Sie kommen zur Laufzeit aus einem Secret-Speicher.
- **Hier:** Secrets nur in GitHub-Environments. Agents lesen keine `.env`-Dateien und geben keine Umgebungsvariablen aus
  (`CLAUDE.md`, Deny-Regeln in `.claude/`). Das Frontend enthält keine Geheimnisse, die Basis-URL kommt per
  `--dart-define`.
- **Quelle:** A04:2025 Cryptographic Failures, A07:2025 Authentication Failures.
- **Prüft:** Sperre (Deny-Regeln der Agents, Environments), Urteil (Diff).

### SEC-4: Abhängigkeiten gepflegt

- **Prinzip:** Fremder Code kommt nur bewusst ins Projekt: mit fester Version, aus bekannter Quelle, geprüft vor dem
  Update. Neue Abhängigkeiten brauchen eine Entscheidung.
- **Hier:** Versionen im Gradle-Versionskatalog und in `pubspec.yaml`, Actions per Commit-SHA. Dependabot meldet Updates,
  der Reviewer prüft sie nach `DoD-U1` bis `DoD-U3`, die Claude-Action nach dem Vorgehen B1 (`docs/betrieb.md`). Neue
  Abhängigkeiten nur mit Zusage des Owners (`DoD-7: Keine ungeplanten Abhängigkeiten`).
- **Quelle:** A03:2025 Software Supply Chain Failures, A08:2025 Software or Data Integrity Failures.
- **Prüft:** Sperre (`CODEOWNERS` für Build-Dateien), Urteil (Reviewer).

### SEC-5: Statische Analyse

- **Prinzip:** Code wird automatisch auf bekannte Schwachstellenmuster geprüft, bevor er gemergt wird. Befunde werden
  behoben oder begründet zurückgestellt, nicht ignoriert.
- **Hier:** CodeQL (Default-Setup) für Java/Kotlin und GitHub Actions an jedem PR. Dart deckt CodeQL nicht ab.
- **Quelle:** A05:2025 Injection, A06:2025 Insecure Design.
- **Prüft:** Urteil (Befunde lesen). CodeQL ist kein Pflicht-Check im Ruleset.

### SEC-6: Minimale Rechte

- **Prinzip:** Jede Komponente bekommt nur die Rechte, die sie braucht, und nur so lange, wie sie sie braucht.
- **Hier:** Workflows starten mit `permissions: {}` und vergeben je Job nur Nötiges. Schreibende Agent-Läufe brauchen die
  Freigabe im Environment. Der Service gibt per Actuator nur `health` und `info` frei.
- **Quelle:** A01:2025 Broken Access Control, API5:2023 Broken Function Level Authorization.
- **Prüft:** Sperre (Environments, Ruleset, `CODEOWNERS`), Urteil (neue Workflows und Endpunkte).

### SEC-7: Zugriff je Objekt geprüft

- **Prinzip:** Bei jedem Zugriff auf ein Objekt über eine Kennung (`/orders/{id}`) wird geprüft, ob der Aufrufer genau
  dieses Objekt sehen oder ändern darf. Eine gültige Anmeldung allein reicht nicht.
- **Hier:** Heute gibt es keine Anmeldung, der Punkt gilt noch nicht. Wird eine Anmeldung gebaut, kommt sie per ADR,
  und jeder Endpunkt mit Kennung prüft dann Besitz oder Rolle im Paket `service`, mit Test für den fremden Zugriff.
- **Quelle:** API1:2023 Broken Object Level Authorization, A01:2025 Broken Access Control.
- **Prüft:** Urteil (ab Einführung einer Anmeldung).

### SEC-8: Ressourcen begrenzt

- **Prinzip:** Keine Anfrage darf unbegrenzt Speicher, Rechenzeit oder Datenmenge verbrauchen. Mengen, Längen und
  Listen haben Obergrenzen.
- **Hier:** Obergrenzen im Vertrag (zum Beispiel `maxLength`, `maximum` für Mengen). Listen-Endpunkte bekommen Seiten
  (Paging), sobald die Datenmenge wächst.
- **Quelle:** API4:2023 Unrestricted Resource Consumption, API6:2023 Unrestricted Access to Sensitive Business Flows.
- **Prüft:** Urteil.

### SEC-9: Sichere Konfiguration

- **Prinzip:** Standardwerte sind sicher, Debug- und Verwaltungsfunktionen sind aus. Was es nur für die Entwicklung
  gibt, ist als solches erkennbar und kommt nicht in den Betrieb.
- **Hier:** `application.yml` ohne Debug-Optionen, Actuator eingeschränkt (`SEC-6: Minimale Rechte`). `http://localhost`
  im Frontend ist nur der Standard für die Entwicklung. Für einen Betrieb braucht es TLS und eine eigene Konfiguration.
- **Quelle:** A02:2025 Security Misconfiguration, API8:2023 Security Misconfiguration.
- **Prüft:** Urteil.

### SEC-10: Protokolle ohne sensible Daten

- **Prinzip:** Sicherheitsrelevante Ereignisse werden protokolliert, sensible Daten (Token, Passwörter,
  personenbezogene Daten) nicht.
- **Hier:** Ausgaben nur über das Logging-Framework, nicht über `System.out` oder `print`
  (`ARCH-9: Querschnitt konfiguriert`, `CODE-10: Nichts Totes`). Keine Kundendaten oder Anfragekörper im Log.
- **Quelle:** A09:2025 Security Logging and Alerting Failures.
- **Prüft:** Gate für Standard-Streams (ArchUnit, Linter `avoid_print`), sonst Urteil.

## Pflege

- Änderungen nur durch den Owner, in einem eigenen PR mit Begründung.
- Kennungen bleiben stabil; ein neuer Punkt bekommt die nächste freie Nummer.
- Erscheint eine neue Ausgabe der OWASP-Listen, werden die Bezüge unter **Quelle** geprüft.
- Wird ein Urteilspunkt wiederholt verletzt, prüfen wir, ob ein Gate ihn erzwingen kann (Lernschleife P8).
