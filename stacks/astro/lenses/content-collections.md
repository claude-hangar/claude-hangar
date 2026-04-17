---
name: content-collections
stack: astro
category: data
effort_min: 2
effort_max: 8
---

# Lens: Content Collections Health

Single-concern audit of Astro Content Collections: schema quality, typing, and query patterns.

## What this lens checks

1. **Schema coverage** — every `src/content/<collection>/` has a matching `defineCollection` entry in `src/content/config.ts`.
2. **Zod strictness** — schemas use `z.object({...}).strict()` or equivalent to catch typos in frontmatter.
3. **Required fields** — `title`, `description`, `pubDate` (or equivalent) are required and non-empty.
4. **Slug hygiene** — no collisions; slugs derived from filename, not a mutable frontmatter field.
5. **Type inference** — consumers use `CollectionEntry<'name'>` instead of hand-rolled types.
6. **Query performance** — `getCollection()` called at top of page, not inside render loops.

## Signals to extract

- Count collections, entries per collection
- Entries missing required fields (list filenames)
- Schemas without `.strict()`
- Pages calling `getCollection()` inside loops

## Report template

```markdown
### Content Collections Lens — {collection_name}
- Entries: {N} (missing required: {M})
- Schema strictness: strict | loose
- Type inference: typed | untyped
- Top 3 issues:
  1. {issue with file:line}
```

## Severity mapping

- CRITICAL — missing `config.ts` entry for existing folder
- HIGH — schema `z.any()` or `z.unknown()` without narrowing
- MEDIUM — schema not `.strict()`
- LOW — type inference not used
