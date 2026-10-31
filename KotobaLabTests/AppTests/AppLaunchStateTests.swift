//
//  AppLaunchStateTests.swift
//  KotobaLabTests
//
//  Created by shiinayane on 2026/10/30.
//

import Foundation
import Testing

@testable import KotobaLab

@MainActor struct AppLaunchStateTests {
    @Test func make_whenDatabaseCannotOpen_shouldFailWithoutCrashing() {
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("dictionary.sqlite")

        let state = AppLaunchState.make {
            try DatabaseManager(databaseURL: missingURL)
        }

        guard case .failed(let message) = state else {
            Issue.record("Expected failed state, got \(state)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test func make_whenDatabaseOpens_shouldBeReady() throws {
        let bundle = Bundle(for: TestBundleMarker.self)
        let fixtureURL = try #require(
            bundle.url(forResource: "test_dictionary", withExtension: "sqlite")
        )
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString + ".sqlite"
        )
        try FileManager.default.copyItem(at: fixtureURL, to: tempURL)

        let state = AppLaunchState.make {
            try DatabaseManager(databaseURL: tempURL)
        }

        guard case .ready = state else {
            Issue.record("Expected ready state, got \(state)")
            return
        }
    }
}

private final class TestBundleMarker {}
