# Phase 01: Struktur & Architektur

Ordnerstruktur, Architektur-Patterns, Coupling, Layering, Config-Dateien.
Finding-Prefix: `STRUC`

---

## Checks

### 1. Ordnerstruktur

- [ ] Logische Gruppierung? (src/, docs/, tests/, scripts/, config/)
- [ ] Flache vs. verschachtelte Struktur — passt zum Projektumfang?
- [ ] Keine losen Dateien im Root die in Unterordner gehoeren?
- [ ] Temporaere/generierte Dateien nicht im Repo? (dist/, build/, .cache/)
- [ ] Assets/Ressourcen klar getrennt von Code?

### 2. Namenskonventionen

- [ ] Dateinamen konsistent? (kebab-case, camelCase, PascalCase — eines davon)
- [ ] Verzeichnisnamen konsistent?
- [ ] Keine Sonderzeichen, Leerzeichen oder Umlaute in Pfaden?
- [ ] Sprachkonsistenz: Alles Englisch oder alles Deutsch (nicht gemischt)?

### 3. Architektur-Patterns

- [ ] Erkennbares Pattern? (MVC, Layered, Hexagonal, Feature-based, Flat)
- [ ] Passt das Pattern zum Projektumfang? (nicht Over-Engineered, nicht zu chaotisch)
- [ ] Separation of Concerns: Business-Logik getrennt von I/O, UI, Config?
- [ ] Klare Abhaengigkeitsrichtung? (keine zirkulaeren Imports)
- [ ] Einheitliche Abstraktionsebene pro Verzeichnis?

### 4. Coupling & Cohesion

- [ ] Module/Ordner: Hohe Kohaesion innerhalb? (zusammengehoeriges zusammen)
- [ ] Lose Kopplung zwischen Modulen? (klare Interfaces, keine God-Files)
- [ ] Keine God-Dateien mit >500 Zeilen die alles machen?
- [ ] Shared/Common-Ordner: Nicht zur Muellhalde geworden?
- [ ] Zirkulaere Dependencies? (A → B → C → A)

### 5. Config-Dateien

- [ ] package.json / pyproject.toml (falls vorhanden): name, version, description ausgefuellt?
- [ ] Scripts sinnvoll: start, build, test, lint definiert?
- [ ] Engine-Constraints: Node/Python-Version festgelegt?
- [ ] Linter/Formatter-Config vorhanden?
- [ ] .editorconfig: Vorhanden? Konsistente Einstellungen?

### 6. Entry Points

- [ ] Klar definiert wo das Projekt "startet"? (main, bin, index)
- [ ] README beschreibt wie man das Projekt startet?
- [ ] Bei CLI-Tools: `bin` Feld korrekt?
- [ ] Bei Libraries: `exports` / `main` korrekt gesetzt?

### 7. Aufgeraeumt

- [ ] Keine leeren Verzeichnisse?
- [ ] Keine TODO/FIXME/HACK Dateien die vergessen wurden?
- [ ] Keine Duplikate oder Backup-Dateien? (.bak, .old, Copy of...)
- [ ] Keine IDE-spezifischen Dateien im Repo? (.idea/, .vscode/ — ausser gewollt)
- [ ] Keine verwaisten Konfigurationsdateien fuer entfernte Tools?

---

## Ergebnis

Findings als STRUC-01, STRUC-02, ... dokumentieren.
Zirkulaere Dependencies: HIGH. Fehlende Struktur: MEDIUM. Naming-Inkonsistenz: LOW.
