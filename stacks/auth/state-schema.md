# Auth Audit — State Schema v2.1

State file: `.auth-audit-state.json`

```json
{
  "version": 2.1,
  "created": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DD",
  "project": "Project name",
  "framework": "sveltekit|express|fastify|astro",
  "hashingLib": "bcryptjs|argon2|bcrypt",
  "sessionType": "db-sessions|cookie-sessions|jwt",
  "database": "postgresql|sqlite|none",
  "areas": {
    "HASH": {
      "status": "done",
      "session": 1,
      "findingsCount": 2,
      "completeness": {
        "checksTotal": 5,
        "checksExecuted": 5,
        "checksSkipped": [],
        "mustTotal": 4,
        "mustExecuted": 4,
        "mustCompleteness": 100,
        "overallCompleteness": 100
      },
      "layers": { "source": "done", "runtime": "done" }
    },
    "SESS": {
      "status": "in-progress",
      "session": 2,
      "findingsCount": 0,
      "completeness": null,
      "layers": { "source": "pending", "runtime": "pending" }
    },
    "CSRF": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "COOK": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "REG": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "LOGIN": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "RESET": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "AUTHZ": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "STORE": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "LOG": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null }
  },
  "summary": {
    "total": 2,
    "critical": 0,
    "high": 1,
    "medium": 1,
    "low": 0,
    "fixed": 0,
    "skipped": 0
  },
  "findings": [
    {
      "id": "AUTH-01",
      "area": "HASH",
      "severity": "CRITICAL",
      "title": "Short title",
      "description": "What is the problem",
      "location": "File or area",
      "owasp": "ASVS 2.4.4",
      "status": "open",
      "fixedIn": null,
      "notes": ""
    }
  ],
  "history": [
    {
      "date": "YYYY-MM-DD",
      "session": 1,
      "areas": ["HASH", "SESS"],
      "findingsAdded": 2,
      "findingsFixed": 0
    }
  ]
}
```

## State Migration v1 -> v2.1

When a `.auth-audit-state.json` with `"version": 1` is found:

1. Set `version` to `2.1`
2. Add `completeness: null` to each area (if not present)
3. Migrate layer status from bool to string enum: `true` -> `"done"`, `false` -> `"pending"`, `null` -> `null`
4. Existing areas with `layers: { "source": "pending", "runtime": "pending" }` -> set to `null` for areas not yet started
5. Keep `history[]` as-is (format is compatible)
6. Keep `owasp` field in findings (auth-audit-specific)
7. Inform user: "State migrated from v1 to v2.1 (completeness tracking + layer format)."
