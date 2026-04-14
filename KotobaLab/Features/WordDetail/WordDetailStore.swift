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
    
    var state: WordDetailViewState = .loading
    var isSaved = false
    
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
        if case .loading = state {
            return
        }
        
        state = .loading
        
        do {
            let fetchedDetail = try dictionaryRepository.fetchWordDetail(wordID: wordID)
            
            if let fetchedDetail {
                state = .loaded(fetchedDetail)
                isSaved = (try? userDataRepository.isWordSaved(wordID: wordID)) ?? false
            } else {
                state = .notFound
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func toggleSaved() {
        do {
            if isSaved {
                try userDataRepository.unsaveWord(wordID: wordID)
                isSaved = false
            } else {
                try userDataRepository.saveWord(wordID: wordID)
                isSaved = true
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

enum WordDetailViewState {
    case loading
    case loaded(WordDetail)
    case notFound
    case error(String)
}
