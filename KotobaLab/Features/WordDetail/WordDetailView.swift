//
//  WordDetailView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct WordDetailView: View {
    @Bindable var store: WordDetailStore
    
    var body: some View {
        content
        .navigationTitle("Word Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if case .loaded = store.state {
                    bookmarkButton
                }
            }
        }
        .task {
            store.load()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ProgressView()
        case .loaded(let detail):
            detailContent(detail: detail)
        case .notFound:
            notFoundView()
        case .error(let message):
            errorView(message: message)
        }
    }
    
    private func detailContent(detail: WordDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection(detail: detail)
                meaningSection(detail: detail)
            }
            .padding(16)
        }
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
    
    private var bookmarkButton: some View {
        Button {
            store.toggleSaved()
        } label: {
            store.isSaved ?
            Image(systemName: "bookmark.fill") :
            Image(systemName: "bookmark")
        }
    }
    
    private func notFoundView() -> some View {
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
}

#Preview {
    let store = WordDetailStore(
        wordID: 1,
        dictionaryRepository: MockDictionaryRepository(),
        userDataRepository: MockUserDataRepository()
    )
    
    if let detail = try? MockDictionaryRepository().fetchWordDetail(wordID: 1) {
        store.state = .loaded(detail)
    }
    
    return NavigationStack {
        WordDetailView(store: store)
    }
}
