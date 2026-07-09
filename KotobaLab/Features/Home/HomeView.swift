//
//  HomeView.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/03/27.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                recentSearchSection
                recentSavedSection
            }
            .padding(16)
        }
    }
}

private var recentSearchSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Recent Search")
    }
}

private var recentSavedSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Recent Saved")
    }
}

#Preview {
    TabContainer(title: "Home") {
        HomeView()
    }
    .environment(AppRouter())
}
