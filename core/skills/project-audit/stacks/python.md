# Stack-Supplement: Python

Python-spezifische Projekt-Audit-Checks. Nur §-Sektionen laden die zur aktuellen Phase passen.
Erkennung: `pyproject.toml`, `setup.py`, oder `requirements.txt` vorhanden.

---

## §Struktur

- [ ] Projekt-Layout: `src/` Layout oder Flat Layout? Konsistent?
- [ ] `__init__.py`: In allen Packages vorhanden?
- [ ] `pyproject.toml`: Modernes Build-System? (nicht nur setup.py)
- [ ] `src/` Layout: `src/{package}/` fuer saubere Import-Trennung?
- [ ] Entry Points: `[project.scripts]` in pyproject.toml?
- [ ] Konfig: `pyproject.toml` als zentrale Config (statt setup.cfg + .flake8 + ...)

## §Dependencies

- [ ] Dependency-Management: poetry, pip-tools, pdm, uv?
- [ ] `requirements.txt`: Versionen gepinnt? (`==` statt `>=`)
- [ ] `pyproject.toml`: `[project.dependencies]` definiert?
- [ ] Dev-Dependencies getrennt? (`[project.optional-dependencies]` dev)
- [ ] Virtual Environment: `.venv/` in `.gitignore`?
- [ ] Python-Version: `.python-version` oder `python_requires`?
- [ ] `pip audit`: Bekannte CVEs in Dependencies?

## §Code

- [ ] Type Hints: Durchgehend genutzt? (Python 3.10+ Syntax)
- [ ] `mypy` / `pyright`: Strict Mode? Null Fehler?
- [ ] Docstrings: Google/NumPy/Sphinx Style? Konsistent?
- [ ] f-Strings statt `.format()` / `%`?
- [ ] Context Manager: `with` fuer Dateien/Connections?
- [ ] Comprehensions: List/Dict-Comprehensions statt Schleifen wo sinnvoll?
- [ ] `pathlib.Path` statt `os.path`?

## §Git

- [ ] `.gitignore`: `__pycache__/`, `*.pyc`, `.venv/`, `*.egg-info/`, `dist/`?
- [ ] `pyproject.toml`: Committet? (ist die Build-Config)
- [ ] `requirements*.txt`: Committet und aktuell?

## §CICD

- [ ] Python-Version in CI: Matrix-Build? (3.11, 3.12, 3.13)
- [ ] `pip install -r requirements.txt` oder `poetry install` in CI?
- [ ] Cache: `pip` oder `.venv` gecacht?
- [ ] `pip install -e .`: Editable Install fuer Tests?
- [ ] PyPI-Publish: Automated? (twine, flit, poetry publish)

## §Dokumentation

- [ ] Docstrings: Alle oeffentlichen Funktionen/Klassen dokumentiert?
- [ ] Sphinx/MkDocs: Doku-Generator konfiguriert?
- [ ] Type Stubs: Fuer exportierte APIs? (`py.typed` Marker)
- [ ] README: Installation mit pip/poetry dokumentiert?

## §Testing

- [ ] Test-Framework: pytest, unittest?
- [ ] `pytest` konfiguriert? (`pyproject.toml` oder `pytest.ini`)
- [ ] Coverage: `pytest-cov` konfiguriert? Schwellwert?
- [ ] Fixtures: Wiederverwendbar? Nicht zu komplex?
- [ ] `mypy` / Type-Check in CI?
- [ ] Linting: ruff, flake8, pylint?
- [ ] Formatting: black, ruff format?

## §Security

- [ ] `pip audit`: Null CRITICAL/HIGH?
- [ ] `eval()`, `exec()`: Nicht verwendet?
- [ ] `subprocess.shell=True`: Vermieden? (Injection-Risiko)
- [ ] `pickle.load()`: Nur vertrauenswuerdige Daten?
- [ ] SQL: Parameterized Queries? (kein f-String SQL)
- [ ] `os.system()`: Nicht verwendet? (`subprocess.run` stattdessen)
- [ ] Secrets: Nicht in `.py` Dateien hardcodiert?

## §Deployment

- [ ] `pip install` mit Constraints-File fuer reproduzierbare Installs?
- [ ] Docker: Python-slim Base-Image? Nicht `:latest`?
- [ ] Virtual Environment in Docker? (oder system-wide mit `--break-system-packages`)
- [ ] gunicorn/uvicorn: Korrekte Worker-Config?
- [ ] Systemd-Service: Fuer langlebige Prozesse?

## §Maintenance

- [ ] Python EOL-Schedule: Version noch supported?
- [ ] Deprecated stdlib: `asyncio.get_event_loop()`, `datetime.utcnow()` etc.?
- [ ] `pyproject.toml` vs. `setup.py`: Migration zu modernem Format?
- [ ] Tool-Migration: flake8 → ruff, black → ruff format?
- [ ] Dependency-Updates: Automatisiert? (Dependabot, Renovate)
