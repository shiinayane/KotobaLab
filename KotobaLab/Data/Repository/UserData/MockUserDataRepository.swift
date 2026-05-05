//
//  MockUserDataRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/13.
//

import Foundation

final class MockUserDataRepository: UserDataRepositoryProtocol {
    private var mockRecords: [SavedWordRecordData]
    
    init(savedWordsRecord: [SavedWordRecordData] = PreviewData.savedWordRecords) {
        self.mockRecords = savedWordsRecord
    }
    
    func isWordSaved(wordID: Int64) throws -> Bool {
        return mockRecords.contains {
            $0.wordID == wordID
        }
    }
    
    func saveWord(wordID: Int64) throws {
        guard try (!isWordSaved(wordID: wordID)) else { return }
        
        let record = SavedWordRecordData(
            wordID: wordID,
            savedAt: Date.now
        )
        mockRecords.append(record)
    }
    
    func unsaveWord(wordID: Int64) throws {
        guard let index = mockRecords.firstIndex(where: {
            $0.wordID == wordID
        }) else {
            return
        }
        mockRecords.remove(at: index)
    }
    
    func fetchSavedWordIDs() throws -> [Int64] {
        return mockRecords
            .sorted { $0.savedAt > $1.savedAt }
            .map { $0.wordID }
    }
}
