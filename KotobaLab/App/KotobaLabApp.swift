//
//  KotobaLabApp.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/26.
//

import SwiftUI

@main
struct KotobaLabApp: App {
    init () {
        debugSearchRepository()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
