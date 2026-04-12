//
//  MockDictionaryRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

final class MockDictionaryRepository: DictionaryRepositoryProtocol {
    let sampleWordSummary: [WordSummary] = [
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
    
    let sampleWordDetail: [Int64: WordDetail] = [
        1: WordDetail(
            id: 1,
            term: "食べる",
            reading: "たべる",
            meanings: [
                Meaning(id: 1, text: "to eat"),
                Meaning(id: 2, text: "to live on")
            ]
        ),
        2: WordDetail(
            id: 2,
            term: "食器",
            reading: "しょっき",
            meanings: [
                Meaning(id: 3, text: "tableware")
            ]
        )
    ]
    
    func searchWords(query: String, limit: Int) throws -> [WordSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return []
        }

        return sampleWordSummary
            .filter {
                $0.term.contains(trimmed) || $0.reading.contains(trimmed)
            }
            .prefix(limit)
            .map { $0 }
    }

    func fetchWordDetail(id: Int64) throws -> WordDetail? {
        return sampleWordDetail[id]
    }
    
    func fetchWordSummaries(ids: [Int64]) throws -> [WordSummary] {
        guard !ids.isEmpty else { return [] }
        
        let summaryByID: [Int64: WordSummary] = Dictionary(uniqueKeysWithValues: sampleWordSummary.map {
            ($0.id, $0)
        })
        
        let orderedSummaries: [WordSummary] = ids.compactMap {
            summaryByID[$0]
        }
        
        return orderedSummaries
    }
}
