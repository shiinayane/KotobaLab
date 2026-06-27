//
//  LoadWordDetailUseCaseTests.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/10.
//

import Foundation
import Testing

@testable import KotobaLab

struct LoadWordDetailUseCaseTests {
    @MainActor @Test func loadWordDetail_whenWordDoesNotExist_shouldReturnNil() throws {
        let wordID: Int64 = 0
        let dictionaryRepository = MockDictionaryRepository()
        let userDataRepository = MockUserDataRepository()

        let useCase = LoadWordDetailUseCase(
            wordID: wordID,
            dictionaryRepository: dictionaryRepository,
            userDataRepository: userDataRepository
        )

        let result = try useCase.execute()

        #expect(result == nil)
    }

    @MainActor @Test func loadWordDetail_whenWordExistsAndIsSaved_shouldReturnSavedDetail() throws {
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

        let result = try useCase.execute()

        #expect(result != nil)
        #expect(result?.detail.id == wordID)
        #expect(result?.isSaved == true)
    }

    @MainActor @Test func loadWordDetail_whenWordExistsAndIsNotSaved_shouldReturnUnsavedDetail()
        throws
    {
        let wordID: Int64 = 1
        let dictionaryRepository = MockDictionaryRepository()
        let userDataRepository = MockUserDataRepository(savedWordsRecord: [])

        let useCase = LoadWordDetailUseCase(
            wordID: wordID,
            dictionaryRepository: dictionaryRepository,
            userDataRepository: userDataRepository
        )

        let result = try useCase.execute()

        #expect(result != nil)
        #expect(result?.detail.id == wordID)
        #expect(result?.isSaved == false)
    }
}
