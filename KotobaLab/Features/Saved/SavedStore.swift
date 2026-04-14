//
//  SavedStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/29.
//

import Observation
import Foundation

@Observable
final class SavedStore {
    private let dictionaryRepository: any DictionaryRepositoryProtocol
    private let userDataRepository: any UserDataRepositoryProtocol
    
    var state: SavedViewState = .idle
    
    var query: String = ""
    
    var filteredSavedWords: [WordSummary] {
        switch state {
        case .loaded(let words):
            let normalizedQuery = query
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            
            if normalizedQuery.isEmpty { return words }
            return words.filter {
                $0.term.lowercased().contains(normalizedQuery) ||
                $0.reading.lowercased().contains(normalizedQuery) ||
                $0.previewMeaning.lowercased().contains(normalizedQuery)
            }
        case .idle, .loading, .error:
            return []
        }
    }
    
    init(
        dictionaryRepository: any DictionaryRepositoryProtocol,
        userDataRepository: any UserDataRepositoryProtocol,
    ) {
        self.dictionaryRepository = dictionaryRepository
        self.userDataRepository = userDataRepository
    }
    
    func load() {
        if case .loading = state { return }
        
        state = .loading
        
        do {
            let savedWordIDs = try userDataRepository.fetchSavedWordIDs()
            let savedWords = try dictionaryRepository.fetchWordSummaries(wordIDs: savedWordIDs)
            state = .loaded(savedWords)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

enum SavedViewState {
    case idle
    case loading
    case loaded([WordSummary])
    case error(String)
}
