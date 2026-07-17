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

    private static let wordSummaryBaseSQL: SQL = """
            SELECT
                w.id,
                w.term,
                w.reading,
                preview.part_of_speech AS previewPartOfSpeech,
                preview.definition_text AS previewMeaning
            FROM words AS w
            LEFT JOIN meanings AS preview
                ON preview.id = (
                    SELECT m.id
                    FROM meanings AS m
                    WHERE m.word_id = w.id
                    ORDER BY m.sequence, m.id
                    LIMIT 1
                )
        """

    func searchWords(query: String, limit: Int) async throws -> [WordSummary] {
        let pattern = "\(query)%"

        return try await dbQueue.read { db in
            let request: SQLRequest<WordSummaryRecord> = """
                \(Self.wordSummaryBaseSQL)
                WHERE
                    w.term LIKE \(pattern)
                    OR w.reading LIKE \(pattern)
                LIMIT \(limit)
                """

            return
                try request
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }

    func fetchWordDetail(wordID: Int64) async throws -> WordDetail? {
        try await dbQueue.read { db in
            let meanings = WordRecord.meanings
                .order(
                    MeaningRecord.Columns.sequence,
                    MeaningRecord.Columns.id
                )

            let request =
                WordRecord
                .filter(key: wordID)
                .including(all: meanings)
                .asRequest(of: WordDetailRecord.self)

            return try request
                .fetchOne(db)?
                .toDomain()
        }
    }

    func fetchWordSummaries(wordIDs: [Int64]) async throws -> [WordSummary] {
        guard !wordIDs.isEmpty else { return [] }

        var seenIDs = Set<Int64>()
        let uniqueWordIDs = wordIDs.filter {
            seenIDs.insert($0).inserted
        }

        return try await dbQueue.read { db in
            let request: SQLRequest<WordSummaryRecord> = """
                \(Self.wordSummaryBaseSQL)
                WHERE w.id IN \(uniqueWordIDs)
                """

            let records = try request.fetchAll(db)

            let summaryByID: [Int64: WordSummary] = Dictionary(
                uniqueKeysWithValues: records.map {
                    ($0.id, $0.toDomain())
                }
            )

            return wordIDs.compactMap { id in
                summaryByID[id]
            }
        }
    }
}

private struct WordSummaryRecord:
    Decodable,
    FetchableRecord
{
    let id: Int64
    let term: String
    let reading: String?
    let previewPartOfSpeech: String?
    let previewMeaning: String

    func toDomain() -> WordSummary {
        WordSummary(
            id: id,
            term: term,
            reading: reading,
            previewPartOfSpeech: previewPartOfSpeech,
            previewMeaning: previewMeaning
        )
    }
}

private struct WordDetailRecord:
    Decodable,
    FetchableRecord
{
    let word: WordRecord
    let meanings: [MeaningRecord]

    func toDomain() -> WordDetail {
        WordDetail(
            id: word.id,
            term: word.term,
            reading: word.reading,
            meanings: meanings.map { $0.toDomain() }
        )
    }
}
