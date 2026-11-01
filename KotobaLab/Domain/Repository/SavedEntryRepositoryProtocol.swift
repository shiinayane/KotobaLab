//
//  SavedEntryRepositoryProtocol.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/11/01.
//

import KotobaKit

protocol SavedEntryRepositoryProtocol {
    func isSaved(dictionaryID: String, key: DictionaryEntryKey) throws -> Bool
    func save(dictionaryID: String, snapshot: DictionaryEntrySnapshot) throws
    func unsave(dictionaryID: String, key: DictionaryEntryKey) throws
    /// Every saved entry, newest first.
    func fetchSavedEntries() throws -> [SavedEntry]
}
