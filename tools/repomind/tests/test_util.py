"""Tests for repomind.util."""

from __future__ import annotations

from pathlib import Path

from repomind.util import (
    compile_spec,
    ensure_parent,
    iter_matching_files,
    relpath_posix,
    sha256_file,
)


def test_sha256_file_stable(tmp_path: Path) -> None:
    """Same content → same hash; different content → different hash."""
    a = tmp_path / "a.txt"
    b = tmp_path / "b.txt"
    a.write_bytes(b"hello")
    b.write_bytes(b"hello")
    assert sha256_file(a) == sha256_file(b)
    assert sha256_file(a).startswith("sha256:")
    b.write_bytes(b"world")
    assert sha256_file(a) != sha256_file(b)


def test_compile_spec_matches_gitwildmatch() -> None:
    """`**` and `*.ext` patterns behave like gitignore."""
    spec = compile_spec(["docs/**/*.md", "*.md"])
    assert spec.match_file("docs/foo/bar.md")
    assert spec.match_file("README.md")
    assert not spec.match_file("src/main.py")


def test_iter_matching_files_respects_include_exclude(tmp_repo: Path) -> None:
    """Exclude wins over include; results are deterministic and sorted."""
    files = list(iter_matching_files(tmp_repo, ["*.md", "docs/**/*.md"], ["raw/**", "scripts/**"]))
    rels = [relpath_posix(f, tmp_repo) for f in files]
    assert "README.md" in rels
    assert "Dashboard.md" in rels
    assert "docs/INDEX.md" in rels
    assert "docs/infra/firewall.md" in rels
    assert "raw/secrets.txt" not in rels
    assert "scripts/build.sh" not in rels
    assert rels == sorted(rels)


def test_ensure_parent_creates_recursively(tmp_path: Path) -> None:
    """`ensure_parent` creates all missing parent dirs; no-op if present."""
    target = tmp_path / "a" / "b" / "c" / "file.md"
    ensure_parent(target)
    assert target.parent.is_dir()
    # Second call is a no-op, no error raised.
    ensure_parent(target)


def test_relpath_posix_uses_forward_slashes(tmp_path: Path) -> None:
    """Relative paths always use POSIX separators regardless of platform."""
    root = tmp_path / "root"
    child = root / "sub" / "x.md"
    child.parent.mkdir(parents=True)
    child.write_text("x", encoding="utf-8")
    assert relpath_posix(child, root) == "sub/x.md"
