//
//  SearchWordsUseCase.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/04/17.
//

import Foundation

struct SearchWordsUseCase {
    private let dictionaryRepository: any DictionaryRepositoryProtocol

    init(dictionaryRepository: any DictionaryRepositoryProtocol) {
        self.dictionaryRepository = dictionaryRepository
    }

    func execute(query: String) async throws -> [WordSummary] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !q.isEmpty else {
            return []
        }

        return try await dictionaryRepository.searchWords(query: q, limit: 20)
    }
}
