#
#  find_entry.py
#  KotobaLab
#
#  Created by shiinayane on 2026/05/20.
#

import json
import sys
from pathlib import Path
from pprint import pprint

# CLI: uv run debug/find_entry.py <dataset_dir> <term>
dataset_dir = Path(sys.argv[1])
target_term = sys.argv[2]

bank_files = sorted(dataset_dir.glob("term_bank_*.json"))
print(f"Searching {len(bank_files)} bank files for term: {target_term!r}")

found = []
for bank_file in bank_files:
    with bank_file.open(encoding="utf-8") as f:
        entries = json.load(f)
    for i, entry in enumerate(entries):
        if entry[0] == target_term:
            found.append((bank_file.name, i, entry))

print(f"\nFound {len(found)} matches\n")

for bank_name, idx, entry in found:
    print(f"--- {bank_name} [#{idx}] ---")
    print(f"term:    {entry[0]}")
    print(f"reading: {entry[1]}")
    print(f"sequence: {entry[6]}")
    print()

# 詳細を見たい場合（最初の 1 件だけ）
if found and "--verbose" in sys.argv:
    print("\n========== FIRST MATCH FULL ENTRY ==========\n")
    pprint(found[0][2])
