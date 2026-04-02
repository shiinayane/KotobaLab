//
//  KotobaLabApp.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/26.
//

import SwiftUI

@main
struct KotobaLabApp: App {
    private let rootView: RootView
    
    init () {
        //  For debug
        //  debugSearchRepository()
        do {
            let databaseManager = try DatabaseManager()
            let repository = SQLiteDictionaryRepository(dbQueue: databaseManager.dbQueue)
            
            let searchStore = SearchStore(repository: repository)
            
            self.rootView = RootView(
                searchStore: searchStore
            )
        } catch {
            fatalError("Failed to initialize app dependencies: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            rootView
        }
    }
}
