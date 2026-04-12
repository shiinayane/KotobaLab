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
                    SELECT
                        w.id,
                        w.term,
                        w.reading,
                        (
                            SELECT m.definition_text
                            FROM meanings m
                            WHERE m.word_id = w.id
                            ORDER BY m.id
                            LIMIT 1
                        ) AS preview_meaning
                    FROM words w
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
                    previewMeaning: row["preview_meaning"]
                )
            }
        }
    }
    
    func fetchWordDetail(id: Int64) throws -> WordDetail? {
        try dbQueue.read { db in
            guard let word = try Row.fetchOne(
                db,
                sql: """
                    SELECT id, term, reading
                    FROM words
                    WHERE id = ?
                    LIMIT 1
                    """,
                arguments: [id]
            ) else {
                return nil
            }
            
            let meaningRows = try Row.fetchAll(
                db,
                sql: """
                    SELECT id, definition_text
                    FROM meanings
                    WHERE word_id = ?
                    ORDER BY id
                    """,
                arguments: [id]
            )
            
            return WordDetail(
                id: word["id"],
                term: word["term"],
                reading: word["reading"],
                meanings: meaningRows.map { row in
                    Meaning(
                        id: row["id"],
                        text: row["definition_text"]
                    )
                }
            )
        }
    }
    
    func fetchWordSummaries(ids: [Int64]) throws -> [WordSummary] {
        guard !ids.isEmpty else { return [] }
        
        return try dbQueue.read { db in
            
            let placeholders: String = Array(repeating: "?", count: ids.count).joined(separator: ", ")
            
            let rows = try Row.fetchAll(
                db,
                sql: """
                    SELECT
                        w.id,
                        w.term,
                        w.reading,
                        (
                            SELECT m.definition_text
                            FROM meanings m
                            WHERE m.word_id = w.id
                            ORDER BY m.id
                            LIMIT 1
                        ) AS preview_meaning
                    FROM words w
                    WHERE w.id IN (\(placeholders))
                    """,
                arguments: StatementArguments(ids)
            )
            
            let summaries: [WordSummary] = rows.map { row in
                WordSummary(
                    id: row["id"],
                    term: row["term"],
                    reading: row["reading"],
                    previewMeaning: row["preview_meaning"]
                )
            }
            
            let summaryByID: [Int64: WordSummary] = Dictionary(uniqueKeysWithValues: summaries.map {
                ($0.id, $0)
            })
            
            let orderedSummaries: [WordSummary] = ids.compactMap { id in
                summaryByID[id]
            }
            
            return orderedSummaries
        }
    }
}
