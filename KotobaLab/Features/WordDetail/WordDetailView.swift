//
//  WordDetailView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct WordDetailView: View {
    @State private var store: WordDetailStore
    
    init(store: WordDetailStore) {
        _store = State(initialValue: store)
    }
    
    var body: some View {
        content
        .navigationTitle("Word Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.load()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            if store.isLoading {
                loadingView
            } else if let detail = store.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection(detail: detail)
                        meaningSection(detail: detail)
                    }
                    .padding(16)
                }
            } else if store.notFound {
                notFoundView
            } else if let errorMessage = store.errorMessage {
                errorView(message: errorMessage)
            } else {
                emptyView
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView()
    }
    
    private var notFoundView: some View {
        ContentUnavailableView(
            "Not Found",
            systemImage: "magnifyingglass",
            description: Text("The word you are looking for is not found.")
        )
    }
    
    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Fail to load",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "Empty Content",
            systemImage: "book.closed"
        )
    }
    
    private func headerSection(detail: WordDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.term)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(detail.reading)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
    
    private func meaningSection(detail: WordDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meaning")
                .font(.headline)
            
            ForEach(detail.meanings) { meaning in
                Text(meaning.text)
            }
        }
    }
}

#Preview {
    let repository = MockDictionaryRepository()
    let store = WordDetailStore(wordId: 1, repository: repository)
    
    NavigationStack {
        WordDetailView(store: store)
    }
}
