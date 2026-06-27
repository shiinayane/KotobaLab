//
//  MITLicenseView.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/06/27.
//

import SwiftUI

struct MITLicenseView: View {
    @Environment(AppRouter.self) private var router

    static let text = """
        MIT License

        Copyright (c) 2026 Yankai Wang (@shiinayane)

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.

        ---

        Note on the dictionary database asset

        This MIT License covers the source code in this repository.

        The `dictionary.sqlite` artifact distributed via GitHub Releases is a
        derivative work of JMdict (Electronic Dictionary Research and Development
        Group) via jitendex-yomitan, and is licensed separately under the
        Creative Commons Attribution-ShareAlike 4.0 International License
        (CC BY-SA 4.0). The MIT license granted on the source code does not
        waive the attribution and share-alike requirements that CC BY-SA 4.0
        imposes on the dictionary asset.
        """

    var body: some View {
        ScrollView {
            Text(Self.text)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .navigationTitle("MIT License")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.dismissSheet()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

#Preview {
    MITLicenseView()
        .environment(AppRouter())
}
