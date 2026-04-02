//
//  SearchStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/28.
//

import Observation
import Foundation

@Observable
class SearchStore{
    var query: String = ""
    var allWords: [WordEntry] = []
    var results: [WordEntry] = []
    
    private let repository = WordRepository()
    
    func loadWords() {
        allWords = repository.loadWords()
        results = allWords
    }
    
    func search() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !q.isEmpty else {
            results = allWords
            return
        }
        
        results = allWords.filter {
            $0.term.contains(q) ||
            $0.reading.contains(q)
        }
    }
}
