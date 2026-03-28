# Setup & Scripts — Praktische Anleitung

> Wie du setup.sh unter Windows (Git Bash) oder Linux/macOS ausfuehrst.

## Wann brauche ich das?

- Du hast claude-hangar geklont und willst alles einrichten
- Du willst pruefen ob deine Configs noch synchron sind
- Du hast Skills/Hooks geaendert und willst sie deployen

## Voraussetzungen

- **Git Bash** (Windows) oder **bash** (Linux/macOS)
- **Node.js** — fuer JSON-Parsing (beliebige aktuelle Version)

## So geht's

### Shell-Scripts unter Windows ausfuehren

Unter Windows nutzt du **Git Bash** (nicht CMD, nicht PowerShell):

1. Rechtsklick auf den Ordner → "Git Bash Here"
2. Oder: Git Bash oeffnen → `cd /path/to/claude-hangar`

Scripts starten immer mit `bash`:
```bash
bash setup.sh              # Setup ausfuehren
bash setup.sh --check      # Nur pruefen, nichts aendern
```

**Wichtig:** Nicht doppelklicken! `.sh` Dateien muessen in der Shell ausgefuehrt werden.

### setup.sh — Zentrales Setup

```bash
# Alles einrichten (interaktiv)
bash setup.sh

# Nur pruefen was sich geaendert hat (nichts aendern)
bash setup.sh --check
bash setup.sh -c
```

#### Was passiert in den Phasen?

| Phase | Was | Interaktiv? |
|-------|-----|------------|
| 1 — Global | Skills, Hooks, Agents, CLAUDE.md → ~/.claude/ | Nein |
| 2 — Projekte | Projekt-Configs an Zielpfade deployen (optional) | Ja (Pfad-Abfrage) |

#### --check Modus

Zeigt was sich geaendert hat, ohne etwas zu aendern:
```
=== Claude Hangar Setup — CHECK-Modus ===
Nur pruefen, nichts aendern.

[=] CLAUDE.md — identisch
[!] Skill: audit — AENDERUNG
[=] Skill: astro-audit — identisch
[=] Agent: explorer — identisch

1 Aenderung(en) ausstehend — 'bash setup.sh' zum Anwenden.
```

## Beispiel-Session

### Erstmaliges Setup

```
$ cd /path/to/claude-hangar
$ bash setup.sh

=== Claude Hangar Setup ===
Plattform: windows (MINGW64_NT-10.0-22635)

--- Phase 1: Globale Config → ~/.claude/ ---
[+] CLAUDE.md — synchronisiert
[+] Skill: audit — synchronisiert
[+] Skill: astro-audit — synchronisiert
[+] Skill: project-audit — synchronisiert
[+] Agent: explorer — synchronisiert
[+] Hook: secret-leak-check — synchronisiert
...

--- Zusammenfassung ---
Global: 18 Skill(s), 6 Agent(s), 13 Hook(s)

Fertig!
```

### Pruefen ob alles synchron ist

```
$ bash setup.sh --check

=== Claude Hangar Setup — CHECK-Modus ===
Nur pruefen, nichts aendern.

[=] CLAUDE.md — identisch
[=] Skill: audit — identisch
...
Alles synchron — keine Aenderungen noetig.
```

## Haeufige Fragen

### "bash: command not found" — was tun?
Du bist nicht in Git Bash. Oeffne Git Bash (Start → "Git Bash") statt CMD oder PowerShell.

### Wo ist Git Bash?
Wird mit Git fuer Windows installiert: https://git-scm.com/download/win

### Pfade: Forward-Slash oder Backslash?
In Git Bash immer Forward-Slash: `/c/Users/me/claude-hangar` (nicht `C:\Users\me\...`).

### Was macht `--check` genau?
Vergleicht alle Quell-Dateien mit den Ziel-Dateien. Zeigt Unterschiede an (NEU, AENDERUNG, identisch). Aendert nichts — kein Backup, kein Kopieren.

### Kann ich einzelne Projekte ueberspringen?
Ja: Bei der Auswahl `1,3` eingeben (nur Projekt 1 und 3) oder `keine`.

## Naechste Schritte

- [Pipeline-Uebersicht](pipeline-uebersicht.md) — Was ist Claude Hangar?
- [Neue Projekte](neue-projekte.md) — Neues Projekt hinzufuegen
