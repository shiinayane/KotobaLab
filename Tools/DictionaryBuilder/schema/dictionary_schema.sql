--
--  dictionary_schema.sql
--  KotobaLab
--
--  Created by 椎名アヤネ on 2026/05/04.
--

DROP TABLE IF EXISTS meanings;
DROP TABLE IF EXISTS words;

CREATE TABLE words (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    term TEXT NOT NULL,
    reading TEXT,
    sequence INTEGER
);

CREATE TABLE meanings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    sequence INTEGER NOT NULL,
    part_of_speech TEXT,
    definition_text TEXT NOT NULL,
    FOREIGN KEY (word_id) REFERENCES words(id)
);

CREATE INDEX idx_words_term ON words(term);
CREATE INDEX idx_words_reading ON words(reading);
CREATE INDEX idx_words_sequence ON words(sequence);
CREATE INDEX idx_meanings_word_id ON meanings(word_id);