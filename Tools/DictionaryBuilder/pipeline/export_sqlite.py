#
#  export_sqlite.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/04.
#

import sqlite3
from pathlib import Path

from models.dictionary_entry import WordRecord, MeaningRecord


def create_database(output_path: Path, schema_path: Path) -> sqlite3.Connection:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if output_path.exists():
        output_path.unlink()

    conn = sqlite3.connect(output_path)

    with schema_path.open("r", encoding="utf-8") as file:
        schema_sql = file.read()

    conn.executescript(schema_sql)
    return conn


def insert_word(conn: sqlite3.Connection, word: WordRecord) -> int:
    cursor = conn.execute(
        """
        INSERT INTO words (term, reading, sequence)
        VALUES (?, ?, ?)
        """,
        (
            word.term,
            word.reading,
            word.sequence
        ),
    )
    
    word_id = cursor.lastrowid
    
    if word_id is None:
        raise RuntimeError("Failed to get last inserted word_id")

    return word_id


def insert_meanings(
    conn: sqlite3.Connection,
    word_id: int,
    meanings: list[MeaningRecord],
) -> None:
    for meaning in meanings:
        conn.execute(
            """
            INSERT INTO meanings (
                word_id,
                sequence,
                part_of_speech,
                definition_text
            )
            VALUES (?, ?, ?, ?)
            """,
            (
                word_id,
                meaning.sequence,
                meaning.part_of_speech,
                meaning.definition_text
            ),
        )


def insert_entry(
    conn: sqlite3.Connection,
    word: WordRecord,
    meanings: list[MeaningRecord],
) -> None:
    if not meanings:
        return

    word_id = insert_word(conn, word)
    insert_meanings(conn, word_id, meanings)
