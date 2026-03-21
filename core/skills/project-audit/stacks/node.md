# Stack-Supplement: Node.js

Node.js-spezifische Projekt-Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.
Erkennung: `package.json` vorhanden.

---

## §Struktur

- [ ] `src/` vs. Root: Code in src/ oder direkt im Root? Konsistent?
- [ ] `dist/` / `build/`: In .gitignore? Nicht committet?
- [ ] `types/` oder `@types/`: Eigene Type-Definitionen strukturiert?
- [ ] `scripts/`: Build/Deploy-Scripts getrennt von Source?
- [ ] package.json: `name`, `version`, `description`, `license`, `engines` ausgefuellt?
- [ ] `exports` / `main` / `types` Felder korrekt? (ESM vs. CJS)
- [ ] `files` Feld: Nur noetige Dateien im publizierten Paket?

## §Dependencies

- [ ] `npm outdated` / `pnpm outdated`: Veraltete Pakete?
- [ ] `npm audit`: CVEs? (`npm audit --audit-level=high`)
- [ ] `engines.node`: Definiert? Passt zur LTS-Version?
- [ ] `packageManager` Feld: Corepack-kompatibel?
- [ ] `peerDependencies`: Korrekt deklariert? (bei Libraries)
- [ ] `overrides` / `resolutions`: Workarounds dokumentiert?
- [ ] Bundle-Groesse: `bundlephobia` fuer kritische Pakete pruefen?
- [ ] Node.js-Version: `.nvmrc` oder `.node-version` vorhanden?

## §Code

- [ ] ESM vs. CJS: `"type": "module"` in package.json? Konsistent?
- [ ] Import-Stil: Named Imports statt default wo moeglich?
- [ ] Async/Await: Keine unbehandelten Promise-Rejections?
- [ ] `process.exit()`: Nur in CLI-Entry-Points, nicht in Libraries?
- [ ] Buffer/Stream: Korrekte Verwendung? Keine Memory-Leaks?
- [ ] Error-Handling: Custom Error Classes? Error Codes?

## §Git

- [ ] `.gitignore`: `node_modules/`, `dist/`, `.env`, `*.tsbuildinfo`?
- [ ] Lock-File: Committet? Keine Merge-Konflikte?
- [ ] `.npmignore` oder `files` Feld: Unnoetige Dateien nicht im Paket?

## §CICD

- [ ] Node-Version in CI: Matrix-Build? LTS + Current?
- [ ] `npm ci` statt `npm install` in CI?
- [ ] Cache: `node_modules` oder `~/.npm` gecacht?
- [ ] `npm publish`: Automated Release? (semantic-release, changesets)
- [ ] `npm pack --dry-run`: Package-Inhalt geprueft?

## §Dokumentation

- [ ] `npm run` Scripts dokumentiert? (in README oder package.json `description`)
- [ ] JSDoc/TSDoc fuer exportierte APIs?
- [ ] Examples: Nutzungsbeispiele im README oder examples/?
- [ ] Typedoc / API-Reference generiert?

## §Testing

- [ ] Test-Framework: Vitest, Jest, Node Test Runner?
- [ ] `npm test` konfiguriert und lauffaehig?
- [ ] Coverage: `c8` oder Vitest-Coverage konfiguriert?
- [ ] Type-Check: `tsc --noEmit` in CI?
- [ ] Lint: ESLint oder Biome konfiguriert?

## §Security

- [ ] `npm audit`: Null CRITICAL/HIGH?
- [ ] `process.env`: Keine Secrets hardcodiert?
- [ ] `eval()`, `Function()`: Nicht verwendet?
- [ ] `child_process.exec()`: Shell-Injection vermieden? (`execFile` bevorzugen)
- [ ] `__dirname` / `import.meta.url`: Pfad-Traversal sicher?
- [ ] Rate Limiting: Bei Express/Fastify-APIs?
- [ ] Helmet/CORS: Sicherheits-Middleware konfiguriert?

## §Deployment

- [ ] `NODE_ENV=production`: Gesetzt in Prod?
- [ ] `npm prune --production`: Dev-Dependencies entfernt?
- [ ] PM2 / systemd: Prozess-Management fuer Server-Apps?
- [ ] Graceful Shutdown: SIGTERM-Handler? (Verbindungen sauber schliessen)
- [ ] Docker: Node-User statt Root? Signal-Forwarding (`--init`)?

## §Maintenance

- [ ] Node.js LTS-Schedule: Naechstes EOL bekannt?
- [ ] Deprecated Node APIs: `url.parse()`, `fs.exists()` etc.?
- [ ] Package-Lock Drift: `npm ci` schlaegt fehl?
- [ ] Dependabot/Renovate: Auto-Updates konfiguriert?
- [ ] Major-Framework-Upgrades: Geplant? Migrationsaufwand geschaetzt?
