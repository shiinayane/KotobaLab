//
//  DictionaryRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

protocol DictionaryRepositoryProtocol {
    func searchWords(query: String, limit: Int) throws -> [WordSummary]
    func fetchWordDetail(wordID: Int64) throws -> WordDetail?
    func fetchWordSummaries(wordIDs: [Int64]) throws -> [WordSummary]
}
