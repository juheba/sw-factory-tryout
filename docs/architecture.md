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

## Entscheidungen

- [ADR 0001: Spec-first mit OpenAPI](adr/0001-spec-first-openapi.md)
