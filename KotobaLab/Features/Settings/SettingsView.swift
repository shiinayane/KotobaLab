//
//  SettingsView.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/03/29.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack {
            Form {
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
