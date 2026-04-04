# Design Intelligence + Skill Infrastructure — Phase 1 Spec

**Date:** 2026-04-04
**Status:** Approved
**Scope:** Phase 1 of 2

## Summary

Upgrade Claude Hangar's `design-system` skill from a static Markdown reference to a tiered design intelligence system. Add machine-readable skill manifests (`skill.json`) and a central skills index (`skills_index.json`).

## Goals

1. **Design-Intelligence:** Transform `design-system` into a context-aware design advisor with curated CSV databases for styles, palettes, typography, UX rules, and wow effects
2. **skill.json:** Add machine-readable manifests to every skill in `core/skills/`
3. **skills_index.json:** Create a central index of all skills with category, risk level, and triggers

## Non-Goals (Phase 2)

- Instinct extraction hook
- Risk-level system in SKILL.md frontmatter
- AgentShield security scanning
- Tiered memory retrieval
- Selective install manifests in setup.sh

---

## Architecture

### Tiered Hybrid Approach

```
Tier 1: SKILL.md (Quick Reference)
  - Inline tables for the 80% case
  - Spacing scale, 12 industry palettes, 10 font pairings
  - Component patterns, 9 wow techniques
  - Decision tree for when to use Tier 2

Tier 2: CSV Data Layer (Deep Lookup)
  - ~50 UI styles, ~80 palettes, ~35 font pairings
  - ~70 UX rules, ~25 wow effects
  - Claude reads CSVs directly via Read tool
  - No external search script — Claude IS the search engine
```

### Key Design Decision: No Search Script

Unlike UI UX Pro Max (Python BM25), we use Claude's native intelligence as the search engine. Claude reads structured CSVs and extracts what it needs based on context. This means:

- Zero runtime dependencies
- Cross-platform (Linux + Git Bash on Windows)
- No script maintenance
- Leverages Claude's semantic understanding (better than keyword matching)

---

## File Structure

```
core/skills/design-system/
├── SKILL.md              # Workflow + Quick Reference (rewritten)
├── skill.json            # Machine-readable manifest
└── data/
    ├── styles.csv        # ~50 UI styles
    ├── palettes.csv      # ~80 color palettes (by industry + mood)
    ├── typography.csv    # ~35 font pairings (GDPR-ready)
    ├── ux-rules.csv      # ~70 UX rules (prioritized 1-10)
    └── wow-effects.csv   # ~25 wow techniques (with perf impact)

skills_index.json         # Central index at repo root
```

---

## Component 1: Design-Intelligence

### SKILL.md Workflow

The SKILL.md serves two roles:

**Role 1 — Quick Reference (inline tables)**
Kept from current version: spacing scale, 12 industry palettes, 10 font pairings, component patterns, wow techniques. These handle the most common design decisions without touching CSVs.

**Role 2 — Smart Router (decision tree)**
New addition: a context detection and decision tree that tells Claude WHEN and WHICH CSV to read.

#### Context Detection Steps

1. Read `package.json` → detect stack (Astro, SvelteKit, Next.js)
2. Read `src/config/site.ts` or similar → detect industry, brand mood
3. Check `design-system/MASTER.md` → project-specific overrides (highest priority)
4. Check existing Tailwind/CSS config → current design tokens

#### Decision Tree

```
Standard industry (in inline table)?
├── YES → use inline palette, done
└── NO → Read data/palettes.csv, find matching entries

Unusual style combination requested?
└── Read data/styles.csv → find compatible styles + palette pairings

Font recommendation beyond standard 10?
└── Read data/typography.csv → filter by mood/industry

UX optimization needed?
└── Read data/ux-rules.csv → filter by category (nav, cta, forms, etc.)

Wow effect requested?
└── Read data/wow-effects.csv → filter by performance budget
```

#### MASTER.md Override Rule

If `design-system/MASTER.md` exists in the project, its values ALWAYS take precedence over CSV recommendations. The CSV data informs suggestions, but MASTER.md is the source of truth for active projects.

### CSV Schemas

#### styles.csv (~50 entries)

| Column | Type | Description |
|--------|------|-------------|
| id | string | Unique identifier (kebab-case) |
| name | string | Human-readable name |
| description | string | One-line description |
| mood_tags | string | Semicolon-separated mood tags |
| best_for | string | Industries/contexts where this works |
| tailwind_essence | string | Key Tailwind classes that define this style |
| pair_with_palettes | string | Palette IDs that work well with this style |
| avoid_when | string | When NOT to use this style |

Categories to cover: Glass effects, Material styles, Retro/vintage, Organic/natural, Corporate, Creative/artistic, Dark modes, Light/airy, Dense/data-heavy, Playful/fun.

#### palettes.csv (~80 entries)

| Column | Type | Description |
|--------|------|-------------|
| id | string | Unique identifier |
| name | string | Human-readable name |
| industry | string | Primary industry |
| mood | string | Semicolon-separated mood tags |
| primary | string | Hex color |
| secondary | string | Hex color |
| accent | string | Hex color |
| cta | string | Hex color for call-to-action |
| background | string | Hex color |
| surface | string | Hex color for cards/panels |
| text | string | Hex color for body text |
| muted | string | Hex color for secondary text |

Coverage: Multiple palettes per industry (calm, bold, modern variants). Plus mood-based palettes not tied to specific industries (dark-elegant, warm-organic, tech-neon, etc.).

#### typography.csv (~35 entries)

| Column | Type | Description |
|--------|------|-------------|
| id | string | Unique identifier |
| name | string | Human-readable name |
| heading | string | Heading font family |
| body | string | Body font family |
| style | string | Pairing style (serif-sans, mono-sans, etc.) |
| mood | string | Semicolon-separated mood tags |
| best_for | string | Industries/contexts |
| weights | string | Required font weights |
| gdpr_note | string | Self-hosting reminder |

All pairings must be Google Fonts available, with self-hosting note for GDPR compliance.

#### ux-rules.csv (~70 entries)

| Column | Type | Description |
|--------|------|-------------|
| id | string | Unique identifier (category-number) |
| category | string | Rule category |
| rule | string | The rule statement |
| priority | integer | 1-10 (10 = most critical) |
| description | string | Why this rule matters |
| applies_to | string | Page types or contexts |
| check_method | string | How to verify compliance |

Categories: navigation, conversion, forms, content, accessibility, mobile, trust, performance, layout, interaction.

#### wow-effects.csv (~25 entries)

| Column | Type | Description |
|--------|------|-------------|
| id | string | Unique identifier |
| name | string | Human-readable name |
| category | string | Effect category (typography, animation, layout, visual) |
| description | string | What it does |
| tailwind_css | string | Implementation (Tailwind classes or CSS) |
| perf_impact | string | none, low, medium, high |
| complexity | string | low, medium, high |
| best_for | string | Where this effect works best |

---

## Component 2: skill.json Manifest

Every skill in `core/skills/` gets a `skill.json` with this schema:

```json
{
  "name": "string — skill identifier (matches directory name)",
  "version": "string — semver",
  "description": "string — one-line description",
  "category": "string — one of: design, quality, audit, performance, security, workflow, documentation, git",
  "risk": "string — one of: safe, moderate, critical",
  "triggers": ["array of trigger keywords"],
  "platforms": { "claude-code": "supported" },
  "dependencies": ["array of other skill IDs this depends on"],
  "dataFiles": ["array of data file paths relative to skill directory"]
}
```

### Skills to Manifest

All skills in `core/skills/`: adversarial-review, audit, audit-orchestrator, audit-runner, capture-pdf, codebase-map, consult, deploy-check, design-system, doctor, error-analyzer, favicon-check, freshness-check, git-hygiene, handoff, inline-review, lesson-learned, lighthouse-quick, meta-tags, polish, project-audit.

---

## Component 3: skills_index.json

Central index at repo root. Generated from individual skill.json files but committed to git (not auto-generated at runtime).

```json
{
  "$schema": "skills_index.schema.json",
  "version": "1.0",
  "generated": "2026-04-04",
  "skillCount": 21,
  "categories": {
    "design": ["design-system", "polish"],
    "quality": ["adversarial-review", "inline-review"],
    "audit": ["audit", "audit-orchestrator", "audit-runner", "project-audit"],
    "performance": ["lighthouse-quick"],
    "security": ["deploy-check"],
    "workflow": ["capture-pdf", "codebase-map", "consult", "handoff", "lesson-learned"],
    "documentation": ["doctor", "error-analyzer", "meta-tags", "favicon-check"],
    "git": ["git-hygiene"],
    "devops": ["freshness-check"]
  },
  "skills": [
    {
      "id": "design-system",
      "path": "core/skills/design-system",
      "category": "design",
      "risk": "safe",
      "description": "Context-aware design intelligence with curated databases",
      "triggers": ["design", "colors", "typography", "palette", "ui", "component", "style"]
    }
  ]
}
```

---

## Integration Points

### With polish skill
No changes needed. Polish already references `/design-system` for industry palettes and design rules. The upgraded skill remains backward-compatible.

### With stacks (Astro, SvelteKit)
Design-system provides design DECISIONS (colors, fonts, styles). Stacks provide CODE PATTERNS (Astro components, Svelte syntax). No overlap — they complement each other.

### With MASTER.md persistence
Unchanged. Project-specific `design-system/MASTER.md` overrides CSV recommendations. The CSV data helps CREATE the initial MASTER.md for a new project.

### With registry
`skills_index.json` can be referenced by the registry's `skills` array for selective deployment.

---

## Data Quality Standards

- Every palette must pass WCAG AA contrast (4.5:1 text on background)
- Every font pairing must be available on Google Fonts and self-hostable
- Every UX rule must cite a principle or research basis
- Every wow effect must include performance impact assessment
- No duplicate or near-duplicate entries
- Semicolons as list separators within CSV fields (not commas)

---

## Implementation Order

1. Create `data/` directory and all 5 CSV files with curated data
2. Rewrite `SKILL.md` with tiered workflow + decision tree
3. Create `skill.json` for design-system
4. Create `skill.json` for all other skills in core/skills/
5. Create `skills_index.json` at repo root
6. Update tests if applicable
7. Commit with conventional commit message
