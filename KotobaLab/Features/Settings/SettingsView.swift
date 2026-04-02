//
//  SettingsView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/29.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    //  This also works.
    //  @Environment(AppRouter.self) private var router
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Setting page")
            }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                            //  router.dismissSheet()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                .toolbarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
