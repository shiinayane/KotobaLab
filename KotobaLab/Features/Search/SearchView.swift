//
//  SearchView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct SearchView: View {
    @State private var store = SearchStore()

    var body: some View {
        List(store.results) { word in
            Text(word.term)
        }
        .searchable(text: $store.query)
        .onChange(of: store.query) {
            store.search()
        }
        .task {
            store.loadWords()
        }

    }
}

#Preview {
    AppTabContainer(title: "Search") {
        SearchView()
    }
    .environment(AppRouter())
}
