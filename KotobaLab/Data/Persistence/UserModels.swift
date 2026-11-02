//
//  UserModels.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/04/02.
//

import Foundation
import KotobaKit
import SwiftData

@Model final class SavedWordRecord {
    @Attribute(.unique) var wordID: Int64
    var savedAt: Date

    init(wordID: Int64, savedAt: Date = .now) {
        self.wordID = wordID
        self.savedAt = savedAt
    }
}

/// A saved entry, stored as its dictionary ID and entry snapshot.
///
/// The key's fields are columns so that SQLite compares terms and readings by code point.
@Model final class SavedEntryRecord {
    #Unique<SavedEntryRecord>([\.dictionaryID, \.sequence, \.term, \.reading, \.ordinal])

    var dictionaryID: String
    var sequence: Int64
    var term: String
    var reading: String
    var ordinal: Int
    var glossaryFingerprint: String
    var savedAt: Date

    init(dictionaryID: String, snapshot: DictionaryEntrySnapshot, savedAt: Date = .now) {
        self.dictionaryID = dictionaryID
        sequence = snapshot.key.sequence
        term = snapshot.key.term
        reading = snapshot.key.reading
        ordinal = snapshot.key.ordinal
        glossaryFingerprint = snapshot.glossaryFingerprint
        self.savedAt = savedAt
    }

    var savedEntry: SavedEntry {
        SavedEntry(
            dictionaryID: dictionaryID,
            snapshot: DictionaryEntrySnapshot(
                key: DictionaryEntryKey(
                    sequence: sequence,
                    term: term,
                    reading: reading,
                    ordinal: ordinal
                ),
                glossaryFingerprint: glossaryFingerprint
            ),
            savedAt: savedAt
        )
    }
}
