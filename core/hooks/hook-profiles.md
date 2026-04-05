# Hook Profiles

Control hook strictness via the `HANGAR_HOOK_PROFILE` environment variable.

## Available Profiles

| Profile | Behavior | Use When |
|---------|----------|----------|
| `minimal` | Safety hooks only (bash-guard, secret-leak-check) | Quick prototyping |
| `standard` | Safety + quality hooks (default) | Normal development |
| `strict` | All hooks active, blocking mode | Production/CI |

## Usage

```bash
# Set profile for current session
export HANGAR_HOOK_PROFILE=minimal

# Set profile permanently in shell profile
echo 'export HANGAR_HOOK_PROFILE=standard' >> ~/.bashrc
```

## Disabling Individual Hooks

```bash
# Comma-separated list of hooks to disable
export HANGAR_DISABLED_HOOKS=token-warning,desktop-notify
```

## Profile Mapping

### minimal
- bash-guard.sh ✓
- secret-leak-check.sh ✓
- Everything else: disabled

### standard (default)
- All safety hooks ✓
- checkpoint.sh ✓
- session-start.sh ✓
- session-stop.sh ✓
- skill-suggest.sh ✓
- token-warning.sh ✓
- Learning hooks: disabled
- Desktop notify: disabled

### strict
- Everything enabled ✓
- Blocking mode for quality gates ✓
- Cost tracking active ✓
- Learning system active ✓
