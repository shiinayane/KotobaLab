//
//  LaunchFailureView.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/10/30.
//

import SwiftUI

/// Shown instead of the app when its dependencies cannot be composed.
struct LaunchFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Unable to Open Dictionary", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Reinstalling KotobaLab may fix this.")
        } actions: {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    LaunchFailureView(message: "databaseFileNotFound")
}
