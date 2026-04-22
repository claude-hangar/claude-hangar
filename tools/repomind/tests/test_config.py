"""Tests for repomind.config."""

from __future__ import annotations

from pathlib import Path

import pytest
import yaml

from repomind.config import (
    CURRENT_SCHEMA_VERSION,
    Config,
    ConfigError,
    load_config,
    render_config_yaml,
)


def test_from_dict_valid() -> None:
    """A complete minimal dict parses without errors."""
    data = {
        "version": CURRENT_SCHEMA_VERSION,
        "project": {"name": "Demo"},
        "vault": {"root": "/tmp/vault", "subfolder": "Demo"},
        "sync": {"include": ["*.md"], "exclude": []},
    }
    cfg = Config.from_dict(data)
    assert cfg.project.name == "Demo"
    assert cfg.vault.subfolder == "Demo"
    assert cfg.sync.include == ("*.md",)
    assert cfg.sync.exclude == ()


def test_from_dict_rejects_wrong_version() -> None:
    """Unsupported schema versions raise ConfigError."""
    with pytest.raises(ConfigError, match="version"):
        Config.from_dict({"version": 99, "project": {"name": "x"}})


def test_from_dict_rejects_missing_section() -> None:
    """Missing required section → ConfigError names the section."""
    with pytest.raises(ConfigError, match="project"):
        Config.from_dict({"version": CURRENT_SCHEMA_VERSION})


def test_from_dict_rejects_empty_include() -> None:
    """An empty include list is a user error — we refuse to guess."""
    data = {
        "version": CURRENT_SCHEMA_VERSION,
        "project": {"name": "Demo"},
        "vault": {"root": "/tmp/vault", "subfolder": "Demo"},
        "sync": {"include": [], "exclude": []},
    }
    with pytest.raises(ConfigError, match="include"):
        Config.from_dict(data)


def test_load_config_reads_yaml(tmp_path: Path) -> None:
    """`load_config` reads and parses a valid YAML file."""
    cfg_path = tmp_path / ".repomind.yml"
    cfg_path.write_text(
        render_config_yaml(project_name="Demo", vault_root="/tmp/vault", subfolder="Demo"),
        encoding="utf-8",
    )
    cfg = load_config(cfg_path)
    assert cfg.project.name == "Demo"


def test_load_config_missing_file(tmp_path: Path) -> None:
    """Missing config file raises a helpful error."""
    with pytest.raises(ConfigError, match="not found"):
        load_config(tmp_path / "does-not-exist.yml")


def test_load_config_invalid_yaml(tmp_path: Path) -> None:
    """A syntactically broken YAML file raises ConfigError."""
    cfg_path = tmp_path / ".repomind.yml"
    cfg_path.write_text("::: this is not yaml :::", encoding="utf-8")
    with pytest.raises(ConfigError):
        load_config(cfg_path)


def test_load_config_non_mapping_root(tmp_path: Path) -> None:
    """A YAML root that is a list, not a mapping, is rejected."""
    cfg_path = tmp_path / ".repomind.yml"
    cfg_path.write_text("- just a list\n", encoding="utf-8")
    with pytest.raises(ConfigError, match="mapping"):
        load_config(cfg_path)


def test_render_config_yaml_is_valid_yaml() -> None:
    """The rendered default renders back as a valid Config."""
    body = render_config_yaml(
        project_name="Demo",
        vault_root="/tmp/vault",
        subfolder="Demo",
        description="A demo project",
        tags=("demo", "test"),
    )
    parsed = yaml.safe_load(body)
    cfg = Config.from_dict(parsed)
    assert cfg.project.description == "A demo project"
    assert cfg.project.tags == ("demo", "test")
    assert ".repomind/**" in cfg.sync.exclude
