# Multi-Session Task-System

Universelles, file-basiertes Task-Management fuer alle Claude Hangar Projekte.
Kein eigener Skill — globaler Mechanismus ueber CLAUDE.md Regeln.

## Ueberblick

Jedes Projekt bekommt eine `.tasks.json` wenn Aufgaben anfallen die mehrere Sessions brauchen.
Die Datei liegt im Projekt-Root (neben CLAUDE.md, STATUS.md etc.) und wird committet.

### Wann einen Task anlegen?

- Aufgabe braucht voraussichtlich mehrere Sessions
- Aufgabe hat klare Teilschritte die man tracken will
- Aufgabe ist blockiert und soll nicht vergessen werden
- Koordination zwischen verschiedenen Projekten noetig

### Wann KEINEN Task?

- Einzeiler, Typos, Config-Fixes → direkt machen
- Arbeit die in einer Session fertig wird
- Dinge die schon in STATUS.md stehen und nicht session-uebergreifend sind

---

## Schema

```json
{
  "version": 1,
  "project": "projektname",
  "tasks": [
    {
      "id": "T-001",
      "title": "Kurzer actionable Titel",
      "description": "Was genau zu tun ist. Kann auch auf State-Dateien verweisen.",
      "status": "open",
      "priority": "medium",
      "category": "feature",
      "created": "2026-02-18",
      "updated": "2026-02-18",
      "lock": null,
      "handoff": null,
      "dependencies": [],
      "tags": []
    }
  ],
  "archive": [],
  "meta": {
    "lastCleanup": "2026-02-18",
    "counters": { "open": 1, "in-progress": 0, "done": 0, "skipped": 0 }
  }
}
```

### Felder

| Feld | Typ | Pflicht | Beschreibung |
|------|-----|---------|-------------|
| `id` | string | ja | Fortlaufend: T-001, T-002, ... |
| `title` | string | ja | Kurz, actionable, imperativ |
| `description` | string | ja | Details, Kontext, Verweise auf State-Dateien |
| `status` | enum | ja | `open`, `in-progress`, `done`, `blocked`, `skipped` |
| `priority` | enum | ja | `critical`, `high`, `medium`, `low` |
| `category` | enum | ja | `bug`, `feature`, `security`, `docs`, `infra`, `cleanup` |
| `created` | date | ja | ISO-Datum (YYYY-MM-DD) |
| `updated` | date | ja | Wird bei jeder Aenderung aktualisiert |
| `lock` | object/null | nein | Locking-Info (siehe unten) |
| `handoff` | object/null | nein | Uebergabe-Info (siehe unten) |
| `dependencies` | string[] | nein | IDs von Tasks die vorher erledigt sein muessen |
| `tags` | string[] | nein | Freitext-Tags fuer Filterung |

### Status-Uebergaenge

```
open → in-progress → done
                   → blocked → open (wenn Blocker geloest)
                   → skipped
```

- `open` — Bereit zur Bearbeitung
- `in-progress` — Aktiv in Bearbeitung (Lock gesetzt)
- `done` — Erledigt
- `blocked` — Warte auf externe Abhaengigkeit oder Entscheidung
- `skipped` — Bewusst uebersprungen (mit Begruendung in description)

---

## Locking

File-basiert, kein Server noetig. Da Claude Code nur 1 Session pro Verzeichnis laeuft, gibt es keine echten Race Conditions.

### Lock-Objekt

```json
{
  "session": "2026-02-18T14:30:00Z",
  "lockedAt": "2026-02-18T14:30:00Z",
  "expiresAt": "2026-02-18T15:30:00Z"
}
```

### Regeln

1. **Lock setzen** wenn ein Task auf `in-progress` gesetzt wird
2. **Session-ID** = Timestamp (ISO) beim Setzen des Locks
3. **Ablaufzeit** = Lock-Zeitpunkt + 60 Minuten
4. **Abgelaufene Locks** duerfen von einer neuen Session uebernommen werden
   - Bedeutet: vorherige Session ist abgestuerzt oder wurde beendet ohne Aufzuraeumen
5. **Lock freigeben** am Session-Ende (Task auf `done`, `blocked` oder zurueck auf `open`)
6. **Nie zwei Tasks gleichzeitig locken** in derselben Session (Fokus!)

### Lock uebernehmen (Stale Lock)

Wenn ein Lock abgelaufen ist (>60 min):
1. Handoff lesen (falls vorhanden) — dort steht was erledigt wurde
2. Alten Lock entfernen
3. Neuen Lock setzen
4. Task weiterbearbeiten

---

## Handoff

Uebergabe-Objekt fuer Session-uebergreifende Arbeit. Wird geschrieben wenn eine Session einen Task nicht abschliessen kann.

### Handoff-Objekt

```json
{
  "from": "2026-02-18T14:30:00Z",
  "at": "2026-02-18T14:55:00Z",
  "note": "Phasen 1-2 erledigt, Phase 3 steht aus. State in .audit-state.json",
  "completedSteps": ["Phase 1: Detection", "Phase 2: Quick Wins"],
  "nextSteps": ["Phase 3: Performance Audit starten", "Lighthouse laufen lassen"]
}
```

### Regeln

1. **Immer Handoff schreiben** wenn Task nicht in derselben Session fertig wird
2. **completedSteps** und **nextSteps** muessen konkret und actionable sein
3. **note** fuer Kontext der nicht in die Listen passt (Credentials, Workarounds, etc.)
4. **Handoff ersetzt nicht STATUS.md** — STATUS.md bleibt die User-facing Uebersicht

---

## Lifecycle

### Session-Start

1. `.tasks.json` lesen (falls vorhanden)
2. Offene Tasks kurz zusammenfassen (Titel + Status)
3. Tasks mit abgelaufenen Locks melden
4. Falls User eine spezifische Aufgabe hat: pruefen ob passender Task existiert

### Waehrend der Session

1. Task auf `in-progress` setzen + Lock
2. Arbeit erledigen
3. Bei Zwischenschritten: `updated` Datum aktualisieren

### Session-Ende

1. Lock freigeben
2. Status aktualisieren (`done`, `blocked`, `open`)
3. Handoff schreiben wenn nicht fertig
4. `meta.counters` aktualisieren
5. STATUS.md aktualisieren (wie bisher)

### Cleanup (automatisch)

- **done/skipped Tasks aelter als 30 Tage** → ins `archive` Array verschieben
- **Cleanup-Datum** in `meta.lastCleanup` festhalten
- Archive wird nie geloescht — dient als History

---

## Interaktion mit bestehenden Systemen

### State-Dateien (.audit-state.json etc.)

Bestehende State-Dateien bleiben **unberuehrt**. Tasks referenzieren sie nur:

```json
{
  "id": "T-005",
  "title": "Example Project Audit Phase 3-4",
  "description": "Weitermachen ab Phase 3. State in .audit-state.json",
  "status": "open",
  "priority": "high",
  "category": "feature"
}
```

### STATUS.md

STATUS.md bleibt die User-facing Uebersicht. `.tasks.json` ist das maschinenlesbare Pendant.
Beide muessen konsistent gehalten werden — Tasks die in `.tasks.json` stehen, sollten sich in STATUS.md widerspiegeln.

### MEMORY.md

MEMORY.md ist fuer Learnings und Patterns. Tasks gehoeren da NICHT rein.

---

## Beispiele

### Neuen Task anlegen

```json
{
  "id": "T-001",
  "title": "Tutorial-System implementieren (v3.16)",
  "description": "12 Tutorial-Dateien in docs/tutorials/ erstellen. Siehe Plan in ROADMAP.md",
  "status": "open",
  "priority": "high",
  "category": "docs",
  "created": "2026-02-18",
  "updated": "2026-02-18",
  "lock": null,
  "handoff": null,
  "dependencies": [],
  "tags": ["docs", "tutorials"]
}
```

### Task in Bearbeitung

```json
{
  "id": "T-001",
  "title": "Tutorial-System implementieren (v3.16)",
  "status": "in-progress",
  "updated": "2026-02-18",
  "lock": {
    "session": "2026-02-18T14:30:00Z",
    "lockedAt": "2026-02-18T14:30:00Z",
    "expiresAt": "2026-02-18T15:30:00Z"
  }
}
```

### Task mit Handoff (Session-Ende, nicht fertig)

```json
{
  "id": "T-001",
  "title": "Tutorial-System implementieren (v3.16)",
  "status": "open",
  "updated": "2026-02-18",
  "lock": null,
  "handoff": {
    "from": "2026-02-18T14:30:00Z",
    "at": "2026-02-18T15:25:00Z",
    "note": "Session 1 von 3 erledigt.",
    "completedSteps": [
      "index.md erstellt",
      "pipeline-uebersicht.md erstellt",
      "skills/audit.md erstellt",
      "skills/project-audit.md erstellt"
    ],
    "nextSteps": [
      "Session 2: project/ + skills/ Tutorials schreiben",
      "Session 3: hooks/ + neue-projekte.md + Aktualisierungen"
    ]
  }
}
```

### Initiale .tasks.json (leeres Projekt)

```json
{
  "version": 1,
  "project": "claude-hangar",
  "tasks": [],
  "archive": [],
  "meta": {
    "lastCleanup": "2026-02-18",
    "counters": { "open": 0, "in-progress": 0, "done": 0, "skipped": 0 }
  }
}
```

---

## Konventionen

- **IDs** sind fortlaufend pro Projekt (T-001, T-002, ...) — nie wiederverwenden
- **Titel** im Imperativ ("Tutorial-System implementieren", nicht "Tutorial-System wird implementiert")
- **Prioritaet** nur `critical` wenn sofort handeln noetig (Security, Downtime)
- **Tags** frei waehlbar, aber konsistent innerhalb eines Projekts
- **Counters** nach jeder Aenderung aktualisieren (oder am Session-Ende)
- **.tasks.json wird committet** — gehört ins Repository
