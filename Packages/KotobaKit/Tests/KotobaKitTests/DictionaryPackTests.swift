//
//  DictionaryPackTests.swift
//  KotobaKitTests
//

import Foundation
import GRDB
import Testing

@testable import KotobaKit

struct DictionaryPackTests {
    private static let unsequencedIndex = """
        {"title": "Unsequenced", "revision": "1", "format": 3}
        """

    /// Imports the fixture, optionally changed, and opens the pack.
    private func makePack(
        replacing files: [String: String] = [:],
        removing removed: [String] = []
    ) throws -> (FixtureArchive, DictionaryPack) {
        let fixture = try FixtureArchive(replacing: files, removing: removed)
        _ = try YomitanImporter().importArchive(at: fixture.archiveURL, to: fixture.packURL)
        return (fixture, try DictionaryPack(url: fixture.packURL))
    }

    private func terms(_ entries: [DictionaryEntry]) -> [String] {
        entries.map(\.key.term)
    }

    // MARK: - Opening

    @Test func open_shouldReadMetadata() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }

        #expect(pack.info.dictionaryID == "https://example.com/kotobakit-fixture/index.json")
        #expect(pack.info.index.title == "KotobaKit Fixture [2026-01-01]")
        #expect(pack.info.importerVersion == YomitanImporter.version)
        #expect(pack.info.sourceSHA256.count == 64)
        #expect(pack.info.styles == ".gloss { color: gray; }\n")
        #expect(try await pack.tags().map(\.name) == ["n", "v1"])
        #expect(try await pack.media(at: "media/mark.svg")?.isEmpty == false)
        #expect(try await pack.media(at: "missing.png") == nil)
    }

    @Test(arguments: [
        (
            "UPDATE meta SET value = 2 WHERE key = 'format_version'",
            DictionaryPackError.unsupportedFormat(2)
        ),
        ("DELETE FROM meta WHERE key = 'format_version'", .unsupportedFormat(nil)),
        (
            "DELETE FROM meta WHERE key = 'preset_dictionary'",
            .missingMetadata(key: "preset_dictionary")
        ),
        ("UPDATE meta SET value = 'x' WHERE key = 'import_id'", .invalidMetadata(key: "import_id")),
        (
            "UPDATE meta SET value = '{' WHERE key = 'index_json'",
            .invalidMetadata(key: "index_json")
        )
    ])
    func open_shouldRejectIncompatiblePacks(change: String, expected: DictionaryPackError) throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        _ = try YomitanImporter().importArchive(at: fixture.archiveURL, to: fixture.packURL)
        try DatabaseQueue(path: fixture.packURL.path).write { try $0.execute(sql: change) }

        #expect(throws: expected) {
            try DictionaryPack(url: fixture.packURL)
        }
    }

    // MARK: - Search

    @Test func search_shouldRankByMatchedLengthThenScore() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }

        // 食べる and 多弁 match three characters of their readings; 食べ物 matches four.
        let results = try await pack.search(prefix: "たべ", limit: 20)

        #expect(terms(results) == ["食べる", "多弁", "食べ物"])
        #expect(results.first?.key.ordinal == 0)
    }

    @Test func search_shouldGroupRowsOfOneSequenceIncludingRedirects() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }

        // 喰べる is a redirect row of sequence -100; it shares a result with 食べる.
        let redirect = try await pack.search(prefix: "喰", limit: 20)
        #expect(terms(redirect) == ["喰べる"])

        let group = try await pack.group(of: try #require(redirect.first))
        #expect(terms(group) == ["食べる", "食べる", "喰べる"])
        #expect(group.map(\.key.sequence) == [100, 100, -100])
    }

    @Test func search_shouldNotGroupUnsequencedRowsAndBreakTiesBySourceOrder() async throws {
        let (fixture, pack) = try makePack(replacing: ["index.json": Self.unsequencedIndex])
        defer { fixture.remove() }

        let results = try await pack.search(prefix: "に", limit: 20)

        // Same length and score, so source order decides.
        #expect(terms(results) == ["煮る", "\u{FA48}る"])
        #expect(try await pack.search(prefix: "たべ", limit: 20).count == 4)
        let only = try #require(results.first)
        #expect(try await pack.group(of: only).map(\.reference) == [only.reference])
    }

    @Test func search_shouldMatchCodePointsAndWildcardsLiterally() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }

        #expect(terms(try await pack.search(prefix: "\u{FA48}", limit: 20)) == ["\u{FA48}る"])
        for prefix in ["*", "?", "[", "食*", "た?"] {
            #expect(try await pack.search(prefix: prefix, limit: 20).isEmpty)
        }
        #expect(try await pack.search(prefix: "", limit: 20).isEmpty)
        #expect(try await pack.search(prefix: "たべ", limit: 1).count == 1)
    }

    @Test func globPrefixPattern_shouldBracketWildcards() {
        #expect(DictionaryPack.globPrefixPattern(for: "a*b?c[d]") == "a[*]b[?]c[[]d]*")
    }

    @Test func searchQueryPlan_shouldUseTheCoveringIndexes() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }

        let plan = try await pack.searchQueryPlan(prefix: "た", limit: 20)

        // A range search, not a scan of the whole index.
        #expect(
            plan.contains("SEARCH entries USING COVERING INDEX entries_term (term>? AND term<?)")
        )
        #expect(
            plan.contains(
                "SEARCH entries USING COVERING INDEX entries_reading (reading>? AND reading<?)"
            )
        )
    }

    // MARK: - References and identity

    @Test func reference_shouldBeRejectedAfterReimport() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }
        let entry = try #require(try await pack.search(prefix: "ねこ", limit: 1).first)

        _ = try YomitanImporter().importArchive(at: fixture.archiveURL, to: fixture.packURL)
        let reimported = try DictionaryPack(url: fixture.packURL)

        await #expect(throws: DictionaryPackError.staleReference) {
            try await reimported.entry(entry.reference)
        }
        await #expect(throws: DictionaryPackError.staleReference) {
            try await reimported.group(of: entry)
        }
        // A pack opened before the replacement fails instead of reading the new file.
        await #expect(throws: (any Error).self) {
            try await pack.entry(entry.reference)
        }
    }

    @Test func resolve_shouldFindEveryRowOfAnUnchangedPack() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }

        // Includes the second 食べる, which shares its identity with the first.
        for rowID in Int64(1)...Int64(try await pack.entryCount()) {
            let reference = DictionaryEntryReference(importID: pack.info.importID, rowID: rowID)
            let entry = try #require(try await pack.entry(reference))
            guard case .found(let found) = try await pack.resolve(entry.snapshot) else {
                Issue.record("row \(rowID) did not resolve")
                continue
            }
            #expect(found.reference == reference)
        }
    }

    @Test func resolve_shouldPreferTheOrdinalAmongIdenticalGlossaries() async throws {
        let bank = """
            [
                ["語", "ご", "a", "", 0, ["same"], 0, ""],
                ["語", "ご", "b", "", 0, ["same"], 0, ""]
            ]
            """
        let (fixture, pack) = try makePack(
            replacing: ["index.json": Self.unsequencedIndex, "term_bank_1.json": bank],
            removing: ["term_bank_2.json"]
        )
        defer { fixture.remove() }
        let second = try #require(try await pack.search(prefix: "語", limit: 20).last)

        guard case .found(let found) = try await pack.resolve(second.snapshot) else {
            Issue.record("an identical homograph did not resolve")
            return
        }
        #expect(found.key.ordinal == 1)
        #expect(found.definitionTags == ["b"])
    }

    @Test func resolve_shouldFollowTheGlossaryWhenHomographsAreReordered() async throws {
        let bank = """
            [
                ["語", "ご", "", "", 0, ["first"], 0, ""],
                ["語", "ご", "", "", 0, ["second"], 0, ""]
            ]
            """
        let (fixture, pack) = try makePack(
            replacing: ["index.json": Self.unsequencedIndex, "term_bank_1.json": bank],
            removing: ["term_bank_2.json"]
        )
        defer { fixture.remove() }
        let second = try #require(try await pack.search(prefix: "語", limit: 20).last)
        #expect(second.key.ordinal == 1)

        let reordered = """
            [
                ["語", "ご", "", "", 0, ["second"], 0, ""],
                ["語", "ご", "", "", 0, ["first"], 0, ""]
            ]
            """
        let (updatedFixture, updated) = try makePack(
            replacing: ["index.json": Self.unsequencedIndex, "term_bank_1.json": reordered],
            removing: ["term_bank_2.json"]
        )
        defer { updatedFixture.remove() }

        guard case .found(let found) = try await updated.resolve(second.snapshot) else {
            Issue.record("the reordered homograph did not resolve")
            return
        }
        #expect(found.key.ordinal == 0)
        #expect(found.glossaryJSON == second.glossaryJSON)
    }

    @Test func resolve_shouldReportReorderedAndEditedHomographsAsChanged() async throws {
        let bank = """
            [
                ["語", "ご", "", "", 0, ["first"], 0, ""],
                ["語", "ご", "", "", 0, ["second"], 0, ""]
            ]
            """
        let (fixture, pack) = try makePack(
            replacing: ["index.json": Self.unsequencedIndex, "term_bank_1.json": bank],
            removing: ["term_bank_2.json"]
        )
        defer { fixture.remove() }
        let second = try #require(try await pack.search(prefix: "語", limit: 20).last)

        let reorderedAndEdited = """
            [
                ["語", "ご", "", "", 0, ["second, edited"], 0, ""],
                ["語", "ご", "", "", 0, ["first"], 0, ""]
            ]
            """
        let (updatedFixture, updated) = try makePack(
            replacing: [
                "index.json": Self.unsequencedIndex, "term_bank_1.json": reorderedAndEdited
            ],
            removing: ["term_bank_2.json"]
        )
        defer { updatedFixture.remove() }

        // Ordinal 1 is now "first"; only the user can tell which row was saved.
        guard case .changed(let candidates) = try await updated.resolve(second.snapshot) else {
            Issue.record("a reordered and edited homograph resolved")
            return
        }
        #expect(candidates.map(\.key.ordinal) == [0, 1])
    }

    @Test func resolve_shouldFallBackToTheOrdinalForTheOnlyRowOfAnIdentity() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }
        let entry = try #require(try await pack.search(prefix: "多弁", limit: 1).first)
        let edited = DictionaryEntrySnapshot(key: entry.key, glossaryFingerprint: "edited")

        guard case .found(let found) = try await pack.resolve(edited) else {
            Issue.record("an edited glossary did not resolve")
            return
        }
        #expect(found.reference == entry.reference)
    }

    @Test func resolve_shouldOfferRowsOfTheSameSequenceFirst() async throws {
        let (fixture, pack) = try makePack()
        defer { fixture.remove() }
        let gone = DictionaryEntrySnapshot(
            key: DictionaryEntryKey(sequence: 100, term: "食べ物", reading: "たべもの", ordinal: 0),
            glossaryFingerprint: ""
        )

        guard case .changed(let candidates) = try await pack.resolve(gone) else {
            Issue.record("a missing entry resolved")
            return
        }
        // Sequence 100 and its redirect -100 first, then the same term and reading.
        #expect(terms(candidates) == ["食べる", "食べる", "喰べる", "食べ物"])
    }

    @Test func entryKey_shouldCompareByCodePoint() {
        let unified = DictionaryEntryKey(sequence: 1, term: "煮る", reading: "にる", ordinal: 0)
        let compatibility = DictionaryEntryKey(
            sequence: 1,
            term: "\u{FA48}る",
            reading: "にる",
            ordinal: 0
        )

        #expect("煮る" == "\u{FA48}る")
        #expect(unified != compatibility)
        #expect(Set([unified, compatibility]).count == 2)
    }
}
