//
//  WordDetailStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/10.
//

import Foundation

@Observable
final class WordDetailStore {
    private let repository: DictionaryRepositoryProtocol
    let wordId: Int64
    
    var detail: WordDetail?
    var isLoading: Bool = false
    var notFound = false
    var errorMessage: String?
    
    init(wordId: Int64, repository: DictionaryRepositoryProtocol) {
        self.wordId = wordId
        self.repository = repository
    }
    
    func load() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        notFound = false
        
        do {
            let fetchedDetail = try repository.fetchWordDetail(id: wordId)
            
            if let fetchedDetail {
                detail = fetchedDetail
            } else {
                detail = nil
                notFound = true
            }
        } catch {
            detail = nil
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
