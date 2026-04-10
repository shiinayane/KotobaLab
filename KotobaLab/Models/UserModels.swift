//
//  UserModels.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation
import SwiftData

@Model
final class SavedWordRecord {
    @Attribute(.unique) var wordID: Int64
    var savedAt: Date

    init(wordID: Int64, savedAt: Date = .now) {
        self.wordID = wordID
        self.savedAt = savedAt
    }
}
