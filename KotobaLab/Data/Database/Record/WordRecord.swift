//
//  WordRecord.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/07/17.
//

import GRDB

struct WordRecord:
    Decodable,
    FetchableRecord,
    TableRecord
{
    static let databaseTableName = "words"

    let id: Int64
    let term: String
    let reading: String?
}

extension WordRecord {
    static let meanings = hasMany(MeaningRecord.self)
        .forKey("meanings")
}
