//
//  DictionaryPack.swift
//  KotobaKit
//

import Foundation
import GRDB

/// What a pack records about its dictionary and its import.
public struct DictionaryPackInfo: Sendable {
    public let importID: UUID
    public let importerVersion: Int
    public let importedAt: Date
    /// Lowercase hex SHA-256 of the source archive.
    public let sourceSHA256: String
    public let index: YomitanIndex
    public let styles: String?

    /// The identity that stays the same across updates; see ``YomitanIndex/stableIdentity``.
    public var dictionaryID: String {
        index.stableIdentity
    }
}

/// Read access to one imported dictionary.
///
/// Opening checks the format version and metadata, so an incompatible pack fails here rather than
/// on first lookup. Every read decodes glossaries with its own decompressor, so any task may read a
/// pack. Reads run one at a time on the pack's database queue, so a slow search delays the reads
/// queued behind it.
///
/// Replacing the file, as a re-import does, makes an instance opened earlier fail with an I/O
/// error rather than read the new file; open the pack again after a replacement.
public final class DictionaryPack: Sendable {
    public let info: DictionaryPackInfo
    private let queue: DatabaseQueue
    private let presetDictionary: Data

    public init(url: URL) throws {
        var configuration = Configuration()
        configuration.readonly = true
        queue = try DatabaseQueue(path: url.path, configuration: configuration)

        let meta = try queue.read { db in
            try Row.fetchAll(db, sql: "SELECT key, value FROM meta").reduce(into: [:]) {
                (meta: inout [String: DatabaseValue], row) in
                meta[row["key"]] = row["value"]
            }
        }
        typealias Key = DictionaryPackSchema.MetaKey
        func value<Value: DatabaseValueConvertible>(_ key: Key, as type: Value.Type) throws -> Value
        {
            guard let databaseValue = meta[key.rawValue] else {
                throw DictionaryPackError.missingMetadata(key: key.rawValue)
            }
            guard let value = Value.fromDatabaseValue(databaseValue) else {
                throw DictionaryPackError.invalidMetadata(key: key.rawValue)
            }
            return value
        }

        let formatVersion = meta[Key.formatVersion.rawValue].flatMap(Int.fromDatabaseValue)
        guard formatVersion == DictionaryPackSchema.formatVersion else {
            throw DictionaryPackError.unsupportedFormat(formatVersion)
        }
        guard let importID = UUID(uuidString: try value(.importID, as: String.self)) else {
            throw DictionaryPackError.invalidMetadata(key: Key.importID.rawValue)
        }
        let index: YomitanIndex
        do {
            index = try JSONDecoder().decode(
                YomitanIndex.self,
                from: try value(.indexJSON, as: Data.self)
            )
        } catch let error as DictionaryPackError {
            throw error
        } catch {
            throw DictionaryPackError.invalidMetadata(key: Key.indexJSON.rawValue)
        }
        presetDictionary = try value(.presetDictionary, as: Data.self)
        info = DictionaryPackInfo(
            importID: importID,
            importerVersion: try value(.importerVersion, as: Int.self),
            importedAt: Date(
                timeIntervalSince1970: TimeInterval(try value(.importedAt, as: Int64.self))
            ),
            sourceSHA256: try value(.sourceSHA256, as: String.self),
            index: index,
            styles: meta[Key.styles.rawValue]
                .flatMap(Data.fromDatabaseValue)
                .map { String(decoding: $0, as: UTF8.self) }
        )
    }

    // MARK: - Search

    /// Entries whose term or reading starts with `prefix`, best first.
    ///
    /// Results rank by the length of the matched term or reading, then by score, then by source
    /// order. In a `sequenced` dictionary, rows that share a sequence, including Jitendex's
    /// negative-sequence redirect rows, count as one result: the best-matching row.
    public func search(prefix: String, limit: Int) async throws -> [DictionaryEntry] {
        guard !prefix.isEmpty, limit > 0 else {
            return []
        }
        let request = SQLRequest<Row>(literal: searchSQL(prefix: prefix, limit: limit))
        return try await read { db, decode in
            try Row.fetchAll(db, request).map(decode)
        }
    }

    /// The query plan of ``search(prefix:limit:)``, for benchmarks.
    public func searchQueryPlan(prefix: String, limit: Int) async throws -> [String] {
        let request = SQLRequest<Row>(
            literal: "EXPLAIN QUERY PLAN " + searchSQL(prefix: prefix, limit: limit)
        )
        return try await queue.read { db in
            try Row.fetchAll(db, request).map { $0["detail"] }
        }
    }

    private func searchSQL(prefix: String, limit: Int) -> SQL {
        let pattern = Self.globPrefixPattern(for: prefix)
        let grouped = info.index.sequenced
        // The two branches read only the covering indexes; the table is read for the results.
        // A zero sequence never groups, since it means the row has none.
        return """
            WITH matches AS (
                SELECT id, sequence, score, length(term) AS length
                FROM entries WHERE term GLOB \(pattern)
                UNION ALL
                SELECT id, sequence, score, length(reading) AS length
                FROM entries WHERE reading GLOB \(pattern)
            ),
            matched_rows AS (
                SELECT id, sequence, score, MIN(length) AS length
                FROM matches GROUP BY id
            ),
            ranked AS (
                SELECT id, score AS rank_score, length AS rank_length,
                    ROW_NUMBER() OVER (
                        PARTITION BY
                            CASE WHEN \(grouped) AND sequence <> 0 THEN abs(sequence) END,
                            CASE WHEN \(grouped) AND sequence <> 0 THEN NULL ELSE id END
                        ORDER BY length, score DESC, id
                    ) AS position
                FROM matched_rows
            )
            SELECT \(sql: Self.entryColumns)
            FROM ranked JOIN entries USING (id)
            WHERE position = 1
            ORDER BY rank_length, rank_score DESC, id
            LIMIT \(limit)
            """
    }

    /// A `GLOB` pattern that matches `prefix` literally at the start of a value.
    ///
    /// `GLOB` is case-sensitive, so SQLite uses an index for it without
    /// `PRAGMA case_sensitive_like`. `*`, `?`, and `[` are wrapped in brackets to match literally.
    static func globPrefixPattern(for prefix: String) -> String {
        var pattern = ""
        for character in prefix {
            switch character {
            case "*", "?", "[":
                pattern += "[\(character)]"
            default:
                pattern.append(character)
            }
        }
        return pattern + "*"
    }

    // MARK: - Entries

    /// The entry `reference` points to, or `nil` if the pack has no such row.
    ///
    /// Throws ``DictionaryPackError/staleReference`` for a reference from another import.
    public func entry(_ reference: DictionaryEntryReference) async throws -> DictionaryEntry? {
        guard reference.importID == info.importID else {
            throw DictionaryPackError.staleReference
        }
        return try await read { db, decode in
            try Row.fetchOne(
                db,
                sql: "SELECT \(Self.entryColumns) FROM entries WHERE id = ?",
                arguments: [reference.rowID]
            ).map(decode)
        }
    }

    /// The rows that share the sequence of `entry`, including redirects, positive sequences first.
    ///
    /// Returns only `entry` when the dictionary is not `sequenced`. Throws
    /// ``DictionaryPackError/staleReference`` for an entry from another import.
    public func group(of entry: DictionaryEntry) async throws -> [DictionaryEntry] {
        guard entry.reference.importID == info.importID else {
            throw DictionaryPackError.staleReference
        }
        let sequence = entry.key.sequence
        guard info.index.sequenced, sequence != 0 else {
            return [entry]
        }
        return try await read { db, decode in
            try Row.fetchAll(
                db,
                sql: """
                    SELECT \(Self.entryColumns) FROM entries
                    WHERE sequence IN (?, ?) ORDER BY sequence < 0, id
                    """,
                arguments: [sequence, -sequence]
            ).map(decode)
        }
    }

    /// Finds a saved entry again, possibly after the dictionary was re-imported or updated.
    ///
    /// Among rows that share the snapshot's sequence, term, and reading, a row with the same
    /// glossary wins, preferring the same ordinal when several have it. Without a glossary match,
    /// the ordinal decides only when a single row has that identity: among several homographs, a
    /// reorder plus an edit would otherwise retarget the entry. Anything else has changed, and the
    /// candidates are those rows, then rows of the same sequence, then rows with the same term and
    /// reading.
    public func resolve(
        _ snapshot: DictionaryEntrySnapshot
    ) async throws
        -> DictionaryEntryResolution
    {
        let key = snapshot.key
        return try await read { db, decode in
            let sameIdentity = try Row.fetchAll(
                db,
                sql: """
                    SELECT \(Self.entryColumns) FROM entries
                    WHERE term = ? AND reading = ? AND sequence = ? ORDER BY ordinal
                    """,
                arguments: [key.term, key.reading, key.sequence]
            ).map(decode)
            let sameGlossary = sameIdentity.filter {
                $0.snapshot.glossaryFingerprint == snapshot.glossaryFingerprint
            }
            if let match = sameGlossary.first(where: { $0.key.ordinal == key.ordinal })
                ?? sameGlossary.first
            {
                return .found(match)
            }
            if sameIdentity.count == 1, let only = sameIdentity.first,
                only.key.ordinal == key.ordinal
            {
                return .found(only)
            }

            var candidates = sameIdentity
            if key.sequence != 0 {
                candidates += try Row.fetchAll(
                    db,
                    sql: """
                        SELECT \(Self.entryColumns) FROM entries
                        WHERE sequence IN (?, ?) ORDER BY sequence < 0, id
                        """,
                    arguments: [key.sequence, -key.sequence]
                ).map(decode)
            }
            candidates += try Row.fetchAll(
                db,
                sql: """
                    SELECT \(Self.entryColumns) FROM entries
                    WHERE term = ? AND reading = ? ORDER BY id
                    """,
                arguments: [key.term, key.reading]
            ).map(decode)
            var seen = Set<Int64>()
            return .changed(
                candidates: candidates.filter { seen.insert($0.reference.rowID).inserted }
            )
        }
    }

    // MARK: - Metadata and media

    public func tags() async throws -> [DictionaryTag] {
        try await queue.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT name, category, sort_order, notes, score FROM tags ORDER BY name"
            ).map {
                DictionaryTag(
                    name: $0["name"],
                    category: $0["category"],
                    order: $0["sort_order"],
                    notes: $0["notes"],
                    score: $0["score"]
                )
            }
        }
    }

    /// A file the glossaries reference, such as an image, by its path in the source archive.
    public func media(at path: String) async throws -> Data? {
        try await queue.read { db in
            try Data.fetchOne(db, sql: "SELECT data FROM media WHERE path = ?", arguments: [path])
        }
    }

    public func entryCount() async throws -> Int {
        try await queue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM entries") ?? 0
        }
    }

    // MARK: - Decoding

    private static let entryColumns =
        "id, term, reading, sequence, ordinal, definition_tags, rules, score, term_tags, glossary"

    /// Runs `body` with a decoder that turns entry rows into entries.
    private func read<T: Sendable>(
        _ body: @Sendable (Database, (Row) throws -> DictionaryEntry) throws -> T
    ) async throws -> T {
        let importID = info.importID
        let presetDictionary = presetDictionary
        return try await queue.read { db in
            let decompressor = try PresetDecompressor(dictionary: presetDictionary)
            return try body(db) { row in
                DictionaryEntry(
                    reference: DictionaryEntryReference(importID: importID, rowID: row["id"]),
                    key: DictionaryEntryKey(
                        sequence: row["sequence"],
                        term: row["term"],
                        reading: row["reading"],
                        ordinal: row["ordinal"]
                    ),
                    definitionTags: Self.splitTags(row["definition_tags"]),
                    rules: Self.splitTags(row["rules"]),
                    score: row["score"],
                    termTags: Self.splitTags(row["term_tags"]),
                    glossaryJSON: try decompressor.decompress(row["glossary"])
                )
            }
        }
    }

    /// Yomitan separates tags and rules with spaces; tag names may contain no-break spaces.
    private static func splitTags(_ text: String) -> [String] {
        text.split(separator: " ").map(String.init)
    }
}
