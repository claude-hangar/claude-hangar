# Astro-Audit — Versions-Check und Migration

> Prueft deine installierte Astro-Version gegen die neueste, laedt die passende Checkliste und fuehrt dich durch die Migration.

## Wann brauche ich das?

- Du willst wissen ob dein Astro-Projekt auf dem neuesten Stand ist
- Eine neue Astro-Version ist erschienen und du ueberlegst ob du upgraden sollst
- Du willst Best Practices fuer deine aktuelle Version pruefen
- Du migrierst von Astro 5 auf 6 (oder eine zukuenftige Version)

## So geht's

### Schritt 1: Audit starten

```
/astro-audit start
```

Was passiert:
1. **Auto-Detection** — Astro-Version, Node-Version, Adapter, Integrations werden erkannt
2. **Versions-Vergleich** — Deine installierte Version vs. neueste verfuegbare (live per `npm view`)
3. **Frage:** "Aktuelle Version pruefen ODER auf neue Version migrieren?"
4. **Passende Checkliste** wird geladen
5. **Erste 2 Bereiche** werden gegen dein Projekt geprueft
6. **State** wird in `.astro-audit-state.json` gespeichert

### Schritt 2: Weiterarbeiten

```
/astro-audit weiter
```

Liest den State, arbeitet die naechsten 2 Bereiche oder 5 Findings ab.

### Schritt 3: Fortschritt pruefen

```
/astro-audit status
```

Zeigt: Welche Bereiche erledigt, welche offen, Findings pro Severity.

### Schritt 4: Neue Releases pruefen

```
/astro-audit refresh
```

Prueft ob es eine neuere Astro-Version gibt als bei deinem letzten Audit.

## Verfuegbare Checklisten

| Checkliste | Fuer wen | Inhalt |
|-----------|----------|--------|
| v5-stable | Astro 5.x Projekte | 22 Best-Practice Checkpunkte |
| v6-beta | Migration Astro 5→6 | 52 Migrations-Checkpunkte in 14 Bereichen |
| v6-stable | Astro 6.x Projekte | (wird bei Stable-Release befuellt) |
| v7 | Zukuenftig | (Platzhalter) |

Die richtige Checkliste wird automatisch anhand deiner installierten Version gewaehlt.

## Beispiel-Session: Upgrade-Entscheidung

```
Session 1:
Du: /astro-audit start
→ "Installiert: Astro 5.17.2, Node 22.12.0"
→ "Neueste Version: Astro 6.0.0-beta.12"
→ "Aktuelle Version pruefen oder auf 6 migrieren?"
→ Du: "Erstmal pruefen ob mein Projekt up-to-date ist"
→ v5-stable Checkliste: 2 Bereiche geprueft
→ 3 Findings (alle MEDIUM — Best Practices)
→ "Projekt ist solide. Migration auf v6 ist optional."

Spaeter wenn v6 stable ist:
Du: /astro-audit refresh
→ "Astro 6.0.0 ist jetzt stable! Migration empfohlen."
Du: /astro-audit start
→ v6-stable Checkliste wird geladen
→ Migrations-Schritte werden Punkt fuer Punkt durchgegangen
```

## Beispiel-Session: Migration durchfuehren

```
Session 1:
Du: /astro-audit start
→ "Installiert: 5.17.2, Neueste: 6.0.0-beta.12"
→ Du: "Auf 6 migrieren"
→ v6-beta Checkliste geladen (52 Checkpunkte)
→ Bereich ENV + CFG geprueft: 4 Findings
→ "Naechste Session: /astro-audit weiter"

Session 2:
Du: /astro-audit weiter
→ Bereich CODE + COLL geprueft
→ 6 weitere Findings (Content Collections muessen umgebaut werden)

Session 3:
Du: /astro-audit weiter
→ CRITICAL Findings fixen (Node-Version, Breaking Changes)
→ 3 gefixt, 7 offen

...und so weiter bis alle 14 Bereiche durch sind.
```

## Haeufige Fragen

- **Muss ich jede neue Beta ausprobieren?** → Nein. `/astro-audit refresh` informiert dich ueber neue Releases. Du entscheidest ob und wann.
- **Was wenn ein Checkpunkt nicht relevant ist?** → Ueberspringen (`skipped`). Nicht alles trifft auf jedes Projekt zu.
- **Was ist der Unterschied zu /audit?** → `/astro-audit` ist nur fuer Astro-Versions- und Migrationsthemen. `/audit` prueft alles (Code, Server, Security...). Beide ergaenzen sich.
- **Brauche ich Node 22 fuer Astro 6?** → Ja, das ist ein CRITICAL Checkpunkt. Wird als erstes geprueft.

## Naechste Schritte

- [Audit](audit.md) — Generischer Projekt-Audit (Code, Security, Performance...)
- [Explorer](explorer.md) — Code analysieren ohne etwas zu aendern
