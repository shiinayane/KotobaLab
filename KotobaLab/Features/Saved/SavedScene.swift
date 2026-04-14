//
//  SavedScene.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/14.
//

import SwiftUI
import SwiftData

struct SavedScene: View {
    let dependencies: AppDependencies
    @Environment(\.modelContext) private var context
    
    var body: some View {
        SavedContainerView(
            dependencies: dependencies,
            context: context
        )
    }
}

struct SavedContainerView: View {
    let dependencies: AppDependencies
    @State private var store: SavedStore
    
    init(
        dependencies: AppDependencies,
        context: ModelContext
    ) {
        self.dependencies = dependencies
        _store = State(
            initialValue: SavedStore(
                dictionaryRepository: dependencies.dictionaryRepository,
                userDataRepository: dependencies.userDataRepositoryFactory.make(context)
            )
        )
    }
    
    var body: some View {
        SavedView(
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
