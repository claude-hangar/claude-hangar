---
name: polish
description: >
  Frontend quick wins to wow effects (6 dimensions).
  Use when: "polish", "beautify", "improve", "wow", "improve design", "enhance", "quick wins".
---

<!-- AI-QUICK-REF
## /polish — Quick Reference
- **7 Modes:** scan, quick, focus, wow, compete, showcase, auto
- **Arguments:** `/polish $0 [$1]` e.g. `/polish focus visual`, `/polish wow`
- **6 Dimensions:** Visual, UX, Content, Emotion, Conversion, Perf-Design
- **Score:** 1-10 per dimension, overall score = average
- **Performance Budget:** LCP +100ms max, CLS +0.01 max, JS +5KB max
- **Context Protection:** Max 8 improvements per session
- **State:** .polish-state.json in project root
- **Distinction:** /design-system = rules, /audit P09 = check, /polish = action
- **Checkpoint:** git stash before each change (checkpoint.sh triggers automatically)
- **Stack Detection:** Read package.json + config → load matching stack supplement
-->

# Polish — Frontend Improvements

The website is built and works. Now it gets polished.

**Triangle:**
```
/design-system         /audit Phase 09          /polish
    RULES        →       CHECK           →       ACTION
  "How it should be"  "How it is"          "How it gets better"
   (Reference)       (Findings list)      (Analysis + Implementation)
```

---

## 7 Modes

| Mode | Invocation | What happens | Modifies code? |
|------|-----------|-------------|----------------|
| `scan` | `/polish` or `/polish scan` | Design X-ray: rate 6 dimensions, output report | No |
| `quick` | `/polish quick` | Implement 3-5 quick wins with best impact/effort ratio | Yes |
| `focus` | `/polish focus [dim]` | Deep work on one dimension | Yes |
| `wow` | `/polish wow` | Suggest + implement 2-3 bold wow effects | Yes |
| `compete` | `/polish compete [url]` | Analyze competitor + specifically outperform | Yes |
| `showcase` | `/polish showcase` | Before/after screenshots + comparison document | No |
| `auto` | `/polish auto` | scan → prioritize → quick wins → offer wow → showcase | Yes |

---

## 6 Analysis Dimensions

Each dimension is rated with a score of 1-10. Details in `dimensions/*.md`.

| Dim | Code | What is checked | Checks |
|-----|------|----------------|--------|
| 1 | VIS | Color harmony, typography, spacing, layout, image quality, icons | 6 |
| 2 | UX | Navigation, CTAs, hover/focus, mobile, loading impression, user flow | 6 |
| 3 | CON | Headlines, body copy, CTA texts, storytelling, uniqueness, trust | 6 |
| 4 | EMO | First impression, industry fit, trust, differentiation, wow effect | 5 |
| 5 | CVR | CTA placement, contact options, social proof, urgency, friction | 5 |
| 6 | PERF | Animations, images, fonts, above-the-fold | 4 |

**Overall Score** = Average of all 6 dimensions (weighted: VIS/EMO x1.2, PERF x0.8).

---

## Process per Mode

### scan

1. **Load prior context:** Read existing audit states for severity-based prioritization:
   - `.audit-state.json` → Findings from ALL phases (not just Phase 09)
   - `.project-audit-state.json` → Code quality findings
   - `.astro-audit-state.json` → Astro-specific findings
   - `.micro-check-results.json` → Results from micro skills (if available)
   - **Benefit:** Address CRITICAL/HIGH findings first, use findings as context for dimension rating
2. **Identify project:** Read package.json, config files, `site.ts`
3. **Detect stack:** Astro? Tailwind? → load matching stack supplement (`stacks/`)
3. **Detect industry:** From `site.ts` or scan file → reference `/design-system` industry palette
4. **Run auto-detection:**
   - CSS/Tailwind: Extract colors (custom properties, theme config)
   - Fonts: Font files in `public/fonts/`, @font-face declarations
   - Spacing: Count most frequent padding/margin values
   - Animations: Find transition/animation declarations
   - Icons: Lucide/Heroicons? SVG inline or sprite?
5. **Rate 6 dimensions:** Go through each dimension file, assign score
6. **Output report:** Use template `templates/scan-report.md`
7. **Write state:** `.polish-state.json`
8. **Recommendation:** AskUserQuestion — recommend quick wins or targeted focus

### quick

1. **Read state** (if available) or run a brief scan
2. **Build impact matrix:**

| Category | Description | Approach |
|----------|------------|----------|
| Quick Win | Immediate, <5 min, large visual effect | Implement directly |
| Signature Move | 10-20 min, distinctive highlight | Checkpoint → implement |
| Optional | Nice-to-have, low impact | Mention only |

3. **Select 3-5 quick wins** from `strategies/quick-wins.md`
4. **Implement** — brief verification after each change
5. **Update state**

### focus [dim]

1. Dimension code: `visual`, `ux`, `content`, `emotion`, `conversion`, `perf`
2. Load matching dimension file
3. Go through all checks of the dimension
4. Identify weaknesses, prioritize fixes
5. Implement max 5 improvements per focus session
6. Score update in state

### wow

1. **Read state** — which dimensions are weak?
2. **Suggest wow effects** from `strategies/wow-effects.md`
3. **AskUserQuestion** — which effects to implement?
   - **Mark recommendation** (best impact for this website)
   - Max 3 to choose from
4. **Checkpoint** before each change (automatically via hook)
5. **Implement** with performance check after each effect
6. **Verification:** `npm run build` must succeed

### compete [url]

1. **Analyze competitor URL:** Playbook from `strategies/compete-playbook.md`
2. **Build comparison matrix:**
   - Design quality, features, performance, mobile, content
3. **Identify differentiation opportunities**
4. **AskUserQuestion:** Which improvements to implement?
5. **Implement** — specifically target areas where competitor is better
6. **Document** before/after

### showcase

1. Playwright screenshots: Desktop (1440px) + Mobile (375px)
2. If previous screenshots exist (from state): Side-by-side
3. Use template `templates/showcase.md`
4. Delete screenshots after documentation (cleanup rule)

### auto

1. Run `scan`
2. Analyze results, prioritize
3. `quick` — implement 3-5 quick wins
4. **AskUserQuestion:** Add wow effects?
   - **Yes (recommendation):** Run `wow`
   - **No:** Go directly to showcase
5. `showcase` — before/after

---

## Rules

### Performance Budget (CRITICAL)
No effect may exceed these limits:
- **LCP:** Max +100ms degradation
- **CLS:** Max +0.01 degradation
- **JS:** Max +5KB additional JavaScript
- **CSS-only preferred:** Always try animations as CSS-only first

### Context Protection
- Max **8 improvements** per session
- If more: AskUserQuestion whether to continue or start a new session

### Quality Checks after Each Change
1. `npm run build` — must succeed
2. Check contrast (WCAG AA: 4.5:1 text, 3:1 large)
3. Mentally walk through mobile view
4. Do not introduce new a11y problems

### Integration with Other Skills
- **Before polish:** Read `.audit-state.json` — use findings from ALL phases as input (not just Phase 09)
- **Design reference:** Follow `/design-system` industry palette + spacing scale
- **After polish:** Recommend `/lighthouse-quick` for performance verification
- **After polish:** Recommend `/capture-pdf quick` for before/after documentation

### Smart Next Steps

After completing polish, suggest appropriate follow-up skills to the user:

| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| Always | `/lighthouse-quick` | Verify performance after changes |
| Always | `/capture-pdf quick` | Before/after documentation |
| Audit state exists with open findings | `/audit continue` | Fix remaining findings |
| No audit has run | `/audit start` | Check overall quality |

---

## State Management

`.polish-state.json` in project root:

```json
{
  "version": "1.0",
  "project": "slug-from-directory-name",
  "stack": "astro",
  "industry": "industry-from-site-ts",
  "lastScan": {
    "date": "2026-02-21",
    "overallScore": 68,
    "dimensions": {
      "visual": { "score": 7, "findings": 3 },
      "ux": { "score": 8, "findings": 1 },
      "content": { "score": 6, "findings": 4 },
      "emotion": { "score": 5, "findings": 3 },
      "conversion": { "score": 7, "findings": 2 },
      "perf": { "score": 9, "findings": 0 }
    }
  },
  "improvements": [
    {
      "id": "VIS-01",
      "description": "Unified section spacing",
      "status": "fixed",
      "fixedIn": "2026-02-21"
    }
  ]
}
```

---

## Industry Context

Industry is automatically detected from:
1. `src/config/site.ts` → `industry` field
2. Scan file in `scans/` (if available)
3. Directory name (e.g., `hair-salon-downtown` → Hair Salon)

Load industry palette from `/design-system` and use as reference.
Do not apply blindly — respect the website's existing color scheme.
