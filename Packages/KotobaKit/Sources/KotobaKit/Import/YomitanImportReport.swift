//
//  YomitanImportReport.swift
//  KotobaKit
//

import Foundation

/// What an import wrote and how long each phase took.
public struct YomitanImportReport: Sendable {
    public struct Timings: Sendable {
        /// Parsing sampled banks and building the preset dictionary.
        public var presetDictionary: Duration = .zero
        /// Reading term banks out of the archive.
        public var readTermBanks: Duration = .zero
        /// `JSONSerialization` parsing of term banks.
        public var parseTermBanks: Duration = .zero
        /// Serializing glossaries and extracting previews.
        public var serializeGlossaries: Duration = .zero
        public var compressGlossaries: Duration = .zero
        public var insertEntries: Duration = .zero
        public var media: Duration = .zero
        public var indexes: Duration = .zero
        public var total: Duration = .zero
    }

    public let index: YomitanIndex
    public let entryCount: Int
    /// Rows that share sequence, term, and reading with an earlier row, told apart by ordinal.
    public let duplicateIdentityCount: Int
    public let tagCount: Int
    public let mediaCount: Int
    public let mediaBytes: Int
    /// Serialized glossary JSON before compression.
    public let glossaryBytes: Int
    public let compressedGlossaryBytes: Int
    public let presetDictionaryBytes: Int
    /// Rows of banks this importer does not read yet, keyed by bank kind, such as `kanji`.
    public let skippedRows: [String: Int]
    public let packBytes: Int
    public let timings: Timings
}

extension YomitanImportReport: CustomStringConvertible {
    /// A measurement summary, in 10^6-byte megabytes.
    public var description: String {
        func megabytes(_ bytes: Int) -> String {
            String(format: "%.1f MB", Double(bytes) / 1_000_000)
        }
        func seconds(_ duration: Duration) -> String {
            let components = duration.components
            let value = Double(components.seconds) + Double(components.attoseconds) / 1e18
            return String(format: "%.2f s", value)
        }
        let skipped = skippedRows.isEmpty ? "none" : "\(skippedRows)"
        return """
            dictionary          \(index.title) (\(index.revision))
            identity            \(index.stableIdentity)
            entries             \(entryCount), duplicate identities \(duplicateIdentityCount)
            tags                \(tagCount)
            media               \(mediaCount) files, \(megabytes(mediaBytes))
            skipped rows        \(skipped)
            glossary JSON       \(megabytes(glossaryBytes))
            glossary compressed \(megabytes(compressedGlossaryBytes)) \
            (preset \(presetDictionaryBytes) bytes)
            pack file           \(megabytes(packBytes))
            time total          \(seconds(timings.total))
              preset dictionary \(seconds(timings.presetDictionary))
              read banks        \(seconds(timings.readTermBanks))
              parse banks       \(seconds(timings.parseTermBanks))
              serialize         \(seconds(timings.serializeGlossaries))
              compress          \(seconds(timings.compressGlossaries))
              insert            \(seconds(timings.insertEntries))
              media             \(seconds(timings.media))
              indexes           \(seconds(timings.indexes))
            """
    }
}
