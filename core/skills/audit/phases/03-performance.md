# Phase 03: Performance

Web-Performance-Pruefung mit Lighthouse, Core Web Vitals und Ressourcen-Analyse.
Finding-Prefix: `PERF`

---

## Checks

### 1. Lighthouse Audit

- [ ] Lighthouse in 3 Viewports ausfuehren: Mobile (375px), Tablet (768px), Desktop (1440px)
- [ ] Zielwerte: Performance >90, alle Kategorien >80
- [ ] Ergebnisse dokumentieren: Score + groesste Opportunities

### 2. Core Web Vitals

- [ ] **LCP** (Largest Contentful Paint): < 2.5s (gut), 2.5-4s (verbesserungswuerdig), >4s (schlecht)
- [ ] **INP** (Interaction to Next Paint): < 200ms (gut), 200-500ms (mittel), >500ms (schlecht)
- [ ] **CLS** (Cumulative Layout Shift): < 0.1 (gut), 0.1-0.25 (mittel), >0.25 (schlecht)
- [ ] LCP-Element identifizieren: Bild? Hero? Kann es schneller laden?

### 3. Bilder

- [ ] Formate: WebP oder AVIF statt PNG/JPG?
- [ ] Responsive: `srcset` / `sizes` Attribute? Framework-Image-Komponente genutzt?
- [ ] Lazy Loading: Bilder below-the-fold mit `loading="lazy"`?
- [ ] Groessen: Ueberdimensionierte Bilder? (z.B. 4000px breit fuer 800px Container)
- [ ] Hero/LCP-Bild: `loading="eager"` + `fetchpriority="high"`?
- [ ] Bilder-Inventar: Gesamtanzahl, groesste Dateien auflisten

### 4. Fonts

- [ ] Self-hosted? (DSGVO-relevant, siehe Phase 07)
- [ ] Format: WOFF2?
- [ ] `font-display: swap` oder `optional`?
- [ ] Preload fuer kritische Fonts? (`<link rel="preload" as="font">`)
- [ ] Anzahl Font-Dateien: Zu viele Varianten? (Weight, Style)
- [ ] Subset: Nur benoetigte Zeichen? (latin vs. full Unicode)

### 5. Caching

- [ ] Assets (CSS, JS, Bilder): Cache-Control mit langer max-age + immutable?
- [ ] HTML: Kein aggressives Caching (max-age=0 oder kurz)?
- [ ] Service Worker: Vorhanden? Sinnvoll konfiguriert?
- [ ] CDN: Eingesetzt? (Nicht zwingend, aber bei globalem Publikum)

### 6. Bundle & Code

- [ ] JavaScript-Bundle: Groesse? Code-Splitting?
- [ ] CSS: Unused CSS entfernt? (Framework-seitig oder PurgeCSS)
- [ ] HTML: Minimiert?
- [ ] Render-Blocking: Kritische Ressourcen identifizieren
- [ ] Third-Party Scripts: Welche? Impact auf Performance?

### 7. Server-Antwortzeiten

- [ ] TTFB (Time to First Byte): < 200ms (gut), 200-600ms (ok), >600ms (langsam)
- [ ] Kompression: gzip oder brotli aktiviert?
- [ ] HTTP/2 oder HTTP/3 aktiviert?

---

## Ergebnis

Findings als PERF-01, PERF-02, ... dokumentieren.
Performance >2s auf Hauptseiten: HIGH. Lighthouse <50: HIGH.
