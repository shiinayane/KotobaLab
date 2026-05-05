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
    let reading: String?
    let previewPartOfSpeech: String?
    let previewMeaning: String
    
    var displayName: String {
        reading ?? term
    }
}

struct WordDetail: Identifiable, Hashable {
    let id: Int64
    let term: String
    let reading: String?
    let meanings: [Meaning]
    
    var displayName: String {
        reading ?? term
    }
}

struct Meaning: Identifiable, Hashable {
    let id: Int64
    let partOfSpeech: String?
    let definition: String
}
