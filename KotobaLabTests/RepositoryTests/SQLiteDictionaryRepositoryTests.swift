//
//  SQLiteDictionaryRepositoryTests.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/15.
//

import Foundation
import Testing

@testable import KotobaLab

struct SQLiteDictionaryRepositoryTests {
    let repository: SQLiteDictionaryRepository

    init() throws {
        let bundle = Bundle(for: TestBundleMarker.self)

        let fixtureURL = try #require(
            bundle.url(forResource: "test_dictionary", withExtension: "sqlite")
        )

        // Copy the sqlite to the temp dir.
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString + ".sqlite"
        )
        try FileManager.default.copyItem(at: fixtureURL, to: tempURL)

        let databaseManager = try DatabaseManager(databaseURL: tempURL)
        repository = SQLiteDictionaryRepository(databaseManager: databaseManager)
    }

    @Test func searchByTermPrefix_ReturnsMatchingWords() async throws {
        let result = try await repository.searchWords(query: "食", limit: 10)

        #expect(result.map(\.term) == ["食べる"])
    }

    @Test func searchByReadingPrefix_ReturnsMatchingWords() async throws {
        let result = try await repository.searchWords(query: "た", limit: 10)

        #expect(result.map(\.term) == ["食べる"])
    }

    @Test func loadWordDetail_ReturnsMeaningsInSequenceOrder() async throws {
        let detail = try #require(
            try await repository.fetchWordDetail(wordID: 1)
        )

        #expect(detail.term == "日本")
        #expect(detail.meanings.map(\.definition) == ["Japan", "Japanese"])
    }
}

private final class TestBundleMarker {}
