# Standard: Konzept ist reif

Maßstab für den Übergang von der Konzeptphase zum Plan ([ADR 0003](../../docs/adr/0003-rollenmodell.md),
[Rollen](../../docs/rollen.md), Abschnitt „🎯 Konzept“). Der Owner prüft danach, ob ein Konzept bereit für die nächste
Stufe ist; später prüft der Planer ein Konzept danach, bevor er Issues schneidet. Die Vorlage für Konzepte liegt unter
[`docs/konzept/_vorlage.md`](../../docs/konzept/_vorlage.md). Die Datei liegt im Schutzbereich `config/`: Agents lesen
sie, Änderungen macht der Owner in einem eigenen PR mit Begründung.

**Reif heißt reif für die nächste Stufe, nicht vollständig.** Ideen sind am Anfang oft schwammig, und nach jeder Stufe
kommen neue dazu. Unklares ist erlaubt, wenn es als Hypothese (`H-n`) oder offene Frage (`Q-n`) im Konzept steht und
den Muss-Umfang der nächsten Stufe nicht betrifft.

**Aufbau je Punkt** wie bei der [Architektur](architektur.md): **Prinzip** (allgemein), **Hier** (Umsetzung in diesem
Repo), **Prüft** (Gate, Sperre oder Urteil). Jeder Punkt hat Kennung und Kurzname und wird als
`KON-3: Abläufe abnehmbar` zitiert. Die Kennung bleibt stabil.

## Punkte

### KON-1: Ziel prüfbar

- **Prinzip:** Das Ziel ist so formuliert, dass man nach der Umsetzung entscheiden kann, ob es erreicht ist.
  „Besser“, „einfacher“ oder „schneller“ ohne Bezugspunkt reichen nicht.
- **Hier:** Abschnitt 1 der Vorlage („Problem und Ziel“).
- **Prüft:** Urteil.

### KON-2: Umfang getrennt

- **Prinzip:** Für die nächste Stufe ist getrennt, was sein muss, was sein kann und was bewusst nicht gebaut wird. Der
  Muss-Umfang ist klein genug für einen ersten Wurf, der sich ausprobieren lässt.
- **Hier:** Abschnitt 5 („Funktionen“, Spalte „Umfang“) und Abschnitt 9 („Ausbaustufen“).
- **Prüft:** Urteil.

### KON-3: Abläufe abnehmbar

- **Prinzip:** Jeder Kernablauf der nächsten Stufe hat ein Abnahmekriterium aus Sicht des Nutzers.
- **Hier:** Abschnitt 4, je Ablauf `A-n` die Zeile „Abnahme“. Diese Kriterien werden zu Akzeptanzkriterien der Issues;
  QA prüft dagegen ([📌 #125](https://github.com/juheba/sw-factory-tryout/issues/125)).
- **Prüft:** Urteil.

### KON-4: Zustände vollständig

- **Prinzip:** Jeder Bildschirm der nächsten Stufe beschreibt, was der Nutzer sieht, wenn nichts da ist, während etwas
  lädt, wenn ein Fehler auftritt und nach Erfolg.
- **Hier:** Abschnitt 6, je Bildschirm `S-n` die Zustände leer, lädt, Fehler und Erfolg (UX-Linse).
- **Prüft:** Urteil.

### KON-5: Daten benannt

- **Prinzip:** Die fachlichen Objekte und ihre Regeln sind benannt. Ob personenbezogene Daten anfallen, ist geklärt.
- **Hier:** Abschnitt 7 („Daten und Regeln“).
- **Prüft:** Urteil.

### KON-6: Grenzen benannt

- **Prinzip:** Plattform, Anbindungen an andere Systeme und die Anforderungen an Sicherheit und Tempo stehen fest,
  soweit sie die nächste Stufe betreffen.
- **Hier:** Abschnitt 8 („Grenzen“). Ein neuer Baustein (zum Beispiel Anmeldung, Datenbank) braucht ein ADR
  (`ARCH-10: Bausteine per ADR`).
- **Prüft:** Urteil.

### KON-7: Keine offenen Muss-Fragen

- **Prinzip:** Alle Fragen, die den Muss-Umfang der nächsten Stufe betreffen, sind entschieden. Andere Fragen dürfen
  offen bleiben, wenn sie dastehen.
- **Hier:** Abschnitt 10 („Offene Fragen“), Spalte „Entscheidung“.
- **Prüft:** Urteil.

### KON-8: Stand nachgeführt

- **Prinzip:** Nach jeder umgesetzten Stufe spiegelt das Konzept den gebauten Stand: Status der Stufe, geänderte oder
  gestrichene Bausteine, bestätigte oder widerlegte Hypothesen. Eine Folgesitzung beginnt sonst auf falscher Grundlage.
- **Hier:** Abschnitte 3, 9 und 12 der Vorlage; die PRs der Stufe aktualisieren das Konzept (`DoD-8: Doku aktuell`).
- **Prüft:** Urteil.

## Pflege

- Änderungen nur durch den Owner, in einem eigenen PR mit Begründung.
- Kennungen bleiben stabil; ein neuer Punkt bekommt die nächste freie Nummer.
- Zeigt eine Konzeptsitzung, dass ein Punkt fehlt oder stört, kommt die Änderung in diese Datei (Lernschleife P8).
