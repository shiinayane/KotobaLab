//
//  WordDetailScene.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/14.
//

import SwiftUI
import SwiftData

struct WordDetailScene: View {
    let wordID: Int64
    let dependencies: AppDependencies
    @Environment(\.modelContext) private var context
    
    var body: some View {
        WordDetailContainerView(
            wordID: wordID,
            dependencies: dependencies,
            context: context
        )
    }
}

struct WordDetailContainerView: View {
    let dependencies: AppDependencies
    @State private var store: WordDetailStore
    
    init(
        wordID: Int64,
        dependencies: AppDependencies,
        context: ModelContext
    ) {
        self.dependencies = dependencies
        _store = State(
            initialValue: WordDetailStore(
                wordID: wordID,
                dictionaryRepository: dependencies.dictionaryRepository,
                userDataRepository: dependencies.userDataRepositoryFactory.make(context)
            )
        )
    }
    
    var body: some View {
        WordDetailView(store: store)
    }
}
