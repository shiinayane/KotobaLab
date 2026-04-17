//
//  SearchWordsUseCase.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/17.
//

import Foundation

struct SearchWordsUseCase {
    private let dictionaryRepository: any DictionaryRepositoryProtocol
    
    init(dictionaryRepository: any DictionaryRepositoryProtocol) {
        self.dictionaryRepository = dictionaryRepository
    }
    
    func execute(query: String) throws -> [WordSummary] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !q.isEmpty else {
            return []
        }
        
        return try dictionaryRepository.searchWords(query: q, limit: 20)
    }
    
    
}
