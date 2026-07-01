//
//  DictionaryModels.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

struct WordSummary: Identifiable, Hashable, Sendable {
    let id: Int64
    let term: String
    let reading: String?
    let previewPartOfSpeech: String?
    let previewMeaning: String

    var displayReading: String {
        reading ?? term
    }
}

struct WordDetail: Identifiable, Hashable, Sendable {
    let id: Int64
    let term: String
    let reading: String?
    let meanings: [Meaning]

    var displayReading: String {
        reading ?? term
    }
}

struct Meaning: Identifiable, Hashable, Sendable {
    let id: Int64
    let partOfSpeech: String?
    let definition: String
}

struct WordDetailDisplayData {
    let detail: WordDetail
    let isSaved: Bool
}
