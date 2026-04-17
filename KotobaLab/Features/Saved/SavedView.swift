//
//  SavedView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct SavedView: View {
    @Bindable var store: SavedStore
    let makeDestination: (Int64) -> AnyView
    
    var body: some View {
        content
        .onAppear {
            store.load()
        }
        .searchable(
            text: $store.query
        )
    }
    
    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let savedWords):
            loadedContent(savedWords: savedWords)
        case .error(let message):
            errorView(message: message)
        }
    }
    
    @ViewBuilder
    private func loadedContent(savedWords: [WordSummary]) -> some View {
        let filteredSavedWords = store.filteredSavedWords
        
        if savedWords.isEmpty {
            emptySavedView()
        } else if store.query.isEmpty {
            savedContent(words: savedWords)
        } else if filteredSavedWords.isEmpty {
            noResultsView()
        } else {
            savedContent(words: filteredSavedWords)
        }
    }
    
    private func savedContent(words: [WordSummary]) -> some View {
        List(words) { word in
            NavigationLink {
                makeDestination(word.id)
            } label: {
                SearchResultRow(word: word)
            }
        }
    }
    
    private func emptySavedView() -> some View {
        ContentUnavailableView(
            "No saved words",
            systemImage: "bookmark",
            description: Text("Words you save will appear here.")
        )
    }
    
    private func noResultsView() -> some View {
        ContentUnavailableView(
            "No results",
            systemImage: "magnifyingglass",
            description: Text("No matches for \"\(store.query)\"")
        )
    }
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Fail to load",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}

#Preview {
    let dependencies = AppDependencies(
        dictionaryRepository: MockDictionaryRepository(),
        userDataRepositoryFactory: UserDataRepositoryFactory { _ in
            MockUserDataRepository()
        }
    )
    
    let useCase = LoadSavedWordsUseCase(
        dictionaryRepository: MockDictionaryRepository(),
        userDataRepository: MockUserDataRepository()
    )
    
    return TabContainer(title: "Saved") {
        SavedView(
            store: SavedStore(loadSavedWordsUseCase: useCase),
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
    .environment(AppRouter())
}
