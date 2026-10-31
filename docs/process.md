# Software-Factory-Prozess

## Ablauf (Stufe 1: manuell angestoßen)

```mermaid
flowchart LR
    I[Issue mit Akzeptanzkriterien] --> A[Agent: Claude Code]
    A -->|liest| C[CLAUDE.md und openapi.yaml]
    A --> L{Loop: ./verify.sh}
    L -->|rot| A
    L -->|grün| PR[Pull Request]
    PR --> CI[GitHub Actions: build]
    CI --> R[Review durch Mensch]
    R -->|Änderungen| A
    R -->|ok| M[Merge in main]
```

Der **Loop** ist der Kern: Der Agent ändert Code, führt `./verify.sh` aus, liest die Fehler und korrigiert,
bis das Gate grün ist. Ohne dieses Feedback gibt es kein belastbares „geprüft“.

## Ablauf (Stufe 2: Label startet den Lauf)

```mermaid
flowchart LR
    O[Owner legt Issue an und setzt Label agent] --> T{Auslöser geprüft: Label agent, Absender und Autor = Owner}
    T -->|nein| X[Kein Lauf]
    T -->|ja| E[Freigabe im Environment agent]
    E --> A[Agent liest CLAUDE.md und Issue, arbeitet auf agent/nr-slug]
    A --> L{Loop: ./verify.sh}
    L -->|rot| A
    L -->|grün| PR[Pull Request mit Closes nr]
    PR --> CI[CI: Jobs service und frontend]
    CI --> R[Review durch Mensch]
    R -->|Änderungswunsch: Kommentar /agent ...| RK[Überarbeitung auf dem PR-Branch]
    RK --> CI
    R -->|ok| M[Merge in main]
```

Gegenüber Stufe 1 startet der Lauf automatisch, sobald der Owner das Label `agent` setzt, und nur dann, wenn
Absender und Issue-Autor der Owner sind. Jeder Lauf wartet auf eine Freigabe im GitHub-Environment `agent`.
Schutzbereiche (Workflows, Gate, Build-Skripte) darf der Agent nicht ändern, dafür sorgen Code-Owner-Review und
Ruleset. Die Begründungen stehen in [ADR 0002](adr/0002-agent-sicherheit.md).

**Review-Schleife (Spike, Roadmap P2):** Bei Änderungswünschen schreibt der Owner auf dem `agent/*`-PR einen
Kommentar, der mit `/agent` beginnt. Der Workflow `agent-review.yml` prüft zuerst ohne Secrets (offener PR, Branch
`agent/*`, keine Schutzbereiche im Diff, höchstens 5 Runden) und fragt dann die Freigabe im Environment an. Der Agent
arbeitet auf demselben Branch, führt `./verify.sh` aus und antwortet mit einem Kommentar. Ändert der PR Schutzbereiche,
lehnt die Prüfung ab und nennt den Grund; dann arbeitet der Owner selbst weiter. Geht der Wunsch über den PR hinaus,
wird das Issue angepasst und das Label neu gesetzt.

**Rückfrage statt Raten (Roadmap P5):** Ist ein Akzeptanzkriterium deutlich mehrdeutig, baut der Agent nichts auf
Verdacht. Er stellt seine Fragen als Kommentar ins Issue und beendet den Lauf. Der Owner antwortet im Issue und
setzt das Label `agent` erneut (Label entfernen, wieder setzen).

**Freigabe und Lauf sichtbar machen (Roadmap B7):** Jeder Lauf braucht eine Freigabe im Environment `agent`. Damit du
nicht unter Actions suchen musst, zeigt die Factory den Zustand dort, wo du arbeitest:
- **Label `wartet-auf-freigabe`** am Issue bzw. PR, solange der Lauf wartet. In der Liste filterst du mit
  `label:wartet-auf-freigabe`.
- **Ein Kommentar pro Lauf mit Link** auf die Lauf-Seite, auf der du freigibst. Er wird aktualisiert: ⏳ wartet →
  ▶️ läuft → ✅ abgeschlossen, ❌ ohne Erfolg (Fehler oder abgelehnt) oder ⛔ abgebrochen. Den Kommentar legt beim Issue
  der Job `anmelden` an, beim PR der Job `pruefung`; der Job `abschluss` schließt ihn ab und entfernt das Label, auch
  nach einer Ablehnung. Alle drei Jobs laufen ohne Environment und ohne Secrets.

**Meilenstein:** Der Job `abschluss` übernimmt nach einem erfolgreichen Lauf den Meilenstein des Issues auf den PR des
Agents (Branch `agent/<issue>-*`, nur wenn der PR noch keinen hat). Hat das Issue keinen, bleibt der PR ohne. Den
Meilenstein setzt du also einmal am Issue.

**Vertrag ansehen (Roadmap X3):** Berührt ein PR `openapi/**`, legt der Workflow `vertrag-vorschau.yml` einen Kommentar mit
twei Links an: **Vorher** (Seite von `main`) und **Nachher** (dieselbe Seite mit dem Vertrag des PR-Stands). Der Kommentar
wird bei jedem neuen Push aktualisiert. Ohne Änderung an `openapi/` gibt es ihn nicht.

Kommentare von `GITHUB_TOKEN` lösen keinen weiteren Workflow aus und zählen nicht als `/agent`-Runde (gezählt werden
nur Kommentare des Owners). Schlägt das Kommentieren fehl, bleibt es bei einer Warnung und der Lauf läuft weiter.
Soll der Ablauf um einen weiteren Schritt oder Zustand wachsen, wird der Kommentar im selben Job aktualisiert und nicht
durch zusätzliche Kommentare ergänzt.
Liegt der Branch hinter `main`, holt der Agent `main` per Merge-Commit nach (kein Rebase, kein Force-Push, Roadmap P6).

## Wenn der Agent nicht liefern kann

Betrifft ein Auftrag nur Schutzbereiche oder verlangt er etwas Verbotenes, eröffnet der Agent keinen Pull Request.
Stattdessen schreibt er einen Kommentar ins Issue. Der Kommentar nennt, was verlangt wurde, welche Regel es
verhindert und was der Owner selbst tun muss. Die Regeln und ihre Begründung stehen in
[ADR 0002](adr/0002-agent-sicherheit.md).

## Beobachtbarkeit

| Was | Wo |
|---|---|
| Auftrag und Diskussion | GitHub Issue |
| Ergebnis | Pull Request mit Diff und Beschreibung |
| Prüfung | GitHub Actions (Jobs `service` und `frontend`), Berichte als Artefakt |
| Wartende Freigabe | Label `wartet-auf-freigabe` an Issue oder PR (Filter `label:wartet-auf-freigabe`) |
| Architektur und Entscheidungen | `docs/architecture.md`, `docs/adr/` |

## Ausbaustufen

1. **Template-Repo** (dieses Repo): Agent arbeitet an einem Issue, du prüfst den PR.
2. **Automatisierung (aktiv):** Label `agent` am Issue startet den Agent per GitHub Action (`anthropics/claude-code-action`).
3. **Rollen:** Planer, Implementierer und Reviewer als Subagents/Skills in `.claude/`.
4. **Orchestrator:** Eigener Graph mit dem Claude Agent SDK (Knoten = Rollen, Kanten = Übergaben, Schleife = Review → Fix).
5. **Wiederverwendung:** Skills und Templates in einem eigenen Factory-Repo für weitere Stacks.

## Definition of Done

Die Datei [`config/definition-of-done.md`](../config/definition-of-done.md) ist der gemeinsame Maßstab für Coder,
Reviewer, QA und Owner. Sie liegt im Schutzbereich `config/`, damit der Coder die Latte nicht selbst absenkt; Reviewer
und QA lesen die Fassung aus `main`. Die Punkte sind nummeriert (`DoD-1` …) und nach Art der Prüfung markiert: **Gate**
(`./verify.sh` erzwingt es), **Sperre** (Berechtigungen, `.gitignore`, `CODEOWNERS` verhindern es) oder **Urteil**
(jemand muss lesen und beurteilen). Der Coder bewertet jeden Punkt im PR-Text, der Reviewer (Roadmap P4) bewertet die
Urteilspunkte und zitiert die Nummer. Wiederkehrende Befunde werden Teil der Liste (Roadmap P8).
