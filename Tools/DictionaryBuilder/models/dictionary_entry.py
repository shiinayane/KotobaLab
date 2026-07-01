#
#  dictionary_entry.py
#  KotobaLab
#
#  Created by shiinayane on 2026/05/04.
#

from dataclasses import dataclass


@dataclass(frozen=True)
class ParsedDictionaryEntry:
    term: str
    reading: str | None
    sequence: int | None
    part_of_speech: str | None
    glosses: list[str]
    forms: list[str]


@dataclass(frozen=True)
class WordRecord:
    term: str
    reading: str | None
    sequence: int | None


@dataclass(frozen=True)
class MeaningRecord:
    sequence: int
    part_of_speech: str | None
    definition_text: str
