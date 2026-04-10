//
//  DictionaryModels.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

struct WordSummary: Identifiable, Hashable {
    let id: Int64
    let term: String
    let reading: String
    let previewMeaning: String
}

struct WordDetail: Identifiable, Hashable {
    let id: Int64
    let term: String
    let reading: String
    let meanings: [Meaning]
}

struct Meaning: Identifiable, Hashable {
    let id: Int64
    let text: String
}

struct SavedWordSummary: Identifiable, Hashable {
    let id: Int64
    let term: String
    let reading: String
    let previewMeaning: String
    let savedAt: Date
}
