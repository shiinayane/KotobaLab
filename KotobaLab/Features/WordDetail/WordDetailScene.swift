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
            dictionaryRepository: dependencies.dictionaryRepository,
            context: context
        )
    }
}

struct WordDetailContainerView: View {
    @State private var store: WordDetailStore
    
    init(
        wordID: Int64,
        dictionaryRepository: any DictionaryRepositoryProtocol,
        context: ModelContext
    ) {
        let userDataRepository = SwiftDataRepository(context: context)
        _store = State(
            initialValue: WordDetailStore(
                wordID: wordID,
                dictionaryRepository: dictionaryRepository,
                userDataRepository: userDataRepository
            )
        )
    }
    
    var body: some View {
        WordDetailView(store: store)
    }
}
