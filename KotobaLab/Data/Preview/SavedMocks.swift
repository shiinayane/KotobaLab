//
//  SavedMocks.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/05/05.
//

import Foundation

/// A plain copy of `SavedWordRecord` for previews and tests.
struct SavedWordRecordData {
    let wordID: Int64
    let savedAt: Date
}

extension SavedWordRecordData {
    static let sample = SavedWordRecordData(
        wordID: 1,
        savedAt: Date.now.addingTimeInterval(100)
    )

    static let list: [SavedWordRecordData] = [
        .sample,
        SavedWordRecordData(
            wordID: 2,
            savedAt: Date.now
        )
    ]
}
