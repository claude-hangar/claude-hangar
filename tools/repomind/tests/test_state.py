"""Tests for repomind.state."""

from __future__ import annotations

from pathlib import Path

from repomind.state import FileEntry, State, load_state, save_state, state_path


def test_load_state_returns_empty_when_missing(tmp_path: Path) -> None:
    """Missing state file → empty State, no error."""
    state = load_state(tmp_path)
    assert state.files == {}
    assert state.last_sync is None


def test_save_and_load_roundtrip(tmp_path: Path) -> None:
    """`save_state` then `load_state` preserves content."""
    state = State(
        files={
            "Dashboard.md": FileEntry(
                hash="sha256:abc",
                copied_at="2026-04-22T10:00:00+00:00",
                vault_target=str(tmp_path / "vault" / "Dashboard.md"),
            )
        }
    )
    save_state(state, tmp_path)
    assert state_path(tmp_path).exists()
    loaded = load_state(tmp_path)
    assert loaded.files["Dashboard.md"].hash == "sha256:abc"
    assert loaded.last_sync is not None


def test_save_state_is_atomic(tmp_path: Path) -> None:
    """Tempfile is renamed, not left behind after a successful save."""
    save_state(State(), tmp_path)
    tmp = state_path(tmp_path).with_suffix(state_path(tmp_path).suffix + ".tmp")
    assert not tmp.exists()
    assert state_path(tmp_path).exists()


def test_load_state_handles_corrupt_json(tmp_path: Path) -> None:
    """A corrupt state file is logged and treated as empty, no crash."""
    path = state_path(tmp_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("{ not valid json", encoding="utf-8")
    loaded = load_state(tmp_path)
    assert loaded.files == {}


def test_load_state_handles_wrong_root_type(tmp_path: Path) -> None:
    """A state file whose root is a list is treated as empty."""
    path = state_path(tmp_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("[]", encoding="utf-8")
    assert load_state(tmp_path).files == {}


def test_load_state_handles_bad_entry_shape(tmp_path: Path) -> None:
    """A structurally wrong entry is treated as empty, not crashy."""
    path = state_path(tmp_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('{"files": {"a.md": "not a dict"}}', encoding="utf-8")
    assert load_state(tmp_path).files == {}
