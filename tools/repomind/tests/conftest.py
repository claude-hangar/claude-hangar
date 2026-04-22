"""Shared pytest fixtures for repomind tests."""

from __future__ import annotations

from pathlib import Path

import pytest

from repomind.config import Config, ProjectSection, SyncSection, VaultSection


@pytest.fixture
def tmp_repo(tmp_path: Path) -> Path:
    """A minimal throwaway repo with a handful of files in several folders."""
    repo = tmp_path / "repo"
    (repo / "docs" / "infra").mkdir(parents=True)
    (repo / "raw").mkdir()
    (repo / "scripts").mkdir()
    (repo / "README.md").write_text("# root readme\n", encoding="utf-8")
    (repo / "Dashboard.md").write_text("# dashboard\n", encoding="utf-8")
    (repo / "docs" / "INDEX.md").write_text("# docs index\n", encoding="utf-8")
    (repo / "docs" / "infra" / "firewall.md").write_text("# firewall\n", encoding="utf-8")
    (repo / "raw" / "secrets.txt").write_text("ignore me\n", encoding="utf-8")
    (repo / "scripts" / "build.sh").write_text("#!/bin/bash\n", encoding="utf-8")
    return repo


@pytest.fixture
def tmp_vault(tmp_path: Path) -> Path:
    """A fresh empty vault root."""
    vault = tmp_path / "vault"
    vault.mkdir()
    return vault


@pytest.fixture
def sample_config(tmp_repo: Path, tmp_vault: Path) -> Config:
    """A Config that points at `tmp_repo`'s layout."""
    return Config(
        version=1,
        project=ProjectSection(name="TestProject"),
        vault=VaultSection(root=tmp_vault, subfolder="TestProject"),
        sync=SyncSection(
            include=("*.md", "docs/**/*.md"),
            exclude=("raw/**", "scripts/**", ".git/**"),
        ),
    )
