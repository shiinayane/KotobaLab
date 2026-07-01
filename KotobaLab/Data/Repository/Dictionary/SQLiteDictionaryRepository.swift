//
//  SQLiteDictionaryRepository.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/04/02.
//

import Foundation
import GRDB

final class SQLiteDictionaryRepository: DictionaryRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    convenience init(databaseManager: DatabaseManager) {
        self.init(dbQueue: databaseManager.dbQueue)
    }

    func searchWords(query: String, limit: Int) async throws -> [WordSummary] {
        let pattern = "\(query)%"

        return try await dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                //  Simple Prefix Search
                sql: """
                    SELECT
                        w.id,
                        w.term,
                        w.reading,
                        (
                            SELECT m.part_of_speech
                            FROM meanings m
                            WHERE m.word_id = w.id
                            ORDER BY m.sequence
                            LIMIT 1
                        ) AS preview_pos,
                        (
                            SELECT m.definition_text
                            FROM meanings m
                            WHERE m.word_id = w.id
                            ORDER BY m.sequence
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
                    previewPartOfSpeech: row["preview_pos"],
                    previewMeaning: row["preview_meaning"]
                )
            }
        }
    }

    func fetchWordDetail(wordID: Int64) async throws -> WordDetail? {
        try await dbQueue.read { db -> WordDetail? in
            guard
                let word = try Row.fetchOne(
                    db,
                    sql: """
                        SELECT id, term, reading
                        FROM words
                        WHERE id = ?
                        LIMIT 1
                        """,
                    arguments: [wordID]
                )
            else {
                return nil
            }

            let meaningRows = try Row.fetchAll(
                db,
                sql: """
                    SELECT id, part_of_speech, definition_text
                    FROM meanings
                    WHERE word_id = ?
                    ORDER BY id
                    """,
                arguments: [wordID]
            )

            return WordDetail(
                id: word["id"],
                term: word["term"],
                reading: word["reading"],
                meanings: meaningRows.map { row in
                    Meaning(
                        id: row["id"],
                        partOfSpeech: row["part_of_speech"],
                        definition: row["definition_text"]
                    )
                }
            )
        }
    }

    func fetchWordSummaries(wordIDs: [Int64]) async throws -> [WordSummary] {
        guard !wordIDs.isEmpty else { return [] }

        return try await dbQueue.read { db in
            let placeholders: String = Array(repeating: "?", count: wordIDs.count).joined(
                separator: ", "
            )

            let rows = try Row.fetchAll(
                db,
                sql: """
                    SELECT
                        w.id,
                        w.term,
                        w.reading,
                        (
                            SELECT m.part_of_speech
                            FROM meanings m
                            WHERE m.word_id = w.id
                            ORDER BY m.sequence
                            LIMIT 1
                        ) AS preview_pos,
                        (
                            SELECT m.definition_text
                            FROM meanings m
                            WHERE m.word_id = w.id
                            ORDER BY m.sequence
                            LIMIT 1
                        ) AS preview_meaning
                    FROM words w
                    WHERE w.id IN (\(placeholders))
                    """,
                arguments: StatementArguments(wordIDs)
            )

            let summaries = rows.map { row in
                WordSummary(
                    id: row["id"],
                    term: row["term"],
                    reading: row["reading"],
                    previewPartOfSpeech: row["preview_pos"],
                    previewMeaning: row["preview_meaning"]
                )
            }

            let summaryByID: [Int64: WordSummary] = Dictionary(
                uniqueKeysWithValues: summaries.map {
                    ($0.id, $0)
                }
            )

            let orderedSummaries: [WordSummary] = wordIDs.compactMap { id in
                summaryByID[id]
            }

            return orderedSummaries
        }
    }
}
