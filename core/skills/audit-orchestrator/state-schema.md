# Audit Orchestrator — State Schema v3

State file: `.audit-orchestrator-state.json`

```json
{
  "version": 3,
  "created": "YYYY-MM-DD",
  "lastUpdated": "YYYY-MM-DD",
  "project": "{{PROJECT_NAME}}",
  "outputMode": "static|server",
  "executionMode": "team|manual|runner",
  "activeAudits": ["astro-audit", "audit", "project-audit"],
  "auditOrder": ["astro-audit", "audit", "project-audit"],
  "sequencingReason": "Beta version detected — migration first",
  "preAudit": {
    "github": {
      "detected": true,
      "org": "{{GITHUB_ORG}}",
      "repo": "{{GITHUB_REPO}}",
      "orgChecked": false,
      "repoChecked": false,
      "findings": 0
    },
    "vps": {
      "detected": true,
      "servers": ["{{SERVER_1}}", "{{SERVER_2}}"],
      "quickCheckDone": false,
      "findings": 0
    }
  },
  "team": {
    "teamName": "audit-{{PROJECT_NAME}}",
    "teammates": [
      {
        "name": "audit-worker-1",
        "audit": "audit",
        "status": "running|completed|failed",
        "startedAt": "ISO-8601",
        "completedAt": "ISO-8601|null"
      }
    ],
    "taskDependencies": {
      "audit": [],
      "project-audit": ["audit"]
    },
    "timing": {
      "teamStarted": "ISO-8601",
      "teamCompleted": "ISO-8601|null",
      "totalDurationMin": 0
    }
  },
  "phaseMapping": {
    "audit": {
      "active": ["status-analysis", "security", "performance", "seo", "accessibility", "privacy", "infrastructure"],
      "delegated": {
        "code-quality": "project-audit"
      }
    },
    "project-audit": {
      "active": ["dependencies", "code-quality", "git", "cicd", "testing", "security", "deployment", "maintenance"],
      "delegated": {
        "structure": "audit"
      }
    },
    "astro-audit": {
      "active": ["ENV", "CFG", "CODE", "COLL", "MDLK", "IMG", "TOOL", "VITE", "ZOD", "NEW", "CSP", "FONT", "DCI"],
      "skipped": {
        "ADPT": "static-output"
      }
    }
  },
  "progress": {
    "astro-audit": { "done": 0, "total": 13, "skipped": 1 },
    "audit": { "done": 0, "total": 7 },
    "project-audit": { "done": 0, "total": 8 }
  },
  "relatedProjects": [
    {
      "name": "{{PROJECT_NAME}}",
      "path": "{{PROJECT_PATH}}",
      "stack": "{{STACK_INFO}}",
      "auditStatus": "open|planned|audited"
    }
  ],
  "sessionEstimate": {
    "calculated": 10,
    "breakdown": {
      "planning": 1,
      "astro-audit": 3,
      "audit": 3,
      "project-audit": 3,
      "fixing": 2
    }
  },
  "combinedSummary": {
    "totalFindings": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0,
    "fixed": 0,
    "skipped": 0
  }
}
```

**Backward Compatibility:** v2 states continue to work — missing `team` field = manual mode, missing `executionMode` = "manual".
