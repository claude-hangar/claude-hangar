"""Utility helpers — hashing, path walking, safe path handling."""

from __future__ import annotations

import hashlib
from collections.abc import Iterable, Iterator
from pathlib import Path

import pathspec

_HASH_CHUNK = 65536


def sha256_file(path: Path) -> str:
    """Return the streamed SHA-256 hex digest of `path`.

    Streams in 64 KiB chunks so large files do not blow the heap.
    """
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(_HASH_CHUNK), b""):
            digest.update(chunk)
    return f"sha256:{digest.hexdigest()}"


def compile_spec(patterns: Iterable[str]) -> pathspec.PathSpec:
    """Compile gitignore-style patterns into a `PathSpec`.

    Uses gitwildmatch so `**`, `*.ext`, `dir/` etc. behave the same as in
    gitignore. Empty iterables produce a spec that matches nothing.
    """
    return pathspec.PathSpec.from_lines("gitignore", patterns)


def iter_matching_files(
    root: Path,
    include: Iterable[str],
    exclude: Iterable[str],
) -> Iterator[Path]:
    """Yield files under `root` that match `include` and do not match `exclude`.

    Paths are yielded as absolute `Path` objects. Returns in deterministic
    order sorted by the POSIX relative path (case-sensitive) so plans stay
    reproducible across platforms — Windows `Path` ordering is case-insensitive
    which would otherwise drift from Unix behavior.
    """
    include_spec = compile_spec(include)
    exclude_spec = compile_spec(exclude)
    root = root.resolve()

    matches: list[tuple[str, Path]] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        if exclude_spec.match_file(rel):
            continue
        if include_spec.match_file(rel):
            matches.append((rel, path))

    matches.sort(key=lambda pair: pair[0])
    for _rel, path in matches:
        yield path


def ensure_parent(path: Path) -> None:
    """Create `path.parent` recursively if missing. No-op if it exists."""
    path.parent.mkdir(parents=True, exist_ok=True)


def relpath_posix(path: Path, root: Path) -> str:
    """Return `path` relative to `root` as a POSIX-style string."""
    return path.relative_to(root).as_posix()
