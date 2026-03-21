# Phase 03: Code-Qualitaet

Patterns, Complexity, Dead Code, Typisierung, Linting, Formatting.
Finding-Prefix: `CODE`

---

## Checks

### 1. Code-Patterns & Konsistenz

- [ ] Einheitlicher Stil? (Naming, Einrueckung, Klammern)
- [ ] Design-Patterns angemessen eingesetzt? (nicht Over-Engineered)
- [ ] DRY: Keine offensichtliche Code-Duplikation?
- [ ] KISS: Einfache Loesungen wo moeglich?
- [ ] Error-Handling: Konsistentes Pattern? (throw, return, callback)

### 2. Complexity

- [ ] Ueberlange Funktionen? (>50 Zeilen = Warnung, >100 = Finding)
- [ ] Verschachtelungstiefe >3? (if > if > if > ...)
- [ ] Zyklomatische Komplexitaet: Funktionen mit >10 Pfaden?
- [ ] God-Dateien: Dateien >500 Zeilen die zu viel machen?
- [ ] Parameter-Listen: Funktionen mit >5 Parametern?

### 3. Dead Code

- [ ] Ungenutzte Exports/Funktionen?
- [ ] Auskommentierte Code-Bloecke? (>5 Zeilen = aufraeuemen)
- [ ] Unreachable Code nach return/throw/exit?
- [ ] Ungenutzte Variablen/Imports?
- [ ] Feature-Flags die nie aktiviert wurden?
- [ ] TODO/FIXME/HACK Kommentare: Noch relevant oder veraltet?

### 4. Typisierung

- [ ] TypeScript / JSDoc / Type Hints genutzt?
- [ ] Strict Mode aktiviert? (tsconfig `strict: true`, mypy `strict`)
- [ ] `any`/`unknown`/`type: ignore` Nutzung minimal? Wo begruendet?
- [ ] Type-Check in CI? (`tsc --noEmit`, `mypy`, `pyright`)
- [ ] Externe Types: `@types/*` Pakete aktuell?

### 5. Linting

- [ ] Linter konfiguriert? (ESLint, Biome, pylint, ruff, shellcheck)
- [ ] Null Fehler? Nur Warnungen?
- [ ] Regeln sinnvoll? Nicht zu streng, nicht zu locker?
- [ ] Lint-Fehler blockieren CI? (Exit-Code != 0)
- [ ] Linter-Config committet und konsistent?

### 6. Formatting

- [ ] Formatter konfiguriert? (Prettier, Biome, Black, ruff format, shfmt)
- [ ] Format-Check in CI?
- [ ] Konsistent: Alle Dateien formatiert oder nur bestimmte?
- [ ] .editorconfig fuer grundlegende Konsistenz?

### 7. Code-Smells

- [ ] console.log / print-Debugging noch im Code?
- [ ] Hardcodierte Werte die Config sein sollten? (URLs, Ports, Pfade)
- [ ] Magic Numbers ohne Erklaerung?
- [ ] Leere catch-Bloecke / Exception-Swallowing?
- [ ] Globale Variablen / Singletons ohne Not?

---

## Ergebnis

Findings als CODE-01, CODE-02, ... dokumentieren.
Keine Typisierung fuer kritische Module: HIGH. Dead Code: MEDIUM. Magic Numbers: LOW.
