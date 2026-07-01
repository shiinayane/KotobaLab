//
//  StudyView.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/03/27.
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
    TabContainer(title: "Study") {
        StudyView()
    }
    .environment(AppRouter())
}
