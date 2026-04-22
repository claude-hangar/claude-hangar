"""Sync algorithm: plan operations, apply them, maintain state.

Flow:
    1. Walk the repo with the configured include/exclude globs.
    2. Hash each candidate file; compare to stored hash in state.
    3. Classify as NEW / CHANGED / UNCHANGED.
    4. Any file present in state but no longer in the include-set is DELETED
       and moved into `<vault>/_deleted/YYYY-MM-DD/<relpath>`.
    5. Apply operations (or return the plan in dry-run mode).
    6. Persist the new state.

Design notes
    - Sync is one-way: repo → vault. Nothing is ever read back from the vault.
    - Deletions never hard-delete; they move into a dated `_deleted/` tree so
      Giorgo can recover. (Principle: never remove without a trace.)
    - Windows path quirks are handled by always storing relative paths in
      POSIX form inside state/operations and only converting to `Path` at
      I/O boundaries.
"""

from __future__ import annotations

import datetime as _dt
import shutil
from dataclasses import dataclass, field
from enum import StrEnum
from pathlib import Path

from repomind.config import Config
from repomind.state import FileEntry, State, iso_now
from repomind.util import (
    ensure_parent,
    iter_matching_files,
    relpath_posix,
    sha256_file,
)


class OpKind(StrEnum):
    """Sync operation kinds. Values serialize cleanly for CLI tables."""

    NEW = "new"
    CHANGED = "changed"
    UNCHANGED = "unchanged"
    DELETED = "deleted"


@dataclass(frozen=True)
class Operation:
    """A single planned or executed sync step."""

    kind: OpKind
    rel_path: str
    source: Path | None  # None for DELETED
    target: Path
    new_hash: str | None  # None for DELETED / UNCHANGED


@dataclass
class SyncSummary:
    """Aggregated counts + per-operation details returned by `apply_plan`."""

    new: int = 0
    changed: int = 0
    unchanged: int = 0
    deleted: int = 0
    operations: list[Operation] = field(default_factory=list)

    @property
    def total_written(self) -> int:
        """Number of file writes this run (new + changed)."""
        return self.new + self.changed


def plan_sync(
    config: Config,
    state: State,
    repo_root: Path,
    *,
    force: bool = False,
) -> list[Operation]:
    """Compute the list of operations needed to bring the vault in sync.

    Parameters
    ----------
    force:
        If True, treat every matched file as CHANGED even when the hash
        matches state. Useful to re-materialize a lost vault.
    """
    repo_root = repo_root.resolve()
    vault_dir = config.vault.target_dir

    operations: list[Operation] = []
    seen_rel_paths: set[str] = set()

    for src in iter_matching_files(repo_root, config.sync.include, config.sync.exclude):
        rel = relpath_posix(src, repo_root)
        seen_rel_paths.add(rel)
        new_hash = sha256_file(src)
        target = vault_dir / rel
        prior = state.files.get(rel)

        if prior is None:
            operations.append(
                Operation(kind=OpKind.NEW, rel_path=rel, source=src, target=target, new_hash=new_hash)
            )
        elif force or prior.hash != new_hash:
            operations.append(
                Operation(kind=OpKind.CHANGED, rel_path=rel, source=src, target=target, new_hash=new_hash)
            )
        else:
            operations.append(
                Operation(kind=OpKind.UNCHANGED, rel_path=rel, source=src, target=target, new_hash=new_hash)
            )

    # Files present in state but no longer in the include set → deletions
    today = _dt.date.today().isoformat()
    deleted_root = vault_dir / "_deleted" / today
    for rel in sorted(state.files.keys() - seen_rel_paths):
        target = deleted_root / rel
        operations.append(
            Operation(
                kind=OpKind.DELETED,
                rel_path=rel,
                source=None,
                target=target,
                new_hash=None,
            )
        )

    return operations


def apply_plan(
    operations: list[Operation],
    state: State,
    *,
    dry_run: bool,
) -> SyncSummary:
    """Execute `operations`, updating `state` in-place. Returns a summary.

    In `dry_run=True` mode, no filesystem changes are made and state is
    left untouched — only the summary is populated.
    """
    summary = SyncSummary(operations=list(operations))

    for op in operations:
        if op.kind is OpKind.UNCHANGED:
            summary.unchanged += 1
            continue

        if op.kind is OpKind.NEW:
            summary.new += 1
            if not dry_run:
                assert op.source is not None and op.new_hash is not None
                ensure_parent(op.target)
                shutil.copy2(op.source, op.target)
                state.files[op.rel_path] = FileEntry(
                    hash=op.new_hash,
                    copied_at=iso_now(),
                    vault_target=str(op.target),
                )
            continue

        if op.kind is OpKind.CHANGED:
            summary.changed += 1
            if not dry_run:
                assert op.source is not None and op.new_hash is not None
                ensure_parent(op.target)
                shutil.copy2(op.source, op.target)
                state.files[op.rel_path] = FileEntry(
                    hash=op.new_hash,
                    copied_at=iso_now(),
                    vault_target=str(op.target),
                )
            continue

        if op.kind is OpKind.DELETED:
            summary.deleted += 1
            if not dry_run:
                prior = state.files.get(op.rel_path)
                if prior is not None:
                    existing_target = Path(prior.vault_target)
                    if existing_target.exists():
                        ensure_parent(op.target)
                        shutil.move(str(existing_target), str(op.target))
                state.files.pop(op.rel_path, None)
            continue

    return summary
