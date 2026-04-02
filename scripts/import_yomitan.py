#
#  import_yomitan.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/04/01.
#

from typing import Any


def parse_entry(entry: list[Any]) -> dict:
    term = entry[0]
    reading = entry[1]
    definitions = entry[5] if len(entry) > 5 else []

    if isinstance(definitions, str):
        definitions = [definitions]

    return {
        "term": term,
        "reading": reading,
        "definitions": definitions,
        "raw": entry,
    }
