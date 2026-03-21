# Tutorial: /capture-pdf — Website als PDF dokumentieren

## Wann brauche ich das?

- Du willst eine **komplette Website als PDF** erfassen — alle Seiten, alle Viewports
- Du brauchst eine **Kunden-Praesentation** oder ein **Abnahme-Protokoll**
- Du willst **interaktive Zustaende** dokumentieren (Cookie-Banner, Formulare, Modals)
- Du brauchst ein **Archiv** einer Website zu einem bestimmten Zeitpunkt

Der Skill funktioniert mit **jeder Website** — lokal (localhost) oder remote (live URL).

---

## So geht's

### Schnellstart (Quick Mode)

```
/capture-pdf quick
```

Keine Rueckfragen. Erkennt automatisch die Seiten, macht Desktop-Screenshots + Smart Captures und erstellt ein PDF.

### Interaktiver Modus

```
/capture-pdf start
```

Claude analysiert dein Projekt, zeigt die gefundenen Seiten und fragt nach Optionen:
1. **Seiten** — Welche Seiten capturen? (Auto-Erkennung via Sitemap/Routes/Crawling)
2. **Viewport** — Desktop / Tablet / Mobile / Alle?
3. **Format** — A4 oder A3?
4. **Smart Captures** — Cookie-Banner, Formulare, Akkordeons etc.?

### Externe Website

```
/capture-pdf url https://example.com
```

Funktioniert mit jeder oeffentlichen Website.

### Nur bestimmte Seiten

```
/capture-pdf seite /kontakt /ueber-uns /faq
```

### Nur Formulare

```
/capture-pdf forms
```

Scannt alle Seiten, findet Formulare, fuellt sie mit Musterdaten aus und erfasst den Zustand.

---

## Beispiel-Session

```
User: /capture-pdf start

Claude: Projekt erkannt: my-website
        Dev-Server: http://localhost:4321
        13 Seiten gefunden via Sitemap.

        Seiten:
        1. Startseite (/)
        2. Wohnen (/wohnen)
        3. Pflege (/pflege)
        ...

        Optionen:
        - Viewport: Desktop (1920x1080) [empfohlen]
        - Format: A4
        - Smart Captures: Ja (Cookie-Banner, Formulare, Akkordeons)

        Soll ich mit diesen Einstellungen starten?

User: Ja, los

Claude: [Generiert scripts/capture-pdf.mjs]
        [Installiert playwright, pdf-lib, sharp]
        [1/13] Startseite (/)... OK
          Smart Captures: cookie, forms
        [2/13] Wohnen (/wohnen)... OK
          Smart Captures: accordions
        ...
        [13/13] Kontakt (/kontakt)... OK
          Smart Captures: forms

        PDF gespeichert: prints/my-website-desktop-2026-02-17.pdf (4.2 MB)

        Zusammenfassung:
        - 13/13 Seiten erfolgreich
        - 8 Smart Captures
        - prints/ zu .gitignore hinzugefuegt
```

---

## Was wird erfasst?

| Element | Beschreibung |
|---------|-------------|
| Saubere Seiten | Jede Seite ohne Overlays, Animationen gestoppt, Bilder geladen |
| Cookie-Banner | Banner sichtbar, bevor Consent gegeben wird |
| Formulare | Mit Musterdaten ausgefuellt (Name, E-Mail, Telefon etc.) |
| Akkordeons/Tabs | Alle aufgeklappt |
| Modals/Dialoge | Geoeffneter Zustand |
| Mobile Menu | Hamburger-Menu geoeffnet (nur bei Mobile-Viewport) |
| Lightboxes | Erstes Bild einer Galerie geoeffnet |

---

## PDF-Aufbau

1. **Cover** — Projektname, Viewport, Datum, URL
2. **Inhaltsverzeichnis** — Alle Seiten + Smart Captures mit Seitenzahlen
3. **Seiten-Captures** — Pro Seite: Clean Screenshot + Smart Captures mit Labels

Lange Seiten werden automatisch auf mehrere PDF-Seiten aufgeteilt.

---

## FAQ

**Muss ich Playwright vorher installieren?**
Nein. Das Script installiert alle Dependencies automatisch (playwright, pdf-lib, sharp).

**Funktioniert das auf Windows?**
Ja, vollstaendig kompatibel mit Windows 11 + Git Bash.

**Werden Formulare wirklich abgeschickt?**
Nein, niemals. Das Script fuellt nur visuell aus und verhindert jeden Submit.

**Was passiert bei einem Captcha?**
Das Formular wird ausgefuellt, aber der Captcha-Zustand wird im PDF notiert.

**Kann ich die Musterdaten aendern?**
Ja — lege `scripts/form-data.json` im Projekt an. Das Script bevorzugt lokale Daten.

**Wo landen die PDFs?**
Im `prints/` Ordner des Projekts (wird automatisch zu .gitignore hinzugefuegt).

---

## Naechste Schritte

- Probiere `/capture-pdf quick` in einem deiner Projekte
- Passe die Seiten-Liste oder Musterdaten bei Bedarf an
- Nutze `/capture-pdf forms` fuer eine reine Formular-Dokumentation
