# Roadmap der Software-Factory

Stand: 24.10.2026 (letzte vollständige Durchsicht durch den Owner). Diese Datei ist die langfristige Sicht auf Ausbau, Betrieb und Absicherung der Factory. Die
Stufen selbst beschreibt [process.md](process.md), die Entscheidungen stehen in den [ADRs](adr/).

**Pflege:** Wer einen Punkt umsetzt, ändert Status und Verweis im selben PR. Wird ein Punkt konkret, bekommt er ein
GitHub-Issue (Vorlage „Agent-Auftrag“ oder frei) und seine ID im Titel, zum Beispiel `[P2] Review-Schleife`. Diese
Datei hält fest, **was** und **warum** gilt, die Issues halten fest, **wer gerade woran** arbeitet.

**Erinnerungen:** Der Workflow `housekeeping.yml` legt jeden Montag bei Bedarf ein Issue an, wenn der Stand älter als
30 Tage ist oder ein Zugang (`.github/ablaufdaten.json`) in höchstens 30 Tagen abläuft. Agent-PRs aktualisieren nur den
Status ihres Punkts (Regel in `CLAUDE.md`), das Datum bei `Stand:` setzt der Owner bei der Durchsicht.

Status: ✅ erledigt, ⚠️ in Arbeit, ⬜ offen, ❓ zu bewerten (noch nicht entschieden, ob und wann).

## Überblick

```mermaid
flowchart LR
    S1[Stufe 1: manuell<br/>erledigt] --> S2[Stufe 2: Label startet Lauf<br/>läuft, Abnahme bestanden]
    S2 --> RV[Review-Schleife<br/>und Selbstheilung]
    RV --> S3[Stufe 3: Rollen<br/>Planer, Umsetzer, Reviewer]
    S3 --> S4[Stufe 4: Orchestrator<br/>Agent SDK]
    S4 --> S5[Stufe 5: eigenes<br/>Factory-Repo]
    SEC[Querschnitt: Sicherheit] -.-> S2
    SEC -.-> S3
    OPS[Querschnitt: Betrieb und Messung] -.-> S2
    OPS -.-> S4
    classDef done fill:#d4edda,stroke:#2d6a3e,color:#1f2328
    classDef active fill:#fff3cd,stroke:#8a6d1c,color:#1f2328
    classDef planned fill:#eef0f3,stroke:#6b7280,color:#1f2328
    class S1,S2 done
    class RV active
    class S3,S4,S5,SEC,OPS planned
```

## Stufen

| ID | Punkt | Status | Nächster Schritt / Verweis |
|---|---|---|---|
| E1 | Stufe 1: manueller Lauf mit CI-Gate | ✅ erledigt | – |
| E2 | Stufe 2: Label `agent` startet den Lauf | ✅ erledigt | Abnahme bestanden (ADR 0002, „Stand der Abnahme“). ADR 0002 ist seit 24.10.2026 „akzeptiert“. |
| E3 | Stufe 3: Rollen (Planer, Umsetzer, Reviewer) | ❓ zu bewerten | Erst nach der Review-Schleife. Das Vorab-Review (P4) ist ein kleiner Vorgriff. |
| E4 | Stufe 4: eigener Orchestrator mit Agent SDK | ❓ zu bewerten | Setzt E3 und Messwerte (M1) voraus. |
| E5 | Stufe 5: eigenes Repo `sw-factory` | ❓ zu bewerten | Vorher klären, was projektspezifisch und was generisch ist (W1). |

## Prozess und Review

| ID | Punkt | Status | Nächster Schritt / Verweis |
|---|---|---|---|
| P1 | Rückmeldekanal bei verbotenem Auftrag | ✅ erledigt | Kommentar im Issue (Issue #33, PR #32). |
| P2 | Review-Schleife per Kommentar `/agent …` | ✅ erledigt | Abgenommen (ADR 0002, „Ergebnisse der Review-Schleife“): Normalfall, Schutzbereich mit Ablehnungskommentar und Obergrenze bestanden. Der Test mit fremdem Konto entfällt (braucht Zweitkonto). Weiter mit P3 und M3. |
| P3 | Selbstheilung bei roter CI | ⬜ offen | Abwandlung von `examples/ci-failure-auto-fix.yml` der Action: nur `agent/*`-PRs, Run-ID statt Logs im Prompt, Obergrenze, Freigabe. |
| P4 | Vorab-Review durch einen zweiten, schreibgeschützten Lauf | ❓ zu bewerten | Zuerst manuell `/code-review` lokal ausprobieren. Plugin-Variante: Pin- und Environment-Frage klären. |
| P5 | Rückfrage statt Raten bei mehrdeutigen Kriterien | ⚠️ in Arbeit | Gebaut (Issue #68): Regel in `CLAUDE.md` („Wenn etwas unklar ist“) und Schritt 8 im Prompt von `agent.yml`: bei deutlich mehrdeutigen Kriterien Fragen als Kommentar ins Issue, kein PR, der Owner antwortet und setzt das Label erneut. Ungetestet: Test mit einem bewusst mehrdeutigen Issue. Der Agent hat den Auftrag selbst zu Recht abgelehnt (Schutzbereiche), deshalb vom Owner-Assistenten gebaut. |
| P6 | Konflikte mit `main` | ✅ erledigt | Gebaut (Issue #69). Erster Test (PR #80, Lauf 40372099139, 26.10.2026): Der Checkout ist flach, `git merge-base` fand nichts; der Agent versuchte `git fetch --unshallow origin`, `git fetch --unshallow origin main` und `git fetch --depth=500 origin main`, die Allowlist kannte nur `git fetch --unshallow` ohne Argumente und lehnte ab. Kein Merge, kein Schaden, der Bericht war ehrlich. Nachgebessert: erlaubte Formen ergänzt, Prompt nennt `git fetch --unshallow origin main`. Zweiter Test (PR #80, Lauf 40377790137): `git fetch --unshallow origin main` klappte, der Merge brach aber ab: Die Action stellt `CLAUDE.md` und `.claude/` aus `main` wieder her (Arbeitsverzeichnis „M CLAUDE.md, M .claude/agent-settings.json“), und `main` hat dieselben Dateien geändert („local changes would be overwritten“). Der Agent hat nichts verworfen und sauber berichtet. Nachgebessert: `git merge --autostash origin/main` (lokal in einem Probe-Repo bestätigt: der Autostash lässt sich konfliktfrei wieder anwenden, weil die Änderung dem Stand von `main` entspricht). Dritter Test (PR #80, Lauf 40379976448): bestanden. Der Agent holte die Historie, merge-te `main` per Merge-Commit (`822277d`, zwei Eltern, kein Rebase, kein Force-Push), `docs/process.md` wurde ohne Konflikt zusammengeführt, `./verify.sh` lief grün (Exit-Code 0), Arbeitsverzeichnis sauber, keine Ablehnungen, 9 Turns, 0,13 USD, 106 s. Nicht getestet: ein echter Merge-Konflikt (der Prompt verlangt dann `git merge --abort` und einen Bericht). Das Freigabe-Label am PR hat funktioniert (Jobs `pruefung`, `agent`, `abschluss` grün). |
| P7 | Issue-Qualität | ⚠️ in Arbeit | Vorlage geschärft (PR #40). Messen, ob schlechte Issues die häufigste Ursache für Nacharbeit sind (M1). |
| P8 | Lernschleife: wiederkehrende Review-Hinweise nach `CLAUDE.md` | ⬜ offen | Nach dem Merge kurz festhalten, was sich wiederholt. `CLAUDE.md` ist Schutzbereich, Änderung durch den Owner. |

## Sicherheit

| ID | Punkt | Status | Nächster Schritt / Verweis |
|---|---|---|---|
| S1 | Technische Sperren des Agenten | ✅ erledigt | Berechtigungstest bestanden (12 von 12). Regeln in `.claude/agent-settings.json`. |
| S2 | Aktionen auf Commit-SHAs festlegen | ✅ erledigt | PR #40. Option „Require actions to be pinned“ erst nach Test einschalten. |
| S3 | Widerruf des `setup-token`-Tokens klären | ✅ erledigt | Entschieden (Owner, 26.10.2026): Keine Probe mit einem Wegwerf-Token, Restrisiko bewusst akzeptiert (ADR 0002, „Restrisiken“). Recherche und Notfallweg stehen in [betrieb.md](betrieb.md#oauth-token-widerrufen), die Wirkung des Widerrufs ist nicht belegt. Issue #62. |
| S4 | Ablaufdaten: PAT 22.01.2027, OAuth-Token Oktober 2027 | ✅ erledigt | Meldung per Issue 30 Tage vorher (`housekeeping.yml`, Daten in `.github/ablaufdaten.json`). Daten vom Owner geprüft (25.10.2026). Beim Erneuern eines Zugangs das Datum anpassen. |
| S5 | Eigene Bot-Identität mit minimaler GitHub-App | ❓ zu bewerten | Löst: PAT als statisches Token, Agent kann technisch mergen, Approve-Review nicht möglich (Autor = Owner). |
| S6 | Pflicht-Check `agent-approval-check` | ❓ zu bewerten | Braucht S5. |
| S7 | Secret Scanning und Push Protection | ✅ erledigt | Vom Owner per Screenshot belegt (25.10.2026): Secret Protection und Push Protection aktiv, Dependabot-Warnungen und Sicherheits-Updates an. Optional noch aus: Private Vulnerability Reporting, Malware-Warnungen. |
| S8 | CodeQL und Egress-Filter | ⚠️ in Arbeit | CodeQL Default Setup ist aktiv (25.10.2026, Owner): GitHub Actions und Java/Kotlin, Suite „Default“. Dart/Flutter unterstützt CodeQL nicht, das Frontend ist damit nicht abgedeckt (Gate: `flutter analyze`). Offen: erste Ergebnisse unter Security → Code scanning sichten, prüfen ob die Scan-Ereignisse zu uns passen, AI Scan für Dart bewerten, Egress-Filter. Kein Pflicht-Check im Ruleset. Issue #73. |
| S9 | Notausschalter | ⚠️ in Arbeit | Beschrieben in [betrieb.md](betrieb.md). Noch nicht geprobt, einmal durchspielen (Lauf abbrechen, Workflow abschalten, Secret löschen). Der Widerruf beim Anbieter wird bewusst nicht geprobt (S3). Geprüft (Owner, 26.10.2026): Im Environment `agent` ist „Allow administrators to bypass configured protection rules“ bereits aus. Issue #63. |
| S10 | Nutzung des Abo-Tokens im Dauerbetrieb | ❓ zu bewerten | Nutzungsbedingungen und Limits für automatisierte Läufe prüfen. Ich habe das nicht geprüft. |
| S11 | Alternative zum statischen Abo-Token | ❓ zu bewerten | Zurückgestellt: Der Owner bleibt vorerst beim Abo-Token (26.10.2026), ein API-Key würde zusätzliche Kosten pro Nutzung bedeuten. Zwei Wege: API-Key aus der Console (jederzeit löschbar) oder OIDC-Federation (kein statisches Secret). Die Action nennt im Lauf-Log Federation-Eingaben (`anthropic_federation_rule_id` und weitere), das habe ich nicht getestet. Federation bräuchte `id-token: write`, das ADR 0002 heute bewusst nicht vergibt. |

## Messung und Qualität

| ID | Punkt | Status | Nächster Schritt / Verweis |
|---|---|---|---|
| M1 | Kennzahlen | ⚠️ in Arbeit | Die Annotation „Kennzahlen“ im Lauf zeigt Turns, Kosten (Richtwert), Dauer und Gate-Versuche. Datenpunkte (25.10.2026): #52 Filter 47 Turns, 161 s, 0,44 USD, Gate 2×, 3 Ablehnungen. #55 Sortierung 54 Turns, 214 s, 0,46 USD, Gate 3×, 1 Ablehnung. #56 Diagramme 17 Turns, 125 s, 0,21 USD, Gate 1×, 2 Ablehnungen. `/agent` mit Ablehnung (Rebase) 3 Turns, 9 s, 0,09 USD. #61 Anzahl im Titel 18 Turns, 112 s, 0,18 USD, Gate 2×, keine Ablehnung. `/agent`-Überarbeitung dazu 17 Turns, 79 s, 0,17 USD, Gate 1×, keine Ablehnung. Faustwert: ein Feature über Spec, Service und UI braucht 45 bis 55 von 60 Turns. Weiter sammeln, vor allem echte Überarbeitungen. |
| M2 | Wiederholbare Referenzaufgaben (Evals) | ❓ zu bewerten | Die Test-Issues (#18 bis #35) als feste Aufgabenmenge, um Prompt- und Versionsänderungen zu vergleichen. |
| M3 | Diagnoseschritt im Agent-Workflow | ✅ erledigt | Bleibt dauerhaft: Er zeigt Ablehnungen, Kennzahlen (M1) und den Stand des Arbeitsverzeichnisses. |
| M4 | Prompt und `CLAUDE.md` pflegen | ⬜ offen | Prompt in `agent.yml` wächst. Prüfen, was in `CLAUDE.md` gehört. |

## Betrieb

| ID | Punkt | Status | Nächster Schritt / Verweis |
|---|---|---|---|
| B1 | Updates der Action und von Claude Code | ⚠️ in Arbeit | Die Action installiert Claude Code zur Laufzeit (zuletzt 2.1.310). Vorgehen für Versionssprünge ist festgelegt: neues Tag lesen, Referenzaufgaben laufen lassen, dann pinnen, siehe [betrieb.md](betrieb.md#updates-der-action-und-von-claude-code). Offen: ob sich Claude Code selbst pinnen lässt (Owner prüft die `action.yml`), und feste Referenzaufgaben (M2). Issue #66. |
| B2 | Kontingent bei parallelen Läufen | ❓ zu bewerten | Concurrency pro Issue erlaubt Parallelität. Beobachten, ob das Abo-Limit greift. |
| B3 | Aufräumen übrig gebliebener `agent/*`-Branches | ❓ zu bewerten | „Branch nach Merge löschen“ ist aktiv. Branches ohne PR bleiben liegen. |
| B4 | Betriebshandbuch | ✅ erledigt | Erste Fassung in [betrieb.md](betrieb.md): Notausschalter, Störungen, Zugänge erneuern. Wird mit den Erfahrungen ergänzt. |
| B5 | Runner-Image und Abhängigkeiten | ⚠️ in Arbeit | `ubuntu-24.04` festgelegt. Dependabot läuft wöchentlich. |
| B6 | Pflege der Roadmap | ✅ erledigt | Regel in `CLAUDE.md`, Checkbox in der PR-Vorlage, Erinnerung per `housekeeping.yml` (erster Lauf grün). |
| B7 | Transparenz im Repo | ⚠️ in Arbeit | Milestones (Stufen, „Betrieb und Absicherung“, „Review-Schleife und Selbstheilung“), Bereichslabels und Issues zu den anstehenden Punkten sind angelegt (25.10.2026). Gebaut (Issue #74, ungetestet): Kennzahlen, Ablehnungen und Arbeitsverzeichnis als Job-Zusammenfassung (`GITHUB_STEP_SUMMARY`) in `agent.yml` und `agent-review.yml`, CI-Badge im README. Offen: Project-Board (Owner, Weboberfläche). Hinweis: Jedes Label löst einen übersprungenen Agent-Lauf aus (der Trigger kann nicht nach Label filtern), das ist harmlos. Neu (gebaut, ungetestet): Das Label `wartet-auf-freigabe` zeigt an Issue und PR, dass ein Lauf auf deine Freigabe wartet (Filter `label:wartet-auf-freigabe`). Gebaut (Issue #82, ungetestet): Pro Lauf ein Kommentar mit Link auf den Lauf, aktualisiert bis zum Ende. Issue #74. |

## Produkt (Spielwiese)

| ID | Punkt | Status | Nächster Schritt / Verweis |
|---|---|---|---|
| X1 | Flutter-Plattformordner anlegen | ⬜ offen | `flutter create --platforms=android,ios,web --project-name order_app .` in `frontend/`, danach `analysis_options.yaml` prüfen. |
| X2 | Weitere Features als reale Aufträge | ⚠️ in Arbeit | Nach P2, damit die Schleife an echten Änderungen getestet wird. Erstes Feature: Bestellliste nach Status filtern (Issue #52). Zweites Feature: Bestellliste nach Anlegedatum sortieren (Issue #55). Drittes Feature: Anzahl der Bestellungen im Titel anzeigen (Issue #61). Viertes Feature: Detailansicht einer Bestellung (Issue #87). |

## Wiederverwendung

| ID | Punkt | Status | Nächster Schritt / Verweis |
|---|---|---|---|
| W1 | Trennung generisch und projektspezifisch | ❓ zu bewerten | Workflow, Einstellungen, Vorlage, Prompt, ADR 0002 sind generisch. Spec, Gate und Stack sind es nicht. Vor Stufe 5 auflisten. |

## Blinde Flecken (ehrlich: noch nicht bewertet)

Dinge, die beim Gestalten leicht untergehen, weil der Alltag sie nicht einfordert:

1. **Messung fehlt.** Ohne Zahlen (M1) wissen wir nicht, ob die Factory Zeit spart oder nur verlagert.
2. **Regression der Factory selbst.** Ein neuer Prompt oder eine neue Action-Version kann das Verhalten verändern
   (M2, B1). Heute fällt das erst im nächsten echten Auftrag auf.
3. **Notfall.** Ein Weg, schnell zu stoppen (S9), und ein bekannter Widerruf der Tokens (S3).
4. **Ablaufende Zugänge** (S4): ein Token, das stillschweigend abläuft, stoppt den Betrieb.
5. **Nutzungsbedingungen** für den Dauerbetrieb mit dem Abo-Token (S10).
6. **Ein Einzelner als Engpass.** Review, Freigabe im Environment und Merge laufen über den Owner. Mehr
   Parallelität (B2) verschiebt die Last dorthin.
7. **Wissen, das im Chat bleibt.** Entscheidungen gehören in ADRs, offene Punkte in diese Datei, Lehren in `CLAUDE.md`.
