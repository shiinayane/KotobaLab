#
#  build_dictionary_db.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/04/01.
#

import json
import sqlite3
from pathlib import Path
from typing import Any


SOURCE_DIR = Path("data/source/jitendex-yomitan")
OUTPUT_DB = Path("data/output/dictionary.sqlite")

NOISE_TOKENS = {
    "JMdict",
    "Explanation",
    "unclass",
}


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def extract_text(node: Any) -> str:
    """Recursively flatten Yomitan structured content into plain text."""
    if node is None:
        return ""

    if isinstance(node, str):
        return node

    if isinstance(node, list):
        parts = [extract_text(item) for item in node]
        return " ".join(part for part in parts if part.strip())

    if isinstance(node, dict):
        if "content" in node:
            return extract_text(node["content"])
        return ""

    return str(node)


def clean_extracted_text(text: str) -> str:
    """Remove obvious UI/meta noise from extracted text."""
    parts = text.split()
    filtered = [part for part in parts if part not in NOISE_TOKENS]
    return " ".join(filtered).strip()

#   解析并制作条目
def parse_entry(entry: list[Any]) -> dict[str, Any]:
    term = entry[0]
    reading = entry[1]
    raw_content = entry[5]
    source_sequence = entry[6]

    extracted_text = extract_text(raw_content)
    cleaned_text = clean_extracted_text(extracted_text)

    return {
        "term": term,
        "reading": reading,
        "source_sequence": source_sequence,
        "definition_text": cleaned_text,
        "raw_entry_json": json.dumps(entry, ensure_ascii=False),
        "raw_content_json": json.dumps(raw_content, ensure_ascii=False),
    }


def create_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        DROP TABLE IF EXISTS meanings;
        DROP TABLE IF EXISTS words;

        CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            term TEXT NOT NULL,
            reading TEXT,
            sequence INTEGER,
            raw_entry_json TEXT
        );

        CREATE TABLE meanings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word_id INTEGER NOT NULL,
            sequence INTEGER NOT NULL,
            definition_text TEXT NOT NULL,
            raw_content_json TEXT,
            FOREIGN KEY (word_id) REFERENCES words(id)
        );

        CREATE INDEX idx_words_term ON words(term);
        CREATE INDEX idx_words_reading ON words(reading);
        CREATE INDEX idx_words_sequence ON words(sequence);
        """
    )


def insert_entry(conn: sqlite3.Connection, parsed: dict[str, Any]) -> None:
    cursor = conn.execute(
        """
        INSERT INTO words (term, reading, sequence, raw_entry_json)
        VALUES (?, ?, ?, ?)
        """,
        (
            parsed["term"],
            parsed["reading"],
            parsed["source_sequence"],
            parsed["raw_entry_json"],
        ),
    )
    word_id = cursor.lastrowid

    conn.execute(
        """
        INSERT INTO meanings (word_id, sequence, definition_text, raw_content_json)
        VALUES (?, ?, ?, ?)
        """,
        (
            word_id,
            1,
            parsed["definition_text"],
            parsed["raw_content_json"],
        ),
    )


def import_term_bank(conn: sqlite3.Connection, path: Path) -> None:
    entries = load_json(path)

    for entry in entries:
        parsed = parse_entry(entry)
        insert_entry(conn, parsed)


def main() -> None:
    OUTPUT_DB.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(OUTPUT_DB)
    create_schema(conn)

    # Start with one file only
    # import_term_bank(conn, SOURCE_DIR / "term_bank_1.json")

    for path in sorted(SOURCE_DIR.glob("term_bank_*.json")):
        print(f"Importing {path.name}...")
        import_term_bank(conn, path)

    conn.commit()
    conn.close()

    print(f"Database created at: {OUTPUT_DB}")


if __name__ == "__main__":
    main()
