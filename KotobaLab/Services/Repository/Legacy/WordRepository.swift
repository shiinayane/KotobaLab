//
//  WordRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/28.
//

import Foundation

struct WordRepository {
    
    //  Load mock data from words.json
    func loadWords() -> [WordEntry] {
        guard
            let url = Bundle.main.url(forResource: "words", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let words = try? JSONDecoder().decode([WordEntry].self, from: data)
        else {
            return []
        }
        
        return words
    }
    
    func loadSavedWords() -> [WordEntry] {
        guard
            let url = Bundle.main.url(forResource: "SavedWords", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let savedWords = try? JSONDecoder().decode([WordEntry].self, from: data)
        else {
            return []
        }
        
        return savedWords
    }
}
