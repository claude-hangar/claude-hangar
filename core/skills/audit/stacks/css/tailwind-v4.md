# Stack-Supplement: Tailwind CSS v4

Tailwind v4-spezifische Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.

---

## §IST-Analyse

- [ ] Tailwind-Version: package.json pruefen (v4.x bestaetigen)
- [ ] Config-Format: `@import "tailwindcss"` in CSS (nicht tailwind.config.js — v4 Migration)?
- [ ] `@theme` Block: Custom Properties definiert? (Farben, Spacing, Fonts)
- [ ] `@reference` Direktive: In Komponenten-Dateien genutzt?
- [ ] PostCSS oder Lightning CSS? (v4 nutzt Lightning CSS nativ)
- [ ] Alte Config: `tailwind.config.js` noch vorhanden? → Migrationsbedarf

## §Performance

- [ ] CSS-Bundle-Groesse: Wie gross ist das generierte CSS?
- [ ] Unused CSS: Tailwind v4 entfernt automatisch — aber custom CSS pruefen
- [ ] `@layer` korrekt genutzt? (base, components, utilities)
- [ ] Keine duplizierten Utility-Klassen in Templates?
- [ ] Dark Mode: Implementierung effizient? (`dark:` Variante oder CSS-Variable?)

## §Accessibility

- [ ] `sr-only` Utility korrekt genutzt fuer Screen-Reader-Texte?
- [ ] Focus-Styles: `focus-visible:` statt `focus:` fuer Keyboard-Only?
- [ ] Kontrast: Custom-Farben in `@theme` — alle Kombinationen pruefen
- [ ] Responsive: Breakpoints sinnvoll? Keine Content-Versteckung per `hidden`?
- [ ] Motion: `motion-safe:` / `motion-reduce:` fuer Animationen?

## §Code-Quality

- [ ] Konsistente Utility-Nutzung: Keine Mix aus Tailwind + Inline-Styles?
- [ ] `@apply` nur in Ausnahmefaellen? (lieber Utilities direkt)
- [ ] Custom Properties in `@theme`: Sinnvoll benannt? (--color-primary etc.)
- [ ] Responsive Design: Mobile-First Ansatz? (sm/md/lg konsistent)
- [ ] Komponenten-Extraktion: Wiederkehrende Utility-Kombinationen als Klasse?
- [ ] Keine veralteten v3-Syntax (`bg-opacity-50` → `bg-black/50` in v4)?
