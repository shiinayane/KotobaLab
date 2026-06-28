//
//  LoadSavedWordsUseCaseTests.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/10.
//

import Foundation
import Testing

@testable import KotobaLab

struct LoadSavedWordsUseCaseTests {
    @MainActor @Test func loadSavedWords_whenNoSavedWords_shouldReturnEmptyArray() async throws {
        let dictionaryRepository = MockDictionaryRepository()
        let userDataRepository = MockUserDataRepository(savedWordsRecord: [])

        let useCase = LoadSavedWordsUseCase(
            dictionaryRepository: dictionaryRepository,
            userDataRepository: userDataRepository
        )

        let result = try await useCase.execute()

        #expect(result.isEmpty)
    }

    @MainActor @Test func loadSavedWords_whenSavedWordIDsExist_shouldReturnMatchingWords() async throws {
        let dictionaryRepository = MockDictionaryRepository()
        let userDataRepository = MockUserDataRepository(
            savedWordsRecord: [
                SavedWordRecordData(
                    wordID: 1,
                    savedAt: Date(timeIntervalSince1970: 100)
                ),
                SavedWordRecordData(
                    wordID: 2,
                    savedAt: Date(timeIntervalSince1970: 200)
                ),
            ]
        )

        let useCase = LoadSavedWordsUseCase(
            dictionaryRepository: dictionaryRepository,
            userDataRepository: userDataRepository
        )

        let result = try await useCase.execute()

        #expect(result.count == 2)
        #expect(result.map(\.id) == [2, 1])
    }
}
