---
name: design-system
description: >
  Context-aware design intelligence with curated CSV databases for styles, palettes, typography, UX rules, and wow effects.
  Provides industry-matched color palettes, font pairings, layout patterns, spacing/radius/shadow scales, gradient recipes, micro-animations, and accessibility-safe UX rules. Stack-agnostic — outputs design decisions for any frontend (Astro, SvelteKit, Next.js, React).
  Use when: "design", "colors", "typography", "component", "card", "button", "hero", "ui", "palette", "tailwind pattern", "style", "wow", "font", "layout", "spacing", "shadow", "gradient", "animation", "theme", "dark mode", "cta", "section", "landing page", "hero section".
effort: high
user-invocable: true
argument-hint: "[component|palette|typography]"
---

<!-- AI-QUICK-REF
## /design-system — Quick Reference
- **Two tiers:** Inline tables (80% case) + CSV deep layer (20% case)
- **6 areas:** Spacing, Typography, Colors, Components, Industry Palettes, Wow Effects
- **Deep data:** data/styles.csv (~50), data/palettes.csv (~80), data/product-palettes.csv (~40), data/typography.csv (~35), data/ux-rules.csv (~70), data/wow-effects.csv (~25)
- **Activation:** Automatically during UI work, or manually via /design-system
- **Tailwind v4:** All patterns for current Tailwind version
- **Persistence:** Optional design-system/MASTER.md per project
- **Stack-agnostic:** Provides design decisions, not code — stacks provide code patterns
-->

# Design System — Tiered Design Intelligence

Two tiers of design knowledge. Use Tier 1 for common decisions. Dive into Tier 2 CSVs only when you need more options or unusual combinations.

---

## Context Detection (ALWAYS do this first)

Before making any design decision, detect the project context:

```
1. Read package.json → Stack (Astro, SvelteKit, Next.js)
2. Read src/config/site.ts or equivalent → Industry, brand mood
3. Check design-system/MASTER.md → Project-specific overrides (HIGHEST PRIORITY)
4. Check tailwind.config or app.css → Current design tokens
```

**If `design-system/MASTER.md` exists, its values ALWAYS override recommendations.**
The CSV data helps CREATE the initial MASTER.md — it does not overrule an existing one.

---

## Decision Tree — When to Use Tier 2 (CSVs)

```
QUESTION                                          ACTION
─────────────────────────────────────────────────────────────
Standard industry palette?                     → Tier 1 inline table (Section 5)
Unusual mood/industry combo?                   → Read data/palettes.csv
Product-type-specific palette?                 → Read data/product-palettes.csv
One of the 10 standard font pairings?          → Tier 1 inline table (Section 3)
Need more font options or specific mood?       → Read data/typography.csv
Looking for a specific UI style?               → Read data/styles.csv
Need UX best practice guidance?                → Read data/ux-rules.csv
Searching for a wow effect?                    → Read data/wow-effects.csv
Standard spacing or component pattern?         → Tier 1 inline table (Section 2/6)
```

**Rule:** Try Tier 1 first. Only read CSVs when inline tables don't cover the need.

---

## 1. Design Principles

| Principle | Meaning |
|-----------|---------|
| Modern & minimalist | Fewer elements, more impact. No visual noise. |
| Professional, not generic | No stock-photo look, no generic AI aesthetic. Individual. |
| Wow factor | Every project needs a highlight (animation, typography, layout). |
| Aesthetics = Performance | Both must work. No fancy effects at the cost of speed. |
| Mobile First | Always design from small to large. |

---

## 2. Spacing Scale (Tailwind v4)

Consistent spacing prevents "random padding". Always choose from this scale:

| Token | Value | Usage |
|-------|-------|-------|
| `1` | 0.25rem (4px) | Icon gaps, inline spacing |
| `2` | 0.5rem (8px) | Tight padding, tag inner spacing |
| `3` | 0.75rem (12px) | Input padding, small gaps |
| `4` | 1rem (16px) | Standard padding, paragraphs |
| `5` | 1.25rem (20px) | Card padding (compact) |
| `6` | 1.5rem (24px) | Card padding (standard) |
| `8` | 2rem (32px) | Section gaps, larger separations |
| `10` | 2.5rem (40px) | Section padding (vertical) |
| `12` | 3rem (48px) | Large section gaps |
| `16` | 4rem (64px) | Hero padding, section separation |
| `20` | 5rem (80px) | Large sections |
| `24` | 6rem (96px) | Page sections (desktop) |

**Rules:**
- Between elements within a group: `2`-`4`
- Between groups: `6`-`8`
- Between sections: `16`-`24`
- Never mix padding — stay consistent

---

## 3. Typography

### Font Pairings (Quick Reference — 10 most common)

For 25+ more options: `Read data/typography.csv`

| Combination | Heading | Body | Style | Good for |
|-------------|---------|------|-------|----------|
| **Classic Elegant** | Playfair Display | Source Sans 3 | Serif + Sans | Restaurants, hotels, luxury |
| **Modern Clean** | Inter | Inter | Geometric | SaaS, tech, startups |
| **Warm Professional** | DM Serif Display | DM Sans | Warm Serif + Sans | Doctors, law firms, consulting |
| **Craft Honest** | Outfit | Outfit | Friendly Sans | Tradespeople, local businesses |
| **Editorial** | Fraunces | Libre Franklin | Variable Serif | Magazines, blogs, portfolios |
| **Minimal Swiss** | Manrope | Manrope | Geometric | Design agencies, architecture |
| **Soft Rounded** | Nunito | Nunito Sans | Rounded | Childcare, nursing, social services |
| **Bold Statement** | Space Grotesk | Work Sans | Grotesk | Creative, music, events |
| **Corporate Solid** | Plus Jakarta Sans | Plus Jakarta Sans | Modern Corporate | Corporations, B2B, consulting |
| **Warm Organic** | Lora | Karla | Oldstyle + Grotesque | Wellness, organic, sustainability |

### Typography Scale

| Element | Class | Size | Weight |
|---------|-------|------|--------|
| H1 (Hero) | `text-4xl md:text-5xl lg:text-6xl` | 36-60px | `font-bold` |
| H2 (Section) | `text-3xl md:text-4xl` | 30-36px | `font-bold` |
| H3 (Subsection) | `text-xl md:text-2xl` | 20-24px | `font-semibold` |
| H4 (Card Title) | `text-lg` | 18px | `font-semibold` |
| Body | `text-base` | 16px | `font-normal` |
| Body Large | `text-lg` | 18px | `font-normal` |
| Small / Caption | `text-sm` | 14px | `font-normal` |
| Overline | `text-xs uppercase tracking-wider` | 12px | `font-medium` |

**Rules:**
- Max 2 font families per project
- Line height: Body `leading-relaxed` (1.625), Headings `leading-tight` (1.25)
- GDPR: Fonts MUST always be self-hosted (no Google Fonts CDN)

---

## 4. Colors

### Semantic Colors (always use these)

| Token | Tailwind | Usage |
|-------|----------|-------|
| `primary` | `bg-primary text-primary` | Brand color, CTAs, active elements |
| `secondary` | `bg-secondary` | Supporting, badges, tags |
| `accent` | `bg-accent` | Highlights, hover states |
| `background` | `bg-background` | Page background |
| `surface` | `bg-surface` | Cards, panels, elevated surfaces |
| `muted` | `text-muted` | Disabled, placeholders, subtle text |
| `destructive` | `bg-destructive` | Errors, delete, warnings |
| `success` | `bg-success` | Confirmation, success messages |

### Contrast Rules

- Text on background: Minimum **4.5:1** (WCAG AA)
- Large text (24px+): Minimum **3:1**
- UI elements (buttons, inputs): Minimum **3:1** against background
- Tools: `contrast-ratio.com` or DevTools Accessibility Panel

---

## 5. Industry Palettes (Quick Reference — 12 most common)

For 70+ more palettes (multiple moods per industry, dark variants, mood-based): `Read data/palettes.csv`

| Industry | Primary | Secondary | CTA | Background | Mood |
|----------|---------|-----------|-----|------------|------|
| **Hair/Beauty** | `#8B5E83` Mauve | `#D4A574` Gold | `#C7456B` Pink | `#FFF8F5` Warm White | Elegant, feminine |
| **Restaurant/Gastro** | `#2D3436` Charcoal | `#B8860B` Dark Gold | `#E17055` Terracotta | `#FEFEFE` Clean White | Appetizing, warm |
| **Trades/Construction** | `#2C3E50` Navy | `#E67E22` Orange | `#27AE60` Green | `#F8F9FA` Light Grey | Trustworthy |
| **Medical/Healthcare** | `#1A5276` Medical Blue | `#2ECC71` Green | `#3498DB` Light Blue | `#F0F8FF` Alice Blue | Serious, calming |
| **Law/Legal** | `#1B2631` Dark Navy | `#85929E` Steel | `#C0392B` Red | `#FAFAFA` Off White | Authority, trust |
| **Fitness/Sports** | `#1E1E2E` Dark | `#00B894` Teal | `#FF6B35` Energy Orange | `#F5F5F5` Light | Dynamic, energetic |
| **Real Estate** | `#2C3E50` Navy | `#1ABC9C` Teal | `#E74C3C` Red | `#FFFFFF` White | Professional, modern |
| **Care/Social** | `#5B8C5A` Sage Green | `#E8D5B7` Sand | `#D4956B` Warm | `#FFF9F0` Cream | Warm, trustworthy |
| **IT/Tech** | `#0F172A` Slate 900 | `#6366F1` Indigo | `#22D3EE` Cyan | `#F8FAFC` Slate 50 | Modern, technical |
| **Photography** | `#111111` Near Black | `#F5F5F5` Light | `#E63946` Red | `#FFFFFF` White | Minimalist |
| **Flowers/Florist** | `#4A7C59` Forest | `#E8B4B8` Rose | `#D4956B` Warm | `#FDF8F4` Floral White | Natural, fresh |
| **Auto/Workshop** | `#1A1A2E` Dark Blue | `#C0C0C0` Silver | `#E94560` Red | `#F2F2F2` Light Grey | Robust, professional |

**Usage in projects:**
1. Identify the client's industry
2. Choose matching palette from table (or `data/palettes.csv` for more options)
3. Define as CSS custom properties in `tailwind.config` or `app.css`
4. Use consistently — no deviations without reason

> **Reference:** For product-specific palettes covering 161 categories with deeper mood/variant matrices, see `nextlevelbuilder/ui-ux-pro-max-skill` v2.5.0. Hangar's palette database focuses on the most common industries — the external resource covers niche and product-specific verticals.

### Product-Type Palettes

For industry-specific palette recommendations, consult `data/product-palettes.csv`.
Each entry maps a product type to a curated primary/accent/background combination with
reasoning for why these colors work for that specific industry.

**Usage:** When a user describes their project type (e.g., "fintech dashboard",
"restaurant website", "SaaS analytics"), look up the matching product type in the CSV
and use it as the starting point for the palette recommendation.

40 product types covered including: SaaS, fintech, healthcare, e-commerce, education,
food, travel, real estate, fitness, nonprofit, legal, gaming, music, AI/ML, crypto,
sustainability, luxury, developer tools, and more.

---

## 6. Component Patterns (Tailwind v4)

### Hero Section

```html
<section class="relative overflow-hidden bg-background px-6 py-24 sm:py-32 lg:px-8">
  <div class="mx-auto max-w-2xl text-center">
    <p class="text-sm font-medium uppercase tracking-wider text-primary">
      Overline Text
    </p>
    <h1 class="mt-2 text-4xl font-bold tracking-tight sm:text-6xl">
      Main Headline
    </h1>
    <p class="mt-6 text-lg leading-relaxed text-muted">
      Description text, max 2-3 sentences.
    </p>
    <div class="mt-10 flex items-center justify-center gap-4">
      <a href="#" class="rounded-lg bg-primary px-6 py-3 text-sm font-semibold text-white shadow-sm hover:bg-primary/90 transition">
        Primary CTA
      </a>
      <a href="#" class="text-sm font-semibold text-primary hover:text-primary/80 transition">
        Secondary Link &rarr;
      </a>
    </div>
  </div>
</section>
```

### Card

```html
<article class="group rounded-2xl border border-border/50 bg-surface p-6 shadow-sm transition hover:shadow-md">
  <div class="aspect-video overflow-hidden rounded-xl bg-muted/10">
    <img src="..." alt="..." class="h-full w-full object-cover transition group-hover:scale-105" />
  </div>
  <div class="mt-4">
    <p class="text-xs font-medium uppercase tracking-wider text-primary">Category</p>
    <h3 class="mt-1 text-lg font-semibold">Title</h3>
    <p class="mt-2 text-sm text-muted line-clamp-2">Description...</p>
  </div>
</article>
```

### Button Variants

```html
<!-- Primary -->
<button class="rounded-lg bg-primary px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-primary/90 transition">
  Primary
</button>

<!-- Secondary / Outline -->
<button class="rounded-lg border border-primary px-5 py-2.5 text-sm font-semibold text-primary hover:bg-primary/5 transition">
  Secondary
</button>

<!-- Ghost -->
<button class="rounded-lg px-5 py-2.5 text-sm font-semibold text-primary hover:bg-primary/5 transition">
  Ghost
</button>
```

### Section with Overline

```html
<section class="px-6 py-16 sm:py-24 lg:px-8">
  <div class="mx-auto max-w-7xl">
    <div class="mx-auto max-w-2xl text-center">
      <p class="text-sm font-medium uppercase tracking-wider text-primary">Overline</p>
      <h2 class="mt-2 text-3xl font-bold sm:text-4xl">Section Title</h2>
      <p class="mt-4 text-lg text-muted">Optional description text.</p>
    </div>
    <div class="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
      <!-- Cards / Content here -->
    </div>
  </div>
</section>
```

### Navigation (Mobile-Ready)

```html
<header class="sticky top-0 z-50 border-b border-border/50 bg-background/80 backdrop-blur-lg">
  <nav class="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
    <a href="/" class="text-xl font-bold">Logo</a>
    <div class="hidden items-center gap-8 md:flex">
      <a href="#" class="text-sm font-medium text-muted hover:text-foreground transition">Link</a>
      <a href="#" class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white">CTA</a>
    </div>
    <!-- Mobile: Burger menu with JS/Alpine -->
  </nav>
</header>
```

### Footer

```html
<footer class="border-t border-border/50 bg-surface">
  <div class="mx-auto max-w-7xl px-6 py-12 lg:px-8">
    <div class="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
      <!-- Column 1: Logo + Description -->
      <!-- Columns 2-4: Link groups -->
    </div>
    <div class="mt-12 border-t border-border/30 pt-8 text-center text-sm text-muted">
      &copy; {{YEAR}} {{COMPANY_NAME}}. All rights reserved.
      <span class="mx-2">|</span>
      <a href="/imprint" class="hover:text-foreground transition">Imprint</a>
      <span class="mx-2">|</span>
      <a href="/privacy" class="hover:text-foreground transition">Privacy Policy</a>
    </div>
  </div>
</footer>
```

---

## 7. Wow Factor Techniques (Quick Reference — 9 most common)

For 15+ more effects with performance ratings: `Read data/wow-effects.csv`

| Technique | CSS/Tailwind | When |
|-----------|-------------|------|
| **Glassmorphism** | `bg-white/10 backdrop-blur-lg border border-white/20` | Tech, modern, dark |
| **Gradient Text** | `bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent` | Headlines, CTAs |
| **Hover Scale** | `transition hover:scale-105` | Cards, images |
| **Scroll Reveal** | `@keyframes fadeInUp` + Intersection Observer | Sections, lists |
| **Staggered Animation** | `delay-[100ms] delay-[200ms]` etc. | Card grids, lists |
| **Subtle Shadow** | `shadow-sm hover:shadow-md transition` | Cards, buttons |
| **Backdrop Blur Nav** | `bg-background/80 backdrop-blur-lg` | Sticky navigation |
| **Accent Line** | `border-l-4 border-primary` or `before:` pseudo | Quotes, features |
| **Overline Label** | `text-xs uppercase tracking-wider text-primary` | Section intros |

---

## 8. Persistence (Optional)

For projects with multiple pages: create `design-system/MASTER.md` in the project root.

```markdown
# Design System — [Project Name]

## Colors
- Primary: #2C3E50
- Secondary: #E67E22
- CTA: #27AE60
- Background: #F8F9FA

## Fonts
- Heading: Outfit (600, 700)
- Body: Outfit (400)
- Google Fonts: https://fonts.google.com/specimen/Outfit

## Spacing
- Section Padding: py-16 sm:py-24
- Card Padding: p-6
- Grid Gap: gap-8

## Wow Factor
- Glassmorphism cards with backdrop-blur
- Staggered scroll reveal on feature grid
```

Claude reads this file automatically and follows it.
Page-specific overrides: `design-system/pages/{pagename}.md`.

---

## Rules

1. **Consistency > Creativity** — Better uniform than every section different
2. **Max 2 fonts** — Never more, even if it would be "creative"
3. **Spacing from the scale** — No arbitrary px values
4. **Check contrast** — WCAG AA is mandatory, not optional
5. **Mobile First** — Desktop layout is the extension, not the other way around
6. **Self-hosted fonts** — GDPR. Always.
7. **Performance** — No heavy animations at the cost of LCP
8. **MASTER.md overrides all** — If it exists, follow it. CSVs inform, MASTER.md decides.
9. **Stack-agnostic design** — This skill provides design decisions. Code patterns come from the stack skills (Astro, SvelteKit, etc.).
10. **Tier 1 first** — Check inline tables before reading CSVs. Save tokens.
