//
//  YomitanTermRow.swift
//  KotobaKit
//

import Foundation

/// One row of a Yomitan format 3 term bank:
/// `[term, reading, definitionTags, rules, score, glossary, sequence, termTags]`.
struct YomitanTermRow {
    let term: String
    let reading: String
    let definitionTags: String
    let rules: String
    let score: Int
    /// The parsed glossary array, kept as Foundation JSON objects for serialization.
    let glossary: [Any]
    let sequence: Int
    let termTags: String

    /// Parses a row from `JSONSerialization` output, or returns `nil` if it is malformed.
    init?(json: Any) {
        guard
            let fields = json as? [Any],
            fields.count >= 8,
            let term = fields[0] as? String,
            let reading = fields[1] as? String,
            let rules = fields[3] as? String,
            let score = fields[4] as? NSNumber,
            let glossary = fields[5] as? [Any],
            let sequence = fields[6] as? NSNumber,
            let termTags = fields[7] as? String
        else {
            return nil
        }
        self.term = term
        // An empty reading means the term is its own reading.
        self.reading = reading.isEmpty ? term : reading
        // Definition tags may be null in format 3.
        definitionTags = fields[2] as? String ?? ""
        self.rules = rules
        self.score = score.intValue
        self.glossary = glossary
        self.sequence = sequence.intValue
        self.termTags = termTags
    }
}

/// One row of a Yomitan tag bank: `[name, category, order, notes, score]`.
struct YomitanTagRow {
    let name: String
    let category: String
    let order: Int
    let notes: String
    let score: Int

    init?(json: Any) {
        guard
            let fields = json as? [Any],
            fields.count >= 5,
            let name = fields[0] as? String,
            let category = fields[1] as? String,
            let order = fields[2] as? NSNumber,
            let notes = fields[3] as? String,
            let score = fields[4] as? NSNumber
        else {
            return nil
        }
        self.name = name
        self.category = category
        self.order = order.intValue
        self.notes = notes
        self.score = score.intValue
    }
}
