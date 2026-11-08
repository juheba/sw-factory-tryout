# Standard: Architektur

Maßstab der Linse **Architektur** ([ADR 0003](../../docs/adr/0003-rollenmodell.md), [Rollen](../../docs/rollen.md)).
Der Planer entwirft danach, der Coder baut danach, der Reviewer prüft danach. Die Datei liegt im Schutzbereich `config/`:
Agents lesen sie, Änderungen macht der Owner in einem eigenen PR mit Begründung. Reviewer und QA lesen die Fassung aus
`main`.

**Aufbau je Punkt:**

- **Prinzip:** allgemein und unabhängig vom Stack. Es gilt auch für andere Projekte der Factory.
- **Hier:** die Umsetzung in diesem Repo (Pfade, Klassen, Werkzeuge). Für ein neues Projekt wird nur dieser Teil neu
  geschrieben.
- **Prüft:** wie in der [Definition of Done](../definition-of-done.md): **Gate** (der Build erzwingt es), **Sperre**
  (Berechtigungen oder `CODEOWNERS` verhindern es) oder **Urteil** (ein Mensch oder der Reviewer beurteilt es).

Jeder Punkt hat eine **Kennung** (`ARCH-2`) und einen **Kurznamen** (`Abhängigkeiten nach innen`). Zitiert wird
immer beides zusammen, `ARCH-2: Abhängigkeiten nach innen`, wie bei der Definition of Done
(`DoD-11: Standards eingehalten`). Die Kennung bleibt stabil, der Kurzname darf umformuliert werden.

## Punkte

### ARCH-1: Vertrag zuerst

- **Prinzip:** Schnittstellen zwischen Komponenten werden zuerst als maschinenlesbarer Vertrag beschrieben. Beide Seiten
  folgen dem Vertrag, nicht umgekehrt. Generierter Code wird nicht von Hand geändert.
- **Hier:** `openapi/openapi.yaml` ist die Quelle der Wahrheit ([ADR 0001](../../docs/adr/0001-spec-first-openapi.md)).
  Der Service implementiert die generierten `*Api`-Interfaces, das Frontend nutzt den generierten Dart-Client.
  `OpenApiContractTest` prüft Vertrag und Endpunkte.
- **Prüft:** Gate (Vertragstest), Urteil (Frontend).

### ARCH-2: Abhängigkeiten nach innen

- **Prinzip:** Fachliche Logik hängt nicht von der Transportschicht ab (HTTP, UI). Die äußere Schicht übersetzt, die
  innere entscheidet.
- **Hier:** Im Service geht die Richtung `web` → `service` → Speicher. Klassen in `..service..` importieren nichts aus
  `..web..` und kein Spring-HTTP (`org.springframework.http..`, `org.springframework.web..`). Controller enthalten keine
  fachlichen Regeln, sie delegieren.
- **Prüft:** Gate (ArchUnit, `ArchitectureTest`, [ADR 0004](../../docs/adr/0004-architekturregeln-archunit.md)): Abhängigkeitsrichtung und keine Zyklen zwischen Paketen.
  Urteil: Controller ohne fachliche Regeln.

### ARCH-3: Modelle an der Grenze

- **Prinzip:** Datenmodelle der Schnittstelle dürfen innen benutzt werden, solange sie nur Daten tragen. Sobald ein
  Objekt eigenes Verhalten oder eigene Regeln braucht, bekommt es ein eigenes Domänenmodell, und die Grenze übersetzt.
- **Hier:** Der Service arbeitet heute mit den generierten Modellen aus `com.example.orderservice.api.model`. Ein eigenes
  Domänenmodell kommt mit einem ADR, sobald eine Regel am Objekt selbst hängen müsste (zum Beispiel ein Zustandswechsel
  einer Bestellung mit eigener Prüfung). Im Frontend gilt die Trennung schon heute (ARCH-5).
- **Prüft:** Urteil.

### ARCH-4: Fehler innen, Format außen

- **Prinzip:** Fachliche Fehler sind eigene, sprechende Typen in der inneren Schicht. Erst die äußere Schicht bildet sie
  auf das Transportformat ab, an genau einer Stelle und ohne interne Details nach außen.
- **Hier:** Eigene Exceptions im Paket `service` (zum Beispiel `OrderNotFoundException`). Abgebildet werden sie nur im
  `GlobalExceptionHandler` (Paket `web`), als RFC-9457-Problem-Details. `ProblemDetail` wird nur in `..web..` erzeugt.
  Stacktraces und Klassennamen erscheinen nicht in der Antwort.
- **Prüft:** Gate (ArchUnit, [ADR 0004](../../docs/adr/0004-architekturregeln-archunit.md)): „`ProblemDetail` nur in `web`“ und keine generischen Exceptions. Urteil: sprechende
  Typen, keine internen Details in der Antwort.

### ARCH-5: Client gekapselt

- **Prinzip:** Die Oberfläche ist nach Fachthemen gegliedert, nicht nach technischen Schichten. Der Zugriff auf
  Schnittstellen ist hinter einer eigenen Abstraktion gekapselt, die Oberfläche arbeitet mit eigenen Modellen.
- **Hier:** Ordner `frontend/lib/<feature>/` (heute `orders/`, `products/`). Der generierte Client (`package:order_api`)
  steht nur in `*_repository.dart`. Ein Repository ist eine abstrakte Klasse mit einer Implementierung gegen die API
  (zum Beispiel `OrdersRepository` und `ApiOrdersRepository`). Die UI nutzt eigene Modelle wie `OrderSummary` oder
  `Product`.
- **Prüft:** Gate (`frontend/tool/verify.sh`, [ADR 0004](../../docs/adr/0004-architekturregeln-archunit.md)): `package:order_api` nur in `lib/<feature>/*_repository.dart`.
  Urteil: Gliederung nach Features, eigene Modelle in der UI.

### ARCH-6: Logik nicht im Widget

- **Prinzip:** Darstellung und Ablauflogik sind getrennt. Komponenten der Oberfläche zeigen Zustand an und melden
  Eingaben. Was mit den Eingaben passiert, entscheidet eine eigene Einheit.
- **Hier:** Für einfachen Bildschirmzustand reicht `setState`. Wächst der Zustand (mehrere Quellen, Abhängigkeiten
  zwischen Werten, Wiederverwendung), kommt ein eigener `ChangeNotifier` ohne Zusatzpaket. Eine Bibliothek für das
  Zustandsmanagement (zum Beispiel Riverpod oder Bloc) braucht ein ADR (ARCH-10). Siehe auch DoD-B1.
- **Prüft:** Urteil.

### ARCH-7: Konstruktor-Injektion

- **Prinzip:** Eine Einheit bekommt ihre Abhängigkeiten von außen übergeben. Sie holt sie sich nicht selbst und nutzt
  keine globalen Instanzen.
- **Hier:** Im Service gilt Constructor Injection, keine Feld-Injection (`@Autowired` an Feldern). Im Frontend werden
  Repositories über Konstruktoren übergeben und in `main.dart` verdrahtet. Tests übergeben Fakes auf demselben Weg.
- **Prüft:** Gate (ArchUnit, [ADR 0004](../../docs/adr/0004-architekturregeln-archunit.md)): keine Feld-Injection im Service. Urteil: Frontend.

### ARCH-8: Speicher gekapselt

- **Prinzip:** Wie und wo Daten gespeichert werden, bleibt hinter der fachlichen Schicht verborgen. Ein Wechsel der
  Speichertechnik ändert die Schnittstelle nach außen nicht.
- **Hier:** Die Datenhaltung (heute eine Map im Speicher in `OrderService`, ein fester Katalog in `ProductService`)
  ist nur im Paket `service` sichtbar. Ein Wechsel auf eine Datenbank braucht ein ADR (ARCH-10).
- **Prüft:** Urteil.

### ARCH-9: Querschnitt konfiguriert

- **Prinzip:** Querschnittsthemen wie Logging, Sicherheitseinstellungen, Serialisierung oder Cross-Origin-Regeln
  stehen an einer eigenen, benannten Stelle, nicht verstreut im Fachcode. Werte kommen aus der Konfiguration, Secrets
  nie aus dem Code.
- **Hier:** Eigene Konfigurationsklassen im Paket `web` (zum Beispiel `CorsConfig`). Werte kommen aus der
  Anwendungskonfiguration (zum Beispiel `app.cors.allowed-origin-patterns`). Ausgaben laufen über das Logging von
  Spring Boot, nicht über `System.out` oder `java.util.logging`. Keine Secrets im Repository (DoD-7).
- **Prüft:** Gate (ArchUnit, [ADR 0004](../../docs/adr/0004-architekturregeln-archunit.md)): keine Standard-Streams, kein `java.util.logging`. Urteil: der Rest.

### ARCH-10: Bausteine per ADR

- **Prinzip:** Jeder neue Baustein mit langfristiger Wirkung wird bewusst entschieden und begründet: neue Abhängigkeit,
  Persistenz, Authentifizierung, Zustandsmanagement, Messaging, neues Architekturmuster.
- **Hier:** ADR unter `docs/adr/` (Format wie ADR 0001) und Zusage des Owners im Issue. Build-Dateien und `gradle/` sind
  Schutzbereich (DoD-7, DoD-9).
- **Prüft:** Sperre (Build-Dateien), Urteil.

### ARCH-11: Einfach vor allgemein

- **Prinzip:** Gebaut wird die kleinste Lösung, die das Kriterium erfüllt. Keine Abstraktion auf Vorrat, keine zweite
  Schicht ohne zweiten Nutzer, keine Konfiguration für Fälle, die es noch nicht gibt.
- **Hier:** Eine neue Schnittstelle, Basisklasse oder Konfigurationsoption braucht einen heutigen zweiten Nutzer oder ein
  Kriterium im Issue. Die Ausnahme sind Abstraktionen für Testbarkeit (ARCH-12), zum Beispiel das abstrakte Repository.
- **Prüft:** Urteil.

### ARCH-12: Schichten einzeln testbar

- **Prinzip:** Jede Schicht lässt sich ohne die anderen testen. Abhängigkeiten nach außen werden im Test ersetzt.
- **Hier:** Die API wird über MockMvc gegen den Vertrag getestet (zum Beispiel `OrdersApiTest`). Repositories im
  Frontend werden gegen einen Stub der generierten API getestet (`api_products_repository_test.dart`), Widgets mit einem
  Fake des Repositorys (`widget_test.dart`). Siehe DoD-4.
- **Prüft:** Urteil.

## Pflege

- Änderungen nur durch den Owner, in einem eigenen PR mit Begründung.
- Wird ein Urteilspunkt wiederholt verletzt, prüfen wir, ob ein Gate ihn erzwingen kann (zum Beispiel eine
  ArchUnit-Regel). Das ist die Lernschleife, Roadmap P8.
- Kommt ein neues Projekt hinzu, bleibt das Prinzip, und nur „Hier“ wird neu geschrieben.
