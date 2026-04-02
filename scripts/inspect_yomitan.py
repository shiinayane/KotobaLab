#
#  inspect_yomitan.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/04/01.
#

import json
from pathlib import Path
from pprint import pprint


ROOT = Path("data/source/jitendex-yomitan")


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def main():
    index_path = ROOT / "index.json"
    term_bank_path = ROOT / "term_bank_1.json"

    index_data = load_json(index_path)
    term_data = load_json(term_bank_path)

    print("=== index.json ===")
    pprint(index_data)

    print("\n=== term_bank_1.json summary ===")
    print(f"type: {type(term_data)}")
    print(f"length: {len(term_data)}")

    print("\n=== first 3 entries ===")
    for i, entry in enumerate(term_data[:3], start=1):
        print(f"\n--- entry {i} ---")
        pprint(entry)
        print(f"entry type: {type(entry)}")
        if isinstance(entry, list):
            print(f"entry field count: {len(entry)}")


if __name__ == "__main__":
    main()
