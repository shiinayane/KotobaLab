#
#  test_export_sqlite.py
#  KotobaLab
#
#  Created by shiinayane on 2026/05/20.
#

from models.dictionary_entry import WordRecord, MeaningRecord
from pipeline.export_sqlite import (
    create_database,
    insert_entry,
)


class TestCreateDatabase:
    # create_database 関連
    def test_create_database_creates_file_with_schema(self, tmp_path, schema_path):
        output = tmp_path / "test.sqlite"
        conn = create_database(output, schema_path)
        assert output.exists()

        cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cursor.fetchall()]
        assert "words" in tables and "meanings" in tables

        cursor = conn.execute("PRAGMA table_info(words)")
        words_columns = [row[1] for row in cursor.fetchall()]
        assert words_columns == ["id", "term", "reading", "sequence"]

        cursor = conn.execute("PRAGMA table_info(meanings)")
        meanings_columns = [row[1] for row in cursor.fetchall()]
        assert meanings_columns == [
            "id",
            "word_id",
            "sequence",
            "part_of_speech",
            "definition_text",
        ]

        conn.close()

    def test_create_database_overwrites_existing(self, tmp_path, schema_path):
        output = tmp_path / "test.sqlite"

        # 1. 既存 DB を作って、識別可能な「古い」状態を作る
        conn1 = create_database(output, schema_path)
        conn1.execute(
            "INSERT INTO words (term, reading, sequence) VALUES ('old', 'old', 1)"
        )
        conn1.commit()
        conn1.close()

        # 2. もう一度 create_database を呼ぶと、古いデータは消える
        conn2 = create_database(output, schema_path)
        cursor = conn2.execute("SELECT COUNT(*) FROM words")
        assert cursor.fetchone()[0] == 0  # 古いデータが消えている

        conn2.close()


class TestInsertEntry:
    # insert_entry 関連（insert_word / insert_meanings も間接的にカバー）
    def test_insert_entry_happy_path(self, db_conn):
        word = _make_word_record()
        meanings = [_make_meaning_record()]

        insert_entry(db_conn, word, meanings)

        cursor = db_conn.execute("SELECT id, term, reading, sequence FROM words")
        word_rows = cursor.fetchall()
        assert len(word_rows) == 1
        word_id, term, reading, word_sequence = word_rows[0]
        assert term == "食べる"
        assert reading == "たべる"
        assert word_sequence == 1358280

        cursor = db_conn.execute(
            "SELECT word_id, sequence, part_of_speech, definition_text FROM meanings"
        )
        meaning_rows = cursor.fetchall()
        assert len(meaning_rows) == 1
        meaning_word_id, meaning_sequence, part_of_speech, definition_text = (
            meaning_rows[0]
        )
        assert meaning_sequence == 1
        assert part_of_speech == "1-dan"
        assert definition_text == "to eat"

        assert word_id == meaning_word_id

    def test_insert_entry_skips_when_no_meanings(self, db_conn):
        word = _make_word_record()
        meanings = []

        insert_entry(db_conn, word, meanings)

        cursor = db_conn.execute("SELECT COUNT(*) FROM words")
        assert cursor.fetchone()[0] == 0

        cursor = db_conn.execute("SELECT COUNT(*) FROM meanings")
        assert cursor.fetchone()[0] == 0

    def test_insert_entry_with_multiple_meanings(self, db_conn):
        word = _make_word_record()
        meanings = [
            _make_meaning_record(),
            _make_meaning_record(
                sequence=2, part_of_speech="transitive", definition_text="to live on"
            ),
        ]

        insert_entry(db_conn, word, meanings)

        cursor = db_conn.execute(
            "SELECT sequence, part_of_speech, definition_text FROM meanings ORDER BY sequence"
        )
        meaning_rows = cursor.fetchall()
        assert len(meaning_rows) == 2
        sequence1, part_of_speech1, definition_text1 = meaning_rows[0]
        sequence2, part_of_speech2, definition_text2 = meaning_rows[1]

        assert sequence1 == 1
        assert part_of_speech1 == "1-dan"
        assert definition_text1 == "to eat"
        assert sequence2 == 2
        assert part_of_speech2 == "transitive"
        assert definition_text2 == "to live on"

    def test_insert_entry_with_none_reading(self, db_conn):
        word = _make_word_record(reading=None)
        meanings = [_make_meaning_record()]

        insert_entry(db_conn, word, meanings)

        cursor = db_conn.execute("SELECT reading FROM words")
        word_rows = cursor.fetchall()
        assert len(word_rows) == 1
        (reading,) = word_rows[0]
        assert reading is None

    # 連続実行のシナリオ
    def test_multiple_inserts_get_independent_word_ids(self, db_conn):
        word1 = _make_word_record()
        meanings1 = [_make_meaning_record()]

        word2 = _make_word_record(term="飲む", reading="のむ", sequence=1169870)
        meanings2 = [
            _make_meaning_record(part_of_speech="5-dan", definition_text="to drink")
        ]

        insert_entry(db_conn, word1, meanings1)
        insert_entry(db_conn, word2, meanings2)

        cursor = db_conn.execute("SELECT id, term FROM words ORDER BY id")
        words_rows = cursor.fetchall()
        assert len(words_rows) == 2

        word1_id, term1 = words_rows[0]
        word2_id, term2 = words_rows[1]

        assert term1 == "食べる"
        assert term2 == "飲む"
        assert word1_id != word2_id
        assert word2_id > word1_id

        cursor = db_conn.execute(
            "SELECT word_id, definition_text FROM meanings ORDER BY word_id"
        )
        meanings_rows = cursor.fetchall()
        assert len(meanings_rows) == 2

        m1_word_id, m1_def = meanings_rows[0]
        assert m1_word_id == word1_id
        assert m1_def == "to eat"

        m2_word_id, m2_def = meanings_rows[1]
        assert m2_word_id == word2_id
        assert m2_def == "to drink"


def _make_word_record(**kwargs) -> WordRecord:
    defaults = dict(
        term="食べる",
        reading="たべる",
        sequence=1358280,
    )

    return WordRecord(**{**defaults, **kwargs})


def _make_meaning_record(**kwargs) -> MeaningRecord:
    defaults = dict(sequence=1, part_of_speech="1-dan", definition_text="to eat")

    return MeaningRecord(**{**defaults, **kwargs})
