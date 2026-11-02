//
//  YomitanImportProgress.swift
//  KotobaKit
//

/// How far an import has written its term banks, which take most of its time.
public struct YomitanImportProgress: Equatable, Sendable {
    public let completedTermBanks: Int
    public let termBankCount: Int

    public var fractionCompleted: Double {
        Double(completedTermBanks) / Double(termBankCount)
    }
}
