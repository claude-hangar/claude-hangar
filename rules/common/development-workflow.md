# Development Workflow

Structured 5-phase workflow for any non-trivial change. Each phase has
specific tools and outputs.

## The 5 Phases

### Phase 0: Research & Reuse (Before Writing Code)

Before implementing anything:

1. **Search for existing solutions** — `gh search repos`, `gh search code`
2. **Check vendor documentation** — Context7 or primary sources
3. **Query package registries** — npm, PyPI, crates.io, Maven
4. **Evaluate open-source options** — Adopt if it covers 80%+ of requirements

**Output:** Decision on build vs. adopt, with justification.

### Phase 1: Plan

For complex features (3+ files, architectural changes):

1. Use **planner agent** for implementation strategy
2. Identify dependencies and risks
3. Break work into independently testable steps
4. Get approval before proceeding

**Output:** Implementation plan with phases and success criteria.

### Phase 2: TDD

For every code change:

1. **RED** — Write failing test first
2. **GREEN** — Write minimum code to pass
3. **IMPROVE** — Refactor while tests stay green
4. Verify 80%+ coverage

Use **tdd-guide agent** for enforcement.

**Output:** Passing tests with adequate coverage.

### Phase 3: Review

After implementation:

1. Use **code-reviewer agent** for quality check
2. Fix CRITICAL and HIGH severity issues
3. Address MEDIUM issues where feasible
4. Use language-specific reviewers for targeted feedback

**Output:** Review-approved code.

### Phase 4: Commit & Verify

1. `git status` + `git diff` before committing
2. Conventional Commit format
3. Run `/verify` (verification-loop) before PR
4. Push with `-u` for new branches

**Output:** Clean commit history, passing CI.

## When to Skip Phases

| Change Type | Skip | Reason |
|-------------|------|--------|
| Typo fix | Phases 0-1 | Obvious, no architecture impact |
| Bug fix | Phase 0 | Still needs TDD (reproduce with test) |
| Config change | Phases 0, 2 | May not need tests, but needs review |
| New feature | None | Full workflow always |
| Refactoring | Phase 0 | Existing tests must pass throughout |
