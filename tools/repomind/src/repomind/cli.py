"""Typer-based CLI for repomind.

Commands:
    repomind init   — write a starter `.repomind.yml` in the current repo
    repomind sync   — copy changes from the repo into the Obsidian vault
    repomind --version

The CLI is deliberately thin: all logic lives in `config`, `state`, `sync`,
`util`. The CLI only parses arguments, delegates, and renders output.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path

import typer
from rich.console import Console
from rich.table import Table

from repomind import __version__
from repomind.config import (
    CONFIG_FILENAME,
    ConfigError,
    load_config,
    render_config_yaml,
)
from repomind.state import load_state, save_state
from repomind.sync import OpKind, apply_plan, plan_sync

app = typer.Typer(
    name="repomind",
    help="Deterministic repo-to-Obsidian-vault sync for claude-hangar workflows.",
    no_args_is_help=True,
    add_completion=False,
)

console = Console()


def _version_callback(value: bool) -> None:
    """Print version and exit when `--version` is passed."""
    if value:
        console.print(f"repomind {__version__}")
        raise typer.Exit(code=0)


@app.callback()
def _root(
    version: bool = typer.Option(
        False,
        "--version",
        help="Show version and exit.",
        callback=_version_callback,
        is_eager=True,
    ),
    verbose: bool = typer.Option(
        False,
        "-v",
        "--verbose",
        help="Enable verbose logging.",
    ),
) -> None:
    """Top-level options shared by all subcommands."""
    level = logging.DEBUG if verbose else logging.WARNING
    logging.basicConfig(format="%(levelname)s: %(message)s", level=level)


@app.command()
def init(
    project_name: str = typer.Option(..., "--project-name", help="Project display name."),
    vault_root: str = typer.Option(..., "--vault-root", help="Absolute path to the Obsidian vault root."),
    subfolder: str = typer.Option(..., "--subfolder", help="Subfolder name inside the vault."),
    description: str | None = typer.Option(None, "--description", help="Optional project description."),
    force: bool = typer.Option(False, "--force", help="Overwrite an existing .repomind.yml."),
    config_path: Path = typer.Option(  # noqa: B008
        Path(CONFIG_FILENAME),
        "--config",
        help="Where to write the config (default: ./.repomind.yml).",
    ),
) -> None:
    """Write a starter `.repomind.yml` in the current repository."""
    if config_path.exists() and not force:
        typer.secho(
            f"{config_path} already exists. Pass --force to overwrite.",
            fg=typer.colors.RED,
            err=True,
        )
        raise typer.Exit(code=1)

    body = render_config_yaml(
        project_name=project_name,
        vault_root=vault_root,
        subfolder=subfolder,
        description=description,
    )
    config_path.write_text(body, encoding="utf-8")
    console.print(f"[green]Wrote[/green] {config_path}")


@app.command()
def sync(
    config_path: Path = typer.Option(  # noqa: B008
        Path(CONFIG_FILENAME),
        "--config",
        help="Path to the .repomind.yml (default: ./.repomind.yml).",
    ),
    dry_run: bool = typer.Option(False, "--dry-run", help="Compute the plan without touching the filesystem."),
    force: bool = typer.Option(False, "--force", help="Re-copy every matched file, ignoring cached hashes."),
) -> None:
    """Sync tracked files from the repo into the configured vault subfolder."""
    try:
        config = load_config(config_path)
    except ConfigError as exc:
        typer.secho(f"Config error: {exc}", fg=typer.colors.RED, err=True)
        raise typer.Exit(code=1) from exc

    repo_root = config_path.resolve().parent
    state = load_state(repo_root)
    operations = plan_sync(config, state, repo_root, force=force)
    summary = apply_plan(operations, state, dry_run=dry_run)

    table = Table(title=("Plan (dry-run)" if dry_run else "Sync result"))
    table.add_column("Kind", style="bold")
    table.add_column("Count", justify="right")
    table.add_row("new", str(summary.new))
    table.add_row("changed", str(summary.changed))
    table.add_row("deleted", str(summary.deleted))
    table.add_row("unchanged", str(summary.unchanged), style="dim")
    console.print(table)

    if logging.getLogger().isEnabledFor(logging.DEBUG):
        for op in summary.operations:
            if op.kind is OpKind.UNCHANGED:
                continue
            console.print(f"  [{op.kind.value}] {op.rel_path}")

    if not dry_run and summary.total_written + summary.deleted > 0:
        save_state(state, repo_root)

    if dry_run:
        console.print("[yellow]Dry-run — no changes written.[/yellow]")


def main() -> None:
    """Console-script entry point."""
    try:
        app()
    except KeyboardInterrupt:
        typer.secho("Interrupted.", fg=typer.colors.RED, err=True)
        sys.exit(130)


if __name__ == "__main__":
    main()
