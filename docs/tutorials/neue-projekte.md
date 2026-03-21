# Neue Projekte, Skills, Agents und Hooks hinzufuegen

> Wie du claude-hangar um neue Projekte, Skills, Agents oder Hooks erweiterst — Schritt fuer Schritt.

## Wann brauche ich das?

- Du willst ein neues Kundenprojekt in die Pipeline aufnehmen
- Du willst einen neuen Skill (Befehl) erstellen
- Du willst einen neuen Agent erstellen
- Du willst einen neuen Hook erstellen

## Neues Projekt hinzufuegen

### Schritt 1: Ordner erstellen

```
projekte/mein-projekt/
├── CLAUDE.md          # Pflicht: Projekt-Anweisungen
├── skills/            # Optional: Projekt-Skills
│   └── mein-skill/
│       └── SKILL.md
└── hooks/             # Optional: Projekt-Hooks
    └── mein-hook.sh
```

### Schritt 2: CLAUDE.md schreiben

Mindestens enthalten:
- Was ist das Projekt?
- Welcher Tech-Stack?
- Wichtige Dateien und wo sie liegen
- Befehle/Skills (falls vorhanden)
- Deployment-Info

### Schritt 3: In Registry eintragen

In `projekte/registry.json` neuen Eintrag ergaenzen:

```json
{
  "name": "mein-projekt",
  "repo": "https://github.com/user/mein-projekt.git",
  "defaultPath": {
    "windows": "C:\\Users\\me\\projects\\mein-projekt",
    "linux": "/home/user/mein-projekt"
  },
  "server": "server-name"
}
```

### Schritt 4: Setup ausfuehren

```bash
bash setup.sh
```

Deployed die CLAUDE.md, Skills und Hooks an den Zielpfad.

## Neuen Skill erstellen

### Globaler Skill (fuer alle Projekte)

Ordner: `core/skills/mein-skill/`

```
core/skills/mein-skill/
├── SKILL.md           # Pflicht: Skill-Logik
└── supporting-files/  # Optional: Checklisten, Referenzen
```

### Projekt-Skill (fuer ein Projekt)

Ordner: `projekte/mein-projekt/skills/mein-skill/`

Gleiche Struktur wie oben, wird aber nur in dem einen Projekt deployed.

### SKILL.md Aufbau

```markdown
---
name: mein-skill
description: >
  Kurze Beschreibung was der Skill macht.
  Keywords die den Auto-Trigger ausloesen.
---

# /mein-skill — Titel

## Modi
- start → Was passiert
- weiter → Fortsetzen
- status → Fortschritt anzeigen

## Ablauf
1. Schritt 1
2. Schritt 2

## Regeln
- Max X pro Session
- State in .state-datei.json speichern
```

**Wichtig:** Das `description`-Feld entscheidet wann der Skill automatisch geladen wird. Genug Keywords, aber praezise.

### Tutorial mitschreiben

Bei jedem neuen Skill ein Tutorial in `docs/tutorials/` erstellen:
- Template: Wann brauche ich das? → So geht's → Beispiel-Session → FAQ → Naechste Schritte
- `docs/tutorials/index.md` aktualisieren

## Neuen Agent erstellen

Ordner: `core/agents/`

```markdown
---
name: mein-agent
description: >
  Beschreibung + Keywords fuer Auto-Trigger
model: haiku          # haiku/sonnet/opus
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
maxTurns: 15
---

Was der Agent tun soll. Regeln. Ausgabe-Format.
```

**Modell-Wahl:**
- **Haiku** — fuer Read-only, Exploration, schnelle Antworten
- **Sonnet** — fuer Standard-Aufgaben
- **Opus** — fuer komplexe Architektur-Entscheidungen

## Neuen Hook erstellen

Ordner: `projekte/mein-projekt/hooks/`

```bash
#!/bin/bash
# Hook-Name: Was er prueft

INPUT=$(cat)

# JSON parsen (kein jq auf Windows)
FILE_PATH=$(echo "$INPUT" | node -e "
  let d='';
  process.stdin.on('data',c=>d+=c);
  process.stdin.on('end',()=>{
    try{console.log(JSON.parse(d).tool_input.file_path)}
    catch(e){console.log('')}
  });
")

# Pruefung
# ...

# Exit-Codes:
# 0 = OK (Warnungen via stdout)
# 2 = Blockierend (Tool wird verhindert)
exit 0
```

**Wichtig:** JSON-Parsing mit Node.js, nicht mit `jq` (gibt es nicht auf Git Bash).

## Checkliste

Fuer jede neue Komponente:

- [ ] Code/Config geschrieben
- [ ] Tutorial in `docs/tutorials/` erstellt
- [ ] `docs/tutorials/index.md` aktualisiert
- [ ] `docs/changelog.md` Eintrag
- [ ] `STATUS.md` aktualisiert
- [ ] `setup.sh` getestet (deployed korrekt?)

## Haeufige Fragen

- **Muss jeder Skill ein Tutorial haben?** → Ja, das ist eine Regel in der globalen CLAUDE.md. Tutorials wachsen automatisch mit.
- **Kann ich einen Skill nur fuer ein Projekt machen?** → Ja, unter `projekte/{name}/skills/`. Wird nur dort deployed.
- **Was wenn mein Hook etwas blockieren soll?** → Exit-Code 2 statt 0 verwenden. Dann wird der Schreibvorgang verhindert.
- **Muss ich setup.sh danach ausfuehren?** → Ja, sonst landet die neue Komponente nicht am Zielpfad.

## Naechste Schritte

- [Pipeline-Uebersicht](pipeline-uebersicht.md) — Gesamtsystem verstehen
- [Audit](skills/audit.md) — Beispiel fuer einen Skill
