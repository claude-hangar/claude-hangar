# Stack-Supplement: Playwright (Visual & E2E Testing)

Playwright-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

**Wichtig:** Dieses Supplement fuegt jedem Phase-Durchlauf visuelle Verifikation hinzu.
Playwright Tests erfordern einen laufenden Dev-Server oder eine erreichbare URL.

---

## §IST-Analyse

- [ ] Playwright-Version: `npx playwright --version` + package.json
- [ ] Config: `playwright.config.*` — Welche Browser? Welche Viewports?
- [ ] Bestehende Tests: `tests/` oder `e2e/` Verzeichnis? Wie viele Tests?
- [ ] Test-Ergebnis: `npx playwright test` — alle gruen?
- [ ] **Seiten-Inventar visuell:**
  - [ ] Alle Seiten/Routen auflisten (aus Sitemap, Config, oder Router)
  - [ ] Pro Seite Screenshots in 3 Viewports:
    - Mobile: 375x812 (iPhone SE)
    - Tablet: 768x1024 (iPad)
    - Desktop: 1440x900
  - [ ] Screenshots ablegen als `audit-screenshots/{seite}-{viewport}.png`
  - [ ] Ueberblick: Welche Seiten existieren? Welche sind leer/kaputt?

### Auth fuer Staging

Wenn Staging hinter Basic Auth:
```typescript
const context = await browser.newContext({
  httpCredentials: { username: '...', password: '...' }
});
```
**NIEMALS** Credentials in die URL! Immer `httpCredentials` nutzen.

## §Security

- [ ] **Auth-Seiten pruefen:** Login/Admin-Bereiche erreichbar? Redirects korrekt?
- [ ] **Staging-Schutz:** Basic Auth aktiv? Ohne Credentials → 401?
- [ ] **Error-Pages:** 404-Seite zeigt keine Stack-Traces oder Server-Info?
- [ ] **HTTPS-Redirect:** HTTP-URL → automatisch HTTPS? Kein Mixed Content?
- [ ] **Formulare:** CSRF-Token vorhanden? Rate Limiting greift bei Spam?

## §Performance

- [ ] **CLS visuell pruefen:** Seite laden, auf Layout-Shifts achten
  - [ ] `page.evaluate(() => new PerformanceObserver(...)` fuer CLS-Wert
  - [ ] Hero-Bereich: Springt Bild/Text beim Laden?
  - [ ] Font-Swap: Sichtbarer Wechsel (FOUT)?
- [ ] **LCP visuell:** Hauptinhalt sichtbar < 2.5s?
  - [ ] `page.evaluate(() => performance.getEntriesByType('largest-contentful-paint'))`
- [ ] **Lazy Loading:** Below-the-fold Bilder laden erst beim Scrollen?
- [ ] **Skeleton/Loading-States:** Bei dynamischen Inhalten sichtbar?

## §SEO

- [ ] **Redirects verifizieren:** Alte URLs (z.B. WordPress) → korrekte neue URL?
  - [ ] Stichproben: 5-10 alte URLs pruefen, Status 301?
  - [ ] `page.goto(alteUrl)` → `page.url()` vergleichen
- [ ] **404-Seite:** Custom Design? Hilfreiche Links? Kein generischer Server-Error?
- [ ] **Canonical-Check:** `page.locator('link[rel=canonical]').getAttribute('href')` korrekt?
- [ ] **Meta-Tags visuell:** Title in Browser-Tab korrekt? OG-Image existiert?

## §Accessibility

- [ ] **Keyboard-Navigation (alle 3 Viewports):**
  - [ ] Tab durch alle Seiten: Fokus sichtbar? Reihenfolge logisch?
  - [ ] Enter/Space auf Buttons und Links: Funktioniert?
  - [ ] Escape: Schliesst Modals, Popovers, Menues?
  - [ ] Skip-Link: Vorhanden? Funktioniert bei Tab?
- [ ] **Fokus-Management:**
  - [ ] Nach Navigation (View Transitions): Fokus zurueckgesetzt?
  - [ ] Modal/Popover oeffnen: Fokus springt rein?
  - [ ] Modal/Popover schliessen: Fokus zurueck zum Trigger?
- [ ] **Touch-Targets:**
  - [ ] Mobile Viewport: Alle klickbaren Elemente >= 44x44px?
  - [ ] `page.locator('a, button').evaluateAll(...)` fuer Groessen-Check
- [ ] **Mobile Menu:**
  - [ ] Oeffnen per Touch/Click
  - [ ] Alle Links erreichbar
  - [ ] Schliessen per Escape und Overlay-Click
  - [ ] Fokus-Trap: Tab bleibt im Menu?
- [ ] **Cookie Banner:**
  - [ ] Erscheint beim ersten Besuch?
  - [ ] Keyboard-bedienbar? (Tab, Enter)
  - [ ] Seite dahinter blockiert? (inert/aria-hidden)
  - [ ] Ablehnen genauso einfach wie Annehmen?
- [ ] **Formulare E2E:**
  - [ ] Jedes Formular ausfuellen und absenden (Test-Daten)
  - [ ] Validierung: Pflichtfeld leer → Fehlermeldung sichtbar?
  - [ ] Fehlermeldung: Verknuepft mit Input? (aria-describedby)
  - [ ] Erfolg: Bestaetigung sichtbar? Screen-Reader-tauglich?
- [ ] **Kontrast visuell:** Dark-on-light und light-on-dark Bereiche pruefen
- [ ] **Zoom-Test:** 200% Zoom → Layout bricht nicht? 400% → kein horizontales Scrollen?

## §Code-Quality

- [ ] Playwright-Config: Best Practices eingehalten?
  - [ ] `retries` konfiguriert? (mindestens 1 fuer CI)
  - [ ] `timeout` sinnvoll? (nicht zu kurz, nicht zu lang)
  - [ ] `projects` fuer mehrere Browser? (Chromium, Firefox, WebKit)
- [ ] Test-Struktur: Klare Benennung? Logische Gruppierung?
- [ ] Page Object Pattern oder aehnliche Abstraktion?
- [ ] Keine `page.waitForTimeout()`! → `page.waitForSelector()` oder `expect().toBeVisible()`
- [ ] Screenshots: Werden bei Fehlern automatisch gespeichert? (`screenshot: 'only-on-failure'`)

## §Infrastruktur

- [ ] CI-Integration: Playwright Tests in GitHub Actions/CI Pipeline?
- [ ] Docker: Playwright-Container fuer konsistente Test-Umgebung?
- [ ] Fixtures: Test-Daten isoliert? Keine Abhaengigkeit von Prod-Daten?
- [ ] Parallelisierung: Tests laufen parallel? (`workers` konfiguriert?)
