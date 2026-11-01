//
//  YomitanImportError.swift
//  KotobaKit
//

import Foundation

public enum YomitanImportError: Error, Equatable {
    case missingIndex
    case invalidIndex(description: String)
    case unsupportedFormat(Int)
    case noTermBanks
    case malformedBank(path: String)
    case malformedRow(path: String, row: Int)
}
