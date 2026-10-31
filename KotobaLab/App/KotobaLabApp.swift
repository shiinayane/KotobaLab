//
//  KotobaLabApp.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/03/26.
//

import SwiftData
import SwiftUI

@main
struct KotobaLabApp: App {
    private let launchState = AppLaunchState.make {
        try DatabaseManager()
    }

    var body: some Scene {
        WindowGroup {
            switch launchState {
            case .ready(let dependencies):
                RootView(dependencies: dependencies)
                    .modelContainer(for: [
                        SavedWordRecord.self
                    ])
            case .failed(let message):
                LaunchFailureView(message: message)
            }
        }
    }
}
