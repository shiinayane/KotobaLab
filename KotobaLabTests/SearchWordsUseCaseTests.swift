//
//  SearchWordsUseCaseTests.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/10.
//

import Foundation
import Testing
@testable import KotobaLab

struct SearchWordsUseCaseTests {
    
    @Test
    @MainActor
    func searchWords_whenQueryIsEmpty_shouldReturnEmptyArray() throws {
        let repository = MockDictionaryRepository()
        
        let useCase = SearchWordsUseCase(dictionaryRepository: repository)
        
        let result = try useCase.execute(query: "")
        
        #expect(result.isEmpty)
    }
    
    @Test
    @MainActor
    func searchWords_whenQueryMatchesWords_shouldReturnMatchingResults() throws {
        // Mock data has "食べる", "食器", "食欲"
        let repository = MockDictionaryRepository()
        
        let useCase = SearchWordsUseCase(dictionaryRepository: repository)
        
        let result = try useCase.execute(query: "食")
        
        #expect(result.count == 3)
        #expect(result.map(\.term) == ["食べる", "食器", "食欲"])
    }
    
    @Test
    @MainActor
    func searchWords_whenNoWordsMatch_shouldReturnEmptyArray() throws {
        let repository = MockDictionaryRepository()
        
        let useCase = SearchWordsUseCase(dictionaryRepository: repository)
        
        let result = try useCase.execute(query: "xyz")
        
        #expect(result.isEmpty)
    }
}
