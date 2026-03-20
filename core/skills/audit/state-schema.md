# Audit — State Schema v2.1

State file: `.audit-state.json`

```json
{
  "version": 2.1,
  "created": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DD",
  "project": "{{PROJECT_NAME}}",
  "detectedStack": {
    "frontend": { "name": "astro", "version": "6.x" },
    "css": { "name": "tailwind-v4", "version": "4.x" },
    "backend": null,
    "deployment": [
      { "name": "docker", "version": null },
      { "name": "traefik", "version": "3.x" }
    ],
    "database": null,
    "testing": [{ "name": "playwright", "version": null }],
    "ci": { "name": "github-actions", "version": null }
  },
  "relatedProjects": [
    {
      "name": "{{RELATED_PROJECT}}",
      "path": "{{RELATED_PROJECT_PATH}}",
      "stack": "Fastify 5, SQLite"
    }
  ],
  "servers": ["{{SERVER_NAME}}"],
  "auditScope": "full",
  "phases": {
    "baseline-analysis": {
      "status": "done",
      "session": 1,
      "findingsCount": 3,
      "completeness": {
        "checksTotal": 22,
        "checksExecuted": 20,
        "checksSkipped": [
          { "check": "Architecture decisions documented", "priority": "COULD", "reason": "Not available" }
        ],
        "mustTotal": 10,
        "mustExecuted": 10,
        "mustCompleteness": 100,
        "overallCompleteness": 91
      },
      "layers": { "source": "done", "live": "pending" }
    },
    "security": {
      "status": "in-progress",
      "session": 2,
      "findingsCount": 0,
      "completeness": null,
      "layers": { "source": "pending", "live": "pending" }
    },
    "performance": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "seo": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "accessibility": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "code-quality": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "privacy": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "infrastructure": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "content-design": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null }
  },
  "summary": {
    "total": 3,
    "critical": 0,
    "high": 1,
    "medium": 2,
    "low": 0,
    "fixed": 0,
    "skipped": 0
  },
  "findings": [
    {
      "id": "IST-01",
      "phase": "baseline-analysis",
      "severity": "HIGH",
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
      "phases": ["baseline-analysis", "security"],
      "findingsAdded": 5,
      "findingsFixed": 0
    }
  ]
}
```

## State Migration v2 > v2.1

If an `.audit-state.json` with `"version": 2` is found:

1. Add `completeness` field to each phase (initially `null`)
2. Add `layers` field to each phase (initially `null`)
3. Migrate `layers` Bool>String-Enum: `true` > `"done"`, `false` > `"pending"`, `null` > `null`
4. Set `version` to `2.1`
5. Inform user: "State migrated from v2 to v2.1 (completeness tracking + layer format)."

## State Migration v1 > v2

If an `.audit-state.json` with `"version": 1` is found:

1. Map `detectedStack` array > structured object:
   - `"astro"` > `frontend: { name: "astro", version: null }`
   - `"tailwind"` > `css: { name: "tailwind", version: null }`
   - `"docker"` > `deployment: [{ name: "docker", version: null }]`
2. Map phase keys:
   - `code-astro` / `code-node` > `baseline-analysis` + `code-quality`
   - `visual` > kept as special phase (not in v2 standard phases)
   - `performance-seo` > `performance` + `seo`
   - `accessibility` > `accessibility`
   - `security` > `security` + `privacy`
   - `docker` > `infrastructure`
   - `vps` > `infrastructure`
3. Finding-IDs: Map old prefixes to new (`CODE` > `CODE`, `VIS` > keep, `PERF` > `PERF`, `SEC` > `SEC`, `VPS` > `INFRA`)
4. Add new fields: `relatedProjects: []`, `servers: []`, `history: []`
5. Set `version` to `2`
6. Inform user: "State migrated from v1 to v2. Please review."
