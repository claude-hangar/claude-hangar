# Project Audit: Quick-Fix Templates

## Fix Protocol (v4.9 — MANDATORY)

Every fix must go through this 5-step protocol:

```
1. IDENTIFY  — Name finding-ID + location (e.g. QUAL-03, src/utils.ts:120)
2. RUN       — Implement fix (change code, set config)
3. READ      — Re-read the changed file (NOT from memory!)
4. VERIFY    — Test (tsc, npm test, build, etc.)
5. CLAIM     — Only now mark as "fixed" in state
```

**Step 3 (READ) and 4 (VERIFY) must NEVER be skipped.**

---

Ready-made fix templates for common findings. For each fix:
1. Show template, 2. Get user confirmation, 3. Implement, 4. Verify (5-step protocol).

---

## STRUC — Structure & Architecture

### STRUC: God-File (>500 lines)

```
# Split by responsibility:
# 1. Identify functions that belong together
# 2. Extract into separate modules
# 3. Re-export via index.ts/js

# Example:
# utils.ts (800 lines) >
#   utils/string.ts
#   utils/date.ts
#   utils/validation.ts
#   utils/index.ts (re-exports)
```

**Verify:** No file >500 lines? Imports work?

### STRUC: Missing Folder Structure

```
# Recommended minimal structure:
project/
├── src/           # Source code
├── tests/         # Tests
├── docs/          # Documentation
├── scripts/       # Build/deploy scripts
├── .github/       # CI/CD
├── package.json   # Dependencies
├── tsconfig.json  # TypeScript config
├── README.md      # Project description
└── .gitignore     # Git exclusions
```

---

## DEP — Dependencies

### DEP: Outdated Dependencies with CVE

```bash
# Check vulnerabilities
npm audit

# Automatic fixes (patch/minor)
npm audit fix

# Individual major updates (check manually!)
npm install packagename@latest

# Update all to latest (interactive)
npx npm-check-updates -i
```

**Verify:**
```bash
npm audit
# Expected: 0 vulnerabilities
```

### DEP: Missing engines in package.json

```json
{
  "engines": {
    "node": ">=24.0.0"
  }
}
```

**Verify:**
```bash
node -v
# Output must match engines in package.json
```

### DEP: Lock File Not Committed

```bash
# package-lock.json MUST be in repo
git add package-lock.json
git commit -m "fix: add package-lock.json to repo"

# Check .gitignore — lock file NOT ignored?
```

### DEP: Corepack + packageManager Setup

```bash
# 1. Enable Corepack (integrated in Node 22+)
corepack enable

# 2. Set packageManager in package.json
# Check current npm version:
npm --version
# Then add to package.json:
```

```json
{
  "packageManager": "npm@10.9.2"
}
```

```bash
# 3. Update CI/CD (.github/workflows/*.yml)
# Before npm ci/install:
- run: corepack enable

# 4. Update Dockerfile
# After FROM node:24-alpine:
RUN corepack enable
```

**Effect:** Enforces identical package manager version across all environments.
If someone installs with the wrong version > error instead of silent inconsistency.

**Verify:**
```bash
corepack enable && npm --version
# Output must match version in package.json packageManager
```

---

## QUAL — Code Quality

### QUAL: Missing Type Annotations

```json
// tsconfig.json — stricter
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noUncheckedIndexedAccess": true
  }
}
```

**Verify:**
```bash
tsc --noEmit
# Expected: no errors
```

### QUAL: Commented-Out Code

```bash
# Find:
grep -rn '^\s*//.*TODO\|^\s*//.*FIXME\|^\s*//.*HACK' src/
# Also larger commented-out blocks:
grep -rn '^\s*/\*' src/ | head -20

# Fix: Delete. Git has the history.
```

### QUAL: Missing Linting Config

```bash
# Biome (faster than ESLint, all-in-one)
npm install --save-dev @biomejs/biome
npx biome init

# Or ESLint + Prettier
npm install --save-dev eslint prettier
```

---

## GIT — Git & Versioning

### GIT: Missing .gitignore

```gitignore
# Node
node_modules/
dist/
.env
.env.*
!.env.example

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/settings.json
.idea/

# Build
*.tsbuildinfo
coverage/

# Docker
docker-compose.override.yml
```

### GIT: Secrets in Git History

```bash
# 1. Identify secret
git log --all -p -- .env

# 2. Remove with git-filter-repo (better than BFG)
pip install git-filter-repo
git filter-repo --path .env --invert-paths

# 3. Force push (CAUTION — coordinate with team!)
git push --force-with-lease

# 4. Rotate secret! (API key, password, etc.)
```

**IMPORTANT:** ALWAYS rotate the secret — it is compromised the moment it was in the repo.

### GIT: Clean Up Stale Branches

```bash
# Check remote branches that are merged
git branch -r --merged main | grep -v main

# Clean up locally
git fetch --prune
git branch --merged main | grep -v main | xargs git branch -d
```

---

## CICD — CI/CD & Automation

### CICD: Missing CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.nvmrc'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - run: npm test
```

### CICD: Insecure GitHub Actions Permissions

```yaml
# Before (too open):
permissions: write-all

# After (principle of least privilege):
permissions:
  contents: read
  pull-requests: write  # only if needed
```

### CICD: Missing Dependabot Config

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### CICD: OIDC Instead of Secrets (GitHub Actions > AWS)

```yaml
# Before: Long-lived AWS keys as repository secrets
# env:
#   AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
#   AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

# After: OIDC token (short-lived, no secret management)
name: Deploy
on: push
permissions:
  id-token: write   # Request OIDC token
  contents: read
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@a5ac7e51b41094c92402da3b24376905380afc29
      - uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502
        with:
          role-to-assume: arn:aws:iam::123456789:role/github-deploy
          aws-region: eu-central-1
      - run: aws s3 sync dist/ s3://bucket/
```

**Prerequisite:** AWS IAM role configured with GitHub OIDC provider.
Analogous for GCP (`google-github-actions/auth`), Azure (`azure/login`).

**Verify:** Repository secrets removed? Workflow runs with OIDC?

### CICD: Artifact Attestation

```yaml
# Generate build provenance for artifacts (SLSA Level 2+)
name: Build & Attest
on: push
permissions:
  id-token: write
  contents: read
  attestations: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@a5ac7e51b41094c92402da3b24376905380afc29
      - run: npm ci && npm run build
      - uses: actions/attest-build-provenance@ef244123eb79f2f7a7e75d99086184a8f949f4ed
        with:
          subject-path: 'dist/**'
```

**Verify:**
```bash
gh attestation verify dist/file
# Expected: signature valid
```

---

## DOC — Documentation

### DOC: Missing README

```markdown
# Project Name

Brief description in 1-2 sentences.

## Quick Start

\`\`\`bash
git clone ...
npm install
npm run dev
\`\`\`

## Architecture

- **Frontend:** Astro + Tailwind
- **Backend:** Fastify
- **Deployment:** Docker + Traefik

## Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start dev server |
| `npm run build` | Production build |
| `npm test` | Run tests |

## Deployment

\`\`\`bash
docker compose up -d
\`\`\`
```

### DOC: Missing .env.example

```bash
# .env.example — placeholders instead of real values
DATABASE_URL=sqlite:./data/app.db
PORT=3000
NODE_ENV=development
# SECRET_KEY=<generate-with-openssl-rand-base64-32>
```

---

## TEST — Testing

### TEST: No Tests Present

```bash
# Vitest setup (fast, Vite-compatible)
npm install --save-dev vitest

# package.json
# "scripts": { "test": "vitest run" }

# First test file:
# tests/example.test.ts
```

```typescript
// tests/example.test.ts
import { describe, it, expect } from 'vitest';

describe('Example', () => {
  it('should work', () => {
    expect(1 + 1).toBe(2);
  });
});
```

### TEST: Missing Test Coverage

```json
// vitest.config.ts
{
  "test": {
    "coverage": {
      "provider": "v8",
      "reporter": ["text", "html"],
      "thresholds": {
        "statements": 70,
        "branches": 70,
        "functions": 70,
        "lines": 70
      }
    }
  }
}
```

---

## SEC — Security

### SEC: Hardcoded Secrets

```javascript
// Before:
const API_KEY = 'sk-xxx-replace';

// After:
const API_KEY = process.env.API_KEY;
if (!API_KEY) throw new Error('API_KEY not set');
```

```bash
# .env
API_KEY=sk-xxx-replace

# .env.example
API_KEY=<your-api-key>
```

### SEC: Missing Input Validation (Fastify)

```javascript
// JSON Schema on the route
fastify.post('/api/contact', {
  schema: {
    body: {
      type: 'object',
      required: ['name', 'email', 'message'],
      properties: {
        name: { type: 'string', minLength: 1, maxLength: 100 },
        email: { type: 'string', format: 'email' },
        message: { type: 'string', minLength: 1, maxLength: 5000 }
      },
      additionalProperties: false
    }
  }
}, handler);
```

### SEC: Generate SBOM (CycloneDX)

```bash
# Locally: generate SBOM from npm project
npx @cyclonedx/cyclonedx-npm --output-file sbom.json

# Alternative: SPDX format
npx @cyclonedx/cyclonedx-npm --output-file sbom.json --spec-version 1.5
```

```yaml
# In CI (GitHub Actions):
- name: Generate SBOM
  run: npx @cyclonedx/cyclonedx-npm --output-file sbom.json
- name: Upload SBOM
  uses: actions/upload-artifact@SHA
  with:
    name: sbom-${{ github.sha }}
    path: sbom.json
    retention-days: 90
```

```bash
# Container SBOM (Docker):
docker scout sbom image:tag --format cyclonedx > container-sbom.json
# Or during build:
docker buildx build --sbom=true -t image:tag .
```

**Verify:**
```bash
ls -la sbom.json
cat sbom.json | node -e "const d=require('fs').readFileSync('/dev/stdin','utf8');const j=JSON.parse(d);console.log('Components:',j.components?.length||0)"
# Expected: sbom.json exists, Components > 0
```

---

## DEPLOY — Deployment

### DEPLOY: Missing Health Check Endpoint

```javascript
// Fastify
fastify.get('/health', async () => ({
  status: 'ok',
  uptime: process.uptime(),
  timestamp: new Date().toISOString()
}));
```

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://localhost:3000/health || exit 1
```

### DEPLOY: Missing Restart Policy

```yaml
# docker-compose.yml
services:
  web:
    restart: unless-stopped
    # NOT 'always' — otherwise restarts endlessly on config error
```

### DEPLOY: No Rollback Possible

```bash
# Image tagging strategy
docker tag app:latest app:$(date +%Y%m%d-%H%M)
# For rollback:
docker compose down
# docker-compose.yml > set image to old tag
docker compose up -d
```

---

## MAINT — Maintenance

### MAINT: Outdated Node Version

```bash
# Create/update .nvmrc (v24 = Active LTS, v22 = Maintenance LTS)
echo "24" > .nvmrc

# Update Dockerfile
# FROM node:18-alpine  >  FROM node:24-alpine

# Update CI
# node-version: '18'  >  node-version-file: '.nvmrc'
```

**Verify:**
```bash
node -v
cat .nvmrc
# Both must match; also check CI/Docker
```

### MAINT: Missing Changelog

```markdown
# CHANGELOG.md

## [Unreleased]

### Added
- ...

### Changed
- ...

### Fixed
- ...

## [1.0.0] - YYYY-MM-DD

### Added
- Initial release
```

Or automatically with Conventional Commits:
```bash
npx conventional-changelog-cli -p angular -i CHANGELOG.md -s
```
