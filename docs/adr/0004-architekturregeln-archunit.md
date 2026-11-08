# ADR 0004: Architekturregeln als Gate (ArchUnit)

- Status: akzeptiert
- Datum: 2026-11-08

## Kontext

Die Architekturprinzipien stehen in `config/standards/architektur.md` (ARCH-1 bis ARCH-12, Issue #195). Ohne Werkzeug
sind sie nur ein Urteil: Der Reviewer muss jeden Verstoß im Diff finden, und ein übersehener Verstoß landet in `main`.
Die Definition of Done verlangt, wiederkehrende Urteilsbefunde wo möglich ins Gate zu holen.

Der Owner hat am 08.11.2026 entschieden, ArchUnit einzuführen, „Stufe 1 und 2 jetzt“ (Issue #196). Das ist eine neue
Test-Abhängigkeit und braucht diese Zusage (ARCH-10, DoD-7).

## Entscheidung

- **Werkzeug:** ArchUnit als Test-Abhängigkeit des Service, Kern-Artefakt `com.tngtech.archunit:archunit` mit normalen
  JUnit-Tests. Damit ist es egal, welche JUnit-Version die Spring-Boot-BOM bringt. Version 1.5.1, Java 25 wird seit
  1.4.1 unterstützt. Dependabot hält die Version aktuell (Eintrag in `gradle/libs.versions.toml`).
- **Stufe 1 (Grundregeln):** ARCH-2 (`service` hängt nicht von `web` und Spring-HTTP ab), ARCH-4 (`ProblemDetail` nur in
  `web`), DoD-A2 (Controller in `web`, implementieren ein generiertes `*Api`-Interface), ARCH-7 (keine Feld-Injection).
- **Stufe 2 (allgemeine Regeln):** keine Zyklen zwischen Paketen (ARCH-2), keine Standard-Streams und kein
  `java.util.logging` (ARCH-9), keine generischen Exceptions (ARCH-4). Für das Frontend gibt es ArchUnit nicht. Dort
  prüft `frontend/tool/verify.sh` ARCH-5 mit `grep`, ohne neue Abhängigkeit (`package:order_api` nur in
  `lib/<feature>/*_repository.dart`).
- **Ausnahme:** Generierter Code (Paket `com.example.orderservice.api`) ist von den Regeln ausgenommen, er wird nie von
  Hand geändert (ARCH-1).
- **Meldungen:** Jede Regel nennt ihre Kennung (`because("ARCH-n …")`), damit ein roter Build direkt auf den Standard
  verweist.
- **Schutz:** Die Regeln liegen in einem eigenen Unterordner,
  `service/src/test/java/com/example/orderservice/architecture/`. Dieser Ordner und `service/src/test/resources/archunit*`
  sind Schutzbereich (`CODEOWNERS`, Deny-Regeln in `.claude/agent-settings.json`, Prüfung im Job `pruefung` von
  `agent-coder-revise.yml`). Grund: `archunit.properties` kann Prüfungen lockern (zum Beispiel `freeze.refreeze=true`),
  und ein Agent darf sein Gate nicht abschwächen ([ADR 0002](0002-agent-sicherheit.md)). Alle übrigen Tests schreibt
  der Coder weiter selbst.

## Konsequenzen

- Verstöße gegen ARCH-2, ARCH-4, ARCH-5, ARCH-7, ARCH-9 und DoD-A2 machen das Gate rot (jeweils der Teil, den die
  Regel prüft; der Rest bleibt Urteil). Der Reviewer muss sie nicht mehr suchen.
- Eine neue oder geänderte Regel ist ein Owner-PR. Wiederkehrende Review-Befunde werden so zu Regeln (Lernschleife P8).
- **Stufe 3 später:** gefrorene Regeln (`FreezingArchRule`) für Prinzipien, die bestehender Code noch verletzt. Ihr
  Speicher läge ebenfalls im Schutzbereich.
- Abnahme (08.11.2026, lokal mit JDK 25): Alle acht Regeln sind auf dem heutigen Stand grün. Ein Negativtest mit drei
  vorübergehenden Verstößen in `OrderService` (Spring-HTTP-Import, Feld-Injection, `System.out`) ließ genau die drei
  passenden Regeln rot werden, die Meldungen nannten ARCH-2, ARCH-7 und ARCH-11. Die Prüfung für das Frontend war auf
  dem heutigen Stand grün und mit einem eingebauten Import in `orders_page.dart` rot.
- Korrektur nach dem Review (Issue #196, 08.11.2026): Die Regel zu `System.out` gehört zu ARCH-9, nicht zu ARCH-11; der
  Negativtest meldet seither ARCH-9. Die Regel für Controller prüft zusätzlich die Endung `Api`. Die Frontend-Prüfung
  erlaubt den Client nur noch in `lib/<feature>/*_repository.dart` (genau eine Ordnerebene, wie DoD-A3).
