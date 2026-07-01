//
//  UserDataRepositoryProtocol.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/04/10.
//

protocol UserDataRepositoryProtocol {
    func isWordSaved(wordID: Int64) throws -> Bool
    func saveWord(wordID: Int64) throws
    func unsaveWord(wordID: Int64) throws
    func fetchSavedWordIDs() throws -> [Int64]
}
