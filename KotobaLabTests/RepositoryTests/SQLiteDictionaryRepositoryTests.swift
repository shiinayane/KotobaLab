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
    @Test
    @MainActor
    func searchByTermPrefix_ReturnsMatchingWords() throws {
        let repository = try makeRepository()

        let result = try repository.searchWords(query: "食", limit: 10)

        #expect(result.map(\.term) == ["食べる"])
    }

    @Test
    @MainActor
    func searchByReadingPrefix_ReturnsMatchingWords() throws {
        let repository = try makeRepository()

        let result = try repository.searchWords(query: "た", limit: 10)

        #expect(result.map(\.term) == ["食べる"])
    }

    @Test
    @MainActor
    func loadWordDetail_ReturnsMeaningsInSequenceOrder() throws {
        let repository = try makeRepository()

        let detail = try #require(
            try repository.fetchWordDetail(wordID: 1)
        )

        #expect(detail.term == "日本")
        #expect(detail.meanings.map(\.definition) == ["Japan", "Japanese"])
    }
}

private final class TestBundleMarker {}

@MainActor
private func makeRepository() throws -> SQLiteDictionaryRepository {
    let bundle = Bundle(for: TestBundleMarker.self)

    let fixtureURL = try #require(
        bundle.url(
            forResource: "test_dictionary",
            withExtension: "sqlite"
        )
    )

    let databaseManager = try DatabaseManager(databaseURL: fixtureURL)
    return SQLiteDictionaryRepository(databaseManager: databaseManager)
}
