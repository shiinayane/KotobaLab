//
//  ToggleSavedWordUseCaseTests.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/09.
//

import Foundation
import Testing

@testable import KotobaLab

struct ToggleSavedWordUseCaseTests {
    @MainActor @Test func toggleSavedWord_whenWordIsNotSaved_shouldSavedWord() throws {
        // Arrange / Given
        let repository = MockUserDataRepository(savedWordsRecord: [])

        let useCase = ToggleSavedWordUseCase(
            wordID: 1,
            userDataRepository: repository
        )

        // Act / When
        let isSaved = try useCase.execute()

        // Assert / Then
        #expect(isSaved == true)
        #expect(try repository.isWordSaved(wordID: 1) == true)
    }

    @MainActor @Test func toggleSavedWord_whenWordIsSaved_shouldUnsavedWord() throws {
        let repository = MockUserDataRepository(
            savedWordsRecord: [
                SavedWordRecordData(
                    wordID: 1,
                    savedAt: Date(timeIntervalSince1970: 100)
                )
            ]
        )

        let useCase = ToggleSavedWordUseCase(
            wordID: 1,
            userDataRepository: repository
        )

        let isSaved = try useCase.execute()

        #expect(isSaved == false)
        #expect(try repository.isWordSaved(wordID: 1) == false)
    }
}
