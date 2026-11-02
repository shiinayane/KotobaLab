//
//  SavedEntry.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/11/01.
//

import Foundation
import KotobaKit

/// An entry the user saved, identified so that it survives dictionary updates.
struct SavedEntry: Hashable, Sendable {
    let dictionaryID: String
    let snapshot: DictionaryEntrySnapshot
    let savedAt: Date
}
