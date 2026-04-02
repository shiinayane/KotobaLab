//
//  SavedStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/29.
//

import Observation

@Observable
final class SavedStore {
    private let repository = WordRepository()
    
    var savedWords: [WordEntry] = []
    
    func loadSavedWords() {
        savedWords = repository.loadSavedWords()
    }
}
