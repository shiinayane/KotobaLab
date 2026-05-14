#
#  main.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/01.
#

import argparse
from pathlib import Path

from pipeline.load import iter_term_bank_paths, load_term_bank
from pipeline.parse import parse_entry
from pipeline.transform import to_word_record, to_meaning_records
from pipeline.export_sqlite import create_database, insert_entry

BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent.parent

SOURCE_DIR = PROJECT_ROOT / "dataset" / "source" / "jitendex-yomitan"
OUTPUT_DB = BASE_DIR / "output" / "dictionary.sqlite"
SCHEMA_PATH = BASE_DIR / "schema" / "dictionary_schema.sql"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build KotobaLab dictionary SQLite database from Yomitan source files."
    )

    parser.add_argument(
        "--source",
        type=Path,
        default=SOURCE_DIR,
        help="Path to the Yomitan dictionary source directory."
    )

    parser.add_argument(
        "--output",
        type=Path,
        default=OUTPUT_DB,
        help="Path to the output SQLite database."
    )
    
    parser.add_argument(
        "--schema",
        type=Path,
        default=SCHEMA_PATH,
        help="Path to the schema of the SQLite database."
    )

    return parser.parse_args()


def main():
    print("📦 Building dictionary database...")

    args = parse_args()

    source_dir = args.source
    output_db = args.output
    schema_path = args.schema

    if not source_dir.exists():
        raise FileNotFoundError(f"Source directory not found: {source_dir}")

    if not source_dir.is_dir():
        raise NotADirectoryError(
            f"Source Path is not a directory: {source_dir}")

    output_db.parent.mkdir(parents=True, exist_ok=True)
    
    if not schema_path.exists():
        raise FileNotFoundError(f"Schema of the database not found: {schema_path}")

    conn = create_database(output_db, schema_path)

    total_entries = 0
    inserted_entries = 0

    for path in iter_term_bank_paths(source_dir):
        print(f"📥 Loading {path.name}...")

        entries = load_term_bank(path)

        for entry in entries:
            total_entries += 1

            try:
                parsed = parse_entry(entry)

                word = to_word_record(parsed)
                meanings = to_meaning_records(parsed)

                if not meanings:
                    continue

                insert_entry(conn, word, meanings)
                inserted_entries += 1

            except Exception as e:
                print(f"⚠️ Error parsing entry: {e}")

    conn.commit()
    conn.close()

    print("\n✅ Done")
    print(f"Total entries:  {total_entries}")
    print(f"Inserted entries: {inserted_entries}")
    print(f"DB path: {output_db.resolve()}")


if __name__ == "__main__":
    main()
