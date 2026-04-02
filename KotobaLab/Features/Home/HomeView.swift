//
//  HomeView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                RecentSearchSection
                RecentSavedSection
            }
            .padding(16)
        }
    }
}

private var RecentSearchSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Recent Search")
    }
}

private var RecentSavedSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Recent Saved")
    }
}

#Preview {
    AppTabContainer(title: "Home") {
        HomeView()
    }
    .environment(AppRouter())
}
