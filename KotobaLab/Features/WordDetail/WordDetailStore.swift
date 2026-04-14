//
//  WordDetailStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/10.
//

import Foundation

@Observable
final class WordDetailStore {
    let wordID: Int64
    private let dictionaryRepository: any DictionaryRepositoryProtocol
    private let userDataRepository: any UserDataRepositoryProtocol
    
    var detail: WordDetail?
    var isLoading: Bool = false
    var notFound = false
    var errorMessage: String?
    
    init(
        wordID: Int64,
        dictionaryRepository: any DictionaryRepositoryProtocol,
        userDataRepository: any UserDataRepositoryProtocol
    ) {
        self.wordID = wordID
        self.dictionaryRepository = dictionaryRepository
        self.userDataRepository = userDataRepository
    }
    
    func load() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        notFound = false
        
        do {
            let fetchedDetail = try dictionaryRepository.fetchWordDetail(id: wordID)
            
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
