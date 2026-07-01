//
//  SearchStore.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/03/28.
//

import Foundation

@MainActor @Observable final class SearchStore {
    var query = ""
    private(set) var state: SearchViewState = .idle
    private var searchTask: Task<Void, Never>?
    private var searchGeneration = 0

    private let searchWordsUseCase: SearchWordsUseCase

    init(searchWordsUseCase: SearchWordsUseCase) {
        self.searchWordsUseCase = searchWordsUseCase
    }

    func debouncedSearch() {
        searchTask?.cancel()

        searchGeneration += 1
        let myGen = searchGeneration

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        state = .loading

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            await self?.search(generation: myGen, query: trimmed)
        }
    }

    private func search(generation myGen: Int, query: String) async {
        do {
            let results = try await searchWordsUseCase.execute(query: query)

            guard myGen == searchGeneration else { return }

            state = results.isEmpty ? .empty(query: query) : .loaded(results)
        } catch {
            guard myGen == searchGeneration else { return }

            state = .error(error.localizedDescription)
        }
    }
}

enum SearchViewState {
    case idle  // query is empty — show a hint, not an empty list
    case loading  // a search is in flight
    case empty(query: String)  // searched, zero results
    case loaded([WordSummary])
    case error(String)
}
