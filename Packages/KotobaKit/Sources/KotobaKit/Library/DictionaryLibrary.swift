//
//  DictionaryLibrary.swift
//  KotobaKit
//

import Foundation
import GRDB

/// A pack the library can read.
public struct InstalledDictionary: Identifiable, Sendable {
    public let packURL: URL
    public let info: DictionaryPackInfo

    public var id: String {
        info.dictionaryID
    }
}

/// A pack file the library cannot open, such as a damaged file or an unsupported format.
///
/// The library never deletes one on its own, because the source archive may be gone.
public struct UnavailablePack: Sendable {
    public let packURL: URL
    public let error: any Error
}

public enum DictionaryLibraryError: Error, Equatable {
    /// The device ran out of space while importing; the previous state is intact.
    case insufficientStorage
}

/// The installed dictionaries: one pack file per dictionary in one directory.
///
/// The directory is the registry. Each import writes a new file, named for no dictionary in
/// particular, and only then deletes the pack it replaces, so a file is never replaced in place.
/// Opening the library finishes what an interrupted import or replacement left behind, so only
/// one process may install into a directory, through one library.
///
/// After ``install(archiveAt:progress:)`` or ``remove(dictionaryID:)``, ask ``pack(for:)`` again:
/// a ``DictionaryPack`` whose file was deleted fails with an I/O error.
public actor DictionaryLibrary {
    public nonisolated let directory: URL
    private let importer: YomitanImporter
    private var installed: [String: Installed] = [:]
    public private(set) var unavailablePacks: [UnavailablePack] = []

    private struct Installed {
        let pack: DictionaryPack
        let url: URL
    }

    private static let packExtension = "sqlite"
    private static let temporaryExtension = "importing"

    /// Opens the library in `directory`, creating the directory if needed.
    ///
    /// Deletes files left by an interrupted import, and keeps only the newest pack when an
    /// interrupted replacement left two for one dictionary.
    public init(directory: URL, importer: YomitanImporter = YomitanImporter()) throws {
        self.directory = directory
        self.importer = importer
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        var candidates: [(pack: DictionaryPack, url: URL, modified: Date)] = []
        for url in try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) {
            switch url.pathExtension {
            case Self.temporaryExtension:
                try? fileManager.removeItem(at: url)
            case Self.packExtension:
                do {
                    let modified =
                        try url.resourceValues(forKeys: [.contentModificationDateKey])
                        .contentModificationDate ?? .distantPast
                    candidates.append((try DictionaryPack(url: url), url, modified))
                } catch {
                    unavailablePacks.append(UnavailablePack(packURL: url, error: error))
                }
            default:
                continue
            }
        }

        // Pack import times have one-second resolution; the file date breaks ties.
        candidates.sort {
            ($0.pack.info.importedAt, $0.modified) < ($1.pack.info.importedAt, $1.modified)
        }
        var superseded: [URL] = []
        for candidate in candidates {
            let id = candidate.pack.info.dictionaryID
            if let older = installed[id] {
                superseded.append(older.url)
            }
            installed[id] = Installed(pack: candidate.pack, url: candidate.url)
        }
        // Close the superseded packs before deleting them. A file that cannot be deleted now is
        // deleted the next time the library opens.
        candidates.removeAll()
        for url in superseded {
            try? fileManager.removeItem(at: url)
        }
    }

    /// The installed dictionaries, by title.
    public func dictionaries() -> [InstalledDictionary] {
        installed.values
            .map { InstalledDictionary(packURL: $0.url, info: $0.pack.info) }
            .sorted { ($0.info.index.title, $0.id) < ($1.info.index.title, $1.id) }
    }

    public func pack(for dictionaryID: String) -> DictionaryPack? {
        installed[dictionaryID]?.pack
    }

    /// Imports a Yomitan archive, replacing the installed pack of the same dictionary.
    ///
    /// The import runs off the library's actor, so the library stays readable meanwhile. A failed
    /// or cancelled import leaves the installed dictionaries as they were.
    public func install(
        archiveAt archiveURL: URL,
        progress: @Sendable (YomitanImportProgress) -> Void = { _ in }
    ) async throws -> InstalledDictionary {
        let packURL = directory.appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(Self.packExtension)
        try await Self.importPack(
            from: archiveURL,
            to: packURL,
            importer: importer,
            progress: progress
        )

        let pack: DictionaryPack
        do {
            pack = try DictionaryPack(url: packURL)
        } catch {
            try? FileManager.default.removeItem(at: packURL)
            throw error
        }
        let id = pack.info.dictionaryID
        let replaced = installed[id]
        installed[id] = Installed(pack: pack, url: packURL)
        if let replaced {
            // The new pack is installed; opening the library retries a failed deletion.
            try? FileManager.default.removeItem(at: replaced.url)
        }
        return InstalledDictionary(packURL: packURL, info: pack.info)
    }

    /// Deletes the pack of an installed dictionary; does nothing if none is installed.
    public func remove(dictionaryID: String) throws {
        guard let removed = installed.removeValue(forKey: dictionaryID) else {
            return
        }
        try FileManager.default.removeItem(at: removed.url)
    }

    /// Deletes a pack file the library could not open.
    public func removeUnavailablePack(at packURL: URL) throws {
        guard let position = unavailablePacks.firstIndex(where: { $0.packURL == packURL }) else {
            return
        }
        try FileManager.default.removeItem(at: packURL)
        unavailablePacks.remove(at: position)
    }

    @concurrent
    private static func importPack(
        from archiveURL: URL,
        to packURL: URL,
        importer: YomitanImporter,
        progress: @Sendable (YomitanImportProgress) -> Void
    ) async throws {
        do {
            _ = try importer.importArchive(at: archiveURL, to: packURL, progress: progress)
        } catch let error where isOutOfSpace(error) {
            throw DictionaryLibraryError.insufficientStorage
        }
    }

    static func isOutOfSpace(_ error: any Error) -> Bool {
        if let error = error as? DatabaseError {
            return error.resultCode == .SQLITE_FULL
        }
        if let error = error as? CocoaError {
            return error.code == .fileWriteOutOfSpace
        }
        let error = error as NSError
        return error.domain == NSPOSIXErrorDomain && error.code == Int(ENOSPC)
    }
}
