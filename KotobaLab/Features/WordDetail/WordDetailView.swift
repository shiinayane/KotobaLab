//
//  WordDetailView.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/27.
//

import SwiftUI

struct WordDetailView: View {
    let word: WordEntry
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                meaningSection
            }
            .padding(16)
        }
        .navigationTitle(word.term)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word.term)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(word.reading)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
    
    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meaning")
                .font(.headline)
            
            ForEach(word.meanings, id: \.self) { meaning in
                Text(meaning)
            }
        }
    }
}

#Preview {
    let mockWord = WordEntry (
        id: "1",
        term: "食べる",
        reading: "たべる",
        meanings: ["to eat"],
        partOfSpeech: "verb",
        examples: ["私はりんごを食べる。"]
      )
    
    NavigationStack {
        WordDetailView(word: mockWord)
    }
}
