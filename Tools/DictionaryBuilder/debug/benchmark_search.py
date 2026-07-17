#
#  benchmark_search.py
#  KotobaLab
#
#  Created by shiinayane on 2026/05/14.
#

import argparse
import sqlite3
import time
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BASE_DIR / "output" / "dictionary.sqlite"

SEARCH_SQL = """
SELECT
    w.id,
    w.term,
    w.reading,
    preview.part_of_speech AS previewPartOfSpeech,
    preview.definition_text AS previewMeaning
FROM words AS w
LEFT JOIN meanings AS preview
    ON preview.id = (
        SELECT m.id
        FROM meanings AS m
        WHERE m.word_id = w.id
        ORDER BY m.sequence, m.id
        LIMIT 1
    )
WHERE
    w.term LIKE ?
    OR w.reading LIKE ?
LIMIT ?;
"""


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DB_PATH)
    parser.add_argument("--runs", type=int, default=100)
    parser.add_argument("--limit", type=int, default=50)
    return parser.parse_args()


def explain_query_plan(conn, query, limit):
    pattern = f"{query}%"
    rows = conn.execute(
        "EXPLAIN QUERY PLAN " + SEARCH_SQL, (pattern, pattern, limit)
    ).fetchall()

    print(f"\nQuery plan for {query!r}:")
    for row in rows:
        print(" ", row)


def benchmark_query(conn, query, runs, limit):
    pattern = f"{query}%"

    # warm-up
    conn.execute(SEARCH_SQL, (pattern, pattern, limit)).fetchall()

    durations = []

    for _ in range(runs):
        start = time.perf_counter()
        rows = conn.execute(SEARCH_SQL, (pattern, pattern, limit)).fetchall()
        end = time.perf_counter()

        durations.append((end - start) * 1000)

    return {
        "query": query,
        "rows": len(rows),
        "avg_ms": sum(durations) / len(durations),
        "min_ms": min(durations),
        "max_ms": max(durations),
    }


def main():
    args = parse_args()

    if not args.db.exists():
        raise FileNotFoundError(f"Database not found: {args.db}")

    conn = sqlite3.connect(args.db)

    # This matters because the default QUERY PLAN is SCAN words
    conn.execute("PRAGMA case_sensitive_like = ON")

    queries = ["日", "食", "見る", "あ", "zzzznotfound"]

    for query in queries:
        explain_query_plan(conn, query, args.limit)

    print("\nBenchmark results:")
    print("query, rows, avg_ms, min_ms, max_ms")

    for query in queries:
        result = benchmark_query(conn, query, args.runs, args.limit)
        print(
            f"{result['query']}, "
            f"{result['rows']}, "
            f"{result['avg_ms']:.3f}, "
            f"{result['min_ms']:.3f}, "
            f"{result['max_ms']:.3f}"
        )

    conn.close()


if __name__ == "__main__":
    main()
