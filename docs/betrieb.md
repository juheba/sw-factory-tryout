# Betriebshandbuch

Erste Fassung, Stand 24.10.2026. Für den Owner. Sie sagt, was bei einem Notfall und bei den häufigsten Störungen zu
tun ist. Hintergründe stehen in [ADR 0002](adr/0002-agent-sicherheit.md), der Gesamtplan in der [Roadmap](roadmap.md).

**Nicht geprobt:** Der Notausschalter ist beschrieben, aber noch nie durchgespielt worden (Roadmap S9). Einmal ruhig
ausprobieren, bevor er gebraucht wird.

## Notausschalter

Von sanft nach hart. Jede Stufe schließt die vorherigen nicht aus.

| Stufe | Wirkung | So geht es |
|---|---|---|
| 1. Laufenden Lauf stoppen | Der aktuelle Lauf endet sofort. | Actions → Lauf öffnen → **Cancel workflow**. Per CLI: `gh run cancel <run-id>`. |
| 2. Neue Läufe verhindern | Kein weiterer Lauf startet, oder er wartet. | Die **Freigabe** im Environment `agent` verweigern (Läufe bleiben „waiting“ und lassen sich abbrechen). Das Label `agent` nicht setzen. Den Workflow abschalten: Actions → Agent → **Disable workflow**, per CLI `gh workflow disable agent.yml`. |
| 3. Zugänge entziehen | Der Agent kann weder schreiben noch das Modell nutzen. | Fine-grained PAT löschen: GitHub → Settings → Developer settings → Personal access tokens. Secrets `AGENT_GITHUB_TOKEN` und `CLAUDE_CODE_OAUTH_TOKEN` im Environment `agent` löschen. Das Löschen des Secrets verhindert nur die Nutzung in der Factory, das Token selbst bleibt gültig. Widerruf beim Anbieter: siehe „OAuth-Token widerrufen“ unten (Roadmap S3). |
| 4. Schaden begrenzen | Spuren beseitigen. | Offene Agent-PRs schließen, Branches `agent/*` löschen. Auf `main` verhindert das Ruleset direkte Pushes. Ist ein Agent-PR gemerged, per Revert-PR zurücknehmen. |

Danach: Ursache klären (Annotationen und Ergebnis-JSON des Laufs, siehe unten), neue Zugänge erzeugen (siehe
„Zugänge erneuern“), die Lehre im ADR oder hier festhalten.

## Wo du hinsiehst

- **Annotationen am Lauf** (Actions → Lauf → Job → Zusammenfassung): „Agent-Ablehnungen“ (welche Aktionen die Regeln
  abgelehnt haben) und „Arbeitsverzeichnis“ (welche versionierten Dateien nach dem Lauf verändert waren).
- **Job-Zusammenfassung** (Actions → Lauf, Seite „Summary“, Abschnitt „Agent-Lauf“): Kennzahlen (Turns, Kosten,
  Dauer, Gate-Versuche), abgelehnte Aktionen und Arbeitsverzeichnis auf einen Blick, ohne Annotationen zu suchen.
- **Ergebnis des Agenten im Log:** `num_turns`, `total_cost_usd`, `permission_denials_count`. Das Log selbst ist
  absichtlich knapp, die volle Ausgabe ist ausgeschaltet.
- **Kommentar im Issue:** Betrifft der Auftrag nur Schutzbereiche, schreibt der Agent dort, warum er keinen PR öffnet.
- **Housekeeping-Issues** mit Titel `[Betrieb] …`: fällige Roadmap-Durchsicht und ablaufende Zugänge.

## Störungen

| Symptom | Wahrscheinliche Ursache | Maßnahme |
|---|---|---|
| `/agent`-Kommentar bleibt ohne Reaktion | Kommentar beginnt nicht mit `/agent`, stammt nicht vom Owner oder steht nicht auf einem PR. Oder der Job `pruefung` hat abgelehnt. | Actions → „Agent Review“ öffnen. Der Prüfjob nennt den Grund (Annotation „Agent Review abgelehnt“, meist auch als PR-Kommentar): PR nicht offen, Branch nicht `agent/*`, Schutzbereiche im Diff, mehr als 5 Runden. |
| Review-Lauf „waiting“, obwohl `pruefung` grün ist | Jeder `/agent`-Kommentar braucht eine eigene Freigabe im Environment `agent`. | Lauf „Agent Review“ öffnen, **Review deployments**, freigeben. |
| Lauf bleibt „waiting“ | Freigabe im Environment `agent` fehlt. | Lauf öffnen, **Review deployments**, freigeben. |
| Lauf bricht ab, Meldung zu Limit oder Kontingent (vermutet) | Das Abo-Kontingent (5-Stunden-Fenster oder Wochenlimit) ist ausgeschöpft; Agent-Läufe teilen es mit deiner interaktiven Nutzung. Die genaue Meldung ist noch nicht bekannt (Issue #100). | In claude.ai → Settings → Usage den Stand ansehen, bis zum Reset warten, Lauf neu starten (Label entfernen und setzen). „Usage credits“ nicht einschalten, wenn keine Zusatzkosten gewünscht sind. Meldung im Issue #100 festhalten. |
| Issue oder PR trägt das Label `wartet-auf-freigabe` | Ein Lauf wartet auf deine Freigabe. Das Label setzt der Job `anmelden` (Issue) bzw. `pruefung` (PR) und entfernt es nach der Freigabe oder Ablehnung. | Filter in der Liste: `label:wartet-auf-freigabe`. Dann den Lauf öffnen und freigeben oder ablehnen. |
| Kommentar „⏳ Agent-Lauf wartet auf deine Freigabe“ am Issue oder PR | Pro Lauf legt ein Job einen Kommentar mit Link an und aktualisiert ihn bis zum Ende (▶️ läuft, ✅ abgeschlossen, ❌ ohne Erfolg, ⛔ abgebrochen). | Dem Link folgen, **Review deployments**, freigeben oder ablehnen. Bleibt der Kommentar auf ⏳ oder ▶️ stehen, obwohl der Lauf beendet ist, ist die Aktualisierung gescheitert (Warnung „Lauf-Kommentar“ im Lauf). |
| Lauf startet nicht nach Label | Absender oder Issue-Autor ist nicht der Owner, oder das falsche Label. | Bedingung in `.github/workflows/agent.yml` prüfen. Label entfernen und neu setzen. |
| Lauf wurde abgebrochen, obwohl ein neuer folgte | Pro Issue gilt ein Lauf zugleich, GitHub hält nur einen wartenden Lauf pro Gruppe. | Label auf demselben Issue erneut setzen, wenn der laufende Lauf fertig ist. |
| „Action is not allowed“ | Die Allowlist (Settings → Actions → General) kennt die Version nicht. Beim `setup-bun` in der Claude-Action ist der genaue SHA nötig. | Fehlenden Eintrag ergänzen, nach jedem Action-Update neu prüfen. |
| API-Doku ist veraltet oder fehlt | Der Workflow „API-Doku“ ist nicht gelaufen oder fehlgeschlagen (nur Änderungen an `openapi/**`, `site/**` und `pages.yml` lösen ihn aus). | Actions → **API-Doku** ansehen, bei Fehler die Meldung von `site/build.sh` lesen (ungültige Spec, Swagger-UI-Commit stimmt nicht). Neu starten: **Run workflow**. |
| Deploy der API-Doku scheitert an „Branch not allowed“ | Das Environment `github-pages` erlaubt nur bestimmte Branches. | Settings → Environments → `github-pages` → Deployment branches: `main` erlauben (nur `main`). |
| Authentifizierungsfehler im Lauf | Ein Zugang ist abgelaufen oder widerrufen. | `.github/ablaufdaten.json` und das Secret im Environment prüfen, Zugang erneuern. |
| Agent eröffnet keinen PR, kommentiert nur | Der Auftrag betrifft einen Schutzbereich oder verlangt Verbotenes. | Kommentar lesen. Die Änderung selbst durchführen oder das Issue anpassen. |
| `gh pr create` oder ein Befehl wird abgelehnt | Eine Deny-Regel oder fehlende Erlaubnis in `.claude/agent-settings.json`. | Annotation „Agent-Ablehnungen“ lesen. Regel nur mit Bedacht ändern (Schutzbereich, Admin-Bypass). |
| Lauf endet mit Turn-Limit | `--max-turns 60` erreicht, der Auftrag ist zu groß oder zu unscharf. | Issue verkleinern oder präzisieren (Akzeptanzkriterien, „Nicht Teil des Auftrags“). |
| Gate verändert Dateien | Flutter oder ein Generator schreibt in versionierte Dateien. | Annotation „Arbeitsverzeichnis“ lesen und die Datei einmal passend einchecken. |
| Rote CI auf `main` | Ein gemergter PR hat etwas gebrochen. | Per Revert-PR zurücknehmen, nicht per Force-Push. Den Agenten damit nicht beauftragen, solange die Ursache offen ist. |
| PR lässt sich nicht mergen | Code-Owner-Review fehlt (der Agent ist du, du kannst dich nicht selbst freigeben). | Mit Admin-Bypass mergen, wenn der PR Schutzbereiche berührt. Sonst Checks abwarten. |

## Swagger UI aktualisieren

Die API-Doku (`site/build.sh`) holt Swagger UI per Commit-SHA aus dem Repository `swagger-api/swagger-ui`, nicht aus einem
Paketregister. Dependabot sieht das nicht, es ist eine Handarbeit des Owners (`site/` ist Schutzbereich).

1. Neues Release-Tag auf https://github.com/swagger-api/swagger-ui/releases ansehen (Änderungen, Sicherheitshinweise). Ein
   Tag, das mindestens zwei Wochen alt ist, ist ein guter Kandidat.
2. Den Commit des Tags notieren: `git ls-remote https://github.com/swagger-api/swagger-ui.git "refs/tags/<tag>^{}"` (bei
   einem nicht annotierten Tag ohne `^{}`).
3. In `site/build.sh` `SWAGGER_UI_TAG` und `SWAGGER_UI_SHA` gemeinsam ändern, lokal `./site/build.sh` ausführen und die Seite
   ansehen (hell und dunkel).
4. PR öffnen (Schutzbereich, Admin-Bypass nötig). Nach dem Merge läuft der Workflow „API-Doku“ und veröffentlicht die Seite.

## Vertrag-Vorschau pro PR

Der Workflow `vertrag-vorschau.yml` kommentiert PRs, die `openapi/**` ändern. Der Link „Nachher“ ruft die Pages-Seite mit
`?spec=<Raw-URL mit Commit-SHA>` auf. Die Seite (`site/index.html`) akzeptiert nur Raw-URLs dieses Repos mit 40-stelliger
SHA und ignoriert alles andere. Es wird nichts deployt, das Environment `github-pages` bleibt auf `main` beschränkt.

| Symptom | Ursache | Maßnahme |
|---|---|---|
| Kein Kommentar am PR | `openapi/` nicht berührt, PR aus einem Fork, Workflow-Lauf rot | Lauf „Vertrag-Vorschau“ unter Actions ansehen |
| „Nachher“ zeigt einen Ladefehler | Der Browser darf `raw.githubusercontent.com` nicht laden (CORS; am 27.10.2026 funktionierte das Laden) oder die SHA gibt es nicht mehr | Konsole der Seite ansehen, Issue #113 |
| Link „Nachher“ zeigt den Vertrag von `main` mit Hinweis | Ältere Seite ohne `?spec=` oder Parameter nicht erlaubt | Workflow „API-Doku“ ausführen, die Seite neu bauen |

## Statische Badges im README pflegen

Die Badges „OpenAPI“, „Java“ und „Spring Boot“ im README sind Handarbeit und müssen zu den Dateien passen. Beim Update
der Versionen mitpflegen:

| Badge | Quelle der Wahrheit |
|---|---|
| OpenAPI (3.0.3) | `openapi/openapi.yaml` (Zeile `openapi:`) |
| Java (25) | `service/build.gradle.kts` (Toolchain) |
| Spring Boot (4.x) | `gradle/libs.versions.toml` (`spring-boot`) |
| Flutter (stable) | `frontend/` (Kanal stable) |

CI, API-Doku und CodeQL sind Live-Badges (Workflows `ci.yml`, `pages.yml` und das CodeQL-Default-Setup von GitHub) und
brauchen keine Pflege. Das CodeQL-Badge zeigt den letzten Lauf auf `main` und verlinkt auf die Code-Scanning-Ergebnisse.

## Zugänge erneuern

Beim Erneuern das Datum in `.github/ablaufdaten.json` anpassen und das Housekeeping-Issue schließen.

- **PAT `AGENT_GITHUB_TOKEN`:** neues fine-grained Token, nur dieses Repo, Rechte Contents, Pull requests und Issues
  schreibend, **ohne** Workflows-Recht, Laufzeit 90 Tage. Das Secret im Environment `agent` ersetzen.
- **OAuth-Token `CLAUDE_CODE_OAUTH_TOKEN`:** lokal `claude setup-token` ausführen, das Token nicht speichern und nirgends
  einfügen (nicht in Chats, Issues oder PR-Texte), nur als Secret im Environment `agent` ablegen.
- **Nach Action-Updates:** Allowlist prüfen (siehe Störungen), bei Bedarf neuen SHA eintragen.
- **Allowlist für die API-Doku (einmalig):** Settings → Actions → General → „Allow select actions“: `actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9`, `actions/deploy-pages@368f82528645a54fb793d4d04e342629a3f51346` und die von `upload-pages-artifact` genutzte `actions/upload-artifact@bbbca2ddaa5d8feaa63e36b76fdaad77386f024f` ergänzen.

## Updates der Action und von Claude Code

Roadmap B1. Die Action `anthropics/claude-code-action` ist in `agent.yml` und `agent-review.yml` per Commit-SHA
gepinnt (Kommentar mit Tag, zuletzt v1.0.261). Claude Code selbst installiert die Action zur Laufzeit (zuletzt
2.1.310), dort steht also nichts Gepinntes im Repo. Beides kann das Verhalten der Factory ändern, ohne dass im Repo
eine Zeile auffällt. Deshalb gilt: nie unbeobachtet springen, erst prüfen, dann pinnen.

**Wann:** Dependabot meldet eine neue Action-Version, oder der Owner will bewusst aktualisieren. Kleine Patch-Sprünge
dürfen warten, bis ohnehin ein Lauf ansteht. Bei Sicherheitshinweisen sofort.

**Vorgehen (Owner, denn die Workflows sind Schutzbereich):**

1. **Neues Tag lesen.** Release-Notes der Action und die Änderungen an Claude Code zwischen alter und neuer Version
   ansehen. Auf geänderte Eingaben, Berechtigungen, Standardwerte und Verhalten der Settings (`.claude/agent-settings.json`,
   Deny-Regeln) achten. Den SHA des Tags notieren (`gh api repos/anthropics/claude-code-action/git/ref/tags/<tag>`).
2. **Allowlist anpassen.** Settings → Actions → General: neuen SHA und, falls die Action ihre eigenen Unter-Actions
   ändert (zum Beispiel `setup-bun`), deren genauen SHA eintragen (siehe Störungen, „Action is not allowed“).
3. **In einem Branch ausprobieren.** Nur den SHA (und den Tag-Kommentar) in beiden Workflows ändern, als eigener PR.
   Der PR enthält nichts anderes.
4. **Referenzaufgaben laufen lassen.** Ein kleiner Satz bekannter Test-Issues (Roadmap M2, bis dahin zum Beispiel ein
   Fehlerfall, eine Spec-Änderung und ein Schutzbereich-Auftrag aus den Issues #18 bis #35) wird mit der neuen
   Version bearbeitet, auf einem Testbranch oder in einer Kopie des Issues. Vergleichen mit der alten Version:
   Gate grün, Exit-Code im PR-Text, `num_turns` und `total_cost_usd` im Log, keine neuen Einträge unter
   „Agent-Ablehnungen“, Schutzbereiche unangetastet, Review-Lauf (`/agent`) funktioniert.
5. **Entscheiden und pinnen.** Passt alles, wird der PR gemerged, der SHA bleibt damit gepinnt. Passt etwas nicht,
   bleibt es bei der alten Version, und die Abweichung kommt als Issue oder in die Roadmap.
6. **Festhalten.** Die neue Version (Action-Tag und die im Log sichtbare Claude-Code-Version) in `docs/roadmap.md`
   unter B1 nachtragen.

**Zurückrollen:** Revert-PR auf den alten SHA, kein Force-Push. Die Allowlist-Einträge der alten Version bleiben
dafür vorerst bestehen.

**Offen:** Ob die Action eine feste Claude-Code-Version erlaubt (Eingabe oder `claude_args`), ist hier nicht geprüft.
Der Owner sollte das in der `action.yml` des gewählten Tags nachlesen. Wenn ja, den Wert zusätzlich pinnen; ohne
Pin kann sich Claude Code zwischen zwei Läufen ändern, und Schritt 4 gilt nur für den Zeitpunkt der Prüfung.

## OAuth-Token widerrufen

Stand der Recherche (25.10.2026, aus einer anderen Claude-Sitzung und der dort genannten Doku übernommen, nicht von mir
geprüft). Für `claude setup-token` gibt es keinen Befehl zum Widerrufen. Das Token gilt laut Doku ein Jahr, wird nur
im Terminal ausgegeben und nirgends gespeichert. Es hängt am Abo der Person, die es erzeugt hat, und kann nur
Modellanfragen stellen (keine Remote-Control-Sitzungen, keine Connectoren).

1. **Bei GitHub eindämmen:** Secret im Environment `agent` löschen oder ersetzen, verdächtige Läufe abbrechen,
   Workflows abschalten (Notausschalter, Stufe 1 bis 3).
2. **Beim Anbieter widerrufen:** `claude.ai/settings/claude-code` öffnen und die passenden Einträge widerrufen, im
   Zweifel alle. Zusätzlich auf claude.ai alle Sitzungen abmelden.
3. **Prüfen, ob es wirkt:** `CLAUDE_CODE_OAUTH_TOKEN=<altes Token> claude -p "ping"` lokal ausführen, erwartet wird ein
   Fehler „OAuth token revoked“ (401). Das Token dafür nicht in Chats oder Issues einfügen.
4. **Wirkt es nicht:** Support einschalten (support.claude.com) und als Sicherheitsvorfall melden.
5. **Neu aufsetzen** (`/logout`, `/login`, neues Token als Secret).
6. **Spuren suchen und auswerten:** Prüfen, ob das Token in Logs, PRs, Issues oder Dateien aufgetaucht sein könnte, und
   dort bereinigen. Auf unerwarteten Abo-Verbrauch achten. Das GitHub-Audit-Log (Kategorie `workflows`, 180 Tage) gibt es
   nur für Organisationen, nicht für dieses persönliche Repo. Hier hilft die Lauf-Historie unter Actions.
   Bei Teams oder Enterprise zusätzlich den Org-Admin informieren.

**Unsicher:** Ob der Widerruf unter `claude.ai/settings/claude-code` für `setup-token`-Tokens greift und ob sie dort einzeln
erscheinen, ist nicht belegt. Es gibt offene Meldungen im Repository `anthropics/claude-code`, nach denen widerrufene
Tokens weiter funktionierten. Der Owner hat entschieden, den Widerruf nicht zu proben und das Restrisiko zu akzeptieren (ADR 0002, Roadmap S3). Im Ernstfall also die Schritte oben ausführen und das Ergebnis des Tests mit `claude -p` selbst prüfen.

**Robustere Alternativen (Roadmap S11):** ein API-Key aus der Console (jederzeit löschbar, klar dokumentierter Widerruf)
oder die Anmeldung per OIDC-Federation ohne statisches Secret.

**Quellen der Recherche** (vom Owner aus einer anderen Sitzung übernommen, von mir nicht abgerufen):
[Authentifizierung, langlebiges Token](https://code.claude.com/docs/en/authentication#generate-a-long-lived-token),
[GitHub Actions](https://code.claude.com/docs/en/github-actions),
[Fehlermeldungen](https://code.claude.com/docs/en/errors),
[Feature-Wunsch `--list`/`--revoke` (#48373)](https://github.com/anthropics/claude-code/issues/48373),
[weiterer Feature-Wunsch (#57400)](https://github.com/anthropics/claude-code/issues/57400),
[serverseitiger Widerruf (#34198)](https://github.com/anthropics/claude-code/issues/34198),
[Widerruf wirkungslos (#43801)](https://github.com/anthropics/claude-code/issues/43801),
[Widerruf-Schaltfläche reagiert nicht (#98582)](https://github.com/anthropics/claude-code/issues/98582),
[Einrichtung der Action inkl. Federation](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md),
[GitHub Environments](https://docs.github.com/en/actions/reference/environments).
Ein Suchtreffer deutete an, dass ein Widerruf inzwischen sofort wirkt. Bestätigt ist das nicht.

## Kontingent der Läufe lesen

Agent-Läufe und deine eigene Nutzung teilen sich das Abo-Kontingent (Pro: 5-Stunden-Fenster und Wochenlimit, Anzeige unter
claude.ai → Settings → Usage). Die Job-Zusammenfassung jedes Laufs hat die Zeile **Kontingent**. Sie listet Felder mit
`rate_limit` im Namen, Wiederholungsereignisse (`api_retry` mit Status und Kategorie) und den Text eines
fehlgeschlagenen Ergebnisses. Steht dort „keine Daten in der Ausgabe“, liefert der Lauf keine Kontingentangaben
(Stand 27.10.2026 nicht belegt, ob er sie liefert). Dann gilt die Nutzungsseite als einzige Quelle: vor und nach einem
Block mit Läufen nachsehen. Die Kosten in „Kennzahlen“ sind Schätzungen zum Listenpreis und keine Prozentwerte des
Kontingents. Die Zeile **Auslastung** fasst das lesbar zusammen: Sitzung und Woche in Prozent (aus dem letzten `rate_limit_info` mit
`unifiedWindows`, Auflösung 1 %) und die Reset-Zeiten in UTC. Die Zeile **Kennzahlen** nennt zusätzlich Tokens
(Eingabe, Ausgabe, Cache gelesen, Cache geschrieben); fehlt ein Feld, steht dort `?`. Ein einzelner Lauf bewegt die
Auslastung meist um weniger als einen Prozentpunkt, die Anzeige ändert sich erst über mehrere Läufe. Die Werte
teilen sich Läufe und deine eigene Nutzung. Hintergrund und Checkliste: Issue #102 und #118, übergeordnet #100.

## Reviewer einrichten und bedienen

Der Reviewer (Workflow `agent-reviewer.yml`, Roadmap P4) prüft PRs und Issues gegen die
[Definition of Done](../config/definition-of-done.md). Er ist schreibgeschützt und läuft **ohne Freigabe**.

**Einmalig einrichten (nur du, Weboberfläche):**

1. Settings > Environments > New environment: `factory-read`. **Keine** „Required reviewers“, aber Deployment branches
   auf `main` beschränken.
2. Im Environment ein Secret `CLAUDE_CODE_OAUTH_TOKEN` anlegen (Kopie des Tokens, das im Environment `agent` liegt;
   `claude setup-token` liefert ein neues, falls du den Wert nicht mehr hast). Das PAT `AGENT_GITHUB_TOKEN` kommt
   **nicht** hinein.
3. Optional Settings > Secrets and variables > Actions > Variables: `REVIEWER_MODEL` (zum Beispiel `sonnet`).
   Ohne Variable nimmt der Workflow `sonnet`. Das Modell des Laufs steht in der Job-Zusammenfassung („Modell“).
4. Neues Token-Datum in `.github/ablaufdaten.json` eintragen, falls ein neues Token erzeugt wurde.

**Bedienen:**

- **Automatisch:** Ein neuer oder aktualisierter PR auf einem `agent/*`-Branch (Autor `juheba`, gleiches Repo, kein
  Entwurf) löst ein Review aus. Pro Commit höchstens eines, höchstens 5 automatische Reviews pro PR. Der Kommentar
  wird aktualisiert, nicht dupliziert.
- **Auf Zuruf:** Ein Kommentar `/review` von dir auf jedem Issue oder PR, optional mit Hinweis
  (`/review achte besonders auf Fehlerfälle`). Auf einem Issue prüft er den Auftrag, auf einem PR den Diff (auch bei
  fremden Branches und Forks). Jeder Zuruf erzeugt einen eigenen Kommentar.
- **Unterschied zu `/agent`:** `/agent` startet den Umsetzer (schreibt Code, mit Freigabe), `/review` den Reviewer
  (schreibt nie, ohne Freigabe).

**Wirkt erst nach dem Merge:** `pull_request_target` und `issue_comment` laufen mit dem Workflow aus `main`.

**Rechte des Laufs:** Der Job `review` hat nur lesende Rechte (`contents`, `issues`, `pull-requests`, `checks`,
`statuses`; siehe `.github/workflows/agent-reviewer.yml`, Job `review`). `checks` und `statuses` braucht er, damit er den
CI-Stand der Pflicht-Checks in einer Zeile nennen kann. Beurteilt wird das Gate (DoD-1) dadurch nicht, das erzwingt das
Ruleset. Fehlt die Zeile mit dem CI-Stand, prüfe zuerst, ob diese beiden Rechte im Workflow noch stehen.
Begründung: [ADR 0002](adr/0002-agent-sicherheit.md), Abschnitt „Reviewer ohne Freigabe“.

**Notausschalter:** Environment `factory-read` löschen oder das Secret entfernen, dann scheitert der Job `review`
(der Kommentar meldet den Fehler). Härter: Workflow in der Actions-Oberfläche deaktivieren.

## Zuständigkeit

Alles läuft über den Owner: Freigabe der Läufe, Review, Merge, Zugänge. Wird die Factory von mehr Personen genutzt,
gehört das hier überarbeitet (Roadmap S5, eigene Bot-Identität).
