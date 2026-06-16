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
    private var searchGeneration = 0

    init(searchWordsUseCase: SearchWordsUseCase) {
        self.searchWordsUseCase = searchWordsUseCase
    }
    
    func search(generation myGen: Int) {
        do {
            let r = try searchWordsUseCase.execute(query: query)
            guard myGen == searchGeneration else { return }
            results = r
        } catch {
            guard myGen == searchGeneration else { return }
            results = []
        }
    }
    
    func debouncedSearch() {
        searchGeneration += 1
        let myGen = searchGeneration

        searchTask?.cancel()
        
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            self.search(generation: myGen)
        }
    }
}
