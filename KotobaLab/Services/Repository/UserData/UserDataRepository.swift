//
//  UserDataRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/10.
//

import Foundation

protocol UserDataRepositoryProtocol {
    func isWordSaved(wordID: Int64) throws -> Bool
    func saveWord(wordID: Int64) throws
    func unsaveWord(wordID: Int64) throws
    func fetchSavedWordIDs() throws -> [Int64]
}
