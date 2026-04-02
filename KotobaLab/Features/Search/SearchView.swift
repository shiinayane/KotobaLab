//
//  SearchView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct SearchView: View {
    @State private var store: SearchStore
    
    init(store: SearchStore) {
        _store = State(initialValue: store)
    }
    
    var body: some View {
        List(store.results) { word in
            SearchResultRow(word: word)
        }
        .searchable(text: $store.query)
        .onChange(of: store.query) { _, _ in
            store.search()
        }
    }
}

struct SearchResultRow: View {
    let word: WordSummary
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                Text(word.term)
                    .font(.headline)
                
                Text("|")
                
                if !word.reading.isEmpty {
                    Text(word.reading)
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
    AppTabContainer(title: "Search") {
        SearchView(store: .previewWithResults())
    }
    .environment(AppRouter())
}
