//
//  AppGroupTests.swift
//  KotobaLabTests
//
//  Created by shiinayane on 2026/11/01.
//

import Foundation
import Testing

@testable import KotobaLab

struct AppGroupTests {
    @Test func dictionariesDirectory_shouldBeInTheSharedContainer() throws {
        let container = try #require(
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppGroup.identifier
            )
        )
        let directory = try #require(AppGroup.dictionariesDirectory)

        #expect(directory.path.hasPrefix(container.path))
        #expect(directory.lastPathComponent == "Dictionaries")
    }
}
