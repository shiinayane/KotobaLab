//
//  StudyView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct StudyView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("Study page")
            }
        }
    }
}

#Preview {
    AppTabContainer(title: "Study") {
        StudyView()
    }
    .environment(AppRouter())
}
