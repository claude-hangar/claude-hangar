# Phase 01: IST-Analyse

Bestandsaufnahme des Projekts — Versionen, Konfiguration, Architektur.
Finding-Prefix: `IST`

---

## Checks

### 1. Versionen & Dependencies

- [ ] `package.json` lesen: Alle Haupt-Dependencies mit Versionen auflisten
- [ ] Aktuelle Versionen pruefen (npm view / context7): Major-Updates verfuegbar?
- [ ] `npm audit` ausfuehren: Bekannte Vulnerabilities?
- [ ] Lock-File vorhanden und konsistent? (package-lock.json / pnpm-lock.yaml)
- [ ] Node.js-Version: In `.nvmrc`, `engines`, oder Dockerfile definiert?
- [ ] Dev-Dependencies: Veraltete oder ungenutzte Pakete?

### 2. Konfiguration

- [ ] Framework-Config lesen (astro.config.*, next.config.*, nuxt.config.*)
- [ ] Build-Output: static / SSR / hybrid? Passt zum Deployment?
- [ ] TypeScript-Config: strict mode? Konsistent?
- [ ] Linter/Formatter: ESLint, Prettier, Biome konfiguriert?
- [ ] Environment-Variablen: .env.example vorhanden? Alle dokumentiert?

### 3. Projektstruktur

- [ ] Verzeichnisstruktur analysieren: Konventionen eingehalten?
- [ ] Seitenanzahl / Routen zaehlen
- [ ] Komponenten-Inventar: Wie viele, Wiederverwendung?
- [ ] Assets: Bilder (Anzahl, Formate, Groessen), Fonts, Icons
- [ ] Config-Dateien: site.ts / constants / Feature-Toggles?

### 4. Build & Output

- [ ] `npm run build` ausfuehren: Warnungen? Fehler?
- [ ] Build-Groesse: HTML, CSS, JS Bundle-Sizes
- [ ] Generierte Dateien pruefen: Sitemap, robots.txt, Manifest?
- [ ] Source Maps: Nur in Dev, nicht in Prod?

### 5. Dokumentation

- [ ] README.md vorhanden und aktuell?
- [ ] Bestehende Audit-Docs: AUDIT-FINDINGS*.md, TODO*.md
- [ ] Setup-Anleitung: Kann ein neuer Entwickler das Projekt starten?
- [ ] Architektur-Entscheidungen dokumentiert?

---

## Ergebnis

Tabelle erstellen:

```
| Bereich | Status | Details |
|---------|--------|---------|
| Framework | ✅/⚠️/❌ | Name + Version |
| CSS | ... | ... |
| Dependencies | ... | X veraltet, Y vulnerabilities |
| Build | ... | Groesse, Warnungen |
| Doku | ... | Vorhanden/fehlend |
```

Findings als IST-01, IST-02, ... dokumentieren.
