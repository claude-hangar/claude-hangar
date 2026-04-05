# Questioning Style

> Shared behavioral reference for all skills and agents.
> Referenced by: agent prompts, skill instructions, governance rules.
> Location: `core/references/questioning.md`

## Principles

1. **Ask before assuming** — When intent is ambiguous, ask. Do not guess.
2. **Recommended option first** — AskUserQuestion must always place the recommended option as the first choice, with a brief justification.
3. **Max 3 questions per round** — Batch related questions. If more than 3 are needed, prioritize and defer the rest.
4. **Specific, not open-ended** — Ask "Should the sidebar use fixed or sticky positioning?" not "How should the sidebar work?"
5. **Binary decisions: recommend + tradeoff** — State which option you recommend and what the tradeoff is. Let the user override, not decide from scratch.
6. **No permission theater** — Never ask "Do you want me to proceed?" or "Shall I continue?" State what you will do next and do it. Exception: destructive or irreversible operations (data deletion, force-push, production deployment).

## Examples

### Good

> I'll add the auth middleware to all `/api/` routes. Two questions:
>
> 1. **Session duration** — 7 days (recommended, standard for web apps) or 30 days (more convenient, higher risk)?
> 2. **Rate limiting** — 100 req/min per IP (recommended) or custom value?

### Bad

> How would you like me to handle authentication? Should I proceed with adding middleware? What session duration do you prefer? Do you want rate limiting? Should I also add CSRF protection? Want me to update the tests?
