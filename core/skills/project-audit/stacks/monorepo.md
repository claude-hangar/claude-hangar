# Stack-Supplement: Monorepo

Monorepo-spezifische Projekt-Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.
Erkennung: `workspaces` in package.json oder `pnpm-workspace.yaml` vorhanden.

---

## §Struktur

- [ ] Workspace-Konfiguration: `pnpm-workspace.yaml`, `package.json.workspaces`?
- [ ] Package-Struktur: `packages/`, `apps/`, `libs/`? Konvention klar?
- [ ] Shared-Code: In eigenem Package? (nicht Copy-Paste zwischen Workspaces)
- [ ] Root vs. Package: Was lebt im Root, was in Packages?
- [ ] Package-Naming: `@scope/package` Konvention? Konsistent?
- [ ] Abhaengigkeiten zwischen Packages: Klar definiert?

## §Dependencies

- [ ] Hoisting: Phantom Dependencies durch Hoisting? (`pnpm` strict am sichersten)
- [ ] Shared Dependencies: Gleiche Versionen ueberall? (pnpm catalog)
- [ ] Root-Dependencies: Nur Dev-Tools (lint, build), keine Runtime-Deps?
- [ ] Workspace-Protocol: `workspace:*` statt feste Versionen?
- [ ] Peer Dependencies: Korrekt zwischen Packages deklariert?
- [ ] Lock-File: Ein einziges fuer alle Packages?
- [ ] `npm audit` / `pnpm audit`: Gilt fuer alle Packages?

## §Code

- [ ] Shared Types: In eigenem Package? (nicht dupliziert)
- [ ] Cross-Package Imports: Ueber Package-Name, nicht relative Pfade?
- [ ] Circular Dependencies: Keine zirkulaeren Abhaengigkeiten zwischen Packages?
- [ ] Consistent Patterns: Gleicher Code-Stil in allen Packages?
- [ ] Shared Config: ESLint, TypeScript Config geshared? (extends)

## §Git

- [ ] Single Repo: Ein `.git/`, nicht verschachtelte Repos?
- [ ] `.gitignore`: Alle Package-spezifischen Ignores abgedeckt?
- [ ] Commit-Scope: Conventional Commits mit Scope? (`feat(api): ...`)
- [ ] PR-Groesse: Nicht zu gross durch Multi-Package Changes?
- [ ] CODEOWNERS: Pro Package/Verzeichnis definiert?

## §CICD

- [ ] Affected Packages: Nur geaenderte Packages bauen/testen? (nx, turbo)
- [ ] Pipeline-Caching: Pro Package gecacht?
- [ ] Build-Order: Dependency-Graph beruecksichtigt?
- [ ] Independent Releases: Package-weise oder zusammen?
- [ ] Changesets / Release-Please: Fuer Multi-Package Releases?
- [ ] Matrix-Build: Jedes Package als separater Job?

## §Dokumentation

- [ ] Root-README: Uebersicht aller Packages mit Links?
- [ ] Package-README: Jedes Package hat eigene Doku?
- [ ] Getting Started: Wie startet man das Monorepo?
- [ ] Architecture: Package-Abhaengigkeitsgraph dokumentiert?
- [ ] Contributing: Wie fuegt man ein neues Package hinzu?

## §Testing

- [ ] Test-Runner: Monorepo-aware? (turbo test, nx test)
- [ ] Package-uebergreifende Tests: Integration zwischen Packages?
- [ ] Coverage: Pro Package oder gesamt?
- [ ] Test-Isolation: Packages unabhaengig testbar?
- [ ] Shared Test-Utils: In eigenem Package?

## §Security

- [ ] Permissions: Nicht alle Contributors auf alle Packages Zugriff?
- [ ] Secrets: Pro Package/App unterschiedliche Secrets?
- [ ] Dependency-Audit: Gilt fuer alle Packages?
- [ ] Internal Packages: Nicht versehentlich publiziert? (`private: true`)

## §Deployment

- [ ] Independent Deploys: Packages unabhaengig deploybar?
- [ ] Build-Artifacts: Nur betroffene Packages deployed?
- [ ] Environment-Trennung: Pro App/Service separate Envs?
- [ ] Docker: Separate Dockerfiles pro Service? Context korrekt?
- [ ] Selective Builds: Nicht alles bei jedem Change rebuilden?

## §Maintenance

- [ ] Tool-Version: Turborepo, Nx, Lerna aktuell?
- [ ] Workspace-Protokoll: `workspace:*` vs. feste Versionen?
- [ ] Dead Packages: Ungenutzte Packages aufraeuemen?
- [ ] Dependency-Graph: Regelmaessig prufen? (`pnpm why`, `nx graph`)
- [ ] Migration: Von Lerna zu Turborepo/Nx? Tool-Wechsel geplant?
