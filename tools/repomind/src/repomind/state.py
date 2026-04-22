"""State tracking for repomind sync runs.

State lives under `<repo>/.repomind/state.json` and records, per relative
source path, the hash at last sync and the vault target. Used to detect
changes and deletions on subsequent runs.

Atomic writes: we write to a `.tmp` sibling and `os.replace` to the final
name, so an interrupted sync never leaves a half-written state file.
"""

from __future__ import annotations

import datetime as _dt
import json
import logging
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

from repomind.util import ensure_parent

STATE_DIR_NAME = ".repomind"
STATE_FILE_NAME = "state.json"

logger = logging.getLogger(__name__)


@dataclass
class FileEntry:
    """Per-file state: last known hash + where it was copied in the vault."""

    hash: str
    copied_at: str
    vault_target: str


@dataclass
class State:
    """Top-level state object persisted to `state.json`."""

    last_sync: str | None = None
    files: dict[str, FileEntry] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        """Serialize to a JSON-ready dict."""
        return {
            "last_sync": self.last_sync,
            "files": {k: asdict(v) for k, v in sorted(self.files.items())},
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> State:
        """Build a `State` from a parsed JSON dict — raises on structural issues."""
        files_raw = data.get("files") or {}
        if not isinstance(files_raw, dict):
            raise ValueError("`files` must be a mapping")
        files: dict[str, FileEntry] = {}
        for key, value in files_raw.items():
            if not isinstance(value, dict):
                raise ValueError(f"Entry for {key!r} must be a mapping")
            files[str(key)] = FileEntry(
                hash=str(value["hash"]),
                copied_at=str(value["copied_at"]),
                vault_target=str(value["vault_target"]),
            )
        return cls(last_sync=data.get("last_sync"), files=files)


def state_path(repo_root: Path) -> Path:
    """Return the canonical state-file path for `repo_root`."""
    return repo_root / STATE_DIR_NAME / STATE_FILE_NAME


def load_state(repo_root: Path) -> State:
    """Load state from `repo_root/.repomind/state.json`.

    Missing file → empty state. Corrupt file → warning logged + empty state.
    This is intentional: sync must always run; a broken state file just
    means we'll rescan everything.
    """
    path = state_path(repo_root)
    if not path.exists():
        return State()
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        logger.warning("Corrupt state file at %s (%s) — starting fresh", path, exc)
        return State()
    if not isinstance(raw, dict):
        logger.warning("Unexpected state root type in %s — starting fresh", path)
        return State()
    try:
        return State.from_dict(raw)
    except (ValueError, KeyError) as exc:
        logger.warning("Invalid state payload in %s (%s) — starting fresh", path, exc)
        return State()


def save_state(state: State, repo_root: Path) -> None:
    """Persist `state` to `repo_root/.repomind/state.json` atomically."""
    state.last_sync = _dt.datetime.now(tz=_dt.UTC).isoformat(timespec="seconds")
    path = state_path(repo_root)
    ensure_parent(path)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(
        json.dumps(state.to_dict(), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    tmp.replace(path)


def iso_now() -> str:
    """Return current UTC timestamp in ISO-8601 seconds precision."""
    return _dt.datetime.now(tz=_dt.UTC).isoformat(timespec="seconds")
