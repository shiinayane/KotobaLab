//
//  SearchWordsUseCaseTests.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/10.
//

import Testing

@testable import KotobaLab

struct SearchWordsUseCaseTests {
    @Test func searchWords_whenQueryIsEmpty_shouldReturnEmptyArray() async throws {
        let repository = MockDictionaryRepository()

        let useCase = SearchWordsUseCase(dictionaryRepository: repository)

        let result = try await useCase.execute(query: "")

        #expect(result.isEmpty)
    }

    @Test func searchWords_whenQueryMatchesWords_shouldReturnMatchingResults() async throws {
        // Mock data has "食べる", "食器", "食欲"
        let repository = MockDictionaryRepository()

        let useCase = SearchWordsUseCase(dictionaryRepository: repository)

        let result = try await useCase.execute(query: "食")

        #expect(result.count == 3)
        #expect(result.map(\.term) == ["食べる", "食器", "食欲"])
    }

    @Test func searchWords_whenNoWordsMatch_shouldReturnEmptyArray() async throws {
        let repository = MockDictionaryRepository()

        let useCase = SearchWordsUseCase(dictionaryRepository: repository)

        let result = try await useCase.execute(query: "xyz")

        #expect(result.isEmpty)
    }
}
