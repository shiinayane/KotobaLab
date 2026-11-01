//
//  DictionaryPackError.swift
//  KotobaKit
//

import Foundation

public enum DictionaryPackError: Error, Equatable {
    /// The pack was written by another format version, or by none; re-import the source.
    case unsupportedFormat(Int?)
    case missingMetadata(key: String)
    case invalidMetadata(key: String)
    /// The reference came from an earlier import of this dictionary.
    case staleReference
}
