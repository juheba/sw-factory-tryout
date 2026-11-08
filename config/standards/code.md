# Standard: Sauberer Code

Maßstab der Linse **sauberer Code** ([ADR 0003](../../docs/adr/0003-rollenmodell.md), [Rollen](../../docs/rollen.md)).
Der Coder baut danach, der Reviewer prüft danach. Die Datei liegt im Schutzbereich `config/`: Agents lesen sie,
Änderungen macht der Owner in einem eigenen PR mit Begründung. Reviewer und QA lesen die Fassung aus `main`.

Hier stehen die **allgemeinen** Punkte, die für jede Sprache gelten. Regeln, die es nur in einem Stack gibt, stehen in
[`code-java.md`](code-java.md) (`JAVA-n`) und [`code-dart.md`](code-dart.md) (`DART-n`). Architektur (Schichten,
Abhängigkeiten) steht in [`architektur.md`](architektur.md), Sicherheit und UX bekommen eigene Standards.

**Aufbau je Punkt:** **Prinzip** (allgemein), **Hier (Java)** und **Hier (Dart)** (Umsetzung in diesem Repo),
**Prüft** wie in der [Definition of Done](../definition-of-done.md): **Gate** (der Build erzwingt es), **Sperre** oder
**Urteil**. Jeder Punkt hat Kennung und Kurzname und wird als `CODE-4: Fehler sichtbar` zitiert. Die Kennung bleibt
stabil. **Sprache:** Bezeichner englisch, Kommentare und Testbeschreibungen dürfen deutsch sein (`CLAUDE.md`).

## Punkte

### CODE-1: Namen sprechend

- **Prinzip:** Namen sagen, was etwas ist oder tut, in der Sprache der Fachlichkeit. Abkürzungen nur, wenn sie im Fach
  üblich sind.
- **Hier (Java):** Klassen sind Substantive (`OrderService`), Methoden Verben (`cancel`), Testmethoden beschreiben das
  Verhalten (`listsOnlyCancelledOrdersWithStatusCancelled`).
- **Hier (Dart):** Widgets und Modelle sind Substantive (`OrdersPage`, `OrderSummary`), private Bezeichner mit `_`,
  Testbeschreibungen nennen das erwartete Verhalten („zeigt Fehlermeldung, wenn Stornieren fehlschlägt“).
- **Prüft:** Urteil. Namenskonventionen der Sprache erzwingen die Linter teilweise.

### CODE-2: Einheiten klein

- **Prinzip:** Eine Methode tut eine Sache, eine Klasse hat eine Aufgabe. Wächst eine Einheit, wird sie geteilt, bevor
  sie unübersichtlich wird.
- **Hier (Java):** Methoden höchstens 40 Zeilen ohne Leerzeilen und Kommentare. Dateien richtwertig bis etwa 300 Zeilen.
- **Hier (Dart):** `build`-Methoden teilen, sobald sie mehrere Bereiche enthalten (eigene Widgets oder private
  Methoden). Dateien richtwertig bis etwa 300 Zeilen.
- **Prüft:** Gate für Java (Checkstyle `MethodLength`, `max` 40, `countEmpty` false), sonst Urteil.

### CODE-3: Regel einmal

- **Prinzip:** Jede fachliche Regel steht an genau einer Stelle. Wer sie ändern muss, findet sie dort und nur dort.
- **Hier (Java):** Regeln im Paket `service`, nicht zusätzlich im Controller (`ARCH-2: Abhängigkeiten nach innen`).
- **Hier (Dart):** Abbildung und Prüfung im Repository oder in einer eigenen Einheit, nicht im Widget
  (`ARCH-6: Logik nicht im Widget`).
- **Prüft:** Urteil.

### CODE-4: Fehler sichtbar

- **Prinzip:** Kein Fehler wird verschluckt. Ein Fehler wird behandelt, weitergegeben oder ausdrücklich begründet
  ignoriert.
- **Hier (Java):** kein leerer `catch` ohne Kommentar; fachliche Fehler als eigene Exceptions
  (`ARCH-4: Fehler innen, Format außen`).
- **Hier (Dart):** kein leerer `catch`; Repositories werfen typisierte Exceptions (zum Beispiel
  `OrderRejectedException`), die UI zeigt eine verständliche Meldung (`DoD-B1: Keine Logik im Widget`).
- **Prüft:** Gate (Checkstyle `EmptyCatchBlock`; Linter `empty_catches`), sonst Urteil.

### CODE-5: Fehlen ausdrücklich

- **Prinzip:** Ob ein Wert fehlen darf, sieht man an seinem Typ, nicht an einer Konvention.
- **Hier (Java):** Rückgaben, die leer sein können, als `Optional`; Services geben kein `null` zurück (siehe
  `JAVA-1: Optional nur als Rückgabe`).
- **Hier (Dart):** Null-Safety; `?` nur, wo ein Wert wirklich fehlen darf; `!` nur mit Begründung im Kommentar.
- **Prüft:** Urteil.

### CODE-6: Unveränderlich bevorzugt

- **Prinzip:** Was sich nicht ändern muss, ist unveränderlich. Das macht Code leichter zu lesen und schwerer falsch zu
  benutzen.
- **Hier (Java):** `final`-Felder, `record` für Werte (`JAVA-2: Records für Werte`), keine veränderbaren internen
  Listen nach außen (`JAVA-3: Unveränderliche Rückgaben`).
- **Hier (Dart):** `final` für lokale Variablen und Felder, `const` wo möglich (`DART-4: const und final bevorzugt`).
- **Prüft:** Gate für Dart (Linter `prefer_final_locals`, `prefer_final_fields`), sonst Urteil.

### CODE-7: Format automatisch

- **Prinzip:** Formatierung erledigt ein Werkzeug, nicht das Review. Über Formatierung wird nicht diskutiert.
- **Hier (Java):** Checkstyle (Zeilenlänge 120, keine Tabs, keine Leerzeichen am Zeilenende, Imports).
- **Hier (Dart):** `dart format`.
- **Prüft:** Gate.

### CODE-8: Kommentar erklärt Warum

- **Prinzip:** Kommentare erklären Gründe und Zusammenhänge, nicht das, was der Code ohnehin sagt. Kein auskommentierter
  Code.
- **Hier (Java):** Ein `TODO` oder `FIXME` nennt sein Issue (`TODO #123 …`). Javadoc für öffentliche Klassen mit nicht
  offensichtlicher Aufgabe.
- **Hier (Dart):** dasselbe für `TODO`; Doku-Kommentare `///` für öffentliche Klassen der Repositories.
- **Prüft:** Gate für Java (Checkstyle `TodoComment`, Muster „TODO oder FIXME ohne `#<nr>`“), sonst Urteil.

### CODE-9: Tests lesbar

- **Prinzip:** Ein Test prüft ein Verhalten, steht für sich und braucht kein Netz. Man sieht ihm an: Vorbereiten,
  Ausführen, Prüfen.
- **Hier (Java):** MockMvc gegen den Vertrag, Prüfungen mit AssertJ bzw. `jsonPath`, Daten je Test frisch.
- **Hier (Dart):** Fakes statt echter Dienste (`FakeOrdersRepository`, Stub der generierten API), `expect` mit
  Findern, jeder Test baut sein Widget neu.
- **Prüft:** Urteil (siehe auch `DoD-4: Tests mit Fehlerfall`).

### CODE-10: Nichts Totes

- **Prinzip:** Kein ungenutzter Code, keine Debug-Reste, keine auskommentierten Blöcke.
- **Hier (Java):** keine ungenutzten Imports, kein `System.out` (`ARCH-9: Querschnitt konfiguriert`).
- **Hier (Dart):** kein `print`, keine ungenutzten Imports und Variablen.
- **Prüft:** Gate (Checkstyle `UnusedImports`, ArchUnit Standard-Streams; Linter `avoid_print` und die Warnungen des
  Analyzers), sonst Urteil.

### CODE-11: Werte benannt

- **Prinzip:** Fachliche Werte haben einen Namen. Eine Zahl oder ein Text mit Bedeutung steht nicht verstreut im Code.
- **Hier (Java):** Konstanten oder Enums (zum Beispiel generierte Enums wie `OrderStatus`).
- **Hier (Dart):** Konstanten oder Enums; Texte der Oberfläche an einer Stelle je Bildschirm.
- **Prüft:** Urteil.

### CODE-12: Plattform vor Eigenbau

- **Prinzip:** Was Sprache, Standardbibliothek oder Framework schon können, wird nicht nachgebaut.
- **Hier (Java):** Java-API und Spring (zum Beispiel `ProblemDetail`, Validierung) vor eigenen Hilfsklassen.
- **Hier (Dart):** Flutter-Widgets und `dart:` Bibliotheken vor eigenen Lösungen.
- **Prüft:** Urteil (siehe auch `DoD-7: Keine ungeplanten Abhängigkeiten`).

## Pflege

- Änderungen nur durch den Owner, in einem eigenen PR mit Begründung.
- Kennungen bleiben stabil; ein neuer Punkt bekommt die nächste freie Nummer.
- Wird ein Urteilspunkt wiederholt verletzt, prüfen wir, ob ein Gate ihn erzwingen kann (Lernschleife P8).
