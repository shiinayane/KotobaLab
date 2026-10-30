//
//  AppLaunchState.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/10/30.
//

import SwiftData

/// The outcome of composing the app's dependencies at launch.
enum AppLaunchState {
    case ready(AppDependencies)
    case failed(message: String)

    @MainActor static func make(openDatabase: () throws -> DatabaseManager) -> AppLaunchState {
        do {
            let databaseManager = try openDatabase()
            let dictionaryRepository = SQLiteDictionaryRepository(databaseManager: databaseManager)

            return .ready(
                AppDependencies(
                    dictionaryRepository: dictionaryRepository,
                    userDataRepositoryFactory: UserDataRepositoryFactory { context in
                        SwiftDataUserDataRepository(context: context)
                    }
                )
            )
        } catch {
            return .failed(message: String(describing: error))
        }
    }
}
