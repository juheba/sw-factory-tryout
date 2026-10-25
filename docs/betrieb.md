# Betriebshandbuch

Erste Fassung, Stand 24.10.2026. Für den Besitzer. Sie sagt, was bei einem Notfall und bei den häufigsten Störungen zu
tun ist. Hintergründe stehen in [ADR 0002](adr/0002-agent-sicherheit.md), der Gesamtplan in der [Roadmap](roadmap.md).

**Nicht geprobt:** Der Notausschalter ist beschrieben, aber noch nie durchgespielt worden (Roadmap S9). Einmal ruhig
ausprobieren, bevor er gebraucht wird.

## Notausschalter

Von sanft nach hart. Jede Stufe schließt die vorherigen nicht aus.

| Stufe | Wirkung | So geht es |
|---|---|---|
| 1. Laufenden Lauf stoppen | Der aktuelle Lauf endet sofort. | Actions → Lauf öffnen → **Cancel workflow**. Per CLI: `gh run cancel <run-id>`. |
| 2. Neue Läufe verhindern | Kein weiterer Lauf startet, oder er wartet. | Die **Freigabe** im Environment `agent` verweigern (Läufe bleiben „waiting“ und lassen sich abbrechen). Das Label `agent` nicht setzen. Den Workflow abschalten: Actions → Agent → **Disable workflow**, per CLI `gh workflow disable agent.yml`. |
| 3. Zugänge entziehen | Der Agent kann weder schreiben noch das Modell nutzen. | Fine-grained PAT löschen: GitHub → Settings → Developer settings → Personal access tokens. Secrets `AGENT_GITHUB_TOKEN` und `CLAUDE_CODE_OAUTH_TOKEN` im Environment `agent` löschen. **Offen (Roadmap S3):** Ob und wie das OAuth-Token bei Anthropic widerrufen wird, ist nicht geklärt. Das Löschen des Secrets verhindert nur die Nutzung in der Factory. |
| 4. Schaden begrenzen | Spuren beseitigen. | Offene Agent-PRs schließen, Branches `agent/*` löschen. Auf `main` verhindert das Ruleset direkte Pushes. Ist ein Agent-PR gemerged, per Revert-PR zurücknehmen. |

Danach: Ursache klären (Annotationen und Ergebnis-JSON des Laufs, siehe unten), neue Zugänge erzeugen (siehe
„Zugänge erneuern“), die Lehre im ADR oder hier festhalten.

## Wo du hinsiehst

- **Annotationen am Lauf** (Actions → Lauf → Job → Zusammenfassung): „Agent-Ablehnungen“ (welche Aktionen die Regeln
  abgelehnt haben) und „Arbeitsverzeichnis“ (welche versionierten Dateien nach dem Lauf verändert waren).
- **Ergebnis des Agenten im Log:** `num_turns`, `total_cost_usd`, `permission_denials_count`. Das Log selbst ist
  absichtlich knapp, die volle Ausgabe ist ausgeschaltet.
- **Kommentar im Issue:** Betrifft der Auftrag nur Schutzbereiche, schreibt der Agent dort, warum er keinen PR öffnet.
- **Housekeeping-Issues** mit Titel `[Betrieb] …`: fällige Roadmap-Durchsicht und ablaufende Zugänge.

## Störungen

| Symptom | Wahrscheinliche Ursache | Maßnahme |
|---|---|---|
| `/agent`-Kommentar bleibt ohne Reaktion | Kommentar beginnt nicht mit `/agent`, stammt nicht vom Besitzer oder steht nicht auf einem PR. Oder der Job `pruefung` hat abgelehnt. | Actions → „Agent Review“ öffnen. Der Prüfjob nennt den Grund (Annotation „Agent Review abgelehnt“, meist auch als PR-Kommentar): PR nicht offen, Branch nicht `agent/*`, Schutzbereiche im Diff, mehr als 5 Runden. |
| Review-Lauf „waiting“, obwohl `pruefung` grün ist | Jeder `/agent`-Kommentar braucht eine eigene Freigabe im Environment `agent`. | Lauf „Agent Review“ öffnen, **Review deployments**, freigeben. |
| Lauf bleibt „waiting“ | Freigabe im Environment `agent` fehlt. | Lauf öffnen, **Review deployments**, freigeben. |
| Lauf startet nicht nach Label | Absender oder Issue-Autor ist nicht der Besitzer, oder das falsche Label. | Bedingung in `.github/workflows/agent.yml` prüfen. Label entfernen und neu setzen. |
| Lauf wurde abgebrochen, obwohl ein neuer folgte | Pro Issue gilt ein Lauf zugleich, GitHub hält nur einen wartenden Lauf pro Gruppe. | Label auf demselben Issue erneut setzen, wenn der laufende Lauf fertig ist. |
| „Action is not allowed“ | Die Allowlist (Settings → Actions → General) kennt die Version nicht. Beim `setup-bun` in der Claude-Action ist der genaue SHA nötig. | Fehlenden Eintrag ergänzen, nach jedem Action-Update neu prüfen. |
| Authentifizierungsfehler im Lauf | Ein Zugang ist abgelaufen oder widerrufen. | `.github/ablaufdaten.json` und das Secret im Environment prüfen, Zugang erneuern. |
| Agent eröffnet keinen PR, kommentiert nur | Der Auftrag betrifft einen Schutzbereich oder verlangt Verbotenes. | Kommentar lesen. Die Änderung selbst durchführen oder das Issue anpassen. |
| `gh pr create` oder ein Befehl wird abgelehnt | Eine Deny-Regel oder fehlende Erlaubnis in `.claude/agent-settings.json`. | Annotation „Agent-Ablehnungen“ lesen. Regel nur mit Bedacht ändern (Schutzbereich, Admin-Bypass). |
| Lauf endet mit Turn-Limit | `--max-turns 60` erreicht, der Auftrag ist zu groß oder zu unscharf. | Issue verkleinern oder präzisieren (Akzeptanzkriterien, „Nicht Teil des Auftrags“). |
| Gate verändert Dateien | Flutter oder ein Generator schreibt in versionierte Dateien. | Annotation „Arbeitsverzeichnis“ lesen und die Datei einmal passend einchecken. |
| Rote CI auf `main` | Ein gemergter PR hat etwas gebrochen. | Per Revert-PR zurücknehmen, nicht per Force-Push. Den Agenten damit nicht beauftragen, solange die Ursache offen ist. |
| PR lässt sich nicht mergen | Code-Owner-Review fehlt (der Agent ist du, du kannst dich nicht selbst freigeben). | Mit Admin-Bypass mergen, wenn der PR Schutzbereiche berührt. Sonst Checks abwarten. |

## Zugänge erneuern

Beim Erneuern das Datum in `.github/ablaufdaten.json` anpassen und das Housekeeping-Issue schließen.

- **PAT `AGENT_GITHUB_TOKEN`:** neues fine-grained Token, nur dieses Repo, Rechte Contents, Pull requests und Issues
  schreibend, **ohne** Workflows-Recht, Laufzeit 90 Tage. Das Secret im Environment `agent` ersetzen.
- **OAuth-Token `CLAUDE_CODE_OAUTH_TOKEN`:** lokal `claude setup-token` ausführen, das Token nicht speichern und nirgends
  einfügen (nicht in Chats, Issues oder PR-Texte), nur als Secret im Environment `agent` ablegen.
- **Nach Action-Updates:** Allowlist prüfen (siehe Störungen), bei Bedarf neuen SHA eintragen.

## Zuständigkeit

Alles läuft über den Besitzer: Freigabe der Läufe, Review, Merge, Zugänge. Wird die Factory von mehr Personen genutzt,
gehört das hier überarbeitet (Roadmap S5, eigene Bot-Identität).
