//
//  KotobaLabApp.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/26.
//

import SwiftUI
import SwiftData

@main
struct KotobaLabApp: App {
    private let rootView: RootView
    
    init () {
        do {
            let databaseManager = try DatabaseManager()
            let dictionaryRepository = SQLiteDictionaryRepository(dbQueue: databaseManager.dbQueue)
            
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
