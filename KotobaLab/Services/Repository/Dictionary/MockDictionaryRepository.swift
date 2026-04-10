//
//  MockDictionaryRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

final class MockDictionaryRepository: DictionaryRepositoryProtocol {
    func searchWords(query: String, limit: Int) throws -> [WordSummary] {
        let sample = [
            WordSummary(
                id: 1,
                term: "食べる",
                reading: "たべる",
                previewMeaning: "to eat"
            ),
            WordSummary(
                id: 2,
                term: "食器",
                reading: "しょっき",
                previewMeaning: "tableware"
            ),
            WordSummary(
                id: 3,
                term: "食欲",
                reading: "しょくよく",
                previewMeaning: "appetite"
            )
        ]

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return []
        }

        return sample
            .filter {
                $0.term.contains(trimmed) || $0.reading.contains(trimmed)
            }
            .prefix(limit)
            .map { $0 }
    }

    func fetchWordDetail(id: Int64) throws -> WordDetail? {
        switch id {
        case 1:
            return WordDetail(
                id: 1,
                term: "食べる",
                reading: "たべる",
                meanings: [
                    Meaning(id: 1, text: "to eat"),
                    Meaning(id: 2, text: "to live on")
                ]
            )
        case 2:
            return WordDetail(
                id: 2,
                term: "食器",
                reading: "しょっき",
                meanings: [
                    Meaning(id: 3, text: "tableware")
                ]
            )
        default:
            return nil
        }
    }
}
