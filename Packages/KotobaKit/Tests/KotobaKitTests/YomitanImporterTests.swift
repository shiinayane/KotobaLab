//
//  YomitanImporterTests.swift
//  KotobaKitTests
//

import CryptoKit
import Foundation
import GRDB
import Testing

@testable import KotobaKit

struct YomitanImporterTests {
    private struct EntryRow: Equatable {
        let term: String
        let reading: String
        let sequence: Int
        let ordinal: Int
    }

    private func entryRows(in pack: URL) throws -> [EntryRow] {
        let queue = try DatabaseQueue(path: pack.path)
        return try queue.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT term, reading, sequence, ordinal FROM entries ORDER BY id"
            ).map {
                EntryRow(
                    term: $0["term"],
                    reading: $0["reading"],
                    sequence: $0["sequence"],
                    ordinal: $0["ordinal"]
                )
            }
        }
    }

    @Test func importArchive_shouldWriteEveryPartOfTheDictionary() throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }

        let report = try YomitanImporter().importArchive(
            at: fixture.archiveURL,
            to: fixture.packURL
        )

        #expect(report.index.title == "KotobaKit Fixture [2026-01-01]")
        #expect(report.entryCount == 8)
        #expect(report.tagCount == 2)
        #expect(report.mediaCount == 1)
        #expect(report.storedSourceBanks == ["kanji": 1])
        #expect(report.presetDictionaryBytes > 0)
        let archive = try Data(contentsOf: fixture.archiveURL)
        #expect(
            report.sourceSHA256
                == SHA256.hash(data: archive).map { String(format: "%02x", $0) }.joined()
        )

        let queue = try DatabaseQueue(path: fixture.packURL.path)
        try queue.read { db in
            let kanjiBank = try Row.fetchOne(db, sql: "SELECT path, kind, data FROM source_banks")
            #expect(kanjiBank?["path"] == "kanji_bank_1.json")
            #expect(kanjiBank?["kind"] == "kanji")
            let stored: Data = try #require(kanjiBank?["data"])
            let source = try Data(
                contentsOf: fixture.directory.appendingPathComponent("content/kanji_bank_1.json")
            )
            #expect(try PresetDecompressor(dictionary: Data()).decompress(stored) == source)

            let notes = try String.fetchOne(db, sql: "SELECT notes FROM tags WHERE name = 'n'")
            #expect(notes == "noun")
            let mediaPaths = try String.fetchAll(db, sql: "SELECT path FROM media")
            #expect(mediaPaths == ["media/mark.svg"])
            let styles = try Data.fetchOne(
                db,
                sql: "SELECT value FROM meta WHERE key = 'styles_css'"
            )
            #expect(
                styles.map { String(decoding: $0, as: UTF8.self) } == ".gloss { color: gray; }\n"
            )
        }
    }

    @Test func importArchive_shouldKeepBankOrderAndFillEmptyReadings() throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }

        _ = try YomitanImporter().importArchive(at: fixture.archiveURL, to: fixture.packURL)

        let rows = try entryRows(in: fixture.packURL)
        #expect(
            rows.map(\.term) == ["食べる", "食べる", "煮る", "\u{FA48}る", "ねこ", "喰べる", "食べ物", "多弁"]
        )
        #expect(rows[4].reading == "ねこ")
    }

    @Test func sequencedIdentity_shouldCountDuplicatesByCodePoint() throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }

        let report = try YomitanImporter().importArchive(
            at: fixture.archiveURL,
            to: fixture.packURL
        )

        let rows = try entryRows(in: fixture.packURL)
        // The repeated 食べる row is a duplicate; the compatibility ideograph 煮 is not.
        #expect(rows.map(\.ordinal) == [0, 1, 0, 0, 0, 0, 0, 0])
        #expect(rows.map(\.sequence) == [100, 100, 200, 200, 300, -100, 400, 500])
        #expect(report.duplicateIdentityCount == 1)
    }

    @Test func unsequencedIdentity_shouldIgnoreSequenceNumbers() throws {
        let index = """
            {"title": "Unsequenced", "revision": "1", "format": 3}
            """
        let bank = """
            [
                ["語", "ご", "", "", 0, ["first"], 7, ""],
                ["語", "ご", "", "", 0, ["second"], 8, ""]
            ]
            """
        let fixture = try FixtureArchive(
            replacing: ["index.json": index, "term_bank_1.json": bank],
            removing: ["term_bank_2.json"]
        )
        defer { fixture.remove() }

        let report = try YomitanImporter().importArchive(
            at: fixture.archiveURL,
            to: fixture.packURL
        )

        let rows = try entryRows(in: fixture.packURL)
        #expect(rows.map(\.sequence) == [0, 0])
        #expect(rows.map(\.ordinal) == [0, 1])
        #expect(report.index.stableIdentity == "Unsequenced")
    }

    @Test func glossary_shouldRoundTripThroughThePack() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        _ = try YomitanImporter().importArchive(at: fixture.archiveURL, to: fixture.packURL)

        let pack = try DictionaryPack(url: fixture.packURL)
        let source = try #require(
            try JSONSerialization.jsonObject(
                with: Data(
                    contentsOf: fixture.directory.appendingPathComponent("content/term_bank_1.json")
                )
            ) as? [[Any]]
        )
        for (offset, row) in source.enumerated() {
            let reference = DictionaryEntryReference(
                importID: pack.info.importID,
                rowID: Int64(offset + 1)
            )
            let entry = try #require(try await pack.entry(reference))
            let glossary = try JSONSerialization.jsonObject(with: entry.glossaryJSON) as? NSArray
            #expect(glossary == row[5] as? NSArray)
        }
    }

    @Test func importArchive_shouldReplaceAnExistingPack() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        try Data("old".utf8).write(to: fixture.packURL)

        _ = try YomitanImporter().importArchive(at: fixture.archiveURL, to: fixture.packURL)

        #expect(try await DictionaryPack(url: fixture.packURL).entryCount() == 8)
        #expect(try fixture.strayFiles().isEmpty)
    }

    @Test(arguments: [
        (
            ["index.json": #"{"title": "Old", "revision": "1", "version": 1}"#], [String](),
            YomitanImportError.unsupportedFormat(1)
        ),
        ([:], ["index.json"], YomitanImportError.missingIndex),
        ([:], ["term_bank_1.json", "term_bank_2.json"], YomitanImportError.noTermBanks),
        (
            ["term_bank_2.json": #"[["ねこ"]]"#], [],
            YomitanImportError.malformedRow(path: "term_bank_2.json", row: 0)
        ),
        (["term_bank_2.json": "{"], [], YomitanImportError.malformedBank(path: "term_bank_2.json"))
    ])
    func invalidArchive_shouldThrowAndLeaveNoFiles(
        replacing files: [String: String],
        removing removed: [String],
        expected: YomitanImportError
    ) throws {
        let fixture = try FixtureArchive(replacing: files, removing: removed)
        defer { fixture.remove() }

        #expect(throws: expected) {
            try YomitanImporter().importArchive(at: fixture.archiveURL, to: fixture.packURL)
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.packURL.path))
        #expect(try fixture.strayFiles().isEmpty)
    }

    @Test func cancelledImport_shouldThrowAndLeaveNoFiles() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try YomitanImporter().importArchive(
                at: fixture.archiveURL,
                to: fixture.packURL
            )
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.packURL.path))
        #expect(try fixture.strayFiles().isEmpty)
    }
}
