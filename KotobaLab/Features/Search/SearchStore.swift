//
//  SearchStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/28.
//

import Foundation
import Observation

@Observable
@MainActor
final class SearchStore {
    var query: String = ""
    private(set) var state: SearchViewState = .idle
    private var searchTask: Task<Void, Never>?
    private var searchGeneration = 0

    private let searchWordsUseCase: SearchWordsUseCase

    init(searchWordsUseCase: SearchWordsUseCase) {
        self.searchWordsUseCase = searchWordsUseCase
    }

    func debouncedSearch() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        searchGeneration += 1
        let myGen = searchGeneration

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            self?.search(generation: myGen, query: trimmed)
        }
    }

    private func search(generation myGen: Int, query: String) {
        do {
            let results = try searchWordsUseCase.execute(query: query)

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
