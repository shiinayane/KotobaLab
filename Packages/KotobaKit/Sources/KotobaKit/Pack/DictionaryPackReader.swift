//
//  DictionaryPackReader.swift
//  KotobaKit
//

import Foundation
import GRDB

/// Reads entries back out of a dictionary pack.
///
/// The minimum needed to verify imports; the lookup API comes with the pack format freeze.
public final class DictionaryPackReader {
    private let queue: DatabaseQueue
    private let decompressor: PresetDecompressor

    public init(url: URL) throws {
        var configuration = Configuration()
        configuration.readonly = true
        queue = try DatabaseQueue(path: url.path, configuration: configuration)
        let preset = try queue.read { db in
            try Data.fetchOne(
                db,
                sql: "SELECT value FROM meta WHERE key = ?",
                arguments: [DictionaryPackSchema.MetaKey.presetDictionary.rawValue]
            )
        }
        decompressor = try PresetDecompressor(dictionary: preset ?? Data())
    }

    public func entryCount() throws -> Int {
        try queue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM entries") ?? 0
        }
    }

    /// The glossary JSON array of the entry with `id`, or `nil` if there is none.
    public func glossaryJSON(entryID id: Int64) throws -> Data? {
        let compressed = try queue.read { db in
            try Data.fetchOne(db, sql: "SELECT glossary FROM entries WHERE id = ?", arguments: [id])
        }
        return try compressed.map(decompressor.decompress)
    }
}
