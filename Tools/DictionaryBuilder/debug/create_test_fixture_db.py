#
#  create_test_fixture_db.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/15.
#

import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
SCHEMA_PATH = BASE_DIR / "schema" / "dictionary_schema.sql"
OUTPUT_PATH = Path("KotobaLabTests/Fixtures/test_dictionary.sqlite")
OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

if OUTPUT_PATH.exists():
    OUTPUT_PATH.unlink()

conn = sqlite3.connect(OUTPUT_PATH)

with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
    conn.executescript(f.read())

conn.executemany(
    """
    INSERT INTO words (id, term, reading, sequence)
    VALUES (?, ?, ?, ?)
    """,
    [
        (1, "日本", "にほん", 1),
        (2, "食べる", "たべる", 2),
        (3, "見る", "みる", 3),
        (4, "学校", "がっこう", 4),
    ],
)

conn.executemany(
    """
    INSERT INTO meanings (id, word_id, sequence, definition_text, part_of_speech)
    VALUES (?, ?, ?, ?, ?)
    """,
    [
        (1, 1, 1, "Japan", "noun"),
        (2, 1, 2, "Japanese", "noun"),
        (3, 2, 1, "to eat", "verb"),
        (4, 3, 1, "to see", "verb"),
        (5, 4, 1, "school", "noun"),
    ],
)

conn.commit()
conn.close()

print(f"Created fixture DB: {OUTPUT_PATH}")
