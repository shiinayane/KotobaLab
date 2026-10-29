//
//  WordDetailStoreTests.swift
//  KotobaLabTests
//
//  Created by shiinayane on 2026/10/29.
//

import Foundation
import Testing

@testable import KotobaLab

@MainActor struct WordDetailStoreTests {
    @Test func toggleSaved_whenSaveFails_shouldKeepLoadedDetail() async throws {
        let store = makeStore(userDataRepository: FailingWriteUserDataRepository())
        await store.load()

        store.toggleSaved()

        guard case .loaded(let detail) = store.state else {
            Issue.record("Expected loaded state, got \(store.state)")
            return
        }
        #expect(detail.id == 1)
        #expect(store.isSaved == false)
        #expect(store.saveErrorMessage != nil)
    }

    @Test func dismissSaveError_shouldClearMessage() async throws {
        let store = makeStore(userDataRepository: FailingWriteUserDataRepository())
        await store.load()
        store.toggleSaved()

        store.dismissSaveError()

        #expect(store.saveErrorMessage == nil)
    }

    @Test func toggleSaved_whenSaveSucceeds_shouldMarkSavedWithoutError() async throws {
        let store = makeStore(userDataRepository: MockUserDataRepository(savedWordsRecord: []))
        await store.load()

        store.toggleSaved()

        #expect(store.isSaved == true)
        #expect(store.saveErrorMessage == nil)
    }

    private func makeStore(
        userDataRepository: any UserDataRepositoryProtocol
    ) -> WordDetailStore {
        let dictionaryRepository = MockDictionaryRepository()

        return WordDetailStore(
            loadWordDetailUseCase: LoadWordDetailUseCase(
                wordID: 1,
                dictionaryRepository: dictionaryRepository,
                userDataRepository: userDataRepository
            ),
            toggleSavedWordUseCase: ToggleSavedWordUseCase(
                wordID: 1,
                userDataRepository: userDataRepository
            )
        )
    }
}

/// Reads succeed and report nothing saved; every write fails.
private final class FailingWriteUserDataRepository: UserDataRepositoryProtocol {
    struct WriteError: Error {}

    func isWordSaved(wordID: Int64) throws -> Bool { false }

    func saveWord(wordID: Int64) throws { throw WriteError() }

    func unsaveWord(wordID: Int64) throws { throw WriteError() }

    func fetchSavedWordIDs() throws -> [Int64] { [] }
}
