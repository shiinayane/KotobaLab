//
//  DictionaryEntry.swift
//  KotobaKit
//

import CryptoKit
import Foundation

/// A row of one imported pack, valid only for that import.
///
/// Row IDs change whenever a dictionary is re-imported, so a reference carries the import it came
/// from and ``DictionaryPack/entry(_:)`` rejects references from another import. Persist a
/// ``DictionaryEntrySnapshot`` instead.
public struct DictionaryEntryReference: Hashable, Codable, Sendable {
    public let importID: UUID
    public let rowID: Int64

    public init(importID: UUID, rowID: Int64) {
        self.importID = importID
        self.rowID = rowID
    }
}

public struct DictionaryEntry: Identifiable, Sendable {
    public let reference: DictionaryEntryReference
    public let key: DictionaryEntryKey
    public let definitionTags: [String]
    /// Yomitan deinflection rule identifiers, such as `v1` or `v5`.
    public let rules: [String]
    public let score: Int
    public let termTags: [String]
    /// The glossary as a Yomitan JSON array, serialized with sorted keys.
    public let glossaryJSON: Data

    public var id: DictionaryEntryReference {
        reference
    }

    /// What a saved entry stores to find this entry again after the dictionary is re-imported.
    public var snapshot: DictionaryEntrySnapshot {
        DictionaryEntrySnapshot(
            key: key,
            glossaryFingerprint: Self.fingerprint(of: glossaryJSON)
        )
    }

    /// Lowercase hex SHA-256 of the serialized glossary.
    static func fingerprint(of glossary: Data) -> String {
        SHA256.hash(data: glossary).map { String(format: "%02x", $0) }.joined()
    }
}

/// The stored identity of an entry, plus enough to tell apart rows that only differ by ordinal.
///
/// The fingerprint only chooses among rows that share sequence, term, and reading. Glossaries
/// change with ordinary updates, so a different fingerprint alone does not mean a different entry.
public struct DictionaryEntrySnapshot: Hashable, Codable, Sendable {
    public let key: DictionaryEntryKey
    public let glossaryFingerprint: String

    public init(key: DictionaryEntryKey, glossaryFingerprint: String) {
        self.key = key
        self.glossaryFingerprint = glossaryFingerprint
    }
}

public enum DictionaryEntryResolution: Sendable {
    case found(DictionaryEntry)
    /// The entry no longer exists; candidates share its sequence first, then its term and reading.
    case changed(candidates: [DictionaryEntry])
}

public struct DictionaryTag: Equatable, Sendable {
    public let name: String
    public let category: String
    public let order: Int
    public let notes: String
    public let score: Int
}
