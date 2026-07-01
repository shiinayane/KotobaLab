//
//  LoadWordDetailUseCaseTests.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/05/10.
//

import Foundation
import Testing

@testable import KotobaLab

struct LoadWordDetailUseCaseTests {
    @Test func loadWordDetail_whenWordDoesNotExist_shouldReturnNil() async throws {
        let wordID: Int64 = 0
        let dictionaryRepository = MockDictionaryRepository()
        let userDataRepository = MockUserDataRepository()

        let useCase = LoadWordDetailUseCase(
            wordID: wordID,
            dictionaryRepository: dictionaryRepository,
            userDataRepository: userDataRepository
        )

        let result = try await useCase.execute()

        #expect(result == nil)
    }

    @Test func loadWordDetail_whenWordExistsAndIsSaved_shouldReturnSavedDetail()
        async throws
    {
        let wordID: Int64 = 1
        let dictionaryRepository = MockDictionaryRepository()
        let userDataRepository = MockUserDataRepository(
            savedWordsRecord: [
                SavedWordRecordData(
                    wordID: 1,
                    savedAt: Date(timeIntervalSince1970: 100)
                )
            ]
        )

        let useCase = LoadWordDetailUseCase(
            wordID: wordID,
            dictionaryRepository: dictionaryRepository,
            userDataRepository: userDataRepository
        )

        let result = try await useCase.execute()

        #expect(result != nil)
        #expect(result?.detail.id == wordID)
        #expect(result?.isSaved == true)
    }

    @Test func loadWordDetail_whenWordExistsAndIsNotSaved_shouldReturnUnsavedDetail()
        async throws
    {
        let wordID: Int64 = 1
        let dictionaryRepository = MockDictionaryRepository()
        let userDataRepository = MockUserDataRepository(savedWordsRecord: [])

        let useCase = LoadWordDetailUseCase(
            wordID: wordID,
            dictionaryRepository: dictionaryRepository,
            userDataRepository: userDataRepository
        )

        let result = try await useCase.execute()

        #expect(result != nil)
        #expect(result?.detail.id == wordID)
        #expect(result?.isSaved == false)
    }
}
