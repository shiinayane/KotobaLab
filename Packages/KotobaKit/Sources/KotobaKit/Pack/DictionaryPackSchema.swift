//
//  DictionaryPackSchema.swift
//  KotobaKit
//

import Foundation
import GRDB

/// The SQLite layout of one imported dictionary.
///
/// Each dictionary is one self-contained file, so replacing or removing a dictionary replaces or
/// removes one file. The format is provisional until the M1 measurements settle it.
enum DictionaryPackSchema {
    /// Bumped whenever the layout changes; packs of another version are re-imported.
    static let formatVersion = 1

    enum MetaKey: String {
        case formatVersion = "format_version"
        case indexJSON = "index_json"
        case styles = "styles_css"
        case presetDictionary = "preset_dictionary"
    }

    static func createTables(in db: Database) throws {
        try db.execute(
            sql: """
                -- meta and media hold large values, which rowid tables store better
                -- than WITHOUT ROWID tables.
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
                """
        )
    }

    /// Indexes are created after the bulk insert, which is faster than maintaining them per row.
    static func createIndexes(in db: Database) throws {
        try db.execute(
            sql: """
                CREATE INDEX entries_term ON entries (term);
                CREATE INDEX entries_reading ON entries (reading);
                """
        )
    }
}
