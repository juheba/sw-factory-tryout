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
    O[Besitzer legt Issue an und setzt Label agent] --> T{Auslöser geprüft: Label agent, Absender und Autor = Besitzer}
    T -->|nein| X[Kein Lauf]
    T -->|ja| E[Freigabe im Environment agent]
    E --> A[Agent liest CLAUDE.md und Issue, arbeitet auf agent/nr-slug]
    A --> L{Loop: ./verify.sh}
    L -->|rot| A
    L -->|grün| PR[Pull Request mit Closes nr]
    PR --> CI[CI: Jobs service und frontend]
    CI --> R[Review durch Mensch]
    R -->|Änderungen| A
    R -->|ok| M[Merge in main]
```

Gegenüber Stufe 1 startet der Lauf automatisch, sobald der Besitzer das Label `agent` setzt, und nur dann, wenn
Absender und Issue-Autor der Besitzer sind. Jeder Lauf wartet auf eine Freigabe im GitHub-Environment `agent`.
Schutzbereiche (Workflows, Gate, Build-Skripte) darf der Agent nicht ändern, dafür sorgen Code-Owner-Review und
Ruleset. Die Begründungen stehen in [ADR 0002](adr/0002-agent-sicherheit.md).

## Beobachtbarkeit

| Was | Wo |
|---|---|
| Auftrag und Diskussion | GitHub Issue |
| Ergebnis | Pull Request mit Diff und Beschreibung |
| Prüfung | GitHub Actions (Jobs `service` und `frontend`), Berichte als Artefakt |
| Architektur und Entscheidungen | `docs/architecture.md`, `docs/adr/` |

## Ausbaustufen

1. **Template-Repo** (dieses Repo): Agent arbeitet an einem Issue, du prüfst den PR.
2. **Automatisierung (aktiv):** Label `agent` am Issue startet den Agent per GitHub Action (`anthropics/claude-code-action`).
3. **Rollen:** Planer, Implementierer und Reviewer als Subagents/Skills in `.claude/`.
4. **Orchestrator:** Eigener Graph mit dem Claude Agent SDK (Knoten = Rollen, Kanten = Übergaben, Schleife = Review → Fix).
5. **Wiederverwendung:** Skills und Templates in einem eigenen Factory-Repo für weitere Stacks.
