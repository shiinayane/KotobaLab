//
//  SQLiteDictionaryRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation
import GRDB

final class SQLiteDictionaryRepository: DictionaryRepositoryProtocol {
    private let dbQueue: DatabaseQueue
    
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    func searchWords(query: String, limit: Int) throws -> [WordSummary] {
        let pattern = "\(query)%"
        
        return try dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                //  Simple Prefix Search
                sql: """
                    SELECT w.id, w.term, w.reading, m.definition_text
                    FROM words w
                    JOIN meanings m ON w.id = m.word_id
                    WHERE w.term LIKE ? OR w.reading LIKE ?
                    LIMIT ?
                    """,
                arguments: [pattern, pattern, limit]
            )
            
            return rows.map { row in
                WordSummary(
                    id: row["id"],
                    term: row["term"],
                    reading: row["reading"],
                    previewMeaning: row["definition_text"]
                )
            }
        }
    }
    
    func fetchWordDetail(id: Int64) throws -> WordDetail? {
        //  Execute SQL here
        fatalError("Not implemented yet")
    }
}
