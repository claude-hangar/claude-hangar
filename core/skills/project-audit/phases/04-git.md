# Phase 04: Git & Versionierung

Git-Hygiene, Branching, History, Tags, .gitignore.
Finding-Prefix: `GIT`

---

## Checks

### 1. .gitignore

- [ ] Vorhanden und vollstaendig?
- [ ] Build-Artefakte: node_modules, dist/, build/, .cache/, __pycache__/?
- [ ] Environment: .env, .env.local, .env.production?
- [ ] OS-Dateien: .DS_Store, Thumbs.db, Desktop.ini?
- [ ] IDE-Dateien: .idea/, *.swp (wenn nicht gewollt)?
- [ ] Secrets: Keine .env, *.pem, *.key, credentials.* im Repo?
- [ ] Projekt-spezifisch: Lock-Files die nicht committet werden sollen?

### 2. Commit-Historie

- [ ] Sinnvolle Commit-Messages? (nicht "fix", "update", "asdf", "wip")
- [ ] Conventional Commits? (feat:, fix:, docs:, chore:, refactor:)
- [ ] Keine mega-grossen Commits (1000+ Zeilen ohne Grund)?
- [ ] Keine versehentlich committeten Binaries/Bilder?
- [ ] Keine Merge-Commits die Rebase vermieden haetten?
- [ ] Commit-Granularitaet: Logische Einheiten, nicht End-of-Day Dumps?

### 3. Branch-Strategie

- [ ] Haupt-Branch klar? (main oder master)
- [ ] Branch-Protection auf Haupt-Branch? (keine Force-Pushes, PR-Review)
- [ ] Stale Branches: Alte Feature-Branches die aufgeraeumt werden sollten?
- [ ] Branch-Naming: Konsistent? (feature/, fix/, chore/)
- [ ] Merge-Strategie: Squash, Merge, Rebase — dokumentiert?

### 4. Tags & Releases

- [ ] Tags/Releases vorhanden? Versionierung sinnvoll? (SemVer?)
- [ ] Releases mit Changelog/Release-Notes?
- [ ] Tags signiert? (bei oeffentlichen Projekten)
- [ ] Konsistenz: Jede relevante Version getaggt?

### 5. Repository-Groesse

- [ ] Repo-Groesse angemessen? (`git count-objects -vH`)
- [ ] Keine grossen Binaerdateien in der Historie?
- [ ] `.gitattributes`: LFS fuer grosse Dateien konfiguriert?
- [ ] Shallow-Clone freundlich? (fuer CI)

### 6. Pre-Commit

- [ ] Pre-Commit Hooks: Vorhanden? (husky, lint-staged, lefthook, pre-commit)
- [ ] Was laufen sie? (Lint, Format, Test?)
- [ ] Nicht zu langsam? (>10s frustriert Entwickler)
- [ ] Bypass-Schutz: `--no-verify` in Doku erwaehnt?

---

## Ergebnis

Findings als GIT-01, GIT-02, ... dokumentieren.
Secrets in Git-Historie: CRITICAL. Fehlende .gitignore: HIGH. Stale Branches: LOW.
