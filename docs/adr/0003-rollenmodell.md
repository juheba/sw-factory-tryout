# ADR 0003: Rollenmodell nach Phasen, Expertise als Linsen

- Status: akzeptiert
- Datum: 2026-11-07

## Kontext

Ziel des Owners ist, von einer eigenen Idee zu einer umgesetzten Anwendung zu gelangen. Unreife Ideen werden mit KI
aufbereitet, ausgereifte von KI umgesetzt. Das Ergebnis soll die Idee widerspiegeln und aktuellen Standards
entsprechen: Architekturprinzipien, Wartbarkeit, sauberer und sicherer Code, benutzerfreundliches Design.

Bis November 2026 deckten die Rollen vor allem die Strecke Issue → geprüfter PR ab (Coder, Reviewer; QA und Planer
als Entwurf). Es fehlten:

- eine Rolle für Idee → Konzept: Der Planer aus [📌 #128](https://github.com/juheba/sw-factory-tryout/issues/128) war
  technisch („baubar?“), nicht fachlich („was genau?“),
- Verantwortung für Architektur über mehrere Issues,
- UX: Niemand entwarf Abläufe oder prüfte Bedienbarkeit,
- ausdrückliche Maßstäbe für sauberen und sicheren Code und für Architektur, gegen die ein „Experte“ prüfen kann,
- eine Abgrenzung zwischen Reviewer und QA: Beide bewerteten DoD-4 und DoD-5.

Zudem meldete der Reviewer DoD-9 an jedem PR des Owners als blockierend, obwohl dort Änderungen an Schutzbereichen
gewollt sind.

## Entscheidung

Rollen werden nach **Phasen** geschnitten: Konzept, Plan, Umsetzung, Prüfung, Abnahme. Fachgebiete sind **Linsen**
innerhalb der Rollen, keine eigenen Agenten. Jede Linse bekommt einen Maßstab. Die Beschreibung der Rollen steht in
[`docs/rollen.md`](../rollen.md).

Entscheidungen des Owners vom 07.11.2026 ([📌 #184](https://github.com/juheba/sw-factory-tryout/issues/184)):

1. **🎯 Konzept ist interaktiv.** Der Owner schärft eine Idee im Dialog mit KI nach einer festen Vorlage. Es gibt
   dafür keinen Workflow.
2. **Standards liegen in `config/`.** Architekturprinzipien, Leitlinien für sauberen Code, die Sicherheits-Checkliste
   und die UX-Leitlinie sind Maßstab wie die DoD. Sie liegen im Schutzbereich, damit der Coder sie nicht absenken kann.
3. **UX ist eine Linse**, genutzt im Konzept (Entwurf) und von QA (Prüfung), keine eigene Rolle.
4. **DoD-4 und DoD-5 gehen an QA.** QA ordnet jedes Kriterium einem Test zu. Der Reviewer prüft nur noch, ob Tests
   vorhanden und nicht trivial sind.
5. **Die Prüfung von Issues geht an den Planer**, sobald es ihn gibt. Bis dahin bleibt sie beim Reviewer.
6. **DoD-9 bei PRs des Owners:** Der Reviewer meldet „Owner-Freigabe nötig“ statt „blockierend“, wenn ein PR im
   Auftrag des Owners Schutzbereiche ändert. Woran er das sicher erkennt, ist noch offen.
7. **Reihenfolge:** zuerst Standards und Konzept-Vorlage, dann ein Pilot mit einer echten Idee, danach QA und Planer.

Unverändert gilt: Issues legt nur der Owner an, und nur Issues des Owners starten den Coder
([ADR 0002](0002-agent-sicherheit.md)). Der Planer liefert Entwürfe.

## Konsequenzen

- Die Qualität des Ergebnisses hängt zuerst an Konzept und Akzeptanzkriterien. Aufwand verlagert sich nach vorn.
- Neue Pflege: Standards unter `config/` brauchen Owner-PRs. Prompts von Reviewer, QA und Coder verweisen darauf.
- Weniger Agenten als Fachgebiete: weniger Läufe, Prompts und Kommentare. Dafür muss eine Rolle mehrere Linsen
  sauber trennen.
- Die Abnahme misst am Konzept. Dafür braucht der Owner eine laufende Vorschau der App am PR (Roadmap X4).
- Umsetzung über Folge-Issues: Konzept-Vorlage (P12), Standards (P13), App-Vorschau (X4), Pilot (W2), DoD-9-Status,
  Zuschnitt von QA ([📌 #125](https://github.com/juheba/sw-factory-tryout/issues/125)) und Planer
  ([📌 #128](https://github.com/juheba/sw-factory-tryout/issues/128)).
