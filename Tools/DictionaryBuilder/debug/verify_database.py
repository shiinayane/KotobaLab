#
#  verify_database.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/15.
#

import argparse
import sqlite3
from pathlib import Path


REQUIRED_TABLES = {
    "words",
    "meanings",
}

REQUIRED_INDEXES = {
    "idx_words_term",
    "idx_words_reading",
    "idx_meanings_word_id",
}

MAX_DB_SIZE_MB = 100

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "output" / "dictionary.sqlite"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Verify KotobaLab dictionary SQLite database."
    )

    parser.add_argument(
        "--db",
        type=Path,
        default=DB_PATH,
        help="Path to dictionary.sqlite"
    )

    parser.add_argument(
        "--max-size-mb",
        type=float,
        default=MAX_DB_SIZE_MB,
        help="Maximum allowed database size in MB."
    )

    return parser.parse_args()


def fail(message: str):
    raise RuntimeError(f"❌ {message}")


def check_file_exists(db_path: Path):
    if not db_path.exists():
        fail(f"Database not found: {db_path}")

    if not db_path.is_file():
        fail(f"Database path is not a file: {db_path}")


def check_file_size(db_path: Path, max_size_mb: float):
    size_mb = db_path.stat().st_size / 1024 / 1024

    print(f"DB size: {size_mb:.2f} MB")

    if size_mb > max_size_mb:
        fail(
            f"Database size too large: {size_mb:.2f} MB > {max_size_mb:.2f} MB")


def fetch_names(conn: sqlite3.Connection, type_name: str) -> set[str]:
    rows = conn.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type = ?
        """, (type_name,)
    ).fetchall()

    return {row[0] for row in rows}


def check_required_tables(conn: sqlite3.Connection):
    tables = fetch_names(conn, "table")
    missing = REQUIRED_TABLES - tables

    if missing:
        fail(f"Missing required tables: {sorted(missing)}")

    print(f"Tables OK: {sorted(REQUIRED_TABLES)}")


def check_required_indexes(conn: sqlite3.Connection):
    indexes = fetch_names(conn, "index")
    missing = REQUIRED_INDEXES - indexes

    if missing:
        fail(f"Missing required indexes: {sorted(missing)}")

    print(f"Indexes OK: {sorted(REQUIRED_INDEXES)}")


def explain(conn: sqlite3.Connection, sql: str, params=()):
    return conn.execute(
        "EXPLAIN QUERY PLAN " + sql,
        params
    ).fetchall()


def plan_text(plan_rows) -> str:
    return "\n".join(str(row) for row in plan_rows)


def check_search_query_uses_index(conn: sqlite3.Connection):
    conn.execute("PRAGMA case_sensitive_like = ON")

    sql = """
    SELECT id, term, reading
    FROM words
    WHERE term LIKE ?
    LIMIT 50
    """

    plan = explain(conn, sql, ("見る%",))
    text = plan_text(plan)

    print("\nSearch query plan:")
    print(text)

    if "SCAN words" in text:
        fail("Search query is scanning words table.")

    if "idx_words_term" not in text:
        fail("Search query is not using idx_words_term.")


def check_meaning_detail_uses_index(conn: sqlite3.Connection):
    sql = """
    SELECT id, word_id, sequence, definition_text
    FROM meanings
    WHERE word_id = ?
    ORDER BY sequence
    """

    plan = explain(conn, sql, (1,))
    text = plan_text(plan)

    print("\nMeaning detail query plan:")
    print(text)

    if "SCAN meanings" in text:
        fail("Meaning detail query is scanning meanings table.")

    if "idx_meanings_word_id" not in text:
        fail("Meaning detail query is not using idx_meanings_word_id.")


def main():
    args = parse_args()

    db_path = args.db

    check_file_exists(db_path)
    check_file_size(db_path, args.max_size_mb)

    conn = sqlite3.connect(db_path)

    try:
        check_required_tables(conn)
        check_required_indexes(conn)
        check_search_query_uses_index(conn)
        check_meaning_detail_uses_index(conn)

    finally:
        conn.close()

    print("\n✅ Database verification passed.")


if __name__ == "__main__":
    main()
