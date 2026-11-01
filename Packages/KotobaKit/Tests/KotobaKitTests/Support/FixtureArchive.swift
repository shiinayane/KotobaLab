//
//  FixtureArchive.swift
//  KotobaKitTests
//

import Foundation
import Testing
import ZIPFoundation

/// Zips the handwritten fixture dictionary into a fresh temporary directory.
struct FixtureArchive {
    let directory: URL
    let archiveURL: URL

    var packURL: URL {
        directory.appendingPathComponent("pack.sqlite")
    }

    /// A directory for a ``DictionaryLibrary``, not created yet.
    var libraryURL: URL {
        directory.appendingPathComponent("library")
    }

    /// Writes `files`, keyed by archive path, over the fixture before zipping it.
    init(replacing files: [String: String] = [:], removing removed: [String] = []) throws {
        let fileManager = FileManager.default
        directory = fileManager.temporaryDirectory
            .appendingPathComponent("KotobaKitTests-\(UUID().uuidString)")
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let source = try #require(
            Bundle.module.url(
                forResource: "MiniDictionary",
                withExtension: nil,
                subdirectory: "Fixtures"
            )
        )
        let content = directory.appendingPathComponent("content")
        try fileManager.copyItem(at: source, to: content)
        for (path, text) in files {
            try Data(text.utf8).write(to: content.appendingPathComponent(path))
        }
        for path in removed {
            try fileManager.removeItem(at: content.appendingPathComponent(path))
        }

        archiveURL = directory.appendingPathComponent("dictionary.zip")
        try fileManager.zipItem(at: content, to: archiveURL, shouldKeepParent: false)
    }

    /// Files in the directory other than the archive, its source, and the pack.
    func strayFiles() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { !["content", "dictionary.zip", "pack.sqlite", "library"].contains($0) }
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}
