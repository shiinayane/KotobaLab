//
//  SearchScene.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/14.
//

import SwiftUI

struct SearchScene: View {
    let dependencies: AppDependencies
    @State private var store: SearchStore
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        
        let useCase = SearchWordsUseCase(dictionaryRepository: dependencies.dictionaryRepository)
        
        _store = State(initialValue: SearchStore(searchWordsUseCase: useCase))
    }
    
    var body: some View {
        return SearchView(
            store: store,
            makeDestination: { wordID in
                AnyView(
                    WordDetailScene(
                        wordID: wordID,
                        dependencies: dependencies
                    )
                )
            }
        )
    }
}
