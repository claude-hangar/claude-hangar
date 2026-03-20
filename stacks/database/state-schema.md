# DB Audit — State Schema v2.1

State file: `.db-audit-state.json`

```json
{
  "version": 2.1,
  "created": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DD",
  "project": "Project name",
  "drizzleOrmVersion": "0.38.x",
  "drizzleKitVersion": "0.30.x",
  "postgresVersion": "17.x",
  "connectionType": "docker|managed|local",
  "framework": "sveltekit|astro|nextjs|standalone",
  "schemaPath": "src/lib/server/db/schema/",
  "areas": {
    "ENV": {
      "status": "done",
      "session": 1,
      "findingsCount": 2,
      "completeness": {
        "checksTotal": 6,
        "checksExecuted": 6,
        "checksSkipped": [],
        "mustTotal": 3,
        "mustExecuted": 3,
        "mustCompleteness": 100,
        "overallCompleteness": 100
      },
      "layers": { "source": "done", "runtime": "done" }
    },
    "SCHEMA": {
      "status": "in-progress",
      "session": 2,
      "findingsCount": 0,
      "completeness": null,
      "layers": { "source": "pending", "runtime": "pending" }
    },
    "MIG": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "CONN": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "QUERY": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "SEC": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "PERF": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "BAK": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "TOOL": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "INT": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null }
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
      "id": "DB-01",
      "area": "ENV",
      "severity": "CRITICAL",
      "title": "Short title",
      "description": "What is the problem",
      "location": "File or area",
      "status": "open",
      "fixedIn": null,
      "notes": ""
    }
  ],
  "history": [
    {
      "date": "YYYY-MM-DD",
      "session": 1,
      "areas": ["ENV", "SCHEMA"],
      "findingsAdded": 2,
      "findingsFixed": 0
    }
  ]
}
```

## State Migration v1 -> v2.1

When a `.db-audit-state.json` with `"version": 1` is found:

1. Set `version` to `2.1`
2. Add `completeness: null` to each area (if not present)
3. Migrate layer status from bool to string enum: `true` -> `"done"`, `false` -> `"pending"`, `null` -> `null`
4. Existing areas with `layers: { "source": "pending", "runtime": "pending" }` -> set to `null` for areas not yet started
5. Keep `history[]` as-is (format is compatible)
6. Inform user: "State migrated from v1 to v2.1 (completeness tracking + layer format)."
