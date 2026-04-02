#
#  text_extractor.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/04/01.
#

import json
from pathlib import Path
from typing import Any

NOISE_TOKENS = {
    "JMdict",
    "Explanation",
    "unclass",
}

def clean_extracted_text(text: str) -> str:
    parts = text.split()
    filtered = [part for part in parts if part not in NOISE_TOKENS]
    return " ".join(filtered).strip()

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
        # Most useful text is inside the `content` field
        if "content" in node:
            return extract_text(node["content"])
        return ""

    return str(node)


def main():
    root = Path("data/source/jitendex-yomitan")
    term_bank_path = root / "term_bank_1.json"

    with term_bank_path.open("r", encoding="utf-8") as f:
        entries = json.load(f)

    for i, entry in enumerate(entries[:3], start=1):
        term = entry[0]
        reading = entry[1]
        content = entry[5]
        sequence = entry[6]

        text = clean_extracted_text(extract_text(content))

        print(f"\n--- Entry {i} ---")
        print(f"term     : {term}")
        print(f"reading  : {reading}")
        print(f"sequence : {sequence}")
        print("text     :")
        print(text)
        print("-" * 40)


if __name__ == "__main__":
    main()
