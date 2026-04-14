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
                SearchResultRow(word: word)
            }
        }
        .searchable(text: $store.query)
        .onChange(of: store.query) { _, _ in
            store.debouncedSearch()
        }
    }
}

struct SearchResultRow: View {
    let word: WordSummary
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(word.term)
                    .font(.headline)
                
                if !word.reading.isEmpty {
                    Text("「\(word.reading)」")
                        .font(.subheadline)
                }
            }

            Text(word.previewMeaning)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
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
