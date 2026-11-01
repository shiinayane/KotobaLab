//
//  DictionaryEntryKey.swift
//  KotobaKit
//

import Foundation

/// The identity of an entry within one dictionary, stable across re-imports of the same source.
///
/// `sequence` is 0 unless the dictionary declares `sequenced`. `ordinal` numbers rows that share
/// sequence, term, and reading, in source order. See `docs/dictionary.md#identity`.
///
/// Terms and readings compare by code point. `String` equality uses canonical equivalence, which
/// merges CJK compatibility ideographs with their unified forms, such as U+FA48 and U+716E for 煮;
/// Jitendex has separate entries for both. SQLite compares the same bytes this key does.
public struct DictionaryEntryKey: Hashable, Codable, Sendable {
    public let sequence: Int64
    public let term: String
    public let reading: String
    public let ordinal: Int

    public init(sequence: Int64, term: String, reading: String, ordinal: Int) {
        self.sequence = sequence
        self.term = term
        self.reading = reading
        self.ordinal = ordinal
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sequence == rhs.sequence
            && lhs.ordinal == rhs.ordinal
            && lhs.term.utf8.elementsEqual(rhs.term.utf8)
            && lhs.reading.utf8.elementsEqual(rhs.reading.utf8)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sequence)
        hasher.combine(ordinal)
        for byte in term.utf8 {
            hasher.combine(byte)
        }
        // 0xFF never occurs in UTF-8, so it separates term from reading unambiguously.
        hasher.combine(0xFF as UInt8)
        for byte in reading.utf8 {
            hasher.combine(byte)
        }
    }
}
