# Architektur

Ein Vertrag, zwei Konsumenten: Der Service implementiert die generierten Server-Interfaces,
das Frontend nutzt einen generierten Client.

## Bausteine

```mermaid
flowchart TB
    Spec[/openapi/openapi.yaml/]
    Spec -->|OpenAPI Generator: spring| Gen[Generierte Interfaces und Modelle]
    Spec -->|OpenAPI Generator: dart| Cli[Generierter Dart-Client]

    subgraph service [service: Spring Boot]
        Gen --> Ctl[OrdersController]
        Ctl --> Svc[OrderService]
        Svc --> Mem[(In-Memory-Map)]
        Ctl -.Fehler.-> Err[GlobalExceptionHandler]
    end

    subgraph frontend [frontend: Flutter]
        Cli --> Repo[OrdersRepository]
        Repo --> UI[OrdersPage]
    end

    UI -->|HTTP/JSON| Ctl
    Test[OpenApiContractTest] -.prüft.-> Spec
    Test -.prüft.-> Ctl
```

## Ablauf: Bestellung anlegen

```mermaid
sequenceDiagram
    participant U as OrdersPage
    participant R as OrdersRepository
    participant Ctl as OrdersController
    participant S as OrderService
    U->>R: create(customerId, sku, quantity)
    R->>Ctl: POST /orders
    Ctl->>Ctl: Validierung (Bean Validation aus Spec)
    Ctl->>S: create(request)
    S-->>Ctl: Order (Status CREATED)
    Ctl-->>R: 201 Created, Location /orders/{id}
    R-->>U: OrderSummary
```

## Lebenszyklus einer Bestellung

```mermaid
stateDiagram-v2
    [*] --> CREATED: POST /orders
    CREATED --> CANCELLED: POST /orders/{id}/cancel
    CANCELLED --> CANCELLED: 409 Conflict
```

Das Stornieren ist atomar (`ConcurrentHashMap.computeIfPresent`). Unbekannte IDs liefern 404,
eine bereits stornierte Bestellung liefert 409; beide Fehler als RFC-9457-Problem-Details.

## Ablauf: automatischer Agent-Lauf (Stufe 2)

```mermaid
sequenceDiagram
    actor O as Owner
    participant GH as GitHub
    participant WF as Workflow agent.yml
    participant Env as Environment agent
    participant A as Agent (claude-code-action)
    participant CI as CI (ci.yml)
    O->>GH: Issue anlegen, Label "agent" setzen
    GH->>WF: Ereignis issues/labeled
    WF->>WF: Prüfung: Label, Sender und Issue-Autor = Owner
    WF->>Env: Freigabe anfordern (Branch main)
    O-->>Env: Lauf freigeben
    Env-->>WF: Secrets (OAuth-Token, PAT)
    WF->>A: Issue-Nummer, agent-settings.json, max-turns
    A->>GH: Branch agent/nr-slug, Commits, Pull Request (oder Kommentar im Issue, wenn der Auftrag verboten ist)
    GH->>CI: Gate service und frontend
    O->>GH: PR prüfen und mergen (Code-Owner-Review bei Schutzbereichen)
```

Pro Issue läuft höchstens ein Lauf (`concurrency`), verschiedene Issues dürfen parallel laufen.
Der Agent liest den Issue-Text selbst und behandelt ihn als Daten. Schutzbereiche (Workflows, Gate, Build-Skripte)
darf er nicht ändern; die Grenze setzen `CODEOWNERS` und das Ruleset. Details: ADR 0002.

## Ablauf: Review-Schleife per Kommentar

```mermaid
sequenceDiagram
    actor O as Owner
    participant GH as GitHub
    participant P as Job pruefung (ohne Secrets)
    participant Env as Environment agent
    participant A as Agent (claude-code-action, Interaktiv-Modus)
    participant CI as CI (ci.yml)
    O->>GH: Kommentar "/agent Wunsch" auf einem agent/*-PR
    GH->>P: Ereignis issue_comment (Workflow-Stand von main)
    P->>P: PR offen, Branch agent/*, gleiches Repo, Autor Owner, keine Schutzbereiche im Diff, höchstens 5 Runden
    P-->>GH: bei Ablehnung: Kommentar mit Grund, kein Agent-Lauf
    P->>Env: Freigabe anfordern (Branch main)
    O-->>Env: Lauf freigeben
    Env-->>A: Secrets (OAuth-Token, PAT)
    A->>GH: liest Kommentare des Owners, ändert Code, ./verify.sh, Push auf den PR-Branch, Antwortkommentar
    GH->>CI: Gate service und frontend
    O->>GH: erneut prüfen, weiteren Kommentar schreiben oder mergen
```

`issue_comment` läuft immer mit der Workflow-Datei von `main`; ein PR kann den Workflow also nicht verändern. Der Job
`pruefung` entscheidet vor der Freigabe, ob der Befehl zulässig ist. Pro PR läuft höchstens ein Lauf. Die Schleife ist
ein Spike und noch nicht im Echtbetrieb bewertet (Roadmap P2).

## Entscheidungen

- [ADR 0001: Spec-first mit OpenAPI](adr/0001-spec-first-openapi.md)
- [ADR 0002: Absicherung automatischer Agent-Läufe](adr/0002-agent-sicherheit.md)
