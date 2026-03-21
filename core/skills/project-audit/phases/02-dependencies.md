# Phase 02: Dependencies & Ecosystem

Pakete, Versionen, Ecosystem Health, Alternativen, Lizenz-Audit.
Finding-Prefix: `DEP`

---

## Checks

### 1. Package Manager

- [ ] Welcher? (npm, pnpm, yarn, bun, pip, poetry) — konsistent genutzt?
- [ ] Lock-File vorhanden UND committet?
- [ ] Keine mehreren Lock-Files? (z.B. package-lock.json UND yarn.lock)
- [ ] Packagemanager-Version festgelegt? (corepack, .npmrc, .python-version)

### 2. Dependencies

- [ ] Alle Dependencies tatsaechlich genutzt? Keine Waisen?
- [ ] Dev vs. Prod korrekt aufgeteilt? (devDependencies vs. dependencies)
- [ ] Keine doppelten/ueberlappenden Pakete? (moment + dayjs, lodash + underscore)
- [ ] Keine ueberdimensionierten Dependencies fuer kleine Aufgaben?
- [ ] Pinning-Strategie: Exact, Caret, Tilde? Konsistent?

### 3. Versionen

- [ ] `npm outdated` / `pip list --outdated`: Wie viele veraltete Pakete?
- [ ] Major-Updates: Breaking Changes bekannt? Migration noetig?
- [ ] Runtime-Version: Node.js/Python in .nvmrc/.node-version/.python-version definiert?
- [ ] Runtime aktuell? LTS-Version? End-of-Life pruefen!
- [ ] Peer Dependencies: Konflikte?

### 4. Vulnerabilities

- [ ] `npm audit` / `pip audit`: CRITICAL oder HIGH Vulnerabilities?
- [ ] Behebbare Vulnerabilities: Fix moeglich?
- [ ] Nicht-behebbare: Workaround oder Alternative?
- [ ] Bekannte CVEs in direkten Dependencies?

### 5. Ecosystem Health

- [ ] Aktive Maintainer? Letzte Release wann? (>1 Jahr = Warnung)
- [ ] Download-Zahlen: Populaer oder Nischen-Paket?
- [ ] Offene Issues: Viele unbearbeitete Bugs?
- [ ] Alternativen: Gibt es besser gepflegte Pakete fuer denselben Zweck?
- [ ] Deprecated Pakete: Empfohlene Nachfolger?

### 6. Lizenz-Audit

- [ ] Alle Dependencies haben kompatible Lizenzen?
- [ ] Keine GPL-Pakete in proprietaeren Projekten?
- [ ] SBOM (Software Bill of Materials): Generierbar?
- [ ] Lizenz-Feld im eigenen Projekt gesetzt?

### 7. Lock-File Hygiene

- [ ] Lock-File aktuell? (Install erzeugt keinen Diff?)
- [ ] Keine Konflikte im Lock-File?
- [ ] Integritaets-Hashes vorhanden?

---

## Ergebnis

Findings als DEP-01, DEP-02, ... dokumentieren.
CVE in Dependencies: HIGH. Veraltete Major-Version: MEDIUM. Deprecated Pakete: LOW.
