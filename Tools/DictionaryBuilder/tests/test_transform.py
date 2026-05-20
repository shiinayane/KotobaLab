#
#  test_transform.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/20.
#

import pytest
from models.dictionary_entry import ParsedDictionaryEntry
from pipeline.transform import to_meaning_records, to_word_record


class TestToWordRecord:
    def test_to_word_record_happy_path(self):
        entry = _make_parsed_entry()

        result = to_word_record(entry)

        assert result.term == "食べる"
        assert result.reading == "たべる"
        assert result.sequence == 1358280

    def test_to_word_record_edge_cases(self):
        entry = _make_parsed_entry(reading=None, sequence=None)

        result = to_word_record(entry)

        assert result.term == "食べる"
        assert result.reading is None
        assert result.sequence is None


class TestToMeaningRecords:
    def test_to_meaning_records_happy_path(self):
        entry = _make_parsed_entry()

        result = to_meaning_records(entry)

        assert len(result) == 1
        assert result[0].definition_text == "to eat"
        assert result[0].part_of_speech == "transitive"
        assert result[0].sequence == 1

    @pytest.mark.parametrize(
        "glosses, expected_definition_text",
        [
            (["to eat"], "to eat"),
            (["to eat", "to live on"], "to eat; to live on"),
        ],
        ids=[
            "single_gloss_returns_itself",
            "multiple_glosses_concatenated",
        ],
    )
    def test_to_meaning_records_glosses_handling(
        self, glosses, expected_definition_text
    ):
        entry = _make_parsed_entry(glosses=glosses)

        result = to_meaning_records(entry)

        assert result[0].definition_text == expected_definition_text

    def test_to_meaning_records_empty_gloss(self):
        entry = _make_parsed_entry(glosses=[])

        result = to_meaning_records(entry)

        assert result == []

    def test_to_meaning_records_with_no_pos(self):
        entry = _make_parsed_entry(part_of_speech=None)

        result = to_meaning_records(entry)

        assert result[0].part_of_speech is None


def _make_parsed_entry(**kwargs) -> ParsedDictionaryEntry:
    defaults = dict(
        term="食べる",
        reading="たべる",
        sequence=1358280,
        part_of_speech="transitive",
        glosses=["to eat"],
        forms=[],
    )

    return ParsedDictionaryEntry(**{**defaults, **kwargs})
