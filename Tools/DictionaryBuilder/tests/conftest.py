#
#  conftest.py
#  KotobaLab
#
#  Created by shiinayane on 2026/05/17.
#

import pytest
import sqlite3
from pathlib import Path
from collections.abc import Iterator
from pipeline.export_sqlite import create_database


@pytest.fixture
def schema_path() -> Path:
    path = Path(__file__).resolve().parent.parent / "schema" / "dictionary_schema.sql"
    assert path.exists(), f"Schema file not found: {path}"
    return path


@pytest.fixture
def db_conn(tmp_path, schema_path) -> Iterator[sqlite3.Connection]:
    """Test fixture: provide a fresh SQLite connection backed by a clean DB"""

    output = tmp_path / "test.sqlite"
    conn = create_database(output, schema_path)
    yield conn
    conn.close()
