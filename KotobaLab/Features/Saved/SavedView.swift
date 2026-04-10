//
//  SavedView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct SavedView: View {
    @State private var store = SavedStore()
    
    var body: some View {
        List(store.savedWords) { word in
            NavigationLink {
                
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(word.term)
                            .font(.headline)
                        
                        Text("|")
                        
                        Text(word.reading)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Text(word.meanings[0])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                }
            }
        }
        .task {
            store.loadSavedWords()
        }
        .searchable(
            text: $store.query
        )
        .onChange(of: store.query) { _, _ in
            store.search()
        }
    }
}

#Preview {
    TabContainer(title: "Saved") {
        SavedView()
    }
    .environment(AppRouter())
}
