# How to Add a Stack

Stacks are framework-specific configurations for Claude Code. Each stack provides audit skills, templates, and CI workflows tailored to a particular framework or technology.

## Directory Structure

```
stacks/
├── astro/              # Astro (SSG) stack
│   ├── SKILL.md        # Astro-specific audit skill
│   └── templates/      # Astro project templates
├── sveltekit/          # SvelteKit (SSR) stack
│   ├── SKILL.md
│   └── templates/
├── nextjs/             # Next.js stack
│   ├── SKILL.md
│   └── templates/
├── auth/               # Authentication stack
│   └── SKILL.md
├── database/           # Database stack
│   └── SKILL.md
└── README.md           # This file
```

## Creating a New Stack

### 1. Create the Directory

```bash
mkdir stacks/my-framework
```

### 2. Add a SKILL.md

Every stack needs a `SKILL.md` file. This is the audit skill that Claude Code uses when working with projects of this type. It should contain:

- **Framework version** awareness (always check live, never hardcode)
- **Best practices** specific to the framework
- **Common pitfalls** to check for
- **Security considerations**
- **Performance guidelines**

Example structure:

```markdown
# My Framework Audit

## What This Checks
- Configuration correctness
- Security best practices
- Performance optimizations

## Checklist
1. Check framework version compatibility
2. Verify build configuration
3. Review security headers
4. Validate environment variables
...
```

### 3. Add Templates (Optional)

If your stack benefits from starter templates, add them under `templates/`:

```
stacks/my-framework/
├── SKILL.md
└── templates/
    ├── component.tsx.template
    ├── page.tsx.template
    └── config.ts.template
```

Templates use placeholder variables like `{{PROJECT_NAME}}` and `{{DESCRIPTION}}` that the setup wizard replaces.

### 4. Add a CI Template (Optional)

If the stack needs a specific CI workflow, add it to `templates/ci/`:

```bash
# Create a CI template for the stack
cp templates/ci/ci-node.yml templates/ci/ci-my-framework.yml
# Customize for framework-specific build/test commands
```

### 5. Register the Stack

Add your stack to the documentation so users can discover it. Reference it in the registry when configuring projects that use this stack.

## Guidelines

- **One SKILL.md per stack** — keep it focused on the specific framework
- **No hardcoded versions** — always instruct Claude to check versions live
- **Cross-reference** — if your stack depends on another (e.g., database + auth), reference the related stacks
- **Test your skill** — run it against a real project to verify it catches real issues

## Existing Stacks as Reference

Look at the existing stacks for examples of well-structured audit skills:

- `stacks/astro/` — Static site generation with Astro
- `stacks/sveltekit/` — Server-side rendering with SvelteKit
- `stacks/nextjs/` — Full-stack React with Next.js
- `stacks/auth/` — Authentication patterns (bcrypt, sessions)
- `stacks/database/` — Database auditing (Drizzle ORM, PostgreSQL)
