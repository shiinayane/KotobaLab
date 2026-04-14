//
//  RootView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies
    @State private var router = AppRouter()
    
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
                    SavedScene(dependencies: dependencies)
                }
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                TabContainer(title: "Search") {
                    SearchScene(dependencies: dependencies)
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
    let dependencies = AppDependencies(
        dictionaryRepository: MockDictionaryRepository()
    )
    
    RootView(dependencies: dependencies)
}
