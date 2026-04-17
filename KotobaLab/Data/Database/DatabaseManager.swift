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
    
    init() throws {
        let dbURL = try Self.prepareDatabaseFile(named: "dictionary_app.sqlite")
        dbQueue = try DatabaseQueue(path: dbURL.path)
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
            guard let bundleURL = Bundle.main.url(forResource: "dictionary_app", withExtension: "sqlite") else {
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
