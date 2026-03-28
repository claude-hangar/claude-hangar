# Project Audit — State Schema v2.1

State file: `.project-audit-state.json`

```json
{
  "version": 2.1,
  "created": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DD",
  "project": "{{PROJECT_NAME}}",
  "projectType": "management-repo",
  "detectedStack": {
    "node": { "detected": true, "version": "22.x" },
    "python": { "detected": false, "version": null },
    "shell": { "detected": true, "version": null },
    "docker": { "detected": true, "version": null },
    "monorepo": { "detected": false, "version": null },
    "claude-code": { "detected": true, "version": "2.1.86" }
  },
  "auditScope": "full",
  "phases": {
    "structure": {
      "status": "done",
      "session": 1,
      "findingsCount": 2,
      "completeness": {
        "checksTotal": 18,
        "checksExecuted": 16,
        "checksSkipped": [
          { "check": "Monorepo boundaries", "reason": "Not a monorepo", "priority": "COULD" }
        ],
        "mustTotal": 8,
        "mustExecuted": 8,
        "mustCompleteness": 100,
        "overallCompleteness": 89
      },
      "layers": {
        "source": "done",
        "runtime": "not-applicable"
      }
    },
    "dependencies": {
      "status": "done",
      "session": 1,
      "findingsCount": 1,
      "completeness": null,
      "layers": { "source": "done", "runtime": "done" }
    },
    "code-quality": { "status": "in-progress", "session": 2, "findingsCount": 0, "completeness": null, "layers": null },
    "git": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "cicd": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "documentation": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "testing": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "security": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "deployment": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null },
    "maintenance": { "status": "pending", "session": null, "findingsCount": 0, "completeness": null, "layers": null }
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
      "id": "STRUC-01",
      "phase": "structure",
      "severity": "MEDIUM",
      "title": "Short title",
      "description": "What is the problem",
      "location": "File or area",
      "status": "open",
      "fixedIn": null,
      "notes": ""
    }
  ],
  "relatedProjects": [],
  "history": [
    {
      "date": "YYYY-MM-DD",
      "session": 1,
      "phases": ["structure", "dependencies"],
      "findingsAdded": 3,
      "findingsFixed": 0
    }
  ]
}
```

## State Migration v2 > v2.1

If a `.project-audit-state.json` with `"version": 2` is found:

1. Add `completeness: null` and `layers: null` to each phase
2. Set `version` to `2.1`
3. Existing phase data is preserved
4. On next phase execution: completeness is automatically populated
5. Inform user: "State migrated from v2 to v2.1. Completeness tracking active."

## State Migration v1 > v2

If a `.project-audit-state.json` with `"version": 1` is found:

1. Keep `projectType`
2. Recreate `detectedStack` from project analysis:
   - package.json present > `node: { detected: true }`
   - pyproject.toml/requirements.txt > `python: { detected: true }`
   - *.sh dominant > `shell: { detected: true }`
   - Dockerfile > `docker: { detected: true }`
   - workspaces > `monorepo: { detected: true }`
3. Map phase keys:
   - `git-cicd` > split into `git` (findings GIT-*) + `cicd` (findings CICD-*)
   - `structure` > `structure`
   - `dependencies` > `dependencies`
   - `documentation` > `documentation`
   - `testing` > `testing`
   - `security` > `security`
4. Add new phases: `code-quality`, `deployment`, `maintenance` as `pending`
5. New fields: `relatedProjects: []`, `history: []`, `auditScope: "full"`
6. Finding-IDs: Keep `GIT-*`, new CICD findings start at CICD-01
7. Set `version` to `2`
8. Inform user: "State migrated from v1 to v2. 4 new phases available."
