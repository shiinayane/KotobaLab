//
//  SearchView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct SearchView: View {
    @Bindable var store: SearchStore
    let repository: any DictionaryRepositoryProtocol
    
    var body: some View {
        List(store.results) { word in
            SearchResultRow(word: word, repository: repository)
        }
        .searchable(text: $store.query)
        .onChange(of: store.query) { _, _ in
            store.debouncedSearch()
        }
    }
}

struct SearchResultRow: View {
    let word: WordSummary
    let repository: any DictionaryRepositoryProtocol
    
    var body: some View {
        NavigationLink {
            WordDetailView(store: WordDetailStore(wordId: word.id, repository: repository))
        } label: {
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
}

#Preview {
    let repository = MockDictionaryRepository()
    TabContainer(title: "Search") {
        SearchView(store: .previewWithResults(), repository: repository)
    }
    .environment(AppRouter())
}
