//
//  DebugSearchRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

func debugSearchRepository() {
    do {
        let databaseManager = try DatabaseManager()
        let repository = SQLiteDictionaryRepository(dbQueue: databaseManager.dbQueue)
        
        let testQueries: [String] = ["食", "たべ", "しょ", "xyz_not_found"]
        
        for query in testQueries {
            let rusults = try repository.searchWords(query: query, limit: 5)
            
            print("\n=== Query: \(query) ===")
            print("count: \(rusults.count)")
            
            for item in rusults {
                print("\(item.term) | \(item.reading) | \(item.previewMeaning)")
            }
        }
    } catch {
        print("Repository debug failed:", error)
    }
}
