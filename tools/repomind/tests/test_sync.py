"""Tests for repomind.sync — plan + apply, idempotency, deletions."""

from __future__ import annotations

import datetime as _dt
from pathlib import Path

from repomind.config import Config
from repomind.state import State, load_state, save_state
from repomind.sync import OpKind, apply_plan, plan_sync


def _run(config: Config, repo: Path, *, dry_run: bool = False, force: bool = False) -> tuple[State, list[OpKind]]:
    """Small helper: mirrors CLI flow — load/plan/apply, save only on writes."""
    state = load_state(repo)
    ops = plan_sync(config, state, repo, force=force)
    summary = apply_plan(ops, state, dry_run=dry_run)
    if not dry_run and summary.total_written + summary.deleted > 0:
        save_state(state, repo)
    return state, [op.kind for op in ops]


def test_initial_sync_is_all_new(sample_config: Config, tmp_repo: Path) -> None:
    """First sync: every matched file is NEW."""
    state, kinds = _run(sample_config, tmp_repo)
    assert OpKind.NEW in kinds
    assert OpKind.CHANGED not in kinds
    assert len(state.files) >= 3  # README, Dashboard, docs/INDEX, docs/infra/firewall


def test_files_are_copied_to_vault(sample_config: Config, tmp_repo: Path) -> None:
    """After sync, the vault subfolder contains the matched files."""
    _run(sample_config, tmp_repo)
    vault = sample_config.vault.target_dir
    assert (vault / "README.md").read_text(encoding="utf-8") == "# root readme\n"
    assert (vault / "docs" / "infra" / "firewall.md").exists()
    assert not (vault / "raw" / "secrets.txt").exists()


def test_sync_is_idempotent(sample_config: Config, tmp_repo: Path) -> None:
    """Second sync with no repo changes produces zero writes.

    Idempotency is verified by the absence of NEW/CHANGED op kinds and by
    the vault mtime staying constant — not by state.last_sync (that gets
    set by the first run and is loaded back on the second).
    """
    _run(sample_config, tmp_repo)
    before_mtime = (sample_config.vault.target_dir / "Dashboard.md").stat().st_mtime
    _state, kinds = _run(sample_config, tmp_repo)
    assert OpKind.NEW not in kinds
    assert OpKind.CHANGED not in kinds
    assert all(k is OpKind.UNCHANGED for k in kinds)
    after_mtime = (sample_config.vault.target_dir / "Dashboard.md").stat().st_mtime
    assert before_mtime == after_mtime


def test_changed_file_is_detected(sample_config: Config, tmp_repo: Path) -> None:
    """Edit a file → second sync classifies it as CHANGED."""
    _run(sample_config, tmp_repo)
    (tmp_repo / "README.md").write_text("# root readme v2\n", encoding="utf-8")
    _state, kinds = _run(sample_config, tmp_repo)
    assert OpKind.CHANGED in kinds
    vault = sample_config.vault.target_dir
    assert (vault / "README.md").read_text(encoding="utf-8") == "# root readme v2\n"


def test_deleted_file_moves_to_deleted_folder(sample_config: Config, tmp_repo: Path) -> None:
    """When a tracked file disappears from the repo, it ends up in `_deleted/YYYY-MM-DD/`."""
    _run(sample_config, tmp_repo)
    (tmp_repo / "Dashboard.md").unlink()
    _state, kinds = _run(sample_config, tmp_repo)
    assert OpKind.DELETED in kinds
    today = _dt.date.today().isoformat()
    deleted_target = sample_config.vault.target_dir / "_deleted" / today / "Dashboard.md"
    assert deleted_target.exists()
    assert not (sample_config.vault.target_dir / "Dashboard.md").exists()


def test_dry_run_writes_nothing(sample_config: Config, tmp_repo: Path) -> None:
    """`dry_run=True` surfaces the plan but touches neither vault nor state."""
    state = load_state(tmp_repo)
    ops = plan_sync(sample_config, state, tmp_repo)
    summary = apply_plan(ops, state, dry_run=True)
    assert summary.new > 0
    assert not sample_config.vault.target_dir.exists() or not any(
        sample_config.vault.target_dir.iterdir()
    )
    assert load_state(tmp_repo).files == {}


def test_force_reclassifies_unchanged_as_changed(sample_config: Config, tmp_repo: Path) -> None:
    """`force=True` re-copies every file even when the hash matches."""
    _run(sample_config, tmp_repo)
    _state, kinds = _run(sample_config, tmp_repo, force=True)
    assert OpKind.CHANGED in kinds
    assert OpKind.UNCHANGED not in kinds
