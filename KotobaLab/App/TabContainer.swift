//
//  TabContainer.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/29.
//

import SwiftUI

struct TabContainer<Content: View>: View {
    let title: String
    let content: () -> Content
    
    @Environment(AppRouter.self) private var router
    
    //  In order to support closure.
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            router.present(sheet: .settings)
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                        }
                        
                    }
                }
                .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}
