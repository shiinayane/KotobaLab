//
//  SavedMocks.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/05.
//

import Foundation

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
