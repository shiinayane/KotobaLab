//
//  DictionaryRepositoryProtocol.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

protocol DictionaryRepositoryProtocol {
    func searchWords(query: String, limit: Int) async throws -> [WordSummary]
    func fetchWordDetail(wordID: Int64) async throws -> WordDetail?
    func fetchWordSummaries(wordIDs: [Int64]) async throws -> [WordSummary]
}
