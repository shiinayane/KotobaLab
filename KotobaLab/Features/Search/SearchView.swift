//
//  SearchView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct SearchView: View {
    @Bindable var store: SearchStore
    let makeDestination: (Int64) -> AnyView

    var body: some View {
        content
            .searchable(text: $store.query)
            .onChange(of: store.query) { _, _ in
                store.debouncedSearch()
            }
    }

    @ViewBuilder private var content: some View {
        switch store.state {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView()
        case .empty(let query):
            noResultsView(query: query)
        case .loaded(let results):
            List(results) { word in
                NavigationLink {
                    makeDestination(word.id)
                } label: {
                    WordSummaryRow(word: word)
                }
            }
        case .error(let message):
            errorView(message: message)
        }
    }

    private func noResultsView(query: String) -> some View {
        ContentUnavailableView(
            "No results",
            systemImage: "magnifyingglass",
            description: Text("No matches for \"\(query)\"")
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

    TabContainer(title: "Search") {
        SearchView(
            store: .previewWithResults(),
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
