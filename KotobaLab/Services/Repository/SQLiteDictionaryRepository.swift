//
//  SQLiteDictionaryRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

final class SQLiteDictionaryRepository: DictionaryRepositoryProtocol {
    func searchWords(query: String, limit: Int) throws -> [WordSummary] {
        //  Execute SQL here
        return []
    }
    
    func fetchWordDetail(id: Int64) throws -> WordDetail? {
        //  Execute SQL here
        return nil
    }
}
