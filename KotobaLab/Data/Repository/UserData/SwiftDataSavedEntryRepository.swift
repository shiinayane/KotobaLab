//
//  SwiftDataSavedEntryRepository.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/11/01.
//

import Foundation
import KotobaKit
import SwiftData

@MainActor final class SwiftDataSavedEntryRepository: SavedEntryRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func isSaved(dictionaryID: String, key: DictionaryEntryKey) throws -> Bool {
        try record(dictionaryID: dictionaryID, key: key) != nil
    }

    func save(dictionaryID: String, snapshot: DictionaryEntrySnapshot) throws {
        guard try record(dictionaryID: dictionaryID, key: snapshot.key) == nil else { return }

        context.insert(SavedEntryRecord(dictionaryID: dictionaryID, snapshot: snapshot))
        try context.save()
    }

    func unsave(dictionaryID: String, key: DictionaryEntryKey) throws {
        guard let record = try record(dictionaryID: dictionaryID, key: key) else { return }

        context.delete(record)
        try context.save()
    }

    func fetchSavedEntries() throws -> [SavedEntry] {
        let descriptor = FetchDescriptor<SavedEntryRecord>(
            sortBy: [
                .init(\.savedAt, order: .reverse)
            ]
        )

        return try context.fetch(descriptor).map(\.savedEntry)
    }

    private func record(dictionaryID: String, key: DictionaryEntryKey) throws -> SavedEntryRecord? {
        let sequence = key.sequence
        let term = key.term
        let reading = key.reading
        let ordinal = key.ordinal
        var descriptor = FetchDescriptor<SavedEntryRecord>(
            predicate: #Predicate { record in
                record.dictionaryID == dictionaryID && record.sequence == sequence
                    && record.term == term && record.reading == reading
                    && record.ordinal == ordinal
            }
        )

        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }
}
