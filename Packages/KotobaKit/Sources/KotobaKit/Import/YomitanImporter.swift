//
//  YomitanImporter.swift
//  KotobaKit
//

import CryptoKit
import Foundation
import GRDB
import ZIPFoundation

/// Converts a Yomitan format 3 archive into a dictionary pack.
///
/// The pack is written to a temporary file next to the destination and moved into place only
/// after every step succeeds, so a failed or cancelled import leaves no partial pack.
public struct YomitanImporter: Sendable {
    /// Bumped when the importer writes different content for the same source, such as a fix to
    /// how glossaries are serialized.
    public static let version = 1

    public struct Options: Sendable {
        /// The zlib level for glossaries, from 1 (fastest) to 9 (smallest).
        ///
        /// For the speed and size of each level, see `docs/dictionary.md#swift-import-2026-11-01`.
        public var compressionLevel: Int32 = 6
        /// How many entries are sampled across the dictionary to build the preset dictionary.
        public var presetSampleCount = 512
        /// How many term banks are parsed for samples, at most.
        public var presetSampleBankCount = 8
        /// The preset dictionary size in bytes, at most 32 KB.
        ///
        /// Every entry pays to load the dictionary, so a smaller one compresses faster.
        public var presetDictionarySize = PresetDeflate.maximumDictionarySize

        public init() {}
    }

    public let options: Options

    public init(options: Options = Options()) {
        self.options = options
    }

    /// Imports the archive at `archiveURL` into a pack at `packURL`, replacing any existing file.
    ///
    /// Checks for task cancellation between banks.
    public func importArchive(at archiveURL: URL, to packURL: URL) throws -> YomitanImportReport {
        let clock = ContinuousClock()
        let start = clock.now
        var timings = YomitanImportReport.Timings()

        let archive = try ArchiveFiles(url: archiveURL)
        let layout = YomitanArchiveLayout(paths: archive.paths)

        guard let indexData = try archive.read(YomitanArchiveLayout.indexPath) else {
            throw YomitanImportError.missingIndex
        }
        let index: YomitanIndex
        do {
            index = try JSONDecoder().decode(YomitanIndex.self, from: indexData)
        } catch {
            throw YomitanImportError.invalidIndex(description: String(describing: error))
        }
        guard index.format == 3 else {
            throw YomitanImportError.unsupportedFormat(index.format)
        }
        let termBanks = layout.banks(of: .term)
        guard !termBanks.isEmpty else {
            throw YomitanImportError.noTermBanks
        }

        let sourceSHA256 = try Self.sha256(of: archiveURL)
        let importID = UUID()

        let presetStart = clock.now
        let preset = try buildPresetDictionary(termBanks: termBanks, archive: archive)
        timings.presetDictionary = clock.now - presetStart

        let temporaryURL = packURL.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).importing")
        var succeeded = false
        defer {
            if !succeeded {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
        }

        var configuration = Configuration()
        configuration.prepareDatabase { db in
            // The temporary file is discarded on failure, so it needs no journal or syncing.
            try db.execute(sql: "PRAGMA journal_mode = OFF; PRAGMA synchronous = OFF")
        }
        let queue = try DatabaseQueue(path: temporaryURL.path, configuration: configuration)

        var counts = EntryCounts()
        var tagCount = 0
        var media = (count: 0, bytes: 0)
        var storedBanks: [String: Int] = [:]
        try queue.inDatabase { db in
            try DictionaryPackSchema.createTables(in: db)
            try db.inTransaction {
                try writeMeta(
                    Meta(
                        importID: importID,
                        sourceSHA256: sourceSHA256,
                        index: indexData,
                        preset: preset
                    ),
                    archive: archive,
                    db: db
                )
                tagCount = try writeTags(
                    banks: layout.banks(of: .tag),
                    archive: archive,
                    db: db
                )
                counts = try writeEntries(
                    banks: termBanks,
                    sequenced: index.sequenced,
                    preset: preset,
                    archive: archive,
                    db: db,
                    timings: &timings
                )
                let mediaStart = clock.now
                media = try writeMedia(paths: layout.mediaPaths, archive: archive, db: db)
                timings.media = clock.now - mediaStart
                storedBanks = try writeSourceBanks(layout: layout, archive: archive, db: db)
                return .commit
            }
            let indexStart = clock.now
            try DictionaryPackSchema.createIndexes(in: db)
            timings.indexes = clock.now - indexStart
        }
        try queue.close()

        if FileManager.default.fileExists(atPath: packURL.path) {
            _ = try FileManager.default.replaceItemAt(packURL, withItemAt: temporaryURL)
        } else {
            try FileManager.default.moveItem(at: temporaryURL, to: packURL)
        }
        succeeded = true

        let packBytes = try packURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        timings.total = clock.now - start
        return YomitanImportReport(
            importID: importID,
            sourceSHA256: sourceSHA256,
            index: index,
            entryCount: counts.entries,
            duplicateIdentityCount: counts.duplicates,
            tagCount: tagCount,
            mediaCount: media.count,
            mediaBytes: media.bytes,
            glossaryBytes: counts.glossaryBytes,
            compressedGlossaryBytes: counts.compressedBytes,
            presetDictionaryBytes: preset.count,
            storedSourceBanks: storedBanks,
            packBytes: packBytes,
            timings: timings
        )
    }

    // MARK: - Preset dictionary

    private func buildPresetDictionary(
        termBanks: [YomitanArchiveLayout.Bank],
        archive: ArchiveFiles
    ) throws -> Data {
        let bankCount = min(options.presetSampleBankCount, termBanks.count)
        let perBank = max(1, options.presetSampleCount / bankCount)
        var samples: [Data] = []
        for position in 0..<bankCount {
            try Task.checkCancellation()
            // Spread the sampled banks evenly from the first to the last.
            let bank = termBanks[position * termBanks.count / bankCount]
            try autoreleasepool {
                let rows = try Self.parseBank(bank, from: archive)
                let stride = max(1, rows.count / perBank)
                for rowIndex in Swift.stride(from: 0, to: rows.count, by: stride).prefix(perBank) {
                    guard let row = YomitanTermRow(json: rows[rowIndex]) else {
                        throw YomitanImportError.malformedRow(path: bank.path, row: rowIndex)
                    }
                    samples.append(try Self.serialize(row.glossary))
                }
            }
        }
        return PresetDictionaryBuilder.build(from: samples, size: options.presetDictionarySize)
    }

    // MARK: - Tables

    private struct Meta {
        let importID: UUID
        let sourceSHA256: String
        let index: Data
        let preset: Data
    }

    private func writeMeta(_ meta: Meta, archive: ArchiveFiles, db: Database) throws {
        let insert = try db.makeStatement(sql: "INSERT INTO meta (key, value) VALUES (?, ?)")
        typealias Key = DictionaryPackSchema.MetaKey
        let values: [(Key, any DatabaseValueConvertible)] = [
            (.formatVersion, DictionaryPackSchema.formatVersion),
            (.importID, meta.importID.uuidString),
            (.importerVersion, Self.version),
            (.importedAt, Int64(Date().timeIntervalSince1970)),
            (.sourceSHA256, meta.sourceSHA256),
            (.indexJSON, meta.index),
            (.presetDictionary, meta.preset)
        ]
        for (key, value) in values {
            try insert.execute(arguments: [key.rawValue, value])
        }
        if let styles = try archive.read(YomitanArchiveLayout.stylesPath) {
            try insert.execute(arguments: [Key.styles.rawValue, styles])
        }
    }

    private func writeTags(
        banks: [YomitanArchiveLayout.Bank],
        archive: ArchiveFiles,
        db: Database
    ) throws -> Int {
        // The first definition of a tag name wins.
        let insert = try db.makeStatement(
            sql: """
                INSERT OR IGNORE INTO tags (name, category, sort_order, notes, score)
                VALUES (?, ?, ?, ?, ?)
                """
        )
        for bank in banks {
            for (rowIndex, json) in try Self.parseBank(bank, from: archive).enumerated() {
                guard let tag = YomitanTagRow(json: json) else {
                    throw YomitanImportError.malformedRow(path: bank.path, row: rowIndex)
                }
                try insert.execute(arguments: [
                    tag.name, tag.category, tag.order, tag.notes, tag.score
                ])
            }
        }
        return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tags") ?? 0
    }

    private struct EntryCounts {
        var entries = 0
        var duplicates = 0
        var glossaryBytes = 0
        var compressedBytes = 0
    }

    private func writeEntries(
        banks: [YomitanArchiveLayout.Bank],
        sequenced: Bool,
        preset: Data,
        archive: ArchiveFiles,
        db: Database,
        timings: inout YomitanImportReport.Timings
    ) throws -> EntryCounts {
        let clock = ContinuousClock()
        let compressor = try PresetCompressor(
            dictionary: preset,
            level: options.compressionLevel
        )
        let insert = try db.makeStatement(
            sql: """
                INSERT INTO entries (
                    term, reading, sequence, ordinal, definition_tags, rules, score,
                    term_tags, glossary
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
        )
        var counts = EntryCounts()
        // Counts rows per sequence, term, and reading; the key's ordinal stays 0.
        var nextOrdinal: [DictionaryEntryKey: Int] = [:]

        for bank in banks {
            try Task.checkCancellation()
            // JSONSerialization autoreleases its objects; drain them after every bank.
            try autoreleasepool {
                try writeBank(bank)
            }
        }
        return counts

        func writeBank(_ bank: YomitanArchiveLayout.Bank) throws {
            var phaseStart = clock.now
            guard let data = try archive.read(bank.path) else {
                throw YomitanImportError.malformedBank(path: bank.path)
            }
            timings.readTermBanks += clock.now - phaseStart

            phaseStart = clock.now
            let rows = try Self.parseRows(data, path: bank.path)
            timings.parseTermBanks += clock.now - phaseStart

            for (rowIndex, json) in rows.enumerated() {
                guard let row = YomitanTermRow(json: json) else {
                    throw YomitanImportError.malformedRow(path: bank.path, row: rowIndex)
                }
                // Without `sequenced`, sequence numbers carry no identity.
                let key = DictionaryEntryKey(
                    sequence: sequenced ? Int64(row.sequence) : 0,
                    term: row.term,
                    reading: row.reading,
                    ordinal: 0
                )
                let ordinal = nextOrdinal[key, default: 0]
                nextOrdinal[key] = ordinal + 1
                if ordinal > 0 {
                    counts.duplicates += 1
                }

                phaseStart = clock.now
                let glossary = try Self.serialize(row.glossary)
                timings.serializeGlossaries += clock.now - phaseStart

                phaseStart = clock.now
                let compressed = try compressor.compress(glossary)
                timings.compressGlossaries += clock.now - phaseStart

                phaseStart = clock.now
                try insert.execute(arguments: [
                    row.term, row.reading, key.sequence, ordinal, row.definitionTags, row.rules,
                    row.score, row.termTags, compressed
                ])
                timings.insertEntries += clock.now - phaseStart

                counts.entries += 1
                counts.glossaryBytes += glossary.count
                counts.compressedBytes += compressed.count
            }
        }
    }

    private func writeMedia(
        paths: [String],
        archive: ArchiveFiles,
        db: Database
    ) throws -> (count: Int, bytes: Int) {
        let insert = try db.makeStatement(sql: "INSERT INTO media (path, data) VALUES (?, ?)")
        var bytes = 0
        for path in paths {
            try Task.checkCancellation()
            guard let data = try archive.read(path) else {
                continue
            }
            try insert.execute(arguments: [path, data])
            bytes += data.count
        }
        return (paths.count, bytes)
    }

    /// Stores the banks this format does not read, so a later upgrade needs no source archive.
    private func writeSourceBanks(
        layout: YomitanArchiveLayout,
        archive: ArchiveFiles,
        db: Database
    ) throws -> [String: Int] {
        let insert = try db.makeStatement(
            sql: "INSERT INTO source_banks (path, kind, data) VALUES (?, ?, ?)"
        )
        let compressor = try PresetCompressor(dictionary: Data(), level: options.compressionLevel)
        var counts: [String: Int] = [:]
        for kind in [YomitanArchiveLayout.BankKind.termMeta, .kanji, .kanjiMeta] {
            for bank in layout.banks(of: kind) {
                try Task.checkCancellation()
                guard let data = try archive.read(bank.path) else {
                    throw YomitanImportError.malformedBank(path: bank.path)
                }
                try insert.execute(arguments: [
                    bank.path, kind.rawValue, try compressor.compress(data)
                ])
                counts[kind.rawValue, default: 0] += 1
            }
        }
        return counts
    }

    // MARK: - Archive and JSON

    private static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func parseBank(
        _ bank: YomitanArchiveLayout.Bank,
        from archive: ArchiveFiles
    ) throws -> [Any] {
        guard let data = try archive.read(bank.path) else {
            throw YomitanImportError.malformedBank(path: bank.path)
        }
        return try parseRows(data, path: bank.path)
    }

    private static func parseRows(_ data: Data, path: String) throws -> [Any] {
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw YomitanImportError.malformedBank(path: path)
        }
        return rows
    }

    /// Serializes with sorted keys so the same glossary always produces the same bytes.
    static func serialize(_ glossary: [Any]) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: glossary,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    }
}

/// The files of a ZIP archive by path.
///
/// `Archive` subscripts scan the central directory on every lookup, which is quadratic for
/// dictionaries with thousands of images, so the entries are indexed once.
private struct ArchiveFiles {
    private let archive: Archive
    private let entries: [String: Entry]

    init(url: URL) throws {
        archive = try Archive(url: url, accessMode: .read)
        var entries: [String: Entry] = [:]
        for entry in archive where entry.type == .file {
            entries[entry.path] = entry
        }
        self.entries = entries
    }

    var paths: Dictionary<String, Entry>.Keys {
        entries.keys
    }

    /// The most a read reserves up front, above the largest known term bank.
    ///
    /// The size comes from the archive's own header, which a damaged or crafted file can set to
    /// any value; larger entries still read in full, growing as they go.
    private static let maximumReservation: UInt64 = 64 * 1024 * 1024

    func read(_ path: String) throws -> Data? {
        guard let entry = entries[path] else {
            return nil
        }
        var data = Data(capacity: Int(min(entry.uncompressedSize, Self.maximumReservation)))
        _ = try archive.extract(entry, skipCRC32: false) { data.append($0) }
        return data
    }
}
