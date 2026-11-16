# Standard: Dart und Flutter

Stackspezifische Regeln für Dart und Flutter, ergänzend zu den allgemeinen Punkten in [`code.md`](code.md). Hier steht
nur, was es ohne Gegenstück in anderen Sprachen gibt. Aufbau, Zitierweise (`DART-1: Futures beachtet`) und Pflege wie
in [`code.md`](code.md). Die Datei liegt im Schutzbereich `config/`. Die Linter-Regeln stehen in
`frontend/analysis_options.yaml` (Schutzbereich); die Grundlage ist `flutter_lints`, die hier genannten Regeln sind
dort zusätzlich ausdrücklich aktiviert.

## Punkte

### DART-1: Futures beachtet

- **Regel:** In `async`-Code wird jedes Future mit `await` abgewartet oder ausdrücklich mit `unawaited(…)` aus
  `dart:async` freigegeben.
- **Warum:** Ein vergessenes `await` lässt Fehler ins Leere laufen und macht die Reihenfolge zufällig. Gehört zu
  `CODE-4: Fehler sichtbar`.
- **Prüft:** Gate (Linter `unawaited_futures`).

### DART-2: Kontext nach await geprüft

- **Regel:** Nach einem `await` wird `BuildContext` nur benutzt, wenn vorher `mounted` geprüft ist.
- **Warum:** Das Widget kann während des Wartens verschwunden sein; dann führt der Zugriff zu Fehlern.
- **Prüft:** Gate (Linter `use_build_context_synchronously`).

### DART-3: Ressourcen freigegeben

- **Regel:** Controller, Streams und Abonnements, die ein Widget anlegt, gibt es in `dispose` wieder frei.
- **Warum:** Sonst laufen sie weiter, verbrauchen Speicher und melden Ereignisse an Widgets, die es nicht mehr gibt.
- **Prüft:** Gate für Streams (Linter `cancel_subscriptions`, `close_sinks`), sonst Urteil.

### DART-4: const und final bevorzugt

- **Regel:** Lokale Variablen und Felder sind `final`, wenn sie nicht neu zugewiesen werden. Unveränderliche Widgets
  und Werte sind `const`, wo es geht.
- **Warum:** `CODE-6: Unveränderlich bevorzugt`; `const` spart beim Neuzeichnen Arbeit.
- **Prüft:** Gate für `final` (Linter `prefer_final_locals`, `prefer_final_fields`) und für `const` in unveränderlichen
  Klassen (`prefer_const_constructors_in_immutables`); `const` sonst Urteil.
  `prefer_const_constructors` ist bewusst nicht aktiv: `flutter_lints` hat die Regel mit Version 5.0.0 entfernt.

### DART-5: Zustand nach ARCH-6

- **Regel:** Zustand und Abläufe folgen `ARCH-6: Logik nicht im Widget`: `setState` für einfachen Zustand, ein eigener
  `ChangeNotifier` für wachsenden Zustand, eine Bibliothek nur per ADR.
- **Warum:** Verweis statt Doppel, damit die Regel an einer Stelle steht (`CODE-3: Regel einmal`).
- **Prüft:** Urteil.
