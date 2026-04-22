"""YAML config loader + schema validation for `.repomind.yml`."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

CONFIG_FILENAME = ".repomind.yml"
CURRENT_SCHEMA_VERSION = 1


class ConfigError(ValueError):
    """Raised when `.repomind.yml` is missing, malformed, or semantically invalid."""


@dataclass(frozen=True)
class ProjectSection:
    """Metadata about the project the vault folder represents."""

    name: str
    description: str | None = None
    tags: tuple[str, ...] = field(default_factory=tuple)


@dataclass(frozen=True)
class VaultSection:
    """Where the synced files land in the central Obsidian vault."""

    root: Path
    subfolder: str

    @property
    def target_dir(self) -> Path:
        """Return the absolute target directory inside the vault."""
        return (self.root / self.subfolder).resolve()


@dataclass(frozen=True)
class SyncSection:
    """Glob patterns describing which files to copy and which to skip."""

    include: tuple[str, ...]
    exclude: tuple[str, ...]


@dataclass(frozen=True)
class Config:
    """Parsed and validated `.repomind.yml`."""

    version: int
    project: ProjectSection
    vault: VaultSection
    sync: SyncSection

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Config:
        """Build a `Config` from a plain dict, raising `ConfigError` on issues."""
        version = data.get("version")
        if version != CURRENT_SCHEMA_VERSION:
            raise ConfigError(
                f"Unsupported config version {version!r}; expected {CURRENT_SCHEMA_VERSION}."
            )

        try:
            project_raw = data["project"]
            vault_raw = data["vault"]
            sync_raw = data["sync"]
        except KeyError as exc:
            raise ConfigError(f"Missing required section: {exc.args[0]!r}") from exc

        if not isinstance(project_raw, dict) or "name" not in project_raw:
            raise ConfigError("`project.name` is required.")
        if not isinstance(vault_raw, dict) or "root" not in vault_raw or "subfolder" not in vault_raw:
            raise ConfigError("`vault.root` and `vault.subfolder` are required.")
        if not isinstance(sync_raw, dict):
            raise ConfigError("`sync` must be a mapping with `include`/`exclude`.")

        project = ProjectSection(
            name=str(project_raw["name"]),
            description=(
                str(project_raw["description"])
                if project_raw.get("description") is not None
                else None
            ),
            tags=tuple(str(t) for t in project_raw.get("tags") or ()),
        )

        vault = VaultSection(
            root=Path(str(vault_raw["root"])).expanduser(),
            subfolder=str(vault_raw["subfolder"]),
        )

        include = tuple(str(p) for p in sync_raw.get("include") or ())
        exclude = tuple(str(p) for p in sync_raw.get("exclude") or ())
        if not include:
            raise ConfigError("`sync.include` must list at least one glob pattern.")

        return cls(
            version=int(version),
            project=project,
            vault=vault,
            sync=SyncSection(include=include, exclude=exclude),
        )


def load_config(path: Path) -> Config:
    """Load and validate a `.repomind.yml` from `path`.

    Raises `ConfigError` if the file is missing, not valid YAML, or fails
    schema validation.
    """
    if not path.exists():
        raise ConfigError(f"Config file not found: {path}")
    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        raise ConfigError(f"Invalid YAML in {path}: {exc}") from exc
    if not isinstance(raw, dict):
        raise ConfigError(f"Config root must be a mapping, got {type(raw).__name__}")
    return Config.from_dict(raw)


def render_config_yaml(
    project_name: str,
    vault_root: str,
    subfolder: str,
    description: str | None = None,
    tags: tuple[str, ...] = (),
) -> str:
    """Render a sensible default `.repomind.yml` as a YAML string.

    Used by `repomind init` and `/vault-bootstrap` when no config exists yet.
    """
    data: dict[str, Any] = {
        "version": CURRENT_SCHEMA_VERSION,
        "project": {"name": project_name},
        "vault": {"root": vault_root, "subfolder": subfolder},
        "sync": {
            "include": [
                "*.md",
                "docs/**/*.md",
                "docs/**/*.drawio",
                "docs/**/*.png",
                "docs/**/*.svg",
                ".obsidian/**",
            ],
            "exclude": [
                "raw/**",
                "scripts/**",
                "archive/**",
                ".git/**",
                ".claude/**",
                "node_modules/**",
                ".repomind/**",
            ],
        },
    }
    if description is not None:
        data["project"]["description"] = description
    if tags:
        data["project"]["tags"] = list(tags)
    return yaml.safe_dump(data, sort_keys=False, allow_unicode=True)
