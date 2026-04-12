//
//  RootView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct RootView: View {
    let dictionaryRepository: any DictionaryRepositoryProtocol
    let userDataRepository: any UserDataRepositoryProtocol
    
    @State private var router = AppRouter()
    @State private var searchStore: SearchStore
    
    init(
        dictionaryRepository: any DictionaryRepositoryProtocol,
        userDataRepository: any UserDataRepositoryProtocol
    ) {
        self.dictionaryRepository = dictionaryRepository
        self.userDataRepository = userDataRepository
        _searchStore = State(initialValue: SearchStore(repository: dictionaryRepository))
    }
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                TabContainer(title: "Home") {
                    HomeView()
                }
            }
            Tab("Analysis", systemImage: "translate") {
                TabContainer(title: "Analysis") {
                    AnalysisView()
                }
            }
            Tab("Study", systemImage: "character.book.closed.ja") {
                TabContainer(title: "Study") {
                    StudyView()
                }
            }
            Tab("Saved", systemImage: "bookmark") {
                TabContainer(title: "Saved") {
                    SavedView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                TabContainer(title: "Search") {
                    SearchView(
                        store: searchStore,
                        dictionaryRepository: dictionaryRepository
                    )
                }
            }
        }
        .sheet(item: Binding(
                    get: { router.presentedSheet },
                    set: { router.presentedSheet = $0 }
                )) { sheet in
                    switch sheet {
                    case .settings:
                        SettingsView()
                    }
                }
                .environment(router)
    }
}

#Preview {
    let dictionaryRepository = MockDictionaryRepository()
    let userDataRepository = MockUserDataRepository()
    
    RootView(
        dictionaryRepository: dictionaryRepository,
        userDataRepository: userDataRepository
    )
}
