//
//  SwiftDataSavedEntryRepositoryTests.swift
//  KotobaLabTests
//
//  Created by shiinayane on 2026/11/01.
//

import Foundation
import KotobaKit
import SwiftData
import Testing

@testable import KotobaLab

@MainActor struct SwiftDataSavedEntryRepositoryTests {
    let container: ModelContainer
    let repository: SwiftDataSavedEntryRepository

    private static let dictionaryID = "https://example.com/dictionary/index.json"

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SavedEntryRecord.self, configurations: config)

        repository = SwiftDataSavedEntryRepository(context: container.mainContext)
    }

    private func snapshot(
        _ term: String,
        sequence: Int64 = 100,
        ordinal: Int = 0,
        fingerprint: String = "fingerprint"
    ) -> DictionaryEntrySnapshot {
        DictionaryEntrySnapshot(
            key: DictionaryEntryKey(
                sequence: sequence,
                term: term,
                reading: "たべる",
                ordinal: ordinal
            ),
            glossaryFingerprint: fingerprint
        )
    }

    @Test func save_shouldStoreTheWholeSnapshot() throws {
        let saved = snapshot("食べる", ordinal: 1, fingerprint: "abc")

        try repository.save(dictionaryID: Self.dictionaryID, snapshot: saved)

        let entries = try repository.fetchSavedEntries()
        #expect(entries.map(\.dictionaryID) == [Self.dictionaryID])
        #expect(entries.map(\.snapshot) == [saved])
        #expect(try repository.isSaved(dictionaryID: Self.dictionaryID, key: saved.key))
    }

    @Test func save_whenCalledMultipleTimes_shouldNotDuplicate() throws {
        try repository.save(dictionaryID: Self.dictionaryID, snapshot: snapshot("食べる"))
        try repository.save(
            dictionaryID: Self.dictionaryID,
            snapshot: snapshot("食べる", fingerprint: "edited")
        )

        #expect(try repository.fetchSavedEntries().map(\.snapshot) == [snapshot("食べる")])
    }

    @Test func save_shouldKeepEveryPartOfTheIdentityApart() throws {
        let snapshots = [
            snapshot("食べる"),
            snapshot("食べる", sequence: 200),
            snapshot("食べる", ordinal: 1),
            snapshot("喰べる")
        ]
        for saved in snapshots {
            try repository.save(dictionaryID: Self.dictionaryID, snapshot: saved)
        }
        try repository.save(dictionaryID: "Other", snapshot: snapshot("食べる"))

        #expect(try repository.fetchSavedEntries().count == 5)
    }

    @Test func savedTerms_shouldCompareByCodePoint() throws {
        // U+716E and the compatibility ideograph U+FA48 are canonically equivalent.
        try repository.save(dictionaryID: Self.dictionaryID, snapshot: snapshot("\u{716E}る"))

        let compatibility = snapshot("\u{FA48}る").key
        #expect(!(try repository.isSaved(dictionaryID: Self.dictionaryID, key: compatibility)))

        try repository.save(dictionaryID: Self.dictionaryID, snapshot: snapshot("\u{FA48}る"))
        #expect(try repository.fetchSavedEntries().count == 2)
    }

    @Test func unsave_shouldOnlyAffectTargetEntry() throws {
        try repository.save(dictionaryID: Self.dictionaryID, snapshot: snapshot("食べる"))
        try repository.save(dictionaryID: "Other", snapshot: snapshot("食べる"))

        try repository.unsave(dictionaryID: Self.dictionaryID, key: snapshot("食べる").key)

        #expect(
            !(try repository.isSaved(dictionaryID: Self.dictionaryID, key: snapshot("食べる").key))
        )
        #expect(try repository.fetchSavedEntries().map(\.dictionaryID) == ["Other"])
    }

    @Test func unsave_whenNotSaved_shouldDoNothing() throws {
        try repository.unsave(dictionaryID: Self.dictionaryID, key: snapshot("食べる").key)

        #expect(try repository.fetchSavedEntries().isEmpty)
    }

    @Test func fetchSavedEntries_shouldReturnNewestFirst() throws {
        for term in ["一", "二", "三"] {
            try repository.save(dictionaryID: Self.dictionaryID, snapshot: snapshot(term))
        }

        #expect(try repository.fetchSavedEntries().map(\.snapshot.key.term) == ["三", "二", "一"])
    }
}
