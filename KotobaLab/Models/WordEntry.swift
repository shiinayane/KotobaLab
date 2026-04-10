//
//  WordEntry.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/28.
//

import Foundation

struct WordEntry: Identifiable, Codable, Hashable {
    let id: Int64
    let term: String
    let reading: String
    let meanings: [String]
    let partOfSpeech: String
    let examples: [String]?
}
