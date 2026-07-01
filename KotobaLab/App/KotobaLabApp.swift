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
    private let rootView: RootView

    init() {
        do {
            let databaseManager = try DatabaseManager()
            let dictionaryRepository = SQLiteDictionaryRepository(databaseManager: databaseManager)

            let dependencies = AppDependencies(
                dictionaryRepository: dictionaryRepository,
                userDataRepositoryFactory: UserDataRepositoryFactory { context in
                    SwiftDataUserDataRepository(context: context)
                }
            )

            self.rootView = RootView(
                dependencies: dependencies
            )
        } catch {
            fatalError("Failed to initialize app dependencies: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .modelContainer(for: [
                    SavedWordRecord.self
                ])
        }
    }
}
