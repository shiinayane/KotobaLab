//
//  SearchStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/28.
//

import Observation
import Foundation

@Observable
final class SearchStore {
    var query: String = ""
    var results: [WordSummary] = []
    
    private let dictionaryRepository: any DictionaryRepositoryProtocol
    private var searchTask: Task<Void, Never>?
    
    init(
        dictionaryRepository: any DictionaryRepositoryProtocol
    ) {
        self.dictionaryRepository = dictionaryRepository
    }
    
    func search() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !q.isEmpty else {
            results = []
            return
        }
        
        do {
            results = try dictionaryRepository.searchWords(query: q, limit: 20)
        } catch {
            print("Search failed:", error)
            results = []
        }
    }
    
    func debouncedSearch() {
        searchTask?.cancel()
        
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.search()
            }
        }
    }
}
