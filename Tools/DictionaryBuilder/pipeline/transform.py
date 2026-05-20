#
#  transform.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/04.
#

from models.dictionary_entry import ParsedDictionaryEntry, WordRecord, MeaningRecord


def to_word_record(entry: ParsedDictionaryEntry) -> WordRecord:
    return WordRecord(term=entry.term, reading=entry.reading, sequence=entry.sequence)


def to_meaning_records(entry: ParsedDictionaryEntry) -> list[MeaningRecord]:
    if not entry.glosses:
        return []

    definition_text = "; ".join(entry.glosses)

    return [
        MeaningRecord(
            sequence=1,
            part_of_speech=entry.part_of_speech,
            definition_text=definition_text,
        )
    ]
