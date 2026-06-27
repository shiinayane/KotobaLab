//
//  DatabaseManager.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation
import GRDB

final class DatabaseManager {
    let dbQueue: DatabaseQueue

    init(databaseName: String = "dictionary.sqlite") throws {
        let dbURL = try Self.prepareDatabaseFile(named: databaseName)
        dbQueue = try DatabaseQueue(path: dbURL.path)

        try Self.configure(dbQueue)
    }

    init(databaseURL: URL) throws {
        dbQueue = try DatabaseQueue(path: databaseURL.path)

        try Self.configure(dbQueue)
    }

    private static func configure(_ dbQueue: DatabaseQueue) throws {
        try dbQueue.inDatabase { db in
            // Enable SQLite LIKE prefix index optimization.
            // Required for efficient `LIKE 'prefix%'` searches on words.term / reading.
            try db.execute(sql: "PRAGMA case_sensitive_like = ON")
        }
    }

    private static func prepareDatabaseFile(named fileName: String) throws -> URL {
        let fileManager = FileManager.default

        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let destinationURL = appSupportURL.appendingPathComponent(fileName)

        if !fileManager.fileExists(atPath: destinationURL.path) {
            guard
                let bundleURL = Bundle.main.url(forResource: "dictionary", withExtension: "sqlite")
            else {
                throw DatabaseError.databaseFileNotFound
            }

            try fileManager.copyItem(at: bundleURL, to: destinationURL)
        }

        return destinationURL
    }
}

enum DatabaseError: Error {
    case databaseFileNotFound
}
