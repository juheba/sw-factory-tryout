# Standard: UX

Maßstab der Linse **UX** ([ADR 0003](../../docs/adr/0003-rollenmodell.md), [Rollen](../../docs/rollen.md)). Das Konzept
entwirft danach, der Coder baut danach, Reviewer und QA prüfen danach. Die Datei liegt im Schutzbereich `config/`:
Agents lesen sie, Änderungen macht der Owner in einem eigenen PR mit Begründung. Reviewer und QA lesen die Fassung aus
`main`.

**Zielniveau:** [WCAG 2.2](https://www.w3.org/TR/WCAG22/), Stufe AA. Wo ein Punkt ein Erfolgskriterium betrifft, steht
es unter **Quelle**. Hier steht die Oberfläche (Frontend). Die Fehlerformate der API regeln
`ARCH-4: Fehler innen, Format außen` und `SEC-2: Fehler ohne Interna`.

**Aufbau je Punkt:** **Prinzip** (allgemein), **Hier** (Umsetzung in diesem Repo), **Quelle**, **Prüft** wie in der
[Definition of Done](../definition-of-done.md): **Gate** (der Build erzwingt es), **Sperre** oder **Urteil**. Zitiert
wird Kennung und Kurzname, zum Beispiel `UX-1: Vier Zustände je Ansicht`. Die Kennung bleibt stabil.

## Punkte

### UX-1: Vier Zustände je Ansicht

- **Prinzip:** Jede Ansicht, die Daten lädt, hat vier gestaltete Zustände: lädt, leer, Fehler, Daten. Kein Zustand
  zeigt eine leere Fläche ohne Erklärung.
- **Hier:** `FutureBuilder` mit Ladeanzeige, Hinweis bei leerer Liste („Noch keine Bestellungen.“), Fehlertext und
  Daten. Erfolgs- und Fehlerzustand haben je einen Widget-Test (`DoD-B1: Keine Logik im Widget`).
- **Prüft:** Urteil, Widget-Tests.

### UX-2: Fehler verständlich

- **Prinzip:** Eine Fehlermeldung sagt in der Sprache der Nutzer, was passiert ist und was sie tun können. Technische
  Texte (Exceptions, Stacktraces, Statuscodes) erscheinen nicht.
- **Hier:** Fachliche Meldungen kommen aus dem `detail` der Problem-Details (`parseProblemDetail`). Fehlt es, steht
  ein fester, verständlicher Text da, nie `toString()` eines Fehlers.
- **Quelle:** WCAG 2.2, 3.3.1 Error Identification, 3.3.3 Error Suggestion.
- **Prüft:** Urteil, Widget-Tests für den Fehlerzustand.

### UX-3: Rückmeldung auf jede Aktion

- **Prinzip:** Jede Aktion zeigt sofort, dass sie angekommen ist, und am Ende, ob sie gelungen ist. Während sie läuft,
  kann sie nicht doppelt ausgelöst werden.
- **Hier:** SnackBar für Erfolg und Fehler, Aktualisieren der Liste nach dem Anlegen oder Stornieren.
- **Quelle:** WCAG 2.2, 4.1.3 Status Messages.
- **Prüft:** Urteil, Widget-Tests.

### UX-4: Sprache einheitlich

- **Prinzip:** Ein Begriff bedeutet überall dasselbe, und dieselbe Sache heißt überall gleich. Texte sind kurz und in
  einer Sprache.
- **Hier:** Oberfläche auf Deutsch, feste Begriffe (Bestellung, Aktiv, Storniert, Artikelnummer). Texte eines
  Bildschirms stehen an einer Stelle (`CODE-11: Werte benannt`).
- **Quelle:** WCAG 2.2, 3.2.4 Consistent Identification.
- **Prüft:** Urteil.

### UX-5: Bedienelemente benannt

- **Prinzip:** Jedes Bedienelement hat einen zugänglichen Namen, auch wenn es nur ein Symbol zeigt. Ein Screenreader
  liest vor, was es tut.
- **Hier:** `IconButton` und `FloatingActionButton` mit `tooltip`, Bilder mit `semanticLabel`.
- **Quelle:** WCAG 2.2, 1.1.1 Non-text Content, 4.1.2 Name, Role, Value.
- **Prüft:** Urteil. Gate, sobald ein Widget-Test `meetsGuideline(labeledTapTargetGuideline)` aus `flutter_test`
  prüft.

### UX-6: Ziele groß genug

- **Prinzip:** Tippflächen sind groß genug und weit genug auseinander, damit man sie sicher trifft.
- **Hier:** Material-Widgets mit ihrer Standardgröße (48 dp), keine verkleinerten Tippflächen.
- **Quelle:** WCAG 2.2, 2.5.8 Target Size (Minimum).
- **Prüft:** Urteil. Gate, sobald ein Widget-Test `meetsGuideline(androidTapTargetGuideline)` und
  `meetsGuideline(iOSTapTargetGuideline)` prüft.

### UX-7: Farbe nicht allein

- **Prinzip:** Information steckt nie nur in der Farbe. Text hat genug Kontrast zum Hintergrund.
- **Hier:** Status als Text („Storniert“-Chip), nicht nur als Farbe. Farben aus dem `ColorScheme` des Themes.
- **Quelle:** WCAG 2.2, 1.4.1 Use of Color, 1.4.3 Contrast (Minimum).
- **Prüft:** Urteil. Für den Kontrast Gate, sobald ein Widget-Test `meetsGuideline(textContrastGuideline)` prüft.

### UX-8: Text skalierbar

- **Prinzip:** Die Oberfläche bleibt bei vergrößerter Schrift bedienbar, ohne dass Text abgeschnitten wird.
- **Hier:** Keine festen Höhen für Text, Listen und `ListTile` statt fester Layouts, Schriftgröße aus dem Theme.
- **Quelle:** WCAG 2.2, 1.4.4 Resize Text.
- **Prüft:** Urteil.

### UX-9: Design-System statt Eigenbau

- **Prinzip:** Die Oberfläche nutzt die Bausteine eines Design-Systems. Eigene Bausteine entstehen nur, wenn es keinen
  passenden gibt.
- **Hier:** Material 3 aus `material_ui`, ein zentrales `ThemeData` in `main.dart`
  (`CODE-12: Plattform vor Eigenbau`).
- **Prüft:** Urteil.

### UX-10: Folgenreiches umkehrbar oder bestätigt

- **Prinzip:** Eine Aktion, die sich nicht rückgängig machen lässt, wird vorher bestätigt oder lässt sich kurz danach
  rückgängig machen.
- **Hier:** Stornieren einer Bestellung ist endgültig und braucht deshalb eine Bestätigung.
- **Quelle:** WCAG 2.2, 3.3.4 Error Prevention (Legal, Financial, Data), sinngemäß übertragen.
- **Prüft:** Urteil.

## Pflege

- Änderungen nur durch den Owner, in einem eigenen PR mit Begründung.
- Kennungen bleiben stabil; ein neuer Punkt bekommt die nächste freie Nummer.
- Erscheint eine neue Fassung der WCAG, werden die Bezüge unter **Quelle** geprüft.
- Wird ein Urteilspunkt wiederholt verletzt, prüfen wir, ob ein Gate ihn erzwingen kann (Lernschleife P8).
