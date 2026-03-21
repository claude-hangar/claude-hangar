# Phase 04: SEO

Suchmaschinenoptimierung — technisches SEO, Meta-Daten, strukturierte Daten.
Finding-Prefix: `SEO`

---

## Checks

### 1. Meta-Tags

- [ ] Jede Seite: Eindeutiger `<title>` (50-60 Zeichen)?
- [ ] Jede Seite: `<meta name="description">` (120-160 Zeichen)?
- [ ] `<html lang="...">` korrekt gesetzt?
- [ ] `<meta charset="utf-8">` vorhanden?
- [ ] `<meta name="viewport">` korrekt?
- [ ] Staging: `<meta name="robots" content="noindex">` NUR auf Staging, NICHT auf Prod!

### 2. Open Graph & Social

- [ ] `og:title`, `og:description`, `og:image` auf allen Seiten?
- [ ] `og:url` korrekt (kanonische URL)?
- [ ] `og:type` gesetzt (website / article)?
- [ ] `og:image`: Mindestens 1200x630px? Existiert die Datei?
- [ ] Twitter Cards: `twitter:card`, `twitter:title`, `twitter:description`?

### 3. Structured Data (Schema.org)

- [ ] JSON-LD auf relevanten Seiten?
- [ ] Typ passend: Organization, LocalBusiness, WebSite, BreadcrumbList?
- [ ] Pflichtfelder: name, url, logo, contactPoint?
- [ ] Google Rich Results Test: Valide?
- [ ] FAQ-Schema, Event-Schema wo passend?

### 4. Sitemap & Robots

- [ ] `sitemap.xml` vorhanden? Alle relevanten URLs enthalten?
- [ ] Keine Draft-/Staging-URLs in der Sitemap?
- [ ] `robots.txt` vorhanden? Sitemap referenziert?
- [ ] Kein versehentliches `Disallow: /` auf Prod?
- [ ] Sitemap bei Google Search Console eingereicht?

### 5. URL-Struktur & Navigation

- [ ] Sprechende URLs (kein `/page-123`)?
- [ ] Canonical URLs auf allen Seiten? (`<link rel="canonical">`)
- [ ] Keine doppelten Seiten (www vs. non-www, trailing slash)?
- [ ] 301-Redirects fuer alte URLs? (WordPress-Migration etc.)
- [ ] 404-Seite: Vorhanden und hilfreich?
- [ ] Breadcrumbs: Vorhanden? Schema.org BreadcrumbList?

### 6. Heading-Hierarchie

- [ ] Genau ein `<h1>` pro Seite?
- [ ] Logische Hierarchie: h1 → h2 → h3 (keine Spruenge)?
- [ ] Keywords in h1 und h2?
- [ ] Keine leeren Headings?

### 7. Internationalisierung (falls relevant)

- [ ] `hreflang`-Tags fuer mehrsprachige Seiten?
- [ ] Sprach-Switcher korrekt verlinkt?

---

## Ergebnis

Findings als SEO-01, SEO-02, ... dokumentieren.
Fehlende Sitemap/Robots: HIGH. Fehlende Meta-Tags: MEDIUM.
