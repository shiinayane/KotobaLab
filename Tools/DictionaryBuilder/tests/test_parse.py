#
#  test_parse.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/20.
#

from pipeline.parse import parse_entry


def test_parse_entry_happy_path():
    # Arrange: 最小限の entry を組み立てる
    entry = _make_entry(_make_content(pos_values=["1-dan"], glossaries=[["to eat"]]))

    # Act: parse_entry を呼ぶ
    result = parse_entry(entry)

    # Assert: 各フィールドが期待通りか確認
    assert result.term == "食べる"
    assert result.reading == "たべる"
    assert result.sequence == 1358280
    assert result.part_of_speech == "1-dan"
    assert result.glosses == ["to eat"]
    assert result.forms == []


def test_parse_entry_multiple_pos_keeps_last():
    entry = _make_entry(
        _make_content(pos_values=["1-dan", "transitive"], glossaries=[["to eat"]])
    )

    result = parse_entry(entry)

    assert result.term == "食べる"
    assert result.reading == "たべる"
    assert result.sequence == 1358280
    assert result.part_of_speech == "transitive"
    assert result.glosses == ["to eat"]
    assert result.forms == []


def test_parse_entry_multiple_glossaries_are_concatenated():
    entry = _make_entry(
        _make_content(
            pos_values=["1-dan", "transitive"], glossaries=[["to eat"], ["to live on"]]
        )
    )

    result = parse_entry(entry)

    assert result.term == "食べる"
    assert result.reading == "たべる"
    assert result.sequence == 1358280
    assert result.part_of_speech == "transitive"
    assert result.glosses == ["to eat", "to live on"]
    assert result.forms == []


def _make_entry(content: list) -> list:
    """Build a Yomitan-style entry with given content tree."""
    return [
        "食べる",  # term
        "たべる",  # reading
        "★",  # definition tags (unused)
        "v1",  # rules (unused)
        200,  # score (unused)
        content,  # content
        1358280,  # sequence
        "",  # term tags (unused)
    ]


def _make_content(pos_values: list[str], glossaries: list[list[str]]) -> list[dict]:
    """
    Build a structured-content tree with given POS spans and glossary uls.

    Note:
        Each glossary ul currently contains exactly 1 li (use ul[0]).
        Extend this helper if testing multi-li glossaries.

    Args:
        pos_values: POS strings, one per <span part-of-speech-info>
        glossaries: list of glossary uls, each ul is a list of gloss strings
    """

    pos_spans = [
        {
            "tag": "span",
            "data": {"content": "part-of-speech-info"},
            "content": pos,
        }
        for pos in pos_values
    ]

    gloss_uls = [
        {
            "tag": "ul",
            "data": {"content": "glossary"},
            "content": {"tag": "li", "content": ul[0]},
        }
        for ul in glossaries
    ]

    return [
        {
            "type": "structured-content",
            "content": [
                {
                    "tag": "div",
                    "data": {"content": "sense-group"},
                    "content": [
                        *pos_spans,
                        {
                            "tag": "div",
                            "data": {"content": "sense"},
                            "content": gloss_uls,
                        },
                    ],
                }
            ],
        }
    ]
