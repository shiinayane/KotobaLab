//
//  YomitanIndex.swift
//  KotobaKit
//

import Foundation

/// The fields of a Yomitan `index.json` that import depends on.
///
/// The whole file is also stored verbatim in the pack, so fields read later, such as the
/// description, need no schema change.
public struct YomitanIndex: Decodable, Equatable, Sendable {
    public let title: String
    public let revision: String
    public let format: Int
    public let sequenced: Bool
    public let author: String?
    public let attribution: String?
    public let isUpdatable: Bool
    public let indexUrl: String?
    public let downloadUrl: String?

    /// The identity that stays the same across updates of one dictionary.
    ///
    /// Titles of updatable dictionaries often carry a date, such as "Jitendex.org [2026-03-05]",
    /// while `indexUrl` is where updates are checked and does not change.
    public var stableIdentity: String {
        if let indexUrl, !indexUrl.isEmpty {
            return indexUrl
        }
        return title
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case revision
        case format
        case version
        case sequenced
        case author
        case attribution
        case isUpdatable
        case indexUrl
        case downloadUrl
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        revision = try container.decode(String.self, forKey: .revision)
        // Format 1 and 2 dictionaries name the field `version`.
        if let format = try container.decodeIfPresent(Int.self, forKey: .format) {
            self.format = format
        } else {
            format = try container.decode(Int.self, forKey: .version)
        }
        sequenced = try container.decodeIfPresent(Bool.self, forKey: .sequenced) ?? false
        author = try container.decodeIfPresent(String.self, forKey: .author)
        attribution = try container.decodeIfPresent(String.self, forKey: .attribution)
        isUpdatable = try container.decodeIfPresent(Bool.self, forKey: .isUpdatable) ?? false
        indexUrl = try container.decodeIfPresent(String.self, forKey: .indexUrl)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
    }
}
