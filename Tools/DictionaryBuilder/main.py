#
#  main.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/01.
#

from pathlib import Path

from pipeline.load import iter_term_bank_paths, load_term_bank
from pipeline.parse import parse_entry
from pipeline.transform import to_word_record, to_meaning_records
from pipeline.export_sqlite import create_database, insert_entry


SOURCE_DIR = Path("../../dataset/source/jitendex-yomitan")
OUTPUT_DB = Path("output/dictionary.sqlite")
SCHEMA_PATH = Path("schema/dictionary_schema.sql")


def main():
    print("📦 Building dictionary database...")

    conn = create_database(OUTPUT_DB, SCHEMA_PATH)

    total_entries = 0
    inserted_entries = 0

    for path in iter_term_bank_paths(SOURCE_DIR):
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
    print(f"DB path: {OUTPUT_DB.resolve()}")


if __name__ == "__main__":
    main()
