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
    @MainActor @Test func searchByTermPrefix_ReturnsMatchingWords() async throws {
        let repository = try makeRepository()

        let result = try await repository.searchWords(query: "食", limit: 10)

        #expect(result.map(\.term) == ["食べる"])
    }

    @MainActor @Test func searchByReadingPrefix_ReturnsMatchingWords() async throws {
        let repository = try makeRepository()

        let result = try await repository.searchWords(query: "た", limit: 10)

        #expect(result.map(\.term) == ["食べる"])
    }

    @MainActor @Test func loadWordDetail_ReturnsMeaningsInSequenceOrder() async throws {
        let repository = try makeRepository()

        let detail = try #require(
            try await repository.fetchWordDetail(wordID: 1)
        )

        #expect(detail.term == "日本")
        #expect(detail.meanings.map(\.definition) == ["Japan", "Japanese"])
    }
}

private final class TestBundleMarker {}

@MainActor private func makeRepository() throws -> SQLiteDictionaryRepository {
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
