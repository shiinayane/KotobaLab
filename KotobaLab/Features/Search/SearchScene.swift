//
//  SearchScene.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/14.
//

import SwiftUI

struct SearchScene: View {
    let dependencies: AppDependencies
    @State private var store: SearchStore
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        
        _store = State(
            initialValue: SearchStore(
                dictionaryRepository: dependencies.dictionaryRepository
            )
        )
    }
    
    var body: some View {
        return SearchView(
            dependencies: dependencies,
            store: store
        )
    }
}
