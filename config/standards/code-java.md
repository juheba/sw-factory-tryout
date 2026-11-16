# Standard: Java

Stackspezifische Regeln für Java und Spring, ergänzend zu den allgemeinen Punkten in [`code.md`](code.md). Hier steht
nur, was es ohne Gegenstück in anderen Sprachen gibt. Aufbau, Zitierweise (`JAVA-1: Optional nur als Rückgabe`) und
Pflege wie in [`code.md`](code.md). Die Datei liegt im Schutzbereich `config/`.

## Punkte

### JAVA-1: Optional nur als Rückgabe

- **Regel:** `Optional` steht nur als Rückgabetyp, nicht als Feld, Parameter oder Element einer Sammlung.
- **Warum:** `Optional` beschreibt „Ergebnis kann fehlen“. Als Feld oder Parameter macht es den Code umständlich und
  kann selbst `null` sein. Gehört zu `CODE-5: Fehlen ausdrücklich`.
- **Prüft:** Urteil.

### JAVA-2: Records für Werte

- **Regel:** Reine Werte ohne eigenes Verhalten (Ergebnisse, Schlüssel, Zwischenstände) sind `record`.
- **Warum:** unveränderlich, `equals` und `hashCode` stimmen von selbst. Gehört zu `CODE-6: Unveränderlich bevorzugt`.
  Generierte Modelle aus der Spec bleiben, wie der Generator sie erzeugt (`ARCH-3: Modelle an der Grenze`).
- **Prüft:** Urteil.

### JAVA-3: Unveränderliche Rückgaben

- **Regel:** Methoden geben keine veränderbaren internen Sammlungen heraus. Rückgabe als Kopie (`List.copyOf`) oder als
  unveränderliche Sicht.
- **Warum:** Sonst kann ein Aufrufer den inneren Zustand eines Service ändern, ohne dass der Service es merkt.
- **Prüft:** Urteil.

### JAVA-4: Ungeprüfte fachliche Exceptions

- **Regel:** Fachliche Fehler im Paket `service` sind ungeprüfte Exceptions (`RuntimeException` als Basis), mit
  sprechendem Namen. Keine `throws Exception` in Signaturen.
- **Warum:** Der `GlobalExceptionHandler` bildet sie an einer Stelle ab (`ARCH-4: Fehler innen, Format außen`); geprüfte
  Exceptions zwängen jeden Aufrufer zu leerem Weiterreichen.
- **Prüft:** Gate für generische Exceptions (ArchUnit, ADR 0004), sonst Urteil.

### JAVA-5: Streams lesbar

- **Regel:** Ein Stream bleibt lesbar: keine Lambdas über mehrere Ebenen ineinander, keine Seiteneffekte in `map` oder
  `filter`. Wird es verschachtelt, kommt eine benannte Methode.
- **Warum:** `CODE-1: Namen sprechend` und `CODE-2: Einheiten klein` gelten auch innerhalb eines Streams.
- **Prüft:** Urteil.
