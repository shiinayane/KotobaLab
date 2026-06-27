//
//  SettingsView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/29.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                settingsSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.dismissSheet()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            NavigationLink {
                EmptyView()
            } label: {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            NavigationLink {
                LicenseView()
            } label: {
                Text("License")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppRouter())
}
