//
//  SwiftDataUserDataRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/10.
//

import Foundation
import SwiftData

final class SwiftDataUserDataRepository: UserDataRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func isWordSaved(wordID: Int64) throws -> Bool {
        var descriptor = FetchDescriptor<SavedWordRecord>(
            predicate: #Predicate { record in
                record.wordID == wordID
            }
        )
        
        descriptor.fetchLimit = 1
        
        let results = try context.fetch(descriptor)
        
        return !results.isEmpty
    }
    
    func saveWord(wordID: Int64) throws {
        guard !(try isWordSaved(wordID: wordID)) else { return }
        
        let record = SavedWordRecord(wordID: wordID)
        context.insert(record)
        try context.save()
    }
    
    func unsaveWord(wordID: Int64) throws {
        var descriptor = FetchDescriptor<SavedWordRecord>(
            predicate: #Predicate { record in
                record.wordID == wordID
            }
        )
        
        descriptor.fetchLimit = 1
        
        let results = try context.fetch(descriptor)
        
        guard let record = results.first else { return }

        context.delete(record)
        try context.save()
    }
    
    func fetchSavedWordIDs() throws -> [Int64] {
        var descriptor = FetchDescriptor<SavedWordRecord>(
            sortBy: [
                .init(\.savedAt, order: .reverse)
            ]
        )
        
        // Fetch 50 records at first.
        descriptor.fetchLimit = 50
        
        let results = try context.fetch(descriptor)
        
        return results.map {
            $0.wordID
        }
    }
}
