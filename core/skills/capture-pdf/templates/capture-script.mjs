#!/usr/bin/env node

// ============================================================================
// capture-pdf.mjs — Universeller Website-zu-PDF Capture
//
// Erfasst alle Seiten + interaktive Zustaende als druckfertige PDFs.
// Generiert von /capture-pdf Skill (claude-hangar).
//
// Usage: node scripts/capture-pdf.mjs [--url <url>] [--viewport desktop|tablet|mobile]
//        [--format a4|a3] [--no-smart] [--forms-only] [--concurrency <n>]
//        [--output <dir>] [--name <name>] [--pages '<json>'] [--help]
// ============================================================================

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { execSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROJECT_ROOT = resolve(__dirname, '..');

// ─── Configuration ──────────────────────────────────────────────────────────

const CONFIG = {
  projectName: '{{PROJECT_NAME}}',
  baseUrl: '{{BASE_URL}}',
  pages: {{PAGES_JSON}},

  viewports: {
    desktop: { width: 1920, height: 1080 },
    tablet:  { width: 768,  height: 1024 },
    mobile:  { width: 375,  height: 812 },
  },

  paper: {
    a4: { width: 595.28, height: 841.89, label: 'A4' },
    a3: { width: 841.89, height: 1190.55, label: 'A3' },
  },

  margins: { top: 40, right: 40, bottom: 40, left: 40 },
  headerHeight: 24,
  labelHeight: 22,
  jpegQuality: 92,
  defaultConcurrency: 3,
  navigationTimeout: 30_000,
  captureTimeout: 15_000,

  selectors: {
    cookieBanner: [
      '[role="dialog"][class*="cookie"]', '[role="dialog"][class*="consent"]',
      '#cookie-banner', '#cookie-consent', '#cc-main', '#cc-banner',
      '.cookie-banner', '.cookie-consent', '.consent-banner',
      '[class*="cookie-banner"]', '[class*="cookie-consent"]',
      '[class*="consent-overlay"]', '[id*="cookie"]', '[id*="consent"]',
    ],
    forms: [
      'form:not([data-no-capture]):not([role="search"])',
      'form:has(textarea)', 'form:has(input[type="email"])',
    ],
    consentEmbeds: [
      'iframe[src*="google.com/maps"]', '[data-src*="youtube"]',
      '[data-src*="instagram"]', '.consent-placeholder',
      '[class*="embed-consent"]', '[class*="external-content"]',
    ],
    accordions: [
      'details', '[role="tablist"]', '[data-accordion]',
      '[class*="accordion"]', '[class*="collapse"]', '[class*="faq"]',
      '[class*="expandable"]',
    ],
    modals: [
      'dialog:not([class*="cookie"]):not([class*="consent"])',
      '[role="dialog"]:not([class*="cookie"]):not([class*="consent"])',
      '[data-modal]', '[class*="modal"]:not([class*="cookie"])',
    ],
    mobileMenu: [
      '[popover]', '.mobile-menu', '#mobile-nav',
      'button[aria-expanded]', '.hamburger',
      '[class*="mobile-menu"]', '[class*="nav-toggle"]',
    ],
    lightboxes: [
      '[data-lightbox]', '[data-fancybox]', '[data-gallery]',
      'a[href$=".jpg"] > img', 'a[href$=".webp"] > img',
      '[class*="gallery"] a > img',
    ],
    devToolbars: [
      'astro-dev-toolbar', '[id*="__next"]', '[id*="nuxt-devtools"]',
      '[class*="dev-toolbar"]', '[class*="debug-panel"]',
    ],
    floatingWidgets: [
      '[class*="chat-widget"]', '[class*="chat-bubble"]',
      '[class*="feedback-btn"]', '[class*="intercom"]',
      '[class*="crisp"]', '[class*="tawk"]',
    ],
  },

  captcha: [
    '.g-recaptcha', '[data-sitekey]', '.cf-turnstile',
    '.h-captcha', '[class*="captcha"]', '#captcha',
  ],
};

// ─── CLI Parsing ────────────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = {
    url: CONFIG.baseUrl,
    viewport: null,
    format: 'a4',
    pages: null,
    smart: true,
    formsOnly: false,
    concurrency: CONFIG.defaultConcurrency,
    output: join(PROJECT_ROOT, 'prints'),
    name: CONFIG.projectName,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--url':       opts.url = args[++i]; break;
      case '--viewport':  opts.viewport = args[++i]; break;
      case '--format':    opts.format = args[++i]; break;
      case '--pages':     opts.pages = JSON.parse(args[++i]); break;
      case '--no-smart':  opts.smart = false; break;
      case '--forms-only': opts.formsOnly = true; break;
      case '--concurrency': opts.concurrency = parseInt(args[++i], 10); break;
      case '--output':    opts.output = resolve(args[++i]); break;
      case '--name':      opts.name = args[++i]; break;
      case '--help':      printHelp(); process.exit(0);
      default:
        console.error(`Unknown option: ${args[i]}`);
        printHelp();
        process.exit(1);
    }
  }

  // Remove trailing slash from URL
  opts.url = opts.url.replace(/\/+$/, '');

  return opts;
}

function printHelp() {
  console.log(`
capture-pdf.mjs — ${CONFIG.projectName}

Usage: node scripts/capture-pdf.mjs [options]

Options:
  --url <url>        Base URL (default: ${CONFIG.baseUrl})
  --viewport <name>  desktop|tablet|mobile (default: all configured)
  --format <size>    a4|a3 (default: a4)
  --pages '<json>'   JSON array of pages (override config)
  --no-smart         Skip Smart Captures (cookie, forms, etc.)
  --forms-only       Only capture pages with forms
  --concurrency <n>  Parallel page captures (default: ${CONFIG.defaultConcurrency})
  --output <dir>     Output directory (default: prints/)
  --name <name>      PDF filename prefix (default: ${CONFIG.projectName})
  --help             Show this help
`);
}

// ─── Dependency Management ──────────────────────────────────────────────────

async function ensureDeps() {
  const required = ['playwright', 'pdf-lib', 'sharp'];
  const missing = required.filter(pkg => {
    try { require.resolve(pkg); return false; }
    catch { return true; }
  });

  if (missing.length === 0) return;

  console.log(`Installing missing dependencies: ${missing.join(', ')}...`);
  const scriptsDir = __dirname;
  const pkgJsonPath = join(scriptsDir, 'package.json');

  if (!existsSync(pkgJsonPath)) {
    writeFileSync(pkgJsonPath, JSON.stringify({ private: true, type: 'module' }, null, 2));
  }

  execSync(`npm install ${missing.join(' ')}`, { cwd: scriptsDir, stdio: 'inherit' });

  if (missing.includes('playwright')) {
    console.log('Installing Chromium for Playwright...');
    execSync('npx playwright install chromium', { cwd: scriptsDir, stdio: 'inherit' });
  }
}

// ─── PageDiscovery ──────────────────────────────────────────────────────────

class PageDiscovery {
  constructor(baseUrl) {
    this.baseUrl = baseUrl;
  }

  async discoverFromSitemap(page) {
    const urls = [];
    for (const path of ['/sitemap.xml', '/sitemap-index.xml']) {
      try {
        const resp = await page.goto(`${this.baseUrl}${path}`, { timeout: 10_000 });
        if (!resp || resp.status() !== 200) continue;

        const content = await page.content();
        const locMatches = content.matchAll(/<loc>(.*?)<\/loc>/g);
        for (const m of locMatches) {
          const url = m[1].trim();
          const relative = url.replace(this.baseUrl, '').replace(/^\/+/, '/') || '/';
          if (!this.isExcluded(relative)) {
            urls.push(relative);
          }
        }

        // Handle sitemap index (contains other sitemaps)
        if (content.includes('<sitemapindex')) {
          const sitemapUrls = [...content.matchAll(/<loc>(.*?)<\/loc>/g)].map(m => m[1].trim());
          for (const smUrl of sitemapUrls) {
            try {
              const smResp = await page.goto(smUrl, { timeout: 10_000 });
              if (smResp && smResp.status() === 200) {
                const smContent = await page.content();
                const smLocs = smContent.matchAll(/<loc>(.*?)<\/loc>/g);
                for (const sm of smLocs) {
                  const u = sm[1].trim();
                  const rel = u.replace(this.baseUrl, '').replace(/^\/+/, '/') || '/';
                  if (!this.isExcluded(rel)) urls.push(rel);
                }
              }
            } catch { /* skip broken sub-sitemaps */ }
          }
        }

        if (urls.length > 0) break;
      } catch { /* sitemap not available */ }
    }
    return [...new Set(urls)];
  }

  async discoverByCrawling(page, maxDepth = 2) {
    const visited = new Set();
    const toVisit = ['/'];
    const found = ['/'];
    let depth = 0;

    while (toVisit.length > 0 && depth < maxDepth) {
      const current = [...toVisit];
      toVisit.length = 0;
      depth++;

      for (const path of current) {
        if (visited.has(path)) continue;
        visited.add(path);

        try {
          await page.goto(`${this.baseUrl}${path}`, {
            timeout: CONFIG.navigationTimeout,
            waitUntil: 'domcontentloaded',
          });

          const links = await page.evaluate((baseUrl) => {
            const origin = new URL(baseUrl).origin;
            return [...document.querySelectorAll('a[href]')]
              .map(a => {
                try {
                  const url = new URL(a.href, baseUrl);
                  if (url.origin !== origin) return null;
                  return url.pathname;
                } catch { return null; }
              })
              .filter(Boolean);
          }, this.baseUrl);

          for (const link of links) {
            const clean = link.replace(/\/+$/, '') || '/';
            if (!visited.has(clean) && !this.isExcluded(clean) && !found.includes(clean)) {
              found.push(clean);
              toVisit.push(clean);
            }
          }
        } catch { /* skip unreachable pages */ }
      }
    }

    return found;
  }

  isExcluded(path) {
    const excludes = [
      /^\/api\//,
      /^\/admin/,
      /^\/dashboard/,
      /\/404$/,
      /\/500$/,
      /\?page=/,
      /\.(xml|json|txt|ico|png|jpg|svg|css|js)$/,
      /^\/_(.*)/,
      /^\/wp-admin/,
      /^\/wp-login/,
      /^\/feed/,
    ];
    return excludes.some(rx => rx.test(path));
  }

  buildPageList(paths) {
    return paths.map(p => ({
      path: p,
      name: p === '/' ? 'Startseite' : p
        .replace(/^\//, '')
        .replace(/\/$/, '')
        .split('/')
        .map(s => s.charAt(0).toUpperCase() + s.slice(1))
        .join(' / ')
        .replace(/-/g, ' '),
    }));
  }
}

// ─── PagePrep ───────────────────────────────────────────────────────────────

class PagePrep {
  static async prepare(page) {
    await page.evaluate((selectors) => {
      // Remove dev toolbars
      for (const sel of selectors.devToolbars) {
        document.querySelectorAll(sel).forEach(el => el.remove());
      }

      // Remove floating widgets
      for (const sel of selectors.floatingWidgets) {
        document.querySelectorAll(sel).forEach(el => el.remove());
      }

      // Remove cookie banners for clean captures
      for (const sel of selectors.cookieBanner) {
        document.querySelectorAll(sel).forEach(el => {
          el.style.display = 'none';
        });
      }

      // Force lazy-loaded images
      document.querySelectorAll('img[loading="lazy"]').forEach(img => {
        img.loading = 'eager';
        if (img.dataset.src) {
          img.src = img.dataset.src;
        }
      });

      // Trigger intersection observers by scrolling
      window.scrollTo(0, document.body.scrollHeight);
      window.scrollTo(0, 0);

      // Disable all animations
      const style = document.createElement('style');
      style.textContent = `
        *, *::before, *::after {
          animation-duration: 0s !important;
          animation-delay: 0s !important;
          transition-duration: 0s !important;
          transition-delay: 0s !important;
          scroll-behavior: auto !important;
        }
      `;
      document.head.appendChild(style);

      // Make all scroll-triggered elements visible
      document.querySelectorAll('[data-aos], [class*="animate-"]').forEach(el => {
        el.style.opacity = '1';
        el.style.transform = 'none';
        el.style.visibility = 'visible';
      });

      // Close any open popovers
      document.querySelectorAll('[popover]:popover-open').forEach(el => {
        try { el.hidePopover(); } catch {}
      });
    }, CONFIG.selectors);

    // Wait for images and network idle
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(500);
  }
}

// ─── FormFiller ─────────────────────────────────────────────────────────────

class FormFiller {
  constructor(formDataPath) {
    this.formData = this.loadFormData(formDataPath);
  }

  loadFormData(path) {
    try {
      return JSON.parse(readFileSync(path, 'utf-8'));
    } catch {
      return this.defaultFormData();
    }
  }

  defaultFormData() {
    return {
      fields: {
        email: { match: ['email', 'e-mail', 'mail'], value: 'maria@beispiel.de' },
        fullName: { match: ['name'], value: 'Maria Mustermann' },
        phone: { match: ['phone', 'telefon', 'tel'], value: '+49 89 123 4567' },
        message: { match: ['message', 'nachricht'], value: 'Testanfrage.' },
      },
      textareaDefault: 'Dies ist eine Testanfrage.',
      selectStrategy: 'firstNonEmpty',
      checkboxStrategy: 'requiredOnly',
    };
  }

  async fillForms(page) {
    const formData = this.formData;
    return await page.evaluate((data) => {
      const forms = document.querySelectorAll('form:not([data-no-capture]):not([role="search"])');
      const results = [];

      for (const form of forms) {
        const inputs = form.querySelectorAll('input, textarea, select');
        if (inputs.length === 0) continue;

        const formInfo = { filled: 0, fields: [], hasCaptcha: false };

        // Check for captcha
        const captchaSelectors = ['.g-recaptcha', '[data-sitekey]', '.cf-turnstile', '.h-captcha', '[class*="captcha"]'];
        formInfo.hasCaptcha = captchaSelectors.some(sel => form.querySelector(sel));

        for (const input of inputs) {
          if (input.type === 'hidden' || input.type === 'submit' || input.type === 'button') continue;

          const identifier = (input.name || input.id || input.placeholder || '').toLowerCase();
          const label = input.labels?.[0]?.textContent?.toLowerCase() || '';
          const searchStr = `${identifier} ${label}`;

          if (input.type === 'checkbox') {
            if (input.required && !input.checked) {
              input.checked = true;
              input.dispatchEvent(new Event('change', { bubbles: true }));
              formInfo.filled++;
              formInfo.fields.push('checkbox');
            }
            continue;
          }

          if (input.tagName === 'SELECT') {
            const options = [...input.options].filter(o => o.value && o.value !== '');
            if (options.length > 0 && input.selectedIndex <= 0) {
              input.value = options[0].value;
              input.dispatchEvent(new Event('change', { bubbles: true }));
              formInfo.filled++;
              formInfo.fields.push('select');
            }
            continue;
          }

          if (input.tagName === 'TEXTAREA') {
            if (!input.value) {
              input.value = data.textareaDefault;
              input.dispatchEvent(new Event('input', { bubbles: true }));
              formInfo.filled++;
              formInfo.fields.push('textarea');
            }
            continue;
          }

          // Input fields — match by heuristic
          let matched = false;
          for (const [, fieldDef] of Object.entries(data.fields)) {
            if (fieldDef.match.some(m => searchStr.includes(m))) {
              if (input.type === 'email' && !fieldDef.match.includes('email')) continue;
              input.value = fieldDef.value;
              input.dispatchEvent(new Event('input', { bubbles: true }));
              formInfo.filled++;
              formInfo.fields.push(identifier || input.type);
              matched = true;
              break;
            }
          }

          // Fallback for unmatched text inputs
          if (!matched && !input.value && (input.type === 'text' || input.type === '')) {
            input.value = 'Test';
            input.dispatchEvent(new Event('input', { bubbles: true }));
            formInfo.filled++;
          }
        }

        // Prevent actual form submission
        form.addEventListener('submit', e => e.preventDefault(), { capture: true });

        results.push(formInfo);
      }

      return results;
    }, formData);
  }

  async triggerValidation(page) {
    return await page.evaluate(() => {
      const forms = document.querySelectorAll('form:not([data-no-capture]):not([role="search"])');
      const results = [];
      for (const form of forms) {
        const isValid = form.reportValidity();
        results.push({ valid: isValid });
      }
      return results;
    });
  }
}

// ─── SmartCapture ───────────────────────────────────────────────────────────

class SmartCapture {
  constructor(formFiller) {
    this.formFiller = formFiller;
  }

  async detectElements(page, viewportName) {
    const elements = [];

    const detected = await page.evaluate((selectors) => {
      const found = {};

      // Cookie Banner
      for (const sel of selectors.cookieBanner) {
        const el = document.querySelector(sel);
        if (el && el.offsetHeight > 0) { found.cookie = true; break; }
      }

      // Forms
      const forms = document.querySelectorAll('form:not([data-no-capture]):not([role="search"])');
      const meaningfulForms = [...forms].filter(f => {
        const inputs = f.querySelectorAll('input:not([type="hidden"]):not([type="submit"]), textarea, select');
        return inputs.length >= 2;
      });
      if (meaningfulForms.length > 0) found.forms = meaningfulForms.length;

      // Consent Embeds
      for (const sel of selectors.consentEmbeds) {
        if (document.querySelector(sel)) { found.embeds = true; break; }
      }

      // Accordions
      const accEls = [];
      for (const sel of selectors.accordions) {
        accEls.push(...document.querySelectorAll(sel));
      }
      if (accEls.length > 0) found.accordions = accEls.length;

      // Modals
      for (const sel of selectors.modals) {
        if (document.querySelector(sel)) { found.modals = true; break; }
      }

      // Lightboxes
      for (const sel of selectors.lightboxes) {
        if (document.querySelector(sel)) { found.lightboxes = true; break; }
      }

      return found;
    }, CONFIG.selectors);

    // Mobile menu only for mobile viewport
    if (viewportName === 'mobile') {
      const hasMobileMenu = await page.evaluate((selectors) => {
        for (const sel of selectors.mobileMenu) {
          if (document.querySelector(sel)) return true;
        }
        return false;
      }, CONFIG.selectors);
      if (hasMobileMenu) detected.mobileMenu = true;
    }

    // Build capture list
    if (detected.cookie) elements.push({ type: 'cookie', label: 'Cookie-Banner' });
    if (detected.forms) elements.push({ type: 'forms', label: `Formular${detected.forms > 1 ? 'e' : ''} — ausgefuellt`, count: detected.forms });
    if (detected.embeds) elements.push({ type: 'embeds', label: 'Consent-Embed Platzhalter' });
    if (detected.accordions) elements.push({ type: 'accordions', label: 'Akkordeons — aufgeklappt' });
    if (detected.modals) elements.push({ type: 'modals', label: 'Modal/Dialog' });
    if (detected.mobileMenu) elements.push({ type: 'mobileMenu', label: 'Mobile Menu — geoeffnet' });
    if (detected.lightboxes) elements.push({ type: 'lightboxes', label: 'Lightbox/Galerie' });

    return elements;
  }

  async captureCookieBanner(page) {
    // Show cookie banners again
    await page.evaluate((selectors) => {
      for (const sel of selectors.cookieBanner) {
        document.querySelectorAll(sel).forEach(el => {
          el.style.display = '';
          el.style.visibility = 'visible';
          el.style.opacity = '1';
        });
      }
    }, CONFIG.selectors);
    await page.waitForTimeout(300);
    return await page.screenshot({ fullPage: true, type: 'jpeg', quality: CONFIG.jpegQuality });
  }

  async captureForms(page) {
    const screenshots = [];
    await this.formFiller.fillForms(page);
    await page.waitForTimeout(300);
    screenshots.push({
      label: 'Formular — ausgefuellt',
      buffer: await page.screenshot({ fullPage: true, type: 'jpeg', quality: CONFIG.jpegQuality }),
    });

    // Check for captcha
    const hasCaptcha = await page.evaluate((selectors) => {
      return selectors.some(sel => document.querySelector(sel));
    }, CONFIG.captcha);

    if (hasCaptcha) {
      screenshots[0].label += ' (Captcha-geschuetzt)';
    }

    return screenshots;
  }

  async captureAccordions(page) {
    await page.evaluate((selectors) => {
      // Open all <details>
      document.querySelectorAll('details').forEach(d => d.open = true);

      // Click accordion triggers
      for (const sel of selectors.accordions) {
        document.querySelectorAll(sel).forEach(el => {
          if (el.tagName === 'DETAILS') return; // already handled
          const trigger = el.querySelector('[aria-expanded="false"]') ||
                         el.querySelector('button') ||
                         el.querySelector('[role="button"]');
          if (trigger) {
            trigger.click();
            trigger.setAttribute('aria-expanded', 'true');
          }
        });
      }
    }, CONFIG.selectors);
    await page.waitForTimeout(500);
    return await page.screenshot({ fullPage: true, type: 'jpeg', quality: CONFIG.jpegQuality });
  }

  async captureModals(page) {
    const screenshots = [];
    const modalTriggers = await page.evaluate((selectors) => {
      const triggers = [];
      // Find buttons that open modals
      document.querySelectorAll('[data-modal], [data-dialog], [aria-controls]').forEach(btn => {
        triggers.push({
          selector: btn.id ? `#${btn.id}` : `[data-modal="${btn.dataset.modal || ''}"]`,
          label: btn.textContent?.trim().slice(0, 40) || 'Dialog',
        });
      });
      return triggers.slice(0, 3); // Max 3 modals
    }, CONFIG.selectors);

    for (const trigger of modalTriggers) {
      try {
        await page.click(trigger.selector, { timeout: 3000 });
        await page.waitForTimeout(500);
        screenshots.push({
          label: `Modal — ${trigger.label}`,
          buffer: await page.screenshot({ fullPage: false, type: 'jpeg', quality: CONFIG.jpegQuality }),
        });
        // Try to close
        await page.keyboard.press('Escape');
        await page.waitForTimeout(300);
      } catch { /* modal trigger failed */ }
    }
    return screenshots;
  }

  async captureMobileMenu(page) {
    const menuOpened = await page.evaluate((selectors) => {
      for (const sel of selectors.mobileMenu) {
        const el = document.querySelector(sel);
        if (el && (el.tagName === 'BUTTON' || el.matches('[class*="hamburger"]'))) {
          el.click();
          return true;
        }
      }
      // Try aria-expanded buttons
      const btn = document.querySelector('button[aria-expanded="false"]');
      if (btn) { btn.click(); return true; }
      return false;
    }, CONFIG.selectors);

    if (!menuOpened) return null;
    await page.waitForTimeout(500);
    return await page.screenshot({ fullPage: false, type: 'jpeg', quality: CONFIG.jpegQuality });
  }

  async captureLightbox(page) {
    const opened = await page.evaluate((selectors) => {
      for (const sel of selectors.lightboxes) {
        const el = document.querySelector(sel);
        if (el) {
          const link = el.closest('a') || el;
          link.click();
          return true;
        }
      }
      return false;
    }, CONFIG.selectors);

    if (!opened) return null;
    await page.waitForTimeout(800);
    const screenshot = await page.screenshot({ fullPage: false, type: 'jpeg', quality: CONFIG.jpegQuality });
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    return screenshot;
  }
}

// ─── PdfBuilder ─────────────────────────────────────────────────────────────

class PdfBuilder {
  constructor(paperFormat) {
    this.paper = CONFIG.paper[paperFormat] || CONFIG.paper.a4;
    this.margins = CONFIG.margins;
    this.pdfDoc = null;
    this.PDFDocument = null;
    this.rgb = null;
    this.StandardFonts = null;
    this.sharp = null;
    this.toc = [];
  }

  async init() {
    const pdfLib = await import('pdf-lib');
    this.PDFDocument = pdfLib.PDFDocument;
    this.rgb = pdfLib.rgb;
    this.StandardFonts = pdfLib.StandardFonts;
    this.sharp = (await import('sharp')).default;
    this.pdfDoc = await this.PDFDocument.create();
    this.font = await this.pdfDoc.embedFont(this.StandardFonts.Helvetica);
    this.fontBold = await this.pdfDoc.embedFont(this.StandardFonts.HelveticaBold);
  }

  get contentWidth() {
    return this.paper.width - this.margins.left - this.margins.right;
  }

  get contentHeight() {
    return this.paper.height - this.margins.top - this.margins.bottom - CONFIG.headerHeight;
  }

  async addCover(projectName, viewport, format, pageCount, baseUrl) {
    const page = this.pdfDoc.addPage([this.paper.width, this.paper.height]);
    const { height } = page.getSize();
    const centerX = this.paper.width / 2;

    // Project name
    const titleSize = 28;
    const titleWidth = this.fontBold.widthOfTextAtSize(projectName, titleSize);
    page.drawText(projectName, {
      x: centerX - titleWidth / 2,
      y: height - 200,
      size: titleSize,
      font: this.fontBold,
      color: this.rgb(0.15, 0.15, 0.15),
    });

    // Subtitle
    const subtitle = 'Website Capture';
    const subSize = 16;
    const subWidth = this.font.widthOfTextAtSize(subtitle, subSize);
    page.drawText(subtitle, {
      x: centerX - subWidth / 2,
      y: height - 240,
      size: subSize,
      font: this.font,
      color: this.rgb(0.4, 0.4, 0.4),
    });

    // Metadata
    const meta = [
      `Viewport: ${viewport}`,
      `Format: ${format.toUpperCase()}`,
      `Datum: ${new Date().toLocaleDateString('de-DE')}`,
      `Seiten: ${pageCount}`,
      `URL: ${baseUrl}`,
    ];

    let metaY = height - 340;
    for (const line of meta) {
      const lineWidth = this.font.widthOfTextAtSize(line, 12);
      page.drawText(line, {
        x: centerX - lineWidth / 2,
        y: metaY,
        size: 12,
        font: this.font,
        color: this.rgb(0.3, 0.3, 0.3),
      });
      metaY -= 22;
    }

    // Divider line
    page.drawLine({
      start: { x: this.margins.left + 60, y: height - 280 },
      end: { x: this.paper.width - this.margins.right - 60, y: height - 280 },
      thickness: 0.5,
      color: this.rgb(0.8, 0.8, 0.8),
    });
  }

  addTocEntry(name, label) {
    this.toc.push({
      name,
      label: label || null,
      pageNum: this.pdfDoc.getPageCount() + 1,
    });
  }

  async buildToc() {
    const page = this.pdfDoc.insertPage(1, [this.paper.width, this.paper.height]);
    const { height } = page.getSize();

    const titleSize = 18;
    page.drawText('Inhaltsverzeichnis', {
      x: this.margins.left,
      y: height - this.margins.top - 30,
      size: titleSize,
      font: this.fontBold,
      color: this.rgb(0.15, 0.15, 0.15),
    });

    let y = height - this.margins.top - 70;
    const lineHeight = 20;

    for (const entry of this.toc) {
      if (y < this.margins.bottom + 20) {
        // New TOC page if needed
        const newPage = this.pdfDoc.insertPage(
          this.pdfDoc.getPageIndices().indexOf(page) + 1,
          [this.paper.width, this.paper.height]
        );
        y = newPage.getSize().height - this.margins.top - 30;
      }

      const isSmartCapture = entry.label !== null;
      const indent = isSmartCapture ? 20 : 0;
      const displayName = isSmartCapture
        ? `↳ ${entry.label}`
        : entry.name;
      const fontSize = isSmartCapture ? 10 : 11;
      const textFont = isSmartCapture ? this.font : this.fontBold;
      const color = isSmartCapture
        ? this.rgb(0.5, 0.5, 0.5)
        : this.rgb(0.2, 0.2, 0.2);

      const truncated = displayName.length > 60
        ? displayName.slice(0, 57) + '...'
        : displayName;

      page.drawText(truncated, {
        x: this.margins.left + indent,
        y,
        size: fontSize,
        font: textFont,
        color,
      });

      // Page number right-aligned
      const pageStr = String(entry.pageNum);
      const numWidth = this.font.widthOfTextAtSize(pageStr, fontSize);
      page.drawText(pageStr, {
        x: this.paper.width - this.margins.right - numWidth,
        y,
        size: fontSize,
        font: this.font,
        color: this.rgb(0.5, 0.5, 0.5),
      });

      y -= lineHeight;
    }
  }

  async addScreenshot(buffer, pageName, label) {
    const metadata = await this.sharp(buffer).metadata();
    const imgWidth = metadata.width;
    const imgHeight = metadata.height;

    const scale = this.contentWidth / imgWidth;
    const scaledHeight = imgHeight * scale;

    if (scaledHeight <= this.contentHeight) {
      // Fits on one page
      await this.addSinglePage(buffer, pageName, label, imgWidth, imgHeight);
    } else {
      // Slice into multiple pages
      await this.addSlicedPages(buffer, pageName, label, imgWidth, imgHeight);
    }
  }

  async addSinglePage(buffer, pageName, label, imgWidth, imgHeight) {
    const page = this.pdfDoc.addPage([this.paper.width, this.paper.height]);
    const { height } = page.getSize();

    this.drawHeader(page, pageName, label);

    const scale = this.contentWidth / imgWidth;
    const scaledW = imgWidth * scale;
    const scaledH = imgHeight * scale;

    const jpgImage = await this.pdfDoc.embedJpg(buffer);
    const yPos = height - this.margins.top - CONFIG.headerHeight - (label ? CONFIG.labelHeight : 0) - scaledH;

    if (label) {
      this.drawLabel(page, label, height - this.margins.top - CONFIG.headerHeight - CONFIG.labelHeight + 4);
    }

    page.drawImage(jpgImage, {
      x: this.margins.left,
      y: Math.max(this.margins.bottom, yPos),
      width: scaledW,
      height: scaledH,
    });
  }

  async addSlicedPages(buffer, pageName, label, imgWidth, imgHeight) {
    const scale = this.contentWidth / imgWidth;
    const sliceHeightPx = Math.floor(this.contentHeight / scale);
    const totalSlices = Math.ceil(imgHeight / sliceHeightPx);

    for (let i = 0; i < totalSlices; i++) {
      const yOffset = i * sliceHeightPx;
      const currentSliceHeight = Math.min(sliceHeightPx, imgHeight - yOffset);

      const sliceBuffer = await this.sharp(buffer)
        .extract({
          left: 0,
          top: yOffset,
          width: imgWidth,
          height: currentSliceHeight,
        })
        .jpeg({ quality: CONFIG.jpegQuality })
        .toBuffer();

      const page = this.pdfDoc.addPage([this.paper.width, this.paper.height]);
      const { height } = page.getSize();

      const sliceLabel = i === 0 ? label : null;
      const headerText = i === 0 ? pageName : `${pageName} (${i + 1}/${totalSlices})`;
      this.drawHeader(page, headerText, sliceLabel);

      const scaledW = imgWidth * scale;
      const scaledH = currentSliceHeight * scale;

      const jpgImage = await this.pdfDoc.embedJpg(sliceBuffer);
      const startY = height - this.margins.top - CONFIG.headerHeight - (sliceLabel ? CONFIG.labelHeight : 0);

      if (sliceLabel) {
        this.drawLabel(page, sliceLabel, startY + 4);
      }

      page.drawImage(jpgImage, {
        x: this.margins.left,
        y: startY - scaledH,
        width: scaledW,
        height: scaledH,
      });
    }
  }

  drawHeader(page, pageName, label) {
    const { height } = page.getSize();
    const y = height - this.margins.top - 14;

    // Page name left
    const truncName = pageName.length > 50 ? pageName.slice(0, 47) + '...' : pageName;
    page.drawText(truncName, {
      x: this.margins.left,
      y,
      size: 9,
      font: this.font,
      color: this.rgb(0.5, 0.5, 0.5),
    });

    // Page number right
    const pageNum = String(this.pdfDoc.getPageCount());
    const numWidth = this.font.widthOfTextAtSize(pageNum, 9);
    page.drawText(pageNum, {
      x: this.paper.width - this.margins.right - numWidth,
      y,
      size: 9,
      font: this.font,
      color: this.rgb(0.5, 0.5, 0.5),
    });
  }

  drawLabel(page, label, y) {
    const labelWidth = this.font.widthOfTextAtSize(label, 9) + 12;
    page.drawRectangle({
      x: this.margins.left,
      y: y - 4,
      width: labelWidth,
      height: CONFIG.labelHeight - 4,
      color: this.rgb(0.93, 0.93, 0.93),
    });
    page.drawText(label, {
      x: this.margins.left + 6,
      y: y,
      size: 9,
      font: this.font,
      color: this.rgb(0.4, 0.4, 0.4),
    });
  }

  async save(outputPath) {
    const bytes = await this.pdfDoc.save();
    writeFileSync(outputPath, bytes);
    return bytes.length;
  }
}

// ─── CaptureRunner ──────────────────────────────────────────────────────────

class CaptureRunner {
  constructor(opts) {
    this.opts = opts;
    this.formFiller = new FormFiller(this.findFormDataPath());
    this.smartCapture = new SmartCapture(this.formFiller);
    this.stats = { total: 0, success: 0, failed: 0, smartCaptures: 0, errors: [] };
  }

  findFormDataPath() {
    // Look for project-local form-data.json first, then fall back to skill default
    const localPath = join(PROJECT_ROOT, 'scripts', 'form-data.json');
    if (existsSync(localPath)) return localPath;

    // Try skill config path (when installed globally)
    const homeDir = process.env.HOME || process.env.USERPROFILE;
    const skillPath = join(homeDir, '.claude', 'skills', 'capture-pdf', 'config', 'form-data.json');
    if (existsSync(skillPath)) return skillPath;

    return ''; // Will use defaults
  }

  async checkServer(url) {
    const { chromium } = await import('playwright');
    const browser = await chromium.launch({ headless: true });
    try {
      const page = await browser.newPage();
      const resp = await page.goto(url, { timeout: 10_000 });
      if (!resp || resp.status() >= 400) {
        throw new Error(`Server responded with status ${resp?.status()}`);
      }
      console.log(`Server erreichbar: ${url}`);
    } finally {
      await browser.close();
    }
  }

  async run() {
    const { opts } = this;
    const viewports = opts.viewport
      ? { [opts.viewport]: CONFIG.viewports[opts.viewport] }
      : { desktop: CONFIG.viewports.desktop };

    // Parse basic auth from URL
    let authUrl = opts.url;
    let httpCredentials = null;
    try {
      const parsed = new URL(opts.url);
      if (parsed.username && parsed.password) {
        httpCredentials = { username: parsed.username, password: parsed.password };
        parsed.username = '';
        parsed.password = '';
        authUrl = parsed.toString().replace(/\/+$/, '');
      }
    } catch {}

    // Check server
    await this.checkServer(authUrl);

    // Ensure output directory
    mkdirSync(opts.output, { recursive: true });

    const { chromium } = await import('playwright');
    const browser = await chromium.launch({ headless: true });

    try {
      for (const [vpName, vpSize] of Object.entries(viewports)) {
        console.log(`\n--- Viewport: ${vpName} (${vpSize.width}x${vpSize.height}) ---\n`);

        const pdf = new PdfBuilder(opts.format);
        await pdf.init();

        const context = await browser.newContext({
          viewport: vpSize,
          ...(httpCredentials ? { httpCredentials } : {}),
        });
        const page = await context.newPage();

        const pages = opts.pages || CONFIG.pages;
        this.stats.total = pages.length;

        // Capture pages
        for (let i = 0; i < pages.length; i++) {
          const p = pages[i];
          const pageUrl = `${authUrl}${p.path}`;
          const progress = `[${i + 1}/${pages.length}]`;

          try {
            console.log(`${progress} ${p.name} (${p.path})...`);

            await page.goto(pageUrl, {
              timeout: CONFIG.navigationTimeout,
              waitUntil: 'networkidle',
            });

            // Prepare page (remove overlays, disable animations, etc.)
            await PagePrep.prepare(page);

            // Clean screenshot
            const cleanShot = await page.screenshot({
              fullPage: true,
              type: 'jpeg',
              quality: CONFIG.jpegQuality,
            });

            pdf.addTocEntry(p.name);
            await pdf.addScreenshot(cleanShot, p.name, null);
            this.stats.success++;

            // Smart Captures
            if (opts.smart && !opts.formsOnly) {
              await this.doSmartCaptures(page, pdf, p, vpName);
            }

            // Forms-only mode
            if (opts.formsOnly) {
              const hasForms = await page.evaluate(() => {
                return document.querySelectorAll('form:not([data-no-capture]):not([role="search"])').length > 0;
              });
              if (hasForms) {
                await this.captureFormStates(page, pdf, p);
              }
            }
          } catch (err) {
            console.error(`  FEHLER: ${err.message}`);
            this.stats.failed++;
            this.stats.errors.push({ page: p.name, error: err.message });
          }
        }

        // Build TOC and cover
        await pdf.buildToc();
        await pdf.addCover(opts.name, vpName, opts.format, pages.length, authUrl);

        // Move cover to first page
        const totalPages = pdf.pdfDoc.getPageCount();
        const coverPage = pdf.pdfDoc.getPage(totalPages - 1);
        pdf.pdfDoc.removePage(totalPages - 1);
        pdf.pdfDoc.insertPage(0, coverPage);

        // Save
        const date = new Date().toISOString().split('T')[0];
        const filename = `${opts.name}-${vpName}-${date}.pdf`;
        const outputPath = join(opts.output, filename);
        const size = await pdf.save(outputPath);

        const sizeMB = (size / 1024 / 1024).toFixed(1);
        console.log(`\nPDF gespeichert: ${outputPath} (${sizeMB} MB)`);

        await context.close();
      }
    } finally {
      await browser.close();
    }

    this.printSummary();
  }

  async doSmartCaptures(page, pdf, pageInfo, vpName) {
    const elements = await this.smartCapture.detectElements(page, vpName);
    if (elements.length === 0) return;

    console.log(`  Smart Captures: ${elements.map(e => e.type).join(', ')}`);

    for (const el of elements) {
      try {
        let buffer = null;
        let screenshots = null;

        switch (el.type) {
          case 'cookie':
            buffer = await this.smartCapture.captureCookieBanner(page);
            // Re-hide cookie banner after capture
            await page.evaluate((selectors) => {
              for (const sel of selectors.cookieBanner) {
                document.querySelectorAll(sel).forEach(e => e.style.display = 'none');
              }
            }, CONFIG.selectors);
            break;

          case 'forms':
            screenshots = await this.smartCapture.captureForms(page);
            break;

          case 'accordions':
            buffer = await this.smartCapture.captureAccordions(page);
            break;

          case 'modals':
            screenshots = await this.smartCapture.captureModals(page);
            break;

          case 'mobileMenu':
            buffer = await this.smartCapture.captureMobileMenu(page);
            break;

          case 'lightboxes':
            buffer = await this.smartCapture.captureLightbox(page);
            break;
        }

        if (buffer) {
          pdf.addTocEntry(pageInfo.name, el.label);
          await pdf.addScreenshot(buffer, pageInfo.name, el.label);
          this.stats.smartCaptures++;
        }

        if (screenshots) {
          for (const ss of screenshots) {
            pdf.addTocEntry(pageInfo.name, ss.label);
            await pdf.addScreenshot(ss.buffer, pageInfo.name, ss.label);
            this.stats.smartCaptures++;
          }
        }

        // Reload page for clean state before next smart capture
        if (el.type !== 'cookie') {
          await page.goto(`${this.opts.url}${pageInfo.path}`, {
            timeout: CONFIG.navigationTimeout,
            waitUntil: 'networkidle',
          });
          await PagePrep.prepare(page);
        }
      } catch (err) {
        console.error(`  Smart Capture Fehler (${el.type}): ${err.message}`);
      }
    }
  }

  async captureFormStates(page, pdf, pageInfo) {
    try {
      // Filled form
      const formResults = await this.formFiller.fillForms(page);
      if (formResults.length === 0) return;

      await page.waitForTimeout(300);
      const filledShot = await page.screenshot({
        fullPage: true,
        type: 'jpeg',
        quality: CONFIG.jpegQuality,
      });

      const hasCaptcha = formResults.some(f => f.hasCaptcha);
      const label = hasCaptcha
        ? 'Formular — ausgefuellt (Captcha-geschuetzt)'
        : 'Formular — ausgefuellt';

      pdf.addTocEntry(pageInfo.name, label);
      await pdf.addScreenshot(filledShot, pageInfo.name, label);
      this.stats.smartCaptures++;

      // Validation
      if (!hasCaptcha) {
        const validationResults = await this.formFiller.triggerValidation(page);
        const hasErrors = validationResults.some(r => !r.valid);
        if (hasErrors) {
          await page.waitForTimeout(300);
          const validationShot = await page.screenshot({
            fullPage: true,
            type: 'jpeg',
            quality: CONFIG.jpegQuality,
          });
          pdf.addTocEntry(pageInfo.name, 'Formular — Validierung');
          await pdf.addScreenshot(validationShot, pageInfo.name, 'Formular — Validierung');
          this.stats.smartCaptures++;
        }
      }
    } catch (err) {
      console.error(`  Form Capture Fehler: ${err.message}`);
    }
  }

  printSummary() {
    console.log('\n========================================');
    console.log('Zusammenfassung');
    console.log('========================================');
    console.log(`Seiten:          ${this.stats.success}/${this.stats.total} erfolgreich`);
    console.log(`Smart Captures:  ${this.stats.smartCaptures}`);
    if (this.stats.failed > 0) {
      console.log(`Fehler:          ${this.stats.failed}`);
      for (const err of this.stats.errors) {
        console.log(`  - ${err.page}: ${err.error}`);
      }
    }
    console.log('========================================\n');
  }
}

// ─── Main ───────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\ncapture-pdf.mjs — ${CONFIG.projectName}\n`);

  await ensureDeps();
  const opts = parseArgs();
  const runner = new CaptureRunner(opts);
  await runner.run();
}

main().catch(err => {
  console.error('\nFataler Fehler:', err.message);
  process.exit(1);
});
