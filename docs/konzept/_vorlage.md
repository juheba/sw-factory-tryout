# Konzept: <Name der Idee>

<!--
Vorlage für ein Konzept (🎯 Konzept, docs/rollen.md). Kopieren nach docs/konzept/<idee>.md und ausfüllen.

Ein Konzept lebt: Es wächst in Ausbaustufen und wird nach jeder umgesetzten Stufe nachgeführt. Neu geplant wird nur
der Unterschied, nicht das ganze Projekt (docs/process.md, „Neue Ideen und Änderungen: drei Wege“).

Kennungen: Abläufe A-n, Bildschirme S-n, Funktionen F-n, Hypothesen H-n, offene Fragen Q-n. Jede Kennung hat einen
Kurznamen und wird als „Kennung: Kurzname“ zitiert, zum Beispiel „A-3: Bestellung stornieren“. Kennungen bleiben stabil
und werden nie neu vergeben, auch nicht für gestrichene Bausteine (dann „gestrichen am …“ dazuschreiben).

Reif ist ein Konzept, wenn es den Maßstab config/standards/konzept.md (KON-1 bis KON-8) für die nächste Stufe erfüllt.
Unklares bleibt erlaubt, wenn es als Hypothese oder offene Frage dasteht.
-->

## 0. Steckbrief

| | |
|---|---|
| Idee in einem Satz | … |
| Aktuelle Stufe | Stufe 1 |
| Stand | Entwurf / reif für Stufe n / Stufe n umgesetzt |
| Zuletzt geändert | JJJJ-MM-TT |

## 1. Problem und Ziel

- **Problem:** Was ist heute schwierig, umständlich oder unmöglich, und für wen?
- **Ziel:** Was ist nach der Umsetzung anders? Prüfbar formuliert („Ich sehe auf einen Blick, welche … offen sind“),
  nicht „besser“ oder „einfacher“ (`KON-1: Ziel prüfbar`).

## 2. Nutzer und Kontext

- **Wer:** Rollen in zwei, drei Sätzen.
- **Wo und wie oft:** Gerät, Situation, Häufigkeit.

## 3. Hypothesen

Annahmen, die noch nicht belegt sind. Jede Stufe soll mindestens eine davon bestätigen oder widerlegen.

| Kennung | Kurzname | Wir glauben … | Das zeigt sich an … | Stufe | Ergebnis |
|---|---|---|---|---|---|
| H-1 | … | … | … | 1 | offen |

## 4. Kernabläufe

### A-1: <Kurzname>

- **Auslöser:** …
- **Schritte** (aus Sicht des Nutzers): 1. … 2. … 3. …
- **Ergebnis:** …
- **Abnahme:** Woran erkennt man, dass der Ablauf funktioniert? (`KON-3: Abläufe abnehmbar`)
- **Stufe:** 1

## 5. Funktionen

| Kennung | Kurzname | Umfang | Stufe | Gehört zu |
|---|---|---|---|---|
| F-1 | … | Muss | 1 | A-1 |
| F-2 | … | Kann | 2 | A-1 |
| F-3 | … | Nicht | – | bewusst ausgeschlossen, weil … |

„Nicht“ steht hier, damit niemand es erfindet (`KON-2: Umfang getrennt`).

## 6. Bildschirme

### S-1: <Kurzname>

- **Zweck:** …
- **Inhalte:** …
- **Aktionen:** …
- **Zustände** (`KON-4: Zustände vollständig`):
  - leer: …
  - lädt: …
  - Fehler: …
  - Erfolg: …
- **Barrierefreiheit:** Bedienung per Tastatur, Kontraste, Beschriftungen, falls etwas Besonderes gilt.
- **Stufe:** 1

## 7. Daten und Regeln

- **Fachliche Objekte:** Name, wichtigste Felder (grob, nicht technisch).
- **Regeln:** Pflichtfelder, Grenzen, erlaubte Übergänge (zum Beispiel „storniert ist endgültig“).
- **Personenbezogene Daten:** ja oder nein, welche, wie lange (`KON-5: Daten benannt`).

## 8. Grenzen

- **Plattform:** Web, Mobil, beides.
- **Anbindungen:** andere Systeme, Konten, Dienste.
- **Sicherheit und Tempo:** wer darf was, wie schnell muss es sein, wie viel kommt zusammen (`KON-6: Grenzen benannt`).

## 9. Ausbaustufen

| Stufe | Ziel | Umfang (Kennungen) | Status | Issues und PRs |
|---|---|---|---|---|
| 1 | kleinster brauchbarer Kern | A-1, S-1, F-1 | geplant | – |
| 2 | … | … | Idee | – |

Status: Idee, geplant, in Arbeit, umgesetzt. Spätere Stufen dürfen Stichpunkte bleiben, bis sie dran sind.

## 10. Offene Fragen

| Kennung | Frage | Optionen | Empfehlung | Entscheidung |
|---|---|---|---|---|
| Q-1 | … | a) … b) … | … | offen / am JJJJ-MM-TT: … |

Fragen, die den Muss-Umfang der nächsten Stufe betreffen, sind vor „reif“ entschieden (`KON-7: Keine offenen
Muss-Fragen`).

## 11. Abnahme gegen die Idee

Zwei oder drei Szenarien, die der Owner am Ende in der laufenden App durchklickt:

1. …

## 12. Änderungsprotokoll

| Datum | Stufe | Was | Warum |
|---|---|---|---|
| JJJJ-MM-TT | 1 | Konzept angelegt | … |
