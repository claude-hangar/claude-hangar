# Phase 06: Code-Qualitaet

Code-Qualitaet, Wartbarkeit, Testing und Development-Workflow.
Finding-Prefix: `CODE`

---

## Checks

### 1. Code-Stil & Konsistenz

- [ ] Linter konfiguriert? (ESLint, Biome, etc.) — Regeln sinnvoll?
- [ ] Formatter konfiguriert? (Prettier, Biome) — .prettierrc / biome.json?
- [ ] Editor-Config: `.editorconfig` vorhanden?
- [ ] Konsistente Namenskonventionen (camelCase, kebab-case fuer Dateien)?
- [ ] Keine toten Code-Bloecke, auskommentierter Code, console.log?

### 2. TypeScript / Typisierung

- [ ] TypeScript aktiviert? Strict-Mode?
- [ ] `any`-Nutzung: Minimiert? Wo noetig begruendet?
- [ ] Typen fuer Props, API-Responses, Config definiert?
- [ ] Type-Checking im CI/Build-Prozess?
- [ ] Wenn kein TypeScript: JSDoc-Typen genutzt?

### 3. Komponenten-Architektur

- [ ] Klare Trennung: Layout vs. UI vs. Page-Komponenten?
- [ ] Props klar definiert und dokumentiert?
- [ ] Keine ueberdimensionierten Komponenten (>200 Zeilen)?
- [ ] Wiederverwendung: Duplizierter Code in Komponenten extrahiert?
- [ ] Slots/Children sinnvoll genutzt?

### 4. Error Handling

- [ ] Try/Catch an den richtigen Stellen? (API-Calls, File-Ops, DB)
- [ ] Fehler-Seiten: 404, 500 — informativ und gestaltet?
- [ ] Fehler-Logging: Strukturiert? Keine Secrets in Logs?
- [ ] Graceful Degradation: Was passiert bei Netzwerk-Fehler?

### 5. Testing

- [ ] Tests vorhanden? Welche Art? (Unit, Integration, E2E)
- [ ] Test-Coverage: Kritische Pfade abgedeckt?
- [ ] Tests laufen? `npm test` — alle gruen?
- [ ] Test-Daten: Keine produktiven Credentials in Tests?
- [ ] CI: Tests laufen automatisch bei Push/PR?

### 6. Dependencies

- [ ] Anzahl Dependencies: Angemessen? Nicht aufgeblaeht?
- [ ] Veraltete Pakete: `npm outdated` — Major-Updates?
- [ ] Ungenutzte Dependencies: In package.json aber nicht importiert?
- [ ] Peer-Dependencies: Warnungen beim Install?
- [ ] Doppelte Dependencies: Verschiedene Versionen desselben Pakets?

### 7. Git & Workflow

- [ ] .gitignore: Vollstaendig? (node_modules, .env, dist, .DS_Store)
- [ ] Commit-Historie: Sinnvolle Messages? Conventional Commits?
- [ ] Branch-Strategie: main/develop/feature?
- [ ] CI/CD: Pipeline konfiguriert? Build + Test + Deploy?
- [ ] GitHub Actions: Workflows funktionieren? Letzte Runs gruen?
- [ ] Deploy-Prozess: Automatisch (CI/CD) oder manuell? Dokumentiert?

---

## Ergebnis

Findings als CODE-01, CODE-02, ... dokumentieren.
Fehlende Tests fuer kritische Pfade: HIGH. Stil-Inkonsistenzen: LOW.
