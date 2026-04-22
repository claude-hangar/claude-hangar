---
title: "Obsidian-Setup — {{PROJECT_NAME}}"
type: navigation
stand: {{DATE}}
status: aktiv
tags:
  - typ/navigation
  - typ/anleitung
---

# Obsidian-Setup — {{PROJECT_NAME}}

> Stand: {{DATE}}
> Einstiegsanleitung für den Obsidian-Vault dieses Projekts.

---

## 1. Vault öffnen

Dieses Verzeichnis ist ein Obsidian-Vault-Unterordner. Der Vault-Root liegt eine Ebene höher.

**Beim ersten Start:**
1. Obsidian → **"Open folder as vault"**
2. Ordner: Vault-Root (z.B. `D:\Obsidian-Vault`)
3. Bestätigen. Obsidian erkennt `.obsidian/` und lädt die Konfiguration.

Dashboard: [[Dashboard.md]]

---

## 2. Sync (mobile + desktop)

- Desktop: Einstellungen → Sync → Sign in → Remote Vault wählen
- Mobile: "Sync existing vault"
- Selective Sync: rohe Dateien und Archive bei Bedarf ausschließen

---

## 3. Wichtige Shortcuts

| Shortcut | Aktion |
|----------|--------|
| `Strg+O` | Quick Switcher |
| `Strg+P` | Command Palette |
| `Strg+Shift+F` | Volltextsuche |
| `Strg+Shift+G` | Graph View |
| `Strg+Shift+B` | Backlinks |
| `Strg+Shift+T` | Tag Pane |

---

## 4. Gepflegte Dateien

Diese Datei wird automatisch via `repomind sync` aus dem Quell-Repo hierher kopiert. **Lokale Änderungen im Vault überleben den nächsten Sync nicht** — Änderungen im Repo vornehmen.
