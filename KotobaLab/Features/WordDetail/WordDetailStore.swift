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

    private(set) var isSaved = false
    /// Whether the saved state is known, so the bookmark can be toggled safely.
    private(set) var canToggleSaved = false
    private(set) var state: WordDetailViewState = .idle
    /// The message to show when the saved state cannot be read or changed.
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
                applySavedState(displayData.isSaved)
            } else {
                state = .notFound
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func toggleSaved() {
        guard canToggleSaved else { return }

        do {
            isSaved = try toggleSavedWordUseCase.execute()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    func dismissSaveError() {
        saveErrorMessage = nil
    }

    private func applySavedState(_ savedState: Bool?) {
        guard let savedState else {
            isSaved = false
            canToggleSaved = false
            saveErrorMessage = "Could not check whether this word is saved."
            return
        }
        isSaved = savedState
        canToggleSaved = true
    }
}

enum WordDetailViewState {
    case idle
    case loading
    case loaded(WordDetail)
    case notFound
    case error(String)
}
