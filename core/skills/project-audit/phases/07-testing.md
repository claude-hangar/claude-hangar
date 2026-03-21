# Phase 07: Testing & QA

Test-Pyramide, Coverage-Strategie, E2E, Mutation Testing, Qualitaetssicherung.
Finding-Prefix: `TEST`

---

## Checks

### 1. Test-Framework

- [ ] Tests vorhanden? Welches Framework? (Vitest, Jest, Playwright, pytest, bats, etc.)
- [ ] Test-Verzeichnis: Klar strukturiert? (tests/, __tests__, *.test.*, *.spec.*)
- [ ] Tests lauffaehig? Alle gruen?
- [ ] Test-Daten: Keine produktiven Credentials oder echte Daten in Tests?
- [ ] Test-Isolation: Tests unabhaengig voneinander? Keine Reihenfolge-Abhaengigkeit?

### 2. Test-Pyramide

- [ ] **Unit Tests:** Einzelne Funktionen/Module getestet?
- [ ] **Integration Tests:** Komponenten-Zusammenspiel getestet?
- [ ] **E2E Tests:** Kritische User-Flows abgedeckt?
- [ ] Balance: Mehr Unit als Integration, mehr Integration als E2E?
- [ ] Keine Test-Pyramide-Inversion? (zu viele E2E, zu wenige Unit)

### 3. Coverage-Strategie

- [ ] Coverage-Report verfuegbar? Wie hoch?
- [ ] Kritische Pfade getestet? (Hauptfunktionalitaet, Error-Handling)
- [ ] Coverage-Schwelle definiert? (in CI blockierend)
- [ ] Untestete Bereiche: Bewusst ausgelassen oder vergessen?
- [ ] Coverage-Trends: Steigt oder sinkt Coverage ueber Zeit?

### 4. Edge Cases & Error Handling

- [ ] Edge Cases: Leere Eingaben, Null/Undefined, Grenzwerte?
- [ ] Error-Pfade getestet? (Netzwerk-Fehler, Timeout, ungueltige Daten)
- [ ] Negative Tests: Was passiert bei falscher Nutzung?
- [ ] Concurrency: Race Conditions getestet? (falls relevant)

### 5. E2E & Visual Testing

- [ ] E2E-Framework: Playwright, Cypress, Selenium?
- [ ] Kritische Flows: Login, Registrierung, Hauptfunktion?
- [ ] Visual Regression: Screenshot-Vergleich?
- [ ] Cross-Browser: Mehrere Browser getestet?
- [ ] Mobile: Responsive Tests?

### 6. Performance & Load Testing

- [ ] Performance-Tests vorhanden? (k6, Artillery, Locust)
- [ ] Benchmarks: Kritische Operationen gemessen?
- [ ] Regressions-Erkennung: Performance-Budgets definiert?

### 7. Test-Hygiene

- [ ] Flaky Tests: Instabile Tests identifiziert und markiert?
- [ ] Test-Speed: Gesamte Suite <5 Min? (sonst parallelisieren)
- [ ] Mocking: Externe Services gemockt? (keine echten API-Calls)
- [ ] Fixtures: Wiederverwendbare Test-Daten?
- [ ] Test-Namenskonventionen: Beschreibend? ("should X when Y")

---

## Ergebnis

Findings als TEST-01, TEST-02, ... dokumentieren.
Keine Tests fuer kritische Pfade: HIGH. Fehlender Linter: MEDIUM. Keine E2E: MEDIUM.
