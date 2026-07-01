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
SELECT w.id, w.term, w.reading,
  (
    SELECT m.definition_text
    FROM meanings m
    WHERE m.word_id = w.id
    ORDER BY m.id
    LIMIT 1
  ) AS preview_meaning
FROM words w
WHERE w.term LIKE ? OR w.reading LIKE ?
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
    """
    Benchmark results (WHERE w.term LIKE ? OR w.reading LIKE ?):
        query, rows, avg_ms, min_ms, max_ms
        日, 50, 0.864, 0.787, 1.214
        食, 50, 1.923, 1.842, 2.477
        見る, 21, 16.883, 16.421, 17.737
        あ, 50, 0.044, 0.043, 0.057
        zzzznotfound, 0, 16.202, 15.857, 16.764

    Benchmark results (WHERE w.term LIKE ?):
        query, rows, avg_ms, min_ms, max_ms
        日, 50, 0.533, 0.488, 0.707
        食, 50, 1.190, 1.105, 1.315
        見る, 21, 11.207, 10.550, 12.109
        あ, 50, 0.297, 0.269, 0.355
        zzzznotfound, 0, 11.041, 10.671, 11.509
        
    Benchmark results ("PRAGMA case_sensitive_like = ON"):
        query, rows, avg_ms, min_ms, max_ms
        日, 50, 0.197, 0.051, 1.455
        食, 50, 0.099, 0.056, 0.398
        見る, 21, 0.034, 0.028, 0.080
        あ, 50, 0.062, 0.051, 0.205
        zzzznotfound, 0, 0.012, 0.011, 0.016
    """
    main()
