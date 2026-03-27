# Claude Code CLI – Vollstaendige Referenz

## Stand: v2.1.85 (27. Maerz 2026)

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
