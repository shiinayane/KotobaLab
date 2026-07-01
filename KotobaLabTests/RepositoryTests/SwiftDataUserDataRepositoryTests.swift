//
//  SwiftDataUserDataRepositoryTests.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/07/01.
//

import Foundation
import SwiftData
import Testing

@testable import KotobaLab

@MainActor struct SwiftDataUserDataRepositoryTests {
    let container: ModelContainer
    let repository: SwiftDataUserDataRepository

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SavedWordRecord.self, configurations: config)

        repository = SwiftDataUserDataRepository(context: container.mainContext)
    }

    @Test func saveWord_shouldMarkWordAsSaved() throws {
        try repository.saveWord(wordID: 1)
        #expect(try repository.isWordSaved(wordID: 1))
    }

    @Test func saveWord_whenCalledMultipleTimes_shouldNotDuplicate() throws {
        try repository.saveWord(wordID: 1)
        try repository.saveWord(wordID: 1)
        #expect(try repository.fetchSavedWordIDs() == [1])
    }

    @Test func unsaveWord_shouldMarkWordAsNotSaved() throws {
        try repository.saveWord(wordID: 1)
        try repository.unsaveWord(wordID: 1)
        #expect(!(try repository.isWordSaved(wordID: 1)))
    }

    @Test func unsaveWord_whenWordNotSaved_shouldDoNothing() throws {
        try repository.unsaveWord(wordID: 999)
        #expect(try repository.fetchSavedWordIDs().isEmpty)
    }

    @Test func unsaveWord_shouldOnlyAffectTargetWord() throws {
        try repository.saveWord(wordID: 1)
        try repository.saveWord(wordID: 2)
        try repository.unsaveWord(wordID: 1)
        #expect(!(try repository.isWordSaved(wordID: 1)))
        #expect(try repository.isWordSaved(wordID: 2))
    }

    @Test func fetchSavedWordIDs_shouldReturnInReverseChronologicalOrder() throws {
        try repository.saveWord(wordID: 1)
        try repository.saveWord(wordID: 2)
        try repository.saveWord(wordID: 3)
        #expect(try repository.fetchSavedWordIDs() == [3, 2, 1])
    }

    @Test func isWordSaved_whenNothingSaved_shouldReturnFalse() throws {
        #expect(!(try repository.isWordSaved(wordID: 1)))
        #expect(try repository.fetchSavedWordIDs().isEmpty)
    }
}
