# Claude Hangar

> [English version](../../README.md)

**Produktionsreife Konfigurationsverwaltung fuer Claude Code.**
Hooks, Agents, Skills, Multi-Projekt-Orchestrierung — Open Source.

---

## Warum Claude Hangar?

Die meisten Claude-Code-Konfigurationen sind persoenliche Dotfiles — nuetzlich zum Lesen, schwer wiederzuverwenden. Claude Hangar ist anders:

- **Ein Befehl** deployt ein vollstaendiges, getestetes Setup nach `~/.claude/`
- **Multi-Projekt-Orchestrierung** — verwalte Konfigurationen fuer mehrere Repos von einem Ort
- **Modulare Stacks** — nimm nur was du brauchst (`bash integrate.sh <stack>`)
- **Kampferprobte Hooks** die echte Vorfaelle verhindern (Secret Leaks, destruktive Befehle, Context-Ueberlauf)
- **31 Skills** von Projekt-Scanning bis Pre-PR-Verifizierung
- **27 Lifecycle-Hooks** mit 4-Stufen Quality Gates und Config-Schutz
- **21 Agents** fuer spezialisierte Aufgaben, Code Review und TDD
- **19 Governance-Rules** (common + sprachspezifisch)
- **Plattformuebergreifend** — Linux, macOS und Windows (Git Bash)

## Schnellstart

**Ein-Zeiler Installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/claude-hangar/claude-hangar/main/install.sh | bash
```

**Oder manuell klonen:**

```bash
git clone https://github.com/claude-hangar/claude-hangar.git ~/.claude-hangar
cd ~/.claude-hangar && bash setup.sh
```

## Voraussetzungen

| Tool | Erforderlich | Installation |
|------|-------------|--------------|
| **Git** | Ja | In Git Bash enthalten / `apt install git` / `brew install git` |
| **Node.js 18+** | Ja | [nodejs.org](https://nodejs.org/) (LTS-Version) |
| **Bash 4.0+** | Ja | Linux: eingebaut. macOS: `brew install bash`. Windows: Git Bash. |
| **jq** | Optional | Nur fuer die Statusleiste |

## Was wird installiert?

Setup kopiert Dateien aus dem Repo nach `~/.claude/`:

- **27 Hook-Scripts** — Sicherheit, Qualitaets-Gates, Context-Management
- **21 Agent-Definitionen** — Spezialisierte AI-Helfer
- **31 Skill-Workflows** — Slash-Commands fuer echte Arbeit
- **Governance-Rules** — Always-on Code-Qualitaet
- **Statusleiste** — Modell, Context-Balken, Kosten, Sitzungsdauer

## Stacks

Framework-spezifische Erweiterungen:

| Stack | Beschreibung |
|-------|-------------|
| **Astro** | SSG/SSR, Content Collections, View Transitions |
| **SvelteKit** | Svelte 5 Runes, Load Functions, Form Actions |
| **Next.js** | App Router, Server Components, Server Actions |
| **Database** | Drizzle ORM + PostgreSQL Schema und Migrationen |
| **Auth** | Custom bcrypt + Sessions, sichere Cookies, CSRF |

```bash
# Stack hinzufuegen
bash integrate.sh astro

# Stack entfernen
bash integrate.sh --remove astro

# Verfuegbare Stacks anzeigen
bash integrate.sh --list
```

## Multi-Projekt

Verwalte Claude-Code-Konfigurationen fuer mehrere Repositories ueber eine `registry.json`:

```bash
bash registry/deploy.sh              # Alle Projekte deployen
bash registry/deploy.sh --project x  # Einzelnes Projekt
bash registry/deploy.sh --check      # Trockenlauf
```

Jedes Projekt bekommt die richtigen Skills, Hooks und CI-Templates — alles aus einer Quelle.

## Weitere Befehle

```bash
bash setup.sh --check      # Trockenlauf — validieren ohne zu deployen
bash setup.sh --verify     # Bestehende Installation pruefen
bash setup.sh --rollback   # Backup wiederherstellen
bash setup.sh --update     # git pull + sync
bash setup.sh --uninstall  # Hangar-Dateien entfernen (Nutzerdaten bleiben)
```

## Dokumentation

- [Erste Schritte](../../docs/getting-started.md) (EN)
- [Architektur](../../docs/architecture.md) (EN)
- [Hooks schreiben](../../docs/writing-hooks.md) (EN)
- [Skills schreiben](../../docs/writing-skills.md) (EN)
- [Agents schreiben](../../docs/writing-agents.md) (EN)
- [Multi-Projekt-Guide](../../docs/multi-project.md) (EN)
- [FAQ](../../docs/faq.md) (EN)
- [Fehlerbehebung](../../docs/troubleshooting.md) (EN)

## Mitwirken

Beitraege sind willkommen. Siehe [CONTRIBUTING.md](../../CONTRIBUTING.md) fuer Richtlinien.

## Lizenz

MIT — siehe [LICENSE](../../LICENSE).
