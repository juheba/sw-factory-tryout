# ADR 0001: Spec-first mit OpenAPI

- Status: akzeptiert
- Datum: 2026-10-22

## Kontext

Coding-Agents brauchen eine präzise, maschinenlesbare Beschreibung dessen, was gebaut werden soll,
und eine automatische Prüfung, ob das Ergebnis dazu passt. Service und Frontend müssen konsistent bleiben.

## Entscheidung

`openapi/openapi.yaml` ist die Quelle der Wahrheit und liegt außerhalb von Service und Frontend.
Der OpenAPI Generator erzeugt daraus beim Build die Server-Interfaces (Generator `spring`, `interfaceOnly`)
und den Dart-Client (Generator `dart`). Generierter Code wird nicht eingecheckt.
Ein Contract-Test stellt sicher, dass die Endpunkte des Service zum Vertrag passen.
Das Frontend kapselt den generierten Client in einem Repository und arbeitet in der UI mit eigenen Modellen.

## Konsequenzen

- API-Änderungen beginnen im Vertrag; Agents haben eine klare, prüfbare Spezifikation.
- Spec-Drift fällt im Service (Contract-Test) und im Frontend (Analyse und Tests) in der Agent-Schleife auf.
- Der Build hängt vom Generator-Plugin ab; Versions-Updates laufen über Dependabot.
- Generierter Code darf nicht von Hand geändert werden.
