# Stack-Supplement: Claude Code

Claude-Code-spezifische Projekt-Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.
Erkennung: `.claude/` Verzeichnis oder `CLAUDE.md` im Projekt-Root.

**Wissensbasis:** `claude-hangar/docs/claude-code-referenz.md` — bei jeder Pruefung als
Referenz fuer aktuelle Features, Patterns und Best Practices heranziehen.
Die Referenz ist die Source of Truth fuer den aktuellen Stand von Claude Code.

---

## §Struktur

- [ ] `.claude/` Verzeichnis: Vorhanden? Korrekte Unterstruktur?
  - `skills/` — Projekt-Skills (SKILL.md + optionale Supporting Files)
  - `agents/` — Projekt-Agents (.md Dateien)
  - `settings.json` — Projekt-spezifische Berechtigungen, Hooks, MCP
- [ ] Skill-Ordner: Jeder Skill hat eigenen Ordner mit `SKILL.md`?
- [ ] Agent-Dateien: Direkt in `.claude/agents/`, keine Unterordner?
- [ ] Trennung: Globale Skills/Agents (`~/.claude/`) vs. Projekt-Skills korrekt?
  - Projektspezifisch → `.claude/skills/` (committet)
  - Universell → `~/.claude/skills/` (via claude-hangar deployed)
- [ ] Keine verwaisten Dateien in `.claude/` (alte Configs, Backup-Dateien)?
- [ ] `.claude.json` im Projekt-Root: Vorhanden wenn noetig?

## §Dependencies

- [ ] Claude Code Version: Installierte Version pruefen (`claude --version`)
- [ ] MCP-Server: Referenzierte MCP-Server verfuegbar? Konfiguration korrekt?
- [ ] Plugins: `enabledPlugins` in settings.json — alle Plugins installiert?
- [ ] Externe Tools in Hooks: Alle referenzierten Commands verfuegbar? (node, jq, python etc.)
- [ ] Skill-Dependencies: Supporting Files in Skills referenziert und vorhanden?

## §Code

- [ ] SKILL.md Format: YAML-Frontmatter gueltig? Pflicht-Felder vorhanden?
  - Pflicht: `name`, `description`
  - Optional: `allowed-tools`, `disable-model-invocation`, `context`, `agent`, `hooks`
- [ ] Agent .md Format: Frontmatter-Felder gueltig?
  - `name`, `description`, `model`, `tools`, `disallowedTools`, `memory`, `maxTurns`, `skills`, `hooks`
- [ ] Skill-Descriptions: Beschreiben WANN der Skill getriggert werden soll?
- [ ] Agent-Descriptions: Beschreiben WANN der Agent vorgeschlagen wird?
- [ ] Hook-Scripts: JSON auf stdin parsen (nicht `$TOOL_INPUT_*` Variablen — die gibt es NICHT)?
- [ ] Hook Exit-Codes: 0=Erfolg, 2=Blockierend, andere=nicht-blockierend?
- [ ] Keine deprecated Patterns:
  - `$ARGUMENTS.0` → `$ARGUMENTS[0]` (Bracket-Syntax)
  - Alte Tool-Namen oder entfernte Features?

## §Git

- [ ] `.gitignore`: `.claude/settings.local.json` nicht committet?
- [ ] `.claude/settings.json`: Committet (Team-Settings) oder gitignored (persoenlich)?
- [ ] State-Dateien: `.project-audit-state.json`, `.audit-state.json` etc. — committet oder gitignored?
- [ ] Keine Secrets in Hook-Scripts oder Skills?

## §CICD

- [ ] Hooks: PostToolUse fuer Write|Edit mit Validierung? (Linting, Formatting)
- [ ] Setup-Hook: `--init` / `--init-only` Hook definiert fuer Projekt-Setup?
- [ ] Async Hooks: Langsamere Checks als `async: true`? (Tests, Deploys)
- [ ] Hook-Timeouts: Beachtet? (10 Minuten Maximum)
- [ ] `$CLAUDE_PROJECT_DIR`: In Hook-Commands fuer zuverlaessige Pfade genutzt?
- [ ] SessionStart-Hook: `$CLAUDE_ENV_FILE` fuer Env-Vars genutzt wenn noetig?

## §Dokumentation

- [ ] CLAUDE.md: Vorhanden? Unter ~500 Zeilen?
- [ ] CLAUDE.md Inhalt: Coding-Standards, Build-Commands, Projektstruktur, Verbote?
- [ ] CLAUDE.md: Keine Workflow-Details (→ gehoeren in Skills)?
- [ ] CLAUDE.md: Keine API-Docs oder Referenzmaterial (→ gehoeren in Skills)?
- [ ] Skills: `description` in Frontmatter erklaert Trigger-Bedingungen?
- [ ] project-audit-context.md: Vorhanden fuer projektspezifischen Audit-Kontext?
- [ ] Output Styles: Eigene Styles dokumentiert wenn vorhanden?

## §Testing

- [ ] Hook-Scripts: Manuell getestet? (JSON-Testdaten via stdin)
- [ ] Skills: Manuell durchgespielt? Erwartetes Verhalten dokumentiert?
- [ ] Agent-Konfiguration: `maxTurns` sinnvoll? Nicht zu hoch (Token-Verschwendung)?
- [ ] MCP-Server: Verbindung getestet? Fehlerbehandlung bei Ausfall?

## §Security

- [ ] Berechtigungen: `allow` / `ask` in settings.json sinnvoll gesetzt?
  - Nicht zu permissiv (`Bash(*)` nur wenn Sandbox aktiv)
  - Kritische Commands in `ask`: `rm`, `git push`, `docker`, SSH
- [ ] Wildcard-Permissions: `Bash(npm *)` statt `Bash(*)` wo moeglich?
- [ ] Sandbox: Aktiviert auf Linux/Mac? `autoAllowBashIfSandboxed` bewusst gesetzt?
- [ ] Hook-Scripts: Kein `eval` oder `source` von untrusted Input?
- [ ] Hook-Scripts: Keine Secrets hardcoded? Env-Vars oder Credential-Files nutzen?
- [ ] MCP-Server: OAuth-Credentials sicher? Keine Client-Secrets in committetem Code?
- [ ] Skills: Keine Instruktionen die Security-Checks umgehen (`--no-verify` etc.)?

## §Deployment

- [ ] setup.sh: Deployed Skills/Agents/Hooks korrekt? Keine veralteten Kopien?
- [ ] setup.sh: Idempotent? Kann mehrfach laufen ohne Schaden?
- [ ] Plugin-Config: `enabledPlugins` korrekt? Plugins gepinnt fuer Reproduzierbarkeit?
- [ ] MCP-Server Config: Transport-Typ korrekt? (stdio vs. SSE vs. Streamable HTTP)
- [ ] `--add-dir` Pfade: Korrekt konfiguriert wenn genutzt?

## §Maintenance

**Versions-Check (KRITISCH):**
- [ ] Claude Code Version: `claude --version` ausfuehren
- [ ] Referenz-Version: `docs/claude-code-referenz.md` Header lesen (Stand: vX.Y.Z)
- [ ] Version-Match: Installierte Version == Referenz-Version?
  - Falls nein → Finding: "Referenz veraltet — CHANGELOG pruefen und updaten"
- [ ] CHANGELOG pruefen: Neue Features seit letzter Referenz-Version?
  - Quelle: `https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md`

**Feature-Adoption:**
- [ ] Referenz lesen und gegen Projekt abgleichen:
  - Neue Features die das Projekt verbessern wuerden?
  - Patterns die sich geaendert haben?
  - Deprecated Features die noch genutzt werden?
- [ ] Model-Config: Nutzt das Projekt aktuelle Modell-Bezeichnungen?
- [ ] Settings: Neue Settings aus der Referenz relevant fuer das Projekt?

**Hygiene:**
- [ ] Verwaiste Skills: Skills die nie getriggert werden? (description zu vage)
- [ ] Verwaiste Agents: Agents ohne Einsatzzweck?
- [ ] Verwaiste Hooks: Hooks fuer Tools die nicht mehr genutzt werden?
- [ ] State-Dateien: Alte Audit-States aufgeraeumt?
- [ ] Memory: MEMORY.md aktuell? Veraltete Eintraege entfernt?
