#
#  load.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/04.
#

import json
from pathlib import Path
from typing import Any

def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)
    
def iter_term_bank_paths(source_dir: Path) -> list[Path]:
    return sorted(source_dir.glob("term_bank_*.json"))

def load_term_bank(path: Path) -> list[list[Any]]:
    data = load_json(path)
    
    if not isinstance(data, list):
        raise ValueError(f"Expected list in {path}, got {type(data).__name__}")
    
    return data