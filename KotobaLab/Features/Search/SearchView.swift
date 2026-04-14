//
//  SearchView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct SearchView: View {
    let dependencies: AppDependencies
    @Bindable var store: SearchStore
    
    var body: some View {
        List(store.results) { word in
            NavigationLink {
                WordDetailScene(
                    wordID: word.id,
                    dependencies: dependencies
                )
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
        dictionaryRepository: MockDictionaryRepository()
    )
    
    TabContainer(title: "Search") {
        SearchView(
            dependencies: dependencies,
            store: .previewWithResults()
        )
    }
    .environment(AppRouter())
}
