//
//  SearchStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/28.
//

import Observation
import Foundation

@Observable
@MainActor
final class SearchStore {
    var query: String = ""
    var results: [WordSummary] = []
    
    private let searchWordsUseCase: SearchWordsUseCase
    private var searchTask: Task<Void, Never>?
    
    init(searchWordsUseCase: SearchWordsUseCase) {
        self.searchWordsUseCase = searchWordsUseCase
    }
    
    func search() {
        do {
            results = try searchWordsUseCase.execute(query: query)
        } catch {
            results = []
        }
    }
    
    func debouncedSearch() {
        searchTask?.cancel()
        
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            self.search()
        }
    }
}
