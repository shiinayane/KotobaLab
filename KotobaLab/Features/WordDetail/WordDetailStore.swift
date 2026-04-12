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
    let wordID: Int64
    
    var detail: WordDetail?
    var isLoading: Bool = false
    var notFound = false
    var errorMessage: String?
    
    init(wordID: Int64, repository: DictionaryRepositoryProtocol) {
        self.wordID = wordID
        self.repository = repository
    }
    
    func load() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        notFound = false
        
        do {
            let fetchedDetail = try repository.fetchWordDetail(id: wordID)
            
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
