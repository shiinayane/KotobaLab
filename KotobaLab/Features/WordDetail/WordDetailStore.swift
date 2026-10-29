//
//  WordDetailStore.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/04/10.
//

import Foundation

@MainActor @Observable final class WordDetailStore {
    private let loadWordDetailUseCase: LoadWordDetailUseCase
    private let toggleSavedWordUseCase: ToggleSavedWordUseCase

    var isSaved = false
    private(set) var state: WordDetailViewState = .idle
    /// The message to show when saving or unsaving fails.
    ///
    /// The loaded detail stays on screen while this is set.
    private(set) var saveErrorMessage: String?

    init(
        loadWordDetailUseCase: LoadWordDetailUseCase,
        toggleSavedWordUseCase: ToggleSavedWordUseCase
    ) {
        self.loadWordDetailUseCase = loadWordDetailUseCase
        self.toggleSavedWordUseCase = toggleSavedWordUseCase
    }

    func load() async {
        if case .loading = state { return }

        state = .loading

        do {
            let displayData = try await loadWordDetailUseCase.execute()

            if let displayData {
                state = .loaded(displayData.detail)
                isSaved = displayData.isSaved
            } else {
                state = .notFound
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func toggleSaved() {
        do {
            isSaved = try toggleSavedWordUseCase.execute()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    func dismissSaveError() {
        saveErrorMessage = nil
    }
}

enum WordDetailViewState {
    case idle
    case loading
    case loaded(WordDetail)
    case notFound
    case error(String)
}
