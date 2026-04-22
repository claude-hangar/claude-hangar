"""Tests for the Typer CLI surface."""

from __future__ import annotations

from pathlib import Path

from typer.testing import CliRunner

from repomind import __version__
from repomind.cli import app
from repomind.config import CONFIG_FILENAME, load_config

runner = CliRunner()


def test_version_flag() -> None:
    """`repomind --version` prints the module version and exits 0."""
    result = runner.invoke(app, ["--version"])
    assert result.exit_code == 0
    assert __version__ in result.stdout


def test_init_writes_config(tmp_path: Path) -> None:
    """`repomind init` creates a valid .repomind.yml."""
    cfg_path = tmp_path / CONFIG_FILENAME
    result = runner.invoke(
        app,
        [
            "init",
            "--project-name",
            "Demo",
            "--vault-root",
            str(tmp_path / "vault"),
            "--subfolder",
            "Demo",
            "--config",
            str(cfg_path),
        ],
    )
    assert result.exit_code == 0, result.stdout
    assert cfg_path.exists()
    cfg = load_config(cfg_path)
    assert cfg.project.name == "Demo"


def test_init_refuses_overwrite_without_force(tmp_path: Path) -> None:
    """Re-running `init` without `--force` fails cleanly instead of clobbering."""
    cfg_path = tmp_path / CONFIG_FILENAME
    cfg_path.write_text("existing\n", encoding="utf-8")
    result = runner.invoke(
        app,
        [
            "init",
            "--project-name",
            "Demo",
            "--vault-root",
            str(tmp_path / "vault"),
            "--subfolder",
            "Demo",
            "--config",
            str(cfg_path),
        ],
    )
    assert result.exit_code == 1
    assert cfg_path.read_text(encoding="utf-8") == "existing\n"


def test_init_force_overwrites(tmp_path: Path) -> None:
    """`--force` overwrites an existing file."""
    cfg_path = tmp_path / CONFIG_FILENAME
    cfg_path.write_text("existing\n", encoding="utf-8")
    result = runner.invoke(
        app,
        [
            "init",
            "--project-name",
            "Demo",
            "--vault-root",
            str(tmp_path / "vault"),
            "--subfolder",
            "Demo",
            "--config",
            str(cfg_path),
            "--force",
        ],
    )
    assert result.exit_code == 0
    assert "version: 1" in cfg_path.read_text(encoding="utf-8")


def test_sync_dry_run_reports_plan(tmp_path: Path) -> None:
    """End-to-end: init, then dry-run sync reports counts, writes nothing."""
    (tmp_path / "docs").mkdir()
    (tmp_path / "docs" / "INDEX.md").write_text("# index\n", encoding="utf-8")
    (tmp_path / "Dashboard.md").write_text("# dashboard\n", encoding="utf-8")
    vault = tmp_path / "vault"
    cfg_path = tmp_path / CONFIG_FILENAME

    init_result = runner.invoke(
        app,
        [
            "init",
            "--project-name",
            "Demo",
            "--vault-root",
            str(vault),
            "--subfolder",
            "Demo",
            "--config",
            str(cfg_path),
        ],
    )
    assert init_result.exit_code == 0

    sync_result = runner.invoke(app, ["sync", "--config", str(cfg_path), "--dry-run"])
    assert sync_result.exit_code == 0, sync_result.stdout
    assert "Dry-run" in sync_result.stdout
    # No vault target yet because dry-run doesn't write
    assert not (vault / "Demo" / "Dashboard.md").exists()


def test_sync_real_run_writes_files(tmp_path: Path) -> None:
    """A real sync run copies files and state becomes populated."""
    (tmp_path / "docs").mkdir()
    (tmp_path / "docs" / "INDEX.md").write_text("# index\n", encoding="utf-8")
    vault = tmp_path / "vault"
    cfg_path = tmp_path / CONFIG_FILENAME

    runner.invoke(
        app,
        [
            "init",
            "--project-name",
            "Demo",
            "--vault-root",
            str(vault),
            "--subfolder",
            "Demo",
            "--config",
            str(cfg_path),
        ],
    )
    sync_result = runner.invoke(app, ["sync", "--config", str(cfg_path)])
    assert sync_result.exit_code == 0
    assert (vault / "Demo" / "docs" / "INDEX.md").exists()
    assert (tmp_path / ".repomind" / "state.json").exists()


def test_sync_missing_config_fails_cleanly(tmp_path: Path) -> None:
    """Calling `sync` without a config exits non-zero with a helpful message.

    Error goes to stderr via `typer.secho(..., err=True)`; CliRunner's
    `.output` captures both streams when mix_stderr is on (the default),
    so we check `result.output` rather than `.stdout`.
    """
    result = runner.invoke(app, ["sync", "--config", str(tmp_path / "missing.yml")])
    assert result.exit_code == 1
    assert "Config error" in result.output
