//
//  WordDetailScene.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/14.
//

import SwiftData
import SwiftUI

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
        let userDataRepository = dependencies.userDataRepositoryFactory.make(context)

        let loadWordDetailUseCase = LoadWordDetailUseCase(
            wordID: wordID,
            dictionaryRepository: dependencies.dictionaryRepository,
            userDataRepository: userDataRepository
        )
        let toggleSavedWordUseCase = ToggleSavedWordUseCase(
            wordID: wordID,
            userDataRepository: userDataRepository
        )

        _store = State(
            initialValue: WordDetailStore(
                loadWordDetailUseCase: loadWordDetailUseCase,
                toggleSavedWordUseCase: toggleSavedWordUseCase
            )
        )
    }

    var body: some View {
        WordDetailView(store: store)
    }
}
