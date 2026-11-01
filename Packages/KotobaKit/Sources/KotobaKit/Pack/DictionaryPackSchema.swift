//
//  DictionaryPackSchema.swift
//  KotobaKit
//

import Foundation
import GRDB

/// The SQLite layout of one imported dictionary.
///
/// Each dictionary is one self-contained file, so replacing or removing a dictionary replaces or
/// removes one file. The contract for changing this layout is in
/// `docs/dictionary.md#pack-format`: data columns are frozen, indexes and derived columns are
/// upgraded in place, and new meta keys or tables are additive.
enum DictionaryPackSchema {
    /// Bumped only when a data column changes, which requires re-importing the source.
    static let formatVersion = 1

    enum MetaKey: String {
        case formatVersion = "format_version"
        case importID = "import_id"
        case importerVersion = "importer_version"
        /// Seconds since 1970, UTC.
        case importedAt = "imported_at"
        /// Lowercase hex SHA-256 of the source archive.
        case sourceSHA256 = "source_sha256"
        case indexJSON = "index_json"
        case styles = "styles_css"
        case presetDictionary = "preset_dictionary"
    }

    static func createTables(in db: Database) throws {
        try db.execute(
            sql: """
                -- meta, media, and source_banks hold large values, which rowid tables store
                -- better than WITHOUT ROWID tables.
                CREATE TABLE meta (
                    key TEXT PRIMARY KEY NOT NULL,
                    value BLOB NOT NULL
                );

                CREATE TABLE tags (
                    name TEXT PRIMARY KEY NOT NULL,
                    category TEXT NOT NULL,
                    sort_order INTEGER NOT NULL,
                    notes TEXT NOT NULL,
                    score INTEGER NOT NULL
                ) WITHOUT ROWID;

                -- sequence is 0 for dictionaries that do not declare `sequenced`.
                -- ordinal tells apart rows that share sequence, term, and reading,
                -- in source order.
                CREATE TABLE entries (
                    id INTEGER PRIMARY KEY,
                    term TEXT NOT NULL,
                    reading TEXT NOT NULL,
                    sequence INTEGER NOT NULL,
                    ordinal INTEGER NOT NULL,
                    definition_tags TEXT NOT NULL,
                    rules TEXT NOT NULL,
                    score INTEGER NOT NULL,
                    term_tags TEXT NOT NULL,
                    glossary BLOB NOT NULL
                );

                CREATE TABLE media (
                    path TEXT PRIMARY KEY NOT NULL,
                    data BLOB NOT NULL
                );

                -- Banks this format does not read yet, such as kanji and frequency banks,
                -- kept raw-deflated so a later upgrade can read them without the source.
                CREATE TABLE source_banks (
                    path TEXT PRIMARY KEY NOT NULL,
                    kind TEXT NOT NULL,
                    data BLOB NOT NULL
                );
                """
        )
    }

    /// Indexes are created after the bulk insert, which is faster than maintaining them per row.
    ///
    /// The search indexes cover every column search reads, so ranking never touches the table.
    static func createIndexes(in db: Database) throws {
        try db.execute(
            sql: """
                CREATE INDEX entries_term ON entries (term, score, sequence);
                CREATE INDEX entries_reading ON entries (reading, score, sequence);
                CREATE INDEX entries_sequence ON entries (sequence);
                """
        )
    }
}
