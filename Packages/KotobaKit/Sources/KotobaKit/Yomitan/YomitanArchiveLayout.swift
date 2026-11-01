//
//  YomitanArchiveLayout.swift
//  KotobaKit
//

import Foundation

/// Classifies the files of a Yomitan archive by name.
struct YomitanArchiveLayout {
    enum BankKind: String, CaseIterable {
        case term
        case termMeta = "term_meta"
        case kanji
        case kanjiMeta = "kanji_meta"
        case tag
    }

    struct Bank {
        let kind: BankKind
        let number: Int
        let path: String
    }

    static let indexPath = "index.json"
    static let stylesPath = "styles.css"

    private(set) var banks: [BankKind: [Bank]] = [:]
    /// Every other file, such as images, which glossary entries reference by path.
    private(set) var mediaPaths: [String] = []

    init(paths: some Sequence<String>) {
        for path in paths {
            if path == Self.indexPath || path == Self.stylesPath || Self.isJunk(path) {
                continue
            }
            if let bank = Self.bank(at: path) {
                banks[bank.kind, default: []].append(bank)
            } else {
                mediaPaths.append(path)
            }
        }
        for kind in banks.keys {
            banks[kind]?.sort { $0.number < $1.number }
        }
        mediaPaths.sort()
    }

    func banks(of kind: BankKind) -> [Bank] {
        banks[kind] ?? []
    }

    /// Matches `<kind>_bank_<number>.json` at the archive root.
    private static func bank(at path: String) -> Bank? {
        guard !path.contains("/"), path.hasSuffix(".json") else {
            return nil
        }
        let stem = path.dropLast(".json".count)
        guard let separator = stem.range(of: "_bank_", options: .backwards),
            let number = Int(stem[separator.upperBound...]),
            let kind = BankKind(rawValue: String(stem[..<separator.lowerBound]))
        else {
            return nil
        }
        return Bank(kind: kind, number: number, path: path)
    }

    /// Files that archivers add and no dictionary references.
    private static func isJunk(_ path: String) -> Bool {
        path.hasPrefix("__MACOSX/") || path.split(separator: "/").last == ".DS_Store"
    }
}
