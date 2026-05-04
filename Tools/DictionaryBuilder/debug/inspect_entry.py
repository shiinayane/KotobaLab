#
#  inspect_entry.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/01.
#

import json
import sys
from pathlib import Path
from typing import Any
import pprint
from pipeline.parse import parse_semantic


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def extract_text(node: Any) -> str:
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


def inspect_entry(entry: list[Any]) -> None:
    print("=" * 80)
    print("📌 BASIC INFO")
    print("=" * 80)

    term = entry[0]
    reading = entry[1]
    content = entry[5]

    print(f"term:    {term}")
    print(f"reading: {reading}")

    print("\n" + "=" * 80)
    print("📦 RAW ENTRY (truncated)")
    print("=" * 80)

    pprint.pp(entry[:6])  # 不打印全部，太大

    print("\n" + "=" * 80)
    print("🧠 CONTENT STRUCTURE")
    print("=" * 80)

    pprint.pp(content)

    print("\n" + "=" * 80)
    print("📝 EXTRACTED TEXT")
    print("=" * 80)

    text = extract_text(content)
    print(text)

    semantic = parse_semantic(entry)

    print("\n" + "=" * 80)
    print("📏 SIZE INFO")
    print("=" * 80)
    print(semantic)

    raw_entry_size = len(json.dumps(entry, ensure_ascii=False))
    raw_content_size = len(json.dumps(content, ensure_ascii=False))
    text_size = len(text)

    print(f"raw_entry_json size:   {raw_entry_size} chars")
    print(f"raw_content_json size: {raw_content_size} chars")
    print(f"extracted_text size:   {text_size} chars")

    print("\n" + "=" * 80)
    print("🧪 QUICK INSIGHT")
    print("=" * 80)

    print("raw_entry_json / extracted_text ratio:",
          f"{raw_entry_size / max(text_size,1):.2f}x")


def main():
    if len(sys.argv) < 2:
        print("Usage: python inspect_entry.py <term_bank_file>")
        sys.exit(1)

    path = Path(sys.argv[1])

    entries = load_json(path)

    print(f"Loaded {len(entries)} entries\n")

    # 只看第一个
    inspect_entry(entries[0])


if __name__ == "__main__":
    main()
