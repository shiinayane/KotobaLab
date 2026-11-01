//
//  YomitanIndexTests.swift
//  KotobaKitTests
//

import Foundation
import Testing

@testable import KotobaKit

struct YomitanIndexTests {
    private func decode(_ json: String) throws -> YomitanIndex {
        try JSONDecoder().decode(YomitanIndex.self, from: Data(json.utf8))
    }

    @Test func stableIdentity_shouldPreferIndexURLOverTheDatedTitle() throws {
        let index = try decode(
            """
            {"title": "Jitendex.org [2026-10-03]", "revision": "2026.10.03.0", "format": 3,
             "sequenced": true, "isUpdatable": true,
             "indexUrl": "https://jitendex.org/static/yomitan.json"}
            """
        )

        #expect(index.stableIdentity == "https://jitendex.org/static/yomitan.json")
        #expect(index.sequenced)
        #expect(index.isUpdatable)
    }

    @Test(arguments: [#""indexUrl": "","#, ""])
    func stableIdentity_shouldFallBackToTheTitle(indexURL: String) throws {
        let index = try decode(#"{\#(indexURL) "title": "辞書", "revision": "1", "format": 3}"#)

        #expect(index.stableIdentity == "辞書")
        #expect(!index.sequenced)
    }

    @Test func legacyVersionField_shouldBeReadAsFormat() throws {
        let index = try decode(#"{"title": "Old", "revision": "1", "version": 1}"#)

        #expect(index.format == 1)
    }
}
