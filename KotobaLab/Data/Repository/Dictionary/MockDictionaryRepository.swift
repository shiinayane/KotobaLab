//
//  MockDictionaryRepository.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/04/02.
//

import Foundation

final class MockDictionaryRepository: DictionaryRepositoryProtocol, Sendable {
    private let mockWordSummaries: [WordSummary]
    private let mockWordDetails: [WordDetail]

    init(
        mockWordSummary: [WordSummary] = PreviewData.wordSummaries,
        mockWordDetail: [WordDetail] = PreviewData.wordDetails
    ) {
        self.mockWordSummaries = mockWordSummary
        self.mockWordDetails = mockWordDetail
    }

    func searchWords(query: String, limit: Int) async throws -> [WordSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return []
        }

        return
            mockWordSummaries
            .filter {
                $0.term.contains(trimmed) || $0.displayReading.contains(trimmed)
            }
            .prefix(limit)
            .map { $0 }
    }

    func fetchWordDetail(wordID: Int64) async throws -> WordDetail? {
        mockWordDetails.first(where: { $0.id == wordID })
    }

    func fetchWordSummaries(wordIDs: [Int64]) async throws -> [WordSummary] {
        guard !wordIDs.isEmpty else { return [] }

        let summaryByID: [Int64: WordSummary] = Dictionary(
            uniqueKeysWithValues: mockWordSummaries.map {
                ($0.id, $0)
            }
        )

        let orderedSummaries: [WordSummary] = wordIDs.compactMap {
            summaryByID[$0]
        }

        return orderedSummaries
    }
}
