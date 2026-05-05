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
        List(store.results) { word in
            NavigationLink {
                makeDestination(word.id)
            } label: {
                WordSummaryRow(word: word)
            }
        }
        .searchable(text: $store.query)
        .onChange(of: store.query) { _, _ in
            store.debouncedSearch()
        }
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
