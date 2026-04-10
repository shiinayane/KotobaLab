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
    var query: String = ""
    private let repository = WordRepository()
    
    var savedWords: [WordEntry] = []
    
    func loadSavedWords() {
        savedWords = repository.loadWords()
    }
    
    func search() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = repository.loadWords()
        
        guard !q.isEmpty else {
            return loadSavedWords()
        }
        
        savedWords = words.filter{
            $0.term.contains(query) ||
            $0.reading.contains(query) }
    }
}
