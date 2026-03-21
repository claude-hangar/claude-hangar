# Phase 05: Accessibility

WCAG 2.1 AA Konformitaet — Barrierefreiheit fuer alle Nutzer.
Finding-Prefix: `A11Y`

---

## Checks

### 1. Kontrast

- [ ] Text auf Hintergrund: Kontrast >= 4.5:1 (normaler Text)
- [ ] Grosser Text (>=18px bold / >=24px): Kontrast >= 3:1
- [ ] UI-Elemente (Buttons, Inputs, Icons): Kontrast >= 3:1
- [ ] Hover/Focus-States: Kontrast ausreichend?
- [ ] Farbpalette des Projekts systematisch pruefen
- [ ] Tool: axe DevTools, Lighthouse Accessibility, oder manuell berechnen

### 2. Tastatur-Navigation

- [ ] Alle interaktiven Elemente per Tab erreichbar?
- [ ] Fokus-Reihenfolge logisch (nicht per tabindex manipuliert)?
- [ ] Fokus-Indikator sichtbar? (kein `outline: none` ohne Alternative)
- [ ] Escape schliesst Modals/Popups?
- [ ] Skip-Navigation-Link vorhanden? (`Skip to main content`)
- [ ] Keine Keyboard-Traps (Fokus bleibt nicht haengen)?
- [ ] In allen 3 Viewports testen: Mobile, Tablet, Desktop

### 3. ARIA & Semantik

- [ ] Landmarks: `<header>`, `<nav>`, `<main>`, `<footer>` korrekt?
- [ ] ARIA-Labels: Auf nicht-textuellen Buttons/Links?
- [ ] `aria-hidden="true"`: Nur auf dekorativen Elementen?
- [ ] `role`-Attribute: Nur wo noetig (nicht auf semantischen Elementen)?
- [ ] Live-Regions (`aria-live`): Fuer dynamische Inhalte?
- [ ] Kein ARIA ist besser als falsches ARIA

### 4. Bilder & Medien

- [ ] Alle `<img>` haben `alt`-Attribut?
- [ ] Alt-Texte beschreibend (nicht "Bild" oder Dateiname)?
- [ ] Dekorative Bilder: `alt=""` (leerer Alt-Text)?
- [ ] SVG-Icons: `aria-hidden="true"` oder `<title>` + `aria-labelledby`?
- [ ] Videos: Untertitel / Transkript vorhanden?

### 5. Formulare

- [ ] Jedes Input hat ein sichtbares `<label>` (per `for`/`id`)?
- [ ] Pflichtfelder: `required` + visueller Indikator + `aria-required`?
- [ ] Fehler-Meldungen: Klar, spezifisch, programmatisch verknuepft (`aria-describedby`)?
- [ ] Gruppen: `<fieldset>` + `<legend>` fuer zusammengehoerige Inputs?
- [ ] Autocomplete-Attribute fuer bekannte Felder (name, email, tel)?
- [ ] Formular-Validierung: Nicht nur Farbe als Indikator (auch Icon/Text)?

### 6. Responsive & Touch

- [ ] Touch-Targets: Mindestens 44x44px?
- [ ] Zoom: Seite bis 200% zoombar ohne Informationsverlust?
- [ ] Text-Reflow: Bei 400% Zoom kein horizontales Scrollen?
- [ ] Orientation: Funktioniert in Portrait und Landscape?

### 7. Screen-Reader

- [ ] Seitenstruktur: Ueberschriften-Hierarchie navigierbar?
- [ ] Landmarks: Navigation per Landmarks moeglich?
- [ ] Link-Texte aussagekraeftig (nicht "hier klicken")?
- [ ] Tabellen: `<th>` mit `scope`? Caption?
- [ ] Sprache: `lang`-Attribut korrekt?

---

## Ergebnis

Findings als A11Y-01, A11Y-02, ... dokumentieren.
Fehlende Keyboard-Navigation: HIGH. Kontrast-Fehler: MEDIUM.
BFSG-relevant: Barrierefreiheit ab Juni 2025 gesetzlich verpflichtend.
