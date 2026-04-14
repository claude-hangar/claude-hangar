# Claude Code CLI – Vollstaendige Referenz

## Stand: v2.1.105 (13. April 2026)

> v2.1.100 ist ein Re-Release von v2.1.98 (identischer Code, npm dist-tag Promotion).
> v2.1.99, v2.1.102, v2.1.103 wurden nicht veroeffentlicht.

### Aenderungen v2.1.105

#### Neue Features

- **`EnterWorktree` `path`-Parameter** — Wechsel in einen bestehenden Worktree des aktuellen Repos via Tool-Parameter statt manuellem `cd`
- **PreCompact Hook blockierend** — Hooks koennen Compaction jetzt verhindern: Exit-Code 2 oder `{"decision":"block"}` abbrechen den Kompaktierungs-Vorgang
- **`monitors` Plugin-Manifest** — Top-Level-Feld `monitors` in plugin.json; Background-Monitore werden bei Session-Start oder Skill-Invoke automatisch armed
- **`/proactive` Alias fuer `/loop`** — zusaetzlicher Einstiegsname fuer den Loop-Operator

#### Verbesserungen

- **Stalled-Stream-Handling** — Streams brechen nach 5 Minuten ohne Daten ab und retryen non-streaming statt haengen zu bleiben
- **Netzwerk-Fehlermeldungen** — Connection-Errors zeigen sofort eine Retry-Nachricht statt stiller Spinner
- **File-Write-Anzeige** — Lange Single-Line-Writes (z.B. minified JSON) werden in der UI truncated statt ueber viele Screens paginiert
- **`/doctor` Layout** — Status-Icons; `f`-Taste laesst Claude die gemeldeten Probleme direkt beheben
- **`/config` Labels** — Klarere Bezeichnungen und Beschreibungen
- **Skill-Descriptions** — Listing-Cap von 250 auf 1.536 Zeichen erhoeht; Startup-Warnung wenn Description truncated wird
- **`WebFetch`** — Entfernt `<style>` und `<script>` Inhalte; CSS-lastige Seiten erschoepfen das Content-Budget nicht mehr vor dem eigentlichen Text
- **Stale-Worktree-Cleanup** — Worktrees mit squash-mergten PRs werden entfernt statt unbegrenzt zu bleiben
- **MCP-Large-Output Truncation-Prompt** — Format-spezifische Rezepte (`jq` fuer JSON, berechnete Read-Chunk-Groessen fuer Text)

#### Fixes

- Bilder in queued Messages (waehrend Claude arbeitet) gingen verloren
- Leerer Bildschirm wenn Prompt-Input in langen Conversations auf zweite Zeile umbricht
- Leading Whitespace beim Copy mehrzeiliger Antworten im Fullscreen
- Leading Whitespace in Assistant-Messages getrimmt — brach ASCII-Art und Diagramme
- Verstuemmelte Bash-Ausgabe bei klickbaren File-Links (Python `rich`/`loguru`)
- `alt+enter` / `Ctrl+J` fuegt Newlines wieder korrekt ein (Regression in 2.1.100)
- Doppelter "Creating worktree"-Text in EnterWorktree/ExitWorktree
- Queued User-Prompts verschwanden aus Focus-Mode
- One-Shot Scheduled-Tasks feuerten wiederholt bei verpasstem Post-Fire-Cleanup
- Inbound-Channel-Notifications nach erster Message still verworfen (Team/Enterprise)
- Marketplace-Plugins mit `package.json`/Lockfile hatten Dependencies nicht auto-installiert
- Marketplace Auto-Update liess offizielle Marketplace in broken State wenn Plugin-Prozess Dateien offen hielt
- "Resume this session with..."-Hinweis fehlte nach `/resume`, `--worktree`, `/branch`
- Feedback-Survey-Shortcuts feuerten mitten in laengeren Prompts
- stdio-MCP-Server mit malformed Output haengte Session statt "Connection closed"
- MCP-Tools fehlten in erster Turn von Headless/Remote-Trigger-Sessions bei asynchronen MCP-Verbindungen
- `/model` Picker auf Bedrock (Non-US Regions) persistierte invalide `us.*` IDs
- 429-Rate-Limit-Errors zeigten rohes JSON statt sauberer Meldung (API-Key, Bedrock, Vertex)
- Crash bei Resume mit malformed Text-Blocks
- `/help` verlor Tab-Bar, Shortcuts, Footer bei kleiner Terminal-Hoehe
- Malformed `keybindings.json`-Werte wurden still geladen statt klar abgelehnt
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` in einem Projekt disablete Usage-Metrics fuer alle Projekte
- Washed-Out 16-Color-Palette bei Ghostty/Kitty/Alacritty/WezTerm/foot/rio/Contour ueber SSH/mosh
- Bash-Tool schlug `acceptEdits`-Mode vor waehrend Exit aus Plan-Mode ein Downgrade gewesen waere

### Aenderungen v2.1.101

#### Neue Features

- **`/team-onboarding`** — Command generiert Teammate-Ramp-Up-Guide aus lokaler Claude-Code-Nutzung
- **OS CA Certificate Store Trust** — Enterprise-TLS-Proxies funktionieren ohne Extra-Setup; `CLAUDE_CODE_CERT_STORE=bundled` fuer nur-gebundelte CAs
- **`/ultraplan` & Remote-Session-Features** — Auto-Creation einer Default-Cloud-Environment statt erzwungenem Web-Setup

#### Verbesserungen

- **Brief-Mode Retry** — Bei Plain-Text-Antwort statt Structured-Message wird einmal retryed
- **Focus-Mode Summaries** — Claude schreibt selbstenthaltene Summaries weil der User nur die Final-Message sieht
- **Tool-not-available-Errors** — Erklaeren warum und wie fortzufahren ist wenn das Tool existiert, aber im aktuellen Context nicht verfuegbar
- **Rate-Limit-Retry-Messages** — Zeigen welches Limit getroffen wurde und wann es resettet
- **Refusal-Error-Messages** — Enthalten API-provided Explanation
- **`claude -p --resume <name>`** — Akzeptiert Session-Titles aus `/rename` oder `--name`
- **Settings-Resilienz** — Unrecognized Hook-Event-Names in `settings.json` ignorieren nicht mehr die gesamte Datei
- **`allowManagedHooksOnly`** — Plugin-Hooks aus force-enabled Plugins via Managed-Settings laufen jetzt
- **`/plugin` & `claude plugin update`** — Warnung bei Marketplace-Refresh-Fehler statt still stale Version
- **Plan-Mode** — "Refine with Ultraplan" versteckt wenn User-Org/Auth-Setup kein Claude-Code-Web hat
- **Beta-Tracing** — Honoriert `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_DETAILS`, `OTEL_LOG_TOOL_CONTENT`
- **SDK `query()`** — Bereinigt Subprocess und Temp-Files bei `break` aus `for await` oder `await using`

#### Security-Fixes

- **CRITICAL:** Command-Injection-Vulnerability im POSIX `which`-Fallback der LSP-Binary-Detection

#### Fixes

- Memory-Leak bei langen Sessions mit historischen Message-List-Kopien im Virtual-Scroller
- `--resume`/`--continue` verlor Conversation-Context bei grossen Sessions (Loader-Anchor auf Dead-End-Branch)
- `--resume` Chain-Recovery wechselte in unrelated Subagent-Conversation
- Crash bei `--resume` mit Edit/Write-Tool-Result ohne `file_path`
- Hardcoded 5-Min-Request-Timeout brach slow Backends (Local-LLMs, Extended-Thinking)
- `permissions.deny` Rules ueberschreiben `permissionDecision: "ask"` aus PreToolUse-Hooks
- `--setting-sources` ohne `user` ignorierte `cleanupPeriodDays` — loeschte History > 30 Tage
- Bedrock SigV4-Auth scheiterte mit 403 wenn `ANTHROPIC_AUTH_TOKEN`/`apiKeyHelper`/`ANTHROPIC_CUSTOM_HEADERS` Authorization-Header setzte
- `claude -w <name>` scheiterte mit "already exists" nach Stale-Worktree-Cleanup
- Subagents erbten keine MCP-Tools aus dynamisch-injizierten Servern
- Sub-Agents in isolierten Worktrees bekamen keinen Read/Edit-Zugriff innerhalb des eigenen Worktrees
- Sandboxed Bash-Commands scheiterten mit `mktemp: No such file or directory` nach Boot
- `claude mcp serve` Tool-Calls fehl in Clients die `outputSchema` validieren
- `RemoteTrigger.run` sendete leeren Body
- `/resume` Picker diverse Fixes (Narrow-Default-View, Preview auf Windows-Terminal, cwd in Worktrees, Session-not-found-Errors)
- Grep-Tool ENOENT bei stalem embedded ripgrep (VS Code Auto-Update, macOS App Translocation) — Self-Heal ueber System-`rg`
- `/btw` schrieb Konversations-Kopie auf Platte bei jedem Use
- `/context` Free-Space/Messages-Breakdown widersprach Header-Prozent
- Plugin-Issues: Slash-Commands mit duplicate `name:`, `/plugin update` `ENAMETOOLONG`, Discover zeigte already-installed, Directory-Source stale Version-Cache, Skills honorierten `context: fork`/`agent` nicht
- `/mcp` Menu bot OAuth-Actions fuer MCP-Server mit `headersHelper` — jetzt Reconnect
- `ctrl+]`, `ctrl+\`, `ctrl+^` Keybindings feuerten nicht in Terminals mit Raw C0 Control-Bytes
- Custom Keybindings (`~/.claude/keybindings.json`) luden nicht bei Bedrock/Vertex
- `claude --continue -p` continued keine `-p`/SDK-Sessions
- Remote-Control-Issues: Worktrees entfernt bei Crash, Connection-Failures nicht im Transcript
- `/insights` liess manchmal Report-File-Link weg
- [VSCode] File-Attachment unter Chat-Input loeschte sich nicht wenn letzter Editor-Tab geschlossen wurde

### Aenderungen v2.1.98

#### Neue Features

- **Google Vertex AI Setup Wizard** — Interaktiver Wizard im Login-Screen unter "3rd-party platform" (GCP Auth, Projekt/Region, Credentials, Model-Pinning)
- **`CLAUDE_CODE_PERFORCE_MODE`** — Edit/Write/NotebookEdit schlagen fehl bei Read-only-Dateien mit `p4 edit`-Hinweis
- **Monitor Tool** — Neues Tool zum Streamen von Events aus Background-Scripts
- **Subprocess Sandboxing** — PID-Namespace-Isolation auf Linux via `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`, neuer `CLAUDE_CODE_SCRIPT_CAPS` Env-Var
- **`--exclude-dynamic-system-prompt-sections`** — Neues Print-Mode Flag fuer besseres Cross-User Prompt-Caching
- **`workspace.git_worktree`** — Neues Feld im StatusLine JSON-Input bei Git-Worktree-Verzeichnissen
- **`TRACEPARENT` in Bash** — W3C-Tracing-Header wird an Subprozesse uebergeben wenn OTEL aktiv
- **LSP `clientInfo`** — Claude Code identifiziert sich bei Language Servern via Initialize-Request

#### Security-Fixes

- **CRITICAL:** Bash-Tool Permission-Bypass via Backslash-escaped Flags (arbitrary code execution)
- **CRITICAL:** Compound Bash-Commands umgehen forced Permission-Prompts in Auto/Bypass-Modes
- **HIGH:** Read-only Commands mit Env-Var-Prefixen prompten nicht (nur bekannte safe vars: `LANG`, `TZ`, `NO_COLOR`)
- **HIGH:** Redirects zu `/dev/tcp/...` oder `/dev/udp/...` werden nicht auto-allowed
- **HIGH:** `grep -f FILE` / `rg -f FILE` prompten nicht bei Pattern-Files ausserhalb Working-Dir
- **HIGH:** `--dangerously-skip-permissions` still downgraded nach Protected-Path-Write
- **HIGH:** Agent-Team-Members erben nicht den Permission-Mode des Leaders

#### Hooks

- **Stop/SubagentStop Hooks** schlagen nicht mehr fehl bei langen Sessions
- **Hook-Evaluator API-Errors** zeigen jetzt echte Fehlermeldung statt "JSON validation failed"
- **Hook-Errors im Transcript** enthalten erste Zeile von stderr fuer Self-Diagnosis

#### MCP

- **OAuth:** `oauth.authServerMetadataUrl` wird bei Token-Refresh nach Restart beachtet (ADFS-Fix)
- **MCP Tools** mit `_meta["anthropic/maxResultSizeChars"]` bypassen Token-based Persist-Layer
- **Crash behoben** beim Hover ueber MCP-Tool-Results im Fullscreen-Mode

#### Agents & Skills

- **`/agents`** hat Tabbed Layout: Running-Tab zeigt Live-Subagents, Library-Tab hat "Run agent" und "View running instance"
- **Background Subagents** reporten bei Fehler Partial-Progress zum Parent
- **Stale Subagent-Worktree Cleanup** entfernt keine Worktrees mit Untracked Files mehr
- **`/reload-plugins`** laedt Plugin-Skills ohne Restart (Hot-Reload)
- **Slash-Command-Picker** crasht nicht mehr bei YAML-Boolean-Keywords in Plugin-Frontmatter

#### Settings & Permissions

- **`permissions.additionalDirectories`** wirkt Mid-Session (sofortiger Entzug/Zugriff)
- **`Bash(cmd:*)` und `Bash(git commit *)`** Wildcard-Rules matchen bei Extra-Spaces/Tabs
- **`Bash(...)` Deny-Rules** werden nicht zu Prompt downgraded bei Piped-Commands mit `cd`
- **Managed-Settings Allow-Rules** bleiben nicht aktiv nach Admin-Entfernung
- **Permission-Rules mit JS-Prototype-Namen** (z.B. `toString`) ignorieren nicht mehr settings.json

#### UI/UX

- **Vim Mode:** `j`/`k` in NORMAL navigieren History und Footer-Pill
- **Accept Edits Mode:** Auto-Approve fuer Filesystem-Commands mit safe Env-Vars
- **`/resume` Picker:** Filter-Hints, Project/Worktree/Branch-Names, diverse Fixes
- **`/export`:** Akzeptiert absolute Pfade und `~`, keine Zwangs-.txt-Extension
- **`/effort max`:** Funktioniert mit unbekannten/zukuenftigen Model-IDs
- **Transcript-Entries** tragen finale Token-Usage statt Streaming-Placeholders

#### Weitere Fixes

- Streaming-Responses fallen auf Non-Streaming zurueck statt Timeout
- 429-Retries nutzen Exponential-Backoff statt alle Attempts in ~13s
- Capital-Letters werden nicht zu Lowercase auf xterm/VSCode bei Kitty-Protocol
- Memory-Leak bei Remote-Control Permission-Handlers behoben
- `DISABLE_AUTOUPDATER` unterdrueckt vollstaendig den npm-Version-Check
- **[VSCode]** False-Positive "requires git-bash" auf Windows behoben wenn `CLAUDE_CODE_GIT_BASH_PATH` gesetzt

### Aenderungen v2.1.92

- `forceRemoteSettingsRefresh` Policy-Setting: CLI blockiert Start bis Remote-Settings geladen, Exit bei Fehler (fail-closed)
- Interaktiver Bedrock Setup-Wizard im Login-Screen (AWS Auth, Region, Credentials, Model-Pinning)
- `/cost` zeigt jetzt per-Modell und Cache-Hit Aufschluesselung (Subscription-User)
- `/release-notes` ist jetzt ein interaktiver Version-Picker
- Remote Control Session-Namen nutzen Hostname als Default-Prefix (z.B. `myhost-graceful-unicorn`)
- Pro-User sehen Footer-Hint bei Prompt-Cache-Expiry nach Session-Rueckkehr
- Write-Tool Diff-Berechnung **60% schneller** bei grossen Dateien
- **Entfernt:** `/tag` und `/vim` Commands (Vim-Mode jetzt via `/config` → Editor Mode)
- Linux Sandbox: `apply-seccomp` Helper in npm und native Builds (Unix-Socket-Blocking)

### Aenderungen v2.1.91

- MCP Tool Result Persistence Override via `_meta["anthropic/maxResultSizeChars"]` (bis 500K) — grosse Ergebnisse wie DB-Schemas passieren ohne Truncation
- `disableSkillShellExecution` Setting: Deaktiviert Shell-Ausfuehrung in Skills, Slash-Commands und Plugin-Commands
- Multi-Line-Prompts in `claude-cli://open?q=` Deep Links (encoded Newlines `%0A`)
- Plugins koennen Executables unter `bin/` shippen und als bare Commands aus dem Bash-Tool aufrufen
- Fix: Transcript Chain Breaks bei `--resume` (async Write Failures)
- Fix: `cmd+delete` funktioniert jetzt in iTerm2, kitty, WezTerm, Ghostty, Windows Terminal

### Aenderungen v2.1.90

- `/powerup` — interaktive Lessons mit animierten Demos fuer Claude Code Features
- `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE` Env-Var fuer Offline-Umgebungen
- `.husky` zu Protected Directories (acceptEdits Mode)
- Auto Mode respektiert jetzt explizite User-Grenzen ("don't push", "wait for X before Y")
- SSE-Transport verarbeitet grosse Frames in **linearer Zeit** (war quadratisch)
- PowerShell: Security-Hardening (Background-Job-Bypass, Debugger-Hang, TOCTOU-Fixes)
- Fix: Infinite Loop bei Rate-Limit-Options-Dialog
- Fix: `--resume` Full Prompt-Cache-Miss bei deferred Tools/MCP/Custom Agents (Regression seit v2.1.69)
- Fix: `Edit`/`Write` "File content has changed" bei PostToolUse Format-on-Save Hooks

### Aenderungen v2.1.89

- **`"defer"` Permission Decision in PreToolUse Hooks** — Headless Sessions pausieren bei Tool-Call, Resume mit `-p --resume`
- `CLAUDE_CODE_NO_FLICKER=1` Env-Var fuer Flicker-Free Alt-Screen Rendering
- **`PermissionDenied` Hook** — feuert nach Auto-Mode Classifier Denials, `{retry: true}` fuer Retry
- Named Subagents in `@` Mention Typeahead
- `MCP_CONNECTION_NONBLOCKING=true` fuer `-p` Mode (Skip MCP Connection Wait), 5s Bound statt unbounded
- `showThinkingSummaries: true` Setting — Thinking-Summaries nicht mehr standardmaessig in interaktiven Sessions
- Hook-Output ueber 50K Zeichen wird auf Disk gespeichert (Datei-Pfad + Preview statt direkte Context-Injection)
- Edit-Tool funktioniert auf Dateien die via `Bash` mit `sed -n`/`cat` angesehen wurden (kein separater Read noetig)
- Auto Mode: Denied Commands zeigen Notification, erscheinen in `/permissions` → Recent Tab
- Fix: StructuredOutput Schema-Cache Bug (~50% Failure-Rate bei mehreren Schemas)

### Aenderungen v2.1.87

- Fix: Cowork Dispatch — Nachrichten werden jetzt zuverlaessig zugestellt

### Aenderungen v2.1.86

- `X-Claude-Code-Session-Id` Header in API-Requests fuer Proxy-Session-Tracking
- `.jj` und `.sl` in VCS-Ausschlusslisten (Jujutsu, Sapling Support)
- MCP-Tool-Beschreibungen auf 2KB gekappt (OpenAPI-Server Context-Schutz)
- MCP-Server Deduplizierung (lokal > claude.ai Connector)
- Voice Push-to-Talk Fix (keine Zeichenlecks mehr)
- Remote Control /poll Rate 300x reduziert (10min statt 1-2s)
- VS Code: Plan-Dokument-Ansicht mit Kommentaren
- VS Code: Native MCP-Server-Verwaltung via `/mcp`
- Default Opus 4.6 auf Bedrock, Vertex und Microsoft Foundry (war Opus 4.1)

---

# 1. ARCHITEKTUR-ÜBERBLICK

Claude Code ist ein agentisches CLI-Tool, das Codebases liest, Befehle ausführt, Dateien bearbeitet, Git-Workflows steuert, externe Services via MCP anbindet und Aufgaben an spezialisierte Sub-Agenten delegiert.

## Kern-Systeme

- **Konfiguration**: claude.md, settings.json, .claude.json
- **Berechtigungen**: Gestuftes Permission-System mit Wildcard-Support
- **Skills**: On-demand Wissens- und Workflow-Pakete (Hot-Reload, Forked Context, `paths:` YAML-Glob-Filter)
- **Sub-Agenten**: Isolierte Claude-Instanzen mit eigenen Tools/Modellen/Memory
- **Hooks**: Automatisierung vor/nach Tool-Aufrufen (inkl. Setup, Agent Teams Events)
- **MCP**: Anbindung externer Services (stdio, SSE, Streamable HTTP, OAuth)
- **Plugins**: Paketierte Bundles aus Skills + Agents + Hooks + MCP
- **Chrome Integration**: Browser-Steuerung direkt aus dem Terminal (Beta)

## Verfügbare Modelle

| Modell | Einsatz | Preis (Input/Output per MTok) |
|--------|---------|-------------------------------|
| Opus 4.6 | Komplexes Reasoning, Architektur | $5 / $25 (>200K: $10/$37.50) |
| Sonnet 4.6 | Tägliche Entwicklung (neuestes Sonnet) | Günstiger |
| Sonnet 4.5 | Tägliche Entwicklung | Günstiger |
| Haiku 4.5 | Sub-Agenten, schnelle Aufgaben | ~15x günstiger als Opus |

**Empfehlung**: Sonnet 4.6 als Default, Haiku fuer Sub-Agenten/Exploration, Opus fuer schwere Reasoning-Aufgaben.

**Opusplan-Modus**: Opus für Planung + Sonnet für Ausführung (Kosten-Hybrid).

**Fast Mode**: Verfügbar für Opus 4.6 – schnellere Antworten bei einfacheren Aufgaben. Toggle mit `/fast`.

**Adaptive Thinking**: Opus 4.6 entscheidet selbst wann und wie intensiv er denkt — kein manuelles Toggle noetig.

**Modell-Wechsel**: Alt+P waehrend der Eingabe — kein Neustart noetig.

## Context Window

- Standard: 200K Tokens
- Opus 4.6: 1M Tokens (Beta)
- Max Output: 128K Tokens
- Skill-Budget: 2% des Context Windows für Skill-Beschreibungen

---

# 2. KONFIGURATION

## 2.1 claude.md (CLAUDE.md)

Persistenter Kontext, der bei jeder Session geladen wird. Wird als User-Message nach dem System-Prompt injiziert.

### Hierarchie (alle additiv)

```
Enterprise Policy       → Höchste Priorität (Admin-gesteuert)
~/.claude/claude.md     → Global (alle Projekte)
./claude.md             → Projekt-Root
./.claude/claude.md     → Alternative Projekt-Position
./src/claude.md         → Unterordner (Monorepo)
--add-dir Pfade         → Zusätzliche Verzeichnisse
```

### Best Practices

- Max ~500 Zeilen empfohlen
- Wenn sie wächst → Inhalte in Skills auslagern
- Enthält: Coding-Standards, Build-Commands, Projektstruktur, "never do X"-Regeln
- Nicht für: Referenzmaterial, Workflows, tiefes Fachwissen (→ Skills)

### Unterschied zu --append-system-prompt

- `claude.md` → User-Message nach System-Prompt
- `--append-system-prompt` → Wird an System-Prompt angehängt
- Output Styles → Ersetzen Teile des System-Prompts direkt

## 2.2 settings.json

```
~/.claude/settings.json        → Global
./.claude/settings.json        → Projekt
~/.claude/settings.local.json  → Lokal (nicht in Git)
```

Enthält: Berechtigungen, Hooks, MCP-Server, Model-Overrides, Sandbox-Regeln.

## 2.3 .claude.json

Projekt-Konfiguration im Root-Verzeichnis.

---

# 3. SKILLS

Skills sind on-demand Wissens- und Workflow-Pakete mit YAML-Frontmatter.

## 3.1 Dateistruktur

```
.claude/skills/
└── my-skill/
    ├── SKILL.md           # Pflicht
    ├── reference.md       # Optional: Zusatz-Doku
    ├── templates/         # Optional: Vorlagen
    └── scripts/           # Optional: Ausführbare Skripte
```

## 3.2 Speicherorte

| Ort | Scope | Verfuegbarkeit |
|-----|-------|---------------|
| ~/.claude/skills/ | User | Alle Projekte |
| .claude/skills/ | Projekt | Nur dieses Projekt (Git-teilbar) |
| --add-dir Pfade | Zusaetzlich | Automatisch geladen (CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1) |
| Plugin-Skills | Plugin | Nach Installation (namespaced: /plugin:skill) |

**Nested Skills:** Verschachtelte `.claude/skills/`-Verzeichnisse werden automatisch entdeckt (Auto-Discovery).

## 3.3 SKILL.md Format

### Pflicht-Felder

```yaml
---
name: skill-name
description: Was der Skill tut UND wann Claude ihn nutzen soll.
---
Markdown-Inhalt mit Anweisungen...
```

### Alle Frontmatter-Felder

```yaml
---
name: secure-deploy                    # Wird zu /secure-deploy Slash-Command
description: >
  Deploy workflow with safety checks.
  Use when deploying to production or
  when user mentions "deploy" or "release".
allowed-tools: Bash, Read, Grep        # Tool-Einschraenkung (ohne = alle erlaubt)
disable-model-invocation: true         # Nur manuell via /name, nie auto-getriggert
context: fork                          # Laeuft als isolierter Sub-Agent
agent: Explore                         # Welcher Agent bei context:fork
hooks:                                 # Lifecycle-Hooks
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint.sh"
---
```

## 3.4 Progressive Disclosure

1. Session-Start: Nur Frontmatter geladen (~100 Tokens pro Skill)
2. Bei Bedarf: Voller SKILL.md-Inhalt wird gelesen
3. Supporting Files: Nur wenn im SKILL.md referenziert und benoetigt
4. **Hot-Reload**: Aenderungen an Skills sofort wirksam ohne Neustart

**Argument-Syntax:**
```bash
/deploy staging          # $ARGUMENTS = "staging"
/deploy staging --force  # $ARGUMENTS[0] = "staging", $ARGUMENTS[1] = "--force"
```
Kurzform: `$0`, `$1` etc. Bracket-Syntax `$ARGUMENTS[0]` (nicht `$ARGUMENTS.0`).

**String-Substitution:** `${CLAUDE_SESSION_ID}` verfuegbar in Skills.

## 3.5 Invocation-Typen

| Typ | Trigger | Beispiel |
|-----|---------|---------|
| Auto (Standard) | Claude entscheidet anhand description | "Review this code" → code-reviewer |
| Manuell | User tippt /skill-name | /deploy |
| Nur manuell | disable-model-invocation: true | /dangerous-operation |
| Forked | context: fork | Eigener Kontext, keine Verschmutzung |

## 3.6 Skill vs claude.md Entscheidung

- **claude.md**: Claude soll es IMMER wissen (Konventionen, Build-Commands)
- **Skill**: Claude soll es MANCHMAL wissen (API-Docs, Deployment-Workflow)

---

# 4. SUB-AGENTEN

Isolierte Claude-Instanzen mit eigenen Tools, Modell, Berechtigungen und Kontext.

## 4.1 Dateiformat

```yaml
---
name: code-reviewer
description: Reviews code for quality. Use when reviewing PRs.
model: sonnet
tools: Read, Glob, Grep
disallowedTools: Write, Edit
permissionMode: default
maxTurns: 20
skills:
  - api-conventions
  - error-handling
memory: user
mcpServers:
  - my-db-server
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate.sh"
---
Du bist ein Code-Reviewer. Fokus auf Security, Performance, Best Practices.
```

## 4.2 Speicherorte

| Ort | Scope |
|-----|-------|
| ~/.claude/agents/ | Global (alle Projekte) |
| .claude/agents/ | Projekt (Git-teilbar) |
| --agents JSON Flag | Nur diese Session |
| Plugin-Agents | Nach Installation |

## 4.3 Frontmatter-Felder

| Feld | Zweck |
|------|-------|
| name | Identifikation |
| description | Wann Claude den Agent vorschlägt |
| model | sonnet / opus / haiku |
| tools | Erlaubte Tools (Read, Grep, Glob, Bash, Write, Edit...) |
| disallowedTools | Explizit verbotene Tools |
| skills | Liste von Skills die geladen werden |
| memory | user / project / local (persistent) |
| permissionMode | Berechtigungsmodus |
| maxTurns | Max Iterationen |
| mcpServers | MCP-Server Zugriff |
| hooks | Lifecycle-Hooks |

## 4.4 Memory

Persistentes Verzeichnis das zwischen Sessions überlebt.

- Agent baut Wissen auf (Patterns, Bugs, Architektur)
- Erste 200 Zeilen von MEMORY.md werden in System-Prompt geladen
- Scopes: user (global), project (pro Projekt), local (pro Maschine)

## 4.5 Skills vs Sub-Agenten

| | Skill | Sub-Agent |
|---|---|---|
| Läuft in | Hauptkontext | Eigener isolierter Kontext |
| Gibt zurück | Direkt im Chat | Summary an Hauptkontext |
| Nutzen wenn | Wissen/Workflow im aktuellen Kontext | Aufgabe isoliert + zusammenfassbar |
| Token-Impact | Verbraucht Hauptkontext | Eigenes Budget |

## 4.6 CLI-Agenten (einmalig)

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

## 4.7 Management

```
/agents              # Alle anzeigen (auch via Session Management)
/agents create       # Neuen erstellen (interaktiv)
/agents edit         # Bearbeiten
/agents delete       # Loeschen
/agents list         # Auflisten
```

## 4.8 Parallel & Sequenziell

```
# Sequenziell
> Nutze erst code-analyzer für Performance-Issues, dann optimizer zum Fixen

# Parallel
> Starte 3 Explore-Agents parallel:
> 1. Authentication Code
> 2. Database Models
> 3. API Routes
```

## 4.9 Background Agents

```
> Starte Security-Review im Hintergrund während ich am Frontend arbeite
> /tasks    # Status prüfen
```

---

# 5. HOOKS

Automatische Aktionen die an bestimmten Punkten im Agentic Loop ausgeführt werden.

## 5.1 Hook Events

| Event | Wann | Typischer Einsatz |
|-------|------|-------------------|
| Setup | `--init` / `--init-only` / `--maintenance` | Projekt-Initialisierung, Env-Setup |
| SessionStart | Session startet/resumed | Kontext laden, Env-Vars setzen |
| PreToolUse | Vor jedem Tool-Aufruf | Validierung, Sicherheitschecks |
| PostToolUse | Nach jedem Tool-Aufruf | Linting, Formatting, Tests |
| Stop | Session endet | Cleanup, Notifications |
| SubagentStart | Sub-Agent gestartet | Observability, Ressourcen-Tracking |
| SubagentStop | Sub-Agent fertig | Ergebnis-Verarbeitung |
| TaskCreated | Task wird erstellt (TaskCreate) | Logging, Validierung, Task-Policies |
| TaskCompleted | Task abgeschlossen | Naechsten Schritt triggern, Quality Gates |
| WorktreeCreate | Worktree erstellt | Pfad-Kontrolle, Setup (auch HTTP-Hook) |
| PermissionDenied | Auto-Mode Classifier lehnt ab | `{retry: true}` fuer Retry, Logging (v2.1.89+) |
| TeammateIdle | Teammate wartet (Agent Teams) | Task-Zuweisung |

## 5.2 Hook-Typen

| Typ | Beschreibung |
|-----|-------------|
| command | Shell-Befehl ausfuehren |
| prompt | Schneller Single-Turn an Claude |
| agent | Sub-Agent mit Tool-Zugriff spawnen |
| http | HTTP-Request an externen Service (JSON-Antwort mit hookSpecificOutput) |

## 5.3 Konfiguration

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/validate.sh\""
          }
        ]
      }
    ]
  }
}
```

- `matcher` unterstuetzt Regex (`Write|Edit`, `Bash`)
- `$CLAUDE_PROJECT_DIR` wird vom System expandiert — fuer zuverlaessige Pfade nutzen
- `once: true` — Hook wird nur einmal pro Session ausgefuehrt (z.B. einmaliges Setup)
- **`if` (2.1.85+):** Bedingungsfeld mit Permission-Rule-Syntax (z.B. `Bash(git *)`) — Hook wird nur ausgefuehrt wenn der Tool-Call dem Pattern entspricht. Reduziert Prozess-Overhead erheblich
- `PreToolUse`-Hooks koennen `additionalContext` im stdout zurueckgeben → wird an das Modell weitergereicht
- **PreToolUse + AskUserQuestion (2.1.85+):** Hooks koennen `AskUserQuestion` beantworten indem sie `updatedInput` zusammen mit `permissionDecision: "allow"` zurueckgeben — ermoeglicht Headless-Integrationen mit eigener UI
- **PreToolUse + `"defer"` Decision (2.1.89+):** Headless Sessions koennen bei einem Tool-Call pausieren, spaeter mit `-p --resume` fortsetzen und den Hook erneut evaluieren lassen
- **PermissionDenied Hook (2.1.89+):** Feuert nach Auto-Mode Classifier Denials — `{retry: true}` im Output laesst das Modell den Versuch wiederholen
- **MCP Result Persistence Override (2.1.91+):** `_meta["anthropic/maxResultSizeChars"]` in MCP-Responses (bis 500K) — grosse Ergebnisse wie DB-Schemas werden nicht truncated
- **Plugin Binaries (2.1.91+):** Plugins koennen unter `bin/` Executables shippen — ausfuehrbar als bare Commands im Bash-Tool
- **`disableSkillShellExecution` (2.1.91+):** Deaktiviert Shell-Ausfuehrung in Skills, Slash-Commands, Plugin-Commands

## 5.4 Hook-Input (KRITISCH)

Hooks empfangen JSON auf **stdin** — KEINE Shell-Variablen wie `$TOOL_INPUT_*`.

### JSON-Schema (PostToolUse)

```json
{
  "session_id": "abc123",
  "transcript_path": "/pfad/zum/transcript.jsonl",
  "cwd": "/aktuelles/arbeitsverzeichnis",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/absoluter/pfad/zur/datei.txt",
    "content": "Dateiinhalt"
  },
  "tool_response": {
    "filePath": "/absoluter/pfad/zur/datei.txt",
    "success": true
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

### JSON parsen (Git Bash / Windows)

```bash
# Variante 1: Node.js (empfohlen wenn verfuegbar)
INPUT=$(cat)
FILE_PATH=$(node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).tool_input.file_path" <<< "$INPUT" 2>/dev/null)

# Variante 2: Python
FILE_PATH=$(cat | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input']['file_path'])")

# Variante 3: jq (wenn installiert)
FILE_PATH=$(cat | jq -r '.tool_input.file_path')
```
**ACHTUNG:** Es gibt KEINE `$TOOL_INPUT_*` Shell-Variablen. Stdin-JSON parsen ist der einzige Weg.

## 5.5 Exit-Codes

| Code | Bedeutung | Effekt |
|------|-----------|--------|
| 0 | Erfolg | Aktion wird erlaubt, stdout wird verarbeitet |
| 2 | Blockierend | PreToolUse: Tool wird blockiert. PostToolUse: Fehler an Claude |
| 1, 3+ | Nicht-blockierend | stderr in Verbose-Modus (Ctrl+O), Ausfuehrung laeuft weiter |

## 5.6 Umgebungsvariablen in Hooks

| Variable | Verfuegbarkeit |
|----------|---------------|
| `$CLAUDE_PROJECT_DIR` | Alle Hooks — Projekt-Root-Pfad |
| `$CLAUDE_ENV_FILE` | Nur SessionStart — Env-Vars fuer spaetere Bash-Aufrufe |
| `$CLAUDE_PLUGIN_ROOT` | Nur Plugin-Hooks |
| `$CLAUDE_CODE_MCP_SERVER_NAME` | headersHelper — Name des anfragenden MCP-Servers |
| `$CLAUDE_CODE_MCP_SERVER_URL` | headersHelper — URL des anfragenden MCP-Servers |

## 5.7 Definierbar in

- settings.json (global/projekt)
- Agent-Frontmatter (nur waehrend Agent aktiv)
- Skill-Frontmatter (nur waehrend Skill aktiv)

## 5.8 Async Hooks

```json
{ "type": "command", "command": "./deploy.sh", "async": true }
```
Blockiert nicht, Ergebnis kommt im naechsten Turn. Ideal fuer Logging, Tests, Deploys.

Timeout: 10 Minuten (erhoeht von urspruenglich 60 Sekunden).

---

# 6. MCP (Model Context Protocol)

Offener Standard zur Anbindung externer Services.

## 6.1 Konfiguration

In settings.json:
```json
{
  "mcpServers": {
    "my-db": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://..."]
    }
  }
}
```

## 6.2 Transport

| Typ | Einsatz |
|-----|---------|
| stdio | Lokaler Prozess (Standard) |
| SSE | Remote über HTTP |
| Streamable HTTP | Neuere Variante, ersetzt SSE langfristig |

## 6.3 OAuth für MCP

```bash
claude mcp add --client-id ID --client-secret SECRET slack-server
```
Pre-configured OAuth für Server ohne Dynamic Client Registration (z.B. Slack).

**RFC 9728 (2.1.85+):** MCP OAuth folgt jetzt Protected Resource Metadata Discovery zur Ermittlung des Authorization-Servers. Step-Up-Authorization bei `403 insufficient_scope` loest korrekt den Re-Authorization-Flow aus.

## 6.4 MCP Limits & Deduplication

- Tool-Beschreibungen und Server-Instruktionen sind auf **2KB** gekappt (verhindert Context-Bloat bei OpenAPI-generierten Servern)
- MCP-Server die sowohl lokal als auch via claude.ai Connectors konfiguriert sind, werden **dedupliziert** — lokale Config gewinnt

## 6.5 MCP + Skills Zusammenspiel

- MCP: Verbindung zum Service
- Skill: Lehrt Claude WIE den Service nutzen
- Beispiel: MCP verbindet DB, Skill kennt Schema + Query-Patterns

---

# 7. AGENT TEAMS (Experimentell)

Multi-Agent-Kollaboration mit Team Lead + Teammates.

## 7.1 Aktivierung

```bash
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## 7.2 Architektur

- Team Lead plant und delegiert
- Teammates arbeiten in eigenen Sessions
- Shared Task Board für Koordination
- Messaging zwischen Agents
- Hook-Events: TeammateIdle, TaskCompleted

## 7.3 Status

Research Preview – nicht produktionsreif. Bekannte Zuverlässigkeitsprobleme. Für Prototyping, nicht für kritische Projekte.

---

# 8. AUTOMATISCHE SESSION MEMORY

## 8.1 Funktionsweise

- Claude zeichnet automatisch Erinnerungen in `MEMORY.md` auf
- Erste 200 Zeilen von MEMORY.md werden in den System-Prompt geladen
- Separat von claude.md (automatisch vs. manuell)
- Pfad: `~/.claude/projects/{projekt-hash}/memory/MEMORY.md`

## 8.2 Memory-Scopes

| Scope | Pfad | Verfuegbarkeit |
|-------|------|---------------|
| user | `~/.claude/memory/` | Global, alle Projekte |
| project | `~/.claude/projects/{hash}/memory/` | Pro Projekt |
| local | Pro Maschine | Nicht geteilt |

## 8.3 Abgrenzung

| Feature | Typ | Kontrolle |
|---------|-----|-----------|
| claude.md | Manuell geschrieben | User pflegt |
| MEMORY.md | Automatisch (Auto Memory) | Claude pflegt, User kann editieren |
| Agent Memory | Persistent pro Agent | Agent pflegt (eigener Scope) |

---

# 9. BUILT-IN TOOLS

Claude Code bevorzugt dedizierte Tools ueber Bash-Aequivalente:

### Datei-Operationen

| Tool | Statt | Zweck |
|------|-------|-------|
| Read | cat/head/tail | Dateien lesen (inkl. PDF, Bilder, Jupyter Notebooks) |
| Edit | sed/awk | Exakte String-Ersetzungen in Dateien |
| Write | echo > | Dateien komplett schreiben/ueberschreiben |
| Glob | find/ls | Dateien per Pattern finden (z.B. `**/*.ts`) |
| Grep | grep/rg | In Dateiinhalten suchen (Regex, Kontext) |
| NotebookEdit | – | Jupyter Notebook Zellen bearbeiten/einfuegen/loeschen |

### Ausfuehrung & Recherche

| Tool | Zweck |
|------|-------|
| Bash | Shell-Befehle ausfuehren (mit Timeout, run_in_background) |
| Task | Sub-Agenten starten (Explore, Plan, Bash, general-purpose etc.) |
| WebFetch | URL abrufen + KI-Zusammenfassung |
| WebSearch | Web-Suche mit aktuellen Ergebnissen |
| ToolSearch | Deferred Tools (MCP etc.) laden/entdecken |
| Skill | User-invocable Skills ausfuehren (/commit, /audit etc.) |

### Task-Management (modernes System)

| Tool | Zweck |
|------|-------|
| TaskCreate | Neue Task anlegen (subject, description, activeForm) |
| TaskUpdate | Status aendern (pending → in_progress → completed) |
| TaskList | Alle Tasks anzeigen |
| TaskGet | Einzelne Task-Details abrufen |
| TaskStop | Laufende Hintergrund-Task stoppen |
| TaskOutput | Ergebnis einer Hintergrund-Task abrufen |

### Interaktion & Planung

| Tool | Zweck |
|------|-------|
| AskUserQuestion | User explizit fragen (mit Optionen) |
| EnterPlanMode | Plan-Modus aktivieren (Shift+Tab) |
| ExitPlanMode | Plan zur Genehmigung vorlegen |

### MCP & Sonstiges

| Tool | Zweck |
|------|-------|
| ListMcpResourcesTool | MCP-Ressourcen auflisten |
| ReadMcpResourceTool | MCP-Ressource lesen |
| LSP | Go-to-definition, find-references, hover-docs |

**Entfernt:** LS Tool (ersetzt durch Glob oder `ls` via Bash).

### Read-Tool Details

- `pages: "1-5"` fuer PDF-Seitenbereiche (max 20 Seiten pro Request)
- Bilder (PNG, JPG) werden visuell dargestellt (multimodal)
- Jupyter Notebooks: Alle Zellen mit Outputs
- Grosse PDFs (>10 Seiten): `pages` Parameter Pflicht

---

# 10. SESSION MANAGEMENT

## 10.1 Befehle

| Befehl | Zweck |
|--------|-------|
| /compact | Chat komprimieren (68% Memory-Reduktion) |
| /resume | Vorherige Session fortsetzen |
| /resume --from-pr PR | Session zu GitHub PR fortsetzen |
| /teleport | Session zu claude.ai/code uebertragen |
| /debug | Session-Troubleshooting |
| /stats | Nutzungsstatistiken |
| /context | Geladenen Kontext anzeigen |
| /rename | Session umbenennen (auto-generate ohne Argument) |
| /tasks | Laufende Hintergrund-Tasks anzeigen |
| /agents | Sub-Agenten verwalten (create, edit, delete, list) |
| /keybindings | Custom Keyboard Shortcuts konfigurieren |
| /copy | Letzte Antwort kopieren |
| /help | Hilfe anzeigen |

## 10.2 Keyboard Shortcuts

| Shortcut | Zweck |
|----------|-------|
| Alt+P / Option+P | Modell schnell wechseln |
| Shift+Tab | Plan-Modus ein/aus (auto-accept edits) |
| Shift+Enter | Newline einfuegen (iTerm2, WezTerm, Ghostty, Kitty) |
| Ctrl+G | Externen Editor oeffnen (auch in AskUserQuestion "Other"-Input) |
| Ctrl+O | Verbose-Modus (Hook-Output sichtbar) |
| Ctrl+B | Bash-Commands und Agents im Hintergrund starten |
| /fast | Fast-Modus Toggle (Opus 4.6 mit schnellerem Output) |

**Clickable File Paths:** Dateipfade sind anklickbar (OSC 8 Hyperlinks) im Terminal.

**Custom Keybindings:** Konfigurierbar ueber `~/.claude/keybindings.json` oder `/keybindings`. Unterstuetzt Chord-Sequences (z.B. Ctrl+K gefolgt von Ctrl+S).

**Vim-Motions (Erweiterungen):** `;`, `,`, `y`/`yy`/`Y`, `p`/`P`, Text Objects, `>>`, `<<`, `J`, Arrow-Key History-Navigation im Normal Mode.

**History-Autocomplete:** `!`-Prefix im Bash-Modus → Tab fuer Completion aus Command-History.

## 10.3 Session-Linking

- Sessions werden automatisch an PRs gelinkt via `gh pr create`
- PR-Review-Status als farbiger Punkt in der Statuszeile (approved, changes requested, pending, draft)
- Session-URL-Attribution bei Commits/PRs aus Web-Sessions
- **Session Forking und Rewind** — Session ab beliebigem Punkt forken

## 10.4 Compaction

- /compact komprimiert den bisherigen Chat
- 68% Memory-Reduktion fuer --resume via stat-based Loading
- **"Summarize from here"** im Message-Selector (partielle Zusammenfassung)
- Session Resume Hint beim Exit

---

# 11. PLUGINS

Paketierte Bundles aus Skills + Agents + Hooks + MCP + LSP + Output Styles.

## 11.1 Struktur

```
my-plugin/
├── plugin.json        # Manifest (name ist Pflicht)
├── skills/
│   └── code-review/
│       └── SKILL.md
├── agents/
│   └── reviewer.md
├── hooks.json
├── mcp-config.json
└── styles/
```

## 11.2 Namespacing

Plugin-Skills werden namespaced: `/my-plugin:code-review`

## 11.3 Pinning

Plugins können auf spezifische Git-Commit-SHAs gepinnt werden für Reproduzierbarkeit.

## 11.4 Agent Skills Open Standard

- Von Anthropic als offener Standard veröffentlicht (Dezember 2025)
- Cross-Platform-Kompatibilität (auch Codex CLI von OpenAI nutzt das Format)

---

# 12. SANDBOX & SICHERHEIT

## 12.1 Sandbox Mode

- Verfügbar auf Linux & Mac
- Schützt .claude/skills/ vor Schreibzugriff
- Konfigurierbar: sandbox.excludedCommands, dangerouslyDisableSandbox

## 12.2 Berechtigungen

- Tool-Level: allow/ask pro Tool
- **Wildcard Bash Permissions**: `Bash(npm *)`, `Bash(*-h*)`, `Bash(*)` (= alles erlauben)
- Content-Level: ask ueberschreibt allow
  - `allow: ["Bash"], ask: ["Bash(rm *)"]` → Prompt bei rm
- autoAllowBashIfSandboxed: Bash erlauben wenn Sandbox aktiv

## 12.3 Heredoc Security

- Verbesserte Delimiter-Parsing verhindert Command Smuggling

---

# 13. NÜTZLICHE ENVIRONMENT VARIABLES

| Variable | Zweck |
|----------|-------|
| CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 | Agent Teams aktivieren |
| CLAUDE_CODE_ENABLE_TASKS=false | Altes Todo-System nutzen |
| CLAUDE_CODE_SHELL | Shell-Override |
| CLAUDE_CODE_PROXY_RESOLVES_HOSTS=true | Proxy DNS-Aufloesung |
| CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 | Beta-Features deaktivieren |
| CLAUDE_CODE_EXIT_AFTER_STOP_DELAY | Delay fuer automatisierte Workflows |
| CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 | claude.md aus --add-dir laden |
| CLAUDE_CODE_DISABLE_BACKGROUND_TASKS | Hintergrund-Tasks deaktivieren |
| CLAUDE_CODE_TMPDIR | Custom Temp Directory |
| CLAUDE_STREAM_IDLE_TIMEOUT_MS | Streaming Idle Watchdog Threshold (Default: 90s) |
| ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL_SUPPORTS | Capability-Override fuer 3P-Modelle (Bedrock/Vertex/Foundry) |
| ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL_NAME | Label im `/model`-Picker fuer 3P-Modelle |

---

# 14. CHROME BROWSER INTEGRATION (Beta)

```bash
claude --chrome
```

Browser-Steuerung direkt aus dem Terminal:
- Navigieren, Klicken, Formulare ausfuellen
- Console-Logs lesen, Network Requests monitoren
- Nutzt Chrome/Edge Extension
- Zugriff auf alle Seiten wo der User eingeloggt ist
- Screenshots und DOM-Analyse

---

# 15. CLI FLAGS & INSTALLATION

## 15.1 Neue CLI Flags

| Flag | Zweck |
|------|-------|
| `--tools` | Built-in Tools in interaktiven Sessions einschraenken |
| `--init` / `--init-only` | Setup-Hook ausfuehren (Projekt-Initialisierung) |
| `--maintenance` | Maintenance-Setup-Hook ausfuehren |
| `--from-pr <PR>` | Session an GitHub PR verknuepfen |
| `--add-dir <Pfad>` | Zusaetzliches Verzeichnis fuer Skills + claude.md + enabledPlugins/extraKnownMarketplaces laden |
| `--chrome` | Browser-Integration starten |
| `--bare` | Scripted `-p` Calls ohne Hooks/LSP/Plugins/Skill-Walks (erfordert ANTHROPIC_API_KEY) |
| `--channels` | Permission Relay — Tool-Approvals ans Handy weiterleiten |

## 15.2 Installation

**npm-Installation ist deprecated.** Bevorzugt native Installation:

```bash
# Native Installation (empfohlen)
claude install

# Oder ueber Paketmanager
# Siehe: https://code.claude.com/docs/en/installation
```

**Windows ARM64** wird nativ unterstuetzt (win32-arm64 Binary).

## 15.3 Weitere Settings

| Setting | Zweck |
|---------|-------|
| `plansDirectory` | Speicherort fuer Plan-Dateien |
| `spinnerVerbs` | Anpassbare Spinner-Texte |
| `spinnerTipsOverride` | Eigene Spinner-Tipps (optional Standard-Tipps deaktivieren) |
| `showTurnDuration` | Turn-Duration ausblenden |
| `reducedMotion` | Reduzierte Animationen |

---

# 16. CLI AUTH

```bash
claude auth login      # Anmelden
claude auth status     # Status prüfen
claude auth logout     # Abmelden
```

---

# 17. OUTPUT STYLES

Ändern WIE Claude antwortet (Formatierung, Ton, Struktur).

| Style | Beschreibung |
|-------|-------------|
| Default | Software Engineering (Standard) |
| Explanatory | Lehrreich, erklärt Entscheidungen |
| Learning | Kollaborativ, fordert User zum Mitcoden auf |
| Custom | Eigene Styles in .claude/styles/ oder Plugins |

Output Styles überschreiben Teile des System-Prompts direkt – anders als claude.md oder Skills.

---

# 18. TOKEN-METRIKEN

- Token-Count, Tool-Uses und Duration in Task-Ergebnissen
- Context Window Info in der Statuszeile
- Token-Anzeige: >= 1M als "1.5m" statt "1512.6k"
- Phantom "(no content)" Bloecke behoben (reduziert Token-Waste)

---

# 19. SCHNELLREFERENZ: WAS WOHIN

| Ich will... | Nutze... |
|------------|----------|
| Immer-geltende Regeln | claude.md |
| On-demand Wissen/Workflow | Skill (.claude/skills/) |
| Isolierte Aufgabe delegieren | Sub-Agent (.claude/agents/) |
| Externe Services anbinden | MCP (settings.json) |
| Automatisierung bei Tool-Calls | Hooks (settings.json / Frontmatter) |
| Alles paketieren & teilen | Plugin |
| Antwort-Stil aendern | Output Style |
| Multi-Agent Kollaboration | Agent Teams (experimentell) |
| Browser steuern | Chrome Integration (--chrome) |
| Tastenkuerzel anpassen | /keybindings oder keybindings.json |

---

# 20. ANTHROPIC SDK — MANAGED AGENTS API

Ab SDK v0.86.0 bietet Anthropic die **Managed Agents API** (Beta):

| Endpoint | Zweck |
|----------|-------|
| `client.beta.agents.create()` | Persistente Agenten erstellen (model, system prompt, tools) |
| `client.beta.sessions.create()` | Sessions an Agent+Environment pinnen |
| `client.beta.skills.create()` | Custom SKILL.md-Dateien hochladen |
| `client.beta.vaults.credentials.create()` | Credential Management |

**Hangar-Kompatibilitaet:** Unser SKILL.md-Format ist direkt kompatibel mit der Upload-API (`client.beta.skills.create()`). Skills koennen ohne Konvertierung hochgeladen werden.

### Breaking Changes in v0.86.0

- Named Path Parameters (statt positional)
- URI Encoding Changes fuer Pfad-Parameter
- Bestehende API-Clients muessen aktualisiert werden
