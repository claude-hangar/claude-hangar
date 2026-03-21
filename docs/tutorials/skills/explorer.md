# Explorer — Code analysieren ohne zu aendern

> Ein schlanker Agent der Code liest, Architektur erklaert und Fragen beantwortet — ohne jemals eine Datei zu veraendern.

## Wann brauche ich das?

- Du willst verstehen wie ein bestimmter Teil des Codes funktioniert
- Du suchst eine Datei oder Funktion im Projekt
- Du willst die Architektur erklaert bekommen
- Du willst sicher sein dass nichts veraendert wird (Read-only)

## So geht's

Der Explorer ist ein Agent, kein Skill. Er wird automatisch gestartet wenn du Fragen stellst wie:

```
"Analysiere die Ordnerstruktur"
"Erklaere wie der Email-Versand funktioniert"
"Wo ist die Navigation definiert?"
"Zeig mir alle Dateien die mit Formularen zu tun haben"
"Wie funktioniert das Cookie-Banner?"
```

### Was der Explorer kann

- **Dateien lesen** — jede Datei im Projekt oeffnen und anzeigen
- **Suchen** — nach Dateinamen, Code-Patterns, Funktionsnamen
- **Git-History** — wer hat was wann geaendert (git log, git diff)
- **Dependencies** — welche Pakete sind installiert (npm ls)
- **Erklaeren** — Zusammenhaenge zwischen Dateien aufzeigen

### Was der Explorer NICHT kann

- Dateien aendern (Write/Edit sind gesperrt)
- Befehle ausfuehren die etwas veraendern
- Auf Server zugreifen (kein SSH)

Das ist absichtlich so — der Explorer ist garantiert sicher.

## Beispiel-Session

```
Du: "Erklaere mir die Architektur der Website"

Explorer:
→ Liest package.json → Astro 6 + Tailwind v4
→ Liest astro.config.mjs → Static Output, Tailwind Plugin
→ Liest src/config/site.ts → Zentrale Konfiguration
→ Liest src/layouts/BaseLayout.astro → HTML-Grundgeruest

Zusammenfassung:
- Astro Static Site mit 8 Seiten
- Zentrale Config in site.ts (Kontakt, Navigation, Social)
- Tailwind v4 Config komplett in CSS (@theme Block)
- Self-hosted Fonts (Outfit + Inter)
- Mobile Menu: Popover API (bewusst kein JS)
```

```
Du: "Wo werden Formular-Submissions verarbeitet?"

Explorer:
→ Sucht nach "form" in src/
→ Findet: kontakt.js, infomaterial.js, bewerbung.js
→ Liest die Route-Handler
→ Folgt dem Pfad: Route → Validation → Turnstile → Queue → Sender

Zusammenfassung:
- 3 Endpoints: /api/kontakt, /api/infomaterial, /api/bewerbung
- Alle nutzen SQLite-Queue (src/services/queue.js)
- Triple-Failover: Graph API → Brevo HTTP → SMTP
- Turnstile-Check vor jeder Submission
```

## Haeufige Fragen

- **Wie starte ich den Explorer?** → Einfach eine Frage stellen die mit "analysiere", "erklaere", "wo ist", "zeig mir" oder "wie funktioniert" beginnt. Er wird automatisch gewaehlt.
- **Kann der Explorer Fehler machen?** → Er kann falsch interpretieren, aber er kann nichts kaputt machen (keine Schreibrechte).
- **Ist der Explorer langsamer als direkt fragen?** → Er nutzt ein schnelleres Modell (Haiku) und ist dadurch schneller und guenstiger als der normale Modus.
- **Kann ich nach der Analyse Aenderungen machen?** → Ja. Sag einfach was du aendern willst — dann wechselt der Modus automatisch.

## Naechste Schritte

- [Audit](audit.md) — Systematisch pruefen (findet Probleme, nicht nur erklaert)
- [Pipeline-Uebersicht](../pipeline-uebersicht.md) — Gesamtsystem verstehen
