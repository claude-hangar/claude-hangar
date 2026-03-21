# Claude Hangar — Best Practices & Patterns

## Projekt-Config Management

### Master-Kopie Prinzip
- Alle Projekt-Configs (CLAUDE.md, Skills, Hooks) haben ihre **Master-Kopie** in `projekte/{name}/`
- `setup.sh` deployed die Master-Kopien an die Zielpfade
- Aenderungen immer erst in der Master-Kopie, dann `setup.sh`
- Nie direkt im Zielprojekt die Config aendern — wird beim naechsten Setup ueberschrieben

### Registry Pattern
- `projekte/registry.json` ist die Single Source of Truth fuer Projekt-Pfade
- `.local-config.json` (gitignored) fuer maschinenspezifische Overrides
- Default-Pfade in der Registry fuer Windows + Linux

## Skills & Agents

### Skill-Design
- **Progressive Disclosure:** Frontmatter wird immer geladen, SKILL.md nur bei Bedarf
- **Supporting Files:** Grosse Inhalte in Unterordner auslagern (z.B. `phases/`)
- **Auto-Detection:** Generische Skills erkennen den Stack selbst
- **description-Feld:** Entscheidend fuer Auto-Trigger — genug Keywords, aber praezise

### Agent-Design
- **Modell-Wahl:** Haiku fuer Read-only/Exploration, Sonnet fuer Standard, Opus fuer Architektur
- **Tool-Einschraenkung:** Nur die noetigsten Tools erlauben
- **maxTurns:** Immer setzen um Endlos-Loops zu vermeiden

## Hooks

### JSON-Parsing auf Windows
- Kein `jq` auf Git Bash → Node.js verwenden
- `node -e` ist die zuverlaessigste Methode
- stdin-Parsing: `INPUT=$(cat)` dann Node.js mit heredoc

### Exit-Codes
- `0` — OK (Warnungen via stdout)
- `2` — Blockierend (Tool wird verhindert)
- Andere — Nicht-blockierend (nur in Verbose-Modus sichtbar)

## Audit: Dreischicht-Architektur (v4.0)

### Drei Schichten pro Phase
```
Schicht 1: Basis-Phase (phases/*.md)         ~50 Zeilen, universell
Schicht 2: Stack-Supplement (stacks/*/*.md)   ~80 Zeilen, framework-spezifisch
Schicht 3: Projekt-Override (audit-context.md) ~20-40 Zeilen, projektspezifisch
```

### Supplement-Lade-Logik
- Stack-Dateien sind nach §-Sektionen gegliedert (§IST-Analyse, §Security, §Performance etc.)
- Pro Phase wird nur die passende §-Sektion aus jedem relevanten Supplement geladen
- Wenn ein Stack erkannt wird aber kein Supplement existiert → nur Basis-Phase verwenden

### Finding-IDs nach Phase
- IST, SEC, PERF, SEO, A11Y, CODE, DSGVO, INFRA + laufende Nummer
- Severity: CRITICAL → HIGH → MEDIUM → LOW

### Erweiterbarkeit
- Neuer Stack: Supplement-Datei in `stacks/{kategorie}/{name}.md` anlegen
- Neues Projekt: `audit-context.md` im Projekt-Root mit verwandten Projekten, Servern, Fokus
- Neue Phase: Datei in `phases/` + §-Sektionen in relevanten Supplements

## Session-Management

### Context-Schutz
- 1 Session = 1 grosse Aufgabe (Bau, Audit, Push)
- Recherche darf mehrere Funde liefern (nur Text)
- Bei Audit: Max 2 Phasen ODER 5 Fixes pro Session
- State in `.audit-state.json` persistieren

### Multi-Session Workflows
- State-Dateien fuer Session-uebergreifende Arbeit
- `/audit weiter` statt alles in einer Session
- `STATUS.md` am Session-Ende aktualisieren

## Task-System (.tasks.json)

### Wann Tasks anlegen?
- Aufgabe braucht mehrere Sessions
- Aufgabe hat klare Teilschritte
- Aufgabe ist blockiert und soll nicht vergessen werden

### Lifecycle
1. Task anlegen (`status: open`)
2. Lock setzen (`status: in-progress`, 60 min Expire)
3. Am Session-Ende: Lock freigeben + Handoff schreiben
4. Naechste Session: Handoff lesen, Lock setzen, weiterarbeiten
5. Fertig: `status: done`
6. Cleanup: done/skipped > 30 Tage → `archive` Array

### Zusammenspiel mit State-Dateien
- `.audit-state.json`, `.astro-audit-state.json` etc. bleiben unberuehrt
- Tasks referenzieren State-Dateien nur im `description`-Feld
- Kein Duplikat: State-Datei = Detail, Task = Tracking

### Zusammenspiel mit STATUS.md
- STATUS.md = User-facing Uebersicht
- .tasks.json = maschinenlesbare Task-Verwaltung
- Beide konsistent halten

Schema + Beispiele: `docs/task-system.md`

## Tutorials

### Tutorial-Template
Jedes Tutorial folgt diesem Aufbau:
```markdown
# {Titel}

> Einzeiler: Was das ist und wofuer

## Wann brauche ich das?
- Konkretes Szenario 1
- Konkretes Szenario 2

## So geht's
### Schritt 1: ...
(Befehl + Was passiert)

## Beispiel-Session (komplett)
Session 1: ...

## Haeufige Fragen
- Was wenn X? → Y

## Naechste Schritte
- Links zu verwandten Tutorials
```

### Regeln
- Zielgruppe: User (kein Programmierer) — verstaendlich und praxisnah
- Jeder neue Skill/Agent/Hook bekommt ein Tutorial in `docs/tutorials/`
- `docs/tutorials/index.md` muss immer aktuell sein (Uebersichtstabelle)
- Bestehende Tutorials nicht ohne Grund umschreiben

## Git

### Conventional Commits
- `feat:` — Neues Feature
- `fix:` — Bugfix
- `refactor:` — Code-Umbau ohne Funktionsaenderung
- `docs:` — Dokumentation
- `chore:` — Wartung, Config, Dependencies

### Commit-Granularitaet
- **Eine Version pro Commit** — nicht mehrere Versionen buendeln
- Commit-Message nennt die Version: `feat: v3.16 — Tutorial-System`
- Erleichtert nachtraegliches Taggen und Rollbacks

### Branching
- Varianten als Branches (`variante-2`, `variante-3`)
- Nur aktiver Branch wird deployed
- `main` ist immer der Live-Branch
