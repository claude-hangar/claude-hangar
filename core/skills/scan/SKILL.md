---
name: scan
description: Scans a project to detect tech stack, architecture, and quality indicators. Can auto-generate CLAUDE.md.
user_invocable: true
argument_hint: "[path]"
---

<!-- AI-QUICK-REF
## /scan — Quick Reference
- **Modes:** quick | full | generate
- **Arguments:** `/scan $0` e.g. `/scan quick`, `/scan full`, `/scan generate`
- **Detection:** Tech stack, frameworks, architecture, build tools, testing, CI/CD, deployment
- **Output:** Structured project profile with tech stack table + quality indicators
- **Generate mode:** Full scan + auto-generate CLAUDE.md from findings
- **No modifications:** quick and full modes are read-only (generate creates CLAUDE.md)
- **State:** .scan-profile.json in project root
- **Context Protection:** Max 5 minutes for quick, 15 minutes for full
-->

# /scan — Project Scanner

Automatically scans a project and creates a comprehensive profile. Detects tech stack,
frameworks, architecture patterns, build tools, testing setup, CI/CD, and deployment targets.
Like having a senior developer look at your project for the first time.

## Problem

Starting work on an unfamiliar project means manually exploring files, configs, and
directory structures to understand what you are dealing with. This takes time and
you often miss things. A systematic scan catches everything.

---

## 3 Modes

| Mode | Trigger | Duration | Output | Modifies files? |
|------|---------|----------|--------|-----------------|
| `quick` | `/scan` or `/scan quick` | ~30 seconds | Tech stack summary table | No |
| `full` | `/scan full` | 2-3 minutes | Complete profile with architecture assessment | No |
| `generate` | `/scan generate` | 3-5 minutes | Full scan + generate CLAUDE.md | Yes (creates CLAUDE.md) |

---

## Detection Engine

### Phase 1 — Package Manager & Language Detection

Detect the primary language and package manager first. This gates everything else.

| File/Pattern | Language | Package Manager |
|-------------|----------|-----------------|
| `package.json` | JavaScript/TypeScript | npm/yarn/pnpm |
| `package-lock.json` | — | npm |
| `yarn.lock` | — | yarn |
| `pnpm-lock.yaml` | — | pnpm |
| `bun.lockb` | — | bun |
| `requirements.txt` | Python | pip |
| `pyproject.toml` | Python | pip/poetry/pdm |
| `Pipfile` | Python | pipenv |
| `setup.py` / `setup.cfg` | Python | setuptools |
| `go.mod` | Go | go modules |
| `Cargo.toml` | Rust | cargo |
| `Gemfile` | Ruby | bundler |
| `composer.json` | PHP | composer |
| `build.gradle` / `pom.xml` | Java/Kotlin | gradle/maven |
| `*.csproj` / `*.sln` | C# / .NET | dotnet |
| `mix.exs` | Elixir | mix |
| `deno.json` / `deno.jsonc` | TypeScript (Deno) | deno |

**TypeScript detection:** If `tsconfig.json` exists or `"typescript"` is in devDependencies,
mark language as TypeScript (not just JavaScript).

### Phase 2 — Framework Detection

Read dependency files and detect frameworks with their versions.

#### Frontend Frameworks

| Dependency | Framework | Architecture |
|-----------|-----------|-------------|
| `astro` | Astro | SSG/SSR (check `output` in `astro.config.*`) |
| `next` | Next.js | SSR/SSG (check `next.config.*`) |
| `@sveltejs/kit` | SvelteKit | SSR/SSG |
| `svelte` (without kit) | Svelte | SPA |
| `react` (without next) | React | SPA |
| `vue` | Vue.js | SPA |
| `nuxt` | Nuxt | SSR/SSG |
| `@angular/core` | Angular | SPA |
| `solid-js` | SolidJS | SPA |
| `gatsby` | Gatsby | SSG |
| `remix` / `@remix-run/*` | Remix | SSR |
| `eleventy` / `@11ty/eleventy` | Eleventy | SSG |

#### Backend Frameworks

| Dependency | Framework | Type |
|-----------|-----------|------|
| `express` | Express | Node.js API |
| `fastify` | Fastify | Node.js API |
| `koa` | Koa | Node.js API |
| `hono` | Hono | Edge/Node.js API |
| `nestjs` / `@nestjs/core` | NestJS | Node.js (structured) |
| `django` | Django | Python Web |
| `flask` | Flask | Python API |
| `fastapi` | FastAPI | Python API |
| `gin-gonic/gin` (go.mod) | Gin | Go API |
| `echo` (go.mod) | Echo | Go API |
| `actix-web` (Cargo.toml) | Actix Web | Rust API |
| `axum` (Cargo.toml) | Axum | Rust API |
| `laravel` (composer.json) | Laravel | PHP Web |
| `rails` (Gemfile) | Ruby on Rails | Ruby Web |

#### CSS Frameworks

| Dependency / File | Framework |
|-------------------|-----------|
| `tailwindcss` | Tailwind CSS |
| `@tailwindcss/vite` or `@tailwindcss/postcss` | Tailwind CSS v4 |
| `bootstrap` | Bootstrap |
| `@mantine/core` | Mantine |
| `@chakra-ui/react` | Chakra UI |
| `sass` / `*.scss` files | Sass/SCSS |
| `styled-components` | Styled Components |

### Phase 3 — Architecture Pattern Detection

Determine architecture from framework config and project structure.

| Pattern | How to detect |
|---------|---------------|
| **SSG** | Astro `output: 'static'`, Next.js `output: 'export'`, Eleventy, Hugo |
| **SSR** | Astro `output: 'server'/'hybrid'`, Next.js (default), SvelteKit, Nuxt |
| **SPA** | React/Vue/Angular without SSR framework, `index.html` entry |
| **API** | Express/Fastify/Flask/FastAPI without frontend |
| **Full-Stack** | SSR framework + database ORM in same project |
| **CLI** | `"bin"` in package.json, or `src/cli.*`, `__main__.py` |
| **Library** | `"main"` / `"exports"` in package.json, no bin, no framework |
| **Monorepo** | `workspaces` in package.json, `pnpm-workspace.yaml`, `turbo.json`, `nx.json` |
| **Microservices** | Multiple `Dockerfile`s, `docker-compose.yml` with 3+ services |
| **Serverless** | `serverless.yml`, `vercel.json`, `netlify.toml` with functions |

### Phase 4 — Build Tool Detection

| File/Dependency | Build Tool |
|----------------|------------|
| `vite.config.*` | Vite |
| `webpack.config.*` | Webpack |
| `esbuild` in deps or `esbuild.config.*` | esbuild |
| `turbo.json` | Turborepo |
| `nx.json` | Nx |
| `rollup.config.*` | Rollup |
| `tsup` in deps | tsup |
| `swc` in deps or `.swcrc` | SWC |

### Phase 5 — Testing Setup Detection

| File/Dependency | Testing Tool | Type |
|----------------|-------------|------|
| `vitest` or `vitest.config.*` | Vitest | Unit/Integration |
| `jest` or `jest.config.*` | Jest | Unit/Integration |
| `playwright` or `playwright.config.*` | Playwright | E2E |
| `cypress` or `cypress.config.*` | Cypress | E2E |
| `pytest` or `conftest.py` | pytest | Unit/Integration |
| `mocha` | Mocha | Unit |
| `@testing-library/*` | Testing Library | Component |
| `.nycrc` or `c8` or `istanbul` | Coverage tool | Coverage |
| `storybook` or `.storybook/` | Storybook | Visual/Component |

**Quality signals from tests:**
- Count test files: `**/*.test.*`, `**/*.spec.*`, `**/test_*.py`, `**/*_test.go`
- Estimate test coverage config presence
- Check for CI test integration (tests in workflow files)

### Phase 6 — CI/CD Detection

| File/Directory | CI/CD Platform |
|---------------|----------------|
| `.github/workflows/*.yml` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `Jenkinsfile` | Jenkins |
| `.circleci/config.yml` | CircleCI |
| `.travis.yml` | Travis CI |
| `bitbucket-pipelines.yml` | Bitbucket Pipelines |
| `.drone.yml` | Drone CI |
| `azure-pipelines.yml` | Azure DevOps |

**Workflow analysis (GitHub Actions):**
- Count workflow files
- Detect triggers (push, PR, schedule, manual)
- Identify steps: test, lint, build, deploy, security scan

### Phase 7 — Deployment Target Detection

| File/Config | Deployment Target |
|------------|-------------------|
| `Dockerfile` | Docker |
| `docker-compose.yml` / `docker-compose.yaml` | Docker Compose |
| `vercel.json` or `.vercel/` | Vercel |
| `netlify.toml` or `_redirects` | Netlify |
| `fly.toml` | Fly.io |
| `render.yaml` | Render |
| `railway.json` or `railway.toml` | Railway |
| `Procfile` | Heroku |
| `*.tf` files | Terraform (IaC) |
| `ansible/` or `playbook.yml` | Ansible |
| `k8s/` or `kubernetes/` or `*.k8s.yml` | Kubernetes |
| `serverless.yml` | Serverless Framework |
| `wrangler.toml` | Cloudflare Workers |

### Phase 8 — Project Health Indicators

Check for the existence and quality of these files:

| File | Category | Quality Check |
|------|----------|---------------|
| `CLAUDE.md` | AI Dev Config | Exists? Content meaningful (>10 lines)? |
| `README.md` | Documentation | Exists? Has setup instructions? |
| `.editorconfig` | Code Style | Exists? |
| `.prettierrc` / `biome.json` / `.eslintrc.*` | Linting/Formatting | Exists? Configured? |
| `LICENSE` | Legal | Exists? Which license? |
| `CHANGELOG.md` | Versioning | Exists? |
| `CONTRIBUTING.md` | Open Source | Exists? |
| `.gitignore` | Git | Exists? Comprehensive? |
| `.env.example` | Config | Exists (when `.env` patterns in .gitignore)? |
| `.nvmrc` / `.node-version` / `.python-version` | Version Pinning | Exists? |
| `renovate.json` / `dependabot.yml` | Dependency Updates | Automated? |

### Phase 9 — Codebase Metrics

Gather quantitative data about the project:

```
Count:
- Total files (excluding node_modules, .git, dist, build, __pycache__)
- Total directories
- Lines of code (approximate — count lines in source files)
- Source files by extension (top 5)
- Largest files (top 5 by line count)
```

**Method:** Use `find` + `wc` or glob patterns. Exclude common vendor/build directories.

---

## Mode: quick

Fast scan — just the essentials. Run Phases 1-4 only.

### Procedure

1. Run Phase 1 (Language/Package Manager)
2. Run Phase 2 (Framework Detection)
3. Run Phase 3 (Architecture Pattern)
4. Run Phase 4 (Build Tools)
5. Output summary table
6. Write `.scan-profile.json`

### Output Format

```
Project Scan: {directory-name}
============================================

Tech Stack:
+-----------------+---------------------+---------+
| Category        | Detected            | Version |
+-----------------+---------------------+---------+
| Language        | TypeScript          | 5.x     |
| Package Manager | pnpm               | 9.x     |
| Framework       | Astro              | 5.17.2  |
| CSS             | Tailwind CSS       | 4.2     |
| Build Tool      | Vite               | 6.x     |
| Architecture    | SSG                | —       |
+-----------------+---------------------+---------+

Quick Assessment: Static site built with Astro + Tailwind.
Modern stack, well-suited for content-heavy websites.
```

---

## Mode: full

Complete analysis — all 9 phases.

### Procedure

1. Run all 9 detection phases
2. Compile findings into structured profile
3. Assess overall project health
4. Output detailed report
5. Write `.scan-profile.json`

### Output Format

```
Project Scan: {directory-name}
============================================

TECH STACK:
+-----------------+---------------------+---------+
| Category        | Detected            | Version |
+-----------------+---------------------+---------+
| Language        | TypeScript          | 5.7     |
| Package Manager | pnpm               | 9.15    |
| Framework       | SvelteKit          | 2.x     |
| CSS             | Tailwind CSS v4    | 4.2     |
| Database        | PostgreSQL (Drizzle)| —       |
| Build Tool      | Vite               | 6.x     |
| Architecture    | Full-Stack SSR     | —       |
+-----------------+---------------------+---------+

TESTING:
  Vitest (unit) — 23 test files found
  Playwright (E2E) — config present, 5 spec files
  Coverage: c8 configured

CI/CD:
  GitHub Actions — 2 workflows
    - ci.yml: test + lint + build (on push/PR)
    - deploy.yml: Docker build + deploy (on tag)

DEPLOYMENT:
  Docker (Dockerfile + docker-compose.yml)
  Target: VPS (inferred from deploy workflow)

QUALITY INDICATORS:
  [pass] README.md — comprehensive (setup + usage + deploy)
  [pass] .gitignore — well-configured
  [pass] TypeScript strict mode
  [pass] ESLint + Prettier configured
  [pass] CI runs tests on PR
  [miss] No CLAUDE.md
  [miss] No .editorconfig
  [miss] No CHANGELOG.md
  [miss] No dependency update automation (Dependabot/Renovate)

CODEBASE METRICS:
  Files: 142 source files
  Lines: ~8,400 lines of code
  Top extensions: .svelte (45), .ts (38), .css (12)
  Directories: 28

HEALTH SCORE: 7/10
  Strong: Modern stack, good test coverage, CI in place
  Gaps: Missing CLAUDE.md, no changelog, no automated dep updates
```

### Health Score Calculation

| Category | Weight | Criteria |
|----------|--------|----------|
| Stack Modernity | 15% | Current framework versions, modern tools |
| Testing | 20% | Test files present, coverage configured, multiple test types |
| CI/CD | 15% | Workflows exist, test integration, automated deploys |
| Documentation | 15% | README quality, CLAUDE.md, inline docs |
| Code Quality | 15% | Linting, formatting, TypeScript, .editorconfig |
| Security | 10% | .gitignore comprehensive, no secrets, dep update automation |
| Project Hygiene | 10% | LICENSE, CHANGELOG, version pinning, .env.example |

Score 1-10: Each category contributes its weighted portion.

---

## Mode: generate

Full scan + generate a CLAUDE.md tailored to the project.

### Procedure

1. Run full scan (all 9 phases)
2. Check if CLAUDE.md already exists
   - If exists: Ask user whether to overwrite or skip
3. Generate CLAUDE.md based on scan results
4. Output scan report + generated file path

### CLAUDE.md Generation Template

The generated CLAUDE.md should include:

```markdown
# {Project Name}

## What Is This?

{Auto-generated description based on framework + architecture + purpose}

## Tech Stack

{Table from scan results — framework, language, CSS, database, etc.}

## Project Structure

{Key directories and their purpose, based on detected patterns}

## Development

### Setup
{Based on detected package manager: npm/pnpm/yarn install, etc.}

### Dev Server
{Based on framework: npm run dev, etc.}

### Build
{Based on framework: npm run build, etc.}

### Test
{Based on detected test runner: npm test, npx vitest, etc.}

## Conventions

{Based on detected linter/formatter: ESLint rules, Prettier config, etc.}
{Based on detected TypeScript: strict mode, path aliases, etc.}

## Deployment

{Based on detected deployment target: Docker, Vercel, etc.}
```

**Rules for generation:**
- Only include sections where data was actually detected
- Keep it concise — CLAUDE.md should be scannable, not a novel
- Use concrete commands from package.json scripts
- Do not invent information — only what was detected
- If `scripts` exist in package.json, extract the relevant ones

---

## State File (.scan-profile.json)

Written after every scan. Used by `/consult` and other skills as input.

```json
{
  "version": "1.0",
  "scanDate": "2026-03-20",
  "mode": "full",
  "project": "my-project",
  "language": {
    "primary": "typescript",
    "version": "5.7",
    "secondary": []
  },
  "packageManager": "pnpm",
  "framework": {
    "name": "sveltekit",
    "version": "2.x",
    "config": "svelte.config.js"
  },
  "css": {
    "framework": "tailwindcss",
    "version": "4.2",
    "variant": "v4"
  },
  "architecture": "full-stack-ssr",
  "buildTool": "vite",
  "testing": {
    "unit": { "tool": "vitest", "fileCount": 23 },
    "e2e": { "tool": "playwright", "fileCount": 5 },
    "coverage": "c8"
  },
  "cicd": {
    "platform": "github-actions",
    "workflows": ["ci.yml", "deploy.yml"]
  },
  "deployment": {
    "targets": ["docker", "vps"],
    "files": ["Dockerfile", "docker-compose.yml"]
  },
  "qualityIndicators": {
    "readme": true,
    "claudeMd": false,
    "editorconfig": false,
    "linting": "eslint",
    "formatting": "prettier",
    "typescript": true,
    "typescriptStrict": true,
    "gitignore": true,
    "license": "MIT",
    "changelog": false,
    "envExample": true,
    "versionPinning": ".nvmrc",
    "depAutomation": null
  },
  "metrics": {
    "sourceFiles": 142,
    "linesOfCode": 8400,
    "directories": 28,
    "topExtensions": {
      ".svelte": 45,
      ".ts": 38,
      ".css": 12,
      ".json": 8,
      ".md": 5
    }
  },
  "healthScore": 7
}
```

---

## Integration with Other Skills

### State as Contract

| Relationship | Description |
|-------------|-------------|
| `/consult` reads `.scan-profile.json` | Consult uses scan results to ask targeted questions |
| `/project-audit` can skip detection | If `.scan-profile.json` exists, project-audit can use it for Phase 01-02 |
| `/polish` can read stack info | Stack detection helps polish load correct supplements |

### Smart Next Steps

After a scan, recommend based on findings:

| Condition | Recommendation |
|-----------|---------------|
| No CLAUDE.md found | "Run `/scan generate` to create one" (if in quick/full mode) |
| No tests found | "Consider `/consult` to plan a testing strategy" |
| Outdated deps detected | "Run `/consult quick` for improvement recommendations" |
| Project looks healthy | "Run `/project-audit` for a thorough code review" |
| Always | "Run `/consult` for a guided improvement plan" |

---

## Rules

1. **Read-only in quick and full modes** — Never modify project files
2. **Detection over assumption** — Only report what is actually found in files
3. **Version accuracy** — Read versions from lock files or dependency declarations, never guess
4. **Exclude vendor directories** — Always skip `node_modules`, `.git`, `dist`, `build`, `__pycache__`, `vendor`, `.next`, `.svelte-kit`, `.astro`
5. **No runtime checks in quick mode** — Quick mode reads files only, no `npm`, `node`, `python` commands
6. **Full mode can use runtime** — `node -v`, `python --version` etc. are allowed in full mode
7. **Idempotent** — Running scan twice produces the same result
8. **State is optional** — Other skills should work without `.scan-profile.json`, it is a bonus
9. **Anti-rationalization** — Do not skip phases because the project "looks simple". See `_shared/anti-rationalization.md`

---

## Files

```
scan/
└── SKILL.md    <- This file
```
