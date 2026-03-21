# Phase 10: Maintenance & Hygiene

Tech Debt, Cleanup, Lifecycle, Deprecations, Changelog-Pflege.
Finding-Prefix: `MAINT`

---

## Checks

### 1. Tech Debt

- [ ] Bekannte Tech-Debt dokumentiert? (TODO.md, Issues, Kommentare)
- [ ] Tech-Debt-Budget: Wird regelmaessig aufgeraeumt?
- [ ] Veraltete Patterns: Code der "schon immer so war" aber besser geht?
- [ ] Workarounds: Temporaere Fixes die permanent wurden?
- [ ] Migration-Backlog: Anstehende Upgrades/Migrationen?

### 2. Cleanup & Hygiene

- [ ] Ungenutzte Dateien: Alte Configs, leere Ordner, orphaned Assets?
- [ ] Ungenutzte Dependencies: Pakete die niemand mehr importiert?
- [ ] Stale Code: Features die nie gelauncht wurden?
- [ ] Kommentar-Hygiene: Veraltete Kommentare, falsche Beschreibungen?
- [ ] Konsistenz: Verschiedene Patterns fuer dasselbe Problem?

### 3. Lifecycle-Management

- [ ] Node.js/Python/Runtime: Auf LTS? EOL-Datum bekannt?
- [ ] Frameworks: Auf aktuellem Major? Naechstes Major-Upgrade geplant?
- [ ] OS auf Servern: Aktuell? Sicherheits-Updates?
- [ ] SSL-Zertifikate: Ablaufdatum bekannt? Auto-Renewal?
- [ ] Domain-Registrierung: Ablaufdatum bekannt?

### 4. Deprecations

- [ ] Deprecated APIs im eigenen Code markiert? (@deprecated, JSDoc)
- [ ] Deprecated Dependencies: Migration zu Nachfolgern geplant?
- [ ] Deprecated Features: User informiert?
- [ ] Breaking Changes: Migrations-Guide vorhanden?

### 5. Changelog & Release-Prozess

- [ ] CHANGELOG.md gepflegt?
- [ ] Releases regelmaessig? (nicht alles auf einem Haufen)
- [ ] Release-Notes aussagekraeftig?
- [ ] SemVer korrekt angewendet? (Breaking = Major, Feature = Minor, Fix = Patch)
- [ ] Automatische Changelog-Generierung? (conventional-changelog, release-please)

### 6. Automatisierung

- [ ] Repetitive Tasks automatisiert? (keine manuellen Schritte die vergessen werden)
- [ ] Dependency-Updates automatisiert? (Dependabot, Renovate)
- [ ] Cleanup-Scripts: Alte Artefakte, Logs, Temp-Dateien?
- [ ] Scheduled Tasks: Cron-Jobs dokumentiert und ueberwacht?

### 7. Projekt-Gesundheit

- [ ] Commit-Frequenz: Aktiv gepflegt oder verwaist?
- [ ] Issue-Backlog: Ueberschaubar oder Muellhalde?
- [ ] Bus-Factor: Mehr als eine Person kennt den Code?
- [ ] Archivierung: Sollte das Projekt archiviert werden?

---

## Ergebnis

Findings als MAINT-01, MAINT-02, ... dokumentieren.
EOL Runtime: HIGH. Undokumentierte Tech-Debt: MEDIUM. Fehlender Changelog: LOW.
