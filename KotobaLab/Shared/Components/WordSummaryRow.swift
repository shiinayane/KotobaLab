//
//  WordSummaryRow.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/05.
//

import SwiftUI

struct WordSummaryRow: View {
    let word: WordSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(word.term)
                    .font(.headline)

                if !word.displayName.isEmpty {
                    Text("「\(word.displayName)」")
                        .font(.subheadline)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                if let previewPartOfSpeech = word.previewPartOfSpeech {
                    Text("[\(previewPartOfSpeech)]")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(word.previewMeaning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let mockWordSummaries = PreviewData.wordSummaries

    List(mockWordSummaries) { word in
        WordSummaryRow(word: word)
    }
}
