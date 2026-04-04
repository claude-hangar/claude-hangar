# Playwright Screencast Deep Integration for capture-pdf

## Summary

Transform capture-pdf from a static screenshot-to-PDF tool into a multi-modal capture platform that produces PDFs, annotated video walkthroughs, responsive comparisons, and authenticated page captures — powered by Playwright 1.59's Screencast API.

## Architecture

**Script-First (Single File):** All Screencast features are integrated into the generated `capture-pdf.mjs`. Feature-detection at startup:

```js
const PW_VERSION = await getPlaywrightVersion();
const HAS_SCREENCAST = semverGte(PW_VERSION, '1.59.0');
```

Screencast features activate automatically when available. Graceful degradation to screenshot-only when Playwright < 1.59.

## Feature Blocks

### P1 — Animated Smart Captures

**Problem:** Static screenshots show the result of an interaction, not the interaction itself. A filled form screenshot doesn't show tab order, typing speed, or validation timing.

**Solution:** Each Smart Capture type becomes a screencast chapter with action annotations.

**Per element type:**

| Element | Screencast Flow |
|---------|----------------|
| Cookie Banner | Chapter start → banner appears → `showActions()` tracks dismiss click → banner animates out → chapter end |
| Form | Chapter "Form — Contact" → `showActions()` on each field → type sample data → tab to next → trigger validation → show errors → chapter end |
| Accordion | Chapter per accordion → click trigger → `showActions()` → slide animation visible → content shown → chapter end |
| Modal | Chapter → trigger button click → modal opens with animation → scroll content → close → chapter end |
| Mobile Menu | Chapter → hamburger click → slide-in animation → navigate links → close → chapter end |
| Lightbox | Chapter → thumbnail click → zoom animation → swipe through gallery → close → chapter end |

**Implementation detail:**
```js
async function captureSmartElement(page, element, type) {
  await page.screencast.showChapter(`${type} — ${element.label}`, {
    description: element.description,
    duration: 1500
  });
  await page.screencast.showActions({ position: 'top-right', duration: 800 });

  // Type-specific interaction sequence
  await interactions[type](page, element);

  await page.screencast.hideActions();
}
```

**Fallback:** When `--no-video` is passed or Playwright < 1.59, the existing screenshot-based capture runs unchanged.

### P2 — Overlay System (5 Types)

Five overlay types that can be combined. Each overlay is a positioned HTML element injected via `page.screencast.showOverlay()`.

**Status Overlay (always on in video mode):**
```html
<div style="position:fixed;top:12px;left:12px;background:rgba(0,0,0,0.7);
  color:#fff;padding:6px 14px;border-radius:6px;font:13px/1 system-ui;z-index:99999">
  Page 3/12 — Contact
</div>
```
Shows current page number and name. Updates per page navigation.

**Viewport Overlay (first 2 seconds per page):**
```html
<div style="position:fixed;top:12px;right:12px;background:rgba(59,130,246,0.85);
  color:#fff;padding:6px 14px;border-radius:6px;font:13px/1 system-ui;z-index:99999">
  Desktop 1920×1080
</div>
```
Shown briefly at the start of each page to identify viewport. Auto-hides after 2s.

**Meta Overlay (opt-in via `--video-meta`):**
```html
<div style="position:fixed;bottom:0;left:0;right:0;background:rgba(0,0,0,0.85);
  color:#fff;padding:10px 16px;font:12px/1.4 system-ui;z-index:99999">
  <strong>Title:</strong> Contact Us | Acme Corp<br>
  <strong>Desc:</strong> Get in touch with our team...<br>
  <strong>Canonical:</strong> https://acme.com/contact
</div>
```
Extracts title, meta description, canonical URL from page and displays as bottom bar.

**Finding Overlay (opt-in via `--video-audit`):**
Reads findings from a JSON file and shows badges at relevant positions:
```js
// findings.json format:
[{ "id": "SEC-03", "severity": "high", "message": "Mixed Content", "selector": "img[src^='http:']" }]
```
Each finding gets a red/yellow badge positioned near the matching element.

**Form State Overlay:**
During form smart captures, shows current state as a progress bar:
```
[ Empty ] → [ Filling ■■■░░ ] → [ Validation ] → [ Errors ]
```

**Overlay control:**
- `--no-overlays` disables all overlays (clean recording)
- Individual overlays toggled via their respective flags
- Overlays use `showOverlays()` / `hideOverlays()` for batch control

### P3 — Responsive Comparison Mode

**Flag:** `--video-responsive`

Records each page at three viewports sequentially in one continuous video:

```
[Chapter: Home — Desktop 1920×1080]
  → Full page capture at desktop
[Chapter: Home — Tablet 768×1024]
  → Resize viewport → full page capture at tablet
[Chapter: Home — Mobile 375×812]
  → Resize viewport → full page capture at mobile
[Chapter: About — Desktop 1920×1080]
  → Navigate to /about → full page capture at desktop
...
```

**Implementation:**
```js
for (const pageInfo of pages) {
  for (const vp of [DESKTOP, TABLET, MOBILE]) {
    await page.setViewportSize(vp.size);
    await page.screencast.showChapter(
      `${pageInfo.name} — ${vp.label} ${vp.size.width}×${vp.size.height}`,
      { duration: 1200 }
    );
    // Viewport overlay shows briefly
    await showViewportOverlay(page, vp);
    await page.goto(pageInfo.url);
    await page.waitForLoadState('networkidle');
    // Smart captures at this viewport
    if (vp.label === 'Mobile') await captureMobileMenu(page);
    await waitForStableFrame(page, 500);
  }
}
```

**Output:** Single file `{name}-responsive-{date}.webm` with chapters navigable by viewport.

### P4 — Authenticated Page Captures

**Problem:** Many sites have protected pages (dashboard, admin, account) that require login. Currently these cannot be captured.

**Solution:** Two approaches via Playwright's `browserContext.setStorageState()`:

**Approach 1 — Pre-saved state (`--auth <file>`):**
```bash
node scripts/capture-pdf.mjs --auth auth-state.json
```
Loads cookies, localStorage, indexedDB from the JSON file before capturing. User creates the state file manually or via Approach 2.

**Approach 2 — Interactive login (`--auth-login <url>`):**
```bash
node scripts/capture-pdf.mjs --auth-login https://example.com/login
```
1. Opens login page in a visible browser (`headless: false`)
2. Binds browser: `browser.bind('capture-auth')` 
3. Prints: `Log in manually, then press Enter in this terminal...`
4. User logs in (handles 2FA, captcha, etc.)
5. On Enter: saves storage state to `prints/auth-state.json`
6. Switches to headless, proceeds with capture using saved state
7. State file reusable for future captures

**Storage state reset between captures:**
```js
// Reset to clean state between auth/non-auth captures
await context.setStorageState({ cookies: [], origins: [] });
```

### P5 — Thumbnail Generation from Frames

**Flag:** `--thumbs`

Uses `onFrame` callback to capture the first visually stable frame of each page:

```js
let lastFrameHash = null;
let stableCount = 0;
const STABLE_THRESHOLD = 3; // 3 identical frames = stable

await page.screencast.start({
  onFrame: ({ data }) => {
    const hash = quickHash(data);
    if (hash === lastFrameHash) {
      stableCount++;
      if (stableCount === STABLE_THRESHOLD && !thumbnailSaved) {
        saveThumbnail(data, pageInfo.name);
        thumbnailSaved = true;
      }
    } else {
      stableCount = 0;
      lastFrameHash = hash;
    }
  },
  size: { width: 600, height: 400 }
});
```

**Output:** `prints/thumbs/{page-name}.jpg` (300px wide, JPEG quality 85)

**Bonus — Index HTML:**
When `--thumbs` is used, generates `prints/index.html` with a visual grid of all thumbnails linking to timestamps in the video.

### P6 — Browser Dashboard Integration

**Flag:** `--dashboard`

Binds the capture browser so external clients can observe and intervene:

```js
const { endpoint } = await browser.bind('capture-session', {
  workspaceDir: process.cwd()
});
console.log(`Watch live: playwright-cli attach capture-session`);
console.log(`Dashboard:  playwright-cli show`);

if (args.dashboard) {
  spawn('npx', ['playwright-cli', 'show'], { stdio: 'ignore', detached: true });
}
```

**Use cases:**
- Watch capture progress in real-time
- Manually solve captchas or dialog prompts
- Debug stuck pages
- Multi-person review (multiple clients connect simultaneously)

**Always active** (bind is cheap). The `--dashboard` flag just auto-opens the UI.

### P7 — AI Vision Frame Pipeline (Extension Point)

**Flag:** `--vision-analyze`

Provides a hook for frame-level analysis without calling external APIs:

```js
// Built-in: CLS detection via frame differencing
async function detectCLS(currentFrame, previousFrame) {
  // Quick pixel-diff using sharp
  const diff = await sharp(currentFrame)
    .composite([{ input: previousFrame, blend: 'difference' }])
    .statistics();
  
  return diff.channels[0].mean > CLS_THRESHOLD;
}
```

**Built-in analyses (local only):**
- CLS detection: Compare consecutive frames, flag pages with layout shift > threshold
- FOUT detection: Font rendering change in first 3 seconds
- Blank page detection: Frame is mostly white/empty → possible loading issue

**Extension interface:**
```js
// User can provide custom analyzer in config
const analyzer = config.visionAnalyzer || defaultAnalyzer;
await page.screencast.start({
  onFrame: ({ data, timestamp }) => analyzer(data, timestamp, pageInfo)
});
```

**Output:** `prints/vision-report.json` with per-page analysis results.

**Privacy rule preserved:** No external API calls. All analysis runs locally. The extension interface allows users to add their own integrations if they choose.

### P8 — Before/After Comparison (Extension Point)

**Flag:** `--compare <baseline.webm>`

Records a new video and generates a comparison report:

```js
// 1. Record new video
const newVideo = await captureAllPages(pages, options);

// 2. Extract key frames from both videos at same timestamps
const baselineFrames = await extractKeyFrames(args.compare);
const newFrames = await extractKeyFrames(newVideo);

// 3. Generate diff report
const report = [];
for (let i = 0; i < Math.min(baselineFrames.length, newFrames.length); i++) {
  const diff = await pixelDiff(baselineFrames[i], newFrames[i]);
  report.push({
    page: pages[i]?.name,
    diffPercentage: diff.percentage,
    diffImage: diff.outputPath
  });
}
```

**Output:** `prints/comparison-{date}.json` + diff images in `prints/diffs/`

**Documented as extension point** — the frame extraction and diff logic is provided, but sophisticated comparison (structural diff, semantic diff) is left for future implementation.

## New CLI Flags (Complete)

```
Video:
  --video              Video walkthrough alongside PDFs (auto if PW >= 1.59)
  --video-only         Video only, skip PDF generation  
  --video-responsive   Record each page at 3 viewports sequentially

Overlays:
  --video-meta         Show title/description/canonical overlay per page
  --video-audit <file> Show finding badges from JSON file
  --no-overlays        Disable all overlays (clean recording)

Auth:
  --auth <file>        Load storage state for authenticated captures
  --auth-login <url>   Interactive login via dashboard, then capture

Debug & Observation:
  --dashboard          Open Playwright dashboard for live observation
  --trace              Enable live tracing alongside video

Thumbnails & Analysis:
  --thumbs             Generate page thumbnails + index.html from frames
  --vision-analyze     Enable local frame analysis (CLS, FOUT, blank detection)
  --compare <file>     Compare against baseline recording

Existing (unchanged):
  --url <url>          Base URL
  --viewport <name>    desktop|tablet|mobile (default: desktop)
  --format <size>      a4|a3 (default: a4)
  --pages <json>       JSON array of pages (override)
  --no-smart           No smart captures
  --no-video           Force disable video even if PW >= 1.59
  --forms-only         Only form pages
  --concurrency <n>    Parallel captures (default: 3)
  --output <dir>       Output directory (default: prints/)
  --name <name>        PDF filename prefix
```

## Output Structure

```
prints/
├── {name}-desktop-2026-04-04.pdf          # PDF (unchanged)
├── {name}-walkthrough-2026-04-04.webm     # Video walkthrough
├── {name}-responsive-2026-04-04.webm      # Responsive comparison
├── thumbs/                                 # Page thumbnails
│   ├── home.jpg
│   ├── about.jpg
│   └── contact.jpg
├── index.html                              # Visual thumbnail index
├── auth-state.json                         # Saved auth state
├── vision-report.json                      # Frame analysis results
├── comparison-2026-04-04.json              # Before/after report
└── diffs/                                  # Diff images
    ├── home-diff.png
    └── about-diff.png
```

## Feature Detection & Graceful Degradation

```js
async function initCapture(args) {
  const pw = await import('playwright');
  const HAS_SCREENCAST = semverGte(pw.version, '1.59.0');
  
  if (!HAS_SCREENCAST || args.noVideo) {
    if (!args.noVideo && (args.video || args.videoOnly || args.videoResponsive)) {
      console.warn('⚠ Playwright < 1.59 — video features disabled, using screenshots');
    }
    // Fall back to existing screenshot pipeline
    return { mode: 'screenshot' };
  }
  
  return {
    mode: 'screencast',
    video: args.video || args.videoOnly || args.videoResponsive,
    overlays: !args.noOverlays,
    auth: args.auth || args.authLogin,
    dashboard: args.dashboard
  };
}
```

## Rules

- **Privacy:** No external API calls. Frame analysis local only. Vision pipeline is extension point.
- **No real submit:** Forms never submitted. `event.preventDefault()` on all submit events.
- **Graceful degradation:** Playwright < 1.59 → everything works like before (screenshots + PDF)
- **`await using`:** All Page and Context objects use async disposables for automatic cleanup
- **No breaking changes:** All existing flags, modes, and output paths remain identical
- **Cross-platform:** Works on Linux and Windows Git Bash
- **No hardcoded versions:** Dependencies installed without fixed version numbers
