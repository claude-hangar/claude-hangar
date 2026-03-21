# Stack-Supplement: Shell/Bash

Shell-spezifische Projekt-Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.
Erkennung: Mehrheit `*.sh` Dateien, kein `package.json`.

---

## §Struktur

- [ ] Scripts-Ordner: Logisch gruppiert? (scripts/, bin/, lib/)
- [ ] Shebang: `#!/usr/bin/env bash` (nicht `#!/bin/bash` fuer Portabilitaet)
- [ ] Namenskonvention: `kebab-case.sh` oder `snake_case.sh`? Konsistent?
- [ ] Executable-Bit: Auf allen Scripts gesetzt?
- [ ] Gemeinsame Funktionen: In `lib/` oder `common.sh` ausgelagert?

## §Dependencies

- [ ] Externe Tools dokumentiert? (jq, curl, age, ssh, etc.)
- [ ] Version-Checks: Scripts pruefen ob benoetigte Tools installiert sind?
- [ ] Cross-Platform: Linux + macOS + Git Bash kompatibel?
- [ ] Keine Abhaengigkeit von nicht-Standard-Tools ohne Fallback?
- [ ] Docker-Tools: docker, docker-compose Version geprueft?

## §Code

- [ ] `set -euo pipefail`: Am Anfang jedes Scripts?
- [ ] `shellcheck`: Null Fehler? (`shellcheck *.sh`)
- [ ] Quoting: Alle Variablen in Quotes? (`"$var"` nicht `$var`)
- [ ] Funktionen: Wiederverwendbare Logik in Funktionen extrahiert?
- [ ] Lokale Variablen: `local` in Funktionen?
- [ ] Error-Handling: Sinnvolle Exit-Codes? (0 OK, 1 Fehler, 2 Usage)
- [ ] Keine `eval` oder `source` von untrusted Input?
- [ ] Temp-Dateien: `mktemp` + Cleanup via `trap`?

## §Git

- [ ] `.gitignore`: `*.log`, `*.tmp`, Output-Dateien?
- [ ] Executable-Bit korrekt im Git? (`git ls-files --stage`)
- [ ] Keine Secrets in Scripts? (Passwords, Tokens)

## §CICD

- [ ] `shellcheck` in CI integriert?
- [ ] `shfmt` fuer konsistente Formatierung?
- [ ] Matrix: Verschiedene Shells getestet? (bash 4, bash 5, zsh)
- [ ] BATS oder shunit2 fuer automatisierte Tests?

## §Dokumentation

- [ ] Usage-Message: `--help` Flag in jedem Script?
- [ ] Header-Kommentar: Zweck, Parameter, Beispiele?
- [ ] README: Alle Scripts aufgelistet mit Kurzbeschreibung?
- [ ] Parameter dokumentiert: Pflicht vs. Optional?

## §Testing

- [ ] Test-Framework: BATS, shunit2, bats-core?
- [ ] Kritische Scripts getestet?
- [ ] Mocking: Externe Commands gemockt fuer Tests?
- [ ] `shellcheck` als Lint-Step?
- [ ] Edge Cases: Leere Eingaben, Leerzeichen in Pfaden, fehlende Dateien?

## §Security

- [ ] Keine `eval` oder `source` von User-Input?
- [ ] `trap` fuer Cleanup von Temp-Dateien und Secrets?
- [ ] Permissions: Sensitive Dateien mit `chmod 600`?
- [ ] SSH-Keys: Korrekte Permissions? Nicht world-readable?
- [ ] Keine Passwoerter in Kommandozeilen-Argumenten? (in `ps` sichtbar)
- [ ] `curl`: HTTPS? Certificate-Verify nicht deaktiviert?

## §Deployment

- [ ] Install-Script: `bash setup.sh` oder `make install`?
- [ ] Idempotent: Script kann mehrfach laufen ohne Schaden?
- [ ] Pfade: Keine hardcodierten absoluten Pfade?
- [ ] Cron-Jobs: Logging? Lock-File gegen Parallelausfuehrung?
- [ ] Systemd-Timer: Bevorzugt gegenueber Cron?

## §Maintenance

- [ ] Bash-Version: Minimum-Version dokumentiert?
- [ ] Deprecated Features: Backticks statt `$()`, `-a`/`-o` statt `&&`/`||`?
- [ ] Tool-Updates: Externe Tools auf aktuellem Stand?
- [ ] Cleanup: Alte Scripts die nicht mehr genutzt werden?
