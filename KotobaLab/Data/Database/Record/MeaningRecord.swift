//
//  MeaningRecord.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/07/17.
//

import GRDB

struct MeaningRecord:
    Decodable,
    FetchableRecord,
    TableRecord
{
    static let databaseTableName = "meanings"

    let id: Int64
    let wordID: Int64
    let sequence: Int
    let partOfSpeech: String?
    let definition: String

    enum CodingKeys: String, CodingKey {
        case id
        case wordID = "word_id"
        case sequence
        case partOfSpeech = "part_of_speech"
        case definition = "definition_text"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sequence = Column(CodingKeys.sequence)
    }

    func toDomain() -> Meaning {
        Meaning(
            id: id,
            partOfSpeech: partOfSpeech,
            definition: definition
        )
    }
}
