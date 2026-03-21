# Stack-Supplement: SQLite

SQLite-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

---

## §IST-Analyse

- [ ] SQLite-Library: `better-sqlite3` oder `sqlite3`? Version?
- [ ] Datenbank-Datei: Pfad? In Docker-Volume gemountet?
- [ ] Schema: Tabellen, Indizes, Constraints dokumentiert?
- [ ] WAL-Modus: Aktiviert? (`PRAGMA journal_mode=WAL`)
- [ ] Datenbankgroesse: Aktuell? Wachstumsrate?

## §Security

- [ ] **Datei-Berechtigungen:** DB-Datei nur vom App-User lesbar/schreibbar?
- [ ] **SQL Injection:** Prepared Statements? Keine String-Konkatenation mit User-Input!
- [ ] **Backup-Zugang:** DB-Datei nicht oeffentlich erreichbar? (Nicht im Web-Root!)
- [ ] **WAL-Datei:** `-wal` und `-shm` auch geschuetzt?
- [ ] **Input-Validierung:** Laenge, Typ, Format vor DB-Schreibvorgaengen pruefen

## §Performance

- [ ] **WAL-Modus:** Aktiviert fuer bessere Concurrency (`PRAGMA journal_mode=WAL`)
- [ ] **Synchronous:** `PRAGMA synchronous=NORMAL` (statt FULL, fuer WAL-Modus)
- [ ] **Cache-Groesse:** `PRAGMA cache_size` angemessen? (Default oft zu klein)
- [ ] **Indizes:** Auf haeufig abgefragte Spalten? `EXPLAIN QUERY PLAN` pruefen
- [ ] **Busy-Timeout:** `PRAGMA busy_timeout=5000` oder aehnlich gesetzt?
- [ ] **VACUUM:** Regelmaessig oder `auto_vacuum` aktiv?
- [ ] **Connection-Reuse:** Nicht bei jedem Request neue Connection oeffnen

## §Code-Quality

- [ ] **Migrations:** Schema-Aenderungen versioniert? Migrations-System?
- [ ] **Prepared Statements:** Konsistent genutzt? Wiederverwendet?
- [ ] **Error Handling:** SQLITE_BUSY, SQLITE_LOCKED korrekt behandelt?
- [ ] **Transaktionen:** Fuer zusammengehoerige Operationen? Rollback bei Fehler?
- [ ] **Close:** Datenbank bei Shutdown korrekt geschlossen?

## §Infrastruktur

- [ ] **Backup-Strategie:** `sqlite3 .backup` oder File-Copy bei WAL?
- [ ] **Backup-Frequenz:** Automatisiert? Cron-Job oder Application-Level?
- [ ] **Docker-Volume:** DB-Datei auf Named Volume? Nicht im Container-Layer!
- [ ] **Locking:** Bei mehreren Containern auf selbe DB → Locking-Probleme?
- [ ] **Monitoring:** DB-Groesse, WAL-Groesse, Checkpoint-Status?
