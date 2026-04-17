//
//  MockUserDataRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/13.
//

import Foundation

final class MockUserDataRepository: UserDataRepositoryProtocol {
    var savedWordsRecord: [MockSavedWordsRecord] = [
        MockSavedWordsRecord(
            wordID: 1,
            savedAt: Date.now.addingTimeInterval(100)
        ),
        MockSavedWordsRecord(
            wordID: 2,
            savedAt: Date.now
        ),
    ]
    
    func isWordSaved(wordID: Int64) throws -> Bool {
        return savedWordsRecord.contains {
            $0.wordID == wordID
        }
    }
    
    func saveWord(wordID: Int64) throws {
        guard try (!isWordSaved(wordID: wordID)) else { return }
        
        let record = MockSavedWordsRecord(
            wordID: wordID,
            savedAt: Date.now
        )
        savedWordsRecord.append(record)
    }
    
    func unsaveWord(wordID: Int64) throws {
        guard let index = savedWordsRecord.firstIndex(where: {
            $0.wordID == wordID
        }) else {
            return
        }
        savedWordsRecord.remove(at: index)
    }
    
    func fetchSavedWordIDs() throws -> [Int64] {
        return savedWordsRecord
            .sorted { $0.savedAt > $1.savedAt }
            .map { $0.wordID }
    }
}

struct MockSavedWordsRecord {
    let wordID: Int64
    let savedAt: Date
}
