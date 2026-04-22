"""Entry point for `python -m repomind`."""

from __future__ import annotations

from repomind.cli import app


def main() -> None:
    """Invoke the Typer CLI."""
    app()


if __name__ == "__main__":
    main()
