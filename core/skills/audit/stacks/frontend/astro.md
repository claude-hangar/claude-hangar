# Stack-Supplement: Astro

Astro-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

---

## §IST-Analyse

- [ ] Astro-Version pruefen: `astro --version` und package.json (context7 fuer aktuelle Version)
- [ ] `astro check` ausfuehren — TypeScript-Fehler, fehlende Typen?
- [ ] Config: `astro.config.*` — Output-Modus (static/hybrid/server)?
- [ ] Integrationen: Welche Astro-Integrationen installiert? (@astrojs/sitemap, @astrojs/image, etc.)
- [ ] Seiten-Inventar: `src/pages/` — Anzahl, Routing-Struktur
- [ ] Komponenten-Inventar: `src/components/` — Anzahl, Framework-Komponenten (React/Vue/Svelte)?
- [ ] Layouts: `src/layouts/` — Wie viele, Vererbungs-Hierarchie?
- [ ] Content Collections: Genutzt? Schema definiert?
- [ ] Config/Site: `src/config/` oder `site.ts` — Zentrale Konfiguration? Feature-Toggles?

## §Security

- [ ] Server-Endpoints (`src/pages/api/`): Input-Validierung? Rate Limiting?
- [ ] SSR-Modus: Wenn hybrid/server — Environment-Variablen sicher? (PUBLIC_ Prefix beachten)
- [ ] `astro:env` genutzt? Secrets korrekt als `secret` markiert?
- [ ] Keine sensitiven Daten in statischem Output (dist/)?

## §Performance

- [ ] `<Image>` Komponente statt `<img>` fuer lokale Bilder?
- [ ] `astro:assets` — Automatische Optimierung aktiv?
- [ ] View Transitions: Aktiviert? Scripts mit `astro:after-swap` Event?
- [ ] Islands-Architektur: `client:*` Direktiven minimal eingesetzt?
- [ ] `client:idle` / `client:visible` statt `client:load` wo moeglich?
- [ ] Prerender: Statische Seiten vorgerendert?
- [ ] Bundle: `astro build` Output-Groesse pruefen

## §SEO

- [ ] `<BaseHead>` oder aehnliche Komponente: Meta-Tags zentral verwaltet?
- [ ] `@astrojs/sitemap` Integration installiert und konfiguriert?
- [ ] `astro.config` → `site` Property gesetzt? (fuer Sitemap, Canonical)
- [ ] Trailing Slash: Konsistent konfiguriert? (`trailingSlash: 'always'` / `'never'`)
- [ ] Redirects: In Config oder per `Astro.redirect()`?

## §Accessibility

- [ ] View Transitions: `<ViewTransitions />` — Focus-Management nach Navigation?
- [ ] `astro:after-swap` Event: Screen-Reader Announcements?
- [ ] Islands: Hydrated Komponenten — ARIA-Attribute im Server-Output?
- [ ] Scoped Styles: `:global()` fuer Fokus-Indikatoren noetig?

## §Code-Quality

- [ ] `astro check` — Null Fehler?
- [ ] Astro-spezifische Linting: `eslint-plugin-astro` konfiguriert?
- [ ] Props: Alle Komponenten-Props typisiert? (interface Props / Astro.props)
- [ ] Frontmatter: Logik kurz halten, Utilities auslagern
- [ ] Slots: Benannte Slots korrekt genutzt?
- [ ] Content Collections: Schema validiert? `getCollection()` statt manuelle Imports?

## §DSGVO

- [ ] Fonts in `public/fonts/` — Self-hosted, kein CDN?
- [ ] `<link rel="preconnect">` nur zu eigenen Domains?
- [ ] Client-Side Scripts: Laden sie externe Ressourcen ohne Consent?
- [ ] Cookie Banner: Blockiert `inert`-Attribut den Rest der Seite?

## §Infrastruktur

- [ ] Build-Container: Node-Version passt zu Astro-Anforderungen?
- [ ] Static Output: Wird per nginx/Caddy ausgeliefert?
- [ ] Asset-Hashing: Astro generiert hashed Filenames — Cache-Header passend?
