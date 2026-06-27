//
//  LicenseView.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/06/27.
//

import SwiftUI

struct LicenseView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Form {
            dictionaryDataSection
            appSourceCodeSection
        }
        .navigationTitle("License")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.dismissSheet()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }

    private var dictionaryDataSection: some View {
        Section {
            LabeledContent("Source", value: "JMdict")
            Link("Provided via Jitendex", destination: Links.jitendex)
            Link("License: CC BY-SA 4.0", destination: Links.ccBYSA4)
        } header: {
            Text("Dictionary Data")
        } footer: {
            Text(
                """
                This app uses the JMdict dictionary files, which are the property of \
                the Electronic Dictionary Research and Development Group (EDRDG) and \
                are used in conformance with the Group's licence. The dictionary \
                database is a modified work of JMdict, obtained via Jitendex and \
                restructured into an SQLite database for this app. It is distributed \
                under the Creative Commons Attribution-ShareAlike 4.0 International \
                License (CC BY-SA 4.0).
                """
            )
        }
    }

    private var appSourceCodeSection: some View {
        Section {
            Link("Repository on Github", destination: Links.kotobaLab)
            NavigationLink("MIT License") {
                MITLicenseView()
            }
        } header: {
            Text("App Source Code")
        } footer: {
            Text("© 2026 Yankai Wang (@shiinayane). Licensed under the MIT License.")
        }
    }
}

private enum Links {
    static let jitendex = URL(string: "https://jitendex.org/")!
    static let ccBYSA4 = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!
    static let kotobaLab = URL(string: "https://github.com/shiinayane/KotobaLab/")!
}

#Preview {
    LicenseView()
        .environment(AppRouter())
}
