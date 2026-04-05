---
name: safety-guard
description: 3-mode protection system for autonomous agent runs. Careful (confirm risky ops), Freeze (restrict writes to directory), Guard (combined). Use when running autonomous loops or untrusted agent tasks.
user_invocable: true
argument_hint: "careful|freeze|guard"
---

# /safety-guard — Write Scope Protection

Three-mode protection system that restricts what autonomous agents can do.
Prevents accidental writes outside project boundaries, destructive operations,
and unauthorized scope expansion.

## Usage

```
/safety-guard careful    # Confirm before risky operations
/safety-guard freeze     # Restrict writes to current directory
/safety-guard guard      # Combined: freeze + careful
/safety-guard off        # Disable all guards
/safety-guard status     # Show current protection level
```

## The Three Modes

### Mode 1: Careful

Intercepts destructive and risky operations before execution:

- **Destructive commands**: `rm -rf`, `git reset --hard`, `git push --force`, `DROP TABLE`
- **Scope expansion**: Writing to files outside the project directory
- **Config weakening**: Disabling strict mode, removing lint rules, weakening security settings
- **External communication**: `curl -X POST`, `git push`, API calls that send data

**Behavior:** Logs a warning message describing the risk. Does NOT auto-block — relies on
the user's permission mode to handle confirmation. Provides context so the user can make
an informed decision.

### Mode 2: Freeze

Restricts all file writes to a specified directory tree:

- **Allowed**: Read any file, write within the frozen directory
- **Blocked**: Write, Edit, or create files outside the frozen directory
- **Default scope**: Current working directory (`.`)

**Behavior:** Any Write/Edit tool call targeting a path outside the frozen directory
triggers a block message. The agent must adjust its approach.

### Mode 3: Guard (Recommended for Autonomous Runs)

Combines Careful + Freeze:

- All Careful checks apply
- All Freeze restrictions apply
- Additional: blocks `Bash` commands that could bypass file restrictions (e.g., `mv`, `cp` to outside paths)

## Implementation

Safety Guard works via PreToolUse hooks. To activate, set the environment variable:

```bash
export HANGAR_SAFETY_MODE="guard"     # careful | freeze | guard | off
export HANGAR_FREEZE_DIR="./src"      # Optional: restrict writes to this path
```

### Hook Integration

The safety-guard check is implemented as a PreToolUse hook that:

1. Reads `HANGAR_SAFETY_MODE` environment variable
2. For **Write/Edit** tools: checks if target path is within `HANGAR_FREEZE_DIR`
3. For **Bash** tool: scans command for destructive patterns and out-of-scope writes
4. Outputs a warning or block message with the risk assessment

### Protected Patterns

| Category | Patterns | Mode |
|----------|----------|------|
| Destructive shell | `rm -rf`, `git reset --hard`, `git clean -fd`, `DROP TABLE`, `TRUNCATE` | Careful |
| Force operations | `--force`, `--hard`, `-f` (with git/rm) | Careful |
| External sends | `curl -X POST/PUT/DELETE`, `git push`, `npm publish` | Careful |
| Config weakening | Remove `strict: true`, disable lint rules, weaken CSP | Careful |
| Out-of-scope writes | Any Write/Edit outside freeze directory | Freeze |
| Bypass commands | `mv`, `cp`, `ln -s` targeting outside freeze dir | Guard |

## When to Use

- **Autonomous loops** — When loop-operator runs unattended
- **Untrusted tasks** — When the task scope is unclear
- **Production-adjacent work** — When mistakes have high blast radius
- **Learning/exploration** — When the agent is exploring unfamiliar code

## Example Session

```
> /safety-guard guard

Safety Guard activated: GUARD mode
- Careful checks: ON (destructive ops, scope expansion, external sends)
- Freeze scope: D:\project\src (writes restricted to this directory)
- Bypass protection: ON (mv/cp/ln to outside paths blocked)

To change: /safety-guard careful | freeze | off
```

## Interaction with Other Hooks

- **bash-guard**: Safety-guard extends bash-guard's destructive command detection
  with write-scope awareness. Both can run simultaneously — bash-guard blocks
  the most dangerous commands, safety-guard adds scope restriction.
- **config-change-guard**: Config weakening detection overlaps. Safety-guard's
  Careful mode provides the superset behavior.

Inspired by ECC's safety-guard skill (Careful/Freeze/Guard modes) adapted for
Hangar's hook-based architecture.
