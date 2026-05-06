//
//  WordDetailStore.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/10.
//

import Foundation

@Observable
final class WordDetailStore {
    private let loadWordDetailUseCase: LoadWordDetailUseCase
    private let toggleSavedWordUseCase: ToggleSavedWordUseCase
    
    var state: WordDetailViewState = .idle
    var isSaved = false
    
    init(
        loadWordDetailUseCase: LoadWordDetailUseCase,
         toggleSavedWordUseCase: ToggleSavedWordUseCase
    ) {
        self.loadWordDetailUseCase = loadWordDetailUseCase
        self.toggleSavedWordUseCase = toggleSavedWordUseCase
    }
    
    func load() {
        if case .loading = state { return }
        
        state = .loading
        
        do {
            let displayData = try loadWordDetailUseCase.execute()
            
            if let displayData {
                state = .loaded(displayData.detail)
                isSaved = displayData.isSaved
            } else {
                state = .notFound
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func toggleSaved() {
        do {
            isSaved = try toggleSavedWordUseCase.execute()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

enum WordDetailViewState {
    case idle
    case loading
    case loaded(WordDetail)
    case notFound
    case error(String)
}
