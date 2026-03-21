# Claude Hangar — Uebersicht

> Open-source configuration management for Claude Code. Ein Repo, ein Dach: Skills, Hooks, Agents, Templates und ein Setup-Wizard.

## Wann brauche ich das?

- Du willst verstehen wie Claude Hangar aufgebaut ist
- Du willst alles einrichten (neuer PC oder erstes Setup)
- Du fragst dich wo eine bestimmte Config liegt

## Architektur

Claude Hangar hat 4 Bereiche:

### 1. Core — `core/`

Alles was fuer **alle Projekte** gilt — wird per `setup.sh` nach `~/.claude/` deployed:
- Skills (Audit, Project-Audit, Astro-Audit, Capture-PDF, etc.)
- Hooks (Secret-Leak-Check, Bash-Guard, Checkpoint, etc.)
- Agents (Explorer, Security-Reviewer, etc.)
- Statusline, Shared Lib

### 2. Stacks — `stacks/`

Framework-spezifische Erweiterungen:
- `stacks/astro/` — Astro-Audit mit versionierten Checklisten
- `stacks/sveltekit/` — SvelteKit + Svelte 5 Audit
- `stacks/database/` — Drizzle ORM + PostgreSQL Audit
- `stacks/auth/` — Custom Auth (bcryptjs + Sessions) Audit

### 3. Templates — `templates/`

CI/CD Workflows und Projekt-CLAUDE.md Templates:
- `templates/ci/` — GitHub Actions (Node, Python, VPS, GH Pages, CF Pages)
- `templates/project/` — CLAUDE.md Vorlagen (minimal, web, fullstack, management)

### 4. Docs — `docs/`

Dokumentation, Patterns, Tutorials:
- `docs/patterns.md` — Best Practices und Anti-Patterns
- `docs/claude-code-referenz.md` — Claude Code CLI Referenz
- `docs/tutorials/` — Anleitungen fuer Skills, Setup, Erweiterung

## So geht's: Einrichten

### Schritt 1: Repository klonen
```bash
git clone https://github.com/claude-hangar/claude-hangar.git
cd claude-hangar
```

### Schritt 2: Setup ausfuehren
```bash
bash setup.sh
```

Was passiert:
1. **Phase 1 — Global:** Kopiert Skills, Hooks, Agents, CLAUDE.md nach `~/.claude/`
2. **Phase 2 — Projekte (optional):** Wenn du Projekte in der Registry hast, deployed Projekt-Configs

Beim zweiten Lauf merkt sich `setup.sh` alle Pfade (in `.local-config.json`) — laeuft dann automatisch durch.

### Schritt 3: Fertig

Ab jetzt funktionieren alle Skills in allen Projekten. Aenderungen immer hier in claude-hangar machen, dann `bash setup.sh` um sie zu deployen.

## Beispiel-Session

```
Du: "Ich will einen neuen Skill anlegen"
→ Siehe Tutorial: Neue Projekte hinzufuegen

Du: "Was kann der Audit-Skill?"
→ /audit — 8-Phasen Website-Audit mit Dreischicht-Modell
```

## Haeufige Fragen

- **Was wenn ich eine Config direkt in ~/.claude/ aendere?** → Wird beim naechsten `setup.sh` ueberschrieben. Immer hier in claude-hangar aendern.
- **Muss ich setup.sh nach jeder Aenderung laufen lassen?** → Ja, wenn du willst dass die Aenderung in `~/.claude/` ankommt.
- **Was ist .local-config.json?** → Speichert deine lokalen Pfade (gitignored). Jeder PC kann andere Pfade haben.

## Naechste Schritte

- [Setup & Scripts](setup-und-scripts.md) — Praktische Setup-Anleitung
- [Neue Projekte](neue-projekte.md) — Neues Projekt/Skill/Agent hinzufuegen
- [Audit](skills/audit.md) — Website-Audit Skill
