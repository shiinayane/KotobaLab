//
//  DictionaryLibraryTests.swift
//  KotobaKitTests
//

import Foundation
import GRDB
import Synchronization
import Testing

@testable import KotobaKit

struct DictionaryLibraryTests {
    private static let fixtureID = "https://example.com/kotobakit-fixture/index.json"

    private func packFiles(in directory: URL) throws -> Set<String> {
        Set(
            try FileManager.default.contentsOfDirectory(atPath: directory.path)
                .filter { $0.hasSuffix(".sqlite") }
        )
    }

    // MARK: - Install and remove

    @Test func install_shouldListAndOpenTheDictionary() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        let library = try DictionaryLibrary(directory: fixture.libraryURL)

        let installed = try await library.install(archiveAt: fixture.archiveURL)

        #expect(installed.id == Self.fixtureID)
        #expect(await library.dictionaries().map(\.id) == [Self.fixtureID])
        let pack = try #require(await library.pack(for: Self.fixtureID))
        #expect(pack.info.importID == installed.info.importID)
        #expect(try await pack.entryCount() == 8)
        #expect(try packFiles(in: fixture.libraryURL) == [installed.packURL.lastPathComponent])
    }

    @Test func install_shouldKeepOtherDictionaries() async throws {
        let fixture = try FixtureArchive()
        let other = try FixtureArchive(replacing: [
            "index.json": #"{"title": "Other", "revision": "1", "format": 3}"#
        ])
        defer {
            fixture.remove()
            other.remove()
        }
        let library = try DictionaryLibrary(directory: fixture.libraryURL)

        _ = try await library.install(archiveAt: fixture.archiveURL)
        _ = try await library.install(archiveAt: other.archiveURL)

        #expect(await library.dictionaries().map(\.id) == [Self.fixtureID, "Other"])
        #expect(try packFiles(in: fixture.libraryURL).count == 2)
    }

    @Test func install_shouldReplaceThePackOfTheSameDictionary() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        let library = try DictionaryLibrary(directory: fixture.libraryURL)
        let first = try await library.install(archiveAt: fixture.archiveURL)

        let second = try await library.install(archiveAt: fixture.archiveURL)

        #expect(second.info.importID != first.info.importID)
        #expect(await library.pack(for: Self.fixtureID)?.info.importID == second.info.importID)
        #expect(try packFiles(in: fixture.libraryURL) == [second.packURL.lastPathComponent])
    }

    @Test func remove_shouldDeleteThePack() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        let library = try DictionaryLibrary(directory: fixture.libraryURL)
        _ = try await library.install(archiveAt: fixture.archiveURL)

        try await library.remove(dictionaryID: Self.fixtureID)

        #expect(await library.dictionaries().isEmpty)
        #expect(await library.pack(for: Self.fixtureID) == nil)
        #expect(try packFiles(in: fixture.libraryURL).isEmpty)
    }

    // MARK: - Failures

    @Test func cancelMidWrite_shouldKeepTheInstalledPack() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        let library = try DictionaryLibrary(directory: fixture.libraryURL)
        let installed = try await library.install(archiveAt: fixture.archiveURL)
        let reports = Mutex<[YomitanImportProgress]>([])

        // The fixture has two term banks: cancel after the first is written, so the importer
        // stops before the second.
        let task = Task {
            try await library.install(archiveAt: fixture.archiveURL) { progress in
                reports.withLock { $0.append(progress) }
                withUnsafeCurrentTask { $0?.cancel() }
            }
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(
            reports.withLock { $0 }
                == [YomitanImportProgress(completedTermBanks: 1, termBankCount: 2)]
        )
        #expect(await library.pack(for: Self.fixtureID)?.info.importID == installed.info.importID)
        #expect(
            try FileManager.default.contentsOfDirectory(atPath: fixture.libraryURL.path)
                == [installed.packURL.lastPathComponent]
        )
        #expect(try await library.pack(for: Self.fixtureID)?.entryCount() == 8)
    }

    @Test func failedImport_shouldKeepTheInstalledPack() async throws {
        let fixture = try FixtureArchive()
        let broken = try FixtureArchive(replacing: ["term_bank_2.json": "{"])
        defer {
            fixture.remove()
            broken.remove()
        }
        let library = try DictionaryLibrary(directory: fixture.libraryURL)
        let installed = try await library.install(archiveAt: fixture.archiveURL)

        await #expect(throws: YomitanImportError.malformedBank(path: "term_bank_2.json")) {
            try await library.install(archiveAt: broken.archiveURL)
        }
        #expect(await library.pack(for: Self.fixtureID)?.info.importID == installed.info.importID)
        #expect(
            try FileManager.default.contentsOfDirectory(atPath: fixture.libraryURL.path)
                == [installed.packURL.lastPathComponent]
        )
    }

    @Test func outOfSpaceErrors_shouldBeRecognized() {
        #expect(DictionaryLibrary.isOutOfSpace(DatabaseError(resultCode: .SQLITE_FULL)))
        #expect(DictionaryLibrary.isOutOfSpace(CocoaError(.fileWriteOutOfSpace)))
        #expect(DictionaryLibrary.isOutOfSpace(POSIXError(.ENOSPC)))
        #expect(!DictionaryLibrary.isOutOfSpace(DatabaseError(resultCode: .SQLITE_IOERR)))
        #expect(!DictionaryLibrary.isOutOfSpace(CancellationError()))
    }

    // MARK: - Opening

    @Test func open_shouldFinishAnInterruptedImport() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        let directory = fixture.libraryURL
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let leftover = directory.appendingPathComponent(".\(UUID().uuidString).importing")
        try Data("partial".utf8).write(to: leftover)

        let library = try DictionaryLibrary(directory: directory)

        #expect(await library.dictionaries().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: leftover.path))
    }

    @Test func open_shouldKeepTheNewestPackOfAnInterruptedReplacement() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        let directory = fixture.libraryURL
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let older = directory.appendingPathComponent("older.sqlite")
        let newer = directory.appendingPathComponent("newer.sqlite")
        _ = try YomitanImporter().importArchive(at: fixture.archiveURL, to: older)
        let newest = try YomitanImporter().importArchive(at: fixture.archiveURL, to: newer)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSinceNow: -60)],
            ofItemAtPath: older.path
        )

        let library = try DictionaryLibrary(directory: directory)

        #expect(await library.pack(for: Self.fixtureID)?.info.importID == newest.importID)
        #expect(try packFiles(in: directory) == ["newer.sqlite"])
    }

    @Test func open_shouldListButKeepPacksItCannotRead() async throws {
        let fixture = try FixtureArchive()
        defer { fixture.remove() }
        let directory = fixture.libraryURL
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let damaged = directory.appendingPathComponent("damaged.sqlite")
        try Data("not a database".utf8).write(to: damaged)

        let library = try DictionaryLibrary(directory: directory)

        #expect(await library.dictionaries().isEmpty)
        let unavailable = try #require(await library.unavailablePacks.first)
        #expect(unavailable.packURL.lastPathComponent == "damaged.sqlite")
        #expect(FileManager.default.fileExists(atPath: damaged.path))

        try await library.removeUnavailablePack(at: unavailable.packURL)

        #expect(await library.unavailablePacks.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: damaged.path))
    }
}
