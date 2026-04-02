//
//  RootView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                AppTabContainer(title: "Home") {
                    HomeView()
                }
            }
            Tab("Analysis", systemImage: "translate") {
                AppTabContainer(title: "Analysis") {
                    AnalysisView()
                }
            }
            Tab("Study", systemImage: "character.book.closed.ja") {
                AppTabContainer(title: "Study") {
                    StudyView()
                }
            }
            Tab("Saved", systemImage: "bookmark") {
                AppTabContainer(title: "Saved") {
                    SavedView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                AppTabContainer(title: "Search") {
                    SearchView()
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
    RootView()
}
